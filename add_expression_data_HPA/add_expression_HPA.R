# Read file and return file content as data.frame
read_file <- function(path,header){
  file <- try(read.csv(path,header=header, sep="\t",stringsAsFactors = FALSE, quote="\"", check.names = F),silent=TRUE)
  if (inherits(file,"try-error")){
    stop("File not found !")
  }else{
    return(file)
  }
}

#convert a string to boolean
str2bool <- function(x){
  if (any(is.element(c("t","true"),tolower(x)))){
    return (TRUE)
  }else if (any(is.element(c("f","false"),tolower(x)))){
    return (FALSE)
  }else{
    return(NULL)
  }
}

stopQuietly <- function(...) {
  blankMsg <- sprintf("\r%s\r", paste(rep(" ", getOption("width")-1L), collapse=" "));
  stop(simpleError(blankMsg));
} # stopQuietly()

check_ensembl_geneids <- function(vector,type) {
  ensembl_geneid_pattern = "^ENS[A-Z]+[0-9]{11}$|^[A-Z]{3}[0-9]{3}[A-Za-z](-[A-Za-z])?$|^CG[0-9]+$|^[A-Z0-9]+[.][0-9]+$|^YM[A-Z][0-9]{3}[a-z][0-9]$"
  res = grepl(ensembl_geneid_pattern,vector)
  if (all(!res)){
    cat("No Ensembl geneIDs found in entered ids")
    stopQuietly()
  } else if (any(!res)) {
    cat(paste(sep="",collapse = " ",c(sum(!res, na.rm=TRUE),'IDs are not ENSG IDs, please check:\n')))
    not_geneids <- sapply(vector[which(!res)], function(x) paste(sep="",collapse = "",x,"\n"),USE.NAMES = F)
    cat(not_geneids)
  }
}

add_expression = function(input, atlas, options) {
  input <- unique(input[!is.na(input)])
  input <- gsub("[[:blank:]]|\u00A0","",input)
  if (all(!input %in% atlas$Ensembl)) {
    return(NULL)
  } else {
    res = atlas[match(input,atlas$Ensembl),c("Ensembl",options)]
    res = res[which(!is.na(res[,1])),]
    row.names(res)=res[,1]
    res=res[2:ncol(res)]
    res <- as.data.frame(apply(res, c(1,2), function(x) gsub("^$|^ $", NA, x)))  #convert "" et " " to NA
    return(res)
  }
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
  
  if (ncol(tab)>1){
    
    tab[,ncol] = sapply(tab[,ncol],function(x) gsub("[[:blank:]]","",x))
    header=colnames(tab)
    res=as.data.frame(matrix(ncol=ncol(tab),nrow=0))
    for (i in 1:nrow(tab) ) {
      lines = split_ids_per_line(tab[i,],ncol)
      res = rbind(res,lines)
    }
  }else {
    res = unlist(sapply(tab[,1],function(x) strsplit(x,";")),use.names = F)
    res = data.frame(res[which(!is.na(res[res!=""]))],stringsAsFactors = F)
    colnames(res)=colnames(tab)
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
        --inputtype: type of input (list of id or filename)
        --input: either a file name (e.g : input.txt) or a list of blank-separated
                 ENSG identifiers (e.g : ENSG00000283071 ENSG00000283072)
        --atlas: path to protein atlas file
        --column: the column number which you would like to apply...
        --header: true/false if your file contains a header
        --select: information from HPA to select, maybe: 
                  RNA.tissue.category,Reliability..IH.,Reliability..IF. (comma-separated)
        --output: text output filename \n")
    q(save="no")
  }
  
  # Parse arguments
  parseArgs <- function(x) strsplit(sub("^--", "", x), "=")
  argsDF <- as.data.frame(do.call("rbind", parseArgs(args)))
  args <- as.list(as.character(argsDF$V2))
  names(args) <- argsDF$V1
  
  return(args)
}

is_col_in_file <- function(file,ncol) { 
  is_in_file = (ncol <= ncol(file) && ncol > 0)
  if (!is_in_file){
    cat(paste(sep = "", collapse = " ", c("Column",ncol,"not found in file") ))
    stopQuietly()
  }
}

convert_to_previous_header <- function(options){
    header = c('Gene','description','Evidence','Antibody','RNA tissue specificity','Reliability (IH)','Reliability (IF)','Subcellular location','RNA tissue specific NX','TPM max in non-specific')
    names(header) = c('Gene','description','Evidence','Antibody','RNA tissue category','Reliability (IH)','Reliability (IF)','Subcellular location','RNA TS TPM','TPM max in non-specific')
    options = names(header[which(header %in% options)])
    return(options)
}

main = function() {
  
  args = get_args()

  #save(args,file="/home/dchristiany/proteore_project/ProteoRE/tools/add_expression_data_HPA/args.rda")
  load("/home/dchristiany/proteore_project/ProteoRE/tools/add_expression_data_HPA/args.rda")
  
  inputtype = args$inputtype
  if (inputtype == "copypaste") {
    ids = strsplit(args$input, "[ \t\n]+")[[1]]
  } else if (inputtype == "tabfile") {
    filename = args$input
    ncol = args$column
    # Check ncol
    if (! as.numeric(gsub("c", "", ncol)) %% 1 == 0) {
      stop("Please enter an integer for level")
    } else {
      ncol = as.numeric(gsub("c", "", ncol))
    }
    header = str2bool(args$header)
    file = read_file(filename, header)
    is_col_in_file(file,ncol)
    file = one_id_one_line(file,ncol)
    ids = unlist(sapply(as.character(file[,ncol]),function(x) rapply(strsplit(x,";"),c),USE.NAMES = FALSE))
    ids = ids[which(!is.na(ids))]
  }
  check_ensembl_geneids(ids)

  # Read protein atlas
  protein_atlas = read_file(args$atlas, T)

  # Add expression
  output = args$output
  options = strsplit(args$select, ",")[[1]]
  if (tail(unlist(strsplit(args$atlas,"/")),1) == "HPA_full_atlas_23-10-2018.tsv"){ 
      options = convert_to_previous_header(options)
  } else {
      options = options[which(options != 'TPM max in non-specific')]
      }
  res = add_expression(ids, protein_atlas, options)
  
  # Write output
  if (is.null(res)) {
    write.table("None of the ENSG ids entered can be found in HPA data file",file=output,sep="\t",quote=FALSE,col.names=TRUE,row.names=FALSE)
  } else {
    if (inputtype == "copypaste") {
      ids <- data.frame(ids)
      output_content = merge(ids,res,by.x=1,by.y="row.names",incomparables = NA, all.x=T)
      colnames(output_content)[1] = "Ensembl"
    } else if (inputtype == "tabfile") {
      output_content = merge(file, res, by.x=ncol, by.y="row.names", incomparables = NA, all.x=T)
      output_content = order_columns(output_content,ncol)
    }
  output_content <- as.data.frame(apply(output_content, c(1,2), function(x) gsub("^$|^ $", NA, x)))
  write.table(output_content, output, row.names = FALSE, sep = "\t", quote = FALSE)
  }
}

main()
