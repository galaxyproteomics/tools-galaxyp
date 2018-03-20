# Read file and return file content as data.frame
readfile = function(filename, header) {
  if (header == "true") {
    # Read only first line of the file as header:
    headers <- read.table(filename, nrows = 1, header = FALSE, sep = "\t", stringsAsFactors = FALSE, fill = TRUE, na.strings=c("", "NA"), blank.lines.skip = TRUE, quote = "")
    #Read the data of the files (skipping the first row)
    file <- read.table(filename, skip = 1, header = FALSE, sep = "\t", stringsAsFactors = FALSE, fill = TRUE, na.strings=c("", "NA"), blank.lines.skip = TRUE, quote = "")
    # Remove empty rows
    file <- file[!apply(is.na(file) | file == "", 1, all), , drop=FALSE]
    #And assign the header to the data
    names(file) <- headers
  }
  else {
    file <- read.table(filename, header = FALSE, sep = "\t", stringsAsFactors = FALSE, fill = TRUE, na.strings=c("", "NA"), blank.lines.skip = TRUE, quote = "")
    # Remove empty rows
    file <- file[!apply(is.na(file) | file == "", 1, all), , drop=FALSE]
  }
  return(file)
}

# Mapping IDs using file built from
#   - HUMAN_9606_idmapping_selected.tab
#     Tarball downloaded from ftp://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/idmapping/by_organism/
#   - nextprot_ac_list_all.txt 
#     Downloaded from ftp://ftp.nextprot.org/pub/current_release/ac_lists/
# Available databases: 
#   UNIPROT_AC: Uniprot accession number (e.g. P31946)
#   UNIPROT_ID: Uniprot identifiers (e.g 1433B_HUMAN)
#   GeneID_EntrezGene: Entrez gene ID (serie of digit) (e.g. 7529)
#   RefSeq: RefSeq (NCBI) protein (e.g.  NP_003395.1; NP_647539.1; XP_016883528.1)
#   GI_number: GI (NCBI GI number) ID (serie of digits) assigned to each sequence record processed by NCBI (e.g; 21328448; 377656701; 67464627; 78101741) 
#   PDB: Protein DataBank Identifiers (e.g. 2BR9:A; 3UAL:A;   3UBW:A) 
#   GO_ID: GOterms (Gene Ontology) Identifiers (e.g. GO:0070062; GO:0005925; GO:0042470; GO:0016020; GO:0005739; GO:0005634)
#   PIR: Protein Information Resource ID (e.g. S34755)	
#   OMIM: OMIM (Online Mendelian Inheritance in Man database) ID (serie of digits) (e.g: 601289)	
#   UniGene: Unigene Identifier (e.g. Hs.643544)
#   Ensembl_ENSG: Ensembl gene identifiers (e.g. ENSG00000166913) 
#   Ensembl_ENST: Ensembl transcript identifiers (e.g. ENST00000353703; ENST00000372839)
#   Ensembl_ENSP: Ensembl protein identifiers (e.g. ENSP00000300161; ENSP00000361930)

mapping = function() {
  # Extract arguments
  args = commandArgs(trailingOnly = TRUE)
  #print(args)
  if (length(args) != 6) {
    stop("Not enough/Too many arguments", call. = FALSE)
  }
  else {
    input_id_type = args[1]
    list_id = args[2]
    list_id_input_type = args[3]
    options = strsplit(args[4], ",")[[1]]
    output = args[5]
    human_id_mapping_file = args[6]
    
    # Extract ID maps
    human_id_map = read.table(human_id_mapping_file, header = TRUE, sep = "\t", stringsAsFactors = FALSE, fill = TRUE, na.strings = "", quote = "")
    
    # Extract input IDs
    if (list_id_input_type == "list") {
      list_id = strsplit(args[2], "[ \t\n]+")[[1]]
      # Remove isoform accession number (e.g. "-2")
      list_id = gsub("-.+", "", list_id)
    }
    else if (list_id_input_type == "file") {
      filename = as.character(strsplit(list_id, ",")[[1]][1])
      column_number = as.numeric(gsub("c", "" ,strsplit(list_id, ",")[[1]][2]))
      header = strsplit(list_id, ",")[[1]][3]
      file_all = readfile(filename, header)
      print(class(file_all))
      str(file_all)
      print(class(file_all[,1]))
      list_id = c()
      list_id = sapply(strsplit(file_all[,column_number], ";"), "[", 1)
      # Remove isoform accession number (e.g. "-2")
      list_id = gsub("-.+", "", list_id)
    }
    names = c()
    
    # Map IDs
    res = matrix(nrow=length(list_id), ncol=0)

    for (opt in options) {
      names = c(names, opt)
      mapped = human_id_map[match(list_id, human_id_map[input_id_type][,]),][opt][,]
      res = cbind(res, matrix(mapped))
    }
     
    # Write output
    if (list_id_input_type == "list") {
      res = cbind(as.matrix(list_id), res)
      names = c(input_id_type, names)
      colnames(res) = names
      write.table(res, output, row.names = FALSE, sep = "\t", quote = FALSE)
    }
    else if (list_id_input_type == "file") {
      names(res) = options
      names = c(names(file_all), names)
      output_content = cbind(file_all, res)
      colnames(output_content) = names
      write.table(output_content, output, row.names = FALSE, sep = "\t", quote = FALSE)
    }
  }
}

mapping()

#Rscript id_converter_UniProt.R "UniProt.AC" "test-data/UnipIDs.txt,c1,false" "file" "Ensembl_PRO,Ensembl,neXtProt_ID" "test-data/output.txt" ../../utils/mapping_file.txt
