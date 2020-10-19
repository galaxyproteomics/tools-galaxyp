#!/bin/bash

base_path=$1

emapper.py \
    -i $base_path/test-data/nlim_fragment.fasta \
    --output DIA_nlim \
    --output_dir $base_path/test-data \
    --override \
    -m diamond \
    --data_dir $base_path/test-data/cached_locally \
    --no_file_comments \
    --no_annot
