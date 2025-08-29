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

METADATA_STRING="Commit: $SHA, Author: $AUTHOR, Date: $DATE, Message: $MESSAGE"

CODE_EXTENSIONS="js|jsx|ts|tsx|py|rb|go|rs|java|c|cpp|cs|html|css|scss|md|txt|sh|json|yaml|yml|xml|php|swift|kt"

mapfile -t COMMITTED_FILES < <(jq -r '
  if .head_commit != null then
    ((.head_commit.added // []) + (.head_commit.modified // [])) | .[]
  elif .commits != null then
    ([.commits[].added[], .commits[].modified[]] | unique) | .[]
  else
    empty
  end
' "$GITHUB_EVENT_PATH")

# this might not be a wanted feature
if [[ ${#COMMITTED_FILES[@]} -eq 0 ]]; then
  echo "No committed files found in event payload, falling back to all source files."
  mapfile -t COMMITTED_FILES < <(find "$SOURCE_PATH" -type f)
fi

mapfile -t AFFECTED_FILES < <(
  for FILE in "${COMMITTED_FILES[@]}"; do
    if [[ "$FILE" == "${SOURCE_PATH%/}/"* ]] && [[ "$FILE" =~ \.($CODE_EXTENSIONS)$ ]] && [[ -f "$FILE" ]]; then
      echo "$FILE"
    fi
  done
)

for FILE in "${AFFECTED_FILES[@]}"; do
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
done

echo ""
echo "Metadata injection completed successfully."

