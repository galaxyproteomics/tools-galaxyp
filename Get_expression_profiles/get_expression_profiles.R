# Read file and return file content as data.frame
read_file <- function(path,header){
  file <- try(read.csv(path,header=header, sep="\t",stringsAsFactors = FALSE, quote="\"", check.names = F),silent=TRUE)
  if (inherits(file,"try-error")){
    stop("File not found !")
  }else{
    return(file)
  }
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

# input has to be a list of IDs in ENSG format
# tissue is one of unique(HPA.normal.tissue$Tissue)
# level is one, or several, or 0 (=ALL) of "Not detected", "Medium", "High", "Low"
# reliability is one, or several, or 0 (=ALL) of "Approved", "Supported", "Uncertain"
annot.HPAnorm<-function(input, HPA_normal_tissue, tissue, level, reliability, not_mapped_option) {
  dat <- subset(HPA_normal_tissue, Gene %in% input)
  res.Tissue<-subset(dat, Tissue %in% tissue) 
  res.Level<-subset(res.Tissue, Level %in% level) 
  res.Rel<-subset(res.Level, Reliability %in% reliability) 
  
  if (not_mapped_option) {
    if (length(setdiff(intersect(input, unique(dat$Gene)), unique(res.Rel$Gene)))>0) {
      not_match_IDs <- matrix(setdiff(intersect(input, unique(dat$Gene)), unique(res.Rel$Gene)), ncol = 1, nrow = length(setdiff(intersect(input, unique(dat$Gene)), unique(res.Rel$Gene))))
      not.match <- matrix(NA, ncol = ncol(HPA_normal_tissue) - 1, nrow = length(not_match_IDs))
      not.match <- cbind(not_match_IDs, unname(not.match))
      colnames(not.match) <- colnames(HPA_normal_tissue)
      res <- rbind(res.Rel, not.match)
    } else {
      res <- res.Rel
    } 
    
    if (length(setdiff(input, unique(dat$Gene)))>0) {
      not.mapped <- matrix(ncol = ncol(HPA_normal_tissue) - 1, nrow = length(setdiff(input, unique(dat$Gene))))
      not.mapped <- cbind(matrix(setdiff(input, unique(dat$Gene)), ncol = 1, nrow = length(setdiff(input, unique(dat$Gene)))), unname(not.mapped))
      colnames(not.mapped) <- colnames(HPA_normal_tissue)
      res <- rbind(res, not.mapped)
    }
    
  } else {
    res <- res.Rel
  }
  
  return(res)
  
}

annot.HPAcancer<-function(input, HPA_cancer_tissue, cancer, not_mapped_option) {
  dat <- subset(HPA_cancer_tissue, Gene %in% input)
  res.Cancer<-subset(dat, Cancer %in% cancer) 

  if (not_mapped_option) {
    not.mapped <- matrix(ncol=ncol(HPA_cancer_tissue)-1, nrow=length(setdiff(input, unique(dat$Gene))))
    not.mapped <- cbind(matrix(setdiff(input, unique(dat$Gene)), ncol = 1, nrow = length(setdiff(input, unique(dat$Gene)))), unname(not.mapped))
    colnames(not.mapped) <- colnames(HPA_cancer_tissue)
    res <- rbind(res.Cancer, not.mapped)
  } else {
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
  
  #save(args,file = "/home/dchristiany/proteore_project/ProteoRE/tools/Get_expression_profiles/args.rda")
  #load("/home/dchristiany/proteore_project/ProteoRE/tools/Get_expression_profiles/args.rda")
  
  # Extract input
  input_type = args$input_type
  if (input_type == "list") {
    list_id = strsplit(args$input, "[ \t\n]+")[[1]]
  } else if (input_type == "file") {
    filename = args$input
    column_number = as.numeric(gsub("c", "" ,args$column_number))
    header = str2bool(args$header)
    file = read_file(filename, header)
    list_id = sapply(strsplit(file[,column_number], ";"), "[", 1)
  }
  input = list_id

  # Read reference file
  reference_file = read_file(args$ref_file, TRUE)

  # Extract other options
  atlas = args$atlas
  not_mapped_option = str2bool(args$not_mapped)
  if (atlas=="normal") {
    tissue = strsplit(args$tissue, ",")[[1]]
    level = strsplit(args$level, ",")[[1]]
    reliability = strsplit(args$reliability, ",")[[1]]
    # Calculation
    res = annot.HPAnorm(input, reference_file, tissue, level, reliability, not_mapped_option)
  } else if (atlas=="cancer") {
    cancer = strsplit(args$cancer, ",")[[1]]
    # Calculation
    res = annot.HPAcancer(input, reference_file, cancer, not_mapped_option)
  }
  
  # Write output
  output = args$output
  res <- apply(res, c(1,2), function(x) gsub("^$|^ $", NA, x))
  write.table(res, output, sep = "\t", quote = FALSE, row.names = FALSE)
}

main()
