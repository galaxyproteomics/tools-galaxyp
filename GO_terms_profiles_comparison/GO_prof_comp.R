options(warn=-1)  #TURN OFF WARNINGS !!!!!!
suppressMessages(library(clusterProfiler,quietly = TRUE))

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

get_args <- function(){
  
  ## Collect arguments
  args <- commandArgs(TRUE)
  
  ## Default setting when no arguments passed
  if(length(args) < 1) {
    args <- c("--help")
  }
  
  ## Help section
  if("--help" %in% args) {
    cat("Selection and Annotation HPA
      Arguments:
      --inputtype1: type of input (list of id or filename)
      --inputtype2: type of input (list of id or filename)
      --input1: input1
      --input2: input2
      --column1: the column number which you would like to apply...
      --column2: the column number which you would like to apply...
      --header1: true/false if your file contains a header
      --header2: true/false if your file contains a header
      --ont: ontology to use
      --lev: ontology level
      --org: organism db package
      --list_name1: name of the first list
      --list_name2: name of the second list \n")
        
    q(save="no")
  }
  
  parseArgs <- function(x) strsplit(sub("^--", "", x), "=")
  argsDF <- as.data.frame(do.call("rbind", parseArgs(args)))
  args <- as.list(as.character(argsDF$V2))
  names(args) <- argsDF$V1
  
  return(args)
}

get_ids=function(inputtype, input, ncol, header) {

    if (inputtype == "text") {
      ids = strsplit(input, "[ \t\n]+")[[1]]
    } else if (inputtype == "file") {
      header=str2bool(header)
      ncol=get_cols(ncol)
      csv = read.csv(input,header=header, sep="\t", as.is=T)
      ids=csv[,ncol]
    }

    ids = unlist(strsplit(as.character(ids),";"))
    ids = ids[which(!is.na(ids))]

    return(ids)
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

check_ids <- function(vector,type) {
  uniprot_pattern = "^([OPQ][0-9][A-Z0-9]{3}[0-9]|[A-NR-Z][0-9]([A-Z][A-Z0-9]{2}[0-9]){1,2})$"
  entrez_id = "^([0-9]+|[A-Z]{1,2}_[0-9]+|[A-Z]{1,2}_[A-Z]{1,4}[0-9]+)$"
  if (type == "entrez")
    return(grepl(entrez_id,vector))
  else if (type == "uniprot") {
    return(grepl(uniprot_pattern,vector))
  }
}

make_dotplot<-function(res.cmp,ontology) {
  
  res.cmp@compareClusterResult$Description <- sapply(as.vector(res.cmp@compareClusterResult$Description), function(x) {ifelse(nchar(x)>50, substr(x,1,50),x)},USE.NAMES = FALSE)
  output_path= paste("GO_profiles_comp_",ontology,".png",sep="")
  png(output_path,height = 720, width = 600)
	p <- dotplot(res.cmp, showCategory=30)
	print(p)
	dev.off()
}

get_cols <-function(input_cols) {
  input_cols <- gsub("c","",gsub("C","",gsub(" ","",input_cols)))
  if (grepl(":",input_cols)) {
    first_col=unlist(strsplit(input_cols,":"))[1]
    last_col=unlist(strsplit(input_cols,":"))[2]
    cols=first_col:last_col
  } else {
    cols = as.integer(unlist(strsplit(input_cols,",")))
  }
  return(cols)
}

#to check
cmp.GO <- function(l,fun="groupGO",orgdb, ontology, level=3, readable=TRUE) {
  cmpGO<-compareCluster(geneClusters = l,
                        fun=fun, 
                        OrgDb = orgdb, 
                        ont=ontology, 
                        level=level, 
                        readable=TRUE)
  
  return(cmpGO)
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

main = function() {
  
  #to get the args of the command line
  args=get_args()  
  
  #save(args,file="/home/dchristiany/proteore_project/ProteoRE/tools/GO_terms_profiles_comparison/args.rda")
  #load("/home/dchristiany/proteore_project/ProteoRE/tools/GO_terms_profiles_comparison/args.rda")
  
  ids1<-get_ids(args$inputtype1, args$input1, args$column1, args$header1) 
  ids2<-get_ids(args$inputtype2, args$input2, args$column2, args$header2)
  ont = strsplit(args$ont, ",")[[1]] 
  lev=as.integer(args$lev)
  org=args$org
  
  #load annot package 
  suppressMessages(library(args$org, character.only = TRUE, quietly = TRUE))
  
  # Extract OrgDb
  if (args$org=="org.Hs.eg.db") {
    orgdb<-org.Hs.eg.db
  } else if (args$org=="org.Mm.eg.db") {
    orgdb<-org.Mm.eg.db
  } else if (args$org=="org.Rn.eg.db") {
    orgdb<-org.Rn.eg.db
  }

  for(ontology in ont) {
    liste = list("l1"=ids1,"l2"=ids2)
    names(liste) = c(args$list_name1,args$list_name2)
    res.cmp<-cmp.GO(l=liste,fun="groupGO",orgdb, ontology, level=lev, readable=TRUE)
    make_dotplot(res.cmp,ontology)  
    output_path = paste("GO_profiles_comp_",ontology,".tsv",sep="")
    write.table(res.cmp@compareClusterResult, output_path, sep="\t", row.names=F, quote=F)
  }
  
} #end main 

main()

