
# Read file and return file content as data.frame
readfile = function(filename, header) {
  if (header == "true") {
    # Read only first line of the file as header:
    headers <- read.table(filename, nrows = 1, header = FALSE, sep = "\t", stringsAsFactors = FALSE, fill = TRUE)
    #Read the data of the files (skipping the first row):
    file <- read.table(filename, skip = 1, header = FALSE, sep = "\t", stringsAsFactors = FALSE, fill = TRUE)
    # Remove empty rows
    #file <- file[!apply(is.na(file) | file == "", 1, all),]
    #And assign the header to the data:
    names(file) <- headers
  }
  else {
    file <- read.table(filename, header = FALSE, sep = "\t", stringsAsFactors = FALSE, fill = TRUE)
  }
  return(file)
}


# input has to be a list of IDs in ENSG format
# tissue is one of unique(HPA.normal.tissue$Tissue)
# level is one, or several, or 0 (=ALL) of "Not detected", "Medium", "High", "Low"
# reliability is one, or several, or 0 (=ALL) of "Approved", "Supported", "Uncertain"
annot.HPAnorm<-function(input, HPA_normal_tissue, tissue, level, reliability, not_mapped_option) {
  dat <- subset(HPA_normal_tissue, Gene %in% input)
  
  if (length(tissue)==1) { 
    res.Tissue<-subset(dat, Tissue==tissue) 
  }
  if (length(tissue)>1)  { 
    res.Tissue<-subset(dat, Tissue %in% tissue) 
  }
  
  if (length(level)==1) { 
    res.Level<-subset(res.Tissue, Level==level) 
  }
  if (length(level)>1)  { 
    print(level)
    res.Level<-subset(res.Tissue, Level %in% level) 
  }
  
  if (length(reliability)==1) { 
    res.Rel<-subset(res.Level, Reliability==reliability) 
  }
  if (length(reliability)>1)  {
    print(reliability)
    res.Rel<-subset(res.Level, Reliability %in% reliability) 
  }
  
  if (not_mapped_option == "true") {
    if (length(setdiff(intersect(input, unique(dat$Gene)), unique(res.Rel$Gene)))>0) {
      not_match_IDs <- matrix(setdiff(intersect(input, unique(dat$Gene)), unique(res.Rel$Gene)), ncol = 1, nrow = length(setdiff(intersect(input, unique(dat$Gene)), unique(res.Rel$Gene))))
      not.match <- matrix("not match", ncol = ncol(HPA_normal_tissue) - 1, nrow = length(not_match_IDs))
      not.match <- cbind(not_match_IDs, unname(not.match))
      colnames(not.match) <- colnames(HPA_normal_tissue)
      res <- rbind(res.Rel, not.match)
    }
    else {
      res <- res.Rel
    }
    if (length(setdiff(input, unique(dat$Gene)))>0) {
      not.mapped <- matrix(ncol = ncol(HPA_normal_tissue) - 1, nrow = length(setdiff(input, unique(dat$Gene))))
      not.mapped <- cbind(matrix(setdiff(input, unique(dat$Gene)), ncol = 1, nrow = length(setdiff(input, unique(dat$Gene)))), unname(not.mapped))
      colnames(not.mapped) <- colnames(HPA_normal_tissue)
      res <- rbind(res, not.mapped)
    }
  }
  else {
    res <- res.Rel
  }
  
  return(res)
  
}

annot.HPAcancer<-function(input, HPA_cancer_tissue, cancer, not_mapped_option) {
  dat <- subset(HPA_cancer_tissue, Gene %in% input)

  if (length(cancer)==1) { 
    res.Cancer<-subset(dat, Cancer==cancer) 
  }
  if (length(cancer)>1)  { 
    res.Cancer<-subset(dat, Cancer %in% cancer) 
  }

  if (not_mapped_option == "true") {
    not.mapped <- matrix(ncol=ncol(HPA_cancer_tissue)-1, nrow=length(setdiff(input, unique(dat$Gene))))
    not.mapped <- cbind(matrix(setdiff(input, unique(dat$Gene)), ncol = 1, nrow = length(setdiff(input, unique(dat$Gene)))), unname(not.mapped))
    colnames(not.mapped) <- colnames(HPA_cancer_tissue)
    res <- rbind(res.Cancer, not.mapped)
  }
  else {
    res <- res.Cancer
  }
  return(res)
}


