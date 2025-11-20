#!/bin/bash

set -euo pipefail

OUTPUT_ROOT=${1:-filter_outputs}
FILTERED_FILENAME=${2:-filtered_files.txt}
MERGED_FILTERED_FILE=${3:-merge_filtered_files.txt}
MERGED_STATS_FILE=${4:-merged_stats.txt}

if [ ! -d "$OUTPUT_ROOT" ]; then
    echo "Error: Output root $OUTPUT_ROOT not found" >&2
    exit 1
fi

: > "$MERGED_FILTERED_FILE"
: > "$MERGED_STATS_FILE"

total_listed=0
total_processed=0
total_matches=0
total_missing=0

while IFS= read -r chunk_dir; do
    filter_file="$chunk_dir/$FILTERED_FILENAME"
    legacy_file="$chunk_dir/matching_files.txt"
    if [ ! -e "$filter_file" ] && [ -e "$legacy_file" ]; then
        mv "$legacy_file" "$filter_file"
    fi
    stats_file="$chunk_dir/stats.txt"
    if [ -s "$filter_file" ]; then
        cat "$filter_file" >> "$MERGED_FILTERED_FILE"
    fi
    if [ -s "$stats_file" ]; then
        listed=$(grep -E "^Total listed files:" "$stats_file" | awk '{print $4}' || echo 0)
        processed=$(grep -E "^Processed:" "$stats_file" | awk '{print $2}' || echo 0)
        matches=$(grep -E "^Matches:" "$stats_file" | awk '{print $2}' || echo 0)
        missing=$(grep -E "^Missing:" "$stats_file" | awk '{print $2}' || echo 0)
        total_listed=$((total_listed + listed))
        total_processed=$((total_processed + processed))
        total_matches=$((total_matches + matches))
        total_missing=$((total_missing + missing))
        echo "$chunk_dir" >> "$MERGED_STATS_FILE"
        cat "$stats_file" >> "$MERGED_STATS_FILE"
        echo "" >> "$MERGED_STATS_FILE"
    fi
done < <(find "$OUTPUT_ROOT" -maxdepth 1 -type d -name 'output_*' | sort)

{
    echo "Aggregate totals"
    echo "Total listed files: $total_listed"
    echo "Processed: $total_processed"
    echo "Matches: $total_matches"
    echo "Missing: $total_missing"
    echo ""
} | cat - "$MERGED_STATS_FILE" > "$MERGED_STATS_FILE.tmp" && mv "$MERGED_STATS_FILE.tmp" "$MERGED_STATS_FILE"

echo "Merged filtered file list saved to $MERGED_FILTERED_FILE"
echo "Merged stats saved to $MERGED_STATS_FILE"
