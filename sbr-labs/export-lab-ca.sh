#!/usr/bin/env bash
set -euo pipefail

HOST="${1:-}"
if [[ -z "$HOST" ]]; then
    echo "Usage: $0 <hostname>"
    echo "Example:"
    echo "$0 console-openshift-console.apps.example.com"
    exit 1
fi

# Colors
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
RESET="\033[0m"

step() {
    echo -e "${BLUE}[+]${RESET} $1"
}

ok() {
    echo -e "${GREEN}[OK]${RESET} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${RESET} $1"
}

fail() {
    echo -e "${RED}[ERROR]${RESET} $1"
    exit 1
}


echo
echo -e "${GREEN}OpenShift ingress CA installer${RESET}"
echo "Host: $HOST"
echo


TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

CHAIN="$TMPDIR/chain.pem"
CA="$PWD/ingress-ca.pem"


step "Downloading certificate chain using openssl..."
openssl s_client \
    -showcerts \
    -connect "${HOST}:443" \
    </dev/null 2>/dev/null \
    > "$CHAIN"
ok "Certificate chain downloaded"


step "Extracting CA certificate..."
awk '
/BEGIN CERTIFICATE/ {n++}
n==2 {print}
/END CERTIFICATE/ && n==2 {exit}
' "$CHAIN" > "$CA"

if ! grep -q "BEGIN CERTIFICATE" "$CA"; then
    fail "Could not extract CA certificate"
fi
ok "CA certificate saved to $CA"


step "Installing CA into system trust store..."
if [[ $EUID -ne 0 ]]; then
    sudo cp "$CA" /etc/pki/ca-trust/source/anchors/
    sudo update-ca-trust
else
    cp "$CA" /etc/pki/ca-trust/source/anchors/
    update-ca-trust
fi
ok "System trust store updated"


step "Checking Chrome NSS database..."
if ! command -v certutil >/dev/null 2>&1; then
    warn "certutil not found, installing nss-tools"

    if [[ $EUID -ne 0 ]]; then
        sudo dnf install -y nss-tools
    else
        dnf install -y nss-tools
    fi
fi


NSSDB="$HOME/.pki/nssdb"
if [[ ! -d "$NSSDB" ]]; then
    warn "Chrome NSS database does not exist, creating it"

    mkdir -p "$NSSDB"

    certutil \
        -d sql:"$NSSDB" \
        -N \
        --empty-password
fi


step "Importing CA into Chrome..."
certutil \
    -d sql:"$NSSDB" \
    -A \
    -t "C,," \
    -n "OpenShift ingress CA - $HOST" \
    -i "$CA"
ok "Chrome certificate database updated"

step "Verifying certificate..."
openssl verify \
    -CAfile /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem \
    "$CA"

step "Cleaning temporary extracted certificate..."
if [[ -f "$CA" ]]; then
    rm -f "$CA"
    ok "Removed $CA"
else
    warn "$CA not found"
fi

echo
echo -e "${GREEN}======================================${RESET}"
echo -e "${GREEN} DONE${RESET}"
echo -e "${GREEN}======================================${RESET}"
echo
echo -e "Restart Chrome completely:"
echo -e "${YELLOW}\$ pkill chrome${RESET}"
echo
echo
echo -e "Open OpenShift Console:"
echo -e "${YELLOW}\$ google-chrome https://${HOST}${RESET}"
echo
