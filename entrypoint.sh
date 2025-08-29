#!/bin/bash

# Required envs: SOURCE_PATH, PLACEHOLDER

set -euo pipefail

if [ -n "$DEBUG" ]; then
    set -x
fi

: "${SOURCE_PATH:?Environment variable SOURCE_PATH is not set}"
: "${PLACEHOLDER:?Environment variable PLACEHOLDER is not set}"

git config --global --add safe.directory /github/workspace

if find "$SOURCE_PATH" -type f | grep -q .; then
  echo "Continuing to look for matches in $SOURCE_PATH"
else
  echo "No files found in $SOURCE_PATH"
  exit 0
fi

SHA=${GITHUB_SHA:-"unknown"}
EVENT_PAYLOAD=$(cat "$GITHUB_EVENT_PATH")

AUTHOR=$(echo "$EVENT_PAYLOAD" | jq -r '.head_commit.author.name // "unknown"')
DATE=$(echo "$EVENT_PAYLOAD" | jq -r '.head_commit.timestamp // "unknown"')
MESSAGE=$(echo "$EVENT_PAYLOAD" | jq -r '.head_commit.message // "unknown"')

echo ""
echo "Running metadata injection script..."
echo "-----------------------------------"
echo "Commit SHA:     $SHA"
echo "Author:         $AUTHOR"
echo "Date:           $DATE"
echo "Message:        $MESSAGE"
echo "Source Path:    $SOURCE_PATH"
echo "-----------------------------------"

if [ -n "$DEBUG" ]; then
    echo "head_commit payload:"
    echo "$EVENT_PAYLOAD" | jq '.head_commit'
fi

AFFECTED_FILES=$(echo "$EVENT_PAYLOAD" | jq -r '
  if .head_commit != null then
    [
      (.head_commit.added // []),
      (.head_commit.modified // [])
    ]
    | add
    | unique
    | .[]
  else
    empty
  end
')

if [ -z "$AFFECTED_FILES" ]; then
  echo "No affected files found in the commit. Exiting."
  exit 0
fi

METADATA_STRING="Commit: $SHA, Author: $AUTHOR, Date: $DATE, Message: $MESSAGE"

echo "$AFFECTED_FILES" | while IFS= read -r FILE; do
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

