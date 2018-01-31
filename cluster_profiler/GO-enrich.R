library(clusterProfiler)

#library(org.Sc.sgd.db)
library(org.Hs.eg.db)
library(org.Mm.eg.db)

# Read file and return file content as data.frame?
readfile = function(filename, header) {
  if (header == "true") {
    # Read only the first line of the files as data (without headers):
    headers <- read.table(filename, nrows = 1, header = FALSE, sep = "\t", stringsAsFactors = FALSE, fill = TRUE, na.strings=c("", "NA"), blank.lines.skip = TRUE)
    #Read the data of the files (skipping the first row):
    file <- read.table(filename, skip = 1, header = FALSE, sep = "\t", stringsAsFactors = FALSE, fill = TRUE, na.strings=c("", "NA"), blank.lines.skip = TRUE)
    # Remove empty rows
    file <- file[!apply(is.na(file) | file == "", 1, all), , drop=FALSE]
    #And assign the headers of step two to the data:
    names(file) <- headers
  }
  else {
    file <- read.table(filename, header = FALSE, sep = "\t", stringsAsFactors = FALSE, fill = TRUE, na.strings=c("", "NA"), blank.lines.skip = TRUE)
    file <- file[!apply(is.na(file) | file == "", 1, all), , drop=FALSE]
  }
  return(file)
}

repartition.GO <- function(geneid, orgdb, ontology, level=3, readable=TRUE) {
  ggo<-groupGO(gene=geneid, 
               OrgDb = orgdb, 
               ont=ontology, 
               level=level, 
               readable=TRUE)
  name <- paste("GGO.", ontology, ".png", sep = "")
  png(name)
  p <- barplot(ggo)
  print(p)
  dev.off()
  return(ggo)
}

# GO over-representation test
enrich.GO <- function(geneid, orgdb, ontology, pval_cutoff, qval_cutoff) {
  ego<-enrichGO(gene=geneid,
                OrgDb=orgdb,
                keytype="ENTREZID",
                ont=ontology,
                pAdjustMethod="BH",
                pvalueCutoff=pval_cutoff,
                qvalueCutoff=qval_cutoff,
                readable=TRUE)
  bar_name <- paste("EGO.", ontology, ".bar.png", sep = "")
  png(bar_name)
  p <- barplot(ego)
  print(p)
  dev.off()
  dot_name <- paste("EGO.", ontology, ".dot.png", sep = "")
  png(dot_name)
  p <- dotplot(ego)
  print(p)
  dev.off()
  return(ego)
}

clusterProfiler = function() {
  args <- commandArgs(TRUE)
  if(length(args)<1) {
    args <- c("--help")
  }
  
  # Help section
  if("--help" %in% args) {
    cat("clusterProfiler Enrichment Analysis
    Arguments:
        --input_type: type of input (list of id or filename)
        --input: input
        --ncol: the column number which you would like to apply...
        --header: true/false if your file contains a header
        --id_type: the type of input IDs (UniProt/EntrezID)
        --species
        --onto_opt: ontology options
        --level: 1-3
        --pval_cutoff
        --qval_cutoff
        --text_output: text output filename \n")
    q(save="no")
  }
  # Parse arguments
  parseArgs <- function(x) strsplit(sub("^--", "", x), "=")
  argsDF <- as.data.frame(do.call("rbind", parseArgs(args)))
  args <- as.list(as.character(argsDF$V2))
  names(args) <- argsDF$V1

  input_type = args$input_type
  if (input_type == "text") {
    input = args$input
  }
  else if (input_type == "file") {
    filename = args$input
    ncol = args$ncol
    # Check ncol
    if (! as.numeric(gsub("c", "", ncol)) %% 1 == 0) {
      stop("Please enter an integer for level")
    }
    else {
      ncol = as.numeric(gsub("c", "", ncol))
    }
    header = args$header
    # Get file content
    file = readfile(filename, header)
    # Extract Protein IDs list
    input = c()
    for (row in as.character(file[,ncol])) {
      input = c(input, strsplit(row, ";")[[1]][1])
    }
  }
  id_type = args$id_type

  
  #ID format Conversion 
  #This case : from UNIPROT (protein id) to ENTREZ (gene id)
  #bitr = conversion function from clusterProfiler

  if (args$species=="human") {
    orgdb<-org.Hs.eg.db
  }
  else if (args$species=="mouse") {
    orgdb<-org.Mm.eg.db
  }
  else if (args$species=="rat") {
    orgdb<-org.Rn.eg.db
  }
  
  ##to initialize
  if (id_type=="Uniprot") {
    idFrom<-"UNIPROT"
    idTo<-"ENTREZID"
    gene<-bitr(input, fromType=idFrom, toType=idTo, OrgDb=orgdb)
  }
  else if (id_type=="Entrez") {
    gene<-input
  }

  ontology <- strsplit(args$onto_opt, ",")[[1]]
  level <- as.numeric(args$level)
  pval_cutoff <- as.numeric(args$pval_cutoff)
  qval_cutoff <- as.numeric(args$qval_cutoff)

  ##enrichGO : GO over-representation test
  for (onto in ontology) {
    ggo<-repartition.GO(gene$ENTREZID, orgdb, onto, level, readable=TRUE)
    ego<-enrich.GO(gene$ENTREZID, orgdb, onto,
                pval_cutoff,
                qval_cutoff)
    # write textual output
    write.table(ggo, args$text_output, append = TRUE, sep="\t", row.names = FALSE, quote=FALSE)
    write.table(ego, args$text_output, append = TRUE, sep="\t", row.names = FALSE, quote=FALSE)
  }
}

clusterProfiler()
