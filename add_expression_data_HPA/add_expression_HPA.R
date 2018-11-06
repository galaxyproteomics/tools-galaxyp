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
  if (all(!input %in% atlas$Ensembl)) {
    return(NULL)
  }
  else {
    res = matrix(nrow=length(input), ncol=0)
    names = c()
    for (opt in options) {
      names = c(names, opt)
      info = atlas[match(input, atlas$Ensembl,incomparable="NA"),][opt][,]
      res = cbind(res, info)
    }
    colnames(res) = names
    return(res)
  }
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

  save(args,file="/home/dchristiany/proteore_project/ProteoRE/tools/add_expression_data_HPA/args.rda")
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
    input =  unlist(sapply(as.character(file[,ncol]),function(x) rapply(strsplit(x,";"),c),USE.NAMES = FALSE))
  }

  # Read protein atlas
  protein_atlas = args$atlas
  protein_atlas = read_file(protein_atlas, T)

  # Add expression
  output = args$output
  options = strsplit(args$select, ",")[[1]]
  res = add_expression(input, protein_atlas, options)
  res <- apply(res, c(1,2), function(x) gsub("^$|^ $", NA, x))  #convert "" et " " to NA

  # Write output
  if (is.null(res)) {
    write.table("None of the input ENSG ids are can be found in HPA data file",file=output,sep="\t",quote=FALSE,col.names=TRUE,row.names=FALSE)
  }
  else {
    if (inputtype == "copypaste") {
      output_content = cbind(as.matrix(input), res)
      colnames(output_content)[1] = "Ensembl"
    } else if (inputtype == "tabfile") {
      output_content = cbind(file, res)
    }
  write.table(output_content, output, row.names = FALSE, sep = "\t", quote = FALSE)
  }
}

main()
