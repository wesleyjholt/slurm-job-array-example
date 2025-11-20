#!/bin/bash

set -euo pipefail

INPUT_SPEC=${1:?!"Input YAML required"}
OUTPUT_DIR=${2:?!"Output directory required"}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ ! -f "$INPUT_SPEC" ]; then
    echo "Error: Input spec $INPUT_SPEC not found" >&2
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

readarray -t CONFIG < <(python3 - "$INPUT_SPEC" <<'PY'
import sys, os
from pathlib import Path
path = Path(sys.argv[1])
config = {}
for raw in path.read_text().splitlines():
    raw = raw.split("#", 1)[0].strip()
    if not raw or ":" not in raw:
        continue
    key, value = raw.split(":", 1)
    key = key.strip()
    value = value.strip()
    if value and value[0] in {'"', "'"} and value[-1] == value[0]:
        value = value[1:-1]
    config[key] = value
file_list = config.get("file_list", "")
case_sensitive = config.get("case_sensitive", "false").lower()
print(file_list)
print(case_sensitive)
PY
)

FILE_LIST=${CONFIG[0]:-}
CASE_SENSITIVE=${CONFIG[1]:-false}

if [ -z "$FILE_LIST" ] || [ ! -f "$FILE_LIST" ]; then
    echo "Error: File list $FILE_LIST missing or unreadable" >&2
    exit 1
fi

python3 "$SCRIPT_DIR/keyword_filter_runner.py" \
    --file-list "$FILE_LIST" \
    --output-dir "$OUTPUT_DIR" \
    --case-sensitive "$CASE_SENSITIVE"

cat > "$OUTPUT_DIR/info.txt" <<EOL
Keyword batch completed at $(date)
Input spec: $INPUT_SPEC
File list: $FILE_LIST
Case sensitive: $CASE_SENSITIVE
EOL

echo "Completed keyword filtering for $FILE_LIST"
