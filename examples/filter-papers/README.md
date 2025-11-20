## To transfer files from remote to local

### Step 1:
Set the required environment variables:
```bash
export REMOTE_USERNAME=your_username  # e.g., your university cluster account username
export REMOTE_HOSTNAME=your.remote.hostname  # e.g., gilbreth.rcac.purdue.edu
export REMOTE_KEY_FILENAME=/path/to/your/ssh_key  # e.g., ~/.ssh/id_rsa
export MOVE_CHUNK_SIZE=5000  # Number of remote files per chunk
export MOVE_SIMS_PER_JOB=1   # Number of chunks per SLURM job
```

### Step 2:
Add the remote directory paths containing the files to `move/remote_dirs.txt`, one per line:
```bash
# remote_dirs.txt
/path/to/remote/dir1
/path/to/remote/dir2
/path/to/remote/dir3
```

### Step 3:
Then `cd` into the `move` directory and run the driver script to transfer the files:
```bash
cd move
bash set_up_and_submit_job_array.sh
```

### Step 4:
Allow the jobs to complete, then verify that the files have been transferred to `move/transferred_files/`.

## To filter the transferred files for keywords

### Step 1:
Set the required environment variables:
```bash
export FILTER_CHUNK_SIZE=100  # Number of files per chunk for filtering
export FILTER_SIMS_PER_JOB=1   # Number of chunks per SLURM job
```

### Step 2:
Then `cd` into the `filter` directory and run the driver script to filter the files:
```bash
cd filter
bash set_up_and_submit_job_array.sh
```

### Step 3:
Allow the jobs to complete. The filtered files will be spread across different subdirectories within the `keyword_outputs` directory.

### Step 4:
Run the provided aggregation script to combine the filtered results into a single directory:
```bash
merge_filtered_files.sh
```

This will create:

- `merged_filtered_files.txt`: A single text file containing all filtered file names.
- `merged_stats.txt`: A summary statistics file for all the filtered results.