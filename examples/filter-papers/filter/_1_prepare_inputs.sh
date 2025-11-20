#!/bin/bash

set -euo pipefail

SOURCE_DIR=${1:-"../move/transferred_files"}
CHUNK_SIZE=${2:-1000}
CHUNK_DIGITS=${3:-6}
CASE_SENSITIVE=${4:-false}
FILE_PATTERN=${5:-'*.txt'}

SOURCE_DIR=$(readlink -f "$SOURCE_DIR")
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: Source directory $SOURCE_DIR does not exist" >&2
    exit 1
fi

if ! [[ "$CHUNK_SIZE" =~ ^[0-9]+$ ]] || [ "$CHUNK_SIZE" -le 0 ]; then
    echo "Error: CHUNK_SIZE must be a positive integer" >&2
    exit 1
fi

if ! [[ "$CHUNK_DIGITS" =~ ^[0-9]+$ ]] || [ "$CHUNK_DIGITS" -le 0 ]; then
    echo "Error: CHUNK_DIGITS must be a positive integer" >&2
    exit 1
fi

WORK_DIR=$(pwd)
FILE_LIST_DIR="$WORK_DIR/file_lists"
INPUT_DIR="$WORK_DIR/inputs"

rm -rf "$FILE_LIST_DIR" "$INPUT_DIR"
mkdir -p "$FILE_LIST_DIR" "$INPUT_DIR"

MASTER_LIST="$FILE_LIST_DIR/all_files.txt"

echo "Collecting files matching pattern $FILE_PATTERN under $SOURCE_DIR ..."
find "$SOURCE_DIR" -type f -name "$FILE_PATTERN" | sort > "$MASTER_LIST"

if [ ! -s "$MASTER_LIST" ]; then
    echo "Error: No files found in $SOURCE_DIR matching pattern $FILE_PATTERN" >&2
    exit 1
fi

echo "Splitting file list into chunks of $CHUNK_SIZE ..."
split -l "$CHUNK_SIZE" -d -a "$CHUNK_DIGITS" "$MASTER_LIST" "$FILE_LIST_DIR/chunk_"

for chunk_file in "$FILE_LIST_DIR"/chunk_*; do
    [ -f "$chunk_file" ] || continue
    chunk_base=$(basename "$chunk_file")
    yaml_file="$INPUT_DIR/input_${chunk_base}.yaml"
    file_list_abs=$(readlink -f "$chunk_file")
    cat > "$yaml_file" <<EOL
file_list: '$file_list_abs'
case_sensitive: $CASE_SENSITIVE
EOL
    echo "Created $yaml_file"
done

exit 0
