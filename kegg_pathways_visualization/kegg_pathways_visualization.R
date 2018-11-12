#!/usr/bin/Rscript
#Rscript made for mapping genesID on KEGG pathway with Pathview package
#input : csv file containing ids (uniprot or geneID) to map, plus parameters
#output : KEGG pathway : jpeg or pdf file.

options(warn=-1)  #TURN OFF WARNINGS !!!!!!

suppressMessages(library("pathview"))

read_file <- function(path,header){
    file <- try(read.csv(path,header=header, sep="\t",stringsAsFactors = FALSE, quote="\"", check.names = F),silent=TRUE)
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

#return output suffix (pathway name) from id kegg (ex : hsa:00010)
get_suffix <- function(pathways_list,species,id){
  suffix = gsub("/","or",pathways_list[pathways_list[,1]==paste(species,id,sep=""),2])
  suffix = gsub(" ","_",suffix)
  if (nchar(suffix) > 50){
    suffix = substr(suffix,1,50)
  }
  return(suffix)
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

kegg_to_geneID <- function(vector){
  vector <- sapply(vector, function(x) unlist(strsplit(x,":"))[2],USE.NAMES = F)
  return (vector)
}

clean_bad_character <- function(string)  {
  string <- gsub("X","",string)
  return(string)
}

get_list_from_cp <-function(list){
  list = strsplit(list, "[ \t\n]+")[[1]]
  list = list[list != ""]    #remove empty entry
  list = gsub("-.+", "", list)  #Remove isoform accession number (e.g. "-2")
  return(list)
}

#return a summary from the mapping with pathview in a vector
mapping_summary <- function(pv.out,species,id,id_type){
  
  mapped <- unique(pv.out$plot.data.gene$kegg.names[which(pv.out$plot.data.gene$all.mapped!='')])
  nb_mapped <- length(mapped)
  nb_kegg_id <- length(unique(pv.out$plot.data.gene$kegg.names))
  ratio = round((nb_mapped/nb_kegg_id)*100, 2)
  if (is.nan(ratio)) { ratio = ""}
  pathway_id = paste(species,id,sep="")
  pathway_name = as.character(pathways_list[pathways_list[,1]==pathway_id,][2])
  
  if (id_type=="geneid" || id_type=="keggid") {
    row <- c(pathway_id,pathway_name,length(unique(geneID)),nb_kegg_id,nb_mapped,ratio,paste(mapped,collapse=";"))
    names(row) <- c("KEGG pathway ID","pathway name","nb of Entrez gene ID used","nb of Entrez gene ID mapped",
                    "nb of Entrez gene ID in the pathway", "ratio of Entrez gene ID mapped (%)","Entrez gene ID mapped")
  } else if (id_type=="uniprotid") {
    row <- c(pathway_id,pathway_name,length(unique(uniprotID)),length(unique(geneID)),nb_mapped,nb_kegg_id,ratio,paste(mapped,collapse=";"),paste(mapped2geneID[which(mapped2geneID[,2] %in% mapped)],collapse=";"))
    names(row) <- c("KEGG pathway ID","pathway name","nb of Uniprot_AC used","nb of Entrez gene ID used","nb of Entrez gene ID mapped",
                    "nb of Entrez gene ID in the pathway", "ratio of Entrez gene ID mapped (%)","Entrez gene ID mapped","uniprot_AC mapped")
  }
  return(row)
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
      --pathways_id           Id(s) of pathway(s) to use, if several, semicolon separated list : hsa00010;hsa05412 
      --id_type               Type of accession number ('uniprotID' or 'geneID')
      --id_column             Column containing accesion number of interest (ex : 'c1')
      --header                Boolean, TRUE if header FALSE if not
      --output                Output filename
      --fold_change_col       Column(s) containing fold change values (comma separated)
      --native_kegg           TRUE : native KEGG graph, FALSE : Graphviz graph
      --species               KEGG species (hsa, mmu, ...)
      --pathways_input        Tab with pathways in a column, output format of find_pathways
      --pathway_col           Column of pathways to use
      --header2               Boolean, TRUE if header FALSE if not
      --pathways_list         path of file containg the species pathways list (hsa_pathways.loc, mmu_pathways.loc, ...)

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

args <- get_args()

#save(args,file="/home/dchristiany/proteore_project/ProteoRE/tools/kegg_pathways_visualization/args.Rda")
#load("/home/dchristiany/proteore_project/ProteoRE/tools/kegg_pathways_visualization/args.Rda")

###setting variables
if (!is.null(args$pathways_id)) { 
  ids <- get_list_from_cp(clean_bad_character(args$pathways_id))
  ids <- sapply(ids, function(x) remove_kegg_prefix(x),USE.NAMES = FALSE)
}else if (!is.null(args$pathways_input)){
  header2 <- str2bool(args$header2)
  pathway_col <- as.numeric(gsub("c", "" ,args$pathway_col))
  pathways_file = read_file(args$pathways_input,header2)
  ids <- sapply(rapply(strsplit(clean_bad_character(pathways_file[,pathway_col]),","),c), function(x) remove_kegg_prefix(x),USE.NAMES = FALSE)
}
pathways_list <- read_file(args$pathways_list,F)
if (!is.null(args$id_list)) {
  id_list <- get_list_from_cp(args$id_list)
  }
id_type <- tolower(args$id_type)
ncol <- as.numeric(gsub("c", "" ,args$id_column))
header <- str2bool(args$header)
native_kegg <- str2bool(args$native_kegg)
species=args$species
fold_change_data = str2bool(args$fold_change_data)

#org list used in mapped2geneID
org <- c('Hs','Mm','Rn')
names(org) <- c('hsa','mmu','rno')

#read input file or list
if (!is.null(args$input)){
  tab <- read_file(args$input,header)
  tab <- data.frame(tab[which(tab[ncol]!=""),])
} else {
  tab <- data.frame(id_list,stringsAsFactors = F)
  ncol=1
}

#fold change columns
#make sure its double and name expression value columns
if (fold_change_data){
  fold_change <- as.integer(unlist(strsplit(gsub("c","",args$fold_change_col),",")))
  if (length(fold_change) > 3) { fold_change= fold_change[1:3] } 
  for (i in 1:length(fold_change)) {
    fc_col = fold_change[i]
    colnames(tab)[fc_col] <- paste("e",i,sep='')
    tab[,fc_col] <- as.double(gsub(",",".",as.character(tab[,fc_col]) ))
  }
}

##### map uniprotID to entrez geneID and kegg to geneID
if (id_type == "uniprotid") {
  uniprotID = tab[,ncol]
  mapped2geneID = id2eg(ids = uniprotID, category = "uniprot", org = org[[species]], pkg.name = NULL)
  geneID = mapped2geneID[,2]
  tab = cbind(tab,geneID)
}else if (id_type == "keggid"){
  keggID = tab[,ncol]  
  geneID = kegg_to_geneID(keggID)
  tab = cbind(tab,geneID)
}else if (id_type == "geneid"){
  colnames(tab)[ncol] <- "geneID"
}

geneID = as.character(tab$geneID[which(!is.na(tab$geneID))])
geneID = gsub(" ","",geneID)
geneID = unlist(strsplit(geneID,"[;]"))

##### build matrix to map on KEGG pathway (kgml : KEGG xml)
if (fold_change_data) {
  geneID_indices = which(!duplicated(geneID))
  if (length(fold_change) == 3){
    mat <- as.data.frame(cbind(tab$e1,tab$e2,tab$e3)[which(!is.na(tab$geneID)),])
    mat = mat[geneID_indices,]
    row.names(mat) <- geneID[geneID_indices]
  } else if (length(fold_change) == 2){
    mat <- as.data.frame(cbind(tab$e1,tab$e2)[which(!is.na(tab$geneID)),])
    mat = mat[geneID_indices,]
    row.names(mat) <- geneID[geneID_indices]
  } else {
    mat <- as.data.frame(cbind(tab$e1)[which(!is.na(tab$geneID)),])
    mat = mat[geneID_indices,]
    names(mat) <- geneID[geneID_indices]
  }
} else {
  mat <- geneID
}

#####mapping geneID (with or without expression values) on KEGG pathway
plot.col.key= TRUE
low_color = "green"
mid_color = "#F3F781" #yellow
high_color = "red"
if (is.null(tab$e1)) {
  plot.col.key= FALSE   #if there's no exrepession data, we don't show the color key
  high_color = "#81BEF7" #blue
}

#create graph(s) and text output
for (id in ids) {
  suffix= get_suffix(pathways_list,species,id)
  pv.out <- suppressMessages(pathview(gene.data = mat,
           gene.idtype = "entrez", 
           pathway.id = id,
           species = species, 
           kegg.dir = ".", 
           out.suffix=suffix,
           kegg.native = native_kegg,
           low = list(gene = low_color, cpd = "blue"), 
           mid = list(gene = mid_color, cpd = "transparent"), 
           high = list(gene = high_color, cpd = "yellow"), 
           na.col="#D8D8D8", #gray
           cpd.data=NULL,
           plot.col.key = plot.col.key,
           pdf.size=c(9,9)))
  
  if (is.list(pv.out)){
  
    #creating text file
    if (!exists("DF")) {
      DF <- data.frame(t(mapping_summary(pv.out,species,id,id_type)),stringsAsFactors = F,check.names = F)
    } else {
      #print (mapping_summary(pv.out,species,id))
      DF <- rbind(DF,data.frame(t(mapping_summary(pv.out,species,id,id_type)),stringsAsFactors = F,check.names = F))
    }
  }
    
}

DF <- as.data.frame(apply(DF, c(1,2), function(x) gsub("^$|^ $", NA, x)))  #convert "" et " " to NA

#text file output
write.table(DF,file=args$output,quote=FALSE, sep='\t',row.names = FALSE, col.names = TRUE)
