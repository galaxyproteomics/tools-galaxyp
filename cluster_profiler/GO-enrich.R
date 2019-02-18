options(warn=-1)  #TURN OFF WARNINGS !!!!!!
suppressMessages(library(clusterProfiler,quietly = TRUE))

# Read file and return file content as data.frame
read_file <- function(path,header){
  file <- try(read.csv(path,header=header, sep="\t",stringsAsFactors = FALSE, quote="",check.names = F),silent=TRUE)
  if (inherits(file,"try-error")){
    stop("File not found !")
  }else{
    file <- file[!apply(is.na(file) | file == "", 1, all), , drop=FALSE]
    return(file)
  }
}

#return the number of character from the longest description found (from the 10 first)
max_str_length_10_first <- function(vector){
  vector <- as.vector(vector)
  nb_description = length(vector)
  if (nb_description >= 10){nb_description=10}
  return(max(nchar(vector[1:nb_description])))
}

str2bool <- function(x){
  if (any(is.element(c("t","true"),tolower(x)))){
    return (TRUE)
  }else if (any(is.element(c("f","false"),tolower(x)))){
    return (FALSE)
  }else{
    return(NULL)
  }
}

#used before the limit was set to 50 characters
width_by_max_char <- function (nb_max_char) {
  if (nb_max_char < 50 ){
    width=600
  } else if (nb_max_char < 75) {
    width=800
  } else if (nb_max_char < 100) {
    width=900
  } else {
    width=1000
  }
  return (width)
}

repartition.GO <- function(geneid, orgdb, ontology, level=3, readable=TRUE) {
  ggo<-groupGO(gene=geneid, 
               OrgDb = orgdb, 
               ont=ontology, 
               level=level, 
               readable=TRUE)

  if (length(ggo@result$ID) > 0 ) {
    ggo@result$Description <- sapply(as.vector(ggo@result$Description), function(x) {ifelse(nchar(x)>50, substr(x,1,50),x)},USE.NAMES = FALSE)
    #nb_max_char = max_str_length_10_first(ggo$Description)
    #width = width_by_max_char(nb_max_char)
    name <- paste("GGO_", ontology, "_bar-plot", sep = "")
    png(name,height = 720, width = 600)
    p <- barplot(ggo, showCategory=10)
    print(p)
    dev.off()
    ggo <- as.data.frame(ggo)
    return(ggo)
  }
}

# GO over-representation test
enrich.GO <- function(geneid, universe, orgdb, ontology, pval_cutoff, qval_cutoff,plot) {
  ego<-enrichGO(gene=geneid,
                universe=universe,
                OrgDb=orgdb,
                ont=ontology,
                pAdjustMethod="BH",
                pvalueCutoff=pval_cutoff,
                qvalueCutoff=qval_cutoff,
                readable=TRUE)
  
  # Plot bar & dot plots
  #if there are enriched GopTerms
  if (length(ego$ID)>0){
    
    ego@result$Description <- sapply(ego@result$Description, function(x) {ifelse(nchar(x)>50, substr(x,1,50),x)},USE.NAMES = FALSE)
    #nb_max_char = max_str_length_10_first(ego$Description)
    #width = width_by_max_char(nb_max_char)
    
    if ("dotplot" %in% plot ){
    dot_name <- paste("EGO_", ontology, "_dot-plot", sep = "")
    png(dot_name,height = 720, width = 600)
    p <- dotplot(ego, showCategory=10)
    print(p)
    dev.off()
    }

    if ("barplot" %in% plot ){
    bar_name <- paste("EGO_", ontology, "_bar-plot", sep = "")
    png(bar_name,height = 720, width = 600)
    p <- barplot(ego, showCategory=10)
    print(p)
    dev.off()
    
    }
    ego <- as.data.frame(ego)
    return(ego)
  } else {
    warning(paste("No Go terms enriched (EGO) found for ",ontology,"ontology"),immediate. = TRUE,noBreaks. = TRUE,call. = FALSE)
  }
}

