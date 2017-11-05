# Usage : Rscript --vanilla get_data_nextprot.R --inputtype copypaste (or
# tabfile) --input file.txt --nextprot result_nextprot.txt --column column
# --argsP1 IsoPoint,SeqLength,MW
# --argsP2 Chr,SubcellLocations --argsP3 Diseases --type id nextprot (uniprot)
# --output output.txt --header TRUE

# e.g : 
# Rscript --vanilla get_data_nextprot.R --inputtype copypaste  --input P01133 P00533 P62158 Q16566 P31323 P17612 P10644
# P22612 P31321 P13861 P22694 P25098 P16220 Q14573 Q14571 Q14643 Q05655 Q02156
# P19174 O43865 Q01064 P54750 Q14123 P51828 Q08828 O60266 Q08462 O60503 O43306
# Q8NFM4 O95622 P40145 P17252 P05129 --nextprot
# result_nextprot.txt--column c1 --argsP1 IsoPoint --argsP2
# Chr --argsP3 Diseases --typeid uniprot --output output.txt --header FALSE

# Useful functions

'%!in%' <- function(x,y)!('%in%'(x,y))

# Parse arguments

args = commandArgs(trailingOnly = TRUE)

# create a list of the arguments from the command line, separated by a blank space
hh <- paste(unlist(args),collapse=' ')
# delete the first element of the list which is always a blank space
listoptions <- unlist(strsplit(hh,'--'))[-1]
# for each input, split the arguments with blank space as separator, unlist, and delete the first element which is the input name (e.g --protalas) 
options.args <- sapply(listoptions,function(x){
         unlist(strsplit(x, ' '))[-1]
        })
# same as the step above, except that only the names are kept
options.names <- sapply(listoptions,function(x){
  option <-  unlist(strsplit(x, ' '))[1]
})
names(options.args) <- unlist(options.names)


typeinput = as.character(options.args[1])
nextprot = read.table(as.character(options.args[3]),header=TRUE,sep="\t",quote="\"") 
listfile = as.character(options.args[2])
column = as.numeric(gsub("c","",options.args[4]))
P1_args = as.character(options.args[5])
P2_args = as.character(options.args[6])
P3_args = as.character(options.args[7])
typeid = as.character(options.args[8])
filename = as.character(options.args[9])
header = as.character(options.args[10])

if (typeinput=="copypaste"){
  sample = as.data.frame(unlist(listfile))
  sample = sample[,column]
}
if (typeinput=="tabfile"){
  
  if (header=="TRUE"){
    listfile = read.table(listfile,header=TRUE,sep="\t",quote="\"",fill=TRUE)
  }else{
    listfile = read.table(listfile,header=FALSE,sep="\t",quote="\"",fill=TRUE)
  }
  sample = listfile[,column]

}
# Change the sample ids if they are uniprot ids to be able to match them with
# Nextprot data
if (typeid=="uniprot"){
  sample = gsub("^","NX_",sample)
}

# Select user input protein ids in nextprot

if ((length(sample[sample %in% nextprot[,1]]))==0){

    write.table("None of the input ids are can be found in Nextprot",file=filename,sep="\t",quote=FALSE,col.names=TRUE,row.names=FALSE)

}else{ 

	
	to_keep = c()
	
	if (P1_args!="None"){
	  P1_args = unlist(strsplit(P1_args,","))
	  for (arg in P1_args){
	    colnb = which(colnames(nextprot) %in% c(arg))
	    to_keep = c(to_keep,colnb)    
	  }
	}
	
	if (P2_args!="None"){
	  P2_args = unlist(strsplit(P2_args,","))
	  for (arg in P2_args){
	    colnb = which(colnames(nextprot) %in% c(arg))
	    to_keep = c(to_keep,colnb)    
	  }
	}
	
	if (P3_args!="None"){
	  P3_args = unlist(strsplit(P3_args,","))
	  for (arg in P3_args){
	    colnb = which(colnames(nextprot) %in% c(arg))
	    to_keep = c(to_keep,colnb)    
	  }
	}
	to_keep = c(1,to_keep)
	lines = which(nextprot[,1] %in% sample)
  data = nextprot[lines,]
  
  data = data[,to_keep]


  # if only some of the proteins were not found in nextprot they will be added to
	# the file with the fields "Protein not found in Nextprot"
	if (length(which(sample %!in% nextprot[,1]))!=0){
	  proteins_not_found = as.data.frame(sample[which(sample %!in% nextprot[,1])])
	
	  proteins_not_found = cbind(proteins_not_found,matrix(rep("Protein not found in Nextprot",length(proteins_not_found)),nrow=length(proteins_not_found),ncol=length(colnames(data))-1))

  colnames(proteins_not_found)=colnames(data) 
	 data = rbind(data,proteins_not_found)
	}
  
  # Merge original data and data selected from nextprot

  # Before that, if the initial ids were uniprot ids change them back from
  # Nextprot to uniprot ids in data 
  if (typeid=="uniprot"){
    data[,1] = gsub("^NX_","",data[,1])
  }
  data = merge(listfile, data, by.x = column, by.y=1)
  if (typeid=="uniprot"){
    colnames(data)[1] = "UniprotID"	
  }
  if (typeid=="nextprot"){
    colnames(data)[1] = "NextprotID"	
  }
  # Write result
  write.table(data,file=filename,sep="\t",quote=FALSE,col.names=TRUE,row.names=FALSE)
	
}
