NAMEOFOUTPUTFILE<-"output1.csv"

SuperAwesometrial <- read.delim2("input1.tabular", header=FALSE)
#once you've used the other script to turn the FASFA into a CSV, copypaste the filepath and name 
#of the csv into this line between the quote marks.  

SBF<-read.csv("input3.csv", stringsAsFactors = FALSE, header = FALSE)
SBF<-t(SBF)

PositiveMotifs <- read.csv("input2.csv", stringsAsFactors=FALSE)
#because of R reasons, it is required that the motifs in this file have blank cells instead of spaces where there is no letter in 
#the motif

YsToim<-rep("xY",times=nrow(PositiveMotifs))
PositiveMotifs[,11]<-YsToim



################################################################################################################################
#I have to paste them, then split and unlist them, then find the x and paste again
Positive9Letters<-PositiveMotifs[,4:18]
#head(Positive9Letters)
PositiveTrueMotifs<-c()

AccessionNumbers<-as.character(SBF[2:nrow(SBF),1])
AccessionNumbers<-AccessionNumbers[!is.na(AccessionNumbers)]
ALLPOSSIBLE<-SuperAwesometrial[,1]
ALLPOSSIBLE<-as.character(ALLPOSSIBLE)
################################################################################################################################

for (q in 1:nrow(Positive9Letters)) {
  LeftJust<-0
  RightJust<-0
  
  motifmotif<-Positive9Letters[q,]
  motifmotif<-paste(motifmotif, collapse = "",sep = "")
  
  motifmotif<-unlist(strsplit(motifmotif, split = ""))
  
  position <- match(x = "x", table = motifmotif)
  LeftJust<-position-1
  RightJust<-length(motifmotif)-position-1
  
  LeftSpaces<-rep(x=" ", times=(7-LeftJust))
  RightSpaces<-rep(x=" ", times=(7-RightJust))
  
  motifmotif<-motifmotif[!motifmotif %in% c("x")]
  
  motifmotif<-c(LeftSpaces,motifmotif,RightSpaces)
  motifmotif<-paste(motifmotif, collapse = "",sep = "")
  PositiveTrueMotifs<-c(PositiveTrueMotifs,motifmotif)
}


################################################################################################################################
allmotifs<-matrix(data=c("Motifs"),nrow=1)
thenames<-matrix(data=c("AccessionNumbers"),nrow = 1)
################################################################################################################################

################################################################################################################################

#TrueMotifNums<-which(ALLPOSSIBLE %in% AccessionNumbers)
#fihlodeANs<-c()
for (q in 1:length(AccessionNumbers)) {
  patterno<-as.character(AccessionNumbers[q])
  location<-sapply(ALLPOSSIBLE, grepl, pattern=patterno, fixed=TRUE)
  if (sum(location)>0){
    whereisit<-which(location %in% TRUE)
    for (u in 1:length(whereisit)) {
      i<-whereisit[u]
      name<-c()
      data<-c()
      name<-as.character(SuperAwesometrial[i,1])
      #the name of each protein is the first column 
      name<-sub(x=name, pattern=",", replacement="")
      #the names may contain commas, remove them
      data<-as.character(SuperAwesometrial[i,3])
      #the amino acids are stored in the third column
      data<-strsplit(data,"")
      #split them into their component letters
      data<-unlist(data)
      #turn them into a vector
      motif<-c()
      for (j in 1:length(data)){
        if ("Y" %in% data[j]){
          #if there is a Y aka Tyrosine in the data
          #allmotifs=rbind(allmotifs,data[(i-4):(i+4)])
          a<-j-7
          if (a<1){
            a<-1
          }
          b<-j+7
          if (b>length(data)){
            b<-length(data)
          }
          #take the motif that is +/- 4 from that Y, sanity checks so that values are never off the grid from the protein
          
          LeftSide<-7-(j-a)
          RightSide<-7-(b-j)
          #how is the motif justified?  Does it have exactly 4 letters to the left/right, or does it not?
          
          leftspaces<-rep(" ",times=LeftSide)
          rightspaces<-rep(" ",times=RightSide)
          #add blank spaces if the motif has less than 4 letters to the left/right
          
          
          motif<-(data[(a):(b)])
          motif<-c(leftspaces,motif,rightspaces)
          #save that motif, which is the Y and +/- 4 amino acids, including truncation
          
          # lens<-c(lens,length(motif))
          # leni<-c(leni,i)
          # lenj<-c(lenj,j)
          
          motif<-paste(motif, sep="", collapse="")
          #the 4 amino acids, put them back together into a single string
          motif<-matrix(data=c(motif),nrow = 1)
          namesss<-matrix(data=c(name),nrow = 1)
          #keep this motif and separately keep the name of the protein it came from
          allmotifs<-rbind(allmotifs,motif)
          thenames<-rbind(thenames,namesss)
          #add names and motifs to a growing list
          
          # write.table(motif, file="TRIALTIALRIAALSKFDJSD.csv", quote=FALSE, sep=",",
          #             row.names=FALSE,col.names = FALSE, na="", append=TRUE)
          #and then write it into a csv, the sep is needed so that the two pieces of the data frame are separated
          #append has 1to equal true because this thing will loop around many times adding more and more data points
          #you must create a new filename/filepath with each new data you run
        }
      }
    }
  }
}




################################################################################################################################
################################################################################################################################
################################################################################################################################


# for (i in 1:nrow(SuperAwesometrial)){
# 
# }

names(allmotifs)<-thenames

truemotifs<-allmotifs[!duplicated(allmotifs)]
#truenames<-thenames[!duplicated(thenames)]
#remove duplicates from the motifs and names

#make the motifs and names into matrices

# for (w in 1:nrow(truemotifs)) {
#   for (e in 1:length(PositiveTrueMotifs)){
#     if (grepl(pattern=PositiveTrueMotifs[e], x=truemotifs[w,1],ignore.case = TRUE)==TRUE){
#       truemotifs[w,1]<-NA
#     }
#   }
# }

truemotifs<-truemotifs[!truemotifs %in% PositiveTrueMotifs]

# truemotifs<-matrix(data = truemotifs,ncol = 1)
# truenames<-matrix(data=truenames,ncol = 1)
# 
# 
# #program only works if there are more motifs than names, fuck it
# 
# rowsrows<-nrow(truemotifs)-nrow(truenames)
# nanas<-rep(NA,times=rowsrows)
# nanas<-matrix(data = nanas,ncol = 1)
# truenames<-rbind(truenames,nanas)
# #to turn the motifs and names into a single output matrix, add enough rows of NAs so the two initial matrices are equivalent,
# #then put them together columnwise

outputfile<-cbind(names(truemotifs),truemotifs)

outputfile <- gsub(",","",outputfile)

write.table(outputfile, file=NAMEOFOUTPUTFILE, quote=FALSE, sep=",",
             row.names=FALSE,col.names = FALSE, na="", append=TRUE)
