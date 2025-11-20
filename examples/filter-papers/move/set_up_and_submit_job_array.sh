#!/bin/bash

# Sets up and submits a SLURM job array to move files from several directories 
# on a remote location to a local directory.

set -euo pipefail

# Check required environment variables
: "${REMOTE_USERNAME:?Environment variable REMOTE_USERNAME must be set}"
: "${REMOTE_HOSTNAME:?Environment variable REMOTE_HOSTNAME must be set}"
: "${REMOTE_KEY_FILENAME:?Environment variable REMOTE_KEY_FILENAME must be set}"
: "${MOVE_CHUNK_SIZE:?Environment variable MOVE_CHUNK_SIZE must be set}"
: "${MOVE_SIMS_PER_JOB:?Environment variable MOVE_SIMS_PER_JOB must be set}"

# Define parameters
CHUNK_SIZE=$MOVE_CHUNK_SIZE  ### Number of files per chunk ###
SIMS_PER_JOB=$MOVE_SIMS_PER_JOB  ### Number of chunks per job ###
REMOTE_DIRS_FILE=${REMOTE_DIRS_FILE:-"remote_dirs.txt"}
TRANSFERRED_FILES_DIR=${TRANSFERRED_FILES_DIR:-"./transferred_files"}
CHUNK_DIGITS=${MOVE_CHUNK_DIGITS:-6}
JOB_PREFIX=${MOVE_JOB_PREFIX:-transfer_}

# Parse remote directories from file
if [ -z "${REMOTE_DIRS:-}" ]; then
    REMOTE_DIRS=$(tr '\n' ',' < "$REMOTE_DIRS_FILE" | sed 's/,$//')
fi

# Clear contents of shared transfer directory
rm -rf "$TRANSFERRED_FILES_DIR"
mkdir -p "$TRANSFERRED_FILES_DIR"

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
log_and_run "Step 1/3: Creating input YAMLs" \
    bash _1_prepare_inputs.sh \
    "$REMOTE_USERNAME" \
    "$REMOTE_HOSTNAME" \
    "$REMOTE_KEY_FILENAME" \
    "$REMOTE_DIRS" \
    "$CHUNK_SIZE" \
    "$CHUNK_DIGITS" \
    "$TRANSFERRED_FILES_DIR"

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

echo "Successfully submitted job array."