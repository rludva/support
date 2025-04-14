#!/bin/bash

# Prepera downloaded must-gather for investigation process..


FOLDER_NAME="[must-gather]"
MUST_GATHER_FILE=$(find "$HOME/Downloads" -maxdepth 1 -type f -name "must-gather*" -print -quit)
echo $MUST_GATHER_FILE

mkdir -p "./$FOLDER_NAME"
mv "$MUST_GATHER_FILE" ./"$FOLDER_NAME"

basename="$(basename "$MUST_GATHER_FILE")"
extension="${MUST_GATHER_FILE##*.}"
echo "$basename"
echo "$extension"

if [ "$extension" == "tar.gz" ]; then
  cd "$FOLDER_NAME" && tar -xvf "$basename"
fi
if [ "$extension" == "zip" ]; then
  cd "$FOLDER_NAME" && unzip "$basename"
fi
