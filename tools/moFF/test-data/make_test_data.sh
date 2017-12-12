#!/bin/bash

moff=$1
output=$2

source activate moff

$moff/moff_all.py --inputtsv input/mbr_test1.tabular input/mbr_test2.tabular \
    --inputraw input/mbr_test1.mzml input/mbr_test2.mzml \
    --tol 10 \
    --rt_w 3 \
    --rt_p 1 \
    --rt_p_match 1.2 \
    --peptide_summary 1 \
    --output_folder $output/output1
mv $output/output1/peptide_summary_intensity_moFF_run.tab $output/output1/moff_mbr_test_pepsum.tab

$moff/moff.py --inputtsv input/test.tabular \
    --inputraw input/test.mzml \
    --tol 10 \
    --rt_w 3 \
    --rt_p 1 \
    --rt_p_match 1.2 \
    --peptide_summary 1 \
    --output_folder $output/output2
mv $output/output2/peptide_summary_intensity_moFF_run.tab $output/output2/moff_test_pepsum.tab


