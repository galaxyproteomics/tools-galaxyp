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

#take data frame, return  data frame
split_ids_per_line <- function(line,ncol){
  
  #print (line)
  header = colnames(line)
  line[ncol] = gsub("[[:blank:]]","",line[ncol])
  
  if (length(unlist(strsplit(as.character(line[ncol]),";")))>1) {
    if (length(line)==1 ) {
      lines = as.data.frame(unlist(strsplit(as.character(line[ncol]),";")),stringsAsFactors = F)
    } else {
      if (ncol==1) {                                #first column
        lines = suppressWarnings(cbind(unlist(strsplit(as.character(line[ncol]),";")), line[2:length(line)]))
      } else if (ncol==length(line)) {                 #last column
        lines = suppressWarnings(cbind(line[1:ncol-1],unlist(strsplit(as.character(line[ncol]),";"))))
      } else {
        lines = suppressWarnings(cbind(line[1:ncol-1], unlist(strsplit(as.character(line[ncol]),";"),use.names = F), line[(ncol+1):length(line)]))
      }
    }
    colnames(lines)=header
    return(lines)
  } else {
    return(line)
  }
}

#create new lines if there's more than one id per cell in the column in order to have only one id per line
one_id_one_line <-function(tab,ncol){
  if (ncol(tab)>1){
    tab[,ncol] = sapply(tab[,ncol],function(x) gsub("[[:blank:]]","",x))
    header=colnames(tab)
    res=as.data.frame(matrix(ncol=ncol(tab),nrow=0))
    for (i in 1:nrow(tab) ) {
      lines = split_ids_per_line(tab[i,],ncol)
      res = rbind(res,lines)
    }
  }else {
    res = unlist(sapply(tab[,1],function(x) strsplit(x,";")),use.names = F)
    res = data.frame(res[which(!is.na(res[res!=""]))],stringsAsFactors = F)
    colnames(res)=colnames(tab)
  }
  return(res)
}

nb_obs_PeptideAtlas <- function(input, atlas_file) {
  ## Calculate the sum of n_observations for each ID in input
  atlas = read_file(atlas_file, T)
  return(atlas$nb_obs[match(input,atlas$Uniprot_AC)])
}

#function to create a list of infos from file path
extract_info_from_path <- function(path) {
  file_name=strsplit(tail(strsplit(path,"/")[[1]],n=1),"\\.")[[1]][1]
  date=tail(strsplit(file_name,"_")[[1]],n=1)
  tissue=paste(strsplit(file_name,"_")[[1]][1:2],collapse="_")
  return (c(date,tissue,file_name,path))
}

clean_ids <- function(ids){
  
  ids = gsub(" ","",ids)
  ids = ids[which(ids!="")]
  ids = ids[which(ids!="NA")]
  ids = ids[!is.na(ids)]
 
  return(ids) 
}

main = function() {
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
        --atlas: list of file(s) path to use
        --output: text output filename \n")
    q(save="no")
  }
  
  # Parse arguments
  parseArgs <- function(x) strsplit(sub("^--", "", x), "=")
  argsDF <- as.data.frame(do.call("rbind", parseArgs(args)))
  args <- as.list(as.character(argsDF$V2))
  names(args) <- argsDF$V1
  
  #save(args,file="/home/dchristiany/proteore_project/ProteoRE/tools/Get_ms-ms_observations/args.Rda")
  #load("/home/dchristiany/proteore_project/ProteoRE/tools/Get_ms-ms_observations/args.Rda")
  
  # Extract input
  input_type = args$input_type
  if (input_type == "list") {
    input = unlist(strsplit(strsplit(args$input, "[ \t\n]+")[[1]],";"))
  } else if (input_type == "file") {
    filename = args$input
    ncol = args$column
    # Check ncol
    if (! as.numeric(gsub("c", "", ncol)) %% 1 == 0) {
      stop("Please enter an integer for level")
    } else {
      ncol = as.numeric(gsub("c", "", ncol))
    }
    header = str2bool(args$header)
    file = read_file(filename, header)
    file = one_id_one_line(file,ncol) #only one id per line
    input = sapply(file[,ncol],function(x) strsplit(as.character(x),";")[[1]][1],USE.NAMES = F)
  }
  input = clean_ids(input)
  output = args$output
  
  #data_frame building
  paths=strsplit(args$atlas,",")[[1]]
  tmp <- sapply(paths, extract_info_from_path,USE.NAMES = FALSE)
  df <- as.data.frame(t(as.data.frame(tmp)),row.names = c(""),stringsAsFactors = FALSE)
  names(df) <- c("date","tissue","filename","path")
  
  # Annotations
  res = sapply(df$path, function(x) nb_obs_PeptideAtlas(input, x), USE.NAMES = FALSE)
  colnames(res)=df$filename

  # Write output
  if (input_type == "list") {
    res = cbind(as.matrix(input), res)
    colnames(res)[1] = "Uniprot accession number"
  } else if (input_type == "file") {
    res = cbind(file, res)
  }
  res = as.data.frame(apply(res, c(1,2), function(x) gsub("^$|^ $", NA, x)))
  write.table(res, output, row.names = FALSE, sep = "\t", quote = FALSE)
  
}

main()
#Rscript retrieve_peptideatlas.R --input_type="file" --input="test-data/FKW_Lacombe_et_al_2017_OK.txt" --atlas_brain="Human_Brain_201803_PeptideAtlas.txt" --column="c1" --header="true"  --output="test-data/PeptideAtlas_output.txt"  --atlas_urine="Human_Urine_201803_PeptideAtlas.txt" --atlas="brain,urine"

