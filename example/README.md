# Example Usage

Demo of the job array framework.

## Quick Start

```bash
bash do_demo_setup.sh
sbatch demo_run.sh
```

## What It Does

Groups 10 input YAML files into 4 jobs (3 simulations per job) and creates:

```
demo_grouped_input_paths/
  input_group_0001.txt  # Job 1: sims 1-3
  input_group_0002.txt  # Job 2: sims 4-6
  input_group_0003.txt  # Job 3: sims 7-9
  input_group_0004.txt  # Job 4: sim 10
demo_outputs/
  output_0001/ ... output_0010/
demo_run.sh             # Submit with: sbatch demo_run.sh
```

## Files

- `run_simulation.sh` - Example simulation script
- `do_simulation_stuff.py` - Example simulation code
- `slurm_defaults.txt` - Example SLURM config
- `inputs/` - Example input files
