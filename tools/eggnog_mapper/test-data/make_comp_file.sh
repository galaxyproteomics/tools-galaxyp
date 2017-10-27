#!/bin/bash

base_path=$1

emapper.py \
    -i $base_path/test-data/nlim_fragment.fasta \
    --output HMM_nlim \
    --output_dir $base_path/test-data \
    --override \
    --database $base_path/test-data/cached_locally/hmmdb_levels/ENOG411CB2I/ENOG411CB2I \
    --data_dir $base_path/test-data/cached_locally \
    --no_refine\
    --no_annot \
    --no_file_comments

emapper.py \
    -i $base_path/test-data/nlim_fragment.fasta \
    --output DIA_nlim \
    --output_dir $base_path/test-data \
    --override \
    -m diamond \
    --data_dir $base_path/test-data/cached_locally \
    --no_file_comments \
    --no_annot
