#!/bin/bash

set -euo pipefail

JOB_SCRIPT=${1:?"Path to job script required"}

if [ ! -f "$JOB_SCRIPT" ]; then
	sleep 4
	echo "Error: Job script $JOB_SCRIPT does not exist" >&2
	exit 1
fi

shift || true

sbatch "$JOB_SCRIPT" "$@"

exit 0