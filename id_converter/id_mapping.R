

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

# Mapping IDs by using nextprot id
# Available databases: 
#   ENSG: Ensembl gene identifiers
#   ENSP: Ensembl protein identifiers
#   ENSP(unmapped): Ensembl protein identifiers that cannot be mapped to any isoform in neXtProt
#   ENST: Ensembl transcript identifiers
#   ENST(unmapped): Ensembl transcript identifiers considered as coding by Ensembl that cannot be mapped to any isoform in neXtProt
#   GeneID: NCBI GeneID gene accession numbers
#   HGNC: HGNC gene accession numbers
#   IPI: IPI protein identifiers
#   MGI: MGI mouse gene accession numbers
#   NCBI RefSeq: NCBI RefSeq protein accession numbers

####################################################################################
#   ENSG: Ensembl gene identifiers
# list_ensg: a dataframe
# option: from np to ensg (NPtoENSG) or in contrast (ENSGtoNP)
NPvsENSG = function(np_ensg_file, list_ids, option) {
  # Read Nextprot to ENSG file
  np_ensg = readfile(np_ensg_file, 0)
  res = matrix(nrow = length(list_ids), ncol = 2)
  #print(list_ids)
  #print(length(list_ids))
  #print(as.matrix(list_ids))
  res[,1] = as.matrix(list_ids)
  if (option == "ENSGtoNP") {
    for (id in list_ids) {
      res[which(res[,1] == id),2] = np_ensg[grepl(id, np_ensg[,2]),1][1]
    }
  }
  else if (option == "NPtoENSG") {
    for (id in list_ids) {
      res[which(res[,1] == id),2] = np_ensg[grepl(id, np_ensg[,1]),2][1]
    }
  }
  #print(res)
  return(res)
}

NPvsUniProt = function(list_ids, option) {
  res = matrix(nrow = length(list_ids), ncol = 2)
  res[,1] = as.matrix(list_ids)
  if (option == "NPtoUni") {
    res[,2] = substring(res[,1], 4)
  }
  else if (option == "UnitoNP") {
    res[,2] = paste("NX_", res[,1], sep = "")
    #print(res[,2])
  }
  return(res)
}


#   ENSP: Ensembl protein identifiers
NPvsENSP = function(np_ensp_file, list_ids, option) {
  # Read Nextprot to ENSP file
  np_ensp = readfile(np_ensp_file, 0)
  res = matrix(nrow = length(list_ids), ncol = 2)
  #print(list_ids)
  #print(length(list_ids))
  #print(as.matrix(list_ids))
  res[,1] = as.matrix(list_ids)
  if (option == "ENSPtoNP") {
    #list_ids$Nextprot = matrix(nrow = length(list_ids[,1]))
    #list_ids = cbind(list_ids, np_ensp[which(np_ensp[,2] %in% list_ids[,1]),1])
    for (id in list_ids) {
      res[which(res[,1] == id),2] = gsub("-[0-9]", "", np_ensp[grepl(id, np_ensp[,2]),1][1])
    }
  }
  else if (option == "NPtoENSP") {
    for (id in list_ids) {
      res[which(res[,1] == id),2] = np_ensp[grepl(id, np_ensp[,1]),2][1]
    }
  }
  return(res)
}

#   ENST: Ensembl transcript identifiers
NPvsENST = function(np_enst_file, list_ids, option) {
  # Read Nextprot to ENST file
  np_enst = readfile(np_enst_file, 0)
  res = matrix(nrow = length(list_ids), ncol = 2)
  #print(list_ids)
  #print(length(list_ids))
  #print(as.matrix(list_ids))
  res[,1] = as.matrix(list_ids)
  if (option == "ENSTtoNP") {
    for (id in list_ids) {
      res[which(res[,1] == id),2] = gsub("-[0-9]", "", np_enst[grepl(id, np_enst[,2]),1][1])
      
    }
  }
  else if (option == "NPtoENST") {
    for (id in list_ids) {
      res[which(res[,1] == id),2] = np_enst[grepl(id, np_enst[,1]),2][1]
      
    }
  }
  return(res)
}

