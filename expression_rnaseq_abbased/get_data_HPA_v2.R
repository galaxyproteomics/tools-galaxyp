# Usage :
# Rscript --vanilla get_data_HPA_v2.R --typeinput copypaste --input
# ENSG00000283071 --header FALSE --proteinatlas proteinatlas.csv --column c1
# --select RNA.tissue.category,Reliability..IH.,Reliability..IF. --output
# output.txt 

# INPUTS : 
# --typeinput : "copypaste" or "tabfile"
# --input : either a file name (e.g : input.txt) or a list of blank-separated
# ENSG identifiers (e.g : ENSG00000283071 ENSG00000283072)
# --header : "TRUE" or "FALSE" : indicates in case the input is a file if said
# file has an header
#	--proteinatlas : HPA proteinatlas tab file
#	--column : column containing in input ENSG identifiers
#	--select : information from HPA to select, may be
#	: RNA.tissue.category,Reliability..IH.,Reliability..IF. (comma-separated)
# --output : output file name
# Useful functions

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

'%!in%' <- function(x,y)!('%in%'(x,y))

args = commandArgs(trailingOnly = TRUE)

# create a list of the arguments from the command line, separated by a blank space
hh <- paste(unlist(args),collapse=' ')
# delete the first element of the list which is always a blank space
listoptions <- unlist(strsplit(hh,'--'))[-1]
# for each input, split the arguments with blank space as separator, unlist, and delete the first element which is the input name (e.g --protatlas) 
options.args <- sapply(listoptions,function(x){
         unlist(strsplit(x, ' '))[-1]
        })
# same as the step above, except that only the names are kept
options.names <- sapply(listoptions,function(x){
  option <-  unlist(strsplit(x, ' '))[1]
})
names(options.args) <- unlist(options.names)


typeinput = as.character(options.args[1])
proteinatlas = read.table(as.character(options.args[4]),header=TRUE,sep="\t",quote="\"",fill=TRUE,blank.lines.skip=TRUE, na.strings=c("NA"," ","")) 
listfile = options.args[2]

header = as.character(options.args[3])
column = as.numeric(gsub("c","",options.args[5]))
select = as.character(options.args[6])
output = as.character(options.args[7])

if (typeinput=="copypaste"){
  sample = as.data.frame(unlist(listfile))
  sample = sample[,column]
}
if (typeinput=="tabfile"){
  
  if (header=="TRUE"){
    listfile = readfile(listfile, "true")
  }else{
    listfile = readfile(listfile, "false")
  }
  sample = listfile[,column]

}

# Select user input ensembl ids in HPA protein atlas file 

if ((length(sample[sample %in% proteinatlas[,3]]))==0){
    write.table("None of the input ENSG ids are can be found in HPA data file",file=output,sep="\t",quote=FALSE,col.names=TRUE,row.names=FALSE)

}else{ 

	
	to_keep = c()
	
	if (select!="None"){
	  select = unlist(strsplit(select,","))
	  for (arg in select){
	    colnb = which(colnames(proteinatlas) %in% c(arg))
	    to_keep = c(to_keep,colnb)    
	  }
	}
	
  to_keep = c(3,to_keep)
  lines = which(proteinatlas[,3] %in% sample)
  data = proteinatlas[lines,]
  data = data[,to_keep]
  # if only some of the proteins were not found in proteinatlas they will be added to
  # the file with the fields "Protein not found in proteinatlas"
  if (length(which(sample %!in% proteinatlas[,3]))!=0){
    proteins_not_found = as.data.frame(sample[which(sample %!in% proteinatlas[,3])])
	  proteins_not_found = cbind(proteins_not_found,matrix(rep("Protein not found in HPA",length(proteins_not_found)),nrow=length(proteins_not_found),ncol=length(colnames(data))-1))

    colnames(proteins_not_found)=colnames(data) 
	
    data = rbind(data,proteins_not_found)
  }
  
  # Merge original data and data selected from proteinatlas

  # Before that, if the initial ids were uniprot ids change them back from
  # proteinatlas to uniprot ids in data 
  data = merge(listfile, data, by.x = column, by.y=1)
  colnames(data)[1] = "Ensembl gene ids"	
  # Write result
  write.table(data,file=output,sep="\t",quote=FALSE,col.names=TRUE,row.names=FALSE)
	
}


