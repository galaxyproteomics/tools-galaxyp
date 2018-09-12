#!/usr/bin/Rscript
#Rscript made for mapping genesID on KEGG pathway with Pathview package
#input : csv file containing ids (uniprot or geneID) to map, plus parameters
#output : KEGG pathway : jpeg or pdf file.

suppressMessages(library("pathview"))

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
      --id_type               Type of accession number ('uniprotID' or 'geneID')
      --id_column             Column containing accesion number of interest (ex : 'c1')
      --header                Boolean, TRUE if header FALSE if not
      --ouput                 Output filename
      --expression_values1    Column containing expression values (first condition)
      --expression_values2    Column containing expression values (second condition)
      --expression_values3    Column containing expression values (third condition)
      --native_kegg           TRUE : native KEGG graph, FALSE : Graphviz graph
      --species               KEGG species (hsa, mmu, ...)
      --pathways_input        Tab with pathways in a column, output format of find_pathways
      --pathway_col           Column of pathways to use
      --header2               Boolean, TRUE if header FALSE if not

      Example:
      ./PathView.R --input 'input.csv' --pathway_id '05412' --id_type 'uniprotID' --id_column 'c1' --header TRUE \n\n")
    
    q(save="no")
  }
  
  parseArgs <- function(x) strsplit(sub("^--", "", x), "=")
  argsDF <- as.data.frame(do.call("rbind", parseArgs(args)))
  args <- as.list(as.character(argsDF$V2))
  names(args) <- argsDF$V1
  
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
  x = gsub(":","",x)
  if (substr(x,1,4) == 'path'){
    x=substr(x,5,nchar(x))
  }
  if (is.letter(substr(x,1,3))){
    x <- substr(x,4,nchar(x))
  }
  return(x)
}

clean_bad_character <- function(string)  {
  string <- gsub("X","",string)
  string <- gsub(" ","",string)
  return(string)
}

args <- get_args()

###setting variables
if (!is.null(args$pathways_id)) { 
  ids <- sapply(rapply(strsplit(clean_bad_character(args$pathways_id),","),c), function(x) remove_kegg_prefix(x),USE.NAMES = FALSE)
}else if (!is.null(args$pathways_input)){
  header2 <- str2bool(args$header2)
  pathway_col <- as.numeric(gsub("c", "" ,args$pathway_col))
  pathways_file = read_file(args$pathways_input,header2)
  ids <- sapply(rapply(strsplit(clean_bad_character(pathways_file[,pathway_col]),","),c), function(x) remove_kegg_prefix(x),USE.NAMES = FALSE)
}
#if (!is.null(args$pathways_name)) {names <- as.vector(sapply(strsplit(args$pathways_name,","), function(x) concat_string(x),USE.NAMES = FALSE))}
if (!is.null(args$id_list)) {id_list <- as.vector(strsplit(clean_bad_character(args$id_list),","))}
id_type <- tolower(args$id_type)
ncol <- as.numeric(gsub("c", "" ,args$id_column))
header <- str2bool(args$header)
#output <- args$output
native_kegg <- str2bool(args$native_kegg)
species=args$species
#org list used in mapped2geneID
org <- c('Hs','Mm')
names(org) <- c('hsa','mmu')



#read input file or list
if (!is.null(args$input)){
  tab <- read_file(args$input,header)
  tab <- data.frame(tab[which(tab[ncol]!=""),])
} else {
  tab <- data.frame(id_list)
  ncol=1
}

e1 <- as.numeric(gsub("c", "" ,args$expression_values1))
if (!is.null(args$expression_values1)) { colnames(tab)[e1] <- "e1" }
e2 <- as.numeric(gsub("c", "" ,args$expression_values2))
if (!is.null(args$expression_values2)) { colnames(tab)[e2] <- "e2" }
e3 <- as.numeric(gsub("c", "" ,args$expression_values3))
if (!is.null(args$expression_values3)) { colnames(tab)[e3] <- "e3" }


##### map uniprotID to entrez geneID
if (id_type == "uniprotid") {
  
  uniprotID = tab[,ncol]
  mapped2geneID = id2eg(ids = uniprotID, category = "uniprot", org = org[[species]], pkg.name = NULL)
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

##### build matrix to map on KEGG pathway (kgml : KEGG xml)
if (!is.null(args$expression_values1)&is.null(args$expression_values2)&is.null(args$expression_values3)){
  mat <- as.data.frame(cbind(tab$e1)[which(!is.na(tab$geneID)),])
  row.names(mat) <- tab$geneID[which(!is.na(tab$geneID))]
} else if (!is.null(args$expression_values1)&!is.null(args$expression_values2)&is.null(args$expression_values3)){
  mat <- as.data.frame(cbind(tab$e1,tab$e2)[which(!is.na(tab$geneID)),])
  row.names(mat) <- tab$geneID[which(!is.na(tab$geneID))]
}else if (!is.null(args$expression_values1)&!is.null(args$expression_values2)&!is.null(args$expression_values3)){
  mat <- as.data.frame(cbind(tab$e1,tab$e2,tab$e3)[which(!is.na(tab$geneID)),])
  row.names(mat) <- tab$geneID[which(!is.na(tab$geneID))]
} else {
  mat <- geneID
}


#### simulation data test
#exp1 <- sim.mol.data(mol.type = c("gene", "gene.ko", "cpd")[1], id.type = NULL, species="hsa", discrete = FALSE, nmol = 161, nexp = 1, rand.seed=100)
#exp2 <- sim.mol.data(mol.type = c("gene", "gene.ko", "cpd")[1], id.type = NULL, species="hsa", discrete = FALSE, nmol = 161, nexp = 1, rand.seed=50)
#exp3 <- sim.mol.data(mol.type = c("gene", "gene.ko", "cpd")[1], id.type = NULL, species="hsa", discrete = FALSE, nmol = 161, nexp = 1, rand.seed=10)
#tab <- cbind(tab,exp1,exp2,exp3)

#write.table(tab, file='/home/dchristiany/proteore_project/ProteoRE/tools/pathview/Lacombe_sim_expression_data.tsv', quote=FALSE, sep='\t',row.names = FALSE)

#mat <- exp1[1:nrow(tab)]
#names(mat) <- geneID


#####mapping geneID (with or without expression values) on KEGG pathway
plot.col.key= TRUE
low_color = "green"
mid_color = "#F3F781" #yellow
high_color = "red"
if (is.null(tab$e1)) {
  plot.col.key= FALSE   #if there's no exrepession data, we don't show the color key
  high_color = "#81BEF7" #blue
}

for (id in ids) {
  pathview(gene.data = mat,
           pathway.id = id,
           species = species, 
           kegg.dir = ".", 
           gene.idtype = "entrez", 
           kegg.native = native_kegg,
           low = list(gene = low_color, cpd = "blue"), 
           mid = list(gene = mid_color, cpd = "transparent"), 
           high = list(gene = high_color, cpd = "yellow"), 
           na.col="#D8D8D8", #gray
           cpd.data=NULL,
           plot.col.key = plot.col.key,
           pdf.size=c(9,9))
}

########using keggview.native

#xml.file=system.file("extdata", "hsa00010.xml", package = "pathview")
#node.data=node.info("/home/dchristiany/hsa00010.xml")
#plot.data.gene=node.map(mol.data=test, node.data, node.types="gene")
#colors =node.color(plot.data = plot.data.gene[,1:9])