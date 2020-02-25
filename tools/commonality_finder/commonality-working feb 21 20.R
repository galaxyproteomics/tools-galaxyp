FirstSubstrateSet<- read.csv("input1.csv", stringsAsFactors=FALSE, header = FALSE)
Firstsubbackfreq<- read.csv("input2.csv", header=FALSE, stringsAsFactors=FALSE)
SubstrateHeader<-FirstSubstrateSet[1,]
FirstSubstrateSet<- FirstSubstrateSet[2:nrow(FirstSubstrateSet),]
if(nrow(Firstsubbackfreq[1,]>35)){
  if(grepl(pattern = "Properties", x=Firstsubbackfreq[1,22])){
    Firstsubbackfreq<-t(Firstsubbackfreq)
  }
}


SecondSubstrateSet<- read.csv("input3.csv", stringsAsFactors=FALSE, header = FALSE)
Secondsubbackfreq<- read.csv("input4.csv", header=FALSE, stringsAsFactors=FALSE)
SecondSubstrateSet<- SecondSubstrateSet[2:nrow(SecondSubstrateSet),]
if(nrow(Secondsubbackfreq[1,]>35)){
  if(grepl(pattern = "Properties", x=Secondsubbackfreq[1,22])){
    Secondsubbackfreq<-t(Secondsubbackfreq)
  }
}


ThirdSubstrateSet<- read.csv("input5.csv", stringsAsFactors=FALSE, header = FALSE)
Thirdsubbackfreq<- read.csv("input6.csv", header=FALSE, stringsAsFactors=FALSE)
ThirdSubstrateSet<- ThirdSubstrateSet[2:nrow(ThirdSubstrateSet),]
if(nrow(Thirdsubbackfreq[1,]>35)){
  if(grepl(pattern = "Properties", x=Thirdsubbackfreq[1,22])){
    Thirdsubbackfreq<-t(Thirdsubbackfreq)
  }
}




#ff you want ONLY FULL MOTIFS, put "YES" here, please use all caps
FullMotifsOnly_questionmark<-"NO"
#If you want ONLY TRUNCATED MOTIFS, put "YES" here, please use all caps
TruncatedMotifsOnly_questionmark<-"NO"
#if you want to find the overlap, put a "YES" here (all caps), if you want to find the non-overlap, put "NO" (all caps)
Are_You_Looking_For_Commonality<-"YES"


#then put the names of your output files here
Shared_motifs_table<-"sharedmotifs.csv"
Shared_subbackfreq_table<-"sharedSBF.csv"

# Shared_motifs_table<-"Shared motifs 7-27-17.csv"
# Shared_subbackfreq_table<-"SubstrateBackgrounFrequency-for-shared-motifs 4 7-27-17.csv"

First_unshared_motifs_table<-"R1 substrates.csv"
First_unshared_subbackfreq<-"R1 SBF.csv"

Second_unshared_motifs_table<-"R2 subs.csv"
Second_unshared_subbackfreq<-"R2 SBf.csv"

Third_unshared_motifs_table<-"R3 subs.csv"
Third_unshared_subbackfreq<-"R3 SBF.csv"

#final note, this code is going to be unworkable if you want to make a Venn diagram of more than 3 circles.  I think I'll poke around
#other languages to see if any of them can do it.
####################################################################################################################################





FirstxY<-rep("xY",times=nrow(FirstSubstrateSet))
FirstSubstrateSet[,11]<-FirstxY

SecondxY<-rep("xY",times=nrow(SecondSubstrateSet))
SecondSubstrateSet[,11]<-SecondxY

ThirdxY<-rep("xY",times=nrow(ThirdSubstrateSet))
ThirdSubstrateSet[,11]<-ThirdxY











####################################################################################################################################
####################################################################################################################################
# better version of this code written in C: what happens when two kinases share a motif, but they found that motif in two 
# separate proteins thus two separate accession numbers?
# It should actually output the shared motif and BOTH accession numbers.  Right now it does not, it only maps out the second
# accession number.  So that needs to be fixed BUT you need to keep the commonality between a motif and its accession number
####################################################################################################################################
####################################################################################################################################
####################################################################################################################################
####################################################################################################################################

#Create the motif sets, deciding wether or not you're looking for truncated or full here
#full only
 
FTLwtmotifs=matrix(,nrow = nrow(FirstSubstrateSet),ncol=1)
FTLwtAccessionNumbers=matrix(data = Firstsubbackfreq[1,],ncol=1)

