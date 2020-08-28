#!/bin/bash
# wl-01-11-2017, Wed: Rscript test code for Linux
# wl-25-03-2019, Mon: add output directory
# wl-20-08-2020, Thu: use small data set

Rscript --vanilla ../masspix.R \
  --imzML_file "../test-data/cut_masspix.imzML" \
  --process TRUE \
  --rem_outliers TRUE \
  --summary TRUE \
  --rdata TRUE\
  --pca TRUE \
  --loading TRUE \
  --slice TRUE \
  --clus TRUE\
  --intensity TRUE\
  --image_out "../test-data/res/image.tsv"\
  --rdata_out "../test-data/res/r_running.rdata"\
  --pca_out "../test-data/res/pca.pdf"\
  --loading_out "../test-data/res/loading.tsv"\
  --slice_out "../test-data/res/slice.pdf"\
  --clus_out "../test-data/res/clus.pdf"\
  --intensity_out "../test-data/res/intensity.tsv"
