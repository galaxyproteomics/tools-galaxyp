# Read file and return file content as data.frame
readfile = function(filename, header) {
  if (header == "true") {
    # Read only first line of the file as header:
    headers <- read.table(filename, nrows = 1, header = FALSE, sep = "\t", stringsAsFactors = FALSE, fill = TRUE, na.strings=c("", "NA"), blank.lines.skip = TRUE, quote = "")
    #Read the data of the files (skipping the first row)
    file <- read.table(filename, skip = 1, header = FALSE, sep = "\t", stringsAsFactors = FALSE, fill = TRUE, na.strings=c("", "NA"), blank.lines.skip = TRUE, quote = "")
    # Remove empty rows
    file <- file[!apply(is.na(file) | file == "", 1, all), , drop=FALSE]
    #And assign the header to the data
    names(file) <- headers
  }
  else {
    file <- read.table(filename, header = FALSE, sep = "\t", stringsAsFactors = FALSE, fill = TRUE, na.strings=c("", "NA"), blank.lines.skip = TRUE, quote = "")
    # Remove empty rows
    file <- file[!apply(is.na(file) | file == "", 1, all), , drop=FALSE]
  }
  return(file)
}

protein_features = function() {
  args <- commandArgs(TRUE)
  if(length(args)<1) {
    args <- c("--help")
  }
  
  # Help section
  if("--help" %in% args) {
    cat("Selection and Annotation HPA
    Arguments:
        --inputtype: type of input (list of id or filename)
        --input: input
        --nextprot: path to nextprot information file
        --column: the column number which you would like to apply...
        --header: true/false if your file contains a header
        --type: the type of input IDs (UniProt/EntrezID)
        --argsP1: IsoPoint,SeqLength,MW
        --argsP2: Chr,SubcellLocations
        --argsP3: Diseases
        --output: text output filename \n")
    q(save="no")
  }
  
  # Parse arguments
  parseArgs <- function(x) strsplit(sub("^--", "", x), "=")
  argsDF <- as.data.frame(do.call("rbind", parseArgs(args)))
  args <- as.list(as.character(argsDF$V2))
  names(args) <- argsDF$V1 

  inputtype = args$inputtype
  if (inputtype == "copypaste") {
    input = strsplit(args$input, " ")[[1]]
  }
  else if (inputtype == "tabfile") {
    filename = args$input
    ncol = args$column
    # Check ncol
    if (! as.numeric(gsub("c", "", ncol)) %% 1 == 0) {
      stop("Please enter an integer for level")
    }
    else {
      ncol = as.numeric(gsub("c", "", ncol))
    }
    header = args$header
    # Get file content
    file = readfile(filename, header)
    # Extract Protein IDs list
    input = c()
    for (row in as.character(file[,ncol])) {
      input = c(input, strsplit(row, ";")[[1]][1])
    }
  }

  # Read reference file
  nextprot_file = args$nextprot
  nextprot = read.table(nextprot_file, header = TRUE, sep = "\t", stringsAsFactors = FALSE, fill = TRUE, na.strings = "", quote = "")
  
  # Parse arguments
  typeid = args$type
  P1_args = strsplit(args$argsP1, ",")[[1]]
  P2_args = strsplit(args$argsP2, ",")[[1]]
  P3_args = strsplit(args$argsP3, ",")[[1]]
  output = args$output

  # Change the sample ids if they are uniprot ids to be able to match them with
  # Nextprot data
  if (typeid=="uniprot"){
    input = gsub("^","NX_",input)
  }

  # Select user input protein ids in nextprot
  if ((length(input[input %in% nextprot[,1]]))==0){
    write.table("None of the input ids are can be found in Nextprot",file=filename,sep="\t",quote=FALSE,col.names=TRUE,row.names=FALSE)
  } else {
    names = c()
    res = matrix(nrow=length(input), ncol=0)

    # Get information from neXtProt
    if (length(P1_args)>0) {
      for (arg in P1_args) {
        names = c(names, arg)
        info = nextprot[match(input, nextprot["NextprotID"][,]),][arg][,]
        res = cbind(res, info)
      }
    }
    if (length(P2_args)>0) {
      for (arg in P2_args) {
        names = c(names, arg)
        info = nextprot[match(input, nextprot["NextprotID"][,]),][arg][,]
        res = cbind(res, info)
      }
    }
    if (length(P3_args)>0) {
      for (arg in P3_args) {
        names = c(names, arg)
        info = nextprot[match(input, nextprot["NextprotID"][,]),][arg][,]
        res = cbind(res, info)
      }
    }

    # Write output
    if (inputtype == "copypaste") {
      res = cbind(as.matrix(input), res)
      names = c(typeid, names)
      colnames(res) = names
      write.table(res, output, row.names = FALSE, sep = "\t", quote = FALSE)
    }
    else if (inputtype == "tabfile") {
      names = c(names(file), names)
      output_content = cbind(file, res)
      colnames(output_content) = names
      write.table(output_content, output, row.names = FALSE, sep = "\t", quote = FALSE)
    }
  } 

}
protein_features()
