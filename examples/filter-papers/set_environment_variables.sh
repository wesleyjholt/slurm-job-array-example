#!/bin/bash

export REMOTE_USERNAME=holtw
export REMOTE_HOSTNAME=gautschi.rcac.purdue.edu
export REMOTE_KEY_FILENAME=~/.ssh/id_rsa
export MOVE_CHUNK_SIZE=5000  # Number of remote files per chunk
export MOVE_SIMS_PER_JOB=1   # Number of chunks per SLURM job
export FILTER_CHUNK_SIZE=100  # Number of files per chunk
export FILTER_SIMS_PER_JOB=2  # Number of chunks per SLURM job