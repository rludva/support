#!/bin/bash
set -euo pipefail

# Definice barev
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
CYAN='\e[36m'
RESET='\e[0m'

echo -e "${CYAN}=== Průvodce přidáním nového Samba uživatele ===${RESET}"

# Kontrola na práva roota
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}[CHYBA] Tento skript musí být spuštěn jako root (použijte sudo).${RESET}"
   exit 1
fi

# Interaktivní zadání jména
read -p "Zadejte jméno nového uživatele: " NEW_USER

if [[ -z "$NEW_USER" ]]; then
    echo -e "${RED}[CHYBA] Jméno uživatele nesmí být prázdné.${RESET}"
    exit 1
fi

# Kontrola a vytvoření linuxového uživatele
if id "$NEW_USER" &>/dev/null; then
    echo -e "${YELLOW}[INFO] Linuxový uživatel '$NEW_USER' již existuje. Přecházím k Sambě.${RESET}"
else
    echo -e "${CYAN}[INFO] Vytvářím linuxového uživatele '$NEW_USER'...${RESET}"
    # -M nevytvoří domovskou složku, -s /sbin/nologin zakáže běžné SSH přihlášení (bezpečnější pro Sambu)
    useradd -M -s /sbin/nologin "$NEW_USER"
    echo -e "${GREEN}[OK] Linuxový uživatel vytvořen.${RESET}"
fi

# Interaktivní zadání hesla (skryté)
echo -n "Zadejte heslo pro Sambu (nebude zobrazeno): "
read -s NEW_PASS
echo ""
echo -n "Zadejte heslo znovu pro kontrolu: "
read -s NEW_PASS_CONFIRM
echo ""

if [[ "$NEW_PASS" != "$NEW_PASS_CONFIRM" ]]; then
    echo -e "${RED}[CHYBA] Hesla se neshodují!${RESET}"
    exit 1
fi

if [[ -z "$NEW_PASS" ]]; then
    echo -e "${RED}[CHYBA] Heslo nesmí být prázdné.${RESET}"
    exit 1
fi

# Přidání do Samby
echo -e "${CYAN}[INFO] Přidávám uživatele do databáze Samby...${RESET}"
(echo "$NEW_PASS"; echo "$NEW_PASS") | smbpasswd -s -a "$NEW_USER"

# Aktivace účtu (pro jistotu)
smbpasswd -e "$NEW_USER" > /dev/null

echo -e "${GREEN}=== HOTOVO! ===${RESET}"
echo -e "Uživatel ${YELLOW}$NEW_USER${RESET} byl úspěšně přidán do Samby a je aktivní."
