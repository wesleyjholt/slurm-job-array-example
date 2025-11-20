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

- `run_simulation.sh` - Invokes the transfer helper for each manifest chunk
- `compress_pull_extract.py` - Parses the YAML, compresses remote files, pulls them locally, and extracts
- `slurm_defaults.txt` - Example SLURM config
- `inputs/` - Example input manifests (update with your connection details and manifest paths)

## Configuring Remote Transfers

Each `inputs/input_XXXX.yaml` describes one batch of files to transfer. Provide the connection
metadata plus the path to the manifest (a plain text file with one absolute remote file path per
line). Example:

```
hostname: data.example.com
username: demo
key_filename: ~/.ssh/id_demo
file_list: ../manifests/run_0001.txt
archive_basename: run_0001.tar.gz    # optional
keep_archive: false                  # optional
remote_archive_dir: /home/demo/.remote_transfer_archives  # optional (where temp tars live)
```

After updating the manifests and YAML inputs, run `bash do_demo_setup.sh` (or directly call
`src/setup.sh`) to create the grouped inputs and submit the generated job file with `sbatch`.
