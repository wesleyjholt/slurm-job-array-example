#!/bin/bash

set -euo pipefail

RUN_SIMULATION_SCRIPT=${1:?"Path to run_simulation.sh required"}
SLURM_DEFAULTS_FILE=${2:?"SLURM defaults file required"}
INPUT_FILES_FOLDER=${3:?"Inputs folder required"}
SIMS_PER_JOB=${4:-10}
PREFIX=${5:-transfer_}

# Clean up anything from previous runs
rm -rf ${PREFIX}grouped_input_paths ${PREFIX}outputs ${PREFIX}run.sh

bash ../../../src/setup.sh \
	"$RUN_SIMULATION_SCRIPT" \
	"$SLURM_DEFAULTS_FILE" \
	"$INPUT_FILES_FOLDER" \
	"$SIMS_PER_JOB" \
	"$PREFIX"