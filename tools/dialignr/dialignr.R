library(DIAlignR)

## Parse command line arguments
args <- commandArgs(trailingOnly = TRUE)

hh <- paste(unlist(args),collapse=' ')
listoptions <- unlist(strsplit(hh,'--'))[-1]
options.args <- sapply(listoptions,function(x){
                  unlist(strsplit(x, ' '))[-1]
                })
options.names <- sapply(listoptions,function(x){
                  option <- unlist(strsplit(x, ' '))[1]
                })
names(options.args) <- unlist(options.names)
##

data_path <- paste0(options.args["pwd"], "/data/")
runs_file_path <- paste0(options.args["pwd"], "/runs.txt")

runs <- readLines(runs_file_path)

alignTargetedRuns(dataPath = data_path,
                  outFile = "alignedTargetedRuns.csv",
                  runs = runs,
                  oswMerged = as.logical(options.args["oswMerged"]),
                  maxFdrQuery = as.numeric(options.args["maxFdrQuery"]),
                  XICfilter = options.args["XICfilter"],
                  polyOrd = as.integer(options.args["polyOrd"]),
                  kernelLen = as.integer(options.args["kernelLen"]),
                  globalAlignment = options.args["globalAlignment"],
                  globalAlignmentFdr = as.numeric(options.args["globalAlignmentFdr"]),
                  globalAlignmentSpan = as.numeric(options.args["globalAlignmentSpan"]),
                  RSEdistFactor = as.numeric(options.args["RSEdistFactor"]),
                  normalization = options.args["normalization"],
                  simMeasure = options.args["simMeasure"],
                  alignType = options.args["alignType"],
                  goFactor = as.numeric(options.args["goFactor"]),
                  geFactor = as.numeric(options.args["geFactor"]),
                  cosAngleThresh = as.numeric(options.args["cosAngleThresh"]),
                  OverlapAlignment = as.logical(options.args["OverlapAlignment"]),
                  dotProdThresh = as.numeric(options.args["dotProdThresh"]),
                  gapQuantile = as.numeric(options.args["gapQuantile"]),
                  hardConstrain = as.logical(options.args["hardConstrain"]),
                  samples4gradient = as.numeric(options.args["samples4gradient"]),
                  analyteFDR = as.numeric(options.args["analyteFDR"]),
                  unalignedFDR = as.numeric(options.args["unalignedFDR"]),
                  alignedFDR = as.numeric(options.args["alignedFDR"]),
                  baselineType = options.args["baselineType"],
                  integrationType = options.args["integrationType"],
                  fitEMG = as.logical(options.args["fitEMG"]),
                  recalIntensity = as.logical(options.args["recalIntensity"]),
                  fillMissing = as.logical(options.args["fillMissing"]),
                  smoothPeakArea = as.logical(options.args["smoothPeakArea"])
)
