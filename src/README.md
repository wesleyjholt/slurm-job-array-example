# Framework Scripts

Reusable scripts for setting up Slurm job arrays.

## Usage

```bash
bash src/setup.sh <sim_script> <slurm_defaults> <inputs_dir> <sims_per_job> <prefix>
```

## Files

- **`setup.sh`** - Main script: groups inputs, creates directories, generates job file
- **`generate_job_file.sh`** - Internal: creates the job array submission script
- **`slurm_defaults.template.txt`** - Template for your `#SBATCH` directives

## Notes

- Automatically adds default log directives: `--output=logs/job_%A_%a.out` and `--error=logs/job_%A_%a.err`
- Override by including `--output` or `--error` in your slurm defaults file
- See `../example/` for usage
