#!/bin/bash

# Required envs: SOURCE_PATH, PLACEHOLDER

set -euo pipefail

if [ -n "$DEBUG" ]; then
    set -x
fi

: "${SOURCE_PATH:?Environment variable SOURCE_PATH is not set}"
: "${PLACEHOLDER:?Environment variable PLACEHOLDER is not set}"

git config --global --add safe.directory /github/workspace

FOUND_FILES=$(find "$SOURCE_PATH" -type f)

if [ -n "$FOUND_FILES" ]; then
  echo "Found files in $SOURCE_PATH"
  if [ -n "$DEBUG" ]; then
    echo "$FOUND_FILES"
  fi
else
  echo "No files found in $SOURCE_PATH"
  exit 0
fi

SHA=${GITHUB_SHA:-"unknown"}
AUTHOR=$(jq -r '.head_commit.author.name // "unknown"' "$GITHUB_EVENT_PATH")
DATE=$(jq -r '.head_commit.timestamp // "unknown"' "$GITHUB_EVENT_PATH")
MESSAGE=$(jq -r '.head_commit.message // "unknown"' "$GITHUB_EVENT_PATH")


echo ""
echo "Running metadata injection script..."
echo "-----------------------------------"
echo "Commit SHA:     $SHA"
echo "Author:         $AUTHOR"
echo "Date:           $DATE"
echo "Message:        $MESSAGE"
echo "Source Path:    $SOURCE_PATH"
echo "-----------------------------------"

mapfile -t AFFECTED_FILES < <(jq -r '
  if .head_commit != null then
    (
      (.head_commit.added // []) + (.head_commit.modified // [])
    ) | .[]
  elif .commits != null then
    (
      [ .commits[].added[], .commits[].modified[] ] | unique
    ) | .[]
  else
    empty
  end
' "$GITHUB_EVENT_PATH")

METADATA_STRING="Commit: $SHA, Author: $AUTHOR, Date: $DATE, Message: $MESSAGE"

for FILE in "${AFFECTED_FILES[@]}"; do
  if [[ "$FILE" == "${SOURCE_PATH%/}/"* ]] && [[ "$FILE" =~ \.(js|jsx|ts|tsx|py|html|css|md|txt)$ ]]; then
    if [ -f "$FILE" ]; then
      echo "Processing file: $FILE"

      if grep -q "^Commit: " "$FILE"; then
        echo "Updating existing metadata..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
          sed -i '' "s@^Commit: .*@$METADATA_STRING@" "$FILE"
        else
          sed -i "s@^Commit: .*@$METADATA_STRING@" "$FILE"
        fi
      elif grep -q "$PLACEHOLDER" "$FILE"; then
        echo "Injecting metadata into placeholder..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
          sed -i '' "s@$PLACEHOLDER@$METADATA_STRING@" "$FILE"
        else
          sed -i "s@$PLACEHOLDER@$METADATA_STRING@" "$FILE"
        fi
      else
        echo "No matching placeholder or metadata line. Skipping."
      fi
    else
      echo "File does not exist (might be deleted): $FILE"
    fi
  else
    echo "Skipping non-matching file: $FILE"
  fi
done


echo ""
echo "Metadata injection completed successfully."