#   GeneID: NCBI GeneID gene accession numbers
NPvsGeneID = function(np_geneID_file, list_ids, option) {
  # Read Nextprot to GeneID file
  np_geneID = readfile(np_geneID_file, 0)
  res = matrix(nrow = length(list_ids), ncol = 2)
  res[,1] = as.matrix(list_ids)
  if (option == "GeneIDtoNP") {
    for (id in list_ids) {
      res[which(res[,1] == id),2] = np_geneID[grepl(id, np_geneID[,2]),1][1]
    }
  }
  else if (option == "NPtoGeneID") {
    for (id in list_ids) {
      res[which(res[,1] == id),2] = np_geneID[grepl(id, np_geneID[,1]),2][1]
    }
  }
  return(res)
}

#   HGNC: HGNC gene accession numbers
NPvsHGNC = function(np_hgnc_file, list_ids, option) {
  # Read Nextprot to HGNC file
  np_hgnc = readfile(np_hgnc_file, 0)
  res = matrix(nrow = length(list_ids), ncol = 2)
  res[,1] = as.matrix(list_ids)
  if (option == "HGNCtoNP") {
    for (id in list_ids) {
      res[which(res[,1] == id),2] = np_hgnc[grepl(id, np_hgnc[,2]),1][1]
    }
  }
  else if (option == "NPtoHGNC") {
    for (id in list_ids) {
      res[which(res[,1] == id),2] = np_hgnc[grepl(id, np_hgnc[,1]),2][1]
    }
  }
  return(res)
}

#   IPI: IPI protein identifiers
NPvsIPI = function(np_ipi_file, list_ids, option) {
  # Read Nextprot to IPI file
  np_ipi = readfile(np_ipi_file, 0)
  res = matrix(nrow = length(list_ids), ncol = 2)
  res[,1] = as.matrix(list_ids)
  if (option == "IPItoNP") {
    for (id in list_ids) {
      res[which(res[,1] == id),2] = np_ipi[grepl(id, np_ipi[,2]),1][1]
    }
  }
  else if (option == "NPtoIPI") {
    for (id in list_ids) {
      res[which(res[,1] == id),2] = np_ipi[grepl(id, np_ipi[,1]),2][1]
    }
  }
  return(res)
}

#   MGI: MGI mouse gene accession numbers
NPvsMGI = function(np_mgi_file, list_ids, option) {
  # Read Nextprot to IMGI file
  np_mgi = readfile(np_mgi_file, 0)
  res = matrix(nrow = length(list_ids), ncol = 2)
  res[,1] = as.matrix(list_ids)
  if (option == "MGItoNP") {
    for (id in list_ids) {
      res[which(res[,1] == id),2] = np_mgi[grepl(id, np_mgi[,2]),1][1]
    }
  }
  else if (option == "NPtoMGI") {
    for (id in list_ids) {
      res[which(res[,1] == id),2] = np_mgi[grepl(id, np_mgi[,1]),2][1]
    }
  }
  return(res)
}

#   NCBI RefSeq: NCBI RefSeq protein accession numbers
NPvsNCBIRS = function(np_rs_file, list_ids, option) {
  # Read Nextprot to NCBIRS file
  np_rs = readfile(np_rs_file, 0)
  res = matrix(nrow = length(list_ids), ncol = 2)
  res[,1] = as.matrix(list_ids)
  if (option == "NCBIRStoNP") {
    for (id in list_ids) {
      res[which(res[,1] == id),2] = np_rs[grepl(id, np_rs[,2]),1][1]
    }
  }
  else if (option == "NPtoNCBIRS") {
    for (id in list_ids) {
      res[which(res[,1] == id),2] = np_rs[grepl(id, np_rs[,1]),2][1]
    }
  }
  return(res)
}

