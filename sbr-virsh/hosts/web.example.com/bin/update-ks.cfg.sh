#!/bin/bash
set -euo pipefail

# Color codes..
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

#
BASEDIR="$(cd "$(dirname "$0")/.." && pwd)"

SCRIPT_PATH="$(realpath "$0")"
SCRIPT_FOLDER="$(dirname "$SCRIPT_PATH")"
PARENT_FOLDER="$(dirname "$SCRIPT_FOLDER")"
FOLDER_NAME="$(basename "$PARENT_FOLDER")"

# Name of the VM host..
VM_NAME="$FOLDER_NAME"


# --- KONFIGURACE ---
TARGET_FILE="$PARENT_FOLDER/anaconda-ks.cfg"
SOURCE_FILE="$PARENT_FOLDER/update-ks.cfg"

# Vylepšené názvy magických řádků (značek)
MARKER_START="# === BEGIN-UPDATE-KS.CFG ==="
MARKER_END="# === END-UPDATE-KS.CFG ==="

# Pomocný dočasný soubor
TEMP_FILE="${TARGET_FILE}.tmp"

# --- KONTROLA ---
if [ ! -f "$TARGET_FILE" ]; then
    echo "CHYBA: Cílový soubor '$TARGET_FILE' neexistuje!"
    exit 1
fi

if [ ! -f "$SOURCE_FILE" ]; then
    echo "CHYBA: Zdrojový soubor '$SOURCE_FILE' neexistuje!"
    exit 1
fi

# Ověření, zda značky v souboru vůbec jsou
if ! grep -q "$MARKER_START" "$TARGET_FILE" || ! grep -q "$MARKER_END" "$TARGET_FILE"; then
    echo "CHYBA: V souboru '$TARGET_FILE' chybí startovní nebo koncová značka."
    exit 1
fi

echo "Aktualizuji sekci v $TARGET_FILE..."

# --- SED MAGIE (Čistá verze) ---
# 1. /START/,/END/ {...}  -> Pracuj jen uvnitř bloku mezi značkami
# 2. /START/r FILE        -> U startovní značky načti soubor (vloží se až pod ni)
# 3. /START/b             -> Je to startovní značka? SKOČ pryč (tím pádem se nesmaže)
# 4. /END/b               -> Je to koncová značka? SKOČ pryč (tím pádem se nesmaže)
# 5. d                    -> Pokud jsi došel až sem (jsi uprostřed), tak řádek SMAŽ.

sed -i "/$MARKER_START/,/$MARKER_END/{
    /$MARKER_START/r $SOURCE_FILE
    /$MARKER_START/b
    /$MARKER_END/b
    d
}" "$TARGET_FILE"

echo "HOTOVO."
