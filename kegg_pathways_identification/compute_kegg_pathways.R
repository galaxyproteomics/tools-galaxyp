options(warn=-1)  #TURN OFF WARNINGS !!!!!!

suppressMessages(library(KEGGREST))

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
      --input                 tab file
      --id_list               id list ',' separated
      --id_type               type of input ids (kegg-id, uniprot_AC,geneID)
      --id_column             number og column containg ids of interest
      --nb_pathways           number of pathways to return
      --header                boolean
      --output                output path
      --species               species used to get specific pathways (hsa,mmu,rno)

      Example:
      Rscript keggrest.R --input='P31946,P62258' --id_type='uniprot' --id_column 'c1' --header TRUE \n\n")
    
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

read_file <- function(path,header){
  file <- try(read.csv(path,header=header, sep="\t",stringsAsFactors = FALSE, quote="\""),silent=TRUE)
  if (inherits(file,"try-error")){
    stop("File not found !")
  }else{
    return(file)
  }
}

get_pathways_list <- function(species){
  ##all available pathways for the species
  pathways <-keggLink("pathway", species)
  tot_path<-unique(pathways)
  
  ##formating the dat into a list object
  ##key= pathway ID, value = genes of the pathway in the kegg format
  pathways_list <- sapply(tot_path, function(pathway) names(which(pathways==pathway)))
  return (pathways_list)
}

get_list_from_cp <-function(list){
  list = strsplit(list, "[ \t\n]+")[[1]]
  list = list[list != ""]    #remove empty entry
  list = gsub("-.+", "", list)  #Remove isoform accession number (e.g. "-2")
  return(list)
}

kegg_mapping<- function(id_list,id_type,ref_ids) {
  
    #convert to KEGG ID
    if (id_type!="kegg-id"){
      id_list <- unique(sapply(id_list, function(x) paste(id_type,":",x,sep=""),USE.NAMES = F))
      if (length(id_list)>250){
        id_list <- split(id_list, ceiling(seq_along(id_list)/250))
        id_list <- sapply(id_list, function(x) keggConv("genes",x))
        kegg_id_list <- unique(unlist(id_list))
      } else {
      kegg_id_list <- unique(keggConv("genes", id_list))
      }
    } else {
      kegg_id_list <- unique(id_list)
    }
  
    #mapping
    map<-lapply(ref_ids, is.element, unique(kegg_id_list))
    names(map) <- sapply(names(map), function(x) gsub("path:","",x),USE.NAMES = FALSE)    #remove the prefix "path:"
    
    in.path<-sapply(map, function(x) length(which(x==TRUE)))
    tot.path<-sapply(map, length)
    
    ratio <- (as.numeric(in.path[which(in.path!=0)])) / (as.numeric(tot.path[which(in.path!=0)]))
    ratio <- as.numeric(format(round(ratio*100, 2), nsmall = 2))
    
    ##useful but LONG
    ## to do before : in step 1
    path.names<-names(in.path[which(in.path!=0)])
    name <- sapply(path.names, function(x) keggGet(x)[[1]]$NAME,USE.NAMES = FALSE)
    
    res<-data.frame(I(names(in.path[which(in.path!=0)])), I(name), ratio, as.numeric(in.path[which(in.path!=0)]), as.numeric(tot.path[which(in.path!=0)]))
    res <- res[order(as.numeric(res[,3]),decreasing = TRUE),]
    colnames(res)<-c("pathway_ID", "Description" , "Ratio IDs mapped/total IDs (%)" ,"nb KEGG genes IDs mapped in the pathway", "nb total of KEGG genes IDs present in the pathway")
    
    return(res)
    
}

#get args from command line
args <- get_args()

#save(args,file="/home/dchristiany/proteore_project/ProteoRE/tools/kegg_pathways_identification/args.Rda")
#load("/home/dchristiany/proteore_project/ProteoRE/tools/kegg_pathways_identification/args.Rda")

###setting variables
header = str2bool(args$header)
if (!is.null(args$id_list)) {id_list <- get_list_from_cp(args$id_list)}
if (!is.null(args$input)) { 
  csv <- read_file(args$input,header)
  ncol <- as.numeric(gsub("c", "" ,args$id_column))
  id_list <- as.vector(csv[,ncol])
  id_list <- id_list[which(!is.na(id_list))]
}

#get pathways of species with associated KEGG ID genes
pathways_list <- get_pathways_list(args$species)

#mapping on pathways
res <- kegg_mapping(id_list,args$id_type,pathways_list)
if (nrow(res) > as.numeric(args$nb_pathways)) { res <- res[1:args$nb_pathways,] }

write.table(res, file=args$output, quote=FALSE, sep='\t',row.names = FALSE, col.names = TRUE)

