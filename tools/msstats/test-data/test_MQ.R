library('MSstats', warn.conflicts = F, quietly = T, verbose = F)

proteinGroups <- read.delim(file="test_MQ_evidence.tabular")
infile <- read.delim(file="test_MQ_proteingroups.tabular")
annot <- read.delim(file="test_MQ_group12_comparison_matrix.txt")


## conversion of file
quant <- MaxQtoMSstatsFormat(evidence=infile, annotation=annot, 
                             proteinGroups=proteinGroups,
                             removeProtein_with1Peptide=FALSE)

## maxquant default processing: 
maxquant.proposed <- dataProcess(quant,
                                 normalization='equalizeMedians',
                                 summaryMethod="TMP",
                                 cutoffCensored="minFeature",
                                 censoredInt="NA", ## !! important for MaxQuant
                                 MBimpute=TRUE,
                                 maxQuantileforCensored=0.999)

## rename to not have to change the next lines of code

DDA2009.proposed = maxquant.proposed
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

DDA2009.TMP <- dataProcess(raw = DDARawData,
                           normalization = 'equalizeMedians',
                           summaryMethod = 'TMP',
                           censoredInt = NULL, MBimpute=FALSE)

## reading in tabular file from user with comparison matrix and comparison names: 
comp_matrix = read.delim(file="test_MQ_group12_comparison_matrix.txt", header=FALSE, sep="\t")
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

# heatmap - only works with more than 1 comparison
#groupComparisonPlots(data = DDA2009.comparisons$ComparisonResult, type = 'Heatmap')

#comparison
groupComparisonPlots(data=DDA2009.comparisons$ComparisonResult, type="ComparisonPlot",
                     width=5, height=5, address="DDA2009_proposed_")

## quantification
# summarized intensities per protein and per sample
subQuant <- quantification(DDA2009.proposed,  type="Sample")
head(subQuant)
# summarized intensities per protein and per group
groupQuant <- quantification(DDA2009.proposed, type='group')
head(groupQuant)


## also if matrix or long format: 
quantification(DDA2009.proposed, type="Sample", format="long")


