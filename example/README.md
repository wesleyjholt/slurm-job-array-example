# Example: Slurm Job Array Usage

This directory demonstrates how to use the job array framework.

## Files

- **`run_simulation.sh`** - Example simulation script
- **`do_simulation_stuff.py`** - Example Python simulation code
- **`run_example.sh`** - Quick demo script that sets up everything
- **`slurm_defaults.txt`** - Example SLURM configuration
- **`inputs/`** - Example input YAML files (input_0001.yaml, etc.)

## Running the Example

```bash
cd example/
bash run_example.sh
```

This will:
1. Find all input YAML files in `inputs/`
2. Group them into jobs (3 simulations per job by default)
3. Create `demo_grouped_input_paths/` and `demo_outputs/`
4. Generate `demo_run.sh` job file

Then submit:
```bash
sbatch demo_run.sh
```

## Customizing for Your Project

1. Replace `run_simulation.sh` with your own simulation script
2. Replace `do_simulation_stuff.py` with your simulation code
3. Update `slurm_defaults.txt` with your SLURM requirements
4. Create your own input YAML files in `inputs/`
5. Adjust `SIMS_PER_JOB` in `run_example.sh`

Or copy the `src/` directory to your own project and follow the main README.
