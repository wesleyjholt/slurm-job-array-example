# Slurm Job Array Framework

This directory contains the reusable framework scripts for setting up Slurm job arrays.

## Files

### `setup.sh`
Main entry point. Run this script to set up your job array.

**Usage:**
```bash
bash src/setup.sh <run_simulation_script> <slurm_defaults_file> <inputs_folder> <sims_per_job> <prefix>
```

**What it does:**
- Groups input files into jobs
- Creates output directories
- Calls `generate_job_file.sh` to create the submission script

### `generate_job_file.sh`
Internal script called by `setup.sh` to generate the job array submission file.

**What it does:**
- Adds default `--output` and `--error` directives (unless overridden by user)
- Reads the provided SLURM defaults file
- Creates a `{prefix}run.sh` file with the job array logic
- Makes the job file executable

**Default logging:**
- Automatically adds: `#SBATCH --output=logs/job_%A_%a.out`
- Automatically adds: `#SBATCH --error=logs/job_%A_%a.err`
- These can be overridden by including `--output` or `--error` in your slurm defaults file

### `slurm_defaults.template.txt`
Template file for SLURM settings.

**Usage:**
1. Copy to your project directory: `cp src/slurm_defaults.template.txt slurm_defaults.txt`
2. Customize time, memory, CPUs, and other SLURM settings
3. The `generate_job_file.sh` script will read your customized version

## How to Use

1. Copy this `src/` directory to your project
2. Create a simulation script that accepts: `<input_yaml> <output_dir>`
3. Copy and customize `slurm_defaults.template.txt` to `slurm_defaults.txt` in your project
4. Create input YAML files (named `input_XXXX.yaml`)
5. Run `bash src/setup.sh <sim_script> <slurm_defaults> <inputs_dir> <sims_per_job> <prefix>`
6. Submit with `sbatch {prefix}run.sh`

See the `../example/` directory for a complete working example.