for (i in 1:nrow(FirstSubstrateSet)){
  FTLwtletters<-FirstSubstrateSet[i,4:18]
  FTLwtletters<-FTLwtletters[FTLwtletters !="XXXXX"]
  FTLwtletters<-paste(FTLwtletters, sep="", collapse="")
  leftspaces<-c()
  rightspaces<-c()
  
  YYYmotif <- unlist(strsplit(FTLwtletters, split = ""))
  YYYposition <- match(x = "x", table = YYYmotif)
  #position itself tells me how much is to the left of that X by what it's number is.  x at position 4 tells me that there are
  #just 3 letters to the left of x
  
  YYYLettersToTheLeft <- YYYposition - 1
  #how many letters to the right SHOULD just be length(motif)-position-1 if it's 5 long and x is at 3 then Y is at 4 and there is
  #just 1 spot to the right of Y so LettersToTheRight<-1 because 5-3-1=1
  YYYLettersToTheRight <- length(YYYmotif) - YYYposition - 1
  #then sanity check, we're currently looking only at +/-4, but this spot allows for up to +/- 7 as well, just depends on what the
  #variable the user puts in is
  
  
  if (YYYLettersToTheLeft < 7 | YYYLettersToTheRight < 7) {
    leftspaces<-rep(" ",times=(7-YYYLettersToTheLeft))
    rightspaces<-rep(" ",times=7-(YYYLettersToTheRight))
    #add blank spaces if the motif has less than 4 letters to the left/right
    motif<-c(leftspaces,YYYmotif,rightspaces)
    #save that motif, which is the Y and +/- 4 amino acids, including truncation
    motif<-motif[!motif %in% "x"]
    motif<-paste(motif, sep="", collapse="")
    FTLwtletters<-motif
    FTLwtmotifs[i,1]<-FTLwtletters
    # FTLwtAccessionNumbers[i,1]<-FirstSubstrateSet[i,3]
  }
  
  if(YYYLettersToTheLeft>6 && YYYLettersToTheRight>6){
    motif<-YYYmotif
    #add blank spaces if the motif has less than 4 letters to the left/right
    motif<-c(leftspaces,YYYmotif,rightspaces)
    #save that motif, which is the Y and +/- 4 amino acids, including truncation
    motif<-motif[!motif %in% "x"]
    motif<-paste(motif, sep="", collapse="")
    FTLwtletters<-motif
    FTLwtmotifs[i,1]<-FTLwtletters
    # FTLwtAccessionNumbers[i,1]<-FirstSubstrateSet[i,3]
    
    
  }
  
}

D835Ymotifs=matrix(,nrow = nrow(SecondSubstrateSet),ncol=1)
D835YAccessionNumbers<-matrix(data = Secondsubbackfreq[1,],ncol = 1)

for (i in 1:nrow(SecondSubstrateSet)){
  D835letters<-SecondSubstrateSet[i,4:18]
  D835letters<-D835letters[D835letters !="XXXXX"]
  D835letters<-paste(D835letters, sep="", collapse="")
  leftspaces<-c()
  rightspaces<-c()
  
  YYYmotif <- unlist(strsplit(D835letters, split = ""))
  YYYposition <- match(x = "x", table = YYYmotif)
  #position itself tells me how much is to the left of that X by what it's number is.  x at position 4 tells me that there are
  #just 3 letters to the left of x
  
  YYYLettersToTheLeft <- YYYposition - 1
  #how many letters to the right SHOULD just be length(motif)-position-1 if it's 5 long and x is at 3 then Y is at 4 and there is
  #just 1 spot to the right of Y so LettersToTheRight<-1 because 5-3-1=1
  YYYLettersToTheRight <- length(YYYmotif) - YYYposition - 1
  #then sanity check, we're currently looking only at +/-4, but this spot allows for up to +/- 7 as well, just depends on what the
  #variable the user puts in is
  if (YYYLettersToTheLeft < 7 | YYYLettersToTheRight < 7) {
    leftspaces<-rep(" ",times=(7-YYYLettersToTheLeft))
    rightspaces<-rep(" ",times=7-(YYYLettersToTheRight))
    #add blank spaces if the motif has less than 4 letters to the left/right
    motif<-c(leftspaces,YYYmotif,rightspaces)
    #save that motif, which is the Y and +/- 4 amino acids, including truncation
    motif<-motif[!motif %in% "x"]
    motif<-paste(motif, sep="", collapse="")
    D835letters<-motif
    D835Ymotifs[i,1]<-D835letters
    # D835YAccessionNumbers[i,1]<-FirstSubstrateSet[i,3]
  }
  
  if(YYYLettersToTheLeft>6 && YYYLettersToTheRight>6){
    motif<-YYYmotif
    #add blank spaces if the motif has less than 4 letters to the left/right
    motif<-c(leftspaces,YYYmotif,rightspaces)
    #save that motif, which is the Y and +/- 4 amino acids, including truncation
    motif<-motif[!motif %in% "x"]
    motif<-paste(motif, sep="", collapse="")
    D835letters<-motif
    D835Ymotifs[i,1]<-D835letters
    # D835YAccessionNumbers[i,1]<-FirstSubstrateSet[i,3]
  }
}


ITDmotifs=matrix(,nrow = nrow(ThirdSubstrateSet),ncol=1)
ITDAccessionNumbers<-matrix(data = Thirdsubbackfreq[1,],ncol = 1)

