#!/bin/bash

set -euo pipefail

RUN_SCRIPT=${1:-"./run_keyword_batch.sh"}
SLURM_DEFAULTS=${2:-"slurm_defaults.txt"}
INPUT_DIR=${3:-"./inputs"}
SIMS_PER_JOB=${4:-5}
JOB_PREFIX=${5:-keyword_}

if [ ! -f "$RUN_SCRIPT" ]; then
    echo "Error: Run script $RUN_SCRIPT not found" >&2
    exit 1
fi

if [ ! -f "$SLURM_DEFAULTS" ]; then
    echo "Error: SLURM defaults file $SLURM_DEFAULTS not found" >&2
    exit 1
fi

if [ ! -d "$INPUT_DIR" ]; then
    echo "Error: Input directory $INPUT_DIR not found" >&2
    exit 1
fi

rm -rf ${JOB_PREFIX}grouped_input_paths ${JOB_PREFIX}outputs ${JOB_PREFIX}run.sh

bash ../../../src/setup.sh \
    "$RUN_SCRIPT" \
    "$SLURM_DEFAULTS" \
    "$INPUT_DIR" \
    "$SIMS_PER_JOB" \
    "$JOB_PREFIX"
