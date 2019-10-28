FirstSubstrateSet<- read.csv("input1.csv", stringsAsFactors=FALSE)
Firstsubbackfreq<- read.csv("input2.csv", header=FALSE, stringsAsFactors=FALSE)

SecondSubstrateSet<- read.csv("input3.csv", stringsAsFactors=FALSE)
Secondsubbackfreq<- read.csv("input4.csv", header=FALSE, stringsAsFactors=FALSE)

ThirdSubstrateSet<- read.csv("input5.csv", stringsAsFactors=FALSE)
Thirdsubbackfreq<- read.csv("input6.csv", header=FALSE, stringsAsFactors=FALSE)


args = commandArgs(trailingOnly=TRUE)

print(args[1])
print(args[2])
print(args[3])


#ff you want ONLY FULL MOTIFS, put "YES" here, please use all caps
FullMotifsOnly_questionmark<-args[1]
#If you want ONLY TRUNCATED MOTIFS, put "YES" here, please use all caps
TruncatedMotifsOnly_questionmark<-args[2]
#if you want to find the overlap, put a "YES" here (all caps), if you want to find the non-overlap, put "NO" (all caps)
Are_You_Looking_For_Commonality<-args[3]


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
if (Are_You_Looking_For_Commonality=="YES"){
  if (FullMotifsOnly_questionmark=="YES"){
    FTLwtmotifs=matrix(,nrow = nrow(FirstSubstrateSet),ncol=1)
    FTLwtAccessionNumbers=matrix(,nrow = nrow(FirstSubstrateSet),ncol=1)
    leftspaces<-c()
    rightspaces<-c()
    for (i in 1:nrow(FirstSubstrateSet)){
      FTLwtletters<-FirstSubstrateSet[i,4:18]
      FTLwtletters<-FTLwtletters[FTLwtletters !="XXXXX"]
      FTLwtletters<-paste(FTLwtletters, sep="", collapse="")
      
      
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
      
      if (YYYLettersToTheLeft > 6 && YYYLettersToTheRight > 6) {
        motif<-YYYmotif
        #save that motif, which is the Y and +/- 4 amino acids, including truncation
        motif<-motif[!motif %in% "x"]
        motif<-paste(motif, sep="", collapse="")
        FTLwtletters<-motif
        FTLwtmotifs[i,1]<-FTLwtletters
        FTLwtAccessionNumbers[i,1]<-FirstSubstrateSet[i,3]
        
      }
      
    }
    # FTLwtmotifs <- FTLwtmotifs[!is.na(FTLwtmotifs)]
    # FTLwtmotifs<-matrix(FTLwtmotifs,ncol = 1)
    # 
    
    D835Ymotifs=matrix(,nrow = nrow(SecondSubstrateSet),ncol=1)
    D835YAccessionNumbers<-matrix(,nrow = nrow(SecondSubstrateSet),ncol = 1)
    
    for (i in 1:nrow(SecondSubstrateSet)){
      D835letters<-SecondSubstrateSet[i,4:18]
      D835letters<-D835letters[D835letters !="XXXXX"]
      D835letters<-paste(D835letters, sep="", collapse="")
      
      
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
      
      if (YYYLettersToTheLeft > 6 && YYYLettersToTheRight > 6) {
        motif<-YYYmotif
        #add blank spaces if the motif has less than 4 letters to the left/right
        motif<-c(leftspaces,YYYmotif,rightspaces)
        #save that motif, which is the Y and +/- 4 amino acids, including truncation
        motif<-motif[!motif %in% "x"]
        motif<-paste(motif, sep="", collapse="")
        D835letters<-motif
        D835Ymotifs[i,1]<-D835letters
        D835YAccessionNumbers[i,1]<-SecondSubstrateSet[i,3]
        
      }
    }
    
    ITDmotifs=matrix(,nrow = nrow(ThirdSubstrateSet),ncol=1)
    ITDAccessionNumbers<-matrix(,nrow = nrow(ThirdSubstrateSet))
    
    for (i in 1:nrow(ThirdSubstrateSet)){
      ITDletters<-ThirdSubstrateSet[i,4:18]
      ITDletters<-ITDletters[ITDletters !="XXXXX"]
      ITDletters<-paste(ITDletters, sep="", collapse="")
      YYYmotif <- unlist(strsplit(ITDletters, split = ""))
      YYYposition <- match(x = "x", table = YYYmotif)
      #position itself tells me how much is to the left of that X by what it's number is.  x at position 4 tells me that there are
      #just 3 letters to the left of x
      
      YYYLettersToTheLeft <- YYYposition - 1
      #how many letters to the right SHOULD just be length(motif)-position-1 if it's 5 long and x is at 3 then Y is at 4 and there is
      #just 1 spot to the right of Y so LettersToTheRight<-1 because 5-3-1=1
      YYYLettersToTheRight <- length(YYYmotif) - YYYposition - 1
      #then sanity check, we're currently looking only at +/-4, but this spot allows for up to +/- 7 as well, just depends on what the
      #variable the user puts in is
      
      if (YYYLettersToTheLeft > 6 && YYYLettersToTheRight > 6) {
        motif<-YYYmotif
        #add blank spaces if the motif has less than 4 letters to the left/right
        motif<-c(leftspaces,YYYmotif,rightspaces)
        #save that motif, which is the Y and +/- 4 amino acids, including truncation
        motif<-motif[!motif %in% "x"]
        motif<-paste(motif, sep="", collapse="")
        ITDletters<-motif
        ITDmotifs[i,1]<-ITDletters
        ITDAccessionNumbers[i,1]<-ThirdSubstrateSet[i,3]
        
      }
    }
    
  }
  
  ##############################################3
  #Truncated only
  if (TruncatedMotifsOnly_questionmark=="YES"){
    FTLwtmotifs=matrix(,nrow = nrow(FirstSubstrateSet),ncol=1)
    FTLwtAccessionNumbers=matrix(,nrow = nrow(FirstSubstrateSet),ncol=1)
    
    for (i in 1:nrow(FirstSubstrateSet)){
      FTLwtletters<-FirstSubstrateSet[i,4:18]
      FTLwtletters<-FTLwtletters[FTLwtletters !="XXXXX"]
      FTLwtletters<-paste(FTLwtletters, sep="", collapse="")
      
      
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
        FTLwtAccessionNumbers[i,1]<-FirstSubstrateSet[i,3]
      }
      
    }
    
    D835Ymotifs=matrix(,nrow = nrow(SecondSubstrateSet),ncol=1)
    D835YAccessionNumbers<-matrix(,nrow = nrow(SecondSubstrateSet),ncol = 1)
    
    for (i in 1:nrow(SecondSubstrateSet)){
      D835letters<-SecondSubstrateSet[i,4:18]
      D835letters<-D835letters[D835letters !="XXXXX"]
      D835letters<-paste(D835letters, sep="", collapse="")
      
      
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
        D835YAccessionNumbers[i,1]<-SecondSubstrateSet[i,3]
        D835Ymotifs[i,1]<-D835letters
      }
    }
    
    ITDmotifs=matrix(,nrow = nrow(ThirdSubstrateSet),ncol=1)
    ITDAccessionNumbers<-matrix(,nrow = nrow(ThirdSubstrateSet))
    
    for (i in 1:nrow(ThirdSubstrateSet)){
      ITDletters<-ThirdSubstrateSet[i,4:18]
      ITDletters<-ITDletters[ITDletters !="XXXXX"]
      ITDletters<-paste(ITDletters, sep="", collapse="")
      YYYmotif <- unlist(strsplit(ITDletters, split = ""))
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
        ITDAccessionNumbers[i,1]<-ThirdSubstrateSet[i,3]
        ITDmotifs[i,1]<-ITDletters
      }
    }
    
  }
  
  ###############################################
  #ALL motifs, full and truncated
  
  if (FullMotifsOnly_questionmark!="YES"&&TruncatedMotifsOnly_questionmark!="YES"){
    FTLwtmotifs=matrix(,nrow = nrow(FirstSubstrateSet),ncol=1)
    FTLwtAccessionNumbers=matrix(,nrow = nrow(FirstSubstrateSet),ncol=1)
    
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
        FTLwtAccessionNumbers[i,1]<-FirstSubstrateSet[i,3]
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
        FTLwtAccessionNumbers[i,1]<-FirstSubstrateSet[i,3]
        
        
      }
      
    }
    
    D835Ymotifs=matrix(,nrow = nrow(SecondSubstrateSet),ncol=1)
    D835YAccessionNumbers<-matrix(,nrow = nrow(SecondSubstrateSet),ncol = 1)
    
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
        D835YAccessionNumbers[i,1]<-FirstSubstrateSet[i,3]
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
        D835YAccessionNumbers[i,1]<-FirstSubstrateSet[i,3]
      }
    }
    
    
    ITDmotifs=matrix(,nrow = nrow(ThirdSubstrateSet),ncol=1)
    ITDAccessionNumbers<-matrix(,nrow = nrow(ThirdSubstrateSet))
    
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
        ITDAccessionNumbers[i,1]<-FirstSubstrateSet[i,3]
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
        ITDAccessionNumbers[i,1]<-FirstSubstrateSet[i,3]
      }
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
    # write.table(x=columnalheader,
    #             file=Shared_subbackfreq_table,
    #             quote=FALSE, sep=",",
    #             row.names=FALSE,col.names = FALSE, na="", append=TRUE)
    
    FirstOverlapmotifs<-c()
    for (i in 1:nrow(ITDmotifs)){
      for (j in 1:nrow(D835Ymotifs)){
        if (is.na(ITDmotifs[i,1])!=TRUE&&is.na(D835Ymotifs[j,1])!=TRUE){
          if (ITDmotifs[i,1]==D835Ymotifs[j,1]){
            FirstOverlapmotifs<-c(FirstOverlapmotifs,D835Ymotifs[j,1])
          }
        }
      }
    }
    
    AllAccessionNumbers<-c()
    columnalheader<-c(rep(NA,36))
    FinalMatrix<-matrix(data =columnalheader,nrow = 1)
    
    FinalMotifs<-c(rep(NA,20))
    FinalMotifsMatrix<-matrix(data = FinalMotifs,nrow = 1)
    
    
    for (l in 1:length(FirstOverlapmotifs)) {
      AccessionNumber<-00000000000
      for (k in 1:nrow(FTLwtmotifs)) {
        AccessionNumber<-0000000000000
        if(is.na(FTLwtmotifs[k])!=TRUE){
          #I don't remember why, but I felt it necessary to destroy the accession number multiple times to ensure it is
          #destroyed immediately after use
          if (FirstOverlapmotifs[l] == FTLwtmotifs[k]) {
            substratematrix<-FirstSubstrateSet[k,1:20]
            substratematrix<-as.matrix(substratematrix,nrow=1)
            FinalMotifsMatrix<-rbind(FinalMotifsMatrix,substratematrix)
            #when you find a match between the venn diagrams, save the substrate info you get into a matrix
            
            AccessionNumber <- as.character(FirstSubstrateSet[k, 3])
            #then take the accession number 
            
            for (m in 1:ncol(Firstsubbackfreq)) {
              AN <- as.character(Firstsubbackfreq[1, m])
              if (grepl(pattern = AN,
                        x = AccessionNumber,
                        fixed = TRUE) == TRUE) {
                outputmatrix <- as.character(Firstsubbackfreq[, m])
                outputmatrix <- matrix(outputmatrix, nrow = 1)
                #with that accession number, find a match in the subbackfreq file and save it here
                FinalMatrix<-rbind(FinalMatrix,outputmatrix)
              }
            }
          }
        }
      }
    }
    
    
    TrueMatrix<-FinalMatrix[!duplicated(FinalMatrix),]
    TrueFinalMotifsMatrix<-FinalMotifsMatrix[!duplicated(FinalMotifsMatrix),]
    
    TrueFinalMotifsMatrix<-TrueFinalMotifsMatrix[2:nrow(TrueFinalMotifsMatrix),]
    TrueMatrix<-TrueMatrix[2:nrow(TrueMatrix),]
    
    write.table(
      x = TrueFinalMotifsMatrix,
      file = Shared_motifs_table,
      quote = FALSE,
      sep = ",",
      row.names = FALSE,
      col.names = TRUE,
      na = "",
      append = FALSE
    )
    
    #TrueMatrix<-t(TrueMatrix)
    columnalheader<-c(as.character(Thirdsubbackfreq[1:36,1]))
    columnalheader<-matrix(columnalheader,nrow = 1)
    
    TrueMatrix<-rbind(columnalheader,TrueMatrix)
    TrueMatrix<-t(TrueMatrix)
    
    write.table(
      x = TrueMatrix,
      file = Shared_subbackfreq_table,
      quote = FALSE,
      sep = ",",
      row.names = FALSE,
      col.names = FALSE,
      na = "",
      append = TRUE
    )
  }
}

