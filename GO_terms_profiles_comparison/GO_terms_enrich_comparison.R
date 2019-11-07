options(warn=-1)  #TURN OFF WARNINGS !!!!!!
suppressMessages(library(clusterProfiler,quietly = TRUE))
suppressMessages(library(plyr, quietly = TRUE))
suppressMessages(library(ggplot2, quietly = TRUE))
suppressMessages(library(DOSE, quietly = TRUE))

#return the number of character from the longest description found (from the 10 first)
max_str_length_10_first <- function(vector){
  vector <- as.vector(vector)
  nb_description = length(vector)
  if (nb_description >= 10){nb_description=10}
  return(max(nchar(vector[1:nb_description])))
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

get_args <- function(){
  
  ## Collect arguments
  args <- commandArgs(TRUE)
  
  ## Default setting when no arguments passed
  if(length(args) < 1) {
    args <- c("--help")
  }
  
  ## Help section
  if("--help" %in% args) {
    cat("Selection and Annotation HPA
      Arguments:
      --inputtype1: type of input (list of id or filename)
      --inputtype2: type of input (list of id or filename)
      --inputtype3: type of input (list of id or filename)
      --input1: input1
      --input2: input2
      --input3: input3
      --column1: the column number which you would like to apply...
      --column2: the column number which you would like to apply...
      --column3: the column number which you would like to apply...
      --header1: true/false if your file contains a header
      --header2: true/false if your file contains a header
      --header3: true/false if your file contains a header
      --ont: ontology to use
      --org: organism db package
      --list_name1: name of the first list
      --list_name2: name of the second list
      --list_name3: name of the third list \n")
        
    q(save="no")
  }
  
  parseArgs <- function(x) strsplit(sub("^--", "", x), "=")
  argsDF <- as.data.frame(do.call("rbind", parseArgs(args)))
  args <- as.list(as.character(argsDF$V2))
  names(args) <- argsDF$V1
  
  return(args)
}

get_ids=function(inputtype, input, ncol, header) {

    if (inputtype == "text") {
      ids = strsplit(input, "[ \t\n]+")[[1]]
    } else if (inputtype == "file") {
      header=str2bool(header)
      ncol=get_cols(ncol)
      csv = read.csv(input,header=header, sep="\t", as.is=T)
      ids=csv[,ncol]
    }

    ids = unlist(strsplit(as.character(ids),";"))
    ids = ids[which(!is.na(ids))]

    return(ids)
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

check_ids <- function(vector,type) {
  uniprot_pattern = "^([OPQ][0-9][A-Z0-9]{3}[0-9]|[A-NR-Z][0-9]([A-Z][A-Z0-9]{2}[0-9]){1,2})$"
  entrez_id = "^([0-9]+|[A-Z]{1,2}_[0-9]+|[A-Z]{1,2}_[A-Z]{1,4}[0-9]+)$"
  if (type == "entrez")
    return(grepl(entrez_id,vector))
  else if (type == "uniprot") {
    return(grepl(uniprot_pattern,vector))
  }
}

#res.cmp@compareClusterResult$Description <- sapply(as.vector(res.cmp@compareClusterResult$Description), function(x) {ifelse(nchar(x)>50, substr(x,1,50),x)},USE.NAMES = FALSE)
fortify.compareClusterResult <- function(res.cmp, showCategory=30, by="geneRatio", split=NULL, includeAll=TRUE) {
  clProf.df <- as.data.frame(res.cmp)
  .split <- split
  ## get top 5 (default) categories of each gene cluster.
  if (is.null(showCategory)) {
    result <- clProf.df
  } else {
    Cluster <- NULL # to satisfy codetools
    topN <- function(res, showCategory) {
      ddply(.data = res, .variables = .(Cluster), .fun = function(df, N) {
              if (length(df$Count) > N) {
                if (any(colnames(df) == "pvalue")) {
                  idx <- order(df$pvalue, decreasing=FALSE)[1:N]
                } else {
                  ## for groupGO
                  idx <- order(df$Count, decreasing=T)[1:N]
                }
                return(df[idx,])
              } else {
                return(df)
              }
            },
            N=showCategory
      )
    }
    if (!is.null(.split) && .split %in% colnames(clProf.df)) {
      lres <- split(clProf.df, as.character(clProf.df[, .split]))
      lres <- lapply(lres, topN, showCategory = showCategory)
      result <- do.call('rbind', lres)
    } else {
      result <- topN(clProf.df, showCategory)
    }    
  }
  ID <- NULL
  if (includeAll == TRUE) {
    result = subset(clProf.df, ID %in% result$ID)
  }
  ## remove zero count
  result$Description <- as.character(result$Description) ## un-factor
  GOlevel <- result[,c("ID", "Description")] ## GO ID and Term
  #GOlevel <- unique(GOlevel)
  result <- result[result$Count != 0, ]
  result$Description <- factor(result$Description,levels=rev(GOlevel[,2]))
  if (by=="rowPercentage") {
    Description <- Count <- NULL # to satisfy codetools
    result <- ddply(result,.(Description),transform,Percentage = Count/sum(Count),Total = sum(Count))
    ## label GO Description with gene counts.
    x <- mdply(result[, c("Description", "Total")], paste, sep=" (")
    y <- sapply(x[,3], paste, ")", sep="")
    result$Description <- y
    
    ## restore the original order of GO Description
    xx <- result[,c(2,3)]
    xx <- unique(xx)
    rownames(xx) <- xx[,1]
    Termlevel <- xx[as.character(GOlevel[,1]),2]
    
    ##drop the *Total* column
    result <- result[, colnames(result) != "Total"]
    result$Description <- factor(result$Description, levels=rev(Termlevel))
    
  } else if (by == "count") {
    ## nothing
  } else if (by == "geneRatio") { ##default
    gsize <- as.numeric(sub("/\\d+$", "", as.character(result$GeneRatio)))
    gcsize <- as.numeric(sub("^\\d+/", "", as.character(result$GeneRatio)))
    result$GeneRatio = gsize/gcsize
    cluster <- paste(as.character(result$Cluster),"\n", "(", gcsize, ")", sep="")
    lv <- unique(cluster)[order(as.numeric(unique(result$Cluster)))]
    result$Cluster <- factor(cluster, levels = lv)
  } else {
    ## nothing
  }
  return(result)
}

##function plotting.clusteProfile from clusterProfiler pkg
plotting.clusterProfile <- function(clProf.reshape.df,x = ~Cluster,type = "dot", colorBy = "p.adjust",by = "geneRatio",title="",font.size=12) {
  
  Description <- Percentage <- Count <- Cluster <- GeneRatio <- p.adjust <- pvalue <- NULL # to
  if (type == "dot") {
    if (by == "rowPercentage") {
      p <- ggplot(clProf.reshape.df,
                  aes_(x = x, y = ~Description, size = ~Percentage))
    } else if (by == "count") {
      p <- ggplot(clProf.reshape.df,
                  aes_(x = x, y = ~Description, size = ~Count))
    } else if (by == "geneRatio") { ##DEFAULT
      p <- ggplot(clProf.reshape.df,
                  aes_(x = x, y = ~Description, size = ~GeneRatio))
    } else {
      ## nothing here
    }
    if (any(colnames(clProf.reshape.df) == colorBy)) {
      p <- p +
        geom_point() +
        aes_string(color=colorBy) +
        scale_color_continuous(low="red", high="blue", guide=guide_colorbar(reverse=TRUE))
      ## scale_color_gradientn(guide=guide_colorbar(reverse=TRUE), colors = enrichplot:::sig_palette)
    } else {
      p <- p + geom_point(colour="steelblue")
    }
  }
  
  p <- p + xlab("") + ylab("") + ggtitle(title) +
    theme_dose(font.size)
  
  ## theme(axis.text.x = element_text(colour="black", size=font.size, vjust = 1)) +
  ##     theme(axis.text.y = element_text(colour="black",
  ##           size=font.size, hjust = 1)) +
  ##               ggtitle(title)+theme_bw()
  ## p <- p + theme(axis.text.x = element_text(angle=angle.axis.x,
  ##                    hjust=hjust.axis.x,
  ##                    vjust=vjust.axis.x))
  
  return(p)
}

make_dotplot<-function(res.cmp,ontology) {

  dfok<-fortify.compareClusterResult(res.cmp)
  dfok$Description <- sapply(as.vector(dfok$Description), function(x) {ifelse(nchar(x)>50, substr(x,1,50),x)},USE.NAMES = FALSE)
  p<-plotting.clusterProfile(dfok, title="")

  #plot(p, type="dot") #
  output_path= paste("GO_enrich_comp_",ontology,".png",sep="")
  png(output_path,height = 720, width = 600)
  pl <- plot(p, type="dot")
  print(pl)
  dev.off()
}

get_cols <-function(input_cols) {
  input_cols <- gsub("c","",gsub("C","",gsub(" ","",input_cols)))
  if (grepl(":",input_cols)) {
    first_col=unlist(strsplit(input_cols,":"))[1]
    last_col=unlist(strsplit(input_cols,":"))[2]
    cols=first_col:last_col
  } else {
    cols = as.integer(unlist(strsplit(input_cols,",")))
  }
  return(cols)
}

#to check
cmp.GO <- function(l,fun="enrichGO",orgdb, ontology, readable=TRUE) {
  cmpGO<-compareCluster(geneClusters = l,
                        fun=fun, 
                        OrgDb = orgdb, 
                        ont=ontology, 
                        readable=TRUE)
  
  return(cmpGO)
}

check_ids <- function(vector,type) {
  uniprot_pattern = "^([OPQ][0-9][A-Z0-9]{3}[0-9]|[A-NR-Z][0-9]([A-Z][A-Z0-9]{2}[0-9]){1,2})$"
  entrez_id = "^([0-9]+|[A-Z]{1,2}_[0-9]+|[A-Z]{1,2}_[A-Z]{1,4}[0-9]+)$"
  if (type == "entrez")
    return(grepl(entrez_id,vector))
  else if (type == "uniprot") {
    return(grepl(uniprot_pattern,vector))
  }
}

main = function() {
  
  #to get the args of the command line
  args=get_args()  

  l<-list(NULL)
      
  for ($list in args$lists) { 
   
    ids<-get_ids(args$inputype, args$input, args$header, args$column) 


    l[[$list]]<-ids  
  }



  ont = strsplit(args$ont, ",")[[1]] 
  org=args$org
  
  #load annot package 
  suppressMessages(library(args$org, character.only = TRUE, quietly = TRUE))
  
  # Extract OrgDb
  if (args$org=="org.Hs.eg.db") {
    orgdb<-org.Hs.eg.db
  } else if (args$org=="org.Mm.eg.db") {
    orgdb<-org.Mm.eg.db
  } else if (args$org=="org.Rn.eg.db") {
    orgdb<-org.Rn.eg.db
  }

  for(ontology in ont) {
    if (args$list_name3=="null") { 
      liste = list("l1"=ids1,"l2"=ids2)
      names(liste) = c(args$list_name1,args$list_name2)
    } else if (args$list_name3 != "null") {
      liste = list("l1"=ids1,"l2"=ids2, "l3"=ids3)
      names(liste) = c(args$list_name1,args$list_name2, args$list_name3)
    }
    res.cmp<-cmp.GO(l=liste,fun="enrichGO",orgdb, ontology, readable=TRUE)
    make_dotplot(res.cmp,ontology)  
    output_path = paste("GO_enrich_comp_",ontology,".tsv",sep="")
    write.table(res.cmp@compareClusterResult, output_path, sep="\t", row.names=F, quote=F)
  }
  
} #end main 

main()

