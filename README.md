# Slurm Job Array Example

A simple framework for running many simulations as Slurm job arrays.

## Quick Start

```bash
cd example/
bash do_demo_setup.sh
sbatch demo_run.sh
```

## Usage

```bash
bash src/setup.sh <simulation_script> <slurm_defaults> <inputs_dir> <sims_per_job> <prefix>
```

**Example:**
```bash
bash src/setup.sh run_sim.sh slurm_defaults.txt inputs/ 5 myrun_
sbatch myrun_run.sh
```

***Interpretation:*** 
"Setup a job array where:"
- there are (at most) 5 simulations per job
- a single simulation can be run with `bash run_sim.sh <input.yaml> <output_dir>`
- the SLURM directives are taken from `slurm_defaults.txt`
- input files are taken from the `inputs/` directory
- this simulation setup is given the unique id "myrun_"

## What You Need

1. **Simulation script** - Takes 2 arguments: `<input.yaml>` `<output_dir>`
2. **SLURM defaults file** - Your `#SBATCH` directives (copy from `src/slurm_defaults.template.txt`)
3. **Input files** - YAML files named `input_0001.yaml`, `input_0002.yaml`, etc.

## What It Creates

```
myrun_grouped_input_paths/    # Lists of inputs for each job
  input_group_0001.txt
  input_group_0002.txt
myrun_outputs/                 # Output directories
  output_0001/
  output_0002/
myrun_run.sh                   # Job array script (ready to submit)
logs/                          # Created when jobs run
  job_<id>_<task>.out
  job_<id>_<task>.err
```

## Notes

- Output/error logs default to `logs/job_%A_%a.out` and `logs/job_%A_%a.err`
- Override by adding `#SBATCH --output` and `#SBATCH --error` to your slurm defaults file
- See `example/` directory for a complete working demo
