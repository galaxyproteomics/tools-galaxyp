options(warn = -1)  #TURN OFF WARNINGS !!!!!!

suppressMessages(library(ggplot2))
suppressMessages(library(topGO))

get_args <- function() {

  ## Collect arguments
  args <- commandArgs(TRUE)

  ## Default setting when no arguments passed
  if (length(args) < 1) {
    args <- c("--help")
  }

  ## Help section
  if ("--help" %in% args) {
    cat("Pathview R script
    Arguments:
      --help                  Print this test
      --input_type
      --onto
      --option
      --correction
      --threshold
      --text
      --plot
      --column
      --geneuniverse
      --header

      Example:
      Rscript --vanilla enrichment_v3.R --inputtype=tabfile (or copypaste)
      --input=file.txt --ontology='BP/CC/MF' --option=option
      (e.g : classic/elim...) --threshold=threshold --correction=correction
      --textoutput=text --barplotoutput=barplot --dotplotoutput=dotplot
      --column=column --geneuniver=human \n\n")

    q(save = "no")
  }

  parseargs <- function(x) strsplit(sub("^--", "", x), "=")
  argsdf <- as.data.frame(do.call("rbind", parseargs(args)))
  args <- as.list(as.character(argsdf$V2))
  names(args) <- argsdf$V1

  return(args)
}

read_file <- function(path, header) {
  file <- try(read.csv(path, header = header, sep = "\t",
          stringsAsFactors = FALSE, quote = "\"", check.names = F),
          silent = TRUE)
  if (inherits(file, "try-error")) {
    stop("File not found !")
  }else {
    return(file)
  }
}

get_list_from_cp <- function(list) {
  list <- gsub(";", " ", list)
  list <- strsplit(list, "[ \t\n]+")[[1]]
  list <- list[list != ""]    #remove empty entry
  list <- gsub("-.+", "", list)  #Remove isoform accession number (e.g. "-2")
  return(list)
}

check_ens_ids <- function(vector) {
  ens_pattern <-
    "^(ENS[A-Z]+[0-9]{11}|[A-Z]{3}[0-9]{3}[A-Za-z](-[A-Za-z])?
  |CG[0-9]+|[A-Z0-9]+\\.[0-9]+|YM[A-Z][0-9]{3}[a-z][0-9])$"
  return(grepl(ens_pattern, vector))
}

str2bool <- function(x) {
  if (any(is.element(c("t", "true"), tolower(x)))) {
    return(TRUE)
  }else if (any(is.element(c("f", "false"), tolower(x)))) {
    return(FALSE)
  }else {
    return(NULL)
  }
}

# Some libraries such as GOsummaries won't be able to treat the values such as
# "< 1e-30" produced by topGO. As such it is important to delete the < char
# with the deleteinfchar function. Nevertheless the user will have access to
#the original results in the text output.
deleteinfchar <- function(values) {

  lines <- grep("<", values)
  if (length(lines) != 0) {
    for (line in lines) {
      values[line] <- gsub("<", "", values[line])
    }
  }
  return(values)
}

