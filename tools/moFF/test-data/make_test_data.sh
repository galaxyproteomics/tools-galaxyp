#!/bin/bash

#must be run within tools-galaxyp/tools/moFF/test-data

conda create -n mofftestdata moff
source activate mofftestdata

moff_all.py --inputtsv input/mbr_test1.tabular input/mbr_test2.tabular \
    --inputraw input/mbr_test1.mzml input/mbr_test2.mzml \
    --tol 10 \
    --rt_w 3 \
    --rt_p 1 \
    --rt_p_match 1.2 \
    --peptide_summary 1 \
    --output_folder output1

moff.py --inputtsv input/test.tabular \
    --inputraw input/test.mzml \
    --tol 10 \
    --rt_w 3 \
    --rt_p 1 \
    --rt_p_match 1.2 \
    --peptide_summary 1 \
    --output_folder output2
mv output2/peptide_summary_intensity_moFF_run.tab output2/moff_test_pepsum.tab

moff_mbr.py \
    --inputF input \
    --ext tabular \
    --sample mbr_*


# clean up 
# mbr outputs for moff all
rm -r output1/mbr_output

# logs
rm output1/*.log output2/*.log

# peptide summary for all
rm output1/peptide_summary_intensity_moFF_run.tab