check_ids <- function(vector,type) {
  uniprot_pattern = "^([OPQ][0-9][A-Z0-9]{3}[0-9]|[A-NR-Z][0-9]([A-Z][A-Z0-9]{2}[0-9]){1,2})$"
  entrez_id = "^([0-9]+|[A-Z]{1,2}_[0-9]+|[A-Z]{1,2}_[A-Z]{1,4}[0-9]+)$"
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
        --text_output: text output filename 
        --plot : type of visualization, dotplot or/and barplot \n")
    q(save="no")
  }
  # Parse arguments
  parseArgs <- function(x) strsplit(sub("^--", "", x), "=")
  argsDF <- as.data.frame(do.call("rbind", parseArgs(args)))
  args <- as.list(as.character(argsDF$V2))
  names(args) <- argsDF$V1
  
  #save(args,file="/home/dchristiany/proteore_project/ProteoRE/tools/cluster_profiler/args.Rda")
  #load("/home/dchristiany/proteore_project/ProteoRE/tools/cluster_profiler/args.Rda")
  
  
  go_represent=str2bool(args$go_represent)
  go_enrich=str2bool(args$go_enrich)
  if (go_enrich){
    plot = unlist(strsplit(args$plot,","))
  }
  
  suppressMessages(library(args$species, character.only = TRUE, quietly = TRUE))
  
  # Extract OrgDb
  if (args$species=="org.Hs.eg.db") {
    orgdb<-org.Hs.eg.db
  } else if (args$species=="org.Mm.eg.db") {
    orgdb<-org.Mm.eg.db
  } else if (args$species=="org.Rn.eg.db") {
    orgdb<-org.Rn.eg.db
  }

  # Extract input IDs
  input_type = args$input_type
  id_type = args$id_type
  
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
    header = str2bool(args$header)                  # Get file content
    file = read_file(filename, header)              # Extract Protein IDs list
    input =  unlist(sapply(as.character(file[,ncol]),function(x) rapply(strsplit(x,";"),c),USE.NAMES = FALSE))
  }
  
  
  ## Get input gene list from input IDs
  #ID format Conversion 
  #This case : from UNIPROT (protein id) to ENTREZ (gene id)
  #bitr = conversion function from clusterProfiler
  if (id_type=="Uniprot" & any(check_ids(input,"uniprot"))) {
    any(check_ids(input,"uniprot"))
    idFrom<-"UNIPROT"
    idTo<-"ENTREZID"
    suppressMessages(gene<-bitr(input, fromType=idFrom, toType=idTo, OrgDb=orgdb))
    gene<-unique(gene$ENTREZID)
  } else if (id_type=="Entrez" & any(check_ids(input,"entrez"))) {
    gene<-unique(input)
  } else {
    stop(paste(id_type,"not found in your ids list, please check your IDs in input or the selected column of your input file"))
  }

  ontology <- strsplit(args$onto_opt, ",")[[1]]
  
  ## Extract GGO/EGO arguments
  if (go_represent) {level <- as.numeric(args$level)}
  if (go_enrich) {
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
        universe_header = str2bool(args$uheader)
        # Get file content
        universe_file = read_file(universe_filename, universe_header)
        # Extract Protein IDs list
        universe <- unlist(sapply(universe_file[,universe_ncol], function(x) rapply(strsplit(x,";"),c),USE.NAMES = FALSE))
      }
      universe_id_type = args$universe_id_type
      ##to initialize
      if (universe_id_type=="Uniprot" & any(check_ids(universe,"uniprot"))) {
        idFrom<-"UNIPROT"
        idTo<-"ENTREZID"
        suppressMessages(universe_gene<-bitr(universe, fromType=idFrom, toType=idTo, OrgDb=orgdb))
        universe_gene<-unique(universe_gene$ENTREZID)
      } else if (universe_id_type=="Entrez" & any(check_ids(universe,"entrez"))) {
        universe_gene<-unique(unlist(universe))
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
  } else {
    universe_gene = NULL
  }

  ##enrichGO : GO over-representation test
  for (onto in ontology) {
    if (go_represent) {
      ggo<-repartition.GO(gene, orgdb, onto, level, readable=TRUE)
      if (is.list(ggo)){ggo <- as.data.frame(apply(ggo, c(1,2), function(x) gsub("^$|^ $", NA, x)))}  #convert "" and " " to NA
      output_path = paste("cluster_profiler_GGO_",onto,".tsv",sep="")
      write.table(ggo, output_path, sep="\t", row.names = FALSE, quote = FALSE )
    }

    if (go_enrich) {
      ego<-enrich.GO(gene, universe_gene, orgdb, onto, pval_cutoff, qval_cutoff,plot)
      if (is.list(ego)){ego <- as.data.frame(apply(ego, c(1,2), function(x) gsub("^$|^ $", NA, x)))}  #convert "" and " " to NA
      output_path = paste("cluster_profiler_EGO_",onto,".tsv",sep="")
      write.table(ego, output_path, sep="\t", row.names = FALSE, quote = FALSE )
    }
  }
}

clusterProfiler()
