#!/bin/bash

### The internal job file generation script ###

# USAGE: 
# ./generate_job_file.sh <run_simulation_script> <slurm_defaults_file> <num_jobs> <prefix>

# DESCRIPTION:
# Internal script to generate the job array submission script.

RUN_SIMULATION_SCRIPT=$1
SLURM_DEFAULTS_FILE=$2
NUM_JOBS=$3
PREFIX=$4

# Validate inputs
if [ -z "$RUN_SIMULATION_SCRIPT" ] || [ -z "$SLURM_DEFAULTS_FILE" ] || [ -z "$NUM_JOBS" ] || [ -z "$PREFIX" ]; then
    echo "Error: Missing arguments"
    echo "Usage: $0 <run_simulation_script> <slurm_defaults_file> <num_jobs> <prefix>"
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

# Get absolute path to simulation script
ABS_RUN_SCRIPT=$(readlink -f "$RUN_SIMULATION_SCRIPT")

# Define paths
GROUPED_FOLDER="${PREFIX}grouped_input_paths"
OUTPUTS_FOLDER="${PREFIX}outputs"
JOB_FILE="${PREFIX}run.sh"

# Check if required folders exist
if [ ! -d "$GROUPED_FOLDER" ]; then
    echo "Error: Grouped input folder $GROUPED_FOLDER does not exist"
    echo "Please run setup.sh first"
    exit 1
fi

if [ ! -d "$OUTPUTS_FOLDER" ]; then
    echo "Error: Outputs folder $OUTPUTS_FOLDER does not exist"
    echo "Please run setup.sh first"
    exit 1
fi

# Create logs directory if it doesn't exist
mkdir -p logs

# Create the job file
echo "Creating job file: $JOB_FILE"

# Start with shebang
echo "#!/bin/bash" > "$JOB_FILE"

# Add default output/error directives (can be overridden by user's file)
if ! grep -q "^\s*#SBATCH\s*--output" "$SLURM_DEFAULTS_FILE"; then
    echo "#SBATCH --output=logs/job_%A_%a.out" >> "$JOB_FILE"
fi
if ! grep -q "^\s*#SBATCH\s*--error" "$SLURM_DEFAULTS_FILE"; then
    echo "#SBATCH --error=logs/job_%A_%a.err" >> "$JOB_FILE"
fi

# Add user's SLURM defaults
cat "$SLURM_DEFAULTS_FILE" >> "$JOB_FILE"

# Add job array directive
echo "" >> "$JOB_FILE"
echo "#SBATCH --array=1-${NUM_JOBS}" >> "$JOB_FILE"
echo "" >> "$JOB_FILE"

# Add the main job script
cat >> "$JOB_FILE" << 'EOF'
# Print job information
echo "=========================================="
echo "Job ID: $SLURM_JOB_ID"
echo "Array Task ID: $SLURM_ARRAY_TASK_ID"
echo "Running on host: $(hostname)"
echo "Starting at: $(date)"
echo "=========================================="
echo ""

# Define paths based on array task ID
EOF

# Add the specific paths (these need variable expansion)
cat >> "$JOB_FILE" << EOF
INPUT_GROUP_FILE="${GROUPED_FOLDER}/input_group_\$(printf '%04d' \$SLURM_ARRAY_TASK_ID).txt"

# Check if input group file exists
if [ ! -f "\$INPUT_GROUP_FILE" ]; then
    echo "Error: Input group file \$INPUT_GROUP_FILE not found"
    exit 1
fi

# Read each line from the input group file and run simulation
while IFS= read -r input_yaml; do
    if [ -z "\$input_yaml" ]; then
        continue
    fi
    
    # Extract simulation ID from input filename
    sim_id=\$(basename "\$input_yaml" | sed 's/input_\(.*\)\.yaml/\1/')
    output_dir="${OUTPUTS_FOLDER}/output_\${sim_id}"
    
    echo "Running simulation: \$input_yaml -> \$output_dir"
    
    # Run the simulation
    bash "$ABS_RUN_SCRIPT" "\$input_yaml" "\$output_dir"
    
    # Check exit status
    if [ \$? -eq 0 ]; then
        echo "Simulation \$sim_id completed successfully"
    else
        echo "Error: Simulation \$sim_id failed"
    fi
    echo ""
done < "\$INPUT_GROUP_FILE"

echo "=========================================="
echo "All simulations in task \$SLURM_ARRAY_TASK_ID completed"
echo "Finished at: \$(date)"
echo "=========================================="
EOF

chmod +x "$JOB_FILE"
echo "Job file created: $JOB_FILE"
echo ""
echo "To submit the job array, run:"
echo "  sbatch $JOB_FILE"
