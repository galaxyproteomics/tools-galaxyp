# Read file and return file content as data.frame
read_file <- function(path,header){
  file <- try(read.table(path,header=header, sep="\t",stringsAsFactors = FALSE, quote=""),silent=TRUE)
  if (inherits(file,"try-error")){
    stop("File not found !")
  }else{
    file <- file[!apply(is.na(file) | file == "", 1, all), , drop=FALSE]
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
    cat("Selection and Annotation HPA
        Arguments:
          --inputtype: type of input (list of id or filename)
        --input: input
        --nextprot: path to nextprot information file
        --column: the column number which you would like to apply...
        --header: true/false if your file contains a header
        --type: the type of input IDs (UniProt/EntrezID)
        --pc_features: IsoPoint,SeqLength,MW
        --localization: Chr,SubcellLocations
        --diseases_info: Diseases
        --output: text output filename \n")
    
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

# Get information from neXtProt
get_nextprot_info <- function(nextprot,input,pc_features,localization,diseases_info){
  if(diseases_info){
    cols = c("NextprotID",pc_features,localization,"Diseases")
  } else {
    cols = c("NextprotID",pc_features,localization)
  }
  
  info = nextprot[match(input,nextprot$NextprotID),cols]
  return(info)
}

protein_features = function() {

  args <- get_args()  
  
  #save(args,file="/home/dchristiany/proteore_project/ProteoRE/tools/prot_features/args.rda")
  #load("/home/dchristiany/proteore_project/ProteoRE/tools/prot_features/args.rda")
  
  #setting variables
  inputtype = args$inputtype
  if (inputtype == "copypaste") {
    input = strsplit(args$input, "[ \t\n]+")[[1]]
  } else if (inputtype == "file") {
    filename = args$input
    ncol = args$column
    # Check ncol
    if (! as.numeric(gsub("c", "", ncol)) %% 1 == 0) {
      stop("Please enter an integer for level")
    } else {
      ncol = as.numeric(gsub("c", "", ncol))
    }
    
    header = str2bool(args$header)
    file = read_file(filename, header)                        # Get file content
    input = unlist(strsplit(as.character(file[,ncol]),";"))   # Extract Protein IDs list
    colnames(file)[ncol] <- "NextprotID"
  
  }

  # Read reference file
  nextprot = read_file(args$nextprot,T)
  
  # Parse arguments
  typeid = args$type
  pc_features = strsplit(args$pc_features, ",")[[1]]
  localization = strsplit(args$localization, ",")[[1]]
  diseases_info = str2bool(args$diseases_info)
  output = args$output

  # Change the sample ids if they are uniprot ids to be able to match them with
  # Nextprot data
  if (typeid=="uniprot"){
    input = gsub("^","NX_",input)
  }

  # Select user input protein ids in nextprot
  if ((length(input[input %in% nextprot[,1]]))==0){
    write.table("None of the input ids can be found in Nextprot",file=output,sep="\t",quote=FALSE,col.names=TRUE,row.names=FALSE)
  } else {
    res <- get_nextprot_info(nextprot,input,pc_features,localization,diseases_info)
  
    # Write output
    if (inputtype == "copypaste") {
      res = cbind(as.matrix(input), res)
      colnames(res)[1] = typeid
      write.table(res, output, row.names = FALSE, sep = "\t", quote = FALSE)
    }
    else if (inputtype == "file") {
      output_content = merge(file, res,by="NextprotID",incomparables = NA,all.x=T)
      output_content = output_content[,c(2:ncol,1,(ncol+1):dim.data.frame(output_content)[2])]
      write.table(output_content, output, row.names = FALSE, sep = "\t", quote = FALSE)
    }
  } 

}
protein_features()
