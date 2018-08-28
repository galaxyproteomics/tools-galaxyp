suppressMessages(library(clusterProfiler))

#library(org.Sc.sgd.db)
suppressMessages(library(org.Hs.eg.db))
suppressMessages(library(org.Mm.eg.db))

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

repartition.GO <- function(geneid, orgdb, ontology, level=3, readable=TRUE) {
  ggo<-groupGO(gene=geneid, 
               OrgDb = orgdb, 
               ont=ontology, 
               level=level, 
               readable=TRUE)
  name <- paste("GGO.", ontology, ".png", sep = "")
  png(name)
  p <- barplot(ggo, showCategory=10)
  print(p)
  dev.off()
  return(ggo)
}

# GO over-representation test
enrich.GO <- function(geneid, universe, orgdb, ontology, pval_cutoff, qval_cutoff) {
  ego<-enrichGO(gene=geneid,
                universe=universe,
                OrgDb=orgdb,
                keytype="ENTREZID",
                ont=ontology,
                pAdjustMethod="BH",
                pvalueCutoff=pval_cutoff,
                qvalueCutoff=qval_cutoff,
                readable=TRUE)
  # Plot bar & dot plots
  bar_name <- paste("EGO.", ontology, ".bar.png", sep = "")
  png(bar_name)
  p <- barplot(ego)
  print(p)
  dev.off()
  dot_name <- paste("EGO.", ontology, ".dot.png", sep = "")
  png(dot_name)
  p <- dotplot(ego, showCategory=10)
  print(p)
  dev.off()
  return(ego)
}

check_ids <- function(vector,type) {
  uniprot_pattern = "^([OPQ][0-9][A-Z0-9]{3}[0-9]|[A-NR-Z][0-9]([A-Z][A-Z0-9]{2}[0-9]){1,2})$"
  entrez_id = "^'[0-9]+|[A-Z]{1,2}_[0-9]+|[A-Z]{1,2}_[A-Z]{1,4}[0-9]+)$"
  if (type == "entrez")
    return(grepl(entrez_id,vector))
  else if (type == "uniprot") {
    return(grepl(uniprot_pattern,vector))
  }
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
        --ncol: the column number which contains list of input IDs
        --header: true/false if your file contains a header
        --id_type: the type of input IDs (UniProt/EntrezID)
        --universe_type: list or filename
        --universe: background IDs list
        --uncol: the column number which contains background IDs list
        --uheader: true/false if the background IDs file contains header
        --universe_id_type: the type of universe IDs (UniProt/EntrezID)
        --species
        --onto_opt: ontology options
        --go_function: groupGO/enrichGO
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
  #print(args)
  
  #save(args,file="args.Rda")
  #load("/home/dchristiany/proteore_project/ProteoRE/tools/cluster_profiler/args.Rda")
  
  # Extract OrgDb
  if (args$species=="human") {
    orgdb<-org.Hs.eg.db
  } else if (args$species=="mouse") {
    orgdb<-org.Mm.eg.db
  } else if (args$species=="rat") {
    orgdb<-org.Rn.eg.db
  }

  # Extract input IDs
  input_type = args$input_type
  if (input_type == "text") {
    input = strsplit(args$input, "[ \t\n]+")[[1]]
  } else if (input_type == "file") {
    filename = args$input
    ncol = args$ncol
    # Check ncol
    if (! as.numeric(gsub("c", "", ncol)) %% 1 == 0) {
      stop("Please enter the right format for column number: c[number]")
    } else {
      ncol = as.numeric(gsub("c", "", ncol))
    }
    header = args$header
    # Get file content
    file = readfile(filename, header)
    # Extract Protein IDs list
    input =  sapply(as.character(file[,ncol]),function(x) rapply(strsplit(x,";"),c),USE.NAMES = FALSE)
  }
  id_type = args$id_type
  ## Get input gene list from input IDs
  #ID format Conversion 
  #This case : from UNIPROT (protein id) to ENTREZ (gene id)
  #bitr = conversion function from clusterProfiler
  if (id_type=="Uniprot" & any(check_ids(input,"uniprot"))) {
    any(check_ids(input,"uniprot"))
    idFrom<-"UNIPROT"
    idTo<-"ENTREZID"
    gene<-bitr(input, fromType=idFrom, toType=idTo, OrgDb=orgdb)
    gene<-unique(gene$ENTREZID)
  } else if (id_type=="Entrez" & any(check_ids(input,"entrez"))) {
    gene<-unique(input)
  } else {
    print(paste(id_type,"not found in your ids list, please check your IDs in input or the selected column of your input file"))
    stop()
  }

  ontology <- strsplit(args$onto_opt, ",")[[1]]
  ## Extract GGO/EGO arguments
  if (args$go_represent == "true") {
    go_represent <- args$go_represent
    level <- as.numeric(args$level)
  }
  if (args$go_enrich == "true") {
    go_enrich <- args$go_enrich
    pval_cutoff <- as.numeric(args$pval_cutoff)
    qval_cutoff <- as.numeric(args$qval_cutoff)
    # Extract universe background genes (same as input file)
    if (!is.null(args$universe_type)) {
      universe_type = args$universe_type
      if (universe_type == "text") {
        universe = strsplit(args$universe, "[ \t\n]+")[[1]]
      } else if (universe_type == "file") {
        universe_filename = args$universe
        universe_ncol = args$uncol
        # Check ncol
        if (! as.numeric(gsub("c", "", universe_ncol)) %% 1 == 0) {
          stop("Please enter the right format for column number: c[number]")
        } else {
          universe_ncol = as.numeric(gsub("c", "", universe_ncol))
        }
        universe_header = args$uheader
        # Get file content
        universe_file = readfile(universe_filename, universe_header)
        # Extract Protein IDs list
        universe <- sapply(universe_file[,universe_ncol], function(x) rapply(strsplit(x,";"),c),USE.NAMES = FALSE)
      }
      universe_id_type = args$universe_id_type
      ##to initialize
      if (universe_id_type=="Uniprot" & any(check_ids(universe,"uniprot"))) {
        idFrom<-"UNIPROT"
        idTo<-"ENTREZID"
        universe_gene<-bitr(universe, fromType=idFrom, toType=idTo, OrgDb=orgdb)
        universe_gene<-unique(universe_gene$ENTREZID)
      } else if (universe_id_type=="Entrez" & any(check_ids(universe,"entrez"))) {
        universe_gene<-unique(universe)
      } else {
        if (universe_type=="text"){
          print(paste(universe_id_type,"not found in your background IDs list",sep=" "))
        } else {
          print(paste(universe_id_type,"not found in the column",universe_ncol,"of your background IDs file",sep=" "))
        }
        universe_gene = NULL
      } 
    } else {
      universe_gene = NULL
    }
  }

  ##enrichGO : GO over-representation test
  for (onto in ontology) {
    if (args$go_represent == "true") {
      ggo<-repartition.GO(gene, orgdb, onto, level, readable=TRUE)
      write.table(ggo, args$text_output, append = TRUE, sep="\t", row.names = FALSE, quote=FALSE)
    }
    if (args$go_enrich == "true" & !is.null(universe_gene)) {
      ego<-enrich.GO(gene, universe_gene, orgdb, onto, pval_cutoff, qval_cutoff)
      write.table(ego, args$text_output, append = TRUE, sep="\t", row.names = FALSE, quote=FALSE)
    }
  }
}

clusterProfiler()
