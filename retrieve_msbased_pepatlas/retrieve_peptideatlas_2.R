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

annotPeptideAtlas<-function(input, atlas_file) {
  atlas = readfile(atlas_file, "true")
  info = matrix(ncol = 6, nrow = 0)
  colnames(info) = c("biosequence_name","peptide_accession","peptide_sequence","n_observations","empirical_proteotypic_score","SSRCalc_relative_hydrophobicity")
  for (id in input) {
    info = rbind(info,subset(atlas, biosequence_name == id, select = c(biosequence_name,peptide_accession,peptide_sequence,n_observations,empirical_proteotypic_score,SSRCalc_relative_hydrophobicity)))
  }
  colnames(info)[which(colnames(info) == "biosequence_name")] = "Uniprot_accNum"
  colnames(info)[which(colnames(info) == "peptide_accession")] = "PA_peptide_accession"  
  return(info)
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
        --atlas: list of tissues choosen by users 
        --atlas_brain: path to brain atlas file
        --atlas_heart: path to heart atlas file
        --atlas_kidney: path to kidney atlas file
        --atlas_liver: path to liver atlas file
        --atlas_plasma_nonglyco: path to plasma non glyco atlas file
        --atlas_urine: path to urine atlas file
        --column: the column number which contains Uniprot IDs
        --header: true/false if your file contains a header
        --output: text output filename \n")
    q(save="no")
  }
  
  # Parse arguments
  parseArgs <- function(x) strsplit(sub("^--", "", x), "=")
  argsDF <- as.data.frame(do.call("rbind", parseArgs(args)))
  args <- as.list(as.character(argsDF$V2))
  names(args) <- argsDF$V1

  # Extract input
  input_type = args$input_type
  if (input_type == "list") {
    input = strsplit(args$input, "[ \t\n]+")[[1]]
  }
  else if (input_type == "file") {
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

  # Annotations
  atlas = strsplit(args$atlas,",")[[1]] # List of tissues chosen by users
  for (tissue in atlas) {
    output_filename = paste("PA", tissue, "Peptides_2018_output.txt", sep = "_")
    if (tissue == "Human_Plasma") {
      atlas_file = args$atlas_Human_Plasma
    }
    else if (tissue == "Human_Urine") {
      atlas_file = args$atlas_Human_Urine
    }
    else if (tissue == "Human_Brain") {
      atlas_file = args$atlas_Human_Brain
    }
    else if (tissue == "Human_Heart") {
      atlas_file = args$atlas_Human_Heart
    }
    else if (tissue == "Human_Kidney") {
      atlas_file = args$atlas_Human_Kidney
    }
    else if (tissue == "Human_Liver") {
      atlas_file = args$atlas_Human_Liver
    }
    else {
      atlas_file = args$atlas_Human_CSF
    }
    info = annotPeptideAtlas(input, atlas_file)
    write.table(info, output_filename, row.names = FALSE, sep = "\t", quote = FALSE)
  }
}
main()
#Rscript retrieve_peptideatlas.R --input_type="file" --input="test-data/FKW_Lacombe_et_al_2017_OK.txt" --atlas_brain="Human_Brain_201803_PeptideAtlas.txt" --column="c1" --header="true"  --output="test-data/PeptideAtlas_output.txt"  --atlas_urine="Human_Urine_201803_PeptideAtlas.txt" --atlas="brain,urine"

