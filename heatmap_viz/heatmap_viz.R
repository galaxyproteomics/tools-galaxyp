#!/usr/bin/Rscript

suppressMessages(library('plotly'))
suppressMessages(library('heatmaply'))

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

      Example:
      ./heatmap_viz.R --input='dat.nucl.norm.imputed.tsv' --output='heatmap.html' --cols='3:8' --row_names='2' --header=TRUE --col_text_angle=0 \n\n")
    
    q(save="no")
  }

  #save(args,file="/home/dchristiany/proteore_project/ProteoRE/tools/pathview/args.Rda")
  #load("/home/dchristiany/proteore_project/ProteoRE/tools/pathview/args.Rda")
  parseArgs <- function(x) strsplit(sub("^--", "", x), "=")
  argsDF <- as.data.frame(do.call("rbind", parseArgs(args)))
  args <- as.list(as.character(argsDF$V2))
  names(args) <- argsDF$V1
  
  return(args)
}

read_file <- function(path,header){
  file <- try(read.table(path,header=header, sep="\t",stringsAsFactors = FALSE, quote=""),silent=TRUE)
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

args <- get_args()
header=str2bool(args$header)
output <- rapply(strsplit(args$output,"\\."),c) #remove extension
output <- paste(output[1:length(output)-1],collapse=".")
output <- paste(output,args$type,sep=".")
first_col=as.numeric(substr(args$cols,1,1))
last_col=as.numeric(substr(args$cols,3,3))

###save and load args in rda file for testing
#save(args,file="/home/dchristiany/proteore_project/ProteoRE/tools/heatmap_viz/args.Rda")
#load("/home/dchristiany/proteore_project/ProteoRE/tools/heatmap_viz/args.Rda")


uto <- read_file(args$input,TRUE)
uto_light <- uto[,first_col:last_col]
rownames(uto_light) <- uto[,as.numeric(args$row_names)]
colnames(uto_light) <- sapply(colnames(uto_light),function(x) gsub("iBAQ_","",x),USE.NAMES = FALSE)

if (isTRUE(header)) {
  heatmaply(uto_light, file=output, margins=c(100,50,NA,0), plot_method="plotly", labRow = rownames(uto_light), labCol = names(uto_light),
          grid_gap = 0,cexCol = 1, column_text_angle = as.numeric(args$col_text_angle), width = 1000, height=1000, colors = c('blue','green','yellow','red'))
}else{
  heatmaply(uto_light, file=output, margins=c(100,50,NA,0), plot_method="plotly", labRow = rownames(uto_light),
            grid_gap = 0,cexCol = 1, column_text_angle = as.numeric(args$col_text_angle), width = 1000, height=1000, colors = c('blue','green','yellow','red'))
}


#write.table(uto_light, file = "uto_light.tsv",sep="\t",row.names = FALSE)

####heatmaply

simulateExprData <- function(n, n0, p, rho0, rho1){ 
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







