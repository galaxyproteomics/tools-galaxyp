

select_HPAimmunohisto<-function(hpa_ref, tissue, level, reliability) {
  HPA.normal = read.table(hpa_ref,header=TRUE,sep="\t",stringsAsFactors = FALSE)
  HPA.normal$Tissue = sapply(HPA.normal$Tissue, function(string) gsub('cervix, uterine','cervix_uterine',string),USE.NAMES = F)
  if (tissue == "tissue") {
    tissue <- unique(HPA.normal$Tissue) 
  }
  if (level == "level") {
    level <- unique(HPA.normal$Level)
  }
  if (reliability == "reliability") {
    reliability <- unique(HPA.normal$Reliability)
  }
  res.imm <- subset(HPA.normal, Tissue%in%tissue & Level%in%level & Reliability%in%reliability)
  return(res.imm)
}

select_HPARNAseq<-function(hpa_ref, sample) {
  HPA.rnaTissue = read.table(hpa_ref,header=TRUE,sep="\t",stringsAsFactors = FALSE)
  names(HPA.rnaTissue) = sapply(names(HPA.rnaTissue), function(string) gsub('Sample','Tissue',string),USE.NAMES = F)
  HPA.rnaTissue$Tissue = sapply(HPA.rnaTissue$Tissue, function(string) gsub('cervix, uterine','cervix_uterine',string),USE.NAMES = F)
  res.rna <- subset(HPA.rnaTissue, Tissue%in%sample)
  if ("Unit" %in% names(res.rna)){
      res.rna = subset(res.rna, select = -Unit)
      colnames(res.rna)[which(colnames(res.rna) == 'Value')] <- 'Value (TPM unit)'
  }
  
  return(res.rna)
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
        --data_source: IHC/RNAseq
        --hpe_ref: path to reference file normal_tissue.tsv/rna_tissue.tsv)
          if IHC:
            --tissue: list of tissues
            --level: Not detected, Low, Medium, High
            --reliability: Supported, Approved, Enhanced, Uncertain
          if RNAseq:
            --sample: Sample tissues 
        --output: output filename \n")
    q(save="no")
  }
  
  # Parse arguments
  parseArgs <- function(x) strsplit(sub("^--", "", x), "=")
  argsDF <- as.data.frame(do.call("rbind", parseArgs(args)))
  args <- as.list(as.character(argsDF$V2))
  names(args) <- argsDF$V1

  # Extract options
  data_source = args$data_source
  hpa_ref = args$hpa_ref
  if (data_source == "IHC") {
    tissue = strsplit(args$tissue, ",")[[1]]
    level = strsplit(args$level, ",")[[1]]
    reliability = strsplit(args$reliability, ",")[[1]]
    # Calculation
    res = suppressWarnings(select_HPAimmunohisto(hpa_ref, tissue, level, reliability))
  }
  else if (data_source == "RNAseq") {
    sample = strsplit(args$sample, ",")[[1]]
    # Calculation
    res = suppressWarnings(select_HPARNAseq(hpa_ref, sample))
  }

  # Write output
  output = args$output
  write.table(res, output, sep = "\t", quote = FALSE, row.names = FALSE)
}

main()
