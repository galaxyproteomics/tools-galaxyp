#!/usr/bin/Rscript

suppressMessages(library('plotly',quietly = T))
suppressMessages(library('heatmaply',quietly = T))

#packageVersion('plotly')

get_args <- function(){
  
  ## Collect arguments
  args <- commandArgs(TRUE)
  
  ## Default setting when no arguments passed
  if(length(args) < 1) {
    args <- c("--help")
  }
  
  ## Help section
  if("--help" %in% args) {
    cat("Pathview R script
    Arguments:
      --help                  Print this test
      --input                 path of the input  file (must contains a colum of uniprot and/or geneID accession number)
      --output                Output file
      --type                  type of output file, could be html, pdf, jpg or png
      --cols                  Columns to use for heatmap, exemple : '3:8' to use columns from the third to the 8th
      --row_names             Column which contains row names
      --header                True or False
      --col_text_angle        Angle of columns label ; from -90 to 90 degres
      --dist_fun              function used to compute the distance

      Example:
      ./heatmap_viz.R --input='dat.nucl.norm.imputed.tsv' --output='heatmap.html' --cols='3:8' --row_names='2' --header=TRUE --col_text_angle=0 \n\n")
    
    q(save="no")
  }
  
  parseArgs <- function(x) strsplit(sub("^--", "", x), "=")
  argsDF <- as.data.frame(do.call("rbind", parseArgs(args)))
  args <- as.list(as.character(argsDF$V2))
  names(args) <- argsDF$V1
  
  return(args)
}

read_file <- function(path,header){
  file <- try(read.csv(path,header=header, sep="\t",stringsAsFactors = FALSE, quote="",fill=TRUE),silent=TRUE)
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

#remove remaining quote 
#only keep usefull columns
#remove lines with at least one empty cell in a matrix between two defined columns
clean_df <- function(mat,cols,rownames_col){
  uto = mat[,cols]
  uto <- as.data.frame(apply(uto,c(1,2),function(x) gsub(",",".",x)))
  uto <- as.data.frame(apply(uto,c(1,2),function(x) {ifelse(is.character(x),as.numeric(x),x)}))
  rownames(uto) <- mat[,rownames_col]
  #bad_lines <- which(apply(uto, 1, function(x) any(is.na(x))))
  #if (length(bad_lines) > 0) {
  #  uto <- uto[- bad_lines,]
  #  print(paste("lines",bad_lines, "has been removed: at least one non numeric content"))
  #}
  return(uto)
}

get_cols <-function(input_cols) {
  input_cols <- gsub("c","",input_cols)
  if (grepl(":",input_cols)) {
    first_col=unlist(strsplit(input_cols,":"))[1]
    last_col=unlist(strsplit(input_cols,":"))[2]
    cols=first_col:last_col
  } else {
    cols = as.integer(unlist(strsplit(input_cols,",")))
  }
  return(cols)
}

#get args
args <- get_args()

#save(args,file="/home/dchristiany/proteore_project/ProteoRE/tools/heatmap_viz/args.rda")
#load("/home/dchristiany/proteore_project/ProteoRE/tools/heatmap_viz/args.rda")

header=str2bool(args$header)
output <- rapply(strsplit(args$output,"\\."),c) #remove extension
output <- paste(output[1:length(output)-1],collapse=".")
output <- paste(output,args$type,sep=".")
cols = get_cols(args$cols)
rownames_col = as.integer(gsub("c","",args$row_names))
if (length(cols) <=1 ){
  stop("You need several colums to build a heatmap")
}
dist=args$dist
clust=args$clust
dendrogram=args$dendrogram

#cleaning data
uto <- read_file(args$input,header)
uto <- clean_df(uto,cols,rownames_col)
if (header) {
  col_names = names(data)
} else {
  col_names = cols
}

#building heatmap
if (dist %in% c("pearson","spearman","kendall")){
  heatmaply(uto, file=output, margins=c(100,50,NA,0), plot_method="plotly", labRow = rownames(uto), labCol = col_names, distfun=dist, 
            hclust_method = clust, dendrogram = dendrogram, grid_gap = 0,cexCol = 1, column_text_angle = as.numeric(args$col_text_angle), 
            width = 1000, height=1000, colors = c('blue','green','yellow','red'))
} else {
  heatmaply(uto, file=output, margins=c(100,50,NA,0), plot_method="plotly", labRow = rownames(uto), labCol = col_names, dist_method = dist, 
          hclust_method = clust, dendrogram = dendrogram, grid_gap = 0,cexCol = 1, column_text_angle = as.numeric(args$col_text_angle), 
          width = 1000, height=1000, colors = c('blue','green','yellow','red'))
}

####heatmaply

simulateExprData <- function(n, n0, p, rho0, rho1){ row 
  # n: total number of subjects 
  # n0: number of subjects with exposure 0 
  # n1: number of subjects with exposure 1 
  # p: number of genes 
  # rho0: rho between Z_i and Z_j for subjects with exposure 0 
  # rho1: rho between Z_i and Z_j for subjects with exposure 1
  
  # Simulate gene expression values according to exposure 0 or 1, 
  # according to a centered multivariate normal distribution with 
  # covariance between Z_i and Z_j being rho^|i-j| 
  n1 <- n - n0 
  times <- 1:p
  H <- abs(outer(times, times, "-")) 
  V0 <- rho0^H 
  V1 <- rho1^H 
  
  # rows are people, columns are genes 
  genes0 <- MASS::mvrnorm(n = n0, mu = rep(0,p), Sigma = V0) 
  genes1 <- MASS::mvrnorm(n = n1, mu = rep(0,p), Sigma = V1) 
  genes <- rbind(genes0,genes1) 
  return(genes)
}

#genes <- simulateExprData(n = 50, n0 = 25, p = 100, rho0 = 0.01, rho1 = 0.95)

#heatmaply(genes, k_row = 2, k_col = 2)

#heatmaply(cor(genes), k_row = 2, k_col = 2)







