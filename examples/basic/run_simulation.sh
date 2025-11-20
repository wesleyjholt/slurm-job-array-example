#!/bin/bash

### The user-provided simulation script ###

# USAGE: 
# ./run_simulation.sh <input_yaml_file> <output_directory>

# DESCRIPTION:
# This the script that runs a single simulation. 
# It should use the input parameters from the YAML file.
# It should save all results to the specified output directory.

INPUT_YAML=$1
OUTPUT_DIR=$2

# Validate inputs
if [ -z "$INPUT_YAML" ] || [ -z "$OUTPUT_DIR" ]; then
    echo "Error: Missing arguments"
    echo "Usage: $0 <input_yaml_file> <output_directory>"
    exit 1
fi

if [ ! -f "$INPUT_YAML" ]; then
    echo "Error: Input file $INPUT_YAML does not exist"
    exit 1
fi

if [ ! -d "$OUTPUT_DIR" ]; then
    echo "Error: Output directory $OUTPUT_DIR does not exist"
    exit 1
fi

# Extract parameters from YAML (simple parsing)
echo "Running simulation with input: $INPUT_YAML"
echo "Output directory: $OUTPUT_DIR"

# Do the simulation work here vvv
##########################################
# REPLACE THIS WITH ACTUAL SIMULATION CODE
module load anaconda
python do_simulation_stuff.py --input_yaml "$INPUT_YAML" --output_dir "$OUTPUT_DIR"
##########################################

# Create an info file
echo "Simulation completed at $(date)" > "$OUTPUT_DIR/info.txt"
echo "Input file: $INPUT_YAML" >> "$OUTPUT_DIR/info.txt"
cat "$INPUT_YAML" >> "$OUTPUT_DIR/info.txt"

echo "Simulation completed successfully!"
