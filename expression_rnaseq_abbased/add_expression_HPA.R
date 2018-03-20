# Read file and return file content as data.frame
readfile = function(filename, header) {
  if (header == "true") {
    # Read only first line of the file as header:
    headers <- read.table(filename, nrows = 1, header = FALSE, sep = "\t", stringsAsFactors = FALSE, fill = TRUE, na.strings=c("", "NA"), blank.lines.skip = TRUE, quote = "", comment.char = "")
    #Read the data of the files (skipping the first row)
    file <- read.table(filename, skip = 1, header = FALSE, sep = "\t", stringsAsFactors = FALSE, fill = TRUE, na.strings=c("", "NA"), blank.lines.skip = TRUE, quote = "", comment.char = "")
    # Remove empty rows
    file <- file[!apply(is.na(file) | file == "", 1, all), , drop=FALSE]
    #And assign the header to the data
    names(file) <- headers
  }
  else {
    file <- read.table(filename, header = FALSE, sep = "\t", stringsAsFactors = FALSE, fill = TRUE, na.strings=c("", "NA"), blank.lines.skip = TRUE, quote = "", comment.char = "")
    # Remove empty rows
    file <- file[!apply(is.na(file) | file == "", 1, all), , drop=FALSE]
  }
  return(file)
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

  inputtype = args$inputtype
  if (inputtype == "copypaste") {
    input = strsplit(args$input, "[ \t\n]+")[[1]]
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

  # Read protein atlas
  protein_atlas = args$atlas
  protein_atlas = readfile(protein_atlas, "true")

  # Add expression
  output = args$output
  names = c()
  options = strsplit(args$select, ",")[[1]]
  res = add_expression(input, protein_atlas, options)

  # Write output
  if (is.null(res)) {
    write.table("None of the input ENSG ids are can be found in HPA data file",file=output,sep="\t",quote=FALSE,col.names=TRUE,row.names=FALSE)
  }
  else {
    if (inputtype == "copypaste") {
      names = c("Ensembl", colnames(res))
      res = cbind(as.matrix(input), res)
      colnames(res) = names
      write.table(res, output, row.names = FALSE, sep = "\t", quote = FALSE)
    }
    else if (inputtype == "tabfile") {
      names = c(names(file), colnames(res))
      output_content = cbind(file, res)
      colnames(output_content) = names
      write.table(output_content, output, row.names = FALSE, sep = "\t", quote = FALSE)
    }
  }

}

main()
