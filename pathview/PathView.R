#!/usr/bin/Rscript
suppressMessages(library("pathview"))
suppressMessages(library("argparse"))

read_file <- function(path,header){
    file <- try(read.table(path,header=header, sep="\t",stringsAsFactors = FALSE),silent=TRUE)
    if (inherits(file,"try-error")){
      stop("File not found !")
    }else{
      return(file)
    }
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
      -h, --help            Print this test
      -i, --input           path of the input  file (must contains a colum of uniprot and/or geneID accession number)
      -p, --pathway_id      Id(s) of pathway(s) to use, if several, semicolon separated list : hsa00010;hsa05412 
      -n, --pathway_name    Name(s) of the pathway(s) to use, if several, semicolon separated list :  
                            'Glycolysis / Gluconeogenesis - Homo sapiens (human);Arrhythmogenic right ventricular cardiomyopathy (ARVC) - Homo sapiens (human)'
      -t, --id_type         Type of accession number ('uniprotID' or 'geneID')
      -c, --id_column       Column containing accesion number of interest (ex : 'c1')
      --header              Boolean, TRUE if header FALSE if not
      -o, --ouput           Output filename

      Example:
      ./PathView.R -i 'input.csv' -p 'hsa:05412' -t 'uniprotID' -c 'c1' --header TRUE \n\n")
  
    q(save="no")
  }

  ## Parse arguments (we expect the form --arg=value)
  parseArgs <- function(x) strsplit(sub("^--", "", x), "=")
  argsDF <- as.data.frame(do.call("rbind", parseArgs(args)))
  argsL <- as.list(as.character(argsDF$V2))
  names(argsL) <- argsDF$V1
  
  return(argsL)
}

argparse <- function() {
  
  # create parser object
  parser <- ArgumentParser()
  
  # specify our desired options 
  # by default ArgumentParser will add an help option 
  parser$add_argument("-i", "--input", type="character", help="path of the input  file (must contains a colum of uniprot and/or geneID accession number)")
  parser$add_argument("-o", "--output", type="character", help="Output filename")
  parser$add_argument("-p", "--pathway_id", type="character", help="Id(s) of pathway(s) to use, if several, semicolon separated list : hsa00010;hsa05412")
  parser$add_argument("-n", "--pathway_name", type="character", help = "Name(s) of the pathway(s) to use, if several, semicolon separated list : 'Glycolysis / Gluconeogenesis - Homo sapiens (human);Arrhythmogenic right ventricular cardiomyopathy (ARVC) - Homo sapiens (human)'")
  parser$add_argument("-s", "--species", type="character", help= "KEGG short name for species, ex : 'hsa' for human")
  parser$add_argument("-t", "--id_type", type="character", help="Type of accession number ('uniprotID' or 'geneID')")
  parser$add_argument("-c", "--id_column", default="c1", type="character", help="Column containing accesion number of interest (ex : 'c1')")
  parser$add_argument("-e1", "--expression_values1", type="character", help="Column containing expression values (first condition)")
  parser$add_argument("-e2", "--expression_values2", type="character", help="Column containing expression values (second condition)")
  parser$add_argument("--header", type="logical", default=FALSE, help="Boolean, TRUE if header FALSE if not" )
  parser$add_argument("--native_kegg", type="logical", default=TRUE, help="TRUE : native KEGG graph, FALSE : Graphviz graph")
  
  # get command line options, if help option encountered print help and exit,
  # otherwise if options not found on command line then set defaults, 
  args <- parser$parse_args()
  return(args)

}  

args <- argparse()
#args <- get_args()

#save(args,file="/home/dchristiany/proteore_project/ProteoRE/tools/pathview/args.Rda")
#load("/home/dchristiany/proteore_project/ProteoRE/tools/pathview/args.Rda")

###variables declaration
file_path <- args$input
pathways_id <- args$pathway_id
pathways_name <- args$pathway_name
id_type <- tolower(args$id_type)
ncol <- as.numeric(gsub("c", "" ,args$id_column))
e1 <- as.numeric(gsub("c", "" ,args$e1))
if (!is.null(args$e1)) { colnames(tab)[,e1] <- "e1" }
e2 <- as.numeric(gsub("c", "" ,args$e2))
if (!is.null(args$e2)) { colnames(tab)[,e2] <- "e2" }
header <- args$header
output <- args$output
native_kegg <- args$native_kegg
species <- args$species 


#read file
tab <- read_file("/home/dchristiany/proteore_project/ProteoRE/tools/pathview/test-data/Lacombe_et_al_2017_OK.txt",TRUE)
tab <- tab[!apply(is.na(tab) | tab == "", 1, all),] #delete empty rows


##### map uniprotID to entrez geneID
if (id_type == "uniprotid") {
  
  uniprotID = tab[,ncol]
  mapped2geneID = id2eg(ids = uniprotID, category = "uniprot", org = "Hs", pkg.name = NULL)
  geneID = mapped2geneID[,2]
  tab = cbind(tab,geneID)

}else if (id_type == "geneid"){

  colnames(tab)[ncol] <- geneID

}

geneID = tab$geneID[which(tab$geneID !="NA")]
geneID = gsub(" ","",geneID)
geneID = unlist(strsplit(geneID,"[;]"))


#### get hsa pathways list 
#download.file(url = "http://rest.kegg.jp/link/pathway/hsa", destfile = "hsa_pathways") 
#hsa_pathways <- read_file(path = "hsa_pathways",FALSE)
#names(hsa_pathways) <- c("geneID","pathway")

#get rid of hsa: prefix
#tmp <- sapply(hsa_pathways$geneID, function(x) gsub("hsa:","",x))
#names(tmp) <- c()
#hsa_pathways$geneID <- tmp 

#get rid of path: prefix
#tmp <- sapply(hsa_pathways$pathway, function(x) gsub("path:","",x))
#names(tmp) <- c()
#hsa_pathways$pathway <- tmp

#matches <- match(geneID, hsa_pathways$geneID)
#matches <- matches[!is.na(matches)]

#pathways <- hsa_pathways$pathway[matches]


##### build matrix to map on KEGG pathway (kgml : KEGG xml)
if (!is.null(args$e1)&is.null(args$e2)){
  mat <- tab$e1
  names(tab$e1) <- tab$geneID
} else if (!is.null(args$e1)&!is.null(args$e2)){
  mat <- cbind(tab$e1,tab$e2)
  names(mat) <- tab$geneID
} else {
  mat <- geneID
}


#### simulation data test
#sim <- sim.mol.data(mol.type = c("gene", "gene.ko", "cpd")[1], id.type = NULL, species="hsa", discrete = FALSE, nmol = 1000, nexp = 1, rand.seed=100)
#mat <- sim[1:length(geneID)]
#names(mat) <- geneID

#####mapping geneID (with or without expression values) on KEGG pathway

for (id in pathways_id) {
  
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
           kegg.native = args$native_kegg)
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
           #pdf.size=c(7,7),
           #is.signal=TRUE)

}
