options(warn=-1)  #TURN OFF WARNINGS !!!!!!

# Load necessary libraries
suppressMessages(library(goProfiles,quietly = TRUE))

# Read file and return file content as data.frame
read_file <- function(path,header){
  file <- try(read.csv(path,header=header, sep="\t",stringsAsFactors = FALSE, quote="\"", check.names = F),silent=TRUE)
  if (inherits(file,"try-error")){
    stop("File not found !")
  }else{
    return(file)
  }
}

#convert a string to boolean
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
  if (type == "Entrez"){
    return(grepl(entrez_id,vector))
  } else if (type == "UniProt") {
    return(grepl(uniprot_pattern,vector))
  }
}

getprofile = function(ids, id_type, level, duplicate,species) {
  ####################################################################
  # Arguments
  #   - ids: list of input IDs
  #   - id_type: type of input IDs (UniProt/ENTREZID)
  #   - level
  #   - duplicate: if the duplicated IDs should be removed or not (TRUE/FALSE)
  #   - species
  ####################################################################
  
  library(species, character.only = TRUE, quietly = TRUE)
  
  if (species=="org.Hs.eg.db"){
    package=org.Hs.eg.db
  } else if (species=="org.Mm.eg.db"){
    package=org.Mm.eg.db
  } else if (species=="org.Rn.eg.db"){
    package=org.Rn.eg.db
  }
  
  # Check if level is number
  if (! as.numeric(level) %% 1 == 0) {
    stop("Please enter an integer for level")
  } else {
    level = as.numeric(level)
  }
  #genes = as.vector(file[,ncol])
  
  # Extract Gene Entrez ID
  if (id_type == "Entrez") {
    id = select(package, ids, "ENTREZID", multiVals = "first")
  } else {
    id = select(package, ids, "ENTREZID", "UNIPROT", multiVals = "first")
  }
  if (duplicate) { id = unique(id) }
  genes_ids = id$ENTREZID[which( ! is.na(id$ENTREZID))]
  NAs = id$UNIPROT[which(is.na(id$ENTREZID))] # IDs that have NA ENTREZID
  
  # Create basic profiles
  profile.CC = basicProfile(genes_ids, onto='CC', level=level, orgPackage=species, empty.cats=F, ord=T, na.rm=T)
  profile.BP = basicProfile(genes_ids, onto='BP', level=level, orgPackage=species, empty.cats=F, ord=T, na.rm=T)
  profile.MF = basicProfile(genes_ids, onto='MF', level=level, orgPackage=species, empty.cats=F, ord=T, na.rm=T)
  profile.ALL = basicProfile(genes_ids, onto='ANY', level=level, orgPackage=species, empty.cats=F, ord=T, na.rm=T)
  # Print profile
  # printProfiles(profile)
  
  return(c(profile.CC, profile.MF, profile.BP, profile.ALL))
}

#return height and width of plot in inches from profile
plot_size_from_nb_onto <- function(profile){
  width=10
  range = seq(25, 2000, by=25)
  names(range) = seq(5,242, by=3)
  nb_onto = round(nrow(profile[[1]])/25)*25
  if (nb_onto < 25) {nb_onto = 25}
    if (nb_onto <= 2000) {
      height= as.integer(names(which(range==nb_onto)))
    } else {
      height=250
    }
  return (c(width,height))
}

make_plot <- function(profile,percent,title,onto,plot_opt){
  
  tmp <- plot_size_from_nb_onto (profile)
  width <- tmp[1]
  height <- tmp[2]
  
  if (plot_opt == "PDF") {
    file_name=paste("profile_",onto,".pdf",collapse="",sep="")
    pdf(file_name, width=width, heigh=height)
  } else if (plot_opt == "JPEG"){
    file_name=paste("profile_",onto,".jpeg",collapse="",sep="")
    jpeg(file_name,width=width, height=height, units = "in", res=100)
  } else if (plot_opt == "PNG"){
    file_name=paste("profile_",onto,".png",collapse="",sep="")
    png(file_name,width=width, height=height, units = "in", res=100)
  }
  plotProfiles(profile, percentage=percent, multiplePlots=FALSE, aTitle=title)
  dev.off()
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
        --text_output: text output filename \n
        --species")
    q(save="no")
  }
  
  # Parse arguments
  parseArgs <- function(x) strsplit(sub("^--", "", x), "=")
  argsDF <- as.data.frame(do.call("rbind", parseArgs(args)))
  args <- as.list(as.character(argsDF$V2))
  names(args) <- argsDF$V1

  #save(args,file="/home/dchristiany/proteore_project/ProteoRE/tools/goprofiles/args.Rda")
  #load("/home/dchristiany/proteore_project/ProteoRE/tools/goprofiles/args.Rda")
  
  id_type = args$id_type
  input_type = args$input_type
  if (input_type == "text") {
    input = unlist(strsplit(strsplit(args$input, "[ \t\n]+")[[1]],";"))
  } else if (input_type == "file") {
    filename = args$input
    ncol = args$ncol
    # Check ncol
    if (! as.numeric(gsub("c", "", ncol)) %% 1 == 0) {
      stop("Please enter an integer for level")
    } else {
      ncol = as.numeric(gsub("c", "", ncol))
    }
    header = str2bool(args$header)
    # Get file content
    file = read_file(filename, header)
    # Extract Protein IDs list
    input = unlist(strsplit(as.character(file[,ncol]),";"))
  }
  input = input [which(!is.na(gsub("NA",NA,input)))]
  
  if (! any(check_ids(input,id_type))){
    stop(paste(id_type,"not found in your ids list, please check your IDs in input or the selected column of your input file"))
  }
  
  ontoopt = strsplit(args$onto_opt, ",")[[1]]
  onto_pos = as.integer(gsub("BP",3,gsub("MF",2,gsub("CC",1,ontoopt))))
  plotopt = args$plot_opt
  level = args$level
  per = as.logical(args$per)
  title = args$title
  duplicate = str2bool(args$duplicate)
  text_output = args$text_output
  species=args$species

  profiles = getprofile(input, id_type, level, duplicate,species)
  
  for (index in onto_pos) {
    onto = names(profiles[index])
    profile=profiles[index]
    make_plot(profile,per,title,onto,plotopt)
    text_output=paste("goProfiles_",onto,"_",title,".tsv",sep="",collapse="")
    profile = as.data.frame(profile)
    profile <- as.data.frame(apply(profile, c(1,2), function(x) gsub("^$|^ $", NA, x)))  #convert "" and " " to NA
    write.table(profile, text_output, sep="\t", row.names = FALSE, quote=FALSE, col.names = T)
  }
}

goprofiles()
