#!/bin/bash

# Sets up and submits a SLURM job array to filter papers based on keywords.

set -euo pipefail

# Check required environment variables
: "${FILTER_CHUNK_SIZE:?Environment variable FILTER_CHUNK_SIZE must be set}"
: "${FILTER_SIMS_PER_JOB:?Environment variable FILTER_SIMS_PER_JOB must be set}"

# Define parameters
CHUNK_SIZE=$FILTER_CHUNK_SIZE  ### Number of files per chunk ###
SIMS_PER_JOB=$FILTER_SIMS_PER_JOB  ### Number of chunks per job ###
SOURCE_DIR=${SOURCE_DIR:-"../move/transferred_files"}
CHUNK_DIGITS=${FILTER_CHUNK_DIGITS:-6}
JOB_PREFIX=${FILTER_JOB_PREFIX:-filter_}
CASE_SENSITIVE=${CASE_SENSITIVE:-false}
FILE_PATTERN=${FILE_PATTERN:-'*.txt'}

# Function to log and run commands
log_and_run() {
    local label=$1
    shift
    echo "==> $label" >&2
    if ! "$@"; then
        echo "ERROR: $label failed. Exiting workflow." >&2
        exit 1
    fi
    echo "<== Completed $label" >&2
}

# Run the processing steps
log_and_run "Step 1/3: Preparing keyword input chunks" \
    bash _1_prepare_inputs.sh \
    "$SOURCE_DIR" \
    "$CHUNK_SIZE" \
    "$CHUNK_DIGITS" \
    "$CASE_SENSITIVE" \
    "$FILE_PATTERN"

sleep 1

log_and_run "Step 2/3: Generating job script" \
    bash _2_generate_job_script.sh \
    "./run_one_batch.sh" \
    "slurm_defaults.txt" \
    "./inputs" \
    "$SIMS_PER_JOB" \
    "$JOB_PREFIX"

sleep 1

echo "Step 3/3: Submitting job array"

JOB_SCRIPT="${JOB_PREFIX}run.sh"
sbatch "$JOB_SCRIPT"

echo "Keyword filter job array submitted."
