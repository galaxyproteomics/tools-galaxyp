## cut openswath data: 6 proteins from 6 files from 2 groups

library('MSstats', warn.conflicts = F, quietly = T, verbose = F)

raw <- read.delim("Galaxy16-[Select_on_data_10].tabular")

annot = read.delim(file="Galaxy11-[Select_on_data_9].tabular")

quant <- OpenSWATHtoMSstatsFormat(raw,
                                  annotation = annot,
                                  filter_with_mscore = TRUE, ## same as default
                                  mscore_cutoff = 0.01, ## same as default
                                  removeProtein_with1Feature = TRUE)

## swath preprocessing: 
goldstandard.proposed <- dataProcess(quant,
                                     normalization='equalizeMedians',
                                     summaryMethod="TMP",
                                     cutoffCensored="minFeature",
                                     censoredInt="0",
                                     MBimpute=TRUE,
                                     maxQuantileforCensored=0.999)

head(goldstandard.proposed$ProcessedData) # tabular file

## dataprocess visualizations

## rename file name so that the old code works without renaming: 
DDA2009.proposed = goldstandard.proposed

dataProcessPlots(data = DDA2009.proposed, type="QCplot", ylimUp=35,
                 width=5, height=5)

## automatically generates a pdf output, one boxplot for all proteins and then one per protein !

dataProcessPlots(data = DDA2009.proposed, type="Profileplot", ylimUp=35,
                 featureName="NA", width=5, height=5, address="DDA2009_proposed_")
## automatically generates 2 pdf outputs, with and without sum

dataProcessPlots(data = DDA2009.proposed, type="Conditionplot",
                 width=5, height=5, address="DDA2009_proposed_")

DDA2009.TMP <- dataProcess(raw = quant,
                           normalization = 'equalizeMedians',
                           summaryMethod = 'TMP',
                           censoredInt = NULL, MBimpute=FALSE)
dim(DDA2009.TMP$ProcessedData) # 252, 15

## reading in tabular file from user with comparison matrix and comparison names: 
comp_matrix = read.delim(file="test_group12_comparison_matrix.txt", header=FALSE, sep="\t")

comparison = as.matrix(comp_matrix[,-1])
row.names(comparison) = as.character(comp_matrix[,1])

DDA2009.comparisons <- groupComparison(contrast.matrix = comparison, data = DDA2009.proposed)

head(DDA2009.comparisons$ComparisonResult) # tabular
head(DDA2009.comparisons$ModelQC) # tabular
head(DDA2009.comparisons$fittedmodel) # list, probably good to output this somehow

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

# heatmap - works only for more than 1 comparison
##groupComparisonPlots(data = DDA2009.comparisons$ComparisonResult, type = 'Heatmap')

#comparison
groupComparisonPlots(data=DDA2009.comparisons$ComparisonResult, type="ComparisonPlot",
                     width=5, height=5, address="DDA2009_proposed_")

## quantification
# summarized intensities per protein and per sample
subQuant <- quantification(DDA2009.proposed,  type="Sample")

# summarized intensities per protein and per group
groupQuant <- quantification(DDA2009.proposed, type='group')



