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

add_expression = function(input, atlas, options) {
  input <- unique(input[!is.na(input)])
  input <- gsub("[[:blank:]]","",input)
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
  
  tab[,ncol] = sapply(tab[,ncol],function(x) gsub("[[:blank:]]","",x))
  header=colnames(tab)
  res=as.data.frame(matrix(ncol=ncol(tab),nrow=0))
  for (i in 1:nrow(tab) ) {
    lines = split_ids_per_line(tab[i,],ncol)
    res = rbind(res,lines)
  }
  return(res)
}

main = function() {
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

  #save(args,file="/home/dchristiany/proteore_project/ProteoRE/tools/add_expression_data_HPA/args.rda")
  #load("/home/dchristiany/proteore_project/ProteoRE/tools/add_expression_data_HPA/args.rda")
  
  inputtype = args$inputtype
  if (inputtype == "copypaste") {
    input = strsplit(args$input, "[ \t\n]+")[[1]]
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
    file = one_id_one_line(file,ncol)
    input = unlist(sapply(as.character(file[,ncol]),function(x) rapply(strsplit(x,";"),c),USE.NAMES = FALSE))
    input = input[which(!is.na(input))]
  }

  # Read protein atlas
  protein_atlas = args$atlas
  protein_atlas = read_file(protein_atlas, T)

  # Add expression
  output = args$output
  options = strsplit(args$select, ",")[[1]]
  res = add_expression(input, protein_atlas, options)
  
  # Write output
  if (is.null(res)) {
    write.table("None of the input ENSG ids are can be found in HPA data file",file=output,sep="\t",quote=FALSE,col.names=TRUE,row.names=FALSE)
  } else {
    if (inputtype == "copypaste") {
      input <- data.frame(input)
      output_content = merge(input,res,by.x=1,by.y="row.names",incomparables = NA, all.x=T)
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