for (i in 1:nrow(ThirdSubstrateSet)){
  ITDletters<-ThirdSubstrateSet[i,4:18]
  ITDletters<-ITDletters[ITDletters !="XXXXX"]
  ITDletters<-paste(ITDletters, sep="", collapse="")
  YYYmotif <- unlist(strsplit(ITDletters, split = ""))
  leftspaces<-c()
  rightspaces<-c()
  YYYposition <- match(x = "x", table = YYYmotif)
  #position itself tells me how much is to the left of that X by what it's number is.  x at position 4 tells me that there are
  #just 3 letters to the left of x
  
  YYYLettersToTheLeft <- YYYposition - 1
  #how many letters to the right SHOULD just be length(motif)-position-1 if it's 5 long and x is at 3 then Y is at 4 and there is
  #just 1 spot to the right of Y so LettersToTheRight<-1 because 5-3-1=1
  YYYLettersToTheRight <- length(YYYmotif) - YYYposition - 1
  #then sanity check, we're currently looking only at +/-4, but this spot allows for up to +/- 7 as well, just depends on what the
  #variable the user puts in is
  if (YYYLettersToTheLeft < 7 | YYYLettersToTheRight < 7) {
    leftspaces<-rep(" ",times=(7-YYYLettersToTheLeft))
    rightspaces<-rep(" ",times=7-(YYYLettersToTheRight))
    #add blank spaces if the motif has less than 4 letters to the left/right
    motif<-c(leftspaces,YYYmotif,rightspaces)
    #save that motif, which is the Y and +/- 4 amino acids, including truncation
    motif<-motif[!motif %in% "x"]
    motif<-paste(motif, sep="", collapse="")
    ITDletters<-motif
    ITDmotifs[i,1]<-ITDletters
    # ITDAccessionNumbers[i,1]<-FirstSubstrateSet[i,3]
  }
  
  if(YYYLettersToTheLeft>6 && YYYLettersToTheRight>6){
    motif<-YYYmotif
    #add blank spaces if the motif has less than 4 letters to the left/right
    motif<-c(leftspaces,YYYmotif,rightspaces)
    #save that motif, which is the Y and +/- 4 amino acids, including truncation
    motif<-motif[!motif %in% "x"]
    motif<-paste(motif, sep="", collapse="")
    ITDletters<-motif
    ITDmotifs[i,1]<-ITDletters
    # ITDAccessionNumbers[i,1]<-FirstSubstrateSet[i,3]
  }
}
  
#############################################################################################################################
#############################################################################################################################
#############################################################################################################################
#############################################################################################################################
#############################################################################################################################

#now look for either commonality or difference.  Actually could you look for both...

if (Are_You_Looking_For_Commonality=="YES"){
  
  columnalheader<-c(as.character(Thirdsubbackfreq[1:36,1]))
  columnalheader<-matrix(columnalheader,nrow = 1)

  SubstrateOverlap1<-intersect(D835Ymotifs,ITDmotifs)
  SubstrateOverlap1<-as.matrix(SubstrateOverlap1)
  
  
  columnalheader<-c(rep(NA,36))
  FinalMatrix<-matrix(data =columnalheader,ncol = 1)

  SubstrateOverlapFINAL<-intersect(FTLwtmotifs,SubstrateOverlap1)
  AccessionOverlap1<-intersect(D835YAccessionNumbers,ITDAccessionNumbers)
  AccessionOverlapFinal<-intersect(AccessionOverlap1,FTLwtAccessionNumbers)
  AccessionOverlapFinal<-unlist(AccessionOverlapFinal)
  
  for (x in 1:length(AccessionOverlapFinal)) {
    for (y in 1:ncol(Firstsubbackfreq)) {
      Acc<-AccessionOverlapFinal[x]
      SBF<-Firstsubbackfreq[1,y]
      if(Acc==SBF){
        FinalMatrix<-cbind(FinalMatrix,Firstsubbackfreq[,y])
      }
    }
  }
  FinalMatrix<-FinalMatrix[,2:ncol(FinalMatrix)]
  
  if(grepl(pattern = "Properties", x=FinalMatrix[22,1])==FALSE){
    Outputmatrix<-cbind(Firstsubbackfreq[,1],FinalMatrix)
    write.table(x=Outputmatrix,file = Shared_subbackfreq_table,quote = FALSE,sep = ",",row.names = FALSE,col.names = FALSE,na="")
  } else {
    write.table(x=FinalMatrix,file = Shared_subbackfreq_table,quote = FALSE,sep = ",",row.names = FALSE,col.names = FALSE,na="")
  }
  
  SubstrateMatrix<-SubstrateHeader
  if(ncol(SubstrateMatrix)>18){
    SubstrateMatrix<-SubstrateMatrix[,1:18]
  }
  
  for (z in 1:length(SubstrateOverlapFINAL)) {
    motif<-SubstrateOverlapFINAL[z]
    newmotif<-unlist(strsplit(motif,split = ""))
    
    Addition<-""
    outputmotif<-c(Addition,Addition,Addition,newmotif)
    SubstrateMatrix<-rbind(SubstrateMatrix,outputmotif)
  }
  write.table(x=SubstrateMatrix,file = Shared_motifs_table,quote = FALSE,sep = ",",row.names = FALSE,col.names = FALSE,na="")
}