main <- function() {
  args <- commandArgs(TRUE)
  if(length(args)<1) {
    args <- c("--help")
  }
  
  # Help section
  if("--help" %in% args) {
    cat("Selection and Annotation HPA
    Arguments:
        --ref_file: HPA normal/cancer tissue file path
        --input_type: type of input (list of id or filename)
        --input: list of IDs in ENSG format
        --column_number: the column number which you would like to apply...
        --header: true/false if your file contains a header
        --atlas: normal/cancer
          if normal:
            --tissue: list of tissues
            --level: Not detected, Low, Medium, High
            --reliability: Supportive, Uncertain
          if cancer:
            --cancer: Cancer tissues
        --not_mapped: true/false if your output file should contain not-mapped and not-match IDs 
        --output: output filename \n")
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
    list_id = strsplit(args$input, " ")[[1]]
  }
  else if (input_type == "file") {
    filename = args$input
    column_number = as.numeric(gsub("c", "" ,args$column_number))
    header = args$header
    file = readfile(filename, header)
    list_id = c()
    print(file)
    list_id = sapply(strsplit(file[,column_number], ";"), "[", 1)
  }
  input = list_id

  # Read reference file
  #reference_file = read.table(args$ref_file, header = TRUE, sep = "\t", stringsAsFactors = FALSE, fill = TRUE)
  #print(colnames(reference_file))

  # Extract other options
  atlas = args$atlas
  not_mapped_option = args$not_mapped
  if (atlas=="normal") {
    # Read reference file
    reference_file = read.table(args$ref_file, header = TRUE, sep = ",", stringsAsFactors = FALSE, fill = TRUE)
    tissue = strsplit(args$tissue, ",")[[1]]
    level = strsplit(args$level, ",")[[1]]
    reliability = strsplit(args$reliability, ",")[[1]]
    # Calculation
    res = annot.HPAnorm(input, reference_file, tissue, level, reliability, not_mapped_option)
  }
  else if (atlas=="cancer") {
    # Read reference file
    reference_file = read.table(args$ref_file, header = TRUE, sep = "\t", stringsAsFactors = FALSE, fill = TRUE)
    cancer = strsplit(args$cancer, ",")[[1]]
    # Calculation
    res = annot.HPAcancer(input, reference_file, cancer, not_mapped_option)
  }
  
  # Write output
  output = args$output
  write.table(res, output, sep = "\t", quote = FALSE, row.names = FALSE)
}

main()

# Example commands
# Rscript sel_ann_hpa.R --input_type="file" --input="./test-data/ENSGid.txt" --ref_file="./pathology.tsv" --cancer="lung cancer,carcinoid" --not_mapped="true" --column_number="c1" --header="true" --output="test-data/ENSG_tissue_output_cancer.txt"
# Rscript sel_ann_hpa.R --input_type="file" --input="./test-data/ENSGid.txt" --ref_file="./normal_tissue.tsv" --tissue="lung" --level="Not detected,Medium,High,Low" --reliability="Approved,Supported,Uncertain" --column_number="c1" --header="true" --not_mapped="false" --output="./test-data/ENSG_tissue_output.txt"
# Rscript sel_ann_hpa.R --input_type="file" --input="./test-data/ENSG_no_not_match.txt" --ref_file="/Users/LinCun/Documents/ProteoRE/usecase1/normal_tissue.csv" --tissue="lung" --level="Not detected,Medium,High,Low" --reliability="Approved,Supportive,Uncertain" --column_number="c1" --header="true" --output="./test-data/ENSG_tissue_output2.txt"