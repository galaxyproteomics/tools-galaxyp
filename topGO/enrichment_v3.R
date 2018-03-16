# enrichment_v3.R
# Usage : Rscript --vanilla enrichment_v3.R --inputtype tabfile (or
# copypaste) --input file.txt --ontology "BP/CC/MF" --option option (e.g
# : classic/elim...) --threshold threshold --correction correction --textoutput
# text --barplotoutput barplot
# --dotplotoutput dotplot --column column --geneuniver human 
# e.g : Rscript --vanilla enrichment_v3.R --inputtype tabfile --input file.txt
# --ontology BP --option classic --threshold 1e-15 --correction holm
# --textoutput TRUE
# --barplotoutput TRUE --dotplotoutput TRUE --column c1 --geneuniverse
# org.Hs.eg.db
# INPUT :
# - type of input. Can be ids separated by a blank space (copypast), or a text
# file (tabfile)
#	- file with at least one column of ensembl ids 
#	- gene ontology category : Biological Process (BP), Cellular Component (CC), Molecular Function (MF)
#	- test option (relative to topGO algorithms) : elim, weight01, parentchild, or no option (classic)
#	- threshold for enriched GO term pvalues (e.g : 1e-15)     
#	- correction for multiple testing (see p.adjust options : holm, hochberg, hommel, bonferroni, BH, BY,fdr,none
#	- outputs wanted in this order text, barplot, dotplot with boolean value (e.g
#	: TRUE TRUE TRUE ).
#	Declare the output not wanted as none
#	- column containing the ensembl ids if the input file is a tabfile
# - gene universe reference for the user chosen specie
# - header : if the input is a text file, does this text file have a header
# (TRUE/FALSE)
#
# OUTPUT :
#	- outputs commanded by the user named respectively result.tsv for the text
#	results file, barplot.png for the barplot image file and dotplot.png for the
#	dotplot image file 


# loading topGO library
library(topGO)

# Read file and return file content as data.frame
readfile = function(filename, header) {
  if (header == "true") {
    # Read only first line of the file as header:
    headers <- read.table(filename, nrows = 1, header = FALSE, sep = "\t", stringsAsFactors = FALSE, fill = TRUE, na.strings=c("", "NA"), blank.lines.skip = TRUE, quote = "")
    #Read the data of the files (skipping the first row)
    file <- read.table(filename, skip = 1, header = FALSE, sep = "\t", stringsAsFactors = FALSE, fill = TRUE, na.strings=c("", "NA"), blank.lines.skip = TRUE, quote = "")
    # Remove empty rows
    file <- file[!apply(is.na(file) | file == "", 1, all), , drop=FALSE]
    #And assign the header to the data
    names(file) <- headers
  }
  else {
    file <- read.table(filename, header = FALSE, sep = "\t", stringsAsFactors = FALSE, fill = TRUE, na.strings=c("", "NA"), blank.lines.skip = TRUE, quote = "")
    # Remove empty rows
    file <- file[!apply(is.na(file) | file == "", 1, all), , drop=FALSE]
  }
  return(file)
} 

'%!in%' <- function(x,y)!('%in%'(x,y))


# Parse command line arguments

args = commandArgs(trailingOnly = TRUE)

# create a list of the arguments from the command line, separated by a blank space
hh <- paste(unlist(args),collapse=' ')

# delete the first element of the list which is always a blank space
listoptions <- unlist(strsplit(hh,'--'))[-1]

# for each input, split the arguments with blank space as separator, unlist,
# and delete the first element which is the input name (e.g --inputtype) 
options.args <- sapply(listoptions,function(x){
         unlist(strsplit(x, ' '))[-1]
        })
# same as the step above, except that only the names are kept
options.names <- sapply(listoptions,function(x){
  option <-  unlist(strsplit(x, ' '))[1]
})
names(options.args) <- unlist(options.names)


if (length(options.args) != 12) {
    stop("Not enough/Too many arguments", call. = FALSE)
}

typeinput = options.args[1]
listfile = options.args[2]
onto = as.character(options.args[3])
option = as.character(options.args[4])
correction = as.character(options.args[6])
threshold = as.numeric(options.args[5])
text = as.character(options.args[7])
barplot = as.character(options.args[8])
dotplot = as.character(options.args[9])
column = as.numeric(gsub("c","",options.args[10]))
geneuniverse = as.character(options.args[11])
header = as.character(options.args[12])

