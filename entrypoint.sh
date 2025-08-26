#!/bin/bash

# envs: SOURCE_PATH, PLACEHOLDER

set -e

# trust the action
git config --global --add safe.directory /github/workspace

SHA=$GITHUB_SHA

EVENT_PAYLOAD=$(cat "$GITHUB_EVENT_PATH")

AUTHOR=$(echo "$EVENT_PAYLOAD" | jq -r '.head_commit.author.name')
DATE=$(echo "$EVENT_PAYLOAD" | jq -r '.head_commit.timestamp')
MESSAGE=$(echo "$EVENT_PAYLOAD" | jq -r '.head_commit.message')

echo "Running metadata injection script..."
echo "-----------------------------------"
echo "Commit SHA: $SHA"
echo "Author: $AUTHOR"
echo "Date: $DATE"
echo "Message: $MESSAGE"
echo "Source Path: $SOURCE_PATH"
echo "-----------------------------------"

AFFECTED_FILES=$(echo "$EVENT_PAYLOAD" | jq -r '[.head_commit.added // [], .head_commit.modified // [], .head_commit.removed // []] | unique | .[]')

if [ -z "$AFFECTED_FILES" ]; then
  echo "No affected files found in the commit. Exiting."
  exit 0
fi

for FILE in $AFFECTED_FILES; do
  if [[ "$FILE" =~ ^"$SOURCE_PATH" ]] && [[ "$FILE" =~ \.(js|jsx|ts|tsx|py|html|css|md|txt)$ ]]; then
    METADATA_STRING="Commit: $SHA, Author: $AUTHOR, Date: $DATE, Message: $MESSAGE"

    if grep -q "^Commit: " "$FILE"; then
      echo "Updating metadata in $FILE..."
      sed -i "s@^Commit: .*@$METADATA_STRING@g" "$FILE"
    elif grep -q "$PLACEHOLDER" "$FILE"; then
      echo "Injecting new metadata into $FILE..."
      sed -i "s@$PLACEHOLDER@$METADATA_STRING@g" "$FILE"
    fi
  fi
done