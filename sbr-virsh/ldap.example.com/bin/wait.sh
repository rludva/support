#!/bin/bash

# Zpráva pro uživatele (zobrazí se na jednom řádku, -n potlačí nový řádek)
echo -n "Waiting 10s to get chance to manually stop this script if any failure... "

# Příkaz read s časovým limitem:
# -r: zabrání Backslash interpretaci.
# -t 10: čeká maximálně 10 sekund.
# -n 1: čeká na stisk JEDNÉ klávesy (není nutný Enter).
read -r -t 10 -n 1

# Kontrolujeme návratový kód ($?):
# Kód 0 znamená, že vstup byl úspěšný (klávesa stisknuta).

if [ $? -eq 0 ]; then
  echo ""
  echo "Manual break activated.."
  exit 1
else
  echo ""
  echo "Manual break chance timeout.."
fi
