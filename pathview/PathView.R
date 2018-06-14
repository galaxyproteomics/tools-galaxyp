#!/usr/bin/Rscript
#Rscript made for mapping genesID on KEGG pathway with Pathview package
#input : csv file containing ids (uniprot or geneID) to map, plus parameters
#output : KEGG pathway : jpeg or pdf file.

suppressMessages(library("pathview"))
#suppressMessages(library("argparse"))

read_file <- function(path,header){
    file <- try(read.table(path,header=header, sep="\t",stringsAsFactors = FALSE, quote=""),silent=TRUE)
    if (inherits(file,"try-error")){
      stop("File not found !")
    }else{
      return(file)
    }
}

##### fuction to clean and concatenate pathway name (allow more flexibility for user input) 
concat_string <- function(x){
  x <- gsub(" - .*","",x)
  x <- gsub(" ","",x)
  x <- gsub("-","",x)
  x <- gsub("_","",x)
  x <- gsub(",","",x)
  x <- gsub("\\'","",x)
  x <- gsub("\\(.*)","",x)
  x <- gsub("\\/","",x)
  x <- tolower(x)
  return(x)
}


get_args <- function(){
  
  ## Collect arguments
  args <- commandArgs(TRUE)
  
  ## Default setting when no arguments passed
  if(length(args) < 1) {
    args <- c("--help")
  }
  
  ## Help section
  if("--help" %in% args) {
    cat("Pathview R script
    Arguments:
      --help                  Print this test
      --input                 path of the input  file (must contains a colum of uniprot and/or geneID accession number)
      --id_list               list of ids to use, ',' separated
      --pathways_id            Id(s) of pathway(s) to use, if several, semicolon separated list : hsa00010;hsa05412 
      --pathways_name          Name(s) of the pathway(s) to use, if several, semicolon separated list :  
                                'Glycolysis / Gluconeogenesis - Homo sapiens (human);Arrhythmogenic right ventricular cardiomyopathy (ARVC) - Homo sapiens (human)'
      --id_type               Type of accession number ('uniprotID' or 'geneID')
      --id_column             Column containing accesion number of interest (ex : 'c1')
      --header                Boolean, TRUE if header FALSE if not
      --ouput                 Output filename
      --expression_values1    Column containing expression values (first condition)
      --expression_values2    Column containing expression values (second condition)
      --expression_values3    Column containing expression values (third condition)
      --native_kegg           TRUE : native KEGG graph, FALSE : Graphviz graph
      --species               KEGG short name for species, ex : 'hsa' for human

      Example:
      ./PathView.R --input 'input.csv' --pathway_id '05412' --id_type 'uniprotID' --id_column 'c1' --header TRUE \n\n")
    
    q(save="no")
  }
  
  
  #save(args,file="/home/dchristiany/proteore_project/ProteoRE/tools/pathview/args.Rda")
  #load("/home/dchristiany/proteore_project/ProteoRE/tools/pathview/args.Rda")
  parseArgs <- function(x) strsplit(sub("^--", "", x), "=")
  argsDF <- as.data.frame(do.call("rbind", parseArgs(args)))
  args <- as.list(as.character(argsDF$V2))
  names(args) <- argsDF$V1
  
  return(args)
}

  
argparse <- function() {
  # create parser object
  parser <- ArgumentParser()
  
  # specify our desired options 
  # by default ArgumentParser will add an help option 
  parser$add_argument("-i", "--input", type="character", help="path of the input  file (must contains a colum of uniprot and/or geneID accession number)")
  parser$add_argument("-l", "--id_list", type="character", help="list of ids to use, ',' separated")
  #parser$add_argument("-o", "--output", type="character", help="Output filename")
  parser$add_argument("-p", "--pathways_id", type="character", help="Id(s) of pathway(s) to use, if several, semicolon separated list : 00010,05412")
  parser$add_argument("-n", "--pathways_name", type="character", help = "Name(s) of the pathway(s) to use, if several, semicolon separated list : 'Glycolysis / Gluconeogenesis - Homo sapiens (human),Arrhythmogenic right ventricular cardiomyopathy (ARVC) - Homo sapiens (human)'")
  parser$add_argument("-s", "--species", type="character", default='hsa', help= "KEGG short name for species, ex : 'hsa' for human")
  parser$add_argument("-t", "--id_type", type="character", default='geneID', help="Type of accession number ('uniprotID' or 'geneID')")
  parser$add_argument("-c", "--id_column", default="c1", type="character", help="Column containing accesion number of interest (ex : 'c1')")
  parser$add_argument("-e1", "--expression_values1", type="character", help="Column containing expression values (first condition)")
  parser$add_argument("-e2", "--expression_values2", type="character", help="Column containing expression values (second condition)")
  parser$add_argument("-e3", "--expression_values3", type="character", help="Column containing expression values (third condition)")
  parser$add_argument("--header", type="character", default="TRUE", help="Boolean, TRUE if header FALSE if not" )
  parser$add_argument("--native_kegg", type="character", default="FALSE", help="TRUE : native KEGG graph, FALSE : Graphviz graph")
  
  # get command line options, if help option encountered print help and exit,
  # otherwise if options not found on command line then set defaults, 
  args <- parser$parse_args()
  return(args)
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

is.letter <- function(x) grepl("[[:alpha:]]", x)

#### hsa00010 -> 00010
remove_kegg_prefix <- function(x){
  if (is.letter(substr(x,1,3))){
    x <- substr(x,4,nchar(x))
  }
  return(x)
}


#args <- argparse()
#print(args)

args <- get_args()

###save and load args in rda file for testing
#save(args,file="/home/dchristiany/proteore_project/ProteoRE/tools/pathview/args.Rda")
#load("/home/dchristiany/proteore_project/ProteoRE/tools/pathview/args.Rda")

###setting variables
if (!is.null(args$pathways_id)) { ids <- sapply(rapply(strsplit(args$pathways_id,","),c), function(x) remove_kegg_prefix(x),USE.NAMES = FALSE)}
if (!is.null(args$pathways_name)) {names <- as.vector(sapply(strsplit(args$pathways_name,","), function(x) concat_string(x),USE.NAMES = FALSE))}
if (!is.null(args$id_list)) {id_list <- as.vector(strsplit(args$id_list,","))}
id_type <- tolower(args$id_type)
ncol <- as.numeric(gsub("c", "" ,args$id_column))
e1 <- as.numeric(gsub("c", "" ,args$e1))
if (!is.null(args$e1)) { colnames(tab)[,e1] <- "e1" }
e2 <- as.numeric(gsub("c", "" ,args$e2))
if (!is.null(args$e2)) { colnames(tab)[,e2] <- "e2" }
e3 <- as.numeric(gsub("c", "" ,args$e3))
if (!is.null(args$e2)) { colnames(tab)[,e3] <- "e3" }
header <- str2bool(args$header)
#output <- args$output
native_kegg <- str2bool(args$native_kegg)


#read input file or list
if (!is.null(args$input)){
  tab <- read_file(args$input,header)
  tab <- tab[!apply(is.na(tab) | tab == "", 1, all),] #delete empty rows
} else {
  tab <- data.frame(id_list)
  ncol=1
}


##### map uniprotID to entrez geneID
if (id_type == "uniprotid") {
  
  uniprotID = tab[,ncol]
  mapped2geneID = id2eg(ids = uniprotID, category = "uniprot", org = "Hs", pkg.name = NULL)
  geneID = mapped2geneID[,2]
  tab = cbind(tab,geneID)

}else if (id_type == "geneid"){

  colnames(tab)[ncol] <- "geneID"

}

geneID = tab$geneID[which(tab$geneID !="NA")]
geneID = gsub(" ","",geneID)
geneID = unlist(strsplit(geneID,"[;]"))


#### get hsa pathways list 
#download.file(url = "http://rest.kegg.jp/link/pathway/hsa", destfile = "/home/dchristiany/proteore_project/ProteoRE/tools/pathview/geneID_to_hsa_pathways.csv") 
#geneid_hsa_pathways <- read_file(path = "/home/dchristiany/proteore_project/ProteoRE/tools/pathview/geneID_to_hsa_pathways.csv",FALSE)
#names(geneid_hsa_pathways) <- c("geneID","pathway")


##### retrieve pathway id

if (is.null(args$pathways_id)){
  
  #### build data.frame of pathways
  #download.file(url = "http://rest.kegg.jp/list/pathway/hsa", destfile = "/home/dchristiany/proteore_project/ProteoRE/tools/pathview/hsa_pathways.csv")
  hsa_pathways <- read_file(path = paste(wd,"/projet/galaxydev/galaxy/tools/proteore/ProteoRE/tools/pathview/hsa_pathways.csv",sep="/"),FALSE)
  pathways <- sapply(hsa_pathways$V1, function(x) gsub("path:","",x),USE.NAMES = FALSE)
  pathways <- cbind(sapply(pathways, function(x) substr(x,1,3), USE.NAMES = FALSE), sapply(pathways, function(x) substr(x,4,nchar(x)),USE.NAMES = FALSE))
  pathways <- cbind(pathways,sapply(hsa_pathways$V2, function(x) gsub(" - .*","",x), USE.NAMES = FALSE))  #remove the last part of the name (ex : ' - Homo sapiens (human)')
  pathways <- cbind(pathways,sapply(pathways[,3], function(x) concat_string(x), USE.NAMES = FALSE))
  pathways <- data.frame(pathways,stringsAsFactors = FALSE)
  names(pathways) <- c("species","id","name","concat_name")

  ids <- pathways$id[match(names,pathways$concat_name)]
}


##### build matrix to map on KEGG pathway (kgml : KEGG xml)
if (!is.null(args$e1)&is.null(args$e2)&is.null(args$e3)){
  mat <- tab$e1
  names(tab$e1) <- tab$geneID
} else if (!is.null(args$e1)&!is.null(args$e2)&is.null(args$e3)){
  mat <- cbind(tab$e1,tab$e2)
  names(mat) <- tab$geneID
}else if (!is.null(args$e1)&!is.null(args$e2)&!is.null(args$e3)){
  mat <- cbind(tab$e1,tab$e2,tab$e3)
  names(mat) <- tab$geneID
} else {
  mat <- geneID
}


#### simulation data test
#sim <- sim.mol.data(mol.type = c("gene", "gene.ko", "cpd")[1], id.type = NULL, species="hsa", discrete = FALSE, nmol = 1000, nexp = 1, rand.seed=100)
#mat <- sim[1:length(geneID)]
#names(mat) <- geneID


#####mapping geneID (with or without expression values) on KEGG pathway
for (id in ids) {
  pathview(gene.data = mat,
           #gene.idtype = "geneID",
           #cpd.data = uniprotID,
           #cpd.idtype = "uniprot",
           pathway.id = id,
           #pathway.name = "",
           species = args$species, 
           kegg.dir = ".", 
           gene.idtype = "entrez", 
           #gene.annotpkg = NULL, 
           #min.nnodes = 3, 
           kegg.native = native_kegg,
           #map.null = TRUE, 
           #expand.node = FALSE, 
           #split.group = FALSE, 
           #map.symbol = TRUE, 
           #map.cpdname = TRUE, 
           #node.sum = "sum", 
           #discrete=list(gene=FALSE,cpd=FALSE), 
           #limit = list(gene = 1, cpd = 1), 
           #bins = list(gene = 10, cpd = 10), 
           #both.dirs = list(gene = T, cpd = T), 
           #trans.fun = list(gene = NULL, cpd = NULL), 
           #low = list(gene = "green", cpd = "blue"), 
           #mid = list(gene = "gray", cpd = "gray"), 
           #high = list(gene = "red", cpd = "yellow"), 
           #na.col = "transparent",
           #sign.pos="bottomleft",
           #key.pos="topright",
           #new.signature=TRUE,
           #rankdir="LB",
           #cex=0.3,
           #text.width=15,
           #res=300,
           pdf.size=c(9,9))
           #is.signal=TRUE)
}
