library(DIAlignR)

args <- commandArgs(trailingOnly = FALSE)

data_path <- paste0(args[7], "/data/")
runs_file_path <- paste0(args[7], "/runs.txt")

runs <- scan(runs_file_path, what = "", sep = "\n")

alignTargetedRuns(dataPath = data_path,
                  outFile = "alignedTargetedRuns.csv",
                  runs = runs,
                  oswMerged = TRUE)