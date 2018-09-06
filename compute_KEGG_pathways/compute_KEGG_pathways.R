library(KEGGREST)

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
      --id_list      
id list ',' separated
      --id_type               type of input ids (uniprot_AC or geneID)
      --id_column             number og column containg ids of interest
      --nb_pathways           number of pathways to return
      --header                boolean
      --output                output path
      --ref                  ref file (l.hsa.gene.RData, l.hsa.up.RData, l.mmu.up.Rdata)

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

args <- get_args()

#save(args,file="/home/dchristiany/proteore_project/ProteoRE/tools/compute_KEGG_pathways/args.Rda")
#load("/home/dchristiany/proteore_project/ProteoRE/tools/compute_KEGG_pathways/args.Rda")

##function arguments :  
## id.ToMap = input from the user to map on the pathways = list of IDs
## idType : must be "UNIPROT" or "ENTREZ"
## org : for the moment can be "Hs" only. Has to evoluate to "Mm"

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
  file <- try(read.table(path,header=header, sep="\t",stringsAsFactors = FALSE, quote=""),silent=TRUE)
  if (inherits(file,"try-error")){
    stop("File not found !")
  }else{
    return(file)
  }
}

ID2KEGG.Mapping<- function(id.ToMap,ref) {
    
    ref_ids = get(load(ref))
    map<-lapply(ref_ids, is.element, unique(id.ToMap))
    names(map) <- sapply(names(map), function(x) gsub("path:","",x),USE.NAMES = FALSE)    #remove the prefix "path:"
    
    in.path<-sapply(map, function(x) length(which(x==TRUE)))
    tot.path<-sapply(map, length)
    
    ratio<-(as.numeric(in.path[which(in.path!=0)])) / (as.numeric(tot.path[which(in.path!=0)]))
    ratio <- as.numeric(format(round(ratio*100, 2), nsmall = 2))
    
    ##useful but LONG
    ## to do before : in step 1
    path.names<-names(in.path[which(in.path!=0)])
    name <- sapply(path.names, function(x) keggGet(x)[[1]]$NAME,USE.NAMES = FALSE)
    
    res<-data.frame(I(names(in.path[which(in.path!=0)])), I(name), ratio, as.numeric(in.path[which(in.path!=0)]), as.numeric(tot.path[which(in.path!=0)]))
    res <- res[order(as.numeric(res[,3]),decreasing = TRUE),]
    colnames(res)<-c("pathway_ID", "Description" , "Ratio IDs mapped/total IDs (%)" ,"# genes mapped in the pathway", "# total genes present in the pathway")
    
    return(res)
    
}

###setting variables
header = str2bool(args$header)
if (!is.null(args$id_list)) {id_list <- strsplit(args$id_list,",")[[1]]}
if (!is.null(args$input)) { 
  csv <- read_file(args$input,header)
  ncol <- as.numeric(gsub("c", "" ,args$id_column))
  id_list <- as.vector(csv[,ncol])
}
id_type <- toupper(args$id_type)

#mapping on pathways
res <- ID2KEGG.Mapping(id_list,args$ref)
if (nrow(res) > as.numeric(args$nb_pathways)) { res <- res[1:args$nb_pathways,] }

write.table(res, file=args$output, quote=FALSE, sep='\t',row.names = FALSE, col.names = TRUE)

