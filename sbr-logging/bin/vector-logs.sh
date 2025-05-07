#!/bin/bash

# Namespace (by default openshift-logging)
NAMESPACE="openshift-logging"
LABEL="app.kubernetes.io/name=vector"

# Output files..
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

export OUTPUT_WATCHER="/tmp/vector-logs-watcher.log"
if [ -f "$OUTPUT_WATCHER" ]; then
    rm -f "$OUTPUT_WATCHER"
fi
touch $OUTPUT_WATCHER


function output() {
  text="$1"
	param="$2"
	echo "$1" >> $OUTPUT

	if [ "$param" == "header" ]; then
		echo "$text" >> $OUTPUT_ERRORS
  fi
  if echo "$text" | grep -iq "ERROR"; then
    echo "$text" >> $OUTPUT_ERROR
  fi
  if echo "$text" | grep -iq "Watcher"; then
    echo "$text" >> $OUTPUT_WATCHER
  fi
}

# Get list of all vector pods in the namespace..
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

# Process the output..
for pod in $pods; do 
  echo "reading logs from $pod"
    output "Logs from: $pod" "header"
		output "-------------------" "header"

		omc logs -n "$NAMESPACE" "$pod" >> $OUTPUT
		omc logs -n "$NAMESPACE" "$pod" | grep -i "error" >> $OUTPUT_ERRORS
		omc logs -n "$NAMESPACE" "$pod" | grep -i "Watcher" >> $OUTPUT_WATCHER

		output "" "header"
		output "" "header"
		output "" "header"
done
