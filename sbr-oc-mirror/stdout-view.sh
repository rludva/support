#!/bin/bash

# Cesta k souboru logu
stdfile="/tmp/oc-mirror.log"

# Escape sekvence pro tput reset
reset_sequence=$(tput reset)

# Header sequence..
SEQUENCE_HEADER="(header)"
SEQUENCE_OUTPUT="(output)"

# Number of already printed lines (usually header + one line)..
# So I exptect the we already printed twu lines..
RELATIVE_ZERO=2

# Načítání souboru a zpracování řádek po řádku
function stdout_view() {
  printed_lines=$RELATIVE_ZERO
	HEADER=false
	NEW_PAGE=false
  while IFS= read -r line || [[ -n "$line" ]]; do

	  if [[ "$line" == *"$SEQUENCE_HEADER"* ]]; then
		  HEADER=true
			continue
		fi

		# If Header is true, then print the line as header
		if [ "$HEADER" = true ]; then
			HEADER_CONTENT="$line"
			HEADER=false
		fi

		if [ "$NEW_PAGE" = true ]; then
			echo "$HEADER_CONTENT"
			echo "..."
			NEW_PAGE=false
		fi

    # Pokud řádek obsahuje escape sekvenci pro tput reset
    if [[ "$line" == *"$reset_sequence"* ]]; then
		  printed_lines=RELATIVE_ZERO
      echo "Sekvence pro reset nalezena. Čekám 5 sekund..."
      sleep 5
    fi

    echo "$line"

	  printed_lines=$((printed_lines + 1))
		max_lines=$(tput lines)
		if [ $printed_lines -ge $max_lines ]; then
			echo "-- next page --"
			sleep 3
		  clear
			printed_lines=$RELATIVE_ZERO
			NEW_PAGE=true
		fi

  done < "$stdfile"
}

# Infinite loop to view the output..
while true; do
	tput reset

	stdout_view	
done