if (typeinput=="copypaste"){
  sample = as.data.frame(unlist(listfile))
  sample = sample[,column]
}
if (typeinput=="tabfile"){
  
  if (header=="TRUE"){
    sample = readfile(listfile, "true")  
  }else{
    sample = readfile(listfile, "false")
  }
  sample = sample[,column]

}
# Launch enrichment analysis and return result data from the analysis or the null
# object if the enrichment could not be done.
goEnrichment = function(geneuniverse,sample,onto){

	# get all the GO terms of the corresponding ontology (BP/CC/MF) and all their
  # associated ensembl ids according to the org package
	xx = annFUN.org(onto,mapping=geneuniverse,ID="ensembl")
	allGenes = unique(unlist(xx))
	# check if the genes given by the user can be found in the org package (gene
  # universe), that is in
	# allGenes 
	if (length(intersect(sample,allGenes))==0){
	
	    print("None of the input ids can be found in the org package data, enrichment analysis cannot be realized. \n The inputs ids probably have no associated GO terms.")
      return(c(NULL,NULL))
	
	}
	
	geneList = factor(as.integer(allGenes %in% sample)) 
	names(geneList) <- allGenes
	
	
	#topGO enrichment 
	
	
	# Creation of a topGOdata object
	# It will contain : the list of genes of interest, the GO annotations and the GO hierarchy
	# Parameters : 
	# ontology : character string specifying the ontology of interest (BP, CC, MF)
	# allGenes : named vector of type numeric or factor 
	# annot : tells topGO how to map genes to GO annotations.
	# argument not used here : nodeSize : at which minimal number of GO annotations
	# do we consider a gene  
	 
	myGOdata = new("topGOdata", description="SEA with TopGO", ontology=onto, allGenes=geneList,  annot = annFUN.org, mapping=geneuniverse,ID="ensembl")
	
	
	# Performing enrichment tests
	result <- runTest(myGOdata, algorithm=option, statistic="fisher")
  return(c(result,myGOdata))	
}

# Some libraries such as GOsummaries won't be able to treat the values such as
# "< 1e-30" produced by topGO. As such it is important to delete the < char
# with the deleteInfChar function. Nevertheless the user will have access to the original results in the text output.
deleteInfChar = function(values){

	lines = grep("<",values)
	if (length(lines)!=0){
		for (line in lines){
		  values[line]=gsub("<","",values[line])
		}
	}
	return(values)
}

corrMultipleTesting = function(result, myGOdata,correction,threshold){
	
	# adjust for multiple testing
	if (correction!="none"){	
	  # GenTable : transforms the result object into a list. Filters can be applied
	  # (e.g : with the topNodes argument, to get for instance only the n first
	  # GO terms with the lowest pvalues), but as we want to  apply a correction we
	  # take all the GO terms, no matter their pvalues 
	  allRes <- GenTable(myGOdata, test = result, orderBy = "result", ranksOf = "result",topNodes=length(attributes(result)$score))
    # Some pvalues given by topGO are not numeric (e.g : "<1e-30). As such, these
	  # values are converted to 1e-30 to be able to correct the pvalues 
    pvaluestmp = deleteInfChar(allRes$test)
	
	  # the correction is done from the modified pvalues  
	  allRes$qvalues = p.adjust(pvaluestmp, method = as.character(correction), n = length(pvaluestmp))
	  allRes = as.data.frame(allRes)

	  # Rename the test column by pvalues, so that is more explicit
	  nb = which(names(allRes) %in% c("test"))
	 
    names(allRes)[nb] = "pvalues"
	
	  allRes = allRes[which(as.numeric(allRes$pvalues) <= threshold),]
	  if (length(allRes$pvalues)==0){
		  print("Threshold was too stringent, no GO term found with pvalue equal or lesser than the threshold value")
      return(NULL)
	  }
	  allRes = allRes[order(allRes$qvalues),]
	}
	
	if (correction=="none"){
	  # get all the go terms under user threshold 
	  mysummary <- summary(attributes(result)$score <= threshold)
	  numsignif <- as.integer(mysummary[[3]])
	  # get all significant nodes 
	  allRes <- GenTable(myGOdata, test = result, orderBy = "result", ranksOf = "result",topNodes=numsignif)
	

	  allRes = as.data.frame(allRes)
	  # Rename the test column by pvalues, so that is more explicit
	  nb = which(names(allRes) %in% c("test"))
	  names(allRes)[nb] = "pvalues"
	  if (numsignif==0){
	
		  print("Threshold was too stringent, no GO term found with pvalue equal or lesser than the threshold value")
      return(NULL)
	  }
	
	 allRes = allRes[order(allRes$pvalues),] 
	} 

  return(allRes)  
}

