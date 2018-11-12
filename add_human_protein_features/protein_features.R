# Read file and return file content as data.frame
read_file <- function(path,header){
  file <- try(read.table(path,header=header, sep="\t",stringsAsFactors = FALSE, quote="", check.names = F),silent=TRUE)
  if (inherits(file,"try-error")){
    stop("File not found !")
  }else{
    file <- file[!apply(is.na(file) | file == "", 1, all), , drop=FALSE]
    return(file)
  }
}

order_columns <- function (df,ncol,id_type,file){
  if (id_type=="Uniprot_AC"){ncol=dim.data.frame(file)[2]}
  if (ncol==1){ #already at the right position
    return (df)
  } else {
    df = df[,c(2:ncol,1,(ncol+1):dim.data.frame(df)[2])]
  }
  return (df)
}

get_list_from_cp <-function(list){
  list = strsplit(list, "[ \t\n]+")[[1]]
  list = list[list != ""]    #remove empty entry
  list = gsub("-.+", "", list)  #Remove isoform accession number (e.g. "-2")
  return(list)
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
          --inputtype: type of input (list of id or filename)
        --input: input
        --nextprot: path to nextprot information file
        --column: the column number which you would like to apply...
        --header: true/false if your file contains a header
        --type: the type of input IDs (Uniprot_AC/EntrezID)
        --pc_features: IsoPoint,SeqLength,MW
        --localization: Chr,SubcellLocations
        --diseases_info: Diseases
        --output: text output filename \n")
    
    q(save="no")
  }
  
  parseArgs <- function(x) strsplit(sub("^--", "", x), "=")
  argsDF <- as.data.frame(do.call("rbind", parseArgs(args)))
  args <- as.list(as.character(argsDF$V2))
  names(args) <- argsDF$V1
  
  return(args)
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

# Get information from neXtProt
get_nextprot_info <- function(nextprot,input,pc_features,localization,diseases_info){
  if(diseases_info){
    cols = c("NextprotID",pc_features,localization,"Diseases")
  } else {
    cols = c("NextprotID",pc_features,localization)
  }
  
  cols=cols[cols!="None"]
  info = nextprot[match(input,nextprot$NextprotID),cols]
  return(info)
}

protein_features = function() {

  args <- get_args()  
  
  #save(args,file="/home/dchristiany/proteore_project/ProteoRE/tools/add_human_protein_features/args.rda")
  #load("/home/dchristiany/proteore_project/ProteoRE/tools/add_human_protein_features/args.rda")
  
  #setting variables
  inputtype = args$inputtype
  if (inputtype == "copy_paste") {
    input = get_list_from_cp(args$input)
    input = input[input!=""]
  } else if (inputtype == "file") {
    filename = args$input
    ncol = args$column
    # Check ncol
    if (! as.numeric(gsub("c", "", ncol)) %% 1 == 0) {
      stop("Please enter an integer for level")
    } else {
      ncol = as.numeric(gsub("c", "", ncol))
    }
    
    header = str2bool(args$header)
    file = read_file(filename, header)                                                      # Get file content
    input = sapply(file[,ncol],function(x) strsplit(as.character(x),";")[[1]][1],USE.NAMES = F)     # Extract Protein IDs list
    if (args$type == "NextprotID" && ! "NextprotID" %in% colnames(file)) { colnames(file)[ncol] <- "NextprotID" 
    } else if (args$type == "NextprotID" && "NextprotID" %in% colnames(file) && match("NextprotID",colnames(file))!=ncol ) { 
      colnames(file)[match("NextprotID",colnames(file))] <- "old_NextprotID" 
      colnames(file)[ncol] = "NextprotID"
    }
  }

  # Read reference file
  nextprot = read_file(args$nextprot,T)
  
  # Parse arguments
  id_type = args$type
  pc_features = strsplit(args$pc_features, ",")[[1]]
  localization = strsplit(args$localization, ",")[[1]]
  diseases_info = str2bool(args$diseases_info)
  output = args$output

  # Change the sample ids if they are Uniprot_AC ids to be able to match them with
  # Nextprot data
  if (id_type=="Uniprot_AC"){
    NextprotID = gsub("^","NX_",input)
    if (inputtype == "file" && "NextprotID" %in% colnames(file)){colnames(file)[match("NextprotID",colnames(file))] <- "old_NextprotID"}
    file = cbind(file,NextprotID)
    } else if (id_type=="NextprotID") {
    if (inputtype == "file") {
      NextprotID = file$NextprotID
    } else {
      NextprotID = input
    }
  }

  # Select user input protein ids in nextprot
  if ((length(NextprotID[NextprotID %in% nextprot[,1]]))==0){
    write.table("None of the input ids can be found in Nextprot",file=output,sep="\t",quote=FALSE,col.names=TRUE,row.names=FALSE)
  } else {
    res <- get_nextprot_info(nextprot,NextprotID,pc_features,localization,diseases_info)
    
    # Write output
    if (inputtype == "copy_paste") {
      if (id_type=="Uniprot_AC"){
        output_content = cbind(input, res)
        colnames(output_content)[1] = id_type
      }
      if ("res" %in% colnames(output_content)){colnames(output_content)[which(colnames(output_content)=="res")] = "NexprotID" } #if no features are selected
    } else if (inputtype == "file") {
      res = res[!duplicated(res$NextprotID),]
      output_content = merge(file, res,by="NextprotID",incomparables = NA,all.x=T)
      output_content = order_columns(output_content,ncol,id_type,file)
    }
    output_content <- as.data.frame(apply(output_content, c(1,2), function(x) gsub("^$|^ $", NA, x)))  #convert "" et " " to NA
    write.table(output_content, output, row.names = FALSE, sep = "\t", quote = FALSE)
  } 
  
}
protein_features()
