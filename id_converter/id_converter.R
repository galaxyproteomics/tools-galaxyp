# Read file and return file content as data.frame
read_file <- function(path,header){
  file <- try(read.csv(path,header=header, sep="\t",stringsAsFactors = FALSE, quote="\"",check.names = F),silent=TRUE)
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

get_list_from_cp <-function(list){
  list = strsplit(list, "[ \t\n]+")[[1]]
  list = list[list != ""]    #remove empty entry
  list = gsub("-.+", "", list)  #Remove isoform accession number (e.g. "-2")
  return(list)
}

get_args <- function(){
  args <- commandArgs(TRUE)
  if(length(args)<1) {
    args <- c("--help")
  }
  
  # Help section
  if("--help" %in% args) {
    cat("Selection and Annotation HPA
    Arguments:
        --ref_file: path to reference file (id_mapping_file.txt)
        --input_type: type of input (list of id or filename)
        --id_type: type of input IDs
        --input: list of IDs (text or filename)
        --column_number: the column number which contains list of input IDs
        --header: true/false if your file contains a header
        --target_ids: target IDs to map to 
        --output: output filename \n")
    q(save="no")
  }
  
  # Parse arguments
  parseArgs <- function(x) strsplit(sub("^--", "", x), "=")
  argsDF <- as.data.frame(do.call("rbind", parseArgs(args)))
  args <- as.list(as.character(argsDF$V2))
  names(args) <- argsDF$V1
  
  return(args)
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
  
  args <- get_args()
  
  #save(args,file="/home/dchristiany/proteore_project/ProteoRE/tools/id_converter/args.rda")
  #load("/home/dchristiany/proteore_project/ProteoRE/tools/id_converter/args.rda")
  
  input_id_type = args$id_type # Uniprot, ENSG....
  list_id_input_type = args$input_type # list or file
  options = strsplit(args$target_ids, ",")[[1]]
  output = args$output
  id_mapping_file = args$ref_file
    
  # Extract input IDs
  if (list_id_input_type == "list") {
    list_id = get_list_from_cp(args$input)
  } else if (list_id_input_type == "file") {
    filename = args$input
    column_number = as.numeric(gsub("c", "" ,args$column_number))
    header = str2bool(args$header)
    file_all = read_file(filename, header)
    list_id = trimws(gsub("[$,\xc2\xa0]","",sapply(strsplit(as.character(file_all[,column_number]), ";"), "[", 1)))
    # Remove isoform accession number (e.g. "-2")
    list_id = gsub("-.+", "", list_id)
  }

  # Extract ID maps
  id_map = read_file(id_mapping_file, T)
    
  # Map IDs
  res <- id_map[match(list_id,id_map[input_id_type][,]),options]
  
     
  # Write output
  if (list_id_input_type == "list") {
    res = cbind(as.matrix(list_id), res)
    res <- apply(res, c(1,2), function(x) gsub("^$|^ $", NA, x))
    colnames(res)[1] = args$id_type
    write.table(res, output, row.names = FALSE, sep = "\t", quote = FALSE)
  } else if (list_id_input_type == "file") {
    output_content = cbind(file_all, res)
    output_content <- apply(output_content, c(1,2), function(x) gsub("^$|^ $", NA, x))
    if (length(options) == 1){ colnames(output_content)[ncol(output_content)] = options}
    write.table(output_content, output, row.names = FALSE, sep = "\t", quote = FALSE)
  }
}

mapping()

#Rscript id_converter_UniProt.R "UniProt.AC" "test-data/UnipIDs.txt,c1,false" "file" "Ensembl_PRO,Ensembl,neXtProt_ID" "test-data/output.txt" ../../utils/mapping_file.txt
