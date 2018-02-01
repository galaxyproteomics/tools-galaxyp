#!/bin/bash

# must be run from inside test-data

# tests splitting by line
# makes files test_0.tabular and test_1.tabular
python3 ../split_file_to_collection.py \
    -i test.tabular \
    --ftype tabular \
    --by row \
    --numnew 2 \
    -o test_out \
    -a 'test' \
    -e 'tabular' \
    -t 2

# splitting by column
# makes files foo.tab, foo2.tab, and foo3.tab
python3 ../split_file_to_collection.py \
    -i test.tabular \
    -f tabular \
    -c 1 \
    --by col \
    -m '(.*)\.mgf' \
    -s '\1.tab' \
    -o test_out \
    -t 2

# cat test_out/foo*.tab

# peptide shaker, splitting by column
python3 ../split_file_to_collection.py \
    -i psm.tabular \
    -f tabular \
    -c 10 \
    --by col \
    -m '(.*)\.mgf' \
    -s '\1.tab' \
    -o test_out \
    -t 1

# head test_out/file*.tab

# mgf test
python3 ../split_file_to_collection.py \
    -i demo758Dacentroid.mgf \
    --ftype mgf \
    --numnew 3 \
    -o test_out \
    -a demo \
    -e mgf

# fasta test
python3 ../split_file_to_collection.py \
    -i test.fasta \
    --ftype fasta \
    --numnew 2 \
    -o test_out \
    -a test \
    -e fasta

# fastq test
python3 ../split_file_to_collection.py \
    -i test.fastq \
    --ftype fastq \
    --numnew 2 \
    -o test_out \
    -a test \
    -e fastq

# random test
python3 ../split_file_to_collection.py \
    -i test.fasta \
    --ftype fasta \
    --numnew 2 \
    --rand \
    -x 1010 \
    -o test_out \
    -a rand \
    -e fasta