# roundValues will simplify the results by rounding down the values. For instance 1.1e-17 becomes 1e-17
roundValues = function(values){
	for (line in 1:length(values)){
    		values[line]=as.numeric(gsub(".*e","1e",as.character(values[line])))
  }
  return(values)
}

createDotPlot = function(data, onto){
  
	values  = deleteInfChar(data$pvalues)
  values = roundValues(values)
  values = as.numeric(values)
	
  geneRatio = data$Significant/data$Annotated
	goTerms = data$Term
	count = data$Significant
  
	labely = paste("GO terms",onto,sep=" ")
	png(filename="dotplot.png",res=300, width = 3200, height = 3200, units = "px")
	sp1 = ggplot(data,aes(x=geneRatio,y=goTerms, color=values,size=count)) +geom_point() + scale_colour_gradientn(colours=c("red","violet","blue")) + xlab("Gene Ratio") + ylab(labely) + labs(color="p-values\n") 

	plot(sp1)
	dev.off()
}

createBarPlot = function(data, onto){

  
	values  = deleteInfChar(data$pvalues)
  values = roundValues(values)

  values = as.numeric(values)
  goTerms = data$Term
	count = data$Significant
	png(filename="barplot.png",res=300, width = 3200, height = 3200, units = "px")
	
	labely = paste("GO terms",onto,sep=" ")
  p<-ggplot(data, aes(x=goTerms, y=count,fill=values)) + ylab("Gene count") + xlab(labely) +geom_bar(stat="identity") + scale_fill_gradientn(colours=c("red","violet","blue")) + coord_flip() + labs(fill="p-values\n") 
	plot(p)
	dev.off()
}


# Produce the different outputs
createOutputs = function(result, cut_result,text, barplot, dotplot, onto){


  if (is.null(result)){
    
	  if (text=="TRUE"){

      err_msg = "None of the input ids can be found in the org package data, enrichment analysis cannot be realized. \n The inputs ids probably either have no associated GO terms or are not ENSG identifiers (e.g : ENSG00000012048)."
      write.table(err_msg, file='result.csv', quote=FALSE, sep='\t', col.names = T, row.names = F)
	  
    }

	  if (barplot=="TRUE"){

	    png(filename="barplot.png")
      plot.new()
      #text(0,0,err_msg)
	    dev.off()
    }
	
	  if (dotplot=="TRUE"){
	
	    png(filename="dotplot.png")
      plot.new()
      #text(0,0,err_msg)
	    dev.off()
	
	  }
    return(TRUE)
  }

	
  if (is.null(cut_result)){


	  if (text=="TRUE"){

		  err_msg = "Threshold was too stringent, no GO term found with pvalue equal or lesser than the threshold value."
      write.table(err_msg, file='result.csv', quote=FALSE, sep='\t', col.names = T, row.names = F)
	  
    }

	  if (barplot=="TRUE"){

	    png(filename="barplot.png")
      plot.new()
      text(0,0,err_msg)
	    dev.off()
    }
	
	  if (dotplot=="TRUE"){
	
	    png(filename="dotplot.png")
      plot.new()
      text(0,0,err_msg)
	    dev.off()
	
	  }
    return(TRUE)



  }

	if (text=="TRUE"){
		write.table(cut_result, file='result.csv', quote=FALSE, sep='\t', col.names = T, row.names = F)
	}
	
	if (barplot=="TRUE"){
	
		createBarPlot(cut_result, onto)
	}
	
	if (dotplot=="TRUE"){
	
		createDotPlot(cut_result, onto)
	}
  return(TRUE)
}



# Load R library ggplot2 to plot graphs
library(ggplot2)

# Launch enrichment analysis
allresult = goEnrichment(geneuniverse,sample,onto)
result = allresult[1][[1]]
myGOdata = allresult[2][[1]]
if (!is.null(result)){

	# Adjust the result with a multiple testing correction or not and with the user
	# p-value cutoff
  cut_result = corrMultipleTesting(result,myGOdata, correction,threshold)
}else{

  cut_result=NULL

}


createOutputs(result, cut_result,text, barplot, dotplot, onto)

