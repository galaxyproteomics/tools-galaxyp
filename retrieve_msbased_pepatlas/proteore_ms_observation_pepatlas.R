# Read file and return file content as data.frame
readfile <- function(filename, header) {
  if (header == "true") {
    # Read only first line of the file as header:
    headers <- try(read.table(filename, nrows = 1, header = FALSE, sep = "\t", stringsAsFactors = FALSE, fill = TRUE, na.strings=c("", "NA"), blank.lines.skip = TRUE, quote = ""),silent=TRUE)
    if (!inherits(headers, 'try-error')){
      file
    } else {
      stop("Your file seems to be empty, 'number of MS/MS observations in a tissue' tool stopped !")
    }
    #Read the data of the files (skipping the first row)
    file <- read.table(filename, skip = 1, header = FALSE, sep = "\t", stringsAsFactors = FALSE, fill = TRUE, na.strings=c("", "NA"), blank.lines.skip = TRUE, quote = "")
    # Remove empty rows
    file <- file[!apply(is.na(file) | file == "", 1, all), , drop=FALSE]
    #And assign the header to the data
    names(file) <- headers
  }
  else {
    file <- try(read.table(filename, header = FALSE, sep = "\t", stringsAsFactors = FALSE, fill = TRUE, na.strings=c("", "NA"), blank.lines.skip = TRUE, quote = ""),silent=TRUE)
    if (!inherits(file, 'try-error')){
      file
    } else {
      stop("Your file seems to be empty, 'number of MS/MS observations in a tissue' tool stopped !")
    }
    # Remove empty rows
    file <- file[!apply(is.na(file) | file == "", 1, all), , drop=FALSE]
  }
  return(file)
}

annotPeptideAtlas <- function(input, atlas_file) {
  ## Calculate the sum of n_observations for each ID in input
  atlas = readfile(atlas_file, "true")
  n_observations = c()
  for (id in input) {
    n_observations = c(n_observations, sum(atlas[which(atlas["biosequence_name"][,] == id),]$n_observations))
  }
  # Replace sum value 0 by NA
  n_observations = replace(n_observations, n_observations == 0, NA)
  return(n_observations)
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
        --input_type: type of input (list of id or filename)
        --input: input
        --atlas: list of file(s) path to use
        --output: text output filename \n")
    q(save="no")
  }
  
  # Parse arguments
  parseArgs <- function(x) strsplit(sub("^--", "", x), "=")
  argsDF <- as.data.frame(do.call("rbind", parseArgs(args)))
  args <- as.list(as.character(argsDF$V2))
  names(args) <- argsDF$V1
  
  #save(args,file="/home/dchristiany/proteore_project/ProteoRE/tools/retrieve_msbased_pepatlas/args.Rda")
  #load("/home/dchristiany/proteore_project/ProteoRE/tools/retrieve_msbased_pepatlas/args.Rda")
  
  # Extract input
  input_type = args$input_type
  if (input_type == "list") {
    input = strsplit(args$input, "[ \t\n]+")[[1]]
  } else if (input_type == "file") {
    filename = args$input
    ncol = args$column
    # Check ncol
    if (! as.numeric(gsub("c", "", ncol)) %% 1 == 0) {
      stop("Please enter an integer for level")
    } else {
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

  output = args$output

  #function to create a list of infos from file path
  extract_info_from_path <- function(path) {
    file_name=strsplit(tail(strsplit(path,"/")[[1]],n=1),"\\.")[[1]][1]
    date=tail(strsplit(file_name,"_")[[1]],n=1)
    tissue=paste(strsplit(file_name,"_")[[1]][1:2],collapse="_")
    return (c(date,tissue,file_name,path))
  }
  
  #data_frame building
  paths=strsplit(args$atlas,",")[[1]]
  tmp <- sapply(paths, extract_info_from_path,USE.NAMES = FALSE)
  df <- as.data.frame(t(as.data.frame(tmp)),row.names = c(""),stringsAsFactors = FALSE)
  names(df) <- c("date","tissue","filename","path")
  
  # Annotations
  res = sapply(df$path, function(x) annotPeptideAtlas(input, x), USE.NAMES = FALSE)
  names=df$filename

  # Write output
  if (input_type == "list") {
    res = cbind(as.matrix(input), res)
    names = c("Uniprot accession number", names)
    colnames(res) = names
    write.table(res, output, row.names = FALSE, sep = "\t", quote = FALSE)
  } else if (input_type == "file") {
    names = c(names(file), names)
    output_content = cbind(file, res)
    colnames(output_content) = names
    write.table(output_content, output, row.names = FALSE, sep = "\t", quote = FALSE)
  }
}

main()
#Rscript retrieve_peptideatlas.R --input_type="file" --input="test-data/FKW_Lacombe_et_al_2017_OK.txt" --atlas_brain="Human_Brain_201803_PeptideAtlas.txt" --column="c1" --header="true"  --output="test-data/PeptideAtlas_output.txt"  --atlas_urine="Human_Urine_201803_PeptideAtlas.txt" --atlas="brain,urine"