#nolint start
corrMultipleTesting = function(result, mygodata, correction, threshold){
  
  # adjust for multiple testing
  if (correction != "none"){	
    # GenTable : transforms the result object into a list. Filters can be applied
    # (e.g : with the topNodes argument, to get for instance only the n first
    # GO terms with the lowest pvalues), but as we want to  apply a correction we
    # take all the GO terms, no matter their pvalues 
    allRes <- GenTable(mygodata, test = result, orderBy = "result", 
              ranksOf = "result", topNodes = length(attributes(result)$score))
    # Some pvalues given by topGO are not numeric (e.g : "<1e-30). As such, these
    # values are converted to 1e-30 to be able to correct the pvalues 
    pvaluestmp = deleteinfchar(allRes$test)
    
    # the correction is done from the modified pvalues  
    allRes$qvalues = p.adjust(pvaluestmp, method = as.character(correction),
                              n = length(pvaluestmp))
    allRes = as.data.frame(allRes)
    
    # Rename the test column by pvalues, so that is more explicit
    nb = which(names(allRes) %in% c("test"))
    
    names(allRes)[nb] = "pvalues"
    
    allRes = allRes[which(as.numeric(allRes$pvalues) <= threshold), ]
    if (length(allRes$pvalues) == 0) {
      print("Threshold was too stringent, no GO term found with pvalue
            equal or lesser than the threshold value")
      return(NULL)
    }
    allRes = allRes[order(allRes$qvalues), ]
  }
  
  if (correction == "none"){
    # get all the go terms under user threshold 
    mysummary <- summary(attributes(result)$score <= threshold)
    numsignif <- as.integer(mysummary[[3]])
    # get all significant nodes 
    allRes <- GenTable(mygodata, test = result, orderBy = "result",
                       ranksOf = "result", topNodes = numsignif)
    
    
    allRes = as.data.frame(allRes)
    # Rename the test column by pvalues, so that is more explicit
    nb = which(names(allRes) %in% c("test"))
    names(allRes)[nb] = "pvalues"
    if (numsignif == 0) {
      
      print("Threshold was too stringent, no GO term found with pvalue
            equal or lesser than the threshold value")
      return(NULL)
    }
    
    allRes = allRes[order(allRes$pvalues), ]
  } 
  
  return(allRes)  
}
#nolint end

#roundvalues will simplify the results by rounding down the values.
#For instance 1.1e-17 becomes 1e-17
roundvalues <- function(values) {
  for (line in seq_len(length(values))) {
    values[line] <- as.numeric(gsub(".*e", "1e", as.character(values[line])))
  }
  return(values)
}

#nolint start
createDotPlot = function(data, onto) {
  
    values  = deleteinfchar(data$pvalues)
    values = roundvalues(values)
    values = as.numeric(values)
    
    geneRatio = data$Significant / data$Annotated
    goTerms = data$Term
    count = data$Significant
    
    labely = paste("GO terms", onto, sep = " ")
    ggplot(data, aes(x = geneRatio, y = goTerms, color = values, size=count)) + geom_point( ) + scale_colour_gradientn( colours = c("red", "violet", "blue")) + xlab("Gene Ratio") + ylab(labely) + labs(color = "p-values\n" ) 
    ggsave("dotplot.png", device = "png", dpi = 320, limitsize = TRUE,
           width = 15, height = 15, units = "cm")
}

createBarPlot = function(data, onto) {
  
    values  = deleteinfchar(data$pvalues)
    values = roundvalues(values)
    values = as.numeric(values)
    
    goTerms = data$Term
    count = data$Significant
    
    labely = paste("GO terms", onto, sep=" ")
    ggplot(data, aes(x = goTerms, y = count, fill = values, scale(scale = 0.5))) + ylab("Gene count") + xlab(labely) + geom_bar(stat = "identity") + scale_fill_gradientn(colours = c("red","violet","blue")) + coord_flip() + labs(fill = "p-values\n") 
    ggsave("barplot.png", device = "png", dpi = 320, limitsize = TRUE,
            width = 15, height = 15, units = "cm")
}

#nolint end

# Produce the different outputs
createoutputs <- function(result, cut_result, text, barplot, dotplot, onto) {

  if (is.null(result)) {
    err_msg <- "None of the input ids can be found in the org package data,
    enrichment analysis cannot be realized. \n The inputs ids probably
    either have no associated GO terms or are not ENSG identifiers
    (e.g : ENSG00000012048)."
    write.table(err_msg, file = "result", quote = FALSE, sep = "\t",
                col.names = F, row.names = F)
  }else if (is.null(cut_result)) {
    err_msg <- "Threshold was too stringent, no GO term found with pvalue equal
    or lesser than the threshold value."
    write.table(err_msg, file = "result.tsv", quote = FALSE, sep = "\t",
                col.names = F, row.names = F)
  }else {
    write.table(cut_result, file = "result.tsv", quote = FALSE, sep = "\t",
                col.names = T, row.names = F)

    if (barplot) {
      createBarPlot(cut_result, onto) #nolint
      }
    if (dotplot) {
      createDotPlot(cut_result, onto) #nolint
      }
  }
}

# Launch enrichment analysis and return result data from the analysis or the
# null object if the enrichment could not be done.
goenrichment <- function(geneuniverse, sample, background_sample, onto) {

  if (is.null(background_sample)) {
    xx <- annFUN.org(onto, mapping = geneuniverse, ID = "ensembl")  #nolint
    #get all the GO terms of the corresponding ontology (BP/CC/MF)
    #and all their associated ensembl ids according to the org package

    #nolint start
    
    allGenes <- unique(unlist(xx)) 
    #check if the genes given by the user can be found in the org package 
    #(gene universe), that is in allGenes
  } else {
    allGenes <- background_sample
  }
  
  if (length(intersect(sample,allGenes)) == 0) {
    print("None of the input ids can be found in the org package data,
          enrichment analysis cannot be realized. \n The inputs ids probably
          have no associated GO terms.")
    return(c(NULL, NULL))
  }
  
  geneList <- factor(as.integer(allGenes %in% sample)) 
  #duplicated ids in sample count only for one
  if (length(levels(geneList)) == 1 ){
    stop("All or none of the background genes are found in tested genes dataset,
         enrichment analysis can't be done")
  }
  names(geneList) <- allGenes

#nolint end

  #topGO enrichment

  # Creation of a topGOdata object
  # It will contain : the list of genes of interest, the GO annotations and
  # the GO hierarchy
  # Parameters :
  # ontology : character string specifying the ontology of interest (BP, CC, MF)
  # allGenes : named vector of type numeric or factor
  # annot : tells topGO how to map genes to GO annotations.
  # argument not used here : nodeSize : at which minimal number of GO
  # annotations do we consider a gene

  mygodata <- new("topGOdata", description = "SEA with TopGO", ontology = onto,
                 allGenes = geneList,  annot = annFUN.org,
                 mapping = geneuniverse, ID = "ensembl")

  # Performing enrichment tests
  result <- runTest(mygodata, algorithm = option, statistic = "fisher") #nolint
  return(c(result, mygodata))
}

args <- get_args()


input_type <- args$inputtype
input <- args$input
onto <- args$ontology
option <- args$option
correction <- args$correction
threshold <- as.numeric(args$threshold)
text <- str2bool(args$textoutput)
barplot <- "barplot" %in% unlist(strsplit(args$plot, ","))
dotplot <- "dotplot" %in% unlist(strsplit(args$plot, ","))
column <- as.numeric(gsub("c", "", args$column))
geneuniverse <- args$geneuniverse
header <- str2bool(args$header)
background <- str2bool(args$background)
if (background) {
  background_genes <- args$background_genes
  background_input_type <- args$background_input_type
  background_header <- str2bool(args$background_header)
  background_column <- as.numeric(gsub("c", "", args$background_column))
}

#get input
if (input_type == "copy_paste") {
  sample <- get_list_from_cp(input)
} else if (input_type == "file") {
  tab <- read_file(input, header)
  sample <- trimws(unlist(strsplit(tab[, column], ";")))
}

#check of ENS ids
if (! any(check_ens_ids(sample))) {
  stop("no ensembl gene ids found in your ids list,
    please check your IDs in input or the selected column of your input file")
}

#get input if background genes
if (background) {
  if (background_input_type == "copy_paste") {
    background_sample <- get_list_from_cp(background_genes)
  } else if (background_input_type == "file") {
    background_tab <- read_file(background_genes, background_header)
    background_sample <- unique(trimws(unlist(
      strsplit(background_tab[, background_column], ";"))))
  }
  #check of ENS ids
  if (! any(check_ens_ids(background_sample))) {
    stop("no ensembl gene ids found in your background ids list,
    please check your IDs in input or the selected column of your input file")
  }
} else {
  background_sample <- NULL
}

# Launch enrichment analysis
allresult <- suppressMessages(goenrichment(geneuniverse, sample,
                                          background_sample, onto))
result <- allresult[1][[1]]
mygodata <- allresult[2][[1]]
if (!is.null(result)) {
  cut_result <- corrMultipleTesting(result, mygodata, correction, threshold)
  #Adjust the result with a multiple testing correction or not and with the
  #user, p-value cutoff
}else {
  cut_result <- NULL
}

createoutputs(result, cut_result, text, barplot, dotplot, onto)
