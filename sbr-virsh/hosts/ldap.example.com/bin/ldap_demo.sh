#!/bin/bash

#
BASEDIR="$(cd "$(dirname "$0")/.." && pwd)"

SCRIPT_PATH="$(realpath "$0")"
SCRIPT_FOLDER="$(dirname "$SCRIPT_PATH")"
PARENT_FOLDER="$(dirname "$SCRIPT_FOLDER")"
FOLDER_NAME="$(basename "$PARENT_FOLDER")"

# Name of the VM host..
VM_NAME="$FOLDER_NAME"


# Check if openldap-clients is installed..
if ! rpm -q openldap-clients &> /dev/null; then
    echo "Missing openldap-clients, installing..."
    sudo dnf install -y openldap-clients
fi

# Function to generate SSHA password hash..
# This function is an alternative to `slappasswd`, demonstrating how to create SSHA hashes manually..
# The `slappasswd` utility is preferred for production use..
# The `slappasswd` utlitiy is part only of `openldap-servers` package..
function generate_ssha() {
    local password="$1"
    python3 -c "import sys, os, hashlib, base64; \
        p = sys.argv[1].encode('utf-8'); \
        salt = os.urandom(8); \
        h = hashlib.sha1(p + salt).digest(); \
        print('{SSHA}' + base64.b64encode(h + salt).decode())" "$password"
}

# Storage for passwords..
PASSDB_STORAGE="/var/passwd/$VM_NAME"

# Get existing password or create a new one and store it..
# getes = get+set_tes => getes
function getesPassword() {
    local user_name="$1"
    
    # Path: /var/passwd/ldap.example.com/Manager.passwd
    local dir_path="${PASSDB_STORAGE}"
    local file_path="${dir_path}/${user_name}.passwd"
    
    # 1. Create the directory if it doesn't exist..
    if [ ! -d "$dir_path" ]; then
        mkdir -p "$dir_path"
        echo "Created password storage folder: $dir_path" >&2
    fi

    # 2. Read existing password..
    if [ -f "$file_path" ]; then
        local password=$(cat "$file_path" | tr -d '[:space:]')
        echo "$password"
        return 0
    fi

    # 3. Generate a new password and store it..
    local password=$(openssl rand -base64 16)
    echo "$password" > "$file_path"
        
    echo "Generated a new password for: $file_path" >&2
    echo "$password"
}

LDAP_PASSWORD=$(getesPassword "ldap_root")
LDAP_PASSWORD_HASH=$(generate_ssha "$LDAP_PASSWORD")


cat <<EOF > "$PASSDB_STORAGE/ldap-config.ldif"
dn: olcDatabase={2}mdb,cn=config
changetype: modify
replace: olcSuffix
olcSuffix: dc=nutius,dc=com
-
replace: olcRootDN
olcRootDN: cn=Manager,dc=nutius,dc=com
-
replace: olcRootPW
olcRootPW: $LDAP_PASSWORD_HASH
EOF

# This is not working directly, so we need to use SSH to run it on the LDAP server..
# ldapmodify -H ldap://ldap.local.nutius.com -Y EXTERNAL -H ldapi:/// -f ldap-config.ldif
scp "$PASSDB_STORAGE/ldap-config.ldif" "$VM_NAME":/tmp/ldap-config.ldif
ssh -t "$VM_NAME" "sudo ldapmodify -Y EXTERNAL -H ldapi:/// -f /tmp/ldap-config.ldif || true"


# ssh -t "$VM_NAME" "sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif || true"
# ssh -t "$VM_NAME" "sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif || true"
# ssh -t "$VM_NAME" "sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif || true"
echo "----------------------------------------------------------------"
echo "Checking and importing schemas..."
echo "----------------------------------------------------------------"

# Function that checks for schema existence on remote server and installs it if missing..
function ensure_schema() {
    local SCHEMA_KEYWORD="$1"  # "cosine"
    local SCHEMA_FILE="$2"     # "/etc/openldap/schema/cosine.ldif"
    
    echo -n "Schema '$SCHEMA_KEYWORD': "
    
    # Check if schema is already present on the LDAP server..
    if ssh -T "$VM_NAME" "sudo ldapsearch -Q -Y EXTERNAL -H ldapi:/// -b cn=schema,cn=config \"(cn=*$SCHEMA_KEYWORD*)\" dn 2>/dev/null | grep -q \"dn:\""; then
        echo "ALREADY EXISTS (Skipping)"
    else
        echo "MISSING -> Installing..."
        ssh -T "$VM_NAME" "sudo ldapadd -Y EXTERNAL -H ldapi:/// -f $SCHEMA_FILE"
    fi
}

# Ensure required schemas are present..
ensure_schema "cosine" "/etc/openldap/schema/cosine.ldif"
ensure_schema "nis" "/etc/openldap/schema/nis.ldif"
ensure_schema "inetorgperson" "/etc/openldap/schema/inetorgperson.ldif"


cat <<EOF > "$PASSDB_STORAGE/structure.ldif"
dn: dc=nutius,dc=com
objectClass: top
objectClass: domain

dn: cn=Manager,dc=nutius,dc=com
objectClass: organizationalRole
cn: Manager
description: LDAP Manager

dn: ou=Admins,dc=nutius,dc=com
objectClass: organizationalUnit
ou: Admins

