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

nb_obs_PeptideAtlas <- function(input, atlas_file) {
  ## Calculate the sum of n_observations for each ID in input
  atlas = read_file(atlas_file, T)
  return(atlas$nb_obs[match(input,atlas$Uniprot_AC)])
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
  
  #save(args,file="/home/dchristiany/proteore_project/ProteoRE/tools/retrieve_msbased_pepatlas/args.Rda")
  #load("/home/dchristiany/proteore_project/ProteoRE/tools/retrieve_msbased_pepatlas/args.Rda")
  
  # Extract input
  input_type = args$input_type
  if (input_type == "list") {
    input = strsplit(args$input, "[ \t\n]+")[[1]]
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
    input = sapply(file[,ncol],function(x) strsplit(as.character(x),";")[[1]][1],USE.NAMES = F)
  }

  output = args$output

  #function to create a list of infos from file path
  extract_info_from_path <- function(path) {
    file_name=strsplit(tail(strsplit(path,"/")[[1]],n=1),"\\.")[[1]][1]
    date=tail(strsplit(file_name,"_")[[1]],n=1)
    tissue=paste(strsplit(file_name,"_")[[1]][1:2],collapse="_")
    return (c(date,tissue,file_name,path))
  }
  
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

