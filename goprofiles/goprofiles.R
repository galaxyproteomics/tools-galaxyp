# Load necessary libraries
library("org.Hs.eg.db", quietly=TRUE)
library("goProfiles", quietly=TRUE)

# Read file and return file content as data.frame?
readfile = function(filename, header) {
  if (header == "true") {
    # Read only the first line of the files as data (without headers):
    headers <- read.table(filename, nrows = 1, header = FALSE, sep = "\t", stringsAsFactors = FALSE, fill = TRUE)
    #Read the data of the files (skipping the first row):
    file <- read.table(filename, skip = 1, header = FALSE, sep = "\t", stringsAsFactors = FALSE, fill = TRUE)
    # Remove empty rows
    file <- file[!apply(is.na(file) | file == "", 1, all),]
    #And assign the headers of step two to the data:
    names(file) <- headers
  }
  else {
    file <- read.table(filename, header = FALSE, sep = "\t", stringsAsFactors = FALSE, fill = TRUE)
  }
  return(file)
}

getprofile = function(ids, id_type, level, duplicate) {
  ####################################################################
  # Arguments
  #   - ids: list of input IDs
  #   - id_type: type of input IDs (UniProt/ENTREZID)
  #   - level
  #   - duplicate: if the duplicated IDs should be removed or not (TRUE/FALSE)
  ####################################################################
  
  # Check if level is number
  if (! as.numeric(level) %% 1 == 0) {
    stop("Please enter an integer for level")
  }
  else {
    level = as.numeric(level)
  }
  #genes = as.vector(file[,ncol])
  
  # Extract Gene Entrez ID
  if (id_type == "Entrez") {
    id = select(org.Hs.eg.db, ids, "ENTREZID", multiVals = "first")
    genes_ids = id$ENTREZID[which( ! is.na(id$ENTREZID))]
  }
  else {
    genes_ids = c()
    id = select(org.Hs.eg.db, ids, "ENTREZID", "UNIPROT", multiVals = "first")
    if (duplicate == "TRUE") {
      id = unique(id)
    }
    print(id[[1]])
    genes_ids = id$ENTREZID[which( ! is.na(id$ENTREZID))]
    # IDs that have NA ENTREZID
    NAs = id$UNIPROT[which(is.na(id$ENTREZID))]
    print("IDs unable to convert to ENTREZID: ")
    print(NAs)
  }
  
  # Create basic profiles
  profile.CC = basicProfile(genes_ids, onto='CC', level=level, orgPackage="org.Hs.eg.db", empty.cats=F, ord=T, na.rm=T)
  profile.BP = basicProfile(genes_ids, onto='BP', level=level, orgPackage="org.Hs.eg.db", empty.cats=F, ord=T, na.rm=T)
  profile.MF = basicProfile(genes_ids, onto='MF', level=level, orgPackage="org.Hs.eg.db", empty.cats=F, ord=T, na.rm=T)
  profile.ALL = basicProfile(genes_ids, onto='ANY', level=level, orgPackage="org.Hs.eg.db", empty.cats=F, ord=T, na.rm=T)
  
  # Print profile
  # printProfiles(profile)
  
  return(c(profile.CC, profile.MF, profile.BP, profile.ALL))
}

# Plot profiles to PNG
plotPNG = function(profile.CC = NULL, profile.BP = NULL, profile.MF = NULL, profile.ALL = NULL, per = TRUE, title = TRUE) {
  if (!is.null(profile.CC)) {
    png("profile.CC.png")
    plotProfiles(profile.CC, percentage=per, multiplePlots=FALSE, aTitle=title)
    dev.off()
  }
  if (!is.null(profile.BP)) {
    png("profile.BP.png")
    plotProfiles(profile.BP, percentage=per, multiplePlots=FALSE, aTitle=title)
    dev.off()
  }
  if (!is.null(profile.MF)) {
    png("profile.MF.png")
    plotProfiles(profile.MF, percentage=per, multiplePlots=FALSE, aTitle=title)
    dev.off()
  }
  if (!is.null(profile.ALL)) {
    png("profile.ALL.png")
    plotProfiles(profile.ALL, percentage=per, multiplePlots=T, aTitle=title)
    dev.off()
  }
}

# Plot profiles to JPEG
plotJPEG = function(profile.CC = NULL, profile.BP = NULL, profile.MF = NULL, profile.ALL = NULL, per = TRUE, title = TRUE) {
  if (!is.null(profile.CC)) {
    jpeg("profile.CC.jpeg")
    plotProfiles(profile.CC, percentage=per, multiplePlots=FALSE, aTitle=title)
    dev.off()
  }
  if (!is.null(profile.BP)) {
    jpeg("profile.BP.jpeg")
    plotProfiles(profile.BP, percentage=per, multiplePlots=FALSE, aTitle=title)
    dev.off()
  }
  if (!is.null(profile.MF)) {
    jpeg("profile.MF.jpeg")
    plotProfiles(profile.MF, percentage=per, multiplePlots=FALSE, aTitle=title)
    dev.off()
  }
  if (!is.null(profile.ALL)) {
    jpeg("profile.ALL.jpeg")
    plotProfiles(profile.ALL, percentage=per, multiplePlots=FALSE, aTitle=title)
    dev.off()
  }
}