# 1. Vytvoření organizační jednotky pro lidi
dn: ou=People,dc=nutius,dc=com
objectClass: organizationalUnit
ou: People

# 2. Vytvoření organizační jednotky pro skupiny
dn: ou=Groups,dc=nutius,dc=com
objectClass: organizationalUnit
ou: Groups

# 3. Vytvoření skupiny 'users' (GID 5000) uvnitř ou=Groups
dn: cn=users,ou=Groups,dc=nutius,dc=com
objectClass: posixGroup
cn: users
gidNumber: 5000
EOF

ldapadd -H ldap://ldap.local.nutius.com -x -D "cn=Manager,dc=nutius,dc=com" -w "$LDAP_PASSWORD" -f "$PASSDB_STORAGE/structure.ldif"



# User: rludva (UID 1001)
USER_NAME="rludva"
USER_FULL_NAME="Radomir Ludva"
USER_FULL_SN_NAME="Ludva"
USER_PASSWORD=$(getesPassword "$USER_NAME")
USER_PASSWORD_HASH=$(generate_ssha "$USER_PASSWORD")
USER_ID=1001
USER_GID=5000
echo "USER_PASSWORD=$USER_PASSWORD"

cat <<EOF > "$PASSDB_STORAGE/user_$USER_NAME.ldif"
dn: uid=$USER_NAME,ou=People,dc=nutius,dc=com
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
cn: $USER_FULL_NAME
sn: $USER_FULL_SN_NAME
uid: $USER_NAME
uidNumber: $USER_ID
gidNumber: $USER_GID
homeDirectory: /home/$USER_NAME
loginShell: /bin/bash
gecos: $USER_FULL_NAME
userPassword: $USER_PASSWORD_HASH
EOF

ldapadd -H ldap://ldap.local.nutius.com -x -D "cn=Manager,dc=nutius,dc=com" -w "$LDAP_PASSWORD" -f "$PASSDB_STORAGE/user_rludva.ldif"


# User: alice
USER_NAME="alice"
USER_FULL_NAME="Alice Wonderland"
USER_FULL_SN_NAME="Wonderland"
USER_PASSWORD=$(getesPassword "$USER_NAME")
USER_PASSWORD_HASH=$(generate_ssha "$USER_PASSWORD")
USER_ID=1002
USER_GID=5000
cat <<EOF > "$PASSDB_STORAGE/user_$USER_NAME.ldif"
dn: uid=$USER_NAME,ou=People,dc=nutius,dc=com
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
cn: $USER_FULL_NAME
sn: $USER_FULL_SN_NAME
uid: $USER_NAME
uidNumber: $USER_ID
gidNumber: $USER_GID
homeDirectory: /home/$USER_NAME
loginShell: /bin/bash
gecos: $USER_FULL_NAME
userPassword: $USER_PASSWORD_HASH
EOF

ldapadd -H ldap://ldap.local.nutius.com -x -D "cn=Manager,dc=nutius,dc=com" -w "$LDAP_PASSWORD" -f "$PASSDB_STORAGE/user_$USER_NAME.ldif"


# User: bob
USER_NAME="bob"
USER_FULL_NAME="Bob Builder"
USER_FULL_SN_NAME="Builder"
USER_PASSWORD=$(getesPassword "$USER_NAME")
USER_PASSWORD_HASH=$(generate_ssha "$USER_PASSWORD")
USER_ID=1003
USER_GID=5000
cat <<EOF > "$PASSDB_STORAGE/user_$USER_NAME.ldif"
dn: uid=$USER_NAME,ou=People,dc=nutius,dc=com
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
cn: $USER_FULL_NAME
sn: $USER_FULL_SN_NAME
uid: $USER_NAME
uidNumber: $USER_ID
gidNumber: $USER_GID
homeDirectory: /home/$USER_NAME
loginShell: /bin/bash
gecos: $USER_FULL_NAME
userPassword: $USER_PASSWORD_HASH
EOF

ldapadd -H ldap://ldap.local.nutius.com -x -D "cn=Manager,dc=nutius,dc=com" -w "$LDAP_PASSWORD" -f "$PASSDB_STORAGE/user_$USER_NAME.ldif"


# User: malory
USER_NAME="malory"
USER_FULL_NAME="Malory Archer"
USER_FULL_SN_NAME="Archer"
USER_PASSWORD=$(getesPassword "$USER_NAME")
USER_PASSWORD_HASH=$(generate_ssha "$USER_PASSWORD")
USER_ID=1004
USER_GID=5000
cat <<EOF > "$PASSDB_STORAGE/user_$USER_NAME.ldif"
dn: uid=$USER_NAME,ou=People,dc=nutius,dc=com
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
cn: $USER_FULL_NAME
sn: $USER_FULL_SN_NAME
uid: $USER_NAME
uidNumber: $USER_ID
gidNumber: $USER_GID
homeDirectory: /home/$USER_NAME
loginShell: /bin/bash
gecos: $USER_FULL_NAME
userPassword: $USER_PASSWORD_HASH
EOF

ldapadd -H ldap://ldap.local.nutius.com -x -D "cn=Manager,dc=nutius,dc=com" -w "$LDAP_PASSWORD" -f "$PASSDB_STORAGE/user_$USER_NAME.ldif"