if (Are_You_Looking_For_Commonality=="NO"){
  if (FullMotifsOnly_questionmark=="YES"){
    FTLwtmotifs=rep(NA,times=nrow(FirstSubstrateSet))
    FTLwtAccessionNumbers=rep(NA,times=nrow(FirstSubstrateSet))
    leftspaces<-c()
    rightspaces<-c()
    for (i in 1:nrow(FirstSubstrateSet)){
      FTLwtletters<-FirstSubstrateSet[i,4:18]
      FTLwtletters<-FTLwtletters[FTLwtletters !="XXXXX"]
      FTLwtletters<-paste(FTLwtletters, sep="", collapse="")
      
      
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
      
      if (YYYLettersToTheLeft > 6 && YYYLettersToTheRight > 6) {
        motif<-YYYmotif
        #save that motif, which is the Y and +/- 4 amino acids, including truncation
        motif<-motif[!motif %in% "x"]
        motif<-paste(motif, sep="", collapse="")
        FTLwtletters<-motif
        FTLwtmotifs[i]<-FTLwtletters
        FTLwtAccessionNumbers[i]<-FirstSubstrateSet[i,3]
      }
      
    }
    # FTLwtmotifs <- FTLwtmotifs[!is.na(FTLwtmotifs)]
    # FTLwtmotifs<-matrix(FTLwtmotifs,ncol = 1)
    # 
    
    D835Ymotifs=rep(NA,times=nrow(FirstSubstrateSet))
    D835YAccessionNumbers=rep(NA,times=nrow(FirstSubstrateSet))
    
    for (i in 1:nrow(SecondSubstrateSet)){
      D835letters<-SecondSubstrateSet[i,4:18]
      D835letters<-D835letters[D835letters !="XXXXX"]
      D835letters<-paste(D835letters, sep="", collapse="")
      
      
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
      
      if (YYYLettersToTheLeft > 6 && YYYLettersToTheRight > 6) {
        motif<-YYYmotif
        #add blank spaces if the motif has less than 4 letters to the left/right
        motif<-c(leftspaces,YYYmotif,rightspaces)
        #save that motif, which is the Y and +/- 4 amino acids, including truncation
        motif<-motif[!motif %in% "x"]
        motif<-paste(motif, sep="", collapse="")
        D835letters<-motif
        D835Ymotifs[i]<-D835letters
        D835YAccessionNumbers[i]<-SecondSubstrateSet[i,3]
      }
    }
    
    ITDmotifs=rep(NA,times=nrow(FirstSubstrateSet))
    ITDAccessionNumbers=rep(NA,times=nrow(FirstSubstrateSet))
    
    for (i in 1:nrow(ThirdSubstrateSet)){
      ITDletters<-ThirdSubstrateSet[i,4:18]
      ITDletters<-ITDletters[ITDletters !="XXXXX"]
      ITDletters<-paste(ITDletters, sep="", collapse="")
      YYYmotif <- unlist(strsplit(ITDletters, split = ""))
      YYYposition <- match(x = "x", table = YYYmotif)
      #position itself tells me how much is to the left of that X by what it's number is.  x at position 4 tells me that there are
      #just 3 letters to the left of x
      
      YYYLettersToTheLeft <- YYYposition - 1
      #how many letters to the right SHOULD just be length(motif)-position-1 if it's 5 long and x is at 3 then Y is at 4 and there is
      #just 1 spot to the right of Y so LettersToTheRight<-1 because 5-3-1=1
      YYYLettersToTheRight <- length(YYYmotif) - YYYposition - 1
      #then sanity check, we're currently looking only at +/-4, but this spot allows for up to +/- 7 as well, just depends on what the
      #variable the user puts in is
      
      if (YYYLettersToTheLeft > 6 && YYYLettersToTheRight > 6) {
        motif<-YYYmotif
        #add blank spaces if the motif has less than 4 letters to the left/right
        motif<-c(leftspaces,YYYmotif,rightspaces)
        #save that motif, which is the Y and +/- 4 amino acids, including truncation
        motif<-motif[!motif %in% "x"]
        motif<-paste(motif, sep="", collapse="")
        ITDletters<-motif
        ITDmotifs[i]<-ITDletters
        ITDAccessionNumbers[i]<-ThirdSubstrateSet[i,3]
        
      }
    }
    names(ITDmotifs)<-ITDAccessionNumbers
    names(D835Ymotifs)<-D835YAccessionNumbers
    names(FTLwtmotifs)<-FTLwtAccessionNumbers
  }
  
  
  ##############################################3
  #Truncated only
  if (TruncatedMotifsOnly_questionmark=="YES"){
    FTLwtmotifs=matrix(,nrow = nrow(FirstSubstrateSet),ncol=1)
    FTLwtAccessionNumbers=matrix(,nrow = nrow(FirstSubstrateSet),ncol=1)
    
    for (i in 1:nrow(FirstSubstrateSet)){
      FTLwtletters<-FirstSubstrateSet[i,4:18]
      FTLwtletters<-FTLwtletters[FTLwtletters !="XXXXX"]
      FTLwtletters<-paste(FTLwtletters, sep="", collapse="")
      
      
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
        FTLwtAccessionNumbers[i,1]<-FirstSubstrateSet[i,3]
      }
      
    }
    
    D835Ymotifs=matrix(,nrow = nrow(SecondSubstrateSet),ncol=1)
    D835YAccessionNumbers<-matrix(,nrow = nrow(SecondSubstrateSet),ncol = 1)
    i=2
    for (i in 1:nrow(SecondSubstrateSet)){
      D835letters<-SecondSubstrateSet[i,4:18]
      D835letters<-D835letters[D835letters !="XXXXX"]
      D835letters<-paste(D835letters, sep="", collapse="")
      
      
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
        D835YAccessionNumbers[i,1]<-SecondSubstrateSet[i,3]
        D835Ymotifs[i,1]<-D835letters
      }
    }
    
    ITDmotifs=matrix(,nrow = nrow(ThirdSubstrateSet),ncol=1)
    ITDAccessionNumbers<-matrix(,nrow = nrow(ThirdSubstrateSet))
    
    for (i in 1:nrow(ThirdSubstrateSet)){
      ITDletters<-ThirdSubstrateSet[i,4:18]
      ITDletters<-ITDletters[ITDletters !="XXXXX"]
      ITDletters<-paste(ITDletters, sep="", collapse="")
      YYYmotif <- unlist(strsplit(ITDletters, split = ""))
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
        ITDAccessionNumbers[i,1]<-ThirdSubstrateSet[i,3]
        ITDmotifs[i,1]<-ITDletters
      }
    }
    names(FTLwtmotifs)<-FTLwtAccessionNumbers
    names(D835Ymotifs)<-D835YAccessionNumbers
    names(ITDmotifs)<-ITDAccessionNumbers
  }
  
  ###############################################
  #ALL motifs, full and truncated
  
  if (FullMotifsOnly_questionmark!="YES"&&TruncatedMotifsOnly_questionmark!="YES"){
    FTLwtmotifs=matrix(,nrow = nrow(FirstSubstrateSet),ncol=1)
    FTLwtAccessionNumbers=matrix(,nrow = nrow(FirstSubstrateSet),ncol=1)
    
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
        FTLwtAccessionNumbers[i,1]<-FirstSubstrateSet[i,3]
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
        FTLwtAccessionNumbers[i,1]<-FirstSubstrateSet[i,3]
        
        
      }
      
    }
    
    D835Ymotifs=matrix(,nrow = nrow(SecondSubstrateSet),ncol=1)
    D835YAccessionNumbers<-matrix(,nrow = nrow(SecondSubstrateSet),ncol = 1)
    
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
        D835YAccessionNumbers[i,1]<-FirstSubstrateSet[i,3]
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
        D835YAccessionNumbers[i,1]<-FirstSubstrateSet[i,3]
      }
    }
    
    
    ITDmotifs=matrix(,nrow = nrow(ThirdSubstrateSet),ncol=1)
    ITDAccessionNumbers<-matrix(,nrow = nrow(ThirdSubstrateSet))
    
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
        ITDAccessionNumbers[i,1]<-FirstSubstrateSet[i,3]
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
        ITDAccessionNumbers[i,1]<-FirstSubstrateSet[i,3]
      }
    }
    names(FTLwtmotifs)<-FTLwtAccessionNumbers
    names(D835Ymotifs)<-D835YAccessionNumbers
    names(ITDmotifs)<-ITDAccessionNumbers
  }
  
  
  FTLwtmotifsFINAL<-FTLwtmotifs[!FTLwtmotifs %in% D835Ymotifs]
  FTLwtmotifsFINAL<-FTLwtmotifsFINAL[!FTLwtmotifsFINAL %in% ITDmotifs]
  FTLwtmotifsFINAL<-FTLwtmotifsFINAL[!duplicated(FTLwtmotifsFINAL)]
  
  
  ITDmotifsFINAL<-ITDmotifs[!ITDmotifs %in% D835Ymotifs]
  ITDmotifsFINAL<-ITDmotifsFINAL[!ITDmotifsFINAL %in% FTLwtmotifs]
  ITDmotifsFINAL<-ITDmotifsFINAL[!duplicated(ITDmotifsFINAL)]
  
  
  D835YmotifsFINAL<-D835Ymotifs[!D835Ymotifs %in% FTLwtmotifs]
  D835YmotifsFINAL<-D835YmotifsFINAL[!D835YmotifsFINAL %in% ITDmotifs]
  D835YmotifsFINAL<-D835YmotifsFINAL[!duplicated(D835YmotifsFINAL)]
  
  
  columnalheader<-c(rep(NA,36))
  FTLFinalMatrix<-matrix(data =columnalheader,nrow = 1)
  
  for (k in 1:length(FTLwtmotifsFINAL)) {
    AN<-00000
    #I don't remember why, but I felt it necessary to destroy the accession number multiple times to ensure it is
    #destroyed immediately after use
    for (m in 1:ncol(Firstsubbackfreq)) {
      AN <- as.character(Firstsubbackfreq[1, m])
      if (grepl(pattern = AN,
                x = names(FTLwtmotifsFINAL[k]),
                fixed = TRUE) == TRUE) {
        outputmatrix <- as.character(Firstsubbackfreq[, m])
        outputmatrix <- matrix(outputmatrix, nrow = 1)
        #with that accession number, find a match in the subbackfreq file and save it here
        FTLFinalMatrix<-rbind(FTLFinalMatrix,outputmatrix)
      }
    }
  }
  FTLFinalMatrix<-FTLFinalMatrix[!duplicated(FTLFinalMatrix),]
  
  columnalheader<-c(rep(NA,36))
  ITDFinalMatrix<-matrix(data =columnalheader,nrow = 1)
  
  for (k in 1:length(ITDmotifsFINAL)) {
    AN<-00000
    #I don't remember why, but I felt it necessary to destroy the accession number multiple times to ensure it is
    #destroyed immediately after use
    for (m in 1:ncol(Thirdsubbackfreq)) {
      AN <- as.character(Thirdsubbackfreq[1, m])
      if (grepl(pattern = AN,
                x = names(ITDmotifsFINAL[k]),
                fixed = TRUE) == TRUE) {
        outputmatrix <- as.character(Thirdsubbackfreq[, m])
        outputmatrix <- matrix(outputmatrix, nrow = 1)
        #with that accession number, find a match in the subbackfreq file and save it here
        ITDFinalMatrix<-rbind(ITDFinalMatrix,outputmatrix)
      }
    }
  }
  ITDFinalMatrix<-ITDFinalMatrix[!duplicated(ITDFinalMatrix),]
  
  columnalheader<-c(rep(NA,36))
  D835YFinalMatrix<-matrix(data =columnalheader,nrow = 1)
  
  for (k in 1:length(D835YmotifsFINAL)) {
    #I don't remember why, but I felt it necessary to destroy the accession number multiple times to ensure it is
    #destroyed immediately after use
    for (m in 1:ncol(Secondsubbackfreq)) {
      AN <- as.character(Secondsubbackfreq[1, m])
      if (grepl(pattern = AN,
                x = names(D835YmotifsFINAL[k]),
                fixed = TRUE) == TRUE) {
        outputmatrix <- as.character(Secondsubbackfreq[, m])
        outputmatrix <- matrix(outputmatrix, nrow = 1)
        #with that accession number, find a match in the subbackfreq file and save it here
        D835YFinalMatrix<-rbind(D835YFinalMatrix,outputmatrix)
      }
    }
  }
  D835YFinalMatrix<-D835YFinalMatrix[!duplicated(D835YFinalMatrix),]
  
  FTLoutputmatrix<-matrix(data=c(FTLwtmotifsFINAL,names(FTLwtmotifsFINAL)),ncol = 2)
  
  #another fucking for loop
  FLTreference<-FTLoutputmatrix[,2]
  
  FirstLine<-colnames(FirstSubstrateSet)
  FirstLine<-FirstLine[1:23]
  for (q in 1:nrow(FTLoutputmatrix)) {
    thismotif<-unlist(strsplit(FTLoutputmatrix[q,1],""))
    thisoutput<-c("","",FTLoutputmatrix[q,2],thismotif,"","","","","")
    FirstLine<-rbind(FirstLine,thisoutput)
  }
  
  
  
  write.table(x=FirstLine,
              file=First_unshared_motifs_table,
              quote=FALSE, sep=",",
              row.names=FALSE,col.names = FALSE, na="", append=TRUE)
  
  columnalheader<-c(as.character(Thirdsubbackfreq[1:36,1]))
  columnalheader<-matrix(columnalheader,nrow = 1)
  
  # columnalheader<-rbind(columnalheader,FTLFinalMatrix)
  
  write.table(x=columnalheader,
              file=First_unshared_subbackfreq,
              quote=FALSE, sep=",",
              row.names=FALSE,col.names = FALSE, na="", append=TRUE)
  
  write.table(x=FTLFinalMatrix[2:nrow(FTLFinalMatrix),],
              file=First_unshared_subbackfreq,
              quote=FALSE, sep=",",
              row.names=FALSE,col.names = FALSE, na="", append=TRUE)
  
  ############################################################################################################
  
  D835Youtputmatrix<-matrix(data=c(D835YmotifsFINAL,names(D835YmotifsFINAL)),ncol = 2)

  FLTreference<-D835Youtputmatrix[,2]
  
  FirstLine<-colnames(FirstSubstrateSet)
  FirstLine<-FirstLine[1:23]
  for (q in 1:nrow(D835Youtputmatrix)) {
    thismotif<-unlist(strsplit(D835Youtputmatrix[q,1],""))
    thisoutput<-c("","",D835Youtputmatrix[q,2],thismotif,"","","","","")
    FirstLine<-rbind(FirstLine,thisoutput)
  }
  
  
    
  write.table(x=FirstLine,
              file=Second_unshared_motifs_table,
              quote=FALSE, sep=",",
              row.names=FALSE,col.names = FALSE, na="", append=TRUE)
  
  columnalheader<-c(as.character(Thirdsubbackfreq[1:36,1]))
  columnalheader<-matrix(columnalheader,nrow = 1)
  
  # columnalheader<-rbind(columnalheader,D835YFinalMatrix)
  
  write.table(x=columnalheader,
              file=Second_unshared_subbackfreq,
              quote=FALSE, sep=",",
              row.names=FALSE,col.names = FALSE, na="", append=TRUE)
  
  write.table(x=D835YFinalMatrix[2:nrow(D835YFinalMatrix),],
              file=Second_unshared_subbackfreq,
              quote=FALSE, sep=",",
              row.names=FALSE,col.names = FALSE, na="", append=TRUE)
  
  ############################################################################################################
  
  ITDoutputmatrix<-matrix(data = c(ITDmotifsFINAL,names(ITDmotifsFINAL)),ncol = 2)
  
  FLTreference<-ITDoutputmatrix[,2]
  
  FirstLine<-colnames(FirstSubstrateSet)
  FirstLine<-FirstLine[1:23]
  for (q in 1:nrow(ITDoutputmatrix)) {
    thismotif<-unlist(strsplit(ITDoutputmatrix[q,1],""))
    thisoutput<-c("","",ITDoutputmatrix[q,2],thismotif,"","","","","")
    FirstLine<-rbind(FirstLine,thisoutput)
  }
  
  
  write.table(x=FirstLine,
              file=Third_unshared_motifs_table,
              quote=FALSE, sep=",",
              row.names=FALSE,col.names = FALSE, na="", append=TRUE)
  
  columnalheader<-c(as.character(Thirdsubbackfreq[1:36,1]))
  columnalheader<-matrix(columnalheader,nrow = 1)
  
  # columnalheader<-rbind(columnalheader,ITDFinalMatrix)

  write.table(x=columnalheader,
              file=Third_unshared_subbackfreq,
              quote=FALSE, sep=",",
              row.names=FALSE,col.names = FALSE, na="", append=TRUE)
  
  write.table(x=ITDFinalMatrix[2:nrow(ITDFinalMatrix),],
              file=Third_unshared_subbackfreq,
              quote=FALSE, sep=",",
              row.names=FALSE,col.names = FALSE, na="", append=TRUE)
  
}
