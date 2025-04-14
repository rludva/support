#!/bin/bash

# Namespace (změň nebo nech prázdné pro default)
NAMESPACE="openshift-logging"
LABEL="app.kubernetes.io/name=vector"

# Výstupní adresář
export OUTPUT="/tmp/vector-logs.log"
if [ -f "$OUTPUT" ]; then
    rm -f "$OUTPUT"
fi
touch $OUTPUT

export OUTPUT_ERRORS="/tmp/vector-logs-errors.log"
if [ -f "$OUTPUT_ERRORS" ]; then
    rm -f "$OUTPUT_ERRORS"
fi
touch $OUTPUT_ERRORS

function output() {
  text="$1"
	param="$2"
	echo "$1" >> $OUTPUT

	if [ "$param" == "header" ]; then
		echo "$text" >> $OUTPUT_ERRORS
  fi
  if echo "$text" | grep -iq "ERROR"; then
    echo "$text" >> $OUTPUT_ERRORS
  fi
}

# Získání seznamu podů obsahujících "v"
pods=$(omc get pods -n $NAMESPACE -l $LABEL -o name)
		
# Basic information output..		
output "Namespace: $NAMESPACE" "header"
output "Labels: $LABEL"  "header"
output "" "header"
output "" "header"
output "Pods:" "header"
output "-----" "header"
lines=$(omc get pods -n $NAMESPACE -l $LABEL)
output "$lines" "header"
output "" "header"

# Výpis logů do souborů
for pod in $pods; do 
  echo "reading logs from $pod"
    output "Logs from: $pod" "header"
		output "-------------------" "header"

		omc logs -n "$NAMESPACE" "$pod" >> $OUTPUT
		omc logs -n "$NAMESPACE" "$pod" | grep -i "error" >> $OUTPUT_ERRORS

		output "" "header"
		output "" "header"
		output "" "header"
done

lnav "$OUTPUT"
