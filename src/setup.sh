#!/bin/bash

### The setup script ###

# USAGE: 
# ./setup.sh <run_simulation_script> <slurm_defaults_file> <inputs_folder> <sims_per_job> <prefix>

# DESCRIPTION:
# Setup script for job array. It sets up the necessary directories and creates
# the job file for submission. After calling this script, run `sbatch <prefix>run.sh`
# to submit the jobs to the SLURM scheduler.

RUN_SIMULATION_SCRIPT=$1
SLURM_DEFAULTS_FILE=$2
INPUTS_FOLDER=$3
SIMS_PER_JOB=$4
PREFIX=$5

# Validate inputs
if [ -z "$RUN_SIMULATION_SCRIPT" ] || [ -z "$SLURM_DEFAULTS_FILE" ] || [ -z "$INPUTS_FOLDER" ] || [ -z "$SIMS_PER_JOB" ] || [ -z "$PREFIX" ]; then
    echo "Error: Missing arguments"
    echo "Usage: $0 <run_simulation_script> <slurm_defaults_file> <inputs_folder> <sims_per_job> <prefix>"
    exit 1
fi

if [ ! -f "$RUN_SIMULATION_SCRIPT" ]; then
    echo "Error: Simulation script $RUN_SIMULATION_SCRIPT does not exist"
    exit 1
fi

if [ ! -f "$SLURM_DEFAULTS_FILE" ]; then
    echo "Error: SLURM defaults file $SLURM_DEFAULTS_FILE does not exist"
    exit 1
fi

if [ ! -d "$INPUTS_FOLDER" ]; then
    echo "Error: Input folder $INPUTS_FOLDER does not exist"
    exit 1
fi

# Create grouped input paths folder
GROUPED_FOLDER="${PREFIX}grouped_input_paths"
mkdir -p "$GROUPED_FOLDER"

# Create outputs folder
OUTPUTS_FOLDER="${PREFIX}outputs"
mkdir -p "$OUTPUTS_FOLDER"

# Get all input yaml files sorted
INPUT_FILES=($(ls "$INPUTS_FOLDER"/input_*.yaml 2>/dev/null | sort))
TOTAL_SIMS=${#INPUT_FILES[@]}

if [ $TOTAL_SIMS -eq 0 ]; then
    echo "Error: No input_*.yaml files found in $INPUTS_FOLDER"
    exit 1
fi

echo "Found $TOTAL_SIMS simulation input files"

# Calculate number of jobs needed
NUM_JOBS=$(( (TOTAL_SIMS + SIMS_PER_JOB - 1) / SIMS_PER_JOB ))
echo "Creating $NUM_JOBS job groups ($SIMS_PER_JOB simulations per job)"

# Create grouped input files and output directories
job_num=1
sim_count=0

for input_file in "${INPUT_FILES[@]}"; do
    # Extract simulation number from filename (e.g., input_0001.yaml -> 0001)
    sim_id=$(basename "$input_file" | sed 's/input_\(.*\)\.yaml/\1/')
    
    # Determine which job group this belongs to
    job_num=$(( (sim_count / SIMS_PER_JOB) + 1 ))
    job_file=$(printf "${GROUPED_FOLDER}/input_group_%04d.txt" $job_num)
    
    # Get absolute path of input file
    abs_input_file=$(readlink -f "$input_file")
    
    # Append to the appropriate job group file
    echo "$abs_input_file" >> "$job_file"
    
    # Create output directory for this simulation
    output_dir="${OUTPUTS_FOLDER}/output_${sim_id}"
    mkdir -p "$output_dir"
    
    sim_count=$((sim_count + 1))
done

echo "Created $NUM_JOBS grouped input files in $GROUPED_FOLDER"
echo "Created $TOTAL_SIMS output directories in $OUTPUTS_FOLDER"
echo ""

# Generate the job file
echo "Generating job file..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "$SCRIPT_DIR/generate_job_file.sh" "$RUN_SIMULATION_SCRIPT" "$SLURM_DEFAULTS_FILE" "$NUM_JOBS" "$PREFIX"

echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "Job file created: ${PREFIX}run.sh"
echo ""
echo "To submit the job array, run:"
echo "  sbatch ${PREFIX}run.sh"
