#!/bin/bash

set -euo pipefail

REMOTE_USERNAME=${1:?"Remote username required"}
REMOTE_HOSTNAME=${2:?"Remote hostname required"}
REMOTE_KEY_FILENAME=${3:?"Path to SSH key required"}
REMOTE_DIR_SPEC=${4:?"Remote directory (or list/file) required"}
CHUNK=${5:-1000}
NUM_ID_DIGITS=${6:-6}
TRANSFERRED_FILES_DIR=${7:-}

# Expand a leading tilde in the key path so SSH/scp can read it.
REMOTE_KEY_FILENAME=${REMOTE_KEY_FILENAME/#\~/$HOME}

trim_whitespace() {
    local input="$1"
    input="${input#${input%%[![:space:]]*}}"
    input="${input%${input##*[![:space:]]}}"
    printf '%s' "$input"
}

REMOTE_DIRECTORIES=()
if [ -f "$REMOTE_DIR_SPEC" ]; then
    while IFS= read -r line; do
        line=$(trim_whitespace "$line")
        [ -n "$line" ] && REMOTE_DIRECTORIES+=("$line")
    done < "$REMOTE_DIR_SPEC"
else
    IFS=',' read -r -a raw_dirs <<< "$REMOTE_DIR_SPEC"
    for entry in "${raw_dirs[@]}"; do
        entry=$(trim_whitespace "$entry")
        [ -n "$entry" ] && REMOTE_DIRECTORIES+=("$entry")
    done
fi

unset IFS

if [ ${#REMOTE_DIRECTORIES[@]} -eq 0 ]; then
    echo "Error: No remote directories provided" >&2
    exit 1
fi

LOCAL_LIST_DIR="$(pwd)/file_lists"
INPUT_DIR="$(pwd)/inputs"

rm -rf "$LOCAL_LIST_DIR" "$INPUT_DIR" 
mkdir -p "$LOCAL_LIST_DIR" "$INPUT_DIR"

REMOTE_TEMP_PREFIX="chunk_"

REMOTE_FIND_COMMAND=$(python3 - "$CHUNK" "$NUM_ID_DIGITS" "${REMOTE_DIRECTORIES[@]}" <<'PY'
import shlex, sys
chunk = sys.argv[1]
digits = sys.argv[2]
dirs = sys.argv[3:]
if not dirs:
    raise SystemExit("No remote directories provided")
quoted_dirs = " ".join(shlex.quote(d) for d in dirs)
print(f"set -euo pipefail; find {quoted_dirs} -type f -name '*.txt' | sort | split -l {chunk} -d -a {digits} - chunk_")
PY
)

echo "Splitting remote file list into chunks of $CHUNK entries..."
ssh -i "$REMOTE_KEY_FILENAME" "$REMOTE_USERNAME@$REMOTE_HOSTNAME" "$REMOTE_FIND_COMMAND"

echo "Copying chunk manifests locally..."
scp -i "$REMOTE_KEY_FILENAME" "$REMOTE_USERNAME@$REMOTE_HOSTNAME:${REMOTE_TEMP_PREFIX}*" "$LOCAL_LIST_DIR/"

echo "Cleaning up remote chunk manifests..."
ssh -i "$REMOTE_KEY_FILENAME" "$REMOTE_USERNAME@$REMOTE_HOSTNAME" "rm -f ${REMOTE_TEMP_PREFIX}*"

for chunk_file in "$LOCAL_LIST_DIR"/${REMOTE_TEMP_PREFIX}*; do
    chunk_base=$(basename "$chunk_file")
    yaml_file="$INPUT_DIR/input_${chunk_base}.yaml"
    archive_name="archive_${chunk_base}.tar.gz"
    file_list_abs=$(readlink -f "$chunk_file")
    cat > "$yaml_file" <<EOL
hostname: '$REMOTE_HOSTNAME'
username: '$REMOTE_USERNAME'
key_filename: '$REMOTE_KEY_FILENAME'
file_list: '$file_list_abs'
archive_basename: '$archive_name'
keep_archive: false
EOL
    if [ -n "$TRANSFERRED_FILES_DIR" ]; then
	transferred_abs=$(readlink -f "$TRANSFERRED_FILES_DIR")
	cat >> "$yaml_file" <<EOL
transferred_files_dir: '$transferred_abs'
EOL
    fi
    echo "Created $yaml_file"
done

exit 0