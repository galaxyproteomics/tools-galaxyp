
# Read file and return file content as data.frame?
readfile = function(filename, header) {
  if (header == "true") {
    # Read only first line of the file as header:
    headers <- read.table(filename, nrows = 1, header = FALSE, sep = "\t", stringsAsFactors = FALSE, fill = TRUE)
    #Read the data of the files (skipping the first row):
    file <- read.table(filename, skip = 1, header = FALSE, sep = "\t", stringsAsFactors = FALSE, fill = TRUE)
    #And assign the header to the data:
    names(file) <- headers
  }
  else {
    file <- read.table(filename, header = FALSE, sep = "\t", stringsAsFactors = FALSE, fill = TRUE)
  }
  return(file)
}


# input has to be a list of ID in ENSG format
# tissue is one of unique(HPA.normal.tissue$Tissue)
# level is one, or several, or 0 (=ALL) of "Not Detected", "Medium", "High", "Low"
# reliability is one, or several, or 0 (=ALL) of "Approved", "Supported", "Uncertain"
annot.HPAnorm<-function(input, HPA_normal_tissue, tissue, level, reliability) {
  
  #print(HPA_normal_tissue[1:10,]$Gene)
  #print("ENSG00000211638" %in% HPA_normal_tissue$Gene)
  #print(gsub('"', "",HPA_normal_tissue$Gene) %in% gsub('"', "",input))
  dat <- subset(HPA_normal_tissue, Gene %in% input)
  #print(dat)
  
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
    res.Level<-subset(res.Tissue, Level %in% level) 
  }
  # if (level=="all") {
  #   res.Level<-subset(res.Tissue, Level %in% c("Not detected", "Medium", "High","Low")) 
  # }
  
  if (length(reliability)==1) { 
    res.Rel<-subset(res.Level, Reliability==reliability) 
  }
  if (length(reliability)>1)  {
    res.Rel<-subset(res.Level, Reliability %in% reliability) 
  }
  # if (reliability=="all") { 
  #   res.Rel<-subset(res.Level, Reliability %in% c("Uncertain", "Supported", "Approved") ) 
  # }
  print(setdiff(input, unique(res.Rel$Gene)))
  print(intersect(input, unique(res.Rel$Gene)))
  if (length(setdiff(input, unique(res.Rel$Gene)))>0) {
    not.mapped <- matrix(ncol = ncol(HPA_normal_tissue) - 1, nrow = length(setdiff(input, unique(res.Rel$Gene))))
    not.mapped <- cbind(setdiff(input, unique(res.Rel$Gene)), not.mapped)
    colnames(not.mapped) <- colnames(HPA_normal_tissue)
    #print(not.mapped)
    res<-rbind(res.Rel, not.mapped)
  }
  else {
    res<-list(res.Rel)
  }
  
  #print(res)
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
        --ref_file: HPA normal tissue file path
        --input_type: type of input (list of id or filename)
        --input: input
        --column_number: the column number which you would like to apply...
        --header: TRUE/FALSE if your file contains a header
        --tissue: list of tissues
        --level: level
        --reliability: ...
        --output: output filename \n")
    q(save="no")
  }
  
  # Parse arguments
  parseArgs <- function(x) strsplit(sub("^--", "", x), "=")
  argsDF <- as.data.frame(do.call("rbind", parseArgs(args)))
  args <- as.list(as.character(argsDF$V2))
  names(args) <- argsDF$V1
  #print(args)
  
  input_type = args$input_type
  if (input_type == "list") {
    list_id = strsplit(args$input, " ")[[1]]
  }
  else if (input_type == "file") {
    filename = args$input
    column_number = as.numeric(gsub("c", "" ,args$column_number))
    header = args$header
    file = readfile(filename, header)
    #print(file)
    list_id = c()
    list_id = sapply(strsplit(file[,column_number], ";"), "[", 1)
    #list_id = gsub('"', "", list_id)
  }
  #print(list_id)
  input = list_id
  #print("ENSG00000211638"%in%input)
  tissue = strsplit(args$tissue, ",")[[1]]
  level = strsplit(args$level, ",")[[1]]
  reliability = strsplit(args$reliability, ",")[[1]]
  output = args$output
  
  # Calculation
  HPA_normal_tissue = read.table(args$ref_file, header = TRUE, sep = ",", stringsAsFactors = FALSE, fill = TRUE)
  res = annot.HPAnorm(input, HPA_normal_tissue, tissue, level, reliability)
  
  # Write output
  write.table(res, output, sep = "\t", quote = FALSE, row.names = FALSE)
}

main()

# Rscript sel_ann_hpa.R --input_type="file" --input="./test-data/ENSGid.txt" --ref_file="/Users/LinCun/Documents/ProteoRE/usecase1/normal_tissue.csv" --tissue="lung" --level="Not Detected,Medium,High,Low" --reliability="Approved,Supported,Uncertain" --column_number="c1" --header="true" --output="./test-data/ENSG_tissue_output.txt"