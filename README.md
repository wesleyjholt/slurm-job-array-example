# Slurm Job Array Example

This example demonstrates how to use Slurm job arrays to run multiple simulations with different input parameters.

## Directory Structure

```
job_array_example/
├── README.md
├── src/                              # Framework code (reusable)
│   ├── setup.sh                      # Main setup script
│   ├── generate_job_file.sh          # Job file generator (called by setup.sh)
│   └── slurm_defaults.template.txt   # Template for SLURM settings
└── example/                          # Example usage
    ├── run_simulation.sh             # Example simulation script
    ├── do_simulation_stuff.py        # Example simulation code
    ├── run_example.sh                # Quick demo script
    ├── slurm_defaults.txt            # Example SLURM settings
    └── inputs/                       # Example input files
        ├── input_0001.yaml
        └── ...
```

## Overview

The workflow consists of:
- **Framework scripts** (`src/`): Reusable code for setting up job arrays
- **Simulation script**: Your custom script that runs a single simulation
- **Input files**: YAML files containing simulation parameters
- **SLURM defaults**: Your custom SLURM settings (time, memory, CPUs, etc.)

## Quick Start

```bash
cd example/
bash run_example.sh
# Then submit: sbatch demo_run.sh
```

## Workflow

### Step 1: Set Up Your Project

1. Copy the framework scripts:
   ```bash
   cp -r src/ my_project/
   ```

2. Create your simulation script (e.g., `run_simulation.sh`) that takes:
   - Argument 1: Path to input YAML file
   - Argument 2: Path to output directory

3. Copy and customize SLURM settings:
   ```bash
   cp src/slurm_defaults.template.txt my_project/slurm_defaults.txt
   # Edit slurm_defaults.txt to set time, memory, CPUs, etc.
   ```

4. Create input YAML files in an `inputs/` folder:
   ```
   inputs/input_0001.yaml
   inputs/input_0002.yaml
   ...
   ```

### Step 2: Run Setup

From your project directory:

```bash
bash src/setup.sh <run_simulation_script> <slurm_defaults_file> <inputs_folder> <sims_per_job> <prefix>
```

**Arguments:**
- `<run_simulation_script>` - path to the simulation script (e.g., `run_simulation.sh`)
- `<slurm_defaults_file>` - path to your SLURM settings file (e.g., `slurm_defaults.txt`)
- `<inputs_folder>` - path to the folder containing input YAML files (e.g., `inputs/`)
- `<sims_per_job>` - number of simulations to run in each job (e.g., 2)
- `<prefix>` - prefix for created folders (e.g., "test_")

**Example:**
```bash
cd my_project/
bash src/setup.sh run_simulation.sh slurm_defaults.txt inputs/ 2 test_
```

This will:
- Create `test_grouped_input_paths/` folder with `input_group_XXXX.txt` files
- Create `test_outputs/` folder with `output_XXXX/` subdirectories
- Generate the job file `test_run.sh`
- Display the command to submit the job

### Step 3: Submit to Slurm

```bash
sbatch test_run.sh
```

## Complete Example

See the `example/` directory for a working demonstration:

```bash
cd example/
bash run_example.sh        # Sets up with 3 simulations per job
sbatch demo_run.sh         # Submit the generated job
```

## Files Created

After running setup.sh:
- `{prefix}grouped_input_paths/input_group_0001.txt` - paths to inputs for job 1
- `{prefix}grouped_input_paths/input_group_0002.txt` - paths to inputs for job 2
- `{prefix}outputs/output_0001/` - output directory for simulation 1
- `{prefix}outputs/output_0002/` - output directory for simulation 2
- `{prefix}run.sh` - the job array script (ready to submit)
- `logs/job_<jobid>_<taskid>.out` - stdout logs (created after job runs)
- `logs/job_<jobid>_<taskid>.err` - stderr logs (created after job runs)
- `logs/job_<jobid>_<taskid>.err` - stderr logs

## Customization

### Modify SLURM Defaults

Edit your project's `slurm_defaults.txt` to change SLURM settings:
```bash
#SBATCH --time=01:00:00
#SBATCH --mem=4G
#SBATCH --cpus-per-task=1
#SBATCH --partition=gpu
#SBATCH --account=your-account
```

**Note:** The framework automatically adds default log file directives:
- `#SBATCH --output=logs/job_%A_%a.out`
- `#SBATCH --error=logs/job_%A_%a.err`

You can override these by including your own `--output` and `--error` directives in your `slurm_defaults.txt` file.
#SBATCH --output=logs/job_%A_%a.out
#SBATCH --error=logs/job_%A_%a.err
```

### Modify Simulation Script

Edit your `run_simulation.sh` (or equivalent) to implement your actual simulation logic.
It must accept two arguments:
1. Path to input YAML file
2. Path to output directory

## Slurm Variables Used

- `$SLURM_JOB_ID` - Job ID
- `$SLURM_ARRAY_TASK_ID` - Array task ID (1 to NUM_JOBS)
- `%A` - Job array master job ID
- `%a` - Job array index
