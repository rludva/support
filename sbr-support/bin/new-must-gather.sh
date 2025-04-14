#!/bin/bash

#
# This script is used to create a folder for the generated must-gather report..
#


# Function to ask a question and get the answer..
function question {
  VALUE="$1"
  QUESTION="$2 [default: $VALUE]> "

  read -p "$QUESTION" ANSWER

  if [ ! -z "$ANSWER" ]; then
	  VALUE="$ANSWER"
  fi

	echo "$VALUE"
}

# Function to ask a yes/no question and get the answer..
function yesno {
  QUESTION="$1 [Y/N]> "
  read -p "$QUESTION" ANSWER

  RESULT="no"
  if [ "$ANSWER" == "Y" ]; then
	  RESULT="yes"
	fi

  echo "$RESULT"
}

# Read the counter..
echo
ls -l
COUNTER=$(question "01" "What is the counter value?")
echo "Counter value is $COUNTER"

# Logging must-gather?
MUST_GATHER="[must-gather]"
YES=$(yesno "Is this logging must-gather?")
if [ "$YES" == "yes" ]; then
  MUST_GATHER="[logging must-gather]"
fi

echo
FOLDER="$COUNTER - $MUST_GATHER"
echo "Creating folder: \`$FOLDER\`"
mkdir "$FOLDER"

echo
ls -l