mapping = function() {
  # Define files path
  np_ensg_file = "/projet/galaxydev/galaxy/tools/proteore_uc1/tools/id_mapping/nextprot_ensg.txt"
  np_ensp_file = "/projet/galaxydev/galaxy/tools/proteore_uc1/tools/id_mapping/nextprot_ensp.txt"
  np_enst_file = "/projet/galaxydev/galaxy/tools/proteore_uc1/tools/id_mapping/nextprot_enst.txt"
  np_geneID_file = "/projet/galaxydev/galaxy/tools/proteore_uc1/tools/id_mapping/nextprot_geneid.txt"
  np_hgnc_file = "/projet/galaxydev/galaxy/tools/proteore_uc1/tools/id_mapping/nextprot_hgnc.txt"
  np_ipi_file = "/projet/galaxydev/galaxy/tools/proteore_uc1/tools/id_mapping/nextprot_ipi.txt"
  np_mgi_file = "/projet/galaxydev/galaxy/tools/proteore_uc1/tools/id_mapping/nextprot_mgi.txt"
  np_rs_file = "/projet/galaxydev/galaxy/tools/proteore_uc1/tools/id_mapping/nextprot_refseq.txt"
  
  # Extract arguments
  args = commandArgs(trailingOnly = TRUE)
  print(args)
  if (length(args) != 5) {
    stop("Not enough/Too many arguments", call. = FALSE)
  }
  else {
    input_id_type = args[1]
    list_id = args[2]
    list_id_input_type = args[3]
    options = strsplit(args[4], ",")[[1]]
    #print("ENSP" %in% options[[1]])
    output = args[5]
    
    # Extract input IDs
    if (list_id_input_type == "list") {
      list_id = strsplit(args[2], " ")[[1]]
      print(list_id)
    }
    else if (list_id_input_type == "file") {
      filename = as.character(strsplit(list_id, ",")[[1]][1])
      print(filename)
      column_number = as.numeric(gsub("c", "" ,strsplit(list_id, ",")[[1]][2]))
      header = strsplit(list_id, ",")[[1]][3]
      #file_all = read.table(filename, header = TRUE, sep = "\t", stringsAsFactors = FALSE)
      file_all = readfile(filename, header)
      #list_id = file_all[,column_number]
      list_id = c()
      for (i in file_all[,column_number]) {
        list_id = c(list_id, strsplit(i, ";")[[1]][1])
      }
      print(list_id)
    }
    #names = c(input_id_type)
    names = c()
    # Map input IDs to neXtProt if not neXtProt
    if (input_id_type == "neXtProt") {
      np = list_id
    }
    else if (input_id_type == "UniProt") {
      np = NPvsUniProt(list_id, "UnitoNP")[,2]
    }
    else if (input_id_type == "ENSG") {
      np = NPvsENSG(np_ensg_file, list_id, "ENSGtoNP")[,2]
    }
    else if (input_id_type == "ENSP") {
      np = NPvsENSP(np_ensp_file, list_id, "ENSPtoNP")[,2]
    }
    else if (input_id_type == "ENST") {
      np = NPvsENST(np_enst_file, list_id, "ENSTtoNP")[,2]
    }
    else if (input_id_type == "geneID") {
      np = NPvsGeneID(np_geneID_file, list_id, "GeneIDtoNP")[,2]
    }
    else if (input_id_type == "HGNC") {
      np = NPvsHGNC(np_hgnc_file, list_id, "HGNCtoNP")[,2]
    }
    else if (input_id_type == "IPI") {
      np = NPvsIPI(np_ipi_file, list_id, "IPItoNP")[,2]
    }
    else if (input_id_type == "MGI") {
      np = NPvsMGI(np_mgi_file, list_id, "MGItoNP")[,2]
    }
    else if (input_id_type == "RS") {
      np = NPvsNCBIRS(np_rs_file, list_id, "NCBIRStoNP")[,2]
    }
    np = as.array(np)
    
    # Map neXtProt to target ID type(s)
    res = matrix(nrow = length(np), ncol = 0)
    if ("neXtProt" %in% options) {
      res = cbind(res, as.matrix(np))
      names = c(names, "neXtProt")
    }
    if ("UniProt" %in% options) {
      uni = NPvsUniProt(np, "NPtoUni")
      res = cbind(res, uni[,2])
      names = c(names, "UniProt")
    }
    if ("ENSG" %in% options) {
      ensg = NPvsENSG(np_ensg_file, np, "NPtoENSG")
      res = cbind(res, ensg[,2])
      names = c(names, "ENSG")
    }
    if ("ENSP" %in% options) {
      ensp = NPvsENSP(np_ensp_file, np, "NPtoENSP")
      res = cbind(res, ensp[,2])
      names = c(names, "ENSP")
    }
    if ("ENST" %in% options) {
      enst = NPvsENST(np_enst_file, np, "NPtoENST")
      res = cbind(res, enst[,2])
      names = c(names, "ENST")
    }
    if ("geneID" %in% options) {
      geneID = NPvsGeneID(np_geneID_file, np, "NPtoGeneID")
      res = cbind(res, geneID[,2])
      names = c(names, "geneID")
    }
    if ("HGNC" %in% options) {
      hgnc = NPvsHGNC(np_hgnc_file, np, "NPtoHGNC")
      res = cbind(res, hgnc[,2])
      names = c(names, "HGNC")
    }
    if ("IPI" %in% options) {
      ipi = NPvsIPI(np_ipi_file, np, "NPtoIPI")
      res = cbind(res, ipi[,2])
      names = c(names, "IPI")
    }
    if ("MGI" %in% options) {
      mgi = NPvsMGI(np_mgi_file, np, "NPtoMGI")
      res = cbind(res, mgi[,2])
      names = c(names, "MGI")
    }
    if ("RS" %in% options) {
      rs = NPvsNCBIRS(np_rs_file, np, "NPtoNCBIRS")
      res = cbind(res, rs[,2])
      names = c(names, "NCBI RefSeq")
    }
    
    # Write output
    if (list_id_input_type == "list") {
      res = cbind(as.matrix(list_id), res)
      res = noquote(res)
      names = c(input_id_type, names)
      colnames(res) = names
      write.table(res, output, row.names = FALSE, sep = "\t", quote = FALSE)
    }
    else if (list_id_input_type == "file_id") {
      res = cbind(as.matrix(list_id), res)
      res = noquote(res)
      names = c(input_id_type, names)
      colnames(res) = names
      write.table(res, output, row.names = FALSE, sep = "\t", quote = FALSE)
    }
    else if (list_id_input_type == "file") {
      names(res) = options
      #names = c(as.vector(as.character(file_all[1,])), names)
      names = c(names(file_all), names)
      op = cbind(file_all, res)
      colnames(op) = names
      #print(op)
      write.table(op, output, row.names = FALSE, sep = "\t", quote = FALSE)
    }
  }
}

mapping()
#Rscript mappingIDs.R "ENSP" "ENSP00000374817 ENSP00000374818 ENSP00000374819 ENSP00000374822 ENSP00000374830 ENSP00000374835 ENSP00000374842 ENSP00000374853 ENSP00000419353 ENSP00000401707 ENSP00000410711 ENSP00000417637 ENSP00000418292 ENSP00000418903 ENSP00000418948 ENSP00000463419 ENSP00000374831 ENSP00000403672 ENSP00000420285 ENSP00000477871" "list" "HGNC" output.txt
#Rscript mappingIDs.R "UniProt" "/Users/LinCun/Documents/ProteoRE/mapping/proteinGroups_Maud.txt,c1,1" "file" "ENSP,ENSG" "output_file.txt"

