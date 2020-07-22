if (!requireNamespace("BiocManager", quietly = TRUE))
  install.packages("BiocManager")
BiocManager::install("MSstats")

library('MSstats', warn.conflicts = F, quietly = T, verbose = F)

## starting point 4 (page 12)
DDARawData <- read.csv("msstats_testfile.txt")

dim(DDARawData) # 2070, 10

## default preprocessing: 
DDA2009.proposed <- dataProcess(raw = DDARawData,
                                normalization = 'equalizeMedians',
                                summaryMethod = 'TMP',
                                censoredInt = "NA",
                                cutoffCensored = "minFeature",
                                MBimpute = TRUE,
                                maxQuantileforCensored=0.999)
class(DDA2009.proposed) # list of 5
head(DDA2009.proposed$ProcessedData) # tabular file
dim(DDA2009.proposed$ProcessedData) ## 2070, 16
head(DDA2009.proposed$RunlevelData) # tabular file
dim(DDA2009.proposed$RunlevelData) # 107, 13
head(DDA2009.proposed$SummaryMethod) # string with input option, not needed in GAlaxy
head(DDA2009.proposed$ModelQC) # NULL, not sure when this will be needed
head(DDA2009.proposed$PredictBySurvival) # NULL, not sure when this will be needed

## dataprocess visualizations

dataProcessPlots(data = DDA2009.proposed, type="QCplot", ylimUp=35,
                 width=5, height=5)
## automatically generates a pdf output, one boxplot for all proteins and then one per protein !

dataProcessPlots(data = DDA2009.proposed, type="Profileplot", ylimUp=35,
                 featureName="NA", width=5, height=5, address="DDA2009_proposed_")
## automatically generates 2 pdf outputs, with and without sum

dataProcessPlots(data = DDA2009.proposed, type="Conditionplot",
                 width=5, height=5, address="DDA2009_proposed_")

DDA2009.inf <- dataProcess(raw = DDARawData,
                           normalization = 'equalizeMedians',
                           summaryMethod = 'TMP',
                           featureSubset = "highQuality",
                           remove_uninformative_feature_outlier = TRUE)

dim(DDA2009.inf$ProcessedData)##2070,18
names(DDA2009.inf$ProcessedData) ## adds column: featurequality, is_outlier
names(DDA2009.proposed$ProcessedData)

## --> maybe no repeat function is needed and all can be done at once :) 

DDA2009.linear <- dataProcess(raw = DDARawData,
                              normalization = 'equalizeMedians',
                              summaryMethod = 'linear',
                              censoredInt = NULL,
                              MBimpute = FALSE)
dim(DDA2009.linear$ProcessedData) # 2070, 15; is missing censored column compared to default

## --> again, seems not to be necessary to have repeat :) 

DDA2009.TMP <- dataProcess(raw = DDARawData,
                           normalization = 'equalizeMedians',
                           summaryMethod = 'TMP',
                           censoredInt = NULL, MBimpute=FALSE)
dim(DDA2009.TMP$ProcessedData) # 2070, 15

## reading in tabular file from user with comparison matrix and comparison names: 
comp_matrix = read.delim(file="comparison_matrix.txt", header=FALSE, sep="\t")
comparison = as.matrix(comp_matrix[,-1])
row.names(comparison) = as.character(comp_matrix[,1])

DDA2009.comparisons <- groupComparison(contrast.matrix = comparison, data = DDA2009.proposed)

head(DDA2009.comparisons$ComparisonResult) # tabular
head(DDA2009.comparisons$ModelQC) # tabular
class(DDA2009.comparisons$fittedmodel) # list, probably good to output this somehow

## Visualizations: 

# normal quantile-quantile plots
modelBasedQCPlots(data=DDA2009.comparisons, type="QQPlots",
                  width=5, height=5, address="DDA2009_proposed_")

# residual plots
modelBasedQCPlots(data=DDA2009.comparisons, type="ResidualPlots",
                  width=5, height=5, address="DDA2009_proposed_")
# volcano plot
groupComparisonPlots(data = DDA2009.comparisons$ComparisonResult, type = 'VolcanoPlot',
                     width=5, height=5, address="DDA2009_proposed_")
# heatmap
groupComparisonPlots(data = DDA2009.comparisons$ComparisonResult, type = 'Heatmap')

#comparison
groupComparisonPlots(data=DDA2009.comparisons$ComparisonResult, type="ComparisonPlot",
                     width=5, height=5, address="DDA2009_proposed_")

## quantification
# summarized intensities per protein and per sample
subQuant <- quantification(DDA2009.proposed,  type="Sample")
head(subQuant)
dim(subQuant)
# summarized intensities per protein and per group
groupQuant <- quantification(DDA2009.proposed, type='group')
head(groupQuant)
dim(groupQuant)

## also if matrix or long format: 
quantification(DDA2009.proposed, type="Sample", format="long")
