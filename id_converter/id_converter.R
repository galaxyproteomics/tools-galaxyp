# Read file and return file content as data.frame
read_file <- function(path,header){
  file <- try(read.csv(path,header=header, sep="\t",stringsAsFactors = FALSE, quote="\"",check.names = F),silent=TRUE)
  if (inherits(file,"try-error")){
    stop("File not found !")
  }else{
    return(file)
  }
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

mapping_ids <- function(list_id,input_id_type,ref_file,options){
  list_id = list_id[!is.na(list_id)]
  if (!any(grep(";",ref_file[input_id_type]))) {
    res <- ref_file[match(list_id,ref_file[input_id_type][,]),c(input_id_type,options)]
    res=as.data.frame(res)
    res=res[which(!is.na(res[,1])),]
    row.names(res)=res[,1]
    res=res[2:ncol(res)]
    } else {
      if (length(options) > 1) {
        res <- data.frame(t(sapply(list_id, function(x) apply(ref_file[grep(x,ref_file[input_id_type][,]),options],2,function(y) paste(y[y!=""],sep="",collapse=";")) )))
      } else if (length(options)==1){
        res <- data.frame(sapply(list_id, function(x) gsub(";+$","",paste(ref_file[grep(x,ref_file[input_id_type][,]),options],sep="",collapse=";"))))
        colnames(res)=options
      }
    }
  
  return (res)
}

get_list_from_cp <-function(list){
  list = strsplit(list, "[ \t\n]+")[[1]]
  list = list[list != ""]    #remove empty entry
  list = gsub("-.+", "", list)  #Remove isoform accession number (e.g. "-2")
  return(list)
}

order_columns <- function (df,ncol){
  if (ncol==1){ #already at the right position
    return (df)
  } else {
    df = df[,c(2:ncol,1,(ncol+1):dim.data.frame(df)[2])]
  }
  return (df)
}

#take data frame, return  data frame
split_ids_per_line <- function(line,ncol){
  
  #print (line)
  header = colnames(line)
  line[ncol] = gsub("[[:blank:]]","",line[ncol])
  
  if (length(unlist(strsplit(as.character(line[ncol]),";")))>1) {
    if (length(line)==1 ) {
      lines = as.data.frame(unlist(strsplit(as.character(line[ncol]),";")),stringsAsFactors = F)
    } else {
        if (ncol==1) {                                #first column
        lines = suppressWarnings(cbind(unlist(strsplit(as.character(line[ncol]),";")), line[2:length(line)]))
      } else if (ncol==length(line)) {                 #last column
        lines = suppressWarnings(cbind(line[1:ncol-1],unlist(strsplit(as.character(line[ncol]),";"))))
      } else {
        lines = suppressWarnings(cbind(line[1:ncol-1], unlist(strsplit(as.character(line[ncol]),";"),use.names = F), line[(ncol+1):length(line)]))
      }
    }
    colnames(lines)=header
    return(lines)
  } else {
    return(line)
  }
}
 
#create new lines if there's more than one id per cell in the columns in order to have only one id per line
one_id_one_line <-function(tab,ncol){
  
  tab[,ncol] = sapply(tab[,ncol],function(x) gsub("[[:blank:]]","",x))
  header=colnames(tab)
  res=as.data.frame(matrix(ncol=ncol(tab),nrow=0))
  for (i in 1:nrow(tab) ) {
      lines = split_ids_per_line(tab[i,],ncol)
      res = rbind(res,lines)
  }
  return(res)
}

get_args <- function(){
  args <- commandArgs(TRUE)
  if(length(args)<1) {
    args <- c("--help")
  }
  
  # Help section
  if("--help" %in% args) {
    cat("Selection and Annotation HPA
    Arguments:
        --ref_file: path to reference file (id_mapping_file.txt)
        --input_type: type of input (list of id or filename)
        --id_type: type of input IDs
        --input: list of IDs (text or filename)
        --column_number: the column number which contains list of input IDs
        --header: true/false if your file contains a header
        --target_ids: target IDs to map to 
        --output: output filename \n")
    q(save="no")
  }
  
  # Parse arguments
  parseArgs <- function(x) strsplit(sub("^--", "", x), "=")
  argsDF <- as.data.frame(do.call("rbind", parseArgs(args)))
  args <- as.list(as.character(argsDF$V2))
  names(args) <- argsDF$V1
  
  return(args)
}

mapping = function() {
  
  args <- get_args()
  
  #save(args,file="/home/dchristiany/proteore_project/ProteoRE/tools/id_converter/args.rda")
  #load("/home/dchristiany/proteore_project/ProteoRE/tools/id_converter/args.rda")
  
  input_id_type = args$id_type # Uniprot, ENSG....
  list_id_input_type = args$input_type # list or file
  options = strsplit(args$target_ids, ",")[[1]]
  output = args$output
  id_mapping_file = args$ref_file
    
  # Extract input IDs
  if (list_id_input_type == "list") {
    list_id = get_list_from_cp(args$input)
  } else if (list_id_input_type == "file") {
    filename = args$input
    column_number = as.numeric(gsub("c", "" ,args$column_number))
    header = str2bool(args$header)
    file_all = read_file(filename, header)
    file_all = one_id_one_line(file_all,column_number)
    list_id = trimws(gsub("[$,\xc2\xa0]","",sapply(strsplit(as.character(file_all[,column_number]), ";"), "[", 1)))
    # Remove isoform accession number (e.g. "-2")
    list_id = unique(gsub("-.+", "", list_id))
  }

  # Extract ID maps
  id_map = read_file(id_mapping_file, T)
    
  # Map IDs
  res <- mapping_ids(list_id,input_id_type,id_map,options)

  #merge data frames
  if (list_id_input_type == "list"){
    list_id <- data.frame(list_id)
    output_content = merge(list_id,res,by.x=1,by.y="row.names",incomparables = NA, all.x=T)
    colnames(output_content)[1]=input_id_type
  } else if (list_id_input_type == "file") {
    output_content = merge(file_all,res,by.x=column_number,by.y="row.names",incomparables = NA, all.x=T)
    output_content = order_columns(output_content,column_number)
  }
  
  #write output
  header=colnames(output_content)
  output_content <- as.data.frame(apply(output_content, c(1,2), function(x) gsub("^$|^ $", NA, x)))
  colnames(output_content)=header
  write.table(output_content, output, row.names = FALSE, sep = '\t', quote = FALSE)
}

mapping()

#Rscript id_converter_UniProt.R "UniProt.AC" "test-data/UnipIDs.txt,c1,false" "file" "Ensembl_PRO,Ensembl,neXtProt_ID" "test-data/output.txt" ../../utils/mapping_file.txt