# Plot profiles to PDF
plotPDF = function(profile.CC = NULL, profile.BP = NULL, profile.MF = NULL, profile.ALL = NULL, per = TRUE, title = TRUE) {
  if (!is.null(profile.CC)) {
    pdf("profile.CC.pdf")
    plotProfiles(profile.CC, percentage=per, multiplePlots=FALSE, aTitle=title)
    dev.off()
  }
  if (!is.null(profile.BP)) {
    pdf("profile.BP.pdf")
    plotProfiles(profile.BP, percentage=per, multiplePlots=FALSE, aTitle=title)
    dev.off()
  }
  if (!is.null(profile.MF)) {
    pdf("profile.MF.pdf")
    plotProfiles(profile.MF, percentage=per, multiplePlots=FALSE, aTitle=title)
    dev.off()
  }
  if (!is.null(profile.ALL)) {
    #print("all")
    pdf("profile.ALL.pdf")
    plotProfiles(profile.ALL, percentage=per, multiplePlots=FALSE, aTitle=title)
    dev.off()
  }
}

goprofiles = function() {
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
        --ncol: the column number which you would like to apply...
        --header: true/false if your file contains a header
        --id_type: the type of input IDs (UniProt/EntrezID)
        --onto_opt: ontology options
        --plot_opt: plot extension options (PDF/JPEG/PNG)
        --level: 1-3
        --per
        --title: title of the plot
        --duplicate: remove dupliate input IDs (true/false)
        --text_output: text output filename \n")
    q(save="no")
  }
  
  # Parse arguments
  parseArgs <- function(x) strsplit(sub("^--", "", x), "=")
  argsDF <- as.data.frame(do.call("rbind", parseArgs(args)))
  args <- as.list(as.character(argsDF$V2))
  names(args) <- argsDF$V1

  input_type = args$input_type
  if (input_type == "text") {
    input = strsplit(args$input, " ")[[1]]
  }
  else if (input_type == "file") {
    filename = args$input
    ncol = args$ncol
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
  id_type = args$id_type
  ontoopt = strsplit(args$onto_opt, ",")[[1]]
  #print(ontoopt)
  #plotopt = strsplit(args[3], ",")
  plotopt = args$plot_opt
  level = args$level
  per = as.logical(args$per)
  title = args$title
  duplicate = args$duplicate
  text_output = args$text_output

  profiles = getprofile(input, id_type, level, duplicate)
  profile.CC = profiles[1]
  #print(profile.CC)
  profile.MF = profiles[2]
  #print(profile.MF)
  profile.BP = profiles[3]
  #print(profile.BP)
  profile.ALL = profiles[-3:-1]
  #print(profile.ALL)
  #c(profile.ALL, profile.CC, profile.MF, profile.BP)
    
  if ("CC" %in% ontoopt) {
    write.table(profile.CC, text_output, append = TRUE, sep="\t", row.names = FALSE, quote=FALSE)
    if (grepl("PNG", plotopt)) {
      plotPNG(profile.CC=profile.CC, per=per, title=title)
    }
    if (grepl("JPEG", plotopt)) {
      plotJPEG(profile.CC = profile.CC, per=per, title=title)
    }
    if (grepl("PDF", plotopt)) {
      plotPDF(profile.CC = profile.CC, per=per, title=title)
    }
  }
  if ("MF" %in% ontoopt) {
    write.table(profile.MF, text_output, append = TRUE, sep="\t", row.names = FALSE, quote=FALSE)
    if (grepl("PNG", plotopt)) {
      plotPNG(profile.MF = profile.MF, per=per, title=title)
    }
    if (grepl("JPEG", plotopt)) {
      plotJPEG(profile.MF = profile.MF, per=per, title=title)
    }
    if (grepl("PDF", plotopt)) {
      plotPDF(profile.MF = profile.MF, per=per, title=title)
    }
  }
  if ("BP" %in% ontoopt) {
    write.table(profile.BP, text_output, append = TRUE, sep="\t", row.names = FALSE, quote=FALSE)
    if (grepl("PNG", plotopt)) {
      plotPNG(profile.BP = profile.BP, per=per, title=title)
    }
    if (grepl("JPEG", plotopt)) {
      plotJPEG(profile.BP = profile.BP, per=per, title=title)
    }
    if (grepl("PDF", plotopt)) {
      plotPDF(profile.BP = profile.BP, per=per, title=title)
    }
  }
}

goprofiles()
