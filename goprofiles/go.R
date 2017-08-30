# Load necessary libraries
library("org.Hs.eg.db", quietly=TRUE)
library("goProfiles", quietly=TRUE)

# Read file and return file content as data.frame?
readfile = function(filename, header) {
  if (header == "true") {
    # Read only the first two lines of the files as data (without headers):
    headers <- read.table(filename, nrows = 1, header = FALSE, sep = "\t", stringsAsFactors = FALSE, fill = TRUE)
    #print("header")
    #print(headers)
    # Create the headers names with the two (or more) first rows, sappy allows to make operations over the columns (in this case paste) - read more about sapply here :
    #headers_names <- sapply(headers, paste, collapse = "_")
    #print(headers_names)
    #Read the data of the files (skipping the first 2 rows):
    file <- read.table(filename, skip = 1, header = FALSE, sep = "\t", stringsAsFactors = FALSE, fill = TRUE)
    #print(file[1,])
    #And assign the headers of step two to the data:
    names(file) <- headers
  }
  else {
    file <- read.table(filename, header = FALSE, sep = "\t", stringsAsFactors = FALSE, fill = TRUE)
  }
  return(file)
}

#filename = "/Users/LinCun/Documents/ProteoRE/usecase1/Check/HPA.Selection.134.txt"
#test = readfile(filename)
#str(test)
#str(test$Gene.names)
getprofile = function(prot_ids, level) {
  
  # Check if level is number
  if (! as.numeric(level) %% 1 == 0) {
    stop("Please enter an integer for level")
  }
  else {
    level = as.numeric(level)
  }
  #genes = as.vector(file[,ncol])
  
  # Convert Protein IDs into entrez ids
  genes_ids = c()
  id = select(org.Hs.eg.db, prot_ids, "ENTREZID", "UNIPROT", multiVals = "first")
  #print(id[[1]][1])
  genes_ids = id$ENTREZID[which( ! is.na(id$ENTREZID))]
  # IDs that have NA ENTREZID
  NAs = id$UNIPROT[which(is.na(id$ENTREZID))]
  print("IDs unable to convert to ENTREZID: ")
  print(NAs)
  # for (i in 1:length(id$UNIPROT)) {
  #   print(i)
  #   if (is.na(id[[2]][i])) {
  #     print(id[[2]][i])
  #   }
  # }
  # a = id[which(id$ENTREZID == "NA"),]
  # print(a)
  # print(a$UNIPROT)
  #print(id[[1]][which(is.na(id$ENTREZID))])
  #print(genes_ids)
  # for (gene in genes) {
  #   #id = as.character(mget(gene, org.Hs.egALIAS2EG, ifnotfound = NA))
  #   id = select(org.Hs.eg.db, genes, "ENTREZID", "UNIPROT")
  #   print(id)
  #   genes_ids = append(genes_ids, id$ENTREZID)
  # }
  #print(genes_ids)
  
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

goooo = function() {
  args = commandArgs(trailingOnly = TRUE)
  print(args)
  # arguments: filename.R inputfile ncol "CC,MF,BP,ALL" "PNG,JPEG,PDF" level "TRUE"(percentage) "Title"
  if (length(args) != 7) {
    stop("Not enough/Too many arguments", call. = FALSE)
  }
  else {
    input_type = args[2]
    if (input_type == "text") {
      input = strsplit(args[1], "\\s+")[[1]]
    }
    else if (input_type == "file") {
      filename = strsplit(args[1], ",")[[1]][1]
      ncol = strsplit(args[1], ",")[[1]][2]
      # Check ncol
      if (! as.numeric(gsub("c", "", ncol)) %% 1 == 0) {
        stop("Please enter an integer for level")
      }
      else {
        ncol = as.numeric(gsub("c", "", ncol))
      }
      header = strsplit(args[1], ",")[[1]][3]
      # Get file content
      file = readfile(filename, header)
      # Extract Protein IDs list
      input = c()
      for (row in file[,ncol]) {
      input = c(input, strsplit(row, ";")[[1]][1])
      }
    }
    ontoopt = strsplit(args[3], ",")[[1]]
    #print(ontoopt)
    #plotopt = strsplit(args[3], ",")
    plotopt = args[4]
    level = args[5]
    per = as.logical(args[6])
    title = args[7]

    profiles = getprofile(input, level)
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
    
    #if (grepl("PNG", plotopt)) {
    # plotPNG(profile.ALL = profile.ALL, per=per, title=title)
    #}
    #if (grepl("JPEG", plotopt)) {
    # plotJPEG(profile.ALL = profile.ALL, per=per, title=title)
    #}
    #if (grepl("PDF", plotopt)) {
    # plotPDF(profile.ALL = profile.ALL, per=per, title=title)
    #}
  }
  
}

goooo()

#Rscript go.R ../proteinGroups_Maud.txt "1" "CC" "PDF" 2 "TRUE" "Title"
