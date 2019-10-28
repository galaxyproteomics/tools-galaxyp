# system.time({

options(warn=-1)

args = commandArgs(trailingOnly=TRUE)
#args = c("ABL","ABC","ABC","ABC","ABC","ABC","ABC","ABC","ABC","ABC","ABC","ABC","ABC","ABC")
TodaysKinase<-as.character(args[1])

CharTable<-read.csv("Fisher-Char.csv", header = FALSE,stringsAsFactors = FALSE)
ThisKinSheet<-read.csv("Fisher-Table.csv", header=FALSE, stringsAsFactors=FALSE)
NormalizationScore<-CharTable[2,1]

#so here's the question, do I want this file to be able to score using any EPM table as well? I guess I have to.




M6<-as.character(args[2])
M5<-as.character(args[3])
M4<-as.character(args[4])
M3<-as.character(args[5])
M2<-as.character(args[6])
M1<-as.character(args[7])
D0<-as.character(args[8])
P1<-as.character(args[9])
P2<-as.character(args[10])
P3<-as.character(args[11])
P4<-as.character(args[12])
P5<-as.character(args[13])
P6<-as.character(args[14])


A=1
C=2
D=3
E=4
F=5
G=6
H=7
I=8
K=9
L=10
M=11
N=12
P=13
Q=14
R=15
S=16
T=17
V=18
W=19
Y=20
aa_props <- c("A"=A, "C"=C, "D"=D, "E"=E, "F"=F,"G"=G,"H"=H,"I"=I,"K"=K,"L"=L,"M"=M,"N"=N,"P"=P,"Q"=Q,"R"=R,
              "S"=S,"T"=T,"V"=V,"W"=W,"Y"=Y,"xY"=Y,"O"=21)
Positionm6<-gsub("[^a-zA-Z]", "", M6)
Positionm6<-toupper(Positionm6)
Positionm6<-unlist(strsplit(Positionm6,""))
Positionm6<-sapply(Positionm6, function(x) aa_props[x])

Positionm5<-gsub("[^a-zA-Z]", "", M5)
Positionm5<-toupper(Positionm5)
Positionm5<-unlist(strsplit(Positionm5,""))
Positionm5<-sapply(Positionm5, function(x) aa_props[x])

Positionm4<-gsub("[^a-zA-Z]", "", M4)
Positionm4<-toupper(Positionm4)
Positionm4<-unlist(strsplit(Positionm4,""))
Positionm4<-sapply(Positionm4, function(x) aa_props[x])

Positionm3<-gsub("[^a-zA-Z]", "", M3)
Positionm3<-toupper(Positionm3)
Positionm3<-unlist(strsplit(Positionm3,""))
Positionm3<-sapply(Positionm3, function(x) aa_props[x])

Positionm2<-gsub("[^a-zA-Z]", "", M2)
Positionm2<-toupper(Positionm2)
Positionm2<-unlist(strsplit(Positionm2,""))
Positionm2<-sapply(Positionm2, function(x) aa_props[x])

Positionm1<-gsub("[^a-zA-Z]", "", M1)
Positionm1<-toupper(Positionm1)
Positionm1<-unlist(strsplit(Positionm1,""))
Positionm1<-sapply(Positionm1, function(x) aa_props[x])

Positiond0<-gsub("[^a-zA-Z]", "", D0)
Positiond0<-toupper(Positiond0)
Positiond0<-unlist(strsplit(Positiond0,""))
Positiond0<-sapply(Positiond0, function(x) aa_props[x])

Positionp1<-gsub("[^a-zA-Z]", "", P1)
Positionp1<-toupper(Positionp1)
Positionp1<-unlist(strsplit(Positionp1,""))
Positionp1<-sapply(Positionp1, function(x) aa_props[x])

Positionp2<-gsub("[^a-zA-Z]", "", P2)
Positionp2<-toupper(Positionp2)
Positionp2<-unlist(strsplit(Positionp2,""))
Positionp2<-sapply(Positionp2, function(x) aa_props[x])

Positionp3<-gsub("[^a-zA-Z]", "", P3)
Positionp3<-toupper(Positionp3)
Positionp3<-unlist(strsplit(Positionp3,""))
Positionp3<-sapply(Positionp3, function(x) aa_props[x])

Positionp4<-gsub("[^a-zA-Z]", "", P4)
Positionp4<-toupper(Positionp4)
Positionp4<-unlist(strsplit(Positionp4,""))
Positionp4<-sapply(Positionp4, function(x) aa_props[x])

Positionp5<-gsub("[^a-zA-Z]", "", P5)
Positionp5<-toupper(Positionp5)
Positionp5<-unlist(strsplit(Positionp5,""))
Positionp5<-sapply(Positionp5, function(x) aa_props[x])

Positionp6<-gsub("[^a-zA-Z]", "", P6)
Positionp6<-toupper(Positionp6)
Positionp6<-unlist(strsplit(Positionp6,""))
Positionp6<-sapply(Positionp6, function(x) aa_props[x])




#what the below code does is stupid.  I need to make a combinatorial library of peptides and then calculate their values
#but each peptide needs a value calculated for every different kinase.  So I first make it so that every AA at every position is labelled differently
#IE an A at position negative 6 is called m6a (minus 6 Alanine)
#then further on I replace valued like m6a with whatever value is found in the EPM table for both this kinase and every other kinase
#then I will multiply those values together

if(2==2){
aa_props2 <- c("1"="A", "2"="C", "3"="D", "4"="E", "5"="F", "6"="G", "7"="H", "8"="I", "9"="K", "10"="L", "11"="M", "12"="N",
               "13"="P", "14"="Q", "15"="R", "16"="S", "17"="T", "18"="V", "19"="W", "20"="Y", "21"="O")

m6_props2 <- c("1"="m6A", "2"="m6C", "3"="m6D", "4"="m6E", "5"="m6F", "6"="m6G", "7"="m6H", "8"="m6I", "9"="m6K", "10"="m6L", "11"="m6M", "12"="m6N",
               "13"="m6P", "14"="m6Q", "15"="m6R", "16"="m6S", "17"="m6T", "18"="m6V", "19"="m6W", "20"="m6Y", "21"="m6O")

m5_props2 <- c("1"="m5A", "2"="m5C", "3"="m5D", "4"="m5E", "5"="m5F", "6"="m5G", "7"="m5H", "8"="m5I", "9"="m5K", "10"="m5L", "11"="m5M", "12"="m5N",
               "13"="m5P", "14"="m5Q", "15"="m5R", "16"="m5S", "17"="m5T", "18"="m5V", "19"="m5W", "20"="m5Y", "21"="m5O")

m4_props2 <- c("1"="m4A", "2"="m4C", "3"="m4D", "4"="m4E", "5"="m4F", "6"="m4G", "7"="m4H", "8"="m4I", "9"="m4K", "10"="m4L", "11"="m4M", "12"="m4N",
               "13"="m4P", "14"="m4Q", "15"="m4R", "16"="m4S", "17"="m4T", "18"="m4V", "19"="m4W", "20"="m4Y", "21"="m4O")

m3_props2 <- c("1"="m3A", "2"="m3C", "3"="m3D", "4"="m3E", "5"="m3F", "6"="m3G", "7"="m3H", "8"="m3I", "9"="m3K", "10"="m3L", "11"="m3M", "12"="m3N",
               "13"="m3P", "14"="m3Q", "15"="m3R", "16"="m3S", "17"="m3T", "18"="m3V", "19"="m3W", "20"="m3Y", "21"="m3O")

m2_props2 <- c("1"="m2A", "2"="m2C", "3"="m2D", "4"="m2E", "5"="m2F", "6"="m2G", "7"="m2H", "8"="m2I", "9"="m2K", "10"="m2L", "11"="m2M", "12"="m2N",
               "13"="m2P", "14"="m2Q", "15"="m2R", "16"="m2S", "17"="m2T", "18"="m2V", "19"="m2W", "20"="m2Y", "21"="m2O")

m1_props2 <- c("1"="m1A", "2"="m1C", "3"="m1D", "4"="m1E", "5"="m1F", "6"="m1G", "7"="m1H", "8"="m1I", "9"="m1K", "10"="m1L", "11"="m1M", "12"="m1N",
               "13"="m1P", "14"="m1Q", "15"="m1R", "16"="m1S", "17"="m1T", "18"="m1V", "19"="m1W", "20"="m1Y", "21"="m1O")

d0_props2 <- c("1"="d0A", "2"="d0C", "3"="d0D", "4"="d0E", "5"="d0F", "6"="d0G", "7"="d0H", "8"="d0I", "9"="d0K", "10"="d0L", "11"="d0M", "12"="d0N",
               "13"="d0P", "14"="d0Q", "15"="d0R", "16"="d0S", "17"="d0T", "18"="d0V", "19"="d0W", "20"="d0Y", "21"="d0O")

p1_props2 <- c("1"="p1A", "2"="p1C", "3"="p1D", "4"="p1E", "5"="p1F", "6"="p1G", "7"="p1H", "8"="p1I", "9"="p1K", "10"="p1L", "11"="p1M", "12"="p1N",
               "13"="p1P", "14"="p1Q", "15"="p1R", "16"="p1S", "17"="p1T", "18"="p1V", "19"="p1W", "20"="p1Y", "21"="p1O")

p2_props2 <- c("1"="p2A", "2"="p2C", "3"="p2D", "4"="p2E", "5"="p2F", "6"="p2G", "7"="p2H", "8"="p2I", "9"="p2K", "10"="p2L", "11"="p2M", "12"="p2N",
               "13"="p2P", "14"="p2Q", "15"="p2R", "16"="p2S", "17"="p2T", "18"="p2V", "19"="p2W", "20"="p2Y", "21"="p2O")

p3_props2 <- c("1"="p3A", "2"="p3C", "3"="p3D", "4"="p3E", "5"="p3F", "6"="p3G", "7"="p3H", "8"="p3I", "9"="p3K", "10"="p3L", "11"="p3M", "12"="p3N",
               "13"="p3P", "14"="p3Q", "15"="p3R", "16"="p3S", "17"="p3T", "18"="p3V", "19"="p3W", "20"="p3Y", "21"="p3O")

p4_props2 <- c("1"="p4A", "2"="p4C", "3"="p4D", "4"="p4E", "5"="p4F", "6"="p4G", "7"="p4H", "8"="p4I", "9"="p4K", "10"="p4L", "11"="p4M", "12"="p4N",
               "13"="p4P", "14"="p4Q", "15"="p4R", "16"="p4S", "17"="p4T", "18"="p4V", "19"="p4W", "20"="p4Y", "21"="p4O")

p5_props2 <- c("1"="p5A", "2"="p5C", "3"="p5D", "4"="p5E", "5"="p5F", "6"="p5G", "7"="p5H", "8"="p5I", "9"="p5K", "10"="p5L", "11"="p5M", "12"="p5N",
               "13"="p5P", "14"="p5Q", "15"="p5R", "16"="p5S", "17"="p5T", "18"="p5V", "19"="p5W", "20"="p5Y", "21"="p5O")

p6_props2 <- c("1"="p6A", "2"="p6C", "3"="p6D", "4"="p6E", "5"="p6F", "6"="p6G", "7"="p6H", "8"="p6I", "9"="p6K", "10"="p6L", "11"="p6M", "12"="p6N",
               "13"="p6P", "14"="p6Q", "15"="p6R", "16"="p6S", "17"="p6T", "18"="p6V", "19"="p6W", "20"="p6Y", "21"="p6O")

# Positionm7<-sapply(Positionm7, function (x) aa_props2[x])
pPositionm6<-sapply(Positionm6, function (x) m6_props2[x])
pPositionm5<-sapply(Positionm5, function (x) m5_props2[x])
pPositionm4<-sapply(Positionm4, function (x) m4_props2[x])
pPositionm3<-sapply(Positionm3, function (x) m3_props2[x])
pPositionm2<-sapply(Positionm2, function (x) m2_props2[x])
pPositionm1<-sapply(Positionm1, function (x) m1_props2[x])
pPositiond0<-sapply(Positiond0, function (x) d0_props2[x])
pPositionp1<-sapply(Positionp1, function (x) p1_props2[x])
pPositionp2<-sapply(Positionp2, function (x) p2_props2[x])
pPositionp3<-sapply(Positionp3, function (x) p3_props2[x])
pPositionp4<-sapply(Positionp4, function (x) p4_props2[x])
pPositionp5<-sapply(Positionp5, function (x) p5_props2[x])
pPositionp6<-sapply(Positionp6, function (x) p6_props2[x])
# Positionp7<-sapply(Positionp7, function (x) aa_props2[x])

Positionm6<-sapply(Positionm6, function (x) aa_props2[x])
Positionm5<-sapply(Positionm5, function (x) aa_props2[x])
Positionm4<-sapply(Positionm4, function (x) aa_props2[x])
Positionm3<-sapply(Positionm3, function (x) aa_props2[x])
Positionm2<-sapply(Positionm2, function (x) aa_props2[x])
Positionm1<-sapply(Positionm1, function (x) aa_props2[x])
Positiond0<-sapply(Positiond0, function (x) aa_props2[x])
Positionp1<-sapply(Positionp1, function (x) aa_props2[x])
Positionp2<-sapply(Positionp2, function (x) aa_props2[x])
Positionp3<-sapply(Positionp3, function (x) aa_props2[x])
Positionp4<-sapply(Positionp4, function (x) aa_props2[x])
Positionp5<-sapply(Positionp5, function (x) aa_props2[x])
Positionp6<-sapply(Positionp6, function (x) aa_props2[x])


}
#this turns the amino acids from above into positionally appropriate amino acids, that is an A at negative 6 is called m6A, if it's at -5 it's m5A, 
#if it's a B at positive 4 it's p4B



ScreenerFilename<-"screener.csv"
screaner<-read.csv(ScreenerFilename, header = FALSE, stringsAsFactors = FALSE)
#screaner <- read.csv("F:/ParkerLab Dropbox/Dropbox (Parker Lab)/Parker Lab Shared Files/Dropbox (Parker Lab)/Parker Lab Shared Files/CURRENT LAB MEMBERS/John B/Parker Lab/GalaxyP tools/scoring function KTID/screener.csv", header=FALSE, stringsAsFactors=FALSE)

Abl<-screaner[2:25,]
Arg<-screaner[27:50,]
Btk<-screaner[52:75,]
Csk<-screaner[77:100,]
Fyn<-screaner[102:125,]
Hck<-screaner[127:150,]
JAK2<-screaner[152:175,]
Lck<-screaner[177:200,]
Lyn<-screaner[202:225,]
Pyk2<-screaner[227:250,]
Src<-screaner[252:275,]
Syk<-screaner[277:300,]
Yes<-screaner[302:325,]
FLT3<-screaner[327:350,]
ALK<-screaner[352:375,]



ThisKinTable<-ThisKinSheet[2:22,]
#NormalizationScore<-ThisKinSheet[27,1]

if(1==1){
  ThisKinTable_props <- c("m6A"=ThisKinTable[1,3], "m6C"=ThisKinTable[2,3], "m6D"=ThisKinTable[3,3], "m6E"=ThisKinTable[4,3], "m6F"=ThisKinTable[5,3],"m6G"=ThisKinTable[6,3],"m6H"=ThisKinTable[7,3],"m6I"=ThisKinTable[8,3],"m6K"=ThisKinTable[9,3],"m6L"=ThisKinTable[10,3],"m6M"=ThisKinTable[11,3],"m6N"=ThisKinTable[12,3],"m6P"=ThisKinTable[13,3],"m6Q"=ThisKinTable[14,3],"m6R"=ThisKinTable[15,3],
                          "m6S"=ThisKinTable[16,3],"m6T"=ThisKinTable[17,3],"m6V"=ThisKinTable[18,3],"m6W"=ThisKinTable[19,3],"m6Y"=ThisKinTable[20,3],"m6O"=1,
                          "m5A"=ThisKinTable[1,4], "m5C"=ThisKinTable[2,4], "m5D"=ThisKinTable[3,4], "m5E"=ThisKinTable[4,4], "m5F"=ThisKinTable[5,4],"m5G"=ThisKinTable[6,4],"m5H"=ThisKinTable[7,4],"m5I"=ThisKinTable[8,4],"m5K"=ThisKinTable[9,4],"m5L"=ThisKinTable[10,4],"m5M"=ThisKinTable[11,4],"m5N"=ThisKinTable[12,4],"m5P"=ThisKinTable[13,4],"m5Q"=ThisKinTable[14,4],"m5R"=ThisKinTable[15,4],
                          "m5S"=ThisKinTable[16,4],"m5T"=ThisKinTable[17,4],"m5V"=ThisKinTable[18,4],"m5W"=ThisKinTable[19,4],"m5Y"=ThisKinTable[20,4],"m5O"=1,
                          "m4A"=ThisKinTable[1,5], "m4C"=ThisKinTable[2,5], "m4D"=ThisKinTable[3,5], "m4E"=ThisKinTable[4,5], "m4F"=ThisKinTable[5,5],"m4G"=ThisKinTable[6,5],"m4H"=ThisKinTable[7,5],"m4I"=ThisKinTable[8,5],"m4K"=ThisKinTable[9,5],"m4L"=ThisKinTable[10,5],"m4M"=ThisKinTable[11,5],"m4N"=ThisKinTable[12,5],"m4P"=ThisKinTable[13,5],"m4Q"=ThisKinTable[14,5],"m4R"=ThisKinTable[15,5],
                          "m4S"=ThisKinTable[16,5],"m4T"=ThisKinTable[17,5],"m4V"=ThisKinTable[18,5],"m4W"=ThisKinTable[19,5],"m4Y"=ThisKinTable[20,5],"m4O"=1,
                          "m3A"=ThisKinTable[1,6], "m3C"=ThisKinTable[2,6], "m3D"=ThisKinTable[3,6], "m3E"=ThisKinTable[4,6], "m3F"=ThisKinTable[5,6],"m3G"=ThisKinTable[6,6],"m3H"=ThisKinTable[7,6],"m3I"=ThisKinTable[8,6],"m3K"=ThisKinTable[9,6],"m3L"=ThisKinTable[10,6],"m3M"=ThisKinTable[11,6],"m3N"=ThisKinTable[12,6],"m3P"=ThisKinTable[13,6],"m3Q"=ThisKinTable[14,6],"m3R"=ThisKinTable[15,6],
                          "m3S"=ThisKinTable[16,6],"m3T"=ThisKinTable[17,6],"m3V"=ThisKinTable[18,6],"m3W"=ThisKinTable[19,6],"m3Y"=ThisKinTable[20,6],"m3O"=1,
                          "m2A"=ThisKinTable[1,7], "m2C"=ThisKinTable[2,7], "m2D"=ThisKinTable[3,7], "m2E"=ThisKinTable[4,7], "m2F"=ThisKinTable[5,7],"m2G"=ThisKinTable[6,7],"m2H"=ThisKinTable[7,7],"m2I"=ThisKinTable[8,7],"m2K"=ThisKinTable[9,7],"m2L"=ThisKinTable[10,7],"m2M"=ThisKinTable[11,7],"m2N"=ThisKinTable[12,7],"m2P"=ThisKinTable[13,7],"m2Q"=ThisKinTable[14,7],"m2R"=ThisKinTable[15,7],
                          "m2S"=ThisKinTable[16,7],"m2T"=ThisKinTable[17,7],"m2V"=ThisKinTable[18,7],"m2W"=ThisKinTable[19,7],"m2Y"=ThisKinTable[20,7],"m2O"=1,
                          "m1A"=ThisKinTable[1,8], "m1C"=ThisKinTable[2,8], "m1D"=ThisKinTable[3,8], "m1E"=ThisKinTable[4,8], "m1F"=ThisKinTable[5,8],"m1G"=ThisKinTable[6,8],"m1H"=ThisKinTable[7,8],"m1I"=ThisKinTable[8,8],"m1K"=ThisKinTable[9,8],"m1L"=ThisKinTable[10,8],"m1M"=ThisKinTable[11,8],"m1N"=ThisKinTable[12,8],"m1P"=ThisKinTable[13,8],"m1Q"=ThisKinTable[14,8],"m1R"=ThisKinTable[15,8],
                          "m1S"=ThisKinTable[16,8],"m1T"=ThisKinTable[17,8],"m1V"=ThisKinTable[18,8],"m1W"=ThisKinTable[19,8],"m1Y"=ThisKinTable[20,8],"m1O"=1,
                          "d0A"=ThisKinTable[1,9], "d0C"=ThisKinTable[2,9], "d0D"=ThisKinTable[3,9], "d0E"=ThisKinTable[4,9], "d0F"=ThisKinTable[5,9],"d0G"=ThisKinTable[6,9],"d0H"=ThisKinTable[7,9],"d0I"=ThisKinTable[8,9],"d0K"=ThisKinTable[9,9],"d0L"=ThisKinTable[10,9],"d0M"=ThisKinTable[11,9],"d0N"=ThisKinTable[12,9],"d0P"=ThisKinTable[13,9],"d0Q"=ThisKinTable[14,9],"d0R"=ThisKinTable[15,9],
                          "d0S"=ThisKinTable[16,9],"d0T"=ThisKinTable[17,9],"d0V"=ThisKinTable[18,9],"d0W"=ThisKinTable[19,9],"d0Y"=ThisKinTable[20,9],"d0O"=1,
                          "p1A"=ThisKinTable[1,10], "p1C"=ThisKinTable[2,10], "p1D"=ThisKinTable[3,10], "p1E"=ThisKinTable[4,10], "p1F"=ThisKinTable[5,10],"p1G"=ThisKinTable[6,10],"p1H"=ThisKinTable[7,10],"p1I"=ThisKinTable[8,10],"p1K"=ThisKinTable[9,10],"p1L"=ThisKinTable[10,10],"p1M"=ThisKinTable[11,10],"p1N"=ThisKinTable[12,10],"p1P"=ThisKinTable[13,10],"p1Q"=ThisKinTable[14,10],"p1R"=ThisKinTable[15,10],
                          "p1S"=ThisKinTable[16,10],"p1T"=ThisKinTable[17,10],"p1V"=ThisKinTable[18,10],"p1W"=ThisKinTable[19,10],"p1Y"=ThisKinTable[20,10],"p1O"=1,
                          "p2A"=ThisKinTable[1,11], "p2C"=ThisKinTable[2,11], "p2D"=ThisKinTable[3,11], "p2E"=ThisKinTable[4,11], "p2F"=ThisKinTable[5,11],"p2G"=ThisKinTable[6,11],"p2H"=ThisKinTable[7,11],"p2I"=ThisKinTable[8,11],"p2K"=ThisKinTable[9,11],"p2L"=ThisKinTable[10,11],"p2M"=ThisKinTable[11,11],"p2N"=ThisKinTable[12,11],"p2P"=ThisKinTable[13,11],"p2Q"=ThisKinTable[14,11],"p2R"=ThisKinTable[15,11],
                          "p2S"=ThisKinTable[16,11],"p2T"=ThisKinTable[17,11],"p2V"=ThisKinTable[18,11],"p2W"=ThisKinTable[19,11],"p2Y"=ThisKinTable[20,11],"p2O"=1,
                          "p3A"=ThisKinTable[1,12], "p3C"=ThisKinTable[2,12], "p3D"=ThisKinTable[3,12], "p3E"=ThisKinTable[4,12], "p3F"=ThisKinTable[5,12],"p3G"=ThisKinTable[6,12],"p3H"=ThisKinTable[7,12],"p3I"=ThisKinTable[8,12],"p3K"=ThisKinTable[9,12],"p3L"=ThisKinTable[10,12],"p3M"=ThisKinTable[11,12],"p3N"=ThisKinTable[12,12],"p3P"=ThisKinTable[13,12],"p3Q"=ThisKinTable[14,12],"p3R"=ThisKinTable[15,12],
                          "p3S"=ThisKinTable[16,12],"p3T"=ThisKinTable[17,12],"p3V"=ThisKinTable[18,12],"p3W"=ThisKinTable[19,12],"p3Y"=ThisKinTable[20,12],"p3O"=1,
                          "p4A"=ThisKinTable[1,13], "p4C"=ThisKinTable[2,13], "p4D"=ThisKinTable[3,13], "p4E"=ThisKinTable[4,13], "p4F"=ThisKinTable[5,13],"p4G"=ThisKinTable[6,13],"p4H"=ThisKinTable[7,13],"p4I"=ThisKinTable[8,13],"p4K"=ThisKinTable[9,13],"p4L"=ThisKinTable[10,13],"p4M"=ThisKinTable[11,13],"p4N"=ThisKinTable[12,13],"p4P"=ThisKinTable[13,13],"p4Q"=ThisKinTable[14,13],"p4R"=ThisKinTable[15,13],
                          "p4S"=ThisKinTable[16,13],"p4T"=ThisKinTable[17,13],"p4V"=ThisKinTable[18,13],"p4W"=ThisKinTable[19,13],"p4Y"=ThisKinTable[20,13],"p4O"=1,
                          "p5A"=ThisKinTable[1,14], "p5C"=ThisKinTable[2,14], "p5D"=ThisKinTable[3,14], "p5E"=ThisKinTable[4,14], "p5F"=ThisKinTable[5,14],"p5G"=ThisKinTable[6,14],"p5H"=ThisKinTable[7,14],"p5I"=ThisKinTable[8,14],"p5K"=ThisKinTable[9,14],"p5L"=ThisKinTable[10,14],"p5M"=ThisKinTable[11,14],"p5N"=ThisKinTable[12,14],"p5P"=ThisKinTable[13,14],"p5Q"=ThisKinTable[14,14],"p5R"=ThisKinTable[15,14],
                          "p5S"=ThisKinTable[16,14],"p5T"=ThisKinTable[17,14],"p5V"=ThisKinTable[18,14],"p5W"=ThisKinTable[19,14],"p5Y"=ThisKinTable[20,14],"p5O"=1,
                          "p6A"=ThisKinTable[1,15], "p6C"=ThisKinTable[2,15], "p6D"=ThisKinTable[3,15], "p6E"=ThisKinTable[4,15], "p6F"=ThisKinTable[5,15],"p6G"=ThisKinTable[6,15],"p6H"=ThisKinTable[7,15],"p6I"=ThisKinTable[8,15],"p6K"=ThisKinTable[9,15],"p6L"=ThisKinTable[10,15],"p6M"=ThisKinTable[11,15],"p6N"=ThisKinTable[12,15],"p6P"=ThisKinTable[13,15],"p6Q"=ThisKinTable[14,15],"p6R"=ThisKinTable[15,15],
                          "p6S"=ThisKinTable[16,15],"p6T"=ThisKinTable[17,15],"p6V"=ThisKinTable[18,15],"p6W"=ThisKinTable[19,15],"p6Y"=ThisKinTable[20,15],"p6O"=1)
  
  
  Abl_props <- c("m6A"=Abl[1,3], "m6C"=Abl[2,3], "m6D"=Abl[3,3], "m6E"=Abl[4,3], "m6F"=Abl[5,3],"m6G"=Abl[6,3],"m6H"=Abl[7,3],"m6I"=Abl[8,3],"m6K"=Abl[9,3],"m6L"=Abl[10,3],"m6M"=Abl[11,3],"m6N"=Abl[12,3],"m6P"=Abl[13,3],"m6Q"=Abl[14,3],"m6R"=Abl[15,3],
                 "m6S"=Abl[16,3],"m6T"=Abl[17,3],"m6V"=Abl[18,3],"m6W"=Abl[19,3],"m6Y"=Abl[20,3],"m6O"=1,
                 "m5A"=Abl[1,4], "m5C"=Abl[2,4], "m5D"=Abl[3,4], "m5E"=Abl[4,4], "m5F"=Abl[5,4],"m5G"=Abl[6,4],"m5H"=Abl[7,4],"m5I"=Abl[8,4],"m5K"=Abl[9,4],"m5L"=Abl[10,4],"m5M"=Abl[11,4],"m5N"=Abl[12,4],"m5P"=Abl[13,4],"m5Q"=Abl[14,4],"m5R"=Abl[15,4],
                 "m5S"=Abl[16,4],"m5T"=Abl[17,4],"m5V"=Abl[18,4],"m5W"=Abl[19,4],"m5Y"=Abl[20,4],"m5O"=1,
                 "m4A"=Abl[1,5], "m4C"=Abl[2,5], "m4D"=Abl[3,5], "m4E"=Abl[4,5], "m4F"=Abl[5,5],"m4G"=Abl[6,5],"m4H"=Abl[7,5],"m4I"=Abl[8,5],"m4K"=Abl[9,5],"m4L"=Abl[10,5],"m4M"=Abl[11,5],"m4N"=Abl[12,5],"m4P"=Abl[13,5],"m4Q"=Abl[14,5],"m4R"=Abl[15,5],
                 "m4S"=Abl[16,5],"m4T"=Abl[17,5],"m4V"=Abl[18,5],"m4W"=Abl[19,5],"m4Y"=Abl[20,5],"m4O"=1,
                 "m3A"=Abl[1,6], "m3C"=Abl[2,6], "m3D"=Abl[3,6], "m3E"=Abl[4,6], "m3F"=Abl[5,6],"m3G"=Abl[6,6],"m3H"=Abl[7,6],"m3I"=Abl[8,6],"m3K"=Abl[9,6],"m3L"=Abl[10,6],"m3M"=Abl[11,6],"m3N"=Abl[12,6],"m3P"=Abl[13,6],"m3Q"=Abl[14,6],"m3R"=Abl[15,6],
                 "m3S"=Abl[16,6],"m3T"=Abl[17,6],"m3V"=Abl[18,6],"m3W"=Abl[19,6],"m3Y"=Abl[20,6],"m3O"=1,
                 "m2A"=Abl[1,7], "m2C"=Abl[2,7], "m2D"=Abl[3,7], "m2E"=Abl[4,7], "m2F"=Abl[5,7],"m2G"=Abl[6,7],"m2H"=Abl[7,7],"m2I"=Abl[8,7],"m2K"=Abl[9,7],"m2L"=Abl[10,7],"m2M"=Abl[11,7],"m2N"=Abl[12,7],"m2P"=Abl[13,7],"m2Q"=Abl[14,7],"m2R"=Abl[15,7],
                 "m2S"=Abl[16,7],"m2T"=Abl[17,7],"m2V"=Abl[18,7],"m2W"=Abl[19,7],"m2Y"=Abl[20,7],"m2O"=1,
                 "m1A"=Abl[1,8], "m1C"=Abl[2,8], "m1D"=Abl[3,8], "m1E"=Abl[4,8], "m1F"=Abl[5,8],"m1G"=Abl[6,8],"m1H"=Abl[7,8],"m1I"=Abl[8,8],"m1K"=Abl[9,8],"m1L"=Abl[10,8],"m1M"=Abl[11,8],"m1N"=Abl[12,8],"m1P"=Abl[13,8],"m1Q"=Abl[14,8],"m1R"=Abl[15,8],
                 "m1S"=Abl[16,8],"m1T"=Abl[17,8],"m1V"=Abl[18,8],"m1W"=Abl[19,8],"m1Y"=Abl[20,8],"m1O"=1,
                 "d0A"=Abl[1,9], "d0C"=Abl[2,9], "d0D"=Abl[3,9], "d0E"=Abl[4,9], "d0F"=Abl[5,9],"d0G"=Abl[6,9],"d0H"=Abl[7,9],"d0I"=Abl[8,9],"d0K"=Abl[9,9],"d0L"=Abl[10,9],"d0M"=Abl[11,9],"d0N"=Abl[12,9],"d0P"=Abl[13,9],"d0Q"=Abl[14,9],"d0R"=Abl[15,9],
                 "d0S"=Abl[16,9],"d0T"=Abl[17,9],"d0V"=Abl[18,9],"d0W"=Abl[19,9],"d0Y"=Abl[20,9],"d0O"=1,
                 "p1A"=Abl[1,10], "p1C"=Abl[2,10], "p1D"=Abl[3,10], "p1E"=Abl[4,10], "p1F"=Abl[5,10],"p1G"=Abl[6,10],"p1H"=Abl[7,10],"p1I"=Abl[8,10],"p1K"=Abl[9,10],"p1L"=Abl[10,10],"p1M"=Abl[11,10],"p1N"=Abl[12,10],"p1P"=Abl[13,10],"p1Q"=Abl[14,10],"p1R"=Abl[15,10],
                 "p1S"=Abl[16,10],"p1T"=Abl[17,10],"p1V"=Abl[18,10],"p1W"=Abl[19,10],"p1Y"=Abl[20,10],"p1O"=1,
                 "p2A"=Abl[1,11], "p2C"=Abl[2,11], "p2D"=Abl[3,11], "p2E"=Abl[4,11], "p2F"=Abl[5,11],"p2G"=Abl[6,11],"p2H"=Abl[7,11],"p2I"=Abl[8,11],"p2K"=Abl[9,11],"p2L"=Abl[10,11],"p2M"=Abl[11,11],"p2N"=Abl[12,11],"p2P"=Abl[13,11],"p2Q"=Abl[14,11],"p2R"=Abl[15,11],
                 "p2S"=Abl[16,11],"p2T"=Abl[17,11],"p2V"=Abl[18,11],"p2W"=Abl[19,11],"p2Y"=Abl[20,11],"p2O"=1,
                 "p3A"=Abl[1,12], "p3C"=Abl[2,12], "p3D"=Abl[3,12], "p3E"=Abl[4,12], "p3F"=Abl[5,12],"p3G"=Abl[6,12],"p3H"=Abl[7,12],"p3I"=Abl[8,12],"p3K"=Abl[9,12],"p3L"=Abl[10,12],"p3M"=Abl[11,12],"p3N"=Abl[12,12],"p3P"=Abl[13,12],"p3Q"=Abl[14,12],"p3R"=Abl[15,12],
                 "p3S"=Abl[16,12],"p3T"=Abl[17,12],"p3V"=Abl[18,12],"p3W"=Abl[19,12],"p3Y"=Abl[20,12],"p3O"=1,
                 "p4A"=Abl[1,13], "p4C"=Abl[2,13], "p4D"=Abl[3,13], "p4E"=Abl[4,13], "p4F"=Abl[5,13],"p4G"=Abl[6,13],"p4H"=Abl[7,13],"p4I"=Abl[8,13],"p4K"=Abl[9,13],"p4L"=Abl[10,13],"p4M"=Abl[11,13],"p4N"=Abl[12,13],"p4P"=Abl[13,13],"p4Q"=Abl[14,13],"p4R"=Abl[15,13],
                 "p4S"=Abl[16,13],"p4T"=Abl[17,13],"p4V"=Abl[18,13],"p4W"=Abl[19,13],"p4Y"=Abl[20,13],"p4O"=1,
                 "p5A"=Abl[1,14], "p5C"=Abl[2,14], "p5D"=Abl[3,14], "p5E"=Abl[4,14], "p5F"=Abl[5,14],"p5G"=Abl[6,14],"p5H"=Abl[7,14],"p5I"=Abl[8,14],"p5K"=Abl[9,14],"p5L"=Abl[10,14],"p5M"=Abl[11,14],"p5N"=Abl[12,14],"p5P"=Abl[13,14],"p5Q"=Abl[14,14],"p5R"=Abl[15,14],
                 "p5S"=Abl[16,14],"p5T"=Abl[17,14],"p5V"=Abl[18,14],"p5W"=Abl[19,14],"p5Y"=Abl[20,14],"p5O"=1,
                 "p6A"=Abl[1,15], "p6C"=Abl[2,15], "p6D"=Abl[3,15], "p6E"=Abl[4,15], "p6F"=Abl[5,15],"p6G"=Abl[6,15],"p6H"=Abl[7,15],"p6I"=Abl[8,15],"p6K"=Abl[9,15],"p6L"=Abl[10,15],"p6M"=Abl[11,15],"p6N"=Abl[12,15],"p6P"=Abl[13,15],"p6Q"=Abl[14,15],"p6R"=Abl[15,15],
                 "p6S"=Abl[16,15],"p6T"=Abl[17,15],"p6V"=Abl[18,15],"p6W"=Abl[19,15],"p6Y"=Abl[20,15],"p6O"=1)
  
  Arg_props <- c("m6A"=Arg[1,3], "m6C"=Arg[2,3], "m6D"=Arg[3,3], "m6E"=Arg[4,3], "m6F"=Arg[5,3],"m6G"=Arg[6,3],"m6H"=Arg[7,3],"m6I"=Arg[8,3],"m6K"=Arg[9,3],"m6L"=Arg[10,3],"m6M"=Arg[11,3],"m6N"=Arg[12,3],"m6P"=Arg[13,3],"m6Q"=Arg[14,3],"m6R"=Arg[15,3],
                 "m6S"=Arg[16,3],"m6T"=Arg[17,3],"m6V"=Arg[18,3],"m6W"=Arg[19,3],"m6Y"=Arg[20,3],"m6O"=1,
                 "m5A"=Arg[1,4], "m5C"=Arg[2,4], "m5D"=Arg[3,4], "m5E"=Arg[4,4], "m5F"=Arg[5,4],"m5G"=Arg[6,4],"m5H"=Arg[7,4],"m5I"=Arg[8,4],"m5K"=Arg[9,4],"m5L"=Arg[10,4],"m5M"=Arg[11,4],"m5N"=Arg[12,4],"m5P"=Arg[13,4],"m5Q"=Arg[14,4],"m5R"=Arg[15,4],
                 "m5S"=Arg[16,4],"m5T"=Arg[17,4],"m5V"=Arg[18,4],"m5W"=Arg[19,4],"m5Y"=Arg[20,4],"m5O"=1,
                 "m4A"=Arg[1,5], "m4C"=Arg[2,5], "m4D"=Arg[3,5], "m4E"=Arg[4,5], "m4F"=Arg[5,5],"m4G"=Arg[6,5],"m4H"=Arg[7,5],"m4I"=Arg[8,5],"m4K"=Arg[9,5],"m4L"=Arg[10,5],"m4M"=Arg[11,5],"m4N"=Arg[12,5],"m4P"=Arg[13,5],"m4Q"=Arg[14,5],"m4R"=Arg[15,5],
                 "m4S"=Arg[16,5],"m4T"=Arg[17,5],"m4V"=Arg[18,5],"m4W"=Arg[19,5],"m4Y"=Arg[20,5],"m4O"=1,
                 "m3A"=Arg[1,6], "m3C"=Arg[2,6], "m3D"=Arg[3,6], "m3E"=Arg[4,6], "m3F"=Arg[5,6],"m3G"=Arg[6,6],"m3H"=Arg[7,6],"m3I"=Arg[8,6],"m3K"=Arg[9,6],"m3L"=Arg[10,6],"m3M"=Arg[11,6],"m3N"=Arg[12,6],"m3P"=Arg[13,6],"m3Q"=Arg[14,6],"m3R"=Arg[15,6],
                 "m3S"=Arg[16,6],"m3T"=Arg[17,6],"m3V"=Arg[18,6],"m3W"=Arg[19,6],"m3Y"=Arg[20,6],"m3O"=1,
                 "m2A"=Arg[1,7], "m2C"=Arg[2,7], "m2D"=Arg[3,7], "m2E"=Arg[4,7], "m2F"=Arg[5,7],"m2G"=Arg[6,7],"m2H"=Arg[7,7],"m2I"=Arg[8,7],"m2K"=Arg[9,7],"m2L"=Arg[10,7],"m2M"=Arg[11,7],"m2N"=Arg[12,7],"m2P"=Arg[13,7],"m2Q"=Arg[14,7],"m2R"=Arg[15,7],
                 "m2S"=Arg[16,7],"m2T"=Arg[17,7],"m2V"=Arg[18,7],"m2W"=Arg[19,7],"m2Y"=Arg[20,7],"m2O"=1,
                 "m1A"=Arg[1,8], "m1C"=Arg[2,8], "m1D"=Arg[3,8], "m1E"=Arg[4,8], "m1F"=Arg[5,8],"m1G"=Arg[6,8],"m1H"=Arg[7,8],"m1I"=Arg[8,8],"m1K"=Arg[9,8],"m1L"=Arg[10,8],"m1M"=Arg[11,8],"m1N"=Arg[12,8],"m1P"=Arg[13,8],"m1Q"=Arg[14,8],"m1R"=Arg[15,8],
                 "m1S"=Arg[16,8],"m1T"=Arg[17,8],"m1V"=Arg[18,8],"m1W"=Arg[19,8],"m1Y"=Arg[20,8],"m1O"=1,
                 "d0A"=Arg[1,9], "d0C"=Arg[2,9], "d0D"=Arg[3,9], "d0E"=Arg[4,9], "d0F"=Arg[5,9],"d0G"=Arg[6,9],"d0H"=Arg[7,9],"d0I"=Arg[8,9],"d0K"=Arg[9,9],"d0L"=Arg[10,9],"d0M"=Arg[11,9],"d0N"=Arg[12,9],"d0P"=Arg[13,9],"d0Q"=Arg[14,9],"d0R"=Arg[15,9],
                 "d0S"=Arg[16,9],"d0T"=Arg[17,9],"d0V"=Arg[18,9],"d0W"=Arg[19,9],"d0Y"=Arg[20,9],"d0O"=1,
                 "p1A"=Arg[1,10], "p1C"=Arg[2,10], "p1D"=Arg[3,10], "p1E"=Arg[4,10], "p1F"=Arg[5,10],"p1G"=Arg[6,10],"p1H"=Arg[7,10],"p1I"=Arg[8,10],"p1K"=Arg[9,10],"p1L"=Arg[10,10],"p1M"=Arg[11,10],"p1N"=Arg[12,10],"p1P"=Arg[13,10],"p1Q"=Arg[14,10],"p1R"=Arg[15,10],
                 "p1S"=Arg[16,10],"p1T"=Arg[17,10],"p1V"=Arg[18,10],"p1W"=Arg[19,10],"p1Y"=Arg[20,10],"p1O"=1,
                 "p2A"=Arg[1,11], "p2C"=Arg[2,11], "p2D"=Arg[3,11], "p2E"=Arg[4,11], "p2F"=Arg[5,11],"p2G"=Arg[6,11],"p2H"=Arg[7,11],"p2I"=Arg[8,11],"p2K"=Arg[9,11],"p2L"=Arg[10,11],"p2M"=Arg[11,11],"p2N"=Arg[12,11],"p2P"=Arg[13,11],"p2Q"=Arg[14,11],"p2R"=Arg[15,11],
                 "p2S"=Arg[16,11],"p2T"=Arg[17,11],"p2V"=Arg[18,11],"p2W"=Arg[19,11],"p2Y"=Arg[20,11],"p2O"=1,
                 "p3A"=Arg[1,12], "p3C"=Arg[2,12], "p3D"=Arg[3,12], "p3E"=Arg[4,12], "p3F"=Arg[5,12],"p3G"=Arg[6,12],"p3H"=Arg[7,12],"p3I"=Arg[8,12],"p3K"=Arg[9,12],"p3L"=Arg[10,12],"p3M"=Arg[11,12],"p3N"=Arg[12,12],"p3P"=Arg[13,12],"p3Q"=Arg[14,12],"p3R"=Arg[15,12],
                 "p3S"=Arg[16,12],"p3T"=Arg[17,12],"p3V"=Arg[18,12],"p3W"=Arg[19,12],"p3Y"=Arg[20,12],"p3O"=1,
                 "p4A"=Arg[1,13], "p4C"=Arg[2,13], "p4D"=Arg[3,13], "p4E"=Arg[4,13], "p4F"=Arg[5,13],"p4G"=Arg[6,13],"p4H"=Arg[7,13],"p4I"=Arg[8,13],"p4K"=Arg[9,13],"p4L"=Arg[10,13],"p4M"=Arg[11,13],"p4N"=Arg[12,13],"p4P"=Arg[13,13],"p4Q"=Arg[14,13],"p4R"=Arg[15,13],
                 "p4S"=Arg[16,13],"p4T"=Arg[17,13],"p4V"=Arg[18,13],"p4W"=Arg[19,13],"p4Y"=Arg[20,13],"p4O"=1,
                 "p5A"=Arg[1,14], "p5C"=Arg[2,14], "p5D"=Arg[3,14], "p5E"=Arg[4,14], "p5F"=Arg[5,14],"p5G"=Arg[6,14],"p5H"=Arg[7,14],"p5I"=Arg[8,14],"p5K"=Arg[9,14],"p5L"=Arg[10,14],"p5M"=Arg[11,14],"p5N"=Arg[12,14],"p5P"=Arg[13,14],"p5Q"=Arg[14,14],"p5R"=Arg[15,14],
                 "p5S"=Arg[16,14],"p5T"=Arg[17,14],"p5V"=Arg[18,14],"p5W"=Arg[19,14],"p5Y"=Arg[20,14],"p5O"=1,
                 "p6A"=Arg[1,15], "p6C"=Arg[2,15], "p6D"=Arg[3,15], "p6E"=Arg[4,15], "p6F"=Arg[5,15],"p6G"=Arg[6,15],"p6H"=Arg[7,15],"p6I"=Arg[8,15],"p6K"=Arg[9,15],"p6L"=Arg[10,15],"p6M"=Arg[11,15],"p6N"=Arg[12,15],"p6P"=Arg[13,15],"p6Q"=Arg[14,15],"p6R"=Arg[15,15],
                 "p6S"=Arg[16,15],"p6T"=Arg[17,15],"p6V"=Arg[18,15],"p6W"=Arg[19,15],"p6Y"=Arg[20,15],"p6O"=1)
  
  Btk_props <- c("m6A"=Btk[1,3], "m6C"=Btk[2,3], "m6D"=Btk[3,3], "m6E"=Btk[4,3], "m6F"=Btk[5,3],"m6G"=Btk[6,3],"m6H"=Btk[7,3],"m6I"=Btk[8,3],"m6K"=Btk[9,3],"m6L"=Btk[10,3],"m6M"=Btk[11,3],"m6N"=Btk[12,3],"m6P"=Btk[13,3],"m6Q"=Btk[14,3],"m6R"=Btk[15,3],
                 "m6S"=Btk[16,3],"m6T"=Btk[17,3],"m6V"=Btk[18,3],"m6W"=Btk[19,3],"m6Y"=Btk[20,3],"m6O"=1,
                 "m5A"=Btk[1,4], "m5C"=Btk[2,4], "m5D"=Btk[3,4], "m5E"=Btk[4,4], "m5F"=Btk[5,4],"m5G"=Btk[6,4],"m5H"=Btk[7,4],"m5I"=Btk[8,4],"m5K"=Btk[9,4],"m5L"=Btk[10,4],"m5M"=Btk[11,4],"m5N"=Btk[12,4],"m5P"=Btk[13,4],"m5Q"=Btk[14,4],"m5R"=Btk[15,4],
                 "m5S"=Btk[16,4],"m5T"=Btk[17,4],"m5V"=Btk[18,4],"m5W"=Btk[19,4],"m5Y"=Btk[20,4],"m5O"=1,
                 "m4A"=Btk[1,5], "m4C"=Btk[2,5], "m4D"=Btk[3,5], "m4E"=Btk[4,5], "m4F"=Btk[5,5],"m4G"=Btk[6,5],"m4H"=Btk[7,5],"m4I"=Btk[8,5],"m4K"=Btk[9,5],"m4L"=Btk[10,5],"m4M"=Btk[11,5],"m4N"=Btk[12,5],"m4P"=Btk[13,5],"m4Q"=Btk[14,5],"m4R"=Btk[15,5],
                 "m4S"=Btk[16,5],"m4T"=Btk[17,5],"m4V"=Btk[18,5],"m4W"=Btk[19,5],"m4Y"=Btk[20,5],"m4O"=1,
                 "m3A"=Btk[1,6], "m3C"=Btk[2,6], "m3D"=Btk[3,6], "m3E"=Btk[4,6], "m3F"=Btk[5,6],"m3G"=Btk[6,6],"m3H"=Btk[7,6],"m3I"=Btk[8,6],"m3K"=Btk[9,6],"m3L"=Btk[10,6],"m3M"=Btk[11,6],"m3N"=Btk[12,6],"m3P"=Btk[13,6],"m3Q"=Btk[14,6],"m3R"=Btk[15,6],
                 "m3S"=Btk[16,6],"m3T"=Btk[17,6],"m3V"=Btk[18,6],"m3W"=Btk[19,6],"m3Y"=Btk[20,6],"m3O"=1,
                 "m2A"=Btk[1,7], "m2C"=Btk[2,7], "m2D"=Btk[3,7], "m2E"=Btk[4,7], "m2F"=Btk[5,7],"m2G"=Btk[6,7],"m2H"=Btk[7,7],"m2I"=Btk[8,7],"m2K"=Btk[9,7],"m2L"=Btk[10,7],"m2M"=Btk[11,7],"m2N"=Btk[12,7],"m2P"=Btk[13,7],"m2Q"=Btk[14,7],"m2R"=Btk[15,7],
                 "m2S"=Btk[16,7],"m2T"=Btk[17,7],"m2V"=Btk[18,7],"m2W"=Btk[19,7],"m2Y"=Btk[20,7],"m2O"=1,
                 "m1A"=Btk[1,8], "m1C"=Btk[2,8], "m1D"=Btk[3,8], "m1E"=Btk[4,8], "m1F"=Btk[5,8],"m1G"=Btk[6,8],"m1H"=Btk[7,8],"m1I"=Btk[8,8],"m1K"=Btk[9,8],"m1L"=Btk[10,8],"m1M"=Btk[11,8],"m1N"=Btk[12,8],"m1P"=Btk[13,8],"m1Q"=Btk[14,8],"m1R"=Btk[15,8],
                 "m1S"=Btk[16,8],"m1T"=Btk[17,8],"m1V"=Btk[18,8],"m1W"=Btk[19,8],"m1Y"=Btk[20,8],"m1O"=1,
                 "d0A"=Btk[1,9], "d0C"=Btk[2,9], "d0D"=Btk[3,9], "d0E"=Btk[4,9], "d0F"=Btk[5,9],"d0G"=Btk[6,9],"d0H"=Btk[7,9],"d0I"=Btk[8,9],"d0K"=Btk[9,9],"d0L"=Btk[10,9],"d0M"=Btk[11,9],"d0N"=Btk[12,9],"d0P"=Btk[13,9],"d0Q"=Btk[14,9],"d0R"=Btk[15,9],
                 "d0S"=Btk[16,9],"d0T"=Btk[17,9],"d0V"=Btk[18,9],"d0W"=Btk[19,9],"d0Y"=Btk[20,9],"d0O"=1,
                 "p1A"=Btk[1,10], "p1C"=Btk[2,10], "p1D"=Btk[3,10], "p1E"=Btk[4,10], "p1F"=Btk[5,10],"p1G"=Btk[6,10],"p1H"=Btk[7,10],"p1I"=Btk[8,10],"p1K"=Btk[9,10],"p1L"=Btk[10,10],"p1M"=Btk[11,10],"p1N"=Btk[12,10],"p1P"=Btk[13,10],"p1Q"=Btk[14,10],"p1R"=Btk[15,10],
                 "p1S"=Btk[16,10],"p1T"=Btk[17,10],"p1V"=Btk[18,10],"p1W"=Btk[19,10],"p1Y"=Btk[20,10],"p1O"=1,
                 "p2A"=Btk[1,11], "p2C"=Btk[2,11], "p2D"=Btk[3,11], "p2E"=Btk[4,11], "p2F"=Btk[5,11],"p2G"=Btk[6,11],"p2H"=Btk[7,11],"p2I"=Btk[8,11],"p2K"=Btk[9,11],"p2L"=Btk[10,11],"p2M"=Btk[11,11],"p2N"=Btk[12,11],"p2P"=Btk[13,11],"p2Q"=Btk[14,11],"p2R"=Btk[15,11],
                 "p2S"=Btk[16,11],"p2T"=Btk[17,11],"p2V"=Btk[18,11],"p2W"=Btk[19,11],"p2Y"=Btk[20,11],"p2O"=1,
                 "p3A"=Btk[1,12], "p3C"=Btk[2,12], "p3D"=Btk[3,12], "p3E"=Btk[4,12], "p3F"=Btk[5,12],"p3G"=Btk[6,12],"p3H"=Btk[7,12],"p3I"=Btk[8,12],"p3K"=Btk[9,12],"p3L"=Btk[10,12],"p3M"=Btk[11,12],"p3N"=Btk[12,12],"p3P"=Btk[13,12],"p3Q"=Btk[14,12],"p3R"=Btk[15,12],
                 "p3S"=Btk[16,12],"p3T"=Btk[17,12],"p3V"=Btk[18,12],"p3W"=Btk[19,12],"p3Y"=Btk[20,12],"p3O"=1,
                 "p4A"=Btk[1,13], "p4C"=Btk[2,13], "p4D"=Btk[3,13], "p4E"=Btk[4,13], "p4F"=Btk[5,13],"p4G"=Btk[6,13],"p4H"=Btk[7,13],"p4I"=Btk[8,13],"p4K"=Btk[9,13],"p4L"=Btk[10,13],"p4M"=Btk[11,13],"p4N"=Btk[12,13],"p4P"=Btk[13,13],"p4Q"=Btk[14,13],"p4R"=Btk[15,13],
                 "p4S"=Btk[16,13],"p4T"=Btk[17,13],"p4V"=Btk[18,13],"p4W"=Btk[19,13],"p4Y"=Btk[20,13],"p4O"=1,
                 "p5A"=Btk[1,14], "p5C"=Btk[2,14], "p5D"=Btk[3,14], "p5E"=Btk[4,14], "p5F"=Btk[5,14],"p5G"=Btk[6,14],"p5H"=Btk[7,14],"p5I"=Btk[8,14],"p5K"=Btk[9,14],"p5L"=Btk[10,14],"p5M"=Btk[11,14],"p5N"=Btk[12,14],"p5P"=Btk[13,14],"p5Q"=Btk[14,14],"p5R"=Btk[15,14],
                 "p5S"=Btk[16,14],"p5T"=Btk[17,14],"p5V"=Btk[18,14],"p5W"=Btk[19,14],"p5Y"=Btk[20,14],"p5O"=1,
                 "p6A"=Btk[1,15], "p6C"=Btk[2,15], "p6D"=Btk[3,15], "p6E"=Btk[4,15], "p6F"=Btk[5,15],"p6G"=Btk[6,15],"p6H"=Btk[7,15],"p6I"=Btk[8,15],"p6K"=Btk[9,15],"p6L"=Btk[10,15],"p6M"=Btk[11,15],"p6N"=Btk[12,15],"p6P"=Btk[13,15],"p6Q"=Btk[14,15],"p6R"=Btk[15,15],
                 "p6S"=Btk[16,15],"p6T"=Btk[17,15],"p6V"=Btk[18,15],"p6W"=Btk[19,15],"p6Y"=Btk[20,15],"p6O"=1)
  
  Csk_props <- c("m6A"=Csk[1,3], "m6C"=Csk[2,3], "m6D"=Csk[3,3], "m6E"=Csk[4,3], "m6F"=Csk[5,3],"m6G"=Csk[6,3],"m6H"=Csk[7,3],"m6I"=Csk[8,3],"m6K"=Csk[9,3],"m6L"=Csk[10,3],"m6M"=Csk[11,3],"m6N"=Csk[12,3],"m6P"=Csk[13,3],"m6Q"=Csk[14,3],"m6R"=Csk[15,3],
                 "m6S"=Csk[16,3],"m6T"=Csk[17,3],"m6V"=Csk[18,3],"m6W"=Csk[19,3],"m6Y"=Csk[20,3],"m6O"=1,
                 "m5A"=Csk[1,4], "m5C"=Csk[2,4], "m5D"=Csk[3,4], "m5E"=Csk[4,4], "m5F"=Csk[5,4],"m5G"=Csk[6,4],"m5H"=Csk[7,4],"m5I"=Csk[8,4],"m5K"=Csk[9,4],"m5L"=Csk[10,4],"m5M"=Csk[11,4],"m5N"=Csk[12,4],"m5P"=Csk[13,4],"m5Q"=Csk[14,4],"m5R"=Csk[15,4],
                 "m5S"=Csk[16,4],"m5T"=Csk[17,4],"m5V"=Csk[18,4],"m5W"=Csk[19,4],"m5Y"=Csk[20,4],"m5O"=1,
                 "m4A"=Csk[1,5], "m4C"=Csk[2,5], "m4D"=Csk[3,5], "m4E"=Csk[4,5], "m4F"=Csk[5,5],"m4G"=Csk[6,5],"m4H"=Csk[7,5],"m4I"=Csk[8,5],"m4K"=Csk[9,5],"m4L"=Csk[10,5],"m4M"=Csk[11,5],"m4N"=Csk[12,5],"m4P"=Csk[13,5],"m4Q"=Csk[14,5],"m4R"=Csk[15,5],
                 "m4S"=Csk[16,5],"m4T"=Csk[17,5],"m4V"=Csk[18,5],"m4W"=Csk[19,5],"m4Y"=Csk[20,5],"m4O"=1,
                 "m3A"=Csk[1,6], "m3C"=Csk[2,6], "m3D"=Csk[3,6], "m3E"=Csk[4,6], "m3F"=Csk[5,6],"m3G"=Csk[6,6],"m3H"=Csk[7,6],"m3I"=Csk[8,6],"m3K"=Csk[9,6],"m3L"=Csk[10,6],"m3M"=Csk[11,6],"m3N"=Csk[12,6],"m3P"=Csk[13,6],"m3Q"=Csk[14,6],"m3R"=Csk[15,6],
                 "m3S"=Csk[16,6],"m3T"=Csk[17,6],"m3V"=Csk[18,6],"m3W"=Csk[19,6],"m3Y"=Csk[20,6],"m3O"=1,
                 "m2A"=Csk[1,7], "m2C"=Csk[2,7], "m2D"=Csk[3,7], "m2E"=Csk[4,7], "m2F"=Csk[5,7],"m2G"=Csk[6,7],"m2H"=Csk[7,7],"m2I"=Csk[8,7],"m2K"=Csk[9,7],"m2L"=Csk[10,7],"m2M"=Csk[11,7],"m2N"=Csk[12,7],"m2P"=Csk[13,7],"m2Q"=Csk[14,7],"m2R"=Csk[15,7],
                 "m2S"=Csk[16,7],"m2T"=Csk[17,7],"m2V"=Csk[18,7],"m2W"=Csk[19,7],"m2Y"=Csk[20,7],"m2O"=1,
                 "m1A"=Csk[1,8], "m1C"=Csk[2,8], "m1D"=Csk[3,8], "m1E"=Csk[4,8], "m1F"=Csk[5,8],"m1G"=Csk[6,8],"m1H"=Csk[7,8],"m1I"=Csk[8,8],"m1K"=Csk[9,8],"m1L"=Csk[10,8],"m1M"=Csk[11,8],"m1N"=Csk[12,8],"m1P"=Csk[13,8],"m1Q"=Csk[14,8],"m1R"=Csk[15,8],
                 "m1S"=Csk[16,8],"m1T"=Csk[17,8],"m1V"=Csk[18,8],"m1W"=Csk[19,8],"m1Y"=Csk[20,8],"m1O"=1,
                 "d0A"=Csk[1,9], "d0C"=Csk[2,9], "d0D"=Csk[3,9], "d0E"=Csk[4,9], "d0F"=Csk[5,9],"d0G"=Csk[6,9],"d0H"=Csk[7,9],"d0I"=Csk[8,9],"d0K"=Csk[9,9],"d0L"=Csk[10,9],"d0M"=Csk[11,9],"d0N"=Csk[12,9],"d0P"=Csk[13,9],"d0Q"=Csk[14,9],"d0R"=Csk[15,9],
                 "d0S"=Csk[16,9],"d0T"=Csk[17,9],"d0V"=Csk[18,9],"d0W"=Csk[19,9],"d0Y"=Csk[20,9],"d0O"=1,
                 "p1A"=Csk[1,10], "p1C"=Csk[2,10], "p1D"=Csk[3,10], "p1E"=Csk[4,10], "p1F"=Csk[5,10],"p1G"=Csk[6,10],"p1H"=Csk[7,10],"p1I"=Csk[8,10],"p1K"=Csk[9,10],"p1L"=Csk[10,10],"p1M"=Csk[11,10],"p1N"=Csk[12,10],"p1P"=Csk[13,10],"p1Q"=Csk[14,10],"p1R"=Csk[15,10],
                 "p1S"=Csk[16,10],"p1T"=Csk[17,10],"p1V"=Csk[18,10],"p1W"=Csk[19,10],"p1Y"=Csk[20,10],"p1O"=1,
                 "p2A"=Csk[1,11], "p2C"=Csk[2,11], "p2D"=Csk[3,11], "p2E"=Csk[4,11], "p2F"=Csk[5,11],"p2G"=Csk[6,11],"p2H"=Csk[7,11],"p2I"=Csk[8,11],"p2K"=Csk[9,11],"p2L"=Csk[10,11],"p2M"=Csk[11,11],"p2N"=Csk[12,11],"p2P"=Csk[13,11],"p2Q"=Csk[14,11],"p2R"=Csk[15,11],
                 "p2S"=Csk[16,11],"p2T"=Csk[17,11],"p2V"=Csk[18,11],"p2W"=Csk[19,11],"p2Y"=Csk[20,11],"p2O"=1,
                 "p3A"=Csk[1,12], "p3C"=Csk[2,12], "p3D"=Csk[3,12], "p3E"=Csk[4,12], "p3F"=Csk[5,12],"p3G"=Csk[6,12],"p3H"=Csk[7,12],"p3I"=Csk[8,12],"p3K"=Csk[9,12],"p3L"=Csk[10,12],"p3M"=Csk[11,12],"p3N"=Csk[12,12],"p3P"=Csk[13,12],"p3Q"=Csk[14,12],"p3R"=Csk[15,12],
                 "p3S"=Csk[16,12],"p3T"=Csk[17,12],"p3V"=Csk[18,12],"p3W"=Csk[19,12],"p3Y"=Csk[20,12],"p3O"=1,
                 "p4A"=Csk[1,13], "p4C"=Csk[2,13], "p4D"=Csk[3,13], "p4E"=Csk[4,13], "p4F"=Csk[5,13],"p4G"=Csk[6,13],"p4H"=Csk[7,13],"p4I"=Csk[8,13],"p4K"=Csk[9,13],"p4L"=Csk[10,13],"p4M"=Csk[11,13],"p4N"=Csk[12,13],"p4P"=Csk[13,13],"p4Q"=Csk[14,13],"p4R"=Csk[15,13],
                 "p4S"=Csk[16,13],"p4T"=Csk[17,13],"p4V"=Csk[18,13],"p4W"=Csk[19,13],"p4Y"=Csk[20,13],"p4O"=1,
                 "p5A"=Csk[1,14], "p5C"=Csk[2,14], "p5D"=Csk[3,14], "p5E"=Csk[4,14], "p5F"=Csk[5,14],"p5G"=Csk[6,14],"p5H"=Csk[7,14],"p5I"=Csk[8,14],"p5K"=Csk[9,14],"p5L"=Csk[10,14],"p5M"=Csk[11,14],"p5N"=Csk[12,14],"p5P"=Csk[13,14],"p5Q"=Csk[14,14],"p5R"=Csk[15,14],
                 "p5S"=Csk[16,14],"p5T"=Csk[17,14],"p5V"=Csk[18,14],"p5W"=Csk[19,14],"p5Y"=Csk[20,14],"p5O"=1,
                 "p6A"=Csk[1,15], "p6C"=Csk[2,15], "p6D"=Csk[3,15], "p6E"=Csk[4,15], "p6F"=Csk[5,15],"p6G"=Csk[6,15],"p6H"=Csk[7,15],"p6I"=Csk[8,15],"p6K"=Csk[9,15],"p6L"=Csk[10,15],"p6M"=Csk[11,15],"p6N"=Csk[12,15],"p6P"=Csk[13,15],"p6Q"=Csk[14,15],"p6R"=Csk[15,15],
                 "p6S"=Csk[16,15],"p6T"=Csk[17,15],"p6V"=Csk[18,15],"p6W"=Csk[19,15],"p6Y"=Csk[20,15],"p6O"=1)
  
  Fyn_props <- c("m6A"=Fyn[1,3], "m6C"=Fyn[2,3], "m6D"=Fyn[3,3], "m6E"=Fyn[4,3], "m6F"=Fyn[5,3],"m6G"=Fyn[6,3],"m6H"=Fyn[7,3],"m6I"=Fyn[8,3],"m6K"=Fyn[9,3],"m6L"=Fyn[10,3],"m6M"=Fyn[11,3],"m6N"=Fyn[12,3],"m6P"=Fyn[13,3],"m6Q"=Fyn[14,3],"m6R"=Fyn[15,3],
                 "m6S"=Fyn[16,3],"m6T"=Fyn[17,3],"m6V"=Fyn[18,3],"m6W"=Fyn[19,3],"m6Y"=Fyn[20,3],"m6O"=1,
                 "m5A"=Fyn[1,4], "m5C"=Fyn[2,4], "m5D"=Fyn[3,4], "m5E"=Fyn[4,4], "m5F"=Fyn[5,4],"m5G"=Fyn[6,4],"m5H"=Fyn[7,4],"m5I"=Fyn[8,4],"m5K"=Fyn[9,4],"m5L"=Fyn[10,4],"m5M"=Fyn[11,4],"m5N"=Fyn[12,4],"m5P"=Fyn[13,4],"m5Q"=Fyn[14,4],"m5R"=Fyn[15,4],
                 "m5S"=Fyn[16,4],"m5T"=Fyn[17,4],"m5V"=Fyn[18,4],"m5W"=Fyn[19,4],"m5Y"=Fyn[20,4],"m5O"=1,
                 "m4A"=Fyn[1,5], "m4C"=Fyn[2,5], "m4D"=Fyn[3,5], "m4E"=Fyn[4,5], "m4F"=Fyn[5,5],"m4G"=Fyn[6,5],"m4H"=Fyn[7,5],"m4I"=Fyn[8,5],"m4K"=Fyn[9,5],"m4L"=Fyn[10,5],"m4M"=Fyn[11,5],"m4N"=Fyn[12,5],"m4P"=Fyn[13,5],"m4Q"=Fyn[14,5],"m4R"=Fyn[15,5],
                 "m4S"=Fyn[16,5],"m4T"=Fyn[17,5],"m4V"=Fyn[18,5],"m4W"=Fyn[19,5],"m4Y"=Fyn[20,5],"m4O"=1,
                 "m3A"=Fyn[1,6], "m3C"=Fyn[2,6], "m3D"=Fyn[3,6], "m3E"=Fyn[4,6], "m3F"=Fyn[5,6],"m3G"=Fyn[6,6],"m3H"=Fyn[7,6],"m3I"=Fyn[8,6],"m3K"=Fyn[9,6],"m3L"=Fyn[10,6],"m3M"=Fyn[11,6],"m3N"=Fyn[12,6],"m3P"=Fyn[13,6],"m3Q"=Fyn[14,6],"m3R"=Fyn[15,6],
                 "m3S"=Fyn[16,6],"m3T"=Fyn[17,6],"m3V"=Fyn[18,6],"m3W"=Fyn[19,6],"m3Y"=Fyn[20,6],"m3O"=1,
                 "m2A"=Fyn[1,7], "m2C"=Fyn[2,7], "m2D"=Fyn[3,7], "m2E"=Fyn[4,7], "m2F"=Fyn[5,7],"m2G"=Fyn[6,7],"m2H"=Fyn[7,7],"m2I"=Fyn[8,7],"m2K"=Fyn[9,7],"m2L"=Fyn[10,7],"m2M"=Fyn[11,7],"m2N"=Fyn[12,7],"m2P"=Fyn[13,7],"m2Q"=Fyn[14,7],"m2R"=Fyn[15,7],
                 "m2S"=Fyn[16,7],"m2T"=Fyn[17,7],"m2V"=Fyn[18,7],"m2W"=Fyn[19,7],"m2Y"=Fyn[20,7],"m2O"=1,
                 "m1A"=Fyn[1,8], "m1C"=Fyn[2,8], "m1D"=Fyn[3,8], "m1E"=Fyn[4,8], "m1F"=Fyn[5,8],"m1G"=Fyn[6,8],"m1H"=Fyn[7,8],"m1I"=Fyn[8,8],"m1K"=Fyn[9,8],"m1L"=Fyn[10,8],"m1M"=Fyn[11,8],"m1N"=Fyn[12,8],"m1P"=Fyn[13,8],"m1Q"=Fyn[14,8],"m1R"=Fyn[15,8],
                 "m1S"=Fyn[16,8],"m1T"=Fyn[17,8],"m1V"=Fyn[18,8],"m1W"=Fyn[19,8],"m1Y"=Fyn[20,8],"m1O"=1,
                 "d0A"=Fyn[1,9], "d0C"=Fyn[2,9], "d0D"=Fyn[3,9], "d0E"=Fyn[4,9], "d0F"=Fyn[5,9],"d0G"=Fyn[6,9],"d0H"=Fyn[7,9],"d0I"=Fyn[8,9],"d0K"=Fyn[9,9],"d0L"=Fyn[10,9],"d0M"=Fyn[11,9],"d0N"=Fyn[12,9],"d0P"=Fyn[13,9],"d0Q"=Fyn[14,9],"d0R"=Fyn[15,9],
                 "d0S"=Fyn[16,9],"d0T"=Fyn[17,9],"d0V"=Fyn[18,9],"d0W"=Fyn[19,9],"d0Y"=Fyn[20,9],"d0O"=1,
                 "p1A"=Fyn[1,10], "p1C"=Fyn[2,10], "p1D"=Fyn[3,10], "p1E"=Fyn[4,10], "p1F"=Fyn[5,10],"p1G"=Fyn[6,10],"p1H"=Fyn[7,10],"p1I"=Fyn[8,10],"p1K"=Fyn[9,10],"p1L"=Fyn[10,10],"p1M"=Fyn[11,10],"p1N"=Fyn[12,10],"p1P"=Fyn[13,10],"p1Q"=Fyn[14,10],"p1R"=Fyn[15,10],
                 "p1S"=Fyn[16,10],"p1T"=Fyn[17,10],"p1V"=Fyn[18,10],"p1W"=Fyn[19,10],"p1Y"=Fyn[20,10],"p1O"=1,
                 "p2A"=Fyn[1,11], "p2C"=Fyn[2,11], "p2D"=Fyn[3,11], "p2E"=Fyn[4,11], "p2F"=Fyn[5,11],"p2G"=Fyn[6,11],"p2H"=Fyn[7,11],"p2I"=Fyn[8,11],"p2K"=Fyn[9,11],"p2L"=Fyn[10,11],"p2M"=Fyn[11,11],"p2N"=Fyn[12,11],"p2P"=Fyn[13,11],"p2Q"=Fyn[14,11],"p2R"=Fyn[15,11],
                 "p2S"=Fyn[16,11],"p2T"=Fyn[17,11],"p2V"=Fyn[18,11],"p2W"=Fyn[19,11],"p2Y"=Fyn[20,11],"p2O"=1,
                 "p3A"=Fyn[1,12], "p3C"=Fyn[2,12], "p3D"=Fyn[3,12], "p3E"=Fyn[4,12], "p3F"=Fyn[5,12],"p3G"=Fyn[6,12],"p3H"=Fyn[7,12],"p3I"=Fyn[8,12],"p3K"=Fyn[9,12],"p3L"=Fyn[10,12],"p3M"=Fyn[11,12],"p3N"=Fyn[12,12],"p3P"=Fyn[13,12],"p3Q"=Fyn[14,12],"p3R"=Fyn[15,12],
                 "p3S"=Fyn[16,12],"p3T"=Fyn[17,12],"p3V"=Fyn[18,12],"p3W"=Fyn[19,12],"p3Y"=Fyn[20,12],"p3O"=1,
                 "p4A"=Fyn[1,13], "p4C"=Fyn[2,13], "p4D"=Fyn[3,13], "p4E"=Fyn[4,13], "p4F"=Fyn[5,13],"p4G"=Fyn[6,13],"p4H"=Fyn[7,13],"p4I"=Fyn[8,13],"p4K"=Fyn[9,13],"p4L"=Fyn[10,13],"p4M"=Fyn[11,13],"p4N"=Fyn[12,13],"p4P"=Fyn[13,13],"p4Q"=Fyn[14,13],"p4R"=Fyn[15,13],
                 "p4S"=Fyn[16,13],"p4T"=Fyn[17,13],"p4V"=Fyn[18,13],"p4W"=Fyn[19,13],"p4Y"=Fyn[20,13],"p4O"=1,
                 "p5A"=Fyn[1,14], "p5C"=Fyn[2,14], "p5D"=Fyn[3,14], "p5E"=Fyn[4,14], "p5F"=Fyn[5,14],"p5G"=Fyn[6,14],"p5H"=Fyn[7,14],"p5I"=Fyn[8,14],"p5K"=Fyn[9,14],"p5L"=Fyn[10,14],"p5M"=Fyn[11,14],"p5N"=Fyn[12,14],"p5P"=Fyn[13,14],"p5Q"=Fyn[14,14],"p5R"=Fyn[15,14],
                 "p5S"=Fyn[16,14],"p5T"=Fyn[17,14],"p5V"=Fyn[18,14],"p5W"=Fyn[19,14],"p5Y"=Fyn[20,14],"p5O"=1,
                 "p6A"=Fyn[1,15], "p6C"=Fyn[2,15], "p6D"=Fyn[3,15], "p6E"=Fyn[4,15], "p6F"=Fyn[5,15],"p6G"=Fyn[6,15],"p6H"=Fyn[7,15],"p6I"=Fyn[8,15],"p6K"=Fyn[9,15],"p6L"=Fyn[10,15],"p6M"=Fyn[11,15],"p6N"=Fyn[12,15],"p6P"=Fyn[13,15],"p6Q"=Fyn[14,15],"p6R"=Fyn[15,15],
                 "p6S"=Fyn[16,15],"p6T"=Fyn[17,15],"p6V"=Fyn[18,15],"p6W"=Fyn[19,15],"p6Y"=Fyn[20,15],"p6O"=1)
  
  Hck_props <- c("m6A"=Hck[1,3], "m6C"=Hck[2,3], "m6D"=Hck[3,3], "m6E"=Hck[4,3], "m6F"=Hck[5,3],"m6G"=Hck[6,3],"m6H"=Hck[7,3],"m6I"=Hck[8,3],"m6K"=Hck[9,3],"m6L"=Hck[10,3],"m6M"=Hck[11,3],"m6N"=Hck[12,3],"m6P"=Hck[13,3],"m6Q"=Hck[14,3],"m6R"=Hck[15,3],
                 "m6S"=Hck[16,3],"m6T"=Hck[17,3],"m6V"=Hck[18,3],"m6W"=Hck[19,3],"m6Y"=Hck[20,3],"m6O"=1,
                 "m5A"=Hck[1,4], "m5C"=Hck[2,4], "m5D"=Hck[3,4], "m5E"=Hck[4,4], "m5F"=Hck[5,4],"m5G"=Hck[6,4],"m5H"=Hck[7,4],"m5I"=Hck[8,4],"m5K"=Hck[9,4],"m5L"=Hck[10,4],"m5M"=Hck[11,4],"m5N"=Hck[12,4],"m5P"=Hck[13,4],"m5Q"=Hck[14,4],"m5R"=Hck[15,4],
                 "m5S"=Hck[16,4],"m5T"=Hck[17,4],"m5V"=Hck[18,4],"m5W"=Hck[19,4],"m5Y"=Hck[20,4],"m5O"=1,
                 "m4A"=Hck[1,5], "m4C"=Hck[2,5], "m4D"=Hck[3,5], "m4E"=Hck[4,5], "m4F"=Hck[5,5],"m4G"=Hck[6,5],"m4H"=Hck[7,5],"m4I"=Hck[8,5],"m4K"=Hck[9,5],"m4L"=Hck[10,5],"m4M"=Hck[11,5],"m4N"=Hck[12,5],"m4P"=Hck[13,5],"m4Q"=Hck[14,5],"m4R"=Hck[15,5],
                 "m4S"=Hck[16,5],"m4T"=Hck[17,5],"m4V"=Hck[18,5],"m4W"=Hck[19,5],"m4Y"=Hck[20,5],"m4O"=1,
                 "m3A"=Hck[1,6], "m3C"=Hck[2,6], "m3D"=Hck[3,6], "m3E"=Hck[4,6], "m3F"=Hck[5,6],"m3G"=Hck[6,6],"m3H"=Hck[7,6],"m3I"=Hck[8,6],"m3K"=Hck[9,6],"m3L"=Hck[10,6],"m3M"=Hck[11,6],"m3N"=Hck[12,6],"m3P"=Hck[13,6],"m3Q"=Hck[14,6],"m3R"=Hck[15,6],
                 "m3S"=Hck[16,6],"m3T"=Hck[17,6],"m3V"=Hck[18,6],"m3W"=Hck[19,6],"m3Y"=Hck[20,6],"m3O"=1,
                 "m2A"=Hck[1,7], "m2C"=Hck[2,7], "m2D"=Hck[3,7], "m2E"=Hck[4,7], "m2F"=Hck[5,7],"m2G"=Hck[6,7],"m2H"=Hck[7,7],"m2I"=Hck[8,7],"m2K"=Hck[9,7],"m2L"=Hck[10,7],"m2M"=Hck[11,7],"m2N"=Hck[12,7],"m2P"=Hck[13,7],"m2Q"=Hck[14,7],"m2R"=Hck[15,7],
                 "m2S"=Hck[16,7],"m2T"=Hck[17,7],"m2V"=Hck[18,7],"m2W"=Hck[19,7],"m2Y"=Hck[20,7],"m2O"=1,
                 "m1A"=Hck[1,8], "m1C"=Hck[2,8], "m1D"=Hck[3,8], "m1E"=Hck[4,8], "m1F"=Hck[5,8],"m1G"=Hck[6,8],"m1H"=Hck[7,8],"m1I"=Hck[8,8],"m1K"=Hck[9,8],"m1L"=Hck[10,8],"m1M"=Hck[11,8],"m1N"=Hck[12,8],"m1P"=Hck[13,8],"m1Q"=Hck[14,8],"m1R"=Hck[15,8],
                 "m1S"=Hck[16,8],"m1T"=Hck[17,8],"m1V"=Hck[18,8],"m1W"=Hck[19,8],"m1Y"=Hck[20,8],"m1O"=1,
                 "d0A"=Hck[1,9], "d0C"=Hck[2,9], "d0D"=Hck[3,9], "d0E"=Hck[4,9], "d0F"=Hck[5,9],"d0G"=Hck[6,9],"d0H"=Hck[7,9],"d0I"=Hck[8,9],"d0K"=Hck[9,9],"d0L"=Hck[10,9],"d0M"=Hck[11,9],"d0N"=Hck[12,9],"d0P"=Hck[13,9],"d0Q"=Hck[14,9],"d0R"=Hck[15,9],
                 "d0S"=Hck[16,9],"d0T"=Hck[17,9],"d0V"=Hck[18,9],"d0W"=Hck[19,9],"d0Y"=Hck[20,9],"d0O"=1,
                 "p1A"=Hck[1,10], "p1C"=Hck[2,10], "p1D"=Hck[3,10], "p1E"=Hck[4,10], "p1F"=Hck[5,10],"p1G"=Hck[6,10],"p1H"=Hck[7,10],"p1I"=Hck[8,10],"p1K"=Hck[9,10],"p1L"=Hck[10,10],"p1M"=Hck[11,10],"p1N"=Hck[12,10],"p1P"=Hck[13,10],"p1Q"=Hck[14,10],"p1R"=Hck[15,10],
                 "p1S"=Hck[16,10],"p1T"=Hck[17,10],"p1V"=Hck[18,10],"p1W"=Hck[19,10],"p1Y"=Hck[20,10],"p1O"=1,
                 "p2A"=Hck[1,11], "p2C"=Hck[2,11], "p2D"=Hck[3,11], "p2E"=Hck[4,11], "p2F"=Hck[5,11],"p2G"=Hck[6,11],"p2H"=Hck[7,11],"p2I"=Hck[8,11],"p2K"=Hck[9,11],"p2L"=Hck[10,11],"p2M"=Hck[11,11],"p2N"=Hck[12,11],"p2P"=Hck[13,11],"p2Q"=Hck[14,11],"p2R"=Hck[15,11],
                 "p2S"=Hck[16,11],"p2T"=Hck[17,11],"p2V"=Hck[18,11],"p2W"=Hck[19,11],"p2Y"=Hck[20,11],"p2O"=1,
                 "p3A"=Hck[1,12], "p3C"=Hck[2,12], "p3D"=Hck[3,12], "p3E"=Hck[4,12], "p3F"=Hck[5,12],"p3G"=Hck[6,12],"p3H"=Hck[7,12],"p3I"=Hck[8,12],"p3K"=Hck[9,12],"p3L"=Hck[10,12],"p3M"=Hck[11,12],"p3N"=Hck[12,12],"p3P"=Hck[13,12],"p3Q"=Hck[14,12],"p3R"=Hck[15,12],
                 "p3S"=Hck[16,12],"p3T"=Hck[17,12],"p3V"=Hck[18,12],"p3W"=Hck[19,12],"p3Y"=Hck[20,12],"p3O"=1,
                 "p4A"=Hck[1,13], "p4C"=Hck[2,13], "p4D"=Hck[3,13], "p4E"=Hck[4,13], "p4F"=Hck[5,13],"p4G"=Hck[6,13],"p4H"=Hck[7,13],"p4I"=Hck[8,13],"p4K"=Hck[9,13],"p4L"=Hck[10,13],"p4M"=Hck[11,13],"p4N"=Hck[12,13],"p4P"=Hck[13,13],"p4Q"=Hck[14,13],"p4R"=Hck[15,13],
                 "p4S"=Hck[16,13],"p4T"=Hck[17,13],"p4V"=Hck[18,13],"p4W"=Hck[19,13],"p4Y"=Hck[20,13],"p4O"=1,
                 "p5A"=Hck[1,14], "p5C"=Hck[2,14], "p5D"=Hck[3,14], "p5E"=Hck[4,14], "p5F"=Hck[5,14],"p5G"=Hck[6,14],"p5H"=Hck[7,14],"p5I"=Hck[8,14],"p5K"=Hck[9,14],"p5L"=Hck[10,14],"p5M"=Hck[11,14],"p5N"=Hck[12,14],"p5P"=Hck[13,14],"p5Q"=Hck[14,14],"p5R"=Hck[15,14],
                 "p5S"=Hck[16,14],"p5T"=Hck[17,14],"p5V"=Hck[18,14],"p5W"=Hck[19,14],"p5Y"=Hck[20,14],"p5O"=1,
                 "p6A"=Hck[1,15], "p6C"=Hck[2,15], "p6D"=Hck[3,15], "p6E"=Hck[4,15], "p6F"=Hck[5,15],"p6G"=Hck[6,15],"p6H"=Hck[7,15],"p6I"=Hck[8,15],"p6K"=Hck[9,15],"p6L"=Hck[10,15],"p6M"=Hck[11,15],"p6N"=Hck[12,15],"p6P"=Hck[13,15],"p6Q"=Hck[14,15],"p6R"=Hck[15,15],
                 "p6S"=Hck[16,15],"p6T"=Hck[17,15],"p6V"=Hck[18,15],"p6W"=Hck[19,15],"p6Y"=Hck[20,15],"p6O"=1)
  
  JAK2_props <- c("m6A"=JAK2[1,3], "m6C"=JAK2[2,3], "m6D"=JAK2[3,3], "m6E"=JAK2[4,3], "m6F"=JAK2[5,3],"m6G"=JAK2[6,3],"m6H"=JAK2[7,3],"m6I"=JAK2[8,3],"m6K"=JAK2[9,3],"m6L"=JAK2[10,3],"m6M"=JAK2[11,3],"m6N"=JAK2[12,3],"m6P"=JAK2[13,3],"m6Q"=JAK2[14,3],"m6R"=JAK2[15,3],
                  "m6S"=JAK2[16,3],"m6T"=JAK2[17,3],"m6V"=JAK2[18,3],"m6W"=JAK2[19,3],"m6Y"=JAK2[20,3],"m6O"=1,
                  "m5A"=JAK2[1,4], "m5C"=JAK2[2,4], "m5D"=JAK2[3,4], "m5E"=JAK2[4,4], "m5F"=JAK2[5,4],"m5G"=JAK2[6,4],"m5H"=JAK2[7,4],"m5I"=JAK2[8,4],"m5K"=JAK2[9,4],"m5L"=JAK2[10,4],"m5M"=JAK2[11,4],"m5N"=JAK2[12,4],"m5P"=JAK2[13,4],"m5Q"=JAK2[14,4],"m5R"=JAK2[15,4],
                  "m5S"=JAK2[16,4],"m5T"=JAK2[17,4],"m5V"=JAK2[18,4],"m5W"=JAK2[19,4],"m5Y"=JAK2[20,4],"m5O"=1,
                  "m4A"=JAK2[1,5], "m4C"=JAK2[2,5], "m4D"=JAK2[3,5], "m4E"=JAK2[4,5], "m4F"=JAK2[5,5],"m4G"=JAK2[6,5],"m4H"=JAK2[7,5],"m4I"=JAK2[8,5],"m4K"=JAK2[9,5],"m4L"=JAK2[10,5],"m4M"=JAK2[11,5],"m4N"=JAK2[12,5],"m4P"=JAK2[13,5],"m4Q"=JAK2[14,5],"m4R"=JAK2[15,5],
                  "m4S"=JAK2[16,5],"m4T"=JAK2[17,5],"m4V"=JAK2[18,5],"m4W"=JAK2[19,5],"m4Y"=JAK2[20,5],"m4O"=1,
                  "m3A"=JAK2[1,6], "m3C"=JAK2[2,6], "m3D"=JAK2[3,6], "m3E"=JAK2[4,6], "m3F"=JAK2[5,6],"m3G"=JAK2[6,6],"m3H"=JAK2[7,6],"m3I"=JAK2[8,6],"m3K"=JAK2[9,6],"m3L"=JAK2[10,6],"m3M"=JAK2[11,6],"m3N"=JAK2[12,6],"m3P"=JAK2[13,6],"m3Q"=JAK2[14,6],"m3R"=JAK2[15,6],
                  "m3S"=JAK2[16,6],"m3T"=JAK2[17,6],"m3V"=JAK2[18,6],"m3W"=JAK2[19,6],"m3Y"=JAK2[20,6],"m3O"=1,
                  "m2A"=JAK2[1,7], "m2C"=JAK2[2,7], "m2D"=JAK2[3,7], "m2E"=JAK2[4,7], "m2F"=JAK2[5,7],"m2G"=JAK2[6,7],"m2H"=JAK2[7,7],"m2I"=JAK2[8,7],"m2K"=JAK2[9,7],"m2L"=JAK2[10,7],"m2M"=JAK2[11,7],"m2N"=JAK2[12,7],"m2P"=JAK2[13,7],"m2Q"=JAK2[14,7],"m2R"=JAK2[15,7],
                  "m2S"=JAK2[16,7],"m2T"=JAK2[17,7],"m2V"=JAK2[18,7],"m2W"=JAK2[19,7],"m2Y"=JAK2[20,7],"m2O"=1,
                  "m1A"=JAK2[1,8], "m1C"=JAK2[2,8], "m1D"=JAK2[3,8], "m1E"=JAK2[4,8], "m1F"=JAK2[5,8],"m1G"=JAK2[6,8],"m1H"=JAK2[7,8],"m1I"=JAK2[8,8],"m1K"=JAK2[9,8],"m1L"=JAK2[10,8],"m1M"=JAK2[11,8],"m1N"=JAK2[12,8],"m1P"=JAK2[13,8],"m1Q"=JAK2[14,8],"m1R"=JAK2[15,8],
                  "m1S"=JAK2[16,8],"m1T"=JAK2[17,8],"m1V"=JAK2[18,8],"m1W"=JAK2[19,8],"m1Y"=JAK2[20,8],"m1O"=1,
                  "d0A"=JAK2[1,9], "d0C"=JAK2[2,9], "d0D"=JAK2[3,9], "d0E"=JAK2[4,9], "d0F"=JAK2[5,9],"d0G"=JAK2[6,9],"d0H"=JAK2[7,9],"d0I"=JAK2[8,9],"d0K"=JAK2[9,9],"d0L"=JAK2[10,9],"d0M"=JAK2[11,9],"d0N"=JAK2[12,9],"d0P"=JAK2[13,9],"d0Q"=JAK2[14,9],"d0R"=JAK2[15,9],
                  "d0S"=JAK2[16,9],"d0T"=JAK2[17,9],"d0V"=JAK2[18,9],"d0W"=JAK2[19,9],"d0Y"=JAK2[20,9],"d0O"=1,
                  "p1A"=JAK2[1,10], "p1C"=JAK2[2,10], "p1D"=JAK2[3,10], "p1E"=JAK2[4,10], "p1F"=JAK2[5,10],"p1G"=JAK2[6,10],"p1H"=JAK2[7,10],"p1I"=JAK2[8,10],"p1K"=JAK2[9,10],"p1L"=JAK2[10,10],"p1M"=JAK2[11,10],"p1N"=JAK2[12,10],"p1P"=JAK2[13,10],"p1Q"=JAK2[14,10],"p1R"=JAK2[15,10],
                  "p1S"=JAK2[16,10],"p1T"=JAK2[17,10],"p1V"=JAK2[18,10],"p1W"=JAK2[19,10],"p1Y"=JAK2[20,10],"p1O"=1,
                  "p2A"=JAK2[1,11], "p2C"=JAK2[2,11], "p2D"=JAK2[3,11], "p2E"=JAK2[4,11], "p2F"=JAK2[5,11],"p2G"=JAK2[6,11],"p2H"=JAK2[7,11],"p2I"=JAK2[8,11],"p2K"=JAK2[9,11],"p2L"=JAK2[10,11],"p2M"=JAK2[11,11],"p2N"=JAK2[12,11],"p2P"=JAK2[13,11],"p2Q"=JAK2[14,11],"p2R"=JAK2[15,11],
                  "p2S"=JAK2[16,11],"p2T"=JAK2[17,11],"p2V"=JAK2[18,11],"p2W"=JAK2[19,11],"p2Y"=JAK2[20,11],"p2O"=1,
                  "p3A"=JAK2[1,12], "p3C"=JAK2[2,12], "p3D"=JAK2[3,12], "p3E"=JAK2[4,12], "p3F"=JAK2[5,12],"p3G"=JAK2[6,12],"p3H"=JAK2[7,12],"p3I"=JAK2[8,12],"p3K"=JAK2[9,12],"p3L"=JAK2[10,12],"p3M"=JAK2[11,12],"p3N"=JAK2[12,12],"p3P"=JAK2[13,12],"p3Q"=JAK2[14,12],"p3R"=JAK2[15,12],
                  "p3S"=JAK2[16,12],"p3T"=JAK2[17,12],"p3V"=JAK2[18,12],"p3W"=JAK2[19,12],"p3Y"=JAK2[20,12],"p3O"=1,
                  "p4A"=JAK2[1,13], "p4C"=JAK2[2,13], "p4D"=JAK2[3,13], "p4E"=JAK2[4,13], "p4F"=JAK2[5,13],"p4G"=JAK2[6,13],"p4H"=JAK2[7,13],"p4I"=JAK2[8,13],"p4K"=JAK2[9,13],"p4L"=JAK2[10,13],"p4M"=JAK2[11,13],"p4N"=JAK2[12,13],"p4P"=JAK2[13,13],"p4Q"=JAK2[14,13],"p4R"=JAK2[15,13],
                  "p4S"=JAK2[16,13],"p4T"=JAK2[17,13],"p4V"=JAK2[18,13],"p4W"=JAK2[19,13],"p4Y"=JAK2[20,13],"p4O"=1,
                  "p5A"=JAK2[1,14], "p5C"=JAK2[2,14], "p5D"=JAK2[3,14], "p5E"=JAK2[4,14], "p5F"=JAK2[5,14],"p5G"=JAK2[6,14],"p5H"=JAK2[7,14],"p5I"=JAK2[8,14],"p5K"=JAK2[9,14],"p5L"=JAK2[10,14],"p5M"=JAK2[11,14],"p5N"=JAK2[12,14],"p5P"=JAK2[13,14],"p5Q"=JAK2[14,14],"p5R"=JAK2[15,14],
                  "p5S"=JAK2[16,14],"p5T"=JAK2[17,14],"p5V"=JAK2[18,14],"p5W"=JAK2[19,14],"p5Y"=JAK2[20,14],"p5O"=1,
                  "p6A"=JAK2[1,15], "p6C"=JAK2[2,15], "p6D"=JAK2[3,15], "p6E"=JAK2[4,15], "p6F"=JAK2[5,15],"p6G"=JAK2[6,15],"p6H"=JAK2[7,15],"p6I"=JAK2[8,15],"p6K"=JAK2[9,15],"p6L"=JAK2[10,15],"p6M"=JAK2[11,15],"p6N"=JAK2[12,15],"p6P"=JAK2[13,15],"p6Q"=JAK2[14,15],"p6R"=JAK2[15,15],
                  "p6S"=JAK2[16,15],"p6T"=JAK2[17,15],"p6V"=JAK2[18,15],"p6W"=JAK2[19,15],"p6Y"=JAK2[20,15],"p6O"=1)
  
  Lck_props <- c("m6A"=Lck[1,3], "m6C"=Lck[2,3], "m6D"=Lck[3,3], "m6E"=Lck[4,3], "m6F"=Lck[5,3],"m6G"=Lck[6,3],"m6H"=Lck[7,3],"m6I"=Lck[8,3],"m6K"=Lck[9,3],"m6L"=Lck[10,3],"m6M"=Lck[11,3],"m6N"=Lck[12,3],"m6P"=Lck[13,3],"m6Q"=Lck[14,3],"m6R"=Lck[15,3],
                 "m6S"=Lck[16,3],"m6T"=Lck[17,3],"m6V"=Lck[18,3],"m6W"=Lck[19,3],"m6Y"=Lck[20,3],"m6O"=1,
                 "m5A"=Lck[1,4], "m5C"=Lck[2,4], "m5D"=Lck[3,4], "m5E"=Lck[4,4], "m5F"=Lck[5,4],"m5G"=Lck[6,4],"m5H"=Lck[7,4],"m5I"=Lck[8,4],"m5K"=Lck[9,4],"m5L"=Lck[10,4],"m5M"=Lck[11,4],"m5N"=Lck[12,4],"m5P"=Lck[13,4],"m5Q"=Lck[14,4],"m5R"=Lck[15,4],
                 "m5S"=Lck[16,4],"m5T"=Lck[17,4],"m5V"=Lck[18,4],"m5W"=Lck[19,4],"m5Y"=Lck[20,4],"m5O"=1,
                 "m4A"=Lck[1,5], "m4C"=Lck[2,5], "m4D"=Lck[3,5], "m4E"=Lck[4,5], "m4F"=Lck[5,5],"m4G"=Lck[6,5],"m4H"=Lck[7,5],"m4I"=Lck[8,5],"m4K"=Lck[9,5],"m4L"=Lck[10,5],"m4M"=Lck[11,5],"m4N"=Lck[12,5],"m4P"=Lck[13,5],"m4Q"=Lck[14,5],"m4R"=Lck[15,5],
                 "m4S"=Lck[16,5],"m4T"=Lck[17,5],"m4V"=Lck[18,5],"m4W"=Lck[19,5],"m4Y"=Lck[20,5],"m4O"=1,
                 "m3A"=Lck[1,6], "m3C"=Lck[2,6], "m3D"=Lck[3,6], "m3E"=Lck[4,6], "m3F"=Lck[5,6],"m3G"=Lck[6,6],"m3H"=Lck[7,6],"m3I"=Lck[8,6],"m3K"=Lck[9,6],"m3L"=Lck[10,6],"m3M"=Lck[11,6],"m3N"=Lck[12,6],"m3P"=Lck[13,6],"m3Q"=Lck[14,6],"m3R"=Lck[15,6],
                 "m3S"=Lck[16,6],"m3T"=Lck[17,6],"m3V"=Lck[18,6],"m3W"=Lck[19,6],"m3Y"=Lck[20,6],"m3O"=1,
                 "m2A"=Lck[1,7], "m2C"=Lck[2,7], "m2D"=Lck[3,7], "m2E"=Lck[4,7], "m2F"=Lck[5,7],"m2G"=Lck[6,7],"m2H"=Lck[7,7],"m2I"=Lck[8,7],"m2K"=Lck[9,7],"m2L"=Lck[10,7],"m2M"=Lck[11,7],"m2N"=Lck[12,7],"m2P"=Lck[13,7],"m2Q"=Lck[14,7],"m2R"=Lck[15,7],
                 "m2S"=Lck[16,7],"m2T"=Lck[17,7],"m2V"=Lck[18,7],"m2W"=Lck[19,7],"m2Y"=Lck[20,7],"m2O"=1,
                 "m1A"=Lck[1,8], "m1C"=Lck[2,8], "m1D"=Lck[3,8], "m1E"=Lck[4,8], "m1F"=Lck[5,8],"m1G"=Lck[6,8],"m1H"=Lck[7,8],"m1I"=Lck[8,8],"m1K"=Lck[9,8],"m1L"=Lck[10,8],"m1M"=Lck[11,8],"m1N"=Lck[12,8],"m1P"=Lck[13,8],"m1Q"=Lck[14,8],"m1R"=Lck[15,8],
                 "m1S"=Lck[16,8],"m1T"=Lck[17,8],"m1V"=Lck[18,8],"m1W"=Lck[19,8],"m1Y"=Lck[20,8],"m1O"=1,
                 "d0A"=Lck[1,9], "d0C"=Lck[2,9], "d0D"=Lck[3,9], "d0E"=Lck[4,9], "d0F"=Lck[5,9],"d0G"=Lck[6,9],"d0H"=Lck[7,9],"d0I"=Lck[8,9],"d0K"=Lck[9,9],"d0L"=Lck[10,9],"d0M"=Lck[11,9],"d0N"=Lck[12,9],"d0P"=Lck[13,9],"d0Q"=Lck[14,9],"d0R"=Lck[15,9],
                 "d0S"=Lck[16,9],"d0T"=Lck[17,9],"d0V"=Lck[18,9],"d0W"=Lck[19,9],"d0Y"=Lck[20,9],"d0O"=1,
                 "p1A"=Lck[1,10], "p1C"=Lck[2,10], "p1D"=Lck[3,10], "p1E"=Lck[4,10], "p1F"=Lck[5,10],"p1G"=Lck[6,10],"p1H"=Lck[7,10],"p1I"=Lck[8,10],"p1K"=Lck[9,10],"p1L"=Lck[10,10],"p1M"=Lck[11,10],"p1N"=Lck[12,10],"p1P"=Lck[13,10],"p1Q"=Lck[14,10],"p1R"=Lck[15,10],
                 "p1S"=Lck[16,10],"p1T"=Lck[17,10],"p1V"=Lck[18,10],"p1W"=Lck[19,10],"p1Y"=Lck[20,10],"p1O"=1,
                 "p2A"=Lck[1,11], "p2C"=Lck[2,11], "p2D"=Lck[3,11], "p2E"=Lck[4,11], "p2F"=Lck[5,11],"p2G"=Lck[6,11],"p2H"=Lck[7,11],"p2I"=Lck[8,11],"p2K"=Lck[9,11],"p2L"=Lck[10,11],"p2M"=Lck[11,11],"p2N"=Lck[12,11],"p2P"=Lck[13,11],"p2Q"=Lck[14,11],"p2R"=Lck[15,11],
                 "p2S"=Lck[16,11],"p2T"=Lck[17,11],"p2V"=Lck[18,11],"p2W"=Lck[19,11],"p2Y"=Lck[20,11],"p2O"=1,
                 "p3A"=Lck[1,12], "p3C"=Lck[2,12], "p3D"=Lck[3,12], "p3E"=Lck[4,12], "p3F"=Lck[5,12],"p3G"=Lck[6,12],"p3H"=Lck[7,12],"p3I"=Lck[8,12],"p3K"=Lck[9,12],"p3L"=Lck[10,12],"p3M"=Lck[11,12],"p3N"=Lck[12,12],"p3P"=Lck[13,12],"p3Q"=Lck[14,12],"p3R"=Lck[15,12],
                 "p3S"=Lck[16,12],"p3T"=Lck[17,12],"p3V"=Lck[18,12],"p3W"=Lck[19,12],"p3Y"=Lck[20,12],"p3O"=1,
                 "p4A"=Lck[1,13], "p4C"=Lck[2,13], "p4D"=Lck[3,13], "p4E"=Lck[4,13], "p4F"=Lck[5,13],"p4G"=Lck[6,13],"p4H"=Lck[7,13],"p4I"=Lck[8,13],"p4K"=Lck[9,13],"p4L"=Lck[10,13],"p4M"=Lck[11,13],"p4N"=Lck[12,13],"p4P"=Lck[13,13],"p4Q"=Lck[14,13],"p4R"=Lck[15,13],
                 "p4S"=Lck[16,13],"p4T"=Lck[17,13],"p4V"=Lck[18,13],"p4W"=Lck[19,13],"p4Y"=Lck[20,13],"p4O"=1,
                 "p5A"=Lck[1,14], "p5C"=Lck[2,14], "p5D"=Lck[3,14], "p5E"=Lck[4,14], "p5F"=Lck[5,14],"p5G"=Lck[6,14],"p5H"=Lck[7,14],"p5I"=Lck[8,14],"p5K"=Lck[9,14],"p5L"=Lck[10,14],"p5M"=Lck[11,14],"p5N"=Lck[12,14],"p5P"=Lck[13,14],"p5Q"=Lck[14,14],"p5R"=Lck[15,14],
                 "p5S"=Lck[16,14],"p5T"=Lck[17,14],"p5V"=Lck[18,14],"p5W"=Lck[19,14],"p5Y"=Lck[20,14],"p5O"=1,
                 "p6A"=Lck[1,15], "p6C"=Lck[2,15], "p6D"=Lck[3,15], "p6E"=Lck[4,15], "p6F"=Lck[5,15],"p6G"=Lck[6,15],"p6H"=Lck[7,15],"p6I"=Lck[8,15],"p6K"=Lck[9,15],"p6L"=Lck[10,15],"p6M"=Lck[11,15],"p6N"=Lck[12,15],"p6P"=Lck[13,15],"p6Q"=Lck[14,15],"p6R"=Lck[15,15],
                 "p6S"=Lck[16,15],"p6T"=Lck[17,15],"p6V"=Lck[18,15],"p6W"=Lck[19,15],"p6Y"=Lck[20,15],"p6O"=1)
  
  Lyn_props <- c("m6A"=Lyn[1,3], "m6C"=Lyn[2,3], "m6D"=Lyn[3,3], "m6E"=Lyn[4,3], "m6F"=Lyn[5,3],"m6G"=Lyn[6,3],"m6H"=Lyn[7,3],"m6I"=Lyn[8,3],"m6K"=Lyn[9,3],"m6L"=Lyn[10,3],"m6M"=Lyn[11,3],"m6N"=Lyn[12,3],"m6P"=Lyn[13,3],"m6Q"=Lyn[14,3],"m6R"=Lyn[15,3],
                 "m6S"=Lyn[16,3],"m6T"=Lyn[17,3],"m6V"=Lyn[18,3],"m6W"=Lyn[19,3],"m6Y"=Lyn[20,3],"m6O"=1,
                 "m5A"=Lyn[1,4], "m5C"=Lyn[2,4], "m5D"=Lyn[3,4], "m5E"=Lyn[4,4], "m5F"=Lyn[5,4],"m5G"=Lyn[6,4],"m5H"=Lyn[7,4],"m5I"=Lyn[8,4],"m5K"=Lyn[9,4],"m5L"=Lyn[10,4],"m5M"=Lyn[11,4],"m5N"=Lyn[12,4],"m5P"=Lyn[13,4],"m5Q"=Lyn[14,4],"m5R"=Lyn[15,4],
                 "m5S"=Lyn[16,4],"m5T"=Lyn[17,4],"m5V"=Lyn[18,4],"m5W"=Lyn[19,4],"m5Y"=Lyn[20,4],"m5O"=1,
                 "m4A"=Lyn[1,5], "m4C"=Lyn[2,5], "m4D"=Lyn[3,5], "m4E"=Lyn[4,5], "m4F"=Lyn[5,5],"m4G"=Lyn[6,5],"m4H"=Lyn[7,5],"m4I"=Lyn[8,5],"m4K"=Lyn[9,5],"m4L"=Lyn[10,5],"m4M"=Lyn[11,5],"m4N"=Lyn[12,5],"m4P"=Lyn[13,5],"m4Q"=Lyn[14,5],"m4R"=Lyn[15,5],
                 "m4S"=Lyn[16,5],"m4T"=Lyn[17,5],"m4V"=Lyn[18,5],"m4W"=Lyn[19,5],"m4Y"=Lyn[20,5],"m4O"=1,
                 "m3A"=Lyn[1,6], "m3C"=Lyn[2,6], "m3D"=Lyn[3,6], "m3E"=Lyn[4,6], "m3F"=Lyn[5,6],"m3G"=Lyn[6,6],"m3H"=Lyn[7,6],"m3I"=Lyn[8,6],"m3K"=Lyn[9,6],"m3L"=Lyn[10,6],"m3M"=Lyn[11,6],"m3N"=Lyn[12,6],"m3P"=Lyn[13,6],"m3Q"=Lyn[14,6],"m3R"=Lyn[15,6],
                 "m3S"=Lyn[16,6],"m3T"=Lyn[17,6],"m3V"=Lyn[18,6],"m3W"=Lyn[19,6],"m3Y"=Lyn[20,6],"m3O"=1,
                 "m2A"=Lyn[1,7], "m2C"=Lyn[2,7], "m2D"=Lyn[3,7], "m2E"=Lyn[4,7], "m2F"=Lyn[5,7],"m2G"=Lyn[6,7],"m2H"=Lyn[7,7],"m2I"=Lyn[8,7],"m2K"=Lyn[9,7],"m2L"=Lyn[10,7],"m2M"=Lyn[11,7],"m2N"=Lyn[12,7],"m2P"=Lyn[13,7],"m2Q"=Lyn[14,7],"m2R"=Lyn[15,7],
                 "m2S"=Lyn[16,7],"m2T"=Lyn[17,7],"m2V"=Lyn[18,7],"m2W"=Lyn[19,7],"m2Y"=Lyn[20,7],"m2O"=1,
                 "m1A"=Lyn[1,8], "m1C"=Lyn[2,8], "m1D"=Lyn[3,8], "m1E"=Lyn[4,8], "m1F"=Lyn[5,8],"m1G"=Lyn[6,8],"m1H"=Lyn[7,8],"m1I"=Lyn[8,8],"m1K"=Lyn[9,8],"m1L"=Lyn[10,8],"m1M"=Lyn[11,8],"m1N"=Lyn[12,8],"m1P"=Lyn[13,8],"m1Q"=Lyn[14,8],"m1R"=Lyn[15,8],
                 "m1S"=Lyn[16,8],"m1T"=Lyn[17,8],"m1V"=Lyn[18,8],"m1W"=Lyn[19,8],"m1Y"=Lyn[20,8],"m1O"=1,
                 "d0A"=Lyn[1,9], "d0C"=Lyn[2,9], "d0D"=Lyn[3,9], "d0E"=Lyn[4,9], "d0F"=Lyn[5,9],"d0G"=Lyn[6,9],"d0H"=Lyn[7,9],"d0I"=Lyn[8,9],"d0K"=Lyn[9,9],"d0L"=Lyn[10,9],"d0M"=Lyn[11,9],"d0N"=Lyn[12,9],"d0P"=Lyn[13,9],"d0Q"=Lyn[14,9],"d0R"=Lyn[15,9],
                 "d0S"=Lyn[16,9],"d0T"=Lyn[17,9],"d0V"=Lyn[18,9],"d0W"=Lyn[19,9],"d0Y"=Lyn[20,9],"d0O"=1,
                 "p1A"=Lyn[1,10], "p1C"=Lyn[2,10], "p1D"=Lyn[3,10], "p1E"=Lyn[4,10], "p1F"=Lyn[5,10],"p1G"=Lyn[6,10],"p1H"=Lyn[7,10],"p1I"=Lyn[8,10],"p1K"=Lyn[9,10],"p1L"=Lyn[10,10],"p1M"=Lyn[11,10],"p1N"=Lyn[12,10],"p1P"=Lyn[13,10],"p1Q"=Lyn[14,10],"p1R"=Lyn[15,10],
                 "p1S"=Lyn[16,10],"p1T"=Lyn[17,10],"p1V"=Lyn[18,10],"p1W"=Lyn[19,10],"p1Y"=Lyn[20,10],"p1O"=1,
                 "p2A"=Lyn[1,11], "p2C"=Lyn[2,11], "p2D"=Lyn[3,11], "p2E"=Lyn[4,11], "p2F"=Lyn[5,11],"p2G"=Lyn[6,11],"p2H"=Lyn[7,11],"p2I"=Lyn[8,11],"p2K"=Lyn[9,11],"p2L"=Lyn[10,11],"p2M"=Lyn[11,11],"p2N"=Lyn[12,11],"p2P"=Lyn[13,11],"p2Q"=Lyn[14,11],"p2R"=Lyn[15,11],
                 "p2S"=Lyn[16,11],"p2T"=Lyn[17,11],"p2V"=Lyn[18,11],"p2W"=Lyn[19,11],"p2Y"=Lyn[20,11],"p2O"=1,
                 "p3A"=Lyn[1,12], "p3C"=Lyn[2,12], "p3D"=Lyn[3,12], "p3E"=Lyn[4,12], "p3F"=Lyn[5,12],"p3G"=Lyn[6,12],"p3H"=Lyn[7,12],"p3I"=Lyn[8,12],"p3K"=Lyn[9,12],"p3L"=Lyn[10,12],"p3M"=Lyn[11,12],"p3N"=Lyn[12,12],"p3P"=Lyn[13,12],"p3Q"=Lyn[14,12],"p3R"=Lyn[15,12],
                 "p3S"=Lyn[16,12],"p3T"=Lyn[17,12],"p3V"=Lyn[18,12],"p3W"=Lyn[19,12],"p3Y"=Lyn[20,12],"p3O"=1,
                 "p4A"=Lyn[1,13], "p4C"=Lyn[2,13], "p4D"=Lyn[3,13], "p4E"=Lyn[4,13], "p4F"=Lyn[5,13],"p4G"=Lyn[6,13],"p4H"=Lyn[7,13],"p4I"=Lyn[8,13],"p4K"=Lyn[9,13],"p4L"=Lyn[10,13],"p4M"=Lyn[11,13],"p4N"=Lyn[12,13],"p4P"=Lyn[13,13],"p4Q"=Lyn[14,13],"p4R"=Lyn[15,13],
                 "p4S"=Lyn[16,13],"p4T"=Lyn[17,13],"p4V"=Lyn[18,13],"p4W"=Lyn[19,13],"p4Y"=Lyn[20,13],"p4O"=1,
                 "p5A"=Lyn[1,14], "p5C"=Lyn[2,14], "p5D"=Lyn[3,14], "p5E"=Lyn[4,14], "p5F"=Lyn[5,14],"p5G"=Lyn[6,14],"p5H"=Lyn[7,14],"p5I"=Lyn[8,14],"p5K"=Lyn[9,14],"p5L"=Lyn[10,14],"p5M"=Lyn[11,14],"p5N"=Lyn[12,14],"p5P"=Lyn[13,14],"p5Q"=Lyn[14,14],"p5R"=Lyn[15,14],
                 "p5S"=Lyn[16,14],"p5T"=Lyn[17,14],"p5V"=Lyn[18,14],"p5W"=Lyn[19,14],"p5Y"=Lyn[20,14],"p5O"=1,
                 "p6A"=Lyn[1,15], "p6C"=Lyn[2,15], "p6D"=Lyn[3,15], "p6E"=Lyn[4,15], "p6F"=Lyn[5,15],"p6G"=Lyn[6,15],"p6H"=Lyn[7,15],"p6I"=Lyn[8,15],"p6K"=Lyn[9,15],"p6L"=Lyn[10,15],"p6M"=Lyn[11,15],"p6N"=Lyn[12,15],"p6P"=Lyn[13,15],"p6Q"=Lyn[14,15],"p6R"=Lyn[15,15],
                 "p6S"=Lyn[16,15],"p6T"=Lyn[17,15],"p6V"=Lyn[18,15],"p6W"=Lyn[19,15],"p6Y"=Lyn[20,15],"p6O"=1)
  
  Pyk2_props <- c("m6A"=Pyk2[1,3], "m6C"=Pyk2[2,3], "m6D"=Pyk2[3,3], "m6E"=Pyk2[4,3], "m6F"=Pyk2[5,3],"m6G"=Pyk2[6,3],"m6H"=Pyk2[7,3],"m6I"=Pyk2[8,3],"m6K"=Pyk2[9,3],"m6L"=Pyk2[10,3],"m6M"=Pyk2[11,3],"m6N"=Pyk2[12,3],"m6P"=Pyk2[13,3],"m6Q"=Pyk2[14,3],"m6R"=Pyk2[15,3],
                  "m6S"=Pyk2[16,3],"m6T"=Pyk2[17,3],"m6V"=Pyk2[18,3],"m6W"=Pyk2[19,3],"m6Y"=Pyk2[20,3],"m6O"=1,
                  "m5A"=Pyk2[1,4], "m5C"=Pyk2[2,4], "m5D"=Pyk2[3,4], "m5E"=Pyk2[4,4], "m5F"=Pyk2[5,4],"m5G"=Pyk2[6,4],"m5H"=Pyk2[7,4],"m5I"=Pyk2[8,4],"m5K"=Pyk2[9,4],"m5L"=Pyk2[10,4],"m5M"=Pyk2[11,4],"m5N"=Pyk2[12,4],"m5P"=Pyk2[13,4],"m5Q"=Pyk2[14,4],"m5R"=Pyk2[15,4],
                  "m5S"=Pyk2[16,4],"m5T"=Pyk2[17,4],"m5V"=Pyk2[18,4],"m5W"=Pyk2[19,4],"m5Y"=Pyk2[20,4],"m5O"=1,
                  "m4A"=Pyk2[1,5], "m4C"=Pyk2[2,5], "m4D"=Pyk2[3,5], "m4E"=Pyk2[4,5], "m4F"=Pyk2[5,5],"m4G"=Pyk2[6,5],"m4H"=Pyk2[7,5],"m4I"=Pyk2[8,5],"m4K"=Pyk2[9,5],"m4L"=Pyk2[10,5],"m4M"=Pyk2[11,5],"m4N"=Pyk2[12,5],"m4P"=Pyk2[13,5],"m4Q"=Pyk2[14,5],"m4R"=Pyk2[15,5],
                  "m4S"=Pyk2[16,5],"m4T"=Pyk2[17,5],"m4V"=Pyk2[18,5],"m4W"=Pyk2[19,5],"m4Y"=Pyk2[20,5],"m4O"=1,
                  "m3A"=Pyk2[1,6], "m3C"=Pyk2[2,6], "m3D"=Pyk2[3,6], "m3E"=Pyk2[4,6], "m3F"=Pyk2[5,6],"m3G"=Pyk2[6,6],"m3H"=Pyk2[7,6],"m3I"=Pyk2[8,6],"m3K"=Pyk2[9,6],"m3L"=Pyk2[10,6],"m3M"=Pyk2[11,6],"m3N"=Pyk2[12,6],"m3P"=Pyk2[13,6],"m3Q"=Pyk2[14,6],"m3R"=Pyk2[15,6],
                  "m3S"=Pyk2[16,6],"m3T"=Pyk2[17,6],"m3V"=Pyk2[18,6],"m3W"=Pyk2[19,6],"m3Y"=Pyk2[20,6],"m3O"=1,
                  "m2A"=Pyk2[1,7], "m2C"=Pyk2[2,7], "m2D"=Pyk2[3,7], "m2E"=Pyk2[4,7], "m2F"=Pyk2[5,7],"m2G"=Pyk2[6,7],"m2H"=Pyk2[7,7],"m2I"=Pyk2[8,7],"m2K"=Pyk2[9,7],"m2L"=Pyk2[10,7],"m2M"=Pyk2[11,7],"m2N"=Pyk2[12,7],"m2P"=Pyk2[13,7],"m2Q"=Pyk2[14,7],"m2R"=Pyk2[15,7],
                  "m2S"=Pyk2[16,7],"m2T"=Pyk2[17,7],"m2V"=Pyk2[18,7],"m2W"=Pyk2[19,7],"m2Y"=Pyk2[20,7],"m2O"=1,
                  "m1A"=Pyk2[1,8], "m1C"=Pyk2[2,8], "m1D"=Pyk2[3,8], "m1E"=Pyk2[4,8], "m1F"=Pyk2[5,8],"m1G"=Pyk2[6,8],"m1H"=Pyk2[7,8],"m1I"=Pyk2[8,8],"m1K"=Pyk2[9,8],"m1L"=Pyk2[10,8],"m1M"=Pyk2[11,8],"m1N"=Pyk2[12,8],"m1P"=Pyk2[13,8],"m1Q"=Pyk2[14,8],"m1R"=Pyk2[15,8],
                  "m1S"=Pyk2[16,8],"m1T"=Pyk2[17,8],"m1V"=Pyk2[18,8],"m1W"=Pyk2[19,8],"m1Y"=Pyk2[20,8],"m1O"=1,
                  "d0A"=Pyk2[1,9], "d0C"=Pyk2[2,9], "d0D"=Pyk2[3,9], "d0E"=Pyk2[4,9], "d0F"=Pyk2[5,9],"d0G"=Pyk2[6,9],"d0H"=Pyk2[7,9],"d0I"=Pyk2[8,9],"d0K"=Pyk2[9,9],"d0L"=Pyk2[10,9],"d0M"=Pyk2[11,9],"d0N"=Pyk2[12,9],"d0P"=Pyk2[13,9],"d0Q"=Pyk2[14,9],"d0R"=Pyk2[15,9],
                  "d0S"=Pyk2[16,9],"d0T"=Pyk2[17,9],"d0V"=Pyk2[18,9],"d0W"=Pyk2[19,9],"d0Y"=Pyk2[20,9],"d0O"=1,
                  "p1A"=Pyk2[1,10], "p1C"=Pyk2[2,10], "p1D"=Pyk2[3,10], "p1E"=Pyk2[4,10], "p1F"=Pyk2[5,10],"p1G"=Pyk2[6,10],"p1H"=Pyk2[7,10],"p1I"=Pyk2[8,10],"p1K"=Pyk2[9,10],"p1L"=Pyk2[10,10],"p1M"=Pyk2[11,10],"p1N"=Pyk2[12,10],"p1P"=Pyk2[13,10],"p1Q"=Pyk2[14,10],"p1R"=Pyk2[15,10],
                  "p1S"=Pyk2[16,10],"p1T"=Pyk2[17,10],"p1V"=Pyk2[18,10],"p1W"=Pyk2[19,10],"p1Y"=Pyk2[20,10],"p1O"=1,
                  "p2A"=Pyk2[1,11], "p2C"=Pyk2[2,11], "p2D"=Pyk2[3,11], "p2E"=Pyk2[4,11], "p2F"=Pyk2[5,11],"p2G"=Pyk2[6,11],"p2H"=Pyk2[7,11],"p2I"=Pyk2[8,11],"p2K"=Pyk2[9,11],"p2L"=Pyk2[10,11],"p2M"=Pyk2[11,11],"p2N"=Pyk2[12,11],"p2P"=Pyk2[13,11],"p2Q"=Pyk2[14,11],"p2R"=Pyk2[15,11],
                  "p2S"=Pyk2[16,11],"p2T"=Pyk2[17,11],"p2V"=Pyk2[18,11],"p2W"=Pyk2[19,11],"p2Y"=Pyk2[20,11],"p2O"=1,
                  "p3A"=Pyk2[1,12], "p3C"=Pyk2[2,12], "p3D"=Pyk2[3,12], "p3E"=Pyk2[4,12], "p3F"=Pyk2[5,12],"p3G"=Pyk2[6,12],"p3H"=Pyk2[7,12],"p3I"=Pyk2[8,12],"p3K"=Pyk2[9,12],"p3L"=Pyk2[10,12],"p3M"=Pyk2[11,12],"p3N"=Pyk2[12,12],"p3P"=Pyk2[13,12],"p3Q"=Pyk2[14,12],"p3R"=Pyk2[15,12],
                  "p3S"=Pyk2[16,12],"p3T"=Pyk2[17,12],"p3V"=Pyk2[18,12],"p3W"=Pyk2[19,12],"p3Y"=Pyk2[20,12],"p3O"=1,
                  "p4A"=Pyk2[1,13], "p4C"=Pyk2[2,13], "p4D"=Pyk2[3,13], "p4E"=Pyk2[4,13], "p4F"=Pyk2[5,13],"p4G"=Pyk2[6,13],"p4H"=Pyk2[7,13],"p4I"=Pyk2[8,13],"p4K"=Pyk2[9,13],"p4L"=Pyk2[10,13],"p4M"=Pyk2[11,13],"p4N"=Pyk2[12,13],"p4P"=Pyk2[13,13],"p4Q"=Pyk2[14,13],"p4R"=Pyk2[15,13],
                  "p4S"=Pyk2[16,13],"p4T"=Pyk2[17,13],"p4V"=Pyk2[18,13],"p4W"=Pyk2[19,13],"p4Y"=Pyk2[20,13],"p4O"=1,
                  "p5A"=Pyk2[1,14], "p5C"=Pyk2[2,14], "p5D"=Pyk2[3,14], "p5E"=Pyk2[4,14], "p5F"=Pyk2[5,14],"p5G"=Pyk2[6,14],"p5H"=Pyk2[7,14],"p5I"=Pyk2[8,14],"p5K"=Pyk2[9,14],"p5L"=Pyk2[10,14],"p5M"=Pyk2[11,14],"p5N"=Pyk2[12,14],"p5P"=Pyk2[13,14],"p5Q"=Pyk2[14,14],"p5R"=Pyk2[15,14],
                  "p5S"=Pyk2[16,14],"p5T"=Pyk2[17,14],"p5V"=Pyk2[18,14],"p5W"=Pyk2[19,14],"p5Y"=Pyk2[20,14],"p5O"=1,
                  "p6A"=Pyk2[1,15], "p6C"=Pyk2[2,15], "p6D"=Pyk2[3,15], "p6E"=Pyk2[4,15], "p6F"=Pyk2[5,15],"p6G"=Pyk2[6,15],"p6H"=Pyk2[7,15],"p6I"=Pyk2[8,15],"p6K"=Pyk2[9,15],"p6L"=Pyk2[10,15],"p6M"=Pyk2[11,15],"p6N"=Pyk2[12,15],"p6P"=Pyk2[13,15],"p6Q"=Pyk2[14,15],"p6R"=Pyk2[15,15],
                  "p6S"=Pyk2[16,15],"p6T"=Pyk2[17,15],"p6V"=Pyk2[18,15],"p6W"=Pyk2[19,15],"p6Y"=Pyk2[20,15],"p6O"=1)
  
  Src_props <- c("m6A"=Src[1,3], "m6C"=Src[2,3], "m6D"=Src[3,3], "m6E"=Src[4,3], "m6F"=Src[5,3],"m6G"=Src[6,3],"m6H"=Src[7,3],"m6I"=Src[8,3],"m6K"=Src[9,3],"m6L"=Src[10,3],"m6M"=Src[11,3],"m6N"=Src[12,3],"m6P"=Src[13,3],"m6Q"=Src[14,3],"m6R"=Src[15,3],
                 "m6S"=Src[16,3],"m6T"=Src[17,3],"m6V"=Src[18,3],"m6W"=Src[19,3],"m6Y"=Src[20,3],"m6O"=1,
                 "m5A"=Src[1,4], "m5C"=Src[2,4], "m5D"=Src[3,4], "m5E"=Src[4,4], "m5F"=Src[5,4],"m5G"=Src[6,4],"m5H"=Src[7,4],"m5I"=Src[8,4],"m5K"=Src[9,4],"m5L"=Src[10,4],"m5M"=Src[11,4],"m5N"=Src[12,4],"m5P"=Src[13,4],"m5Q"=Src[14,4],"m5R"=Src[15,4],
                 "m5S"=Src[16,4],"m5T"=Src[17,4],"m5V"=Src[18,4],"m5W"=Src[19,4],"m5Y"=Src[20,4],"m5O"=1,
                 "m4A"=Src[1,5], "m4C"=Src[2,5], "m4D"=Src[3,5], "m4E"=Src[4,5], "m4F"=Src[5,5],"m4G"=Src[6,5],"m4H"=Src[7,5],"m4I"=Src[8,5],"m4K"=Src[9,5],"m4L"=Src[10,5],"m4M"=Src[11,5],"m4N"=Src[12,5],"m4P"=Src[13,5],"m4Q"=Src[14,5],"m4R"=Src[15,5],
                 "m4S"=Src[16,5],"m4T"=Src[17,5],"m4V"=Src[18,5],"m4W"=Src[19,5],"m4Y"=Src[20,5],"m4O"=1,
                 "m3A"=Src[1,6], "m3C"=Src[2,6], "m3D"=Src[3,6], "m3E"=Src[4,6], "m3F"=Src[5,6],"m3G"=Src[6,6],"m3H"=Src[7,6],"m3I"=Src[8,6],"m3K"=Src[9,6],"m3L"=Src[10,6],"m3M"=Src[11,6],"m3N"=Src[12,6],"m3P"=Src[13,6],"m3Q"=Src[14,6],"m3R"=Src[15,6],
                 "m3S"=Src[16,6],"m3T"=Src[17,6],"m3V"=Src[18,6],"m3W"=Src[19,6],"m3Y"=Src[20,6],"m3O"=1,
                 "m2A"=Src[1,7], "m2C"=Src[2,7], "m2D"=Src[3,7], "m2E"=Src[4,7], "m2F"=Src[5,7],"m2G"=Src[6,7],"m2H"=Src[7,7],"m2I"=Src[8,7],"m2K"=Src[9,7],"m2L"=Src[10,7],"m2M"=Src[11,7],"m2N"=Src[12,7],"m2P"=Src[13,7],"m2Q"=Src[14,7],"m2R"=Src[15,7],
                 "m2S"=Src[16,7],"m2T"=Src[17,7],"m2V"=Src[18,7],"m2W"=Src[19,7],"m2Y"=Src[20,7],"m2O"=1,
                 "m1A"=Src[1,8], "m1C"=Src[2,8], "m1D"=Src[3,8], "m1E"=Src[4,8], "m1F"=Src[5,8],"m1G"=Src[6,8],"m1H"=Src[7,8],"m1I"=Src[8,8],"m1K"=Src[9,8],"m1L"=Src[10,8],"m1M"=Src[11,8],"m1N"=Src[12,8],"m1P"=Src[13,8],"m1Q"=Src[14,8],"m1R"=Src[15,8],
                 "m1S"=Src[16,8],"m1T"=Src[17,8],"m1V"=Src[18,8],"m1W"=Src[19,8],"m1Y"=Src[20,8],"m1O"=1,
                 "d0A"=Src[1,9], "d0C"=Src[2,9], "d0D"=Src[3,9], "d0E"=Src[4,9], "d0F"=Src[5,9],"d0G"=Src[6,9],"d0H"=Src[7,9],"d0I"=Src[8,9],"d0K"=Src[9,9],"d0L"=Src[10,9],"d0M"=Src[11,9],"d0N"=Src[12,9],"d0P"=Src[13,9],"d0Q"=Src[14,9],"d0R"=Src[15,9],
                 "d0S"=Src[16,9],"d0T"=Src[17,9],"d0V"=Src[18,9],"d0W"=Src[19,9],"d0Y"=Src[20,9],"d0O"=1,
                 "p1A"=Src[1,10], "p1C"=Src[2,10], "p1D"=Src[3,10], "p1E"=Src[4,10], "p1F"=Src[5,10],"p1G"=Src[6,10],"p1H"=Src[7,10],"p1I"=Src[8,10],"p1K"=Src[9,10],"p1L"=Src[10,10],"p1M"=Src[11,10],"p1N"=Src[12,10],"p1P"=Src[13,10],"p1Q"=Src[14,10],"p1R"=Src[15,10],
                 "p1S"=Src[16,10],"p1T"=Src[17,10],"p1V"=Src[18,10],"p1W"=Src[19,10],"p1Y"=Src[20,10],"p1O"=1,
                 "p2A"=Src[1,11], "p2C"=Src[2,11], "p2D"=Src[3,11], "p2E"=Src[4,11], "p2F"=Src[5,11],"p2G"=Src[6,11],"p2H"=Src[7,11],"p2I"=Src[8,11],"p2K"=Src[9,11],"p2L"=Src[10,11],"p2M"=Src[11,11],"p2N"=Src[12,11],"p2P"=Src[13,11],"p2Q"=Src[14,11],"p2R"=Src[15,11],
                 "p2S"=Src[16,11],"p2T"=Src[17,11],"p2V"=Src[18,11],"p2W"=Src[19,11],"p2Y"=Src[20,11],"p2O"=1,
                 "p3A"=Src[1,12], "p3C"=Src[2,12], "p3D"=Src[3,12], "p3E"=Src[4,12], "p3F"=Src[5,12],"p3G"=Src[6,12],"p3H"=Src[7,12],"p3I"=Src[8,12],"p3K"=Src[9,12],"p3L"=Src[10,12],"p3M"=Src[11,12],"p3N"=Src[12,12],"p3P"=Src[13,12],"p3Q"=Src[14,12],"p3R"=Src[15,12],
                 "p3S"=Src[16,12],"p3T"=Src[17,12],"p3V"=Src[18,12],"p3W"=Src[19,12],"p3Y"=Src[20,12],"p3O"=1,
                 "p4A"=Src[1,13], "p4C"=Src[2,13], "p4D"=Src[3,13], "p4E"=Src[4,13], "p4F"=Src[5,13],"p4G"=Src[6,13],"p4H"=Src[7,13],"p4I"=Src[8,13],"p4K"=Src[9,13],"p4L"=Src[10,13],"p4M"=Src[11,13],"p4N"=Src[12,13],"p4P"=Src[13,13],"p4Q"=Src[14,13],"p4R"=Src[15,13],
                 "p4S"=Src[16,13],"p4T"=Src[17,13],"p4V"=Src[18,13],"p4W"=Src[19,13],"p4Y"=Src[20,13],"p4O"=1,
                 "p5A"=Src[1,14], "p5C"=Src[2,14], "p5D"=Src[3,14], "p5E"=Src[4,14], "p5F"=Src[5,14],"p5G"=Src[6,14],"p5H"=Src[7,14],"p5I"=Src[8,14],"p5K"=Src[9,14],"p5L"=Src[10,14],"p5M"=Src[11,14],"p5N"=Src[12,14],"p5P"=Src[13,14],"p5Q"=Src[14,14],"p5R"=Src[15,14],
                 "p5S"=Src[16,14],"p5T"=Src[17,14],"p5V"=Src[18,14],"p5W"=Src[19,14],"p5Y"=Src[20,14],"p5O"=1,
                 "p6A"=Src[1,15], "p6C"=Src[2,15], "p6D"=Src[3,15], "p6E"=Src[4,15], "p6F"=Src[5,15],"p6G"=Src[6,15],"p6H"=Src[7,15],"p6I"=Src[8,15],"p6K"=Src[9,15],"p6L"=Src[10,15],"p6M"=Src[11,15],"p6N"=Src[12,15],"p6P"=Src[13,15],"p6Q"=Src[14,15],"p6R"=Src[15,15],
                 "p6S"=Src[16,15],"p6T"=Src[17,15],"p6V"=Src[18,15],"p6W"=Src[19,15],"p6Y"=Src[20,15],"p6O"=1)
  
  Syk_props <- c("m6A"=Syk[1,3], "m6C"=Syk[2,3], "m6D"=Syk[3,3], "m6E"=Syk[4,3], "m6F"=Syk[5,3],"m6G"=Syk[6,3],"m6H"=Syk[7,3],"m6I"=Syk[8,3],"m6K"=Syk[9,3],"m6L"=Syk[10,3],"m6M"=Syk[11,3],"m6N"=Syk[12,3],"m6P"=Syk[13,3],"m6Q"=Syk[14,3],"m6R"=Syk[15,3],
                 "m6S"=Syk[16,3],"m6T"=Syk[17,3],"m6V"=Syk[18,3],"m6W"=Syk[19,3],"m6Y"=Syk[20,3],"m6O"=1,
                 "m5A"=Syk[1,4], "m5C"=Syk[2,4], "m5D"=Syk[3,4], "m5E"=Syk[4,4], "m5F"=Syk[5,4],"m5G"=Syk[6,4],"m5H"=Syk[7,4],"m5I"=Syk[8,4],"m5K"=Syk[9,4],"m5L"=Syk[10,4],"m5M"=Syk[11,4],"m5N"=Syk[12,4],"m5P"=Syk[13,4],"m5Q"=Syk[14,4],"m5R"=Syk[15,4],
                 "m5S"=Syk[16,4],"m5T"=Syk[17,4],"m5V"=Syk[18,4],"m5W"=Syk[19,4],"m5Y"=Syk[20,4],"m5O"=1,
                 "m4A"=Syk[1,5], "m4C"=Syk[2,5], "m4D"=Syk[3,5], "m4E"=Syk[4,5], "m4F"=Syk[5,5],"m4G"=Syk[6,5],"m4H"=Syk[7,5],"m4I"=Syk[8,5],"m4K"=Syk[9,5],"m4L"=Syk[10,5],"m4M"=Syk[11,5],"m4N"=Syk[12,5],"m4P"=Syk[13,5],"m4Q"=Syk[14,5],"m4R"=Syk[15,5],
                 "m4S"=Syk[16,5],"m4T"=Syk[17,5],"m4V"=Syk[18,5],"m4W"=Syk[19,5],"m4Y"=Syk[20,5],"m4O"=1,
                 "m3A"=Syk[1,6], "m3C"=Syk[2,6], "m3D"=Syk[3,6], "m3E"=Syk[4,6], "m3F"=Syk[5,6],"m3G"=Syk[6,6],"m3H"=Syk[7,6],"m3I"=Syk[8,6],"m3K"=Syk[9,6],"m3L"=Syk[10,6],"m3M"=Syk[11,6],"m3N"=Syk[12,6],"m3P"=Syk[13,6],"m3Q"=Syk[14,6],"m3R"=Syk[15,6],
                 "m3S"=Syk[16,6],"m3T"=Syk[17,6],"m3V"=Syk[18,6],"m3W"=Syk[19,6],"m3Y"=Syk[20,6],"m3O"=1,
                 "m2A"=Syk[1,7], "m2C"=Syk[2,7], "m2D"=Syk[3,7], "m2E"=Syk[4,7], "m2F"=Syk[5,7],"m2G"=Syk[6,7],"m2H"=Syk[7,7],"m2I"=Syk[8,7],"m2K"=Syk[9,7],"m2L"=Syk[10,7],"m2M"=Syk[11,7],"m2N"=Syk[12,7],"m2P"=Syk[13,7],"m2Q"=Syk[14,7],"m2R"=Syk[15,7],
                 "m2S"=Syk[16,7],"m2T"=Syk[17,7],"m2V"=Syk[18,7],"m2W"=Syk[19,7],"m2Y"=Syk[20,7],"m2O"=1,
                 "m1A"=Syk[1,8], "m1C"=Syk[2,8], "m1D"=Syk[3,8], "m1E"=Syk[4,8], "m1F"=Syk[5,8],"m1G"=Syk[6,8],"m1H"=Syk[7,8],"m1I"=Syk[8,8],"m1K"=Syk[9,8],"m1L"=Syk[10,8],"m1M"=Syk[11,8],"m1N"=Syk[12,8],"m1P"=Syk[13,8],"m1Q"=Syk[14,8],"m1R"=Syk[15,8],
                 "m1S"=Syk[16,8],"m1T"=Syk[17,8],"m1V"=Syk[18,8],"m1W"=Syk[19,8],"m1Y"=Syk[20,8],"m1O"=1,
                 "d0A"=Syk[1,9], "d0C"=Syk[2,9], "d0D"=Syk[3,9], "d0E"=Syk[4,9], "d0F"=Syk[5,9],"d0G"=Syk[6,9],"d0H"=Syk[7,9],"d0I"=Syk[8,9],"d0K"=Syk[9,9],"d0L"=Syk[10,9],"d0M"=Syk[11,9],"d0N"=Syk[12,9],"d0P"=Syk[13,9],"d0Q"=Syk[14,9],"d0R"=Syk[15,9],
                 "d0S"=Syk[16,9],"d0T"=Syk[17,9],"d0V"=Syk[18,9],"d0W"=Syk[19,9],"d0Y"=Syk[20,9],"d0O"=1,
                 "p1A"=Syk[1,10], "p1C"=Syk[2,10], "p1D"=Syk[3,10], "p1E"=Syk[4,10], "p1F"=Syk[5,10],"p1G"=Syk[6,10],"p1H"=Syk[7,10],"p1I"=Syk[8,10],"p1K"=Syk[9,10],"p1L"=Syk[10,10],"p1M"=Syk[11,10],"p1N"=Syk[12,10],"p1P"=Syk[13,10],"p1Q"=Syk[14,10],"p1R"=Syk[15,10],
                 "p1S"=Syk[16,10],"p1T"=Syk[17,10],"p1V"=Syk[18,10],"p1W"=Syk[19,10],"p1Y"=Syk[20,10],"p1O"=1,
                 "p2A"=Syk[1,11], "p2C"=Syk[2,11], "p2D"=Syk[3,11], "p2E"=Syk[4,11], "p2F"=Syk[5,11],"p2G"=Syk[6,11],"p2H"=Syk[7,11],"p2I"=Syk[8,11],"p2K"=Syk[9,11],"p2L"=Syk[10,11],"p2M"=Syk[11,11],"p2N"=Syk[12,11],"p2P"=Syk[13,11],"p2Q"=Syk[14,11],"p2R"=Syk[15,11],
                 "p2S"=Syk[16,11],"p2T"=Syk[17,11],"p2V"=Syk[18,11],"p2W"=Syk[19,11],"p2Y"=Syk[20,11],"p2O"=1,
                 "p3A"=Syk[1,12], "p3C"=Syk[2,12], "p3D"=Syk[3,12], "p3E"=Syk[4,12], "p3F"=Syk[5,12],"p3G"=Syk[6,12],"p3H"=Syk[7,12],"p3I"=Syk[8,12],"p3K"=Syk[9,12],"p3L"=Syk[10,12],"p3M"=Syk[11,12],"p3N"=Syk[12,12],"p3P"=Syk[13,12],"p3Q"=Syk[14,12],"p3R"=Syk[15,12],
                 "p3S"=Syk[16,12],"p3T"=Syk[17,12],"p3V"=Syk[18,12],"p3W"=Syk[19,12],"p3Y"=Syk[20,12],"p3O"=1,
                 "p4A"=Syk[1,13], "p4C"=Syk[2,13], "p4D"=Syk[3,13], "p4E"=Syk[4,13], "p4F"=Syk[5,13],"p4G"=Syk[6,13],"p4H"=Syk[7,13],"p4I"=Syk[8,13],"p4K"=Syk[9,13],"p4L"=Syk[10,13],"p4M"=Syk[11,13],"p4N"=Syk[12,13],"p4P"=Syk[13,13],"p4Q"=Syk[14,13],"p4R"=Syk[15,13],
                 "p4S"=Syk[16,13],"p4T"=Syk[17,13],"p4V"=Syk[18,13],"p4W"=Syk[19,13],"p4Y"=Syk[20,13],"p4O"=1,
                 "p5A"=Syk[1,14], "p5C"=Syk[2,14], "p5D"=Syk[3,14], "p5E"=Syk[4,14], "p5F"=Syk[5,14],"p5G"=Syk[6,14],"p5H"=Syk[7,14],"p5I"=Syk[8,14],"p5K"=Syk[9,14],"p5L"=Syk[10,14],"p5M"=Syk[11,14],"p5N"=Syk[12,14],"p5P"=Syk[13,14],"p5Q"=Syk[14,14],"p5R"=Syk[15,14],
                 "p5S"=Syk[16,14],"p5T"=Syk[17,14],"p5V"=Syk[18,14],"p5W"=Syk[19,14],"p5Y"=Syk[20,14],"p5O"=1,
                 "p6A"=Syk[1,15], "p6C"=Syk[2,15], "p6D"=Syk[3,15], "p6E"=Syk[4,15], "p6F"=Syk[5,15],"p6G"=Syk[6,15],"p6H"=Syk[7,15],"p6I"=Syk[8,15],"p6K"=Syk[9,15],"p6L"=Syk[10,15],"p6M"=Syk[11,15],"p6N"=Syk[12,15],"p6P"=Syk[13,15],"p6Q"=Syk[14,15],"p6R"=Syk[15,15],
                 "p6S"=Syk[16,15],"p6T"=Syk[17,15],"p6V"=Syk[18,15],"p6W"=Syk[19,15],"p6Y"=Syk[20,15],"p6O"=1)
  
  Yes_props <- c("m6A"=Yes[1,3], "m6C"=Yes[2,3], "m6D"=Yes[3,3], "m6E"=Yes[4,3], "m6F"=Yes[5,3],"m6G"=Yes[6,3],"m6H"=Yes[7,3],"m6I"=Yes[8,3],"m6K"=Yes[9,3],"m6L"=Yes[10,3],"m6M"=Yes[11,3],"m6N"=Yes[12,3],"m6P"=Yes[13,3],"m6Q"=Yes[14,3],"m6R"=Yes[15,3],
                 "m6S"=Yes[16,3],"m6T"=Yes[17,3],"m6V"=Yes[18,3],"m6W"=Yes[19,3],"m6Y"=Yes[20,3],"m6O"=1,
                 "m5A"=Yes[1,4], "m5C"=Yes[2,4], "m5D"=Yes[3,4], "m5E"=Yes[4,4], "m5F"=Yes[5,4],"m5G"=Yes[6,4],"m5H"=Yes[7,4],"m5I"=Yes[8,4],"m5K"=Yes[9,4],"m5L"=Yes[10,4],"m5M"=Yes[11,4],"m5N"=Yes[12,4],"m5P"=Yes[13,4],"m5Q"=Yes[14,4],"m5R"=Yes[15,4],
                 "m5S"=Yes[16,4],"m5T"=Yes[17,4],"m5V"=Yes[18,4],"m5W"=Yes[19,4],"m5Y"=Yes[20,4],"m5O"=1,
                 "m4A"=Yes[1,5], "m4C"=Yes[2,5], "m4D"=Yes[3,5], "m4E"=Yes[4,5], "m4F"=Yes[5,5],"m4G"=Yes[6,5],"m4H"=Yes[7,5],"m4I"=Yes[8,5],"m4K"=Yes[9,5],"m4L"=Yes[10,5],"m4M"=Yes[11,5],"m4N"=Yes[12,5],"m4P"=Yes[13,5],"m4Q"=Yes[14,5],"m4R"=Yes[15,5],
                 "m4S"=Yes[16,5],"m4T"=Yes[17,5],"m4V"=Yes[18,5],"m4W"=Yes[19,5],"m4Y"=Yes[20,5],"m4O"=1,
                 "m3A"=Yes[1,6], "m3C"=Yes[2,6], "m3D"=Yes[3,6], "m3E"=Yes[4,6], "m3F"=Yes[5,6],"m3G"=Yes[6,6],"m3H"=Yes[7,6],"m3I"=Yes[8,6],"m3K"=Yes[9,6],"m3L"=Yes[10,6],"m3M"=Yes[11,6],"m3N"=Yes[12,6],"m3P"=Yes[13,6],"m3Q"=Yes[14,6],"m3R"=Yes[15,6],
                 "m3S"=Yes[16,6],"m3T"=Yes[17,6],"m3V"=Yes[18,6],"m3W"=Yes[19,6],"m3Y"=Yes[20,6],"m3O"=1,
                 "m2A"=Yes[1,7], "m2C"=Yes[2,7], "m2D"=Yes[3,7], "m2E"=Yes[4,7], "m2F"=Yes[5,7],"m2G"=Yes[6,7],"m2H"=Yes[7,7],"m2I"=Yes[8,7],"m2K"=Yes[9,7],"m2L"=Yes[10,7],"m2M"=Yes[11,7],"m2N"=Yes[12,7],"m2P"=Yes[13,7],"m2Q"=Yes[14,7],"m2R"=Yes[15,7],
                 "m2S"=Yes[16,7],"m2T"=Yes[17,7],"m2V"=Yes[18,7],"m2W"=Yes[19,7],"m2Y"=Yes[20,7],"m2O"=1,
                 "m1A"=Yes[1,8], "m1C"=Yes[2,8], "m1D"=Yes[3,8], "m1E"=Yes[4,8], "m1F"=Yes[5,8],"m1G"=Yes[6,8],"m1H"=Yes[7,8],"m1I"=Yes[8,8],"m1K"=Yes[9,8],"m1L"=Yes[10,8],"m1M"=Yes[11,8],"m1N"=Yes[12,8],"m1P"=Yes[13,8],"m1Q"=Yes[14,8],"m1R"=Yes[15,8],
                 "m1S"=Yes[16,8],"m1T"=Yes[17,8],"m1V"=Yes[18,8],"m1W"=Yes[19,8],"m1Y"=Yes[20,8],"m1O"=1,
                 "d0A"=Yes[1,9], "d0C"=Yes[2,9], "d0D"=Yes[3,9], "d0E"=Yes[4,9], "d0F"=Yes[5,9],"d0G"=Yes[6,9],"d0H"=Yes[7,9],"d0I"=Yes[8,9],"d0K"=Yes[9,9],"d0L"=Yes[10,9],"d0M"=Yes[11,9],"d0N"=Yes[12,9],"d0P"=Yes[13,9],"d0Q"=Yes[14,9],"d0R"=Yes[15,9],
                 "d0S"=Yes[16,9],"d0T"=Yes[17,9],"d0V"=Yes[18,9],"d0W"=Yes[19,9],"d0Y"=Yes[20,9],"d0O"=1,
                 "p1A"=Yes[1,10], "p1C"=Yes[2,10], "p1D"=Yes[3,10], "p1E"=Yes[4,10], "p1F"=Yes[5,10],"p1G"=Yes[6,10],"p1H"=Yes[7,10],"p1I"=Yes[8,10],"p1K"=Yes[9,10],"p1L"=Yes[10,10],"p1M"=Yes[11,10],"p1N"=Yes[12,10],"p1P"=Yes[13,10],"p1Q"=Yes[14,10],"p1R"=Yes[15,10],
                 "p1S"=Yes[16,10],"p1T"=Yes[17,10],"p1V"=Yes[18,10],"p1W"=Yes[19,10],"p1Y"=Yes[20,10],"p1O"=1,
                 "p2A"=Yes[1,11], "p2C"=Yes[2,11], "p2D"=Yes[3,11], "p2E"=Yes[4,11], "p2F"=Yes[5,11],"p2G"=Yes[6,11],"p2H"=Yes[7,11],"p2I"=Yes[8,11],"p2K"=Yes[9,11],"p2L"=Yes[10,11],"p2M"=Yes[11,11],"p2N"=Yes[12,11],"p2P"=Yes[13,11],"p2Q"=Yes[14,11],"p2R"=Yes[15,11],
                 "p2S"=Yes[16,11],"p2T"=Yes[17,11],"p2V"=Yes[18,11],"p2W"=Yes[19,11],"p2Y"=Yes[20,11],"p2O"=1,
                 "p3A"=Yes[1,12], "p3C"=Yes[2,12], "p3D"=Yes[3,12], "p3E"=Yes[4,12], "p3F"=Yes[5,12],"p3G"=Yes[6,12],"p3H"=Yes[7,12],"p3I"=Yes[8,12],"p3K"=Yes[9,12],"p3L"=Yes[10,12],"p3M"=Yes[11,12],"p3N"=Yes[12,12],"p3P"=Yes[13,12],"p3Q"=Yes[14,12],"p3R"=Yes[15,12],
                 "p3S"=Yes[16,12],"p3T"=Yes[17,12],"p3V"=Yes[18,12],"p3W"=Yes[19,12],"p3Y"=Yes[20,12],"p3O"=1,
                 "p4A"=Yes[1,13], "p4C"=Yes[2,13], "p4D"=Yes[3,13], "p4E"=Yes[4,13], "p4F"=Yes[5,13],"p4G"=Yes[6,13],"p4H"=Yes[7,13],"p4I"=Yes[8,13],"p4K"=Yes[9,13],"p4L"=Yes[10,13],"p4M"=Yes[11,13],"p4N"=Yes[12,13],"p4P"=Yes[13,13],"p4Q"=Yes[14,13],"p4R"=Yes[15,13],
                 "p4S"=Yes[16,13],"p4T"=Yes[17,13],"p4V"=Yes[18,13],"p4W"=Yes[19,13],"p4Y"=Yes[20,13],"p4O"=1,
                 "p5A"=Yes[1,14], "p5C"=Yes[2,14], "p5D"=Yes[3,14], "p5E"=Yes[4,14], "p5F"=Yes[5,14],"p5G"=Yes[6,14],"p5H"=Yes[7,14],"p5I"=Yes[8,14],"p5K"=Yes[9,14],"p5L"=Yes[10,14],"p5M"=Yes[11,14],"p5N"=Yes[12,14],"p5P"=Yes[13,14],"p5Q"=Yes[14,14],"p5R"=Yes[15,14],
                 "p5S"=Yes[16,14],"p5T"=Yes[17,14],"p5V"=Yes[18,14],"p5W"=Yes[19,14],"p5Y"=Yes[20,14],"p5O"=1,
                 "p6A"=Yes[1,15], "p6C"=Yes[2,15], "p6D"=Yes[3,15], "p6E"=Yes[4,15], "p6F"=Yes[5,15],"p6G"=Yes[6,15],"p6H"=Yes[7,15],"p6I"=Yes[8,15],"p6K"=Yes[9,15],"p6L"=Yes[10,15],"p6M"=Yes[11,15],"p6N"=Yes[12,15],"p6P"=Yes[13,15],"p6Q"=Yes[14,15],"p6R"=Yes[15,15],
                 "p6S"=Yes[16,15],"p6T"=Yes[17,15],"p6V"=Yes[18,15],"p6W"=Yes[19,15],"p6Y"=Yes[20,15],"p6O"=1)
  
  FLT3_props <- c("m6A"=FLT3[1,3], "m6C"=FLT3[2,3], "m6D"=FLT3[3,3], "m6E"=FLT3[4,3], "m6F"=FLT3[5,3],"m6G"=FLT3[6,3],"m6H"=FLT3[7,3],"m6I"=FLT3[8,3],"m6K"=FLT3[9,3],"m6L"=FLT3[10,3],"m6M"=FLT3[11,3],"m6N"=FLT3[12,3],"m6P"=FLT3[13,3],"m6Q"=FLT3[14,3],"m6R"=FLT3[15,3],
                  "m6S"=FLT3[16,3],"m6T"=FLT3[17,3],"m6V"=FLT3[18,3],"m6W"=FLT3[19,3],"m6Y"=FLT3[20,3],"m6O"=1,
                  "m5A"=FLT3[1,4], "m5C"=FLT3[2,4], "m5D"=FLT3[3,4], "m5E"=FLT3[4,4], "m5F"=FLT3[5,4],"m5G"=FLT3[6,4],"m5H"=FLT3[7,4],"m5I"=FLT3[8,4],"m5K"=FLT3[9,4],"m5L"=FLT3[10,4],"m5M"=FLT3[11,4],"m5N"=FLT3[12,4],"m5P"=FLT3[13,4],"m5Q"=FLT3[14,4],"m5R"=FLT3[15,4],
                  "m5S"=FLT3[16,4],"m5T"=FLT3[17,4],"m5V"=FLT3[18,4],"m5W"=FLT3[19,4],"m5Y"=FLT3[20,4],"m5O"=1,
                  "m4A"=FLT3[1,5], "m4C"=FLT3[2,5], "m4D"=FLT3[3,5], "m4E"=FLT3[4,5], "m4F"=FLT3[5,5],"m4G"=FLT3[6,5],"m4H"=FLT3[7,5],"m4I"=FLT3[8,5],"m4K"=FLT3[9,5],"m4L"=FLT3[10,5],"m4M"=FLT3[11,5],"m4N"=FLT3[12,5],"m4P"=FLT3[13,5],"m4Q"=FLT3[14,5],"m4R"=FLT3[15,5],
                  "m4S"=FLT3[16,5],"m4T"=FLT3[17,5],"m4V"=FLT3[18,5],"m4W"=FLT3[19,5],"m4Y"=FLT3[20,5],"m4O"=1,
                  "m3A"=FLT3[1,6], "m3C"=FLT3[2,6], "m3D"=FLT3[3,6], "m3E"=FLT3[4,6], "m3F"=FLT3[5,6],"m3G"=FLT3[6,6],"m3H"=FLT3[7,6],"m3I"=FLT3[8,6],"m3K"=FLT3[9,6],"m3L"=FLT3[10,6],"m3M"=FLT3[11,6],"m3N"=FLT3[12,6],"m3P"=FLT3[13,6],"m3Q"=FLT3[14,6],"m3R"=FLT3[15,6],
                  "m3S"=FLT3[16,6],"m3T"=FLT3[17,6],"m3V"=FLT3[18,6],"m3W"=FLT3[19,6],"m3Y"=FLT3[20,6],"m3O"=1,
                  "m2A"=FLT3[1,7], "m2C"=FLT3[2,7], "m2D"=FLT3[3,7], "m2E"=FLT3[4,7], "m2F"=FLT3[5,7],"m2G"=FLT3[6,7],"m2H"=FLT3[7,7],"m2I"=FLT3[8,7],"m2K"=FLT3[9,7],"m2L"=FLT3[10,7],"m2M"=FLT3[11,7],"m2N"=FLT3[12,7],"m2P"=FLT3[13,7],"m2Q"=FLT3[14,7],"m2R"=FLT3[15,7],
                  "m2S"=FLT3[16,7],"m2T"=FLT3[17,7],"m2V"=FLT3[18,7],"m2W"=FLT3[19,7],"m2Y"=FLT3[20,7],"m2O"=1,
                  "m1A"=FLT3[1,8], "m1C"=FLT3[2,8], "m1D"=FLT3[3,8], "m1E"=FLT3[4,8], "m1F"=FLT3[5,8],"m1G"=FLT3[6,8],"m1H"=FLT3[7,8],"m1I"=FLT3[8,8],"m1K"=FLT3[9,8],"m1L"=FLT3[10,8],"m1M"=FLT3[11,8],"m1N"=FLT3[12,8],"m1P"=FLT3[13,8],"m1Q"=FLT3[14,8],"m1R"=FLT3[15,8],
                  "m1S"=FLT3[16,8],"m1T"=FLT3[17,8],"m1V"=FLT3[18,8],"m1W"=FLT3[19,8],"m1Y"=FLT3[20,8],"m1O"=1,
                  "d0A"=FLT3[1,9], "d0C"=FLT3[2,9], "d0D"=FLT3[3,9], "d0E"=FLT3[4,9], "d0F"=FLT3[5,9],"d0G"=FLT3[6,9],"d0H"=FLT3[7,9],"d0I"=FLT3[8,9],"d0K"=FLT3[9,9],"d0L"=FLT3[10,9],"d0M"=FLT3[11,9],"d0N"=FLT3[12,9],"d0P"=FLT3[13,9],"d0Q"=FLT3[14,9],"d0R"=FLT3[15,9],
                  "d0S"=FLT3[16,9],"d0T"=FLT3[17,9],"d0V"=FLT3[18,9],"d0W"=FLT3[19,9],"d0Y"=FLT3[20,9],"d0O"=1,
                  "p1A"=FLT3[1,10], "p1C"=FLT3[2,10], "p1D"=FLT3[3,10], "p1E"=FLT3[4,10], "p1F"=FLT3[5,10],"p1G"=FLT3[6,10],"p1H"=FLT3[7,10],"p1I"=FLT3[8,10],"p1K"=FLT3[9,10],"p1L"=FLT3[10,10],"p1M"=FLT3[11,10],"p1N"=FLT3[12,10],"p1P"=FLT3[13,10],"p1Q"=FLT3[14,10],"p1R"=FLT3[15,10],
                  "p1S"=FLT3[16,10],"p1T"=FLT3[17,10],"p1V"=FLT3[18,10],"p1W"=FLT3[19,10],"p1Y"=FLT3[20,10],"p1O"=1,
                  "p2A"=FLT3[1,11], "p2C"=FLT3[2,11], "p2D"=FLT3[3,11], "p2E"=FLT3[4,11], "p2F"=FLT3[5,11],"p2G"=FLT3[6,11],"p2H"=FLT3[7,11],"p2I"=FLT3[8,11],"p2K"=FLT3[9,11],"p2L"=FLT3[10,11],"p2M"=FLT3[11,11],"p2N"=FLT3[12,11],"p2P"=FLT3[13,11],"p2Q"=FLT3[14,11],"p2R"=FLT3[15,11],
                  "p2S"=FLT3[16,11],"p2T"=FLT3[17,11],"p2V"=FLT3[18,11],"p2W"=FLT3[19,11],"p2Y"=FLT3[20,11],"p2O"=1,
                  "p3A"=FLT3[1,12], "p3C"=FLT3[2,12], "p3D"=FLT3[3,12], "p3E"=FLT3[4,12], "p3F"=FLT3[5,12],"p3G"=FLT3[6,12],"p3H"=FLT3[7,12],"p3I"=FLT3[8,12],"p3K"=FLT3[9,12],"p3L"=FLT3[10,12],"p3M"=FLT3[11,12],"p3N"=FLT3[12,12],"p3P"=FLT3[13,12],"p3Q"=FLT3[14,12],"p3R"=FLT3[15,12],
                  "p3S"=FLT3[16,12],"p3T"=FLT3[17,12],"p3V"=FLT3[18,12],"p3W"=FLT3[19,12],"p3Y"=FLT3[20,12],"p3O"=1,
                  "p4A"=FLT3[1,13], "p4C"=FLT3[2,13], "p4D"=FLT3[3,13], "p4E"=FLT3[4,13], "p4F"=FLT3[5,13],"p4G"=FLT3[6,13],"p4H"=FLT3[7,13],"p4I"=FLT3[8,13],"p4K"=FLT3[9,13],"p4L"=FLT3[10,13],"p4M"=FLT3[11,13],"p4N"=FLT3[12,13],"p4P"=FLT3[13,13],"p4Q"=FLT3[14,13],"p4R"=FLT3[15,13],
                  "p4S"=FLT3[16,13],"p4T"=FLT3[17,13],"p4V"=FLT3[18,13],"p4W"=FLT3[19,13],"p4Y"=FLT3[20,13],"p4O"=1,
                  "p5A"=FLT3[1,14], "p5C"=FLT3[2,14], "p5D"=FLT3[3,14], "p5E"=FLT3[4,14], "p5F"=FLT3[5,14],"p5G"=FLT3[6,14],"p5H"=FLT3[7,14],"p5I"=FLT3[8,14],"p5K"=FLT3[9,14],"p5L"=FLT3[10,14],"p5M"=FLT3[11,14],"p5N"=FLT3[12,14],"p5P"=FLT3[13,14],"p5Q"=FLT3[14,14],"p5R"=FLT3[15,14],
                  "p5S"=FLT3[16,14],"p5T"=FLT3[17,14],"p5V"=FLT3[18,14],"p5W"=FLT3[19,14],"p5Y"=FLT3[20,14],"p5O"=1,
                  "p6A"=FLT3[1,15], "p6C"=FLT3[2,15], "p6D"=FLT3[3,15], "p6E"=FLT3[4,15], "p6F"=FLT3[5,15],"p6G"=FLT3[6,15],"p6H"=FLT3[7,15],"p6I"=FLT3[8,15],"p6K"=FLT3[9,15],"p6L"=FLT3[10,15],"p6M"=FLT3[11,15],"p6N"=FLT3[12,15],"p6P"=FLT3[13,15],"p6Q"=FLT3[14,15],"p6R"=FLT3[15,15],
                  "p6S"=FLT3[16,15],"p6T"=FLT3[17,15],"p6V"=FLT3[18,15],"p6W"=FLT3[19,15],"p6Y"=FLT3[20,15],"p6O"=1)
  
  ALK_props <- c("m6A"=ALK[1,3], "m6C"=ALK[2,3], "m6D"=ALK[3,3], "m6E"=ALK[4,3], "m6F"=ALK[5,3],"m6G"=ALK[6,3],"m6H"=ALK[7,3],"m6I"=ALK[8,3],"m6K"=ALK[9,3],"m6L"=ALK[10,3],"m6M"=ALK[11,3],"m6N"=ALK[12,3],"m6P"=ALK[13,3],"m6Q"=ALK[14,3],"m6R"=ALK[15,3],
                 "m6S"=ALK[16,3],"m6T"=ALK[17,3],"m6V"=ALK[18,3],"m6W"=ALK[19,3],"m6Y"=ALK[20,3],"m6O"=1,
                 "m5A"=ALK[1,4], "m5C"=ALK[2,4], "m5D"=ALK[3,4], "m5E"=ALK[4,4], "m5F"=ALK[5,4],"m5G"=ALK[6,4],"m5H"=ALK[7,4],"m5I"=ALK[8,4],"m5K"=ALK[9,4],"m5L"=ALK[10,4],"m5M"=ALK[11,4],"m5N"=ALK[12,4],"m5P"=ALK[13,4],"m5Q"=ALK[14,4],"m5R"=ALK[15,4],
                 "m5S"=ALK[16,4],"m5T"=ALK[17,4],"m5V"=ALK[18,4],"m5W"=ALK[19,4],"m5Y"=ALK[20,4],"m5O"=1,
                 "m4A"=ALK[1,5], "m4C"=ALK[2,5], "m4D"=ALK[3,5], "m4E"=ALK[4,5], "m4F"=ALK[5,5],"m4G"=ALK[6,5],"m4H"=ALK[7,5],"m4I"=ALK[8,5],"m4K"=ALK[9,5],"m4L"=ALK[10,5],"m4M"=ALK[11,5],"m4N"=ALK[12,5],"m4P"=ALK[13,5],"m4Q"=ALK[14,5],"m4R"=ALK[15,5],
                 "m4S"=ALK[16,5],"m4T"=ALK[17,5],"m4V"=ALK[18,5],"m4W"=ALK[19,5],"m4Y"=ALK[20,5],"m4O"=1,
                 "m3A"=ALK[1,6], "m3C"=ALK[2,6], "m3D"=ALK[3,6], "m3E"=ALK[4,6], "m3F"=ALK[5,6],"m3G"=ALK[6,6],"m3H"=ALK[7,6],"m3I"=ALK[8,6],"m3K"=ALK[9,6],"m3L"=ALK[10,6],"m3M"=ALK[11,6],"m3N"=ALK[12,6],"m3P"=ALK[13,6],"m3Q"=ALK[14,6],"m3R"=ALK[15,6],
                 "m3S"=ALK[16,6],"m3T"=ALK[17,6],"m3V"=ALK[18,6],"m3W"=ALK[19,6],"m3Y"=ALK[20,6],"m3O"=1,
                 "m2A"=ALK[1,7], "m2C"=ALK[2,7], "m2D"=ALK[3,7], "m2E"=ALK[4,7], "m2F"=ALK[5,7],"m2G"=ALK[6,7],"m2H"=ALK[7,7],"m2I"=ALK[8,7],"m2K"=ALK[9,7],"m2L"=ALK[10,7],"m2M"=ALK[11,7],"m2N"=ALK[12,7],"m2P"=ALK[13,7],"m2Q"=ALK[14,7],"m2R"=ALK[15,7],
                 "m2S"=ALK[16,7],"m2T"=ALK[17,7],"m2V"=ALK[18,7],"m2W"=ALK[19,7],"m2Y"=ALK[20,7],"m2O"=1,
                 "m1A"=ALK[1,8], "m1C"=ALK[2,8], "m1D"=ALK[3,8], "m1E"=ALK[4,8], "m1F"=ALK[5,8],"m1G"=ALK[6,8],"m1H"=ALK[7,8],"m1I"=ALK[8,8],"m1K"=ALK[9,8],"m1L"=ALK[10,8],"m1M"=ALK[11,8],"m1N"=ALK[12,8],"m1P"=ALK[13,8],"m1Q"=ALK[14,8],"m1R"=ALK[15,8],
                 "m1S"=ALK[16,8],"m1T"=ALK[17,8],"m1V"=ALK[18,8],"m1W"=ALK[19,8],"m1Y"=ALK[20,8],"m1O"=1,
                 "d0A"=ALK[1,9], "d0C"=ALK[2,9], "d0D"=ALK[3,9], "d0E"=ALK[4,9], "d0F"=ALK[5,9],"d0G"=ALK[6,9],"d0H"=ALK[7,9],"d0I"=ALK[8,9],"d0K"=ALK[9,9],"d0L"=ALK[10,9],"d0M"=ALK[11,9],"d0N"=ALK[12,9],"d0P"=ALK[13,9],"d0Q"=ALK[14,9],"d0R"=ALK[15,9],
                 "d0S"=ALK[16,9],"d0T"=ALK[17,9],"d0V"=ALK[18,9],"d0W"=ALK[19,9],"d0Y"=ALK[20,9],"d0O"=1,
                 "p1A"=ALK[1,10], "p1C"=ALK[2,10], "p1D"=ALK[3,10], "p1E"=ALK[4,10], "p1F"=ALK[5,10],"p1G"=ALK[6,10],"p1H"=ALK[7,10],"p1I"=ALK[8,10],"p1K"=ALK[9,10],"p1L"=ALK[10,10],"p1M"=ALK[11,10],"p1N"=ALK[12,10],"p1P"=ALK[13,10],"p1Q"=ALK[14,10],"p1R"=ALK[15,10],
                 "p1S"=ALK[16,10],"p1T"=ALK[17,10],"p1V"=ALK[18,10],"p1W"=ALK[19,10],"p1Y"=ALK[20,10],"p1O"=1,
                 "p2A"=ALK[1,11], "p2C"=ALK[2,11], "p2D"=ALK[3,11], "p2E"=ALK[4,11], "p2F"=ALK[5,11],"p2G"=ALK[6,11],"p2H"=ALK[7,11],"p2I"=ALK[8,11],"p2K"=ALK[9,11],"p2L"=ALK[10,11],"p2M"=ALK[11,11],"p2N"=ALK[12,11],"p2P"=ALK[13,11],"p2Q"=ALK[14,11],"p2R"=ALK[15,11],
                 "p2S"=ALK[16,11],"p2T"=ALK[17,11],"p2V"=ALK[18,11],"p2W"=ALK[19,11],"p2Y"=ALK[20,11],"p2O"=1,
                 "p3A"=ALK[1,12], "p3C"=ALK[2,12], "p3D"=ALK[3,12], "p3E"=ALK[4,12], "p3F"=ALK[5,12],"p3G"=ALK[6,12],"p3H"=ALK[7,12],"p3I"=ALK[8,12],"p3K"=ALK[9,12],"p3L"=ALK[10,12],"p3M"=ALK[11,12],"p3N"=ALK[12,12],"p3P"=ALK[13,12],"p3Q"=ALK[14,12],"p3R"=ALK[15,12],
                 "p3S"=ALK[16,12],"p3T"=ALK[17,12],"p3V"=ALK[18,12],"p3W"=ALK[19,12],"p3Y"=ALK[20,12],"p3O"=1,
                 "p4A"=ALK[1,13], "p4C"=ALK[2,13], "p4D"=ALK[3,13], "p4E"=ALK[4,13], "p4F"=ALK[5,13],"p4G"=ALK[6,13],"p4H"=ALK[7,13],"p4I"=ALK[8,13],"p4K"=ALK[9,13],"p4L"=ALK[10,13],"p4M"=ALK[11,13],"p4N"=ALK[12,13],"p4P"=ALK[13,13],"p4Q"=ALK[14,13],"p4R"=ALK[15,13],
                 "p4S"=ALK[16,13],"p4T"=ALK[17,13],"p4V"=ALK[18,13],"p4W"=ALK[19,13],"p4Y"=ALK[20,13],"p4O"=1,
                 "p5A"=ALK[1,14], "p5C"=ALK[2,14], "p5D"=ALK[3,14], "p5E"=ALK[4,14], "p5F"=ALK[5,14],"p5G"=ALK[6,14],"p5H"=ALK[7,14],"p5I"=ALK[8,14],"p5K"=ALK[9,14],"p5L"=ALK[10,14],"p5M"=ALK[11,14],"p5N"=ALK[12,14],"p5P"=ALK[13,14],"p5Q"=ALK[14,14],"p5R"=ALK[15,14],
                 "p5S"=ALK[16,14],"p5T"=ALK[17,14],"p5V"=ALK[18,14],"p5W"=ALK[19,14],"p5Y"=ALK[20,14],"p5O"=1,
                 "p6A"=ALK[1,15], "p6C"=ALK[2,15], "p6D"=ALK[3,15], "p6E"=ALK[4,15], "p6F"=ALK[5,15],"p6G"=ALK[6,15],"p6H"=ALK[7,15],"p6I"=ALK[8,15],"p6K"=ALK[9,15],"p6L"=ALK[10,15],"p6M"=ALK[11,15],"p6N"=ALK[12,15],"p6P"=ALK[13,15],"p6Q"=ALK[14,15],"p6R"=ALK[15,15],
                 "p6S"=ALK[16,15],"p6T"=ALK[17,15],"p6V"=ALK[18,15],"p6W"=ALK[19,15],"p6Y"=ALK[20,15],"p6O"=1)
  
}
#this creates the apply functions that are used below.  Each amino acid at each position gets assigned a value from an EPM table


#this part turns amino acids at positions into values from the EPM tables using the above apply function
if(1==1){
  ThisKinTablem6<-sapply(pPositionm6, function(x) ThisKinTable_props[x])
  ThisKinTablem5<-sapply(pPositionm5, function(x) ThisKinTable_props[x])
  ThisKinTablem4<-sapply(pPositionm4, function(x) ThisKinTable_props[x])
  ThisKinTablem3<-sapply(pPositionm3, function(x) ThisKinTable_props[x])
  ThisKinTablem2<-sapply(pPositionm2, function(x) ThisKinTable_props[x])
  ThisKinTablem1<-sapply(pPositionm1, function(x) ThisKinTable_props[x])
  ThisKinTabled0<-sapply(pPositiond0, function(x) ThisKinTable_props[x])
  ThisKinTablep1<-sapply(pPositionp1, function(x) ThisKinTable_props[x])
  ThisKinTablep2<-sapply(pPositionp2, function(x) ThisKinTable_props[x])
  ThisKinTablep3<-sapply(pPositionp3, function(x) ThisKinTable_props[x])
  ThisKinTablep4<-sapply(pPositionp4, function(x) ThisKinTable_props[x])
  ThisKinTablep5<-sapply(pPositionp5, function(x) ThisKinTable_props[x])
  ThisKinTablep6<-sapply(pPositionp6, function(x) ThisKinTable_props[x])
  
  Ablm6<-sapply(pPositionm6, function(x) Abl_props[x])
  Ablm5<-sapply(pPositionm5, function(x) Abl_props[x])
  Ablm4<-sapply(pPositionm4, function(x) Abl_props[x])
  Ablm3<-sapply(pPositionm3, function(x) Abl_props[x])
  Ablm2<-sapply(pPositionm2, function(x) Abl_props[x])
  Ablm1<-sapply(pPositionm1, function(x) Abl_props[x])
  Abld0<-sapply(pPositiond0, function(x) Abl_props[x])
  Ablp1<-sapply(pPositionp1, function(x) Abl_props[x])
  Ablp2<-sapply(pPositionp2, function(x) Abl_props[x])
  Ablp3<-sapply(pPositionp3, function(x) Abl_props[x])
  Ablp4<-sapply(pPositionp4, function(x) Abl_props[x])
  Ablp5<-sapply(pPositionp5, function(x) Abl_props[x])
  Ablp6<-sapply(pPositionp6, function(x) Abl_props[x])
  
  Argm6<-sapply(pPositionm6, function(x) Arg_props[x])
  Argm5<-sapply(pPositionm5, function(x) Arg_props[x])
  Argm4<-sapply(pPositionm4, function(x) Arg_props[x])
  Argm3<-sapply(pPositionm3, function(x) Arg_props[x])
  Argm2<-sapply(pPositionm2, function(x) Arg_props[x])
  Argm1<-sapply(pPositionm1, function(x) Arg_props[x])
  Argd0<-sapply(pPositiond0, function(x) Arg_props[x])
  Argp1<-sapply(pPositionp1, function(x) Arg_props[x])
  Argp2<-sapply(pPositionp2, function(x) Arg_props[x])
  Argp3<-sapply(pPositionp3, function(x) Arg_props[x])
  Argp4<-sapply(pPositionp4, function(x) Arg_props[x])
  Argp5<-sapply(pPositionp5, function(x) Arg_props[x])
  Argp6<-sapply(pPositionp6, function(x) Arg_props[x])
  
  Btkm6<-sapply(pPositionm6, function(x) Btk_props[x])
  Btkm5<-sapply(pPositionm5, function(x) Btk_props[x])
  Btkm4<-sapply(pPositionm4, function(x) Btk_props[x])
  Btkm3<-sapply(pPositionm3, function(x) Btk_props[x])
  Btkm2<-sapply(pPositionm2, function(x) Btk_props[x])
  Btkm1<-sapply(pPositionm1, function(x) Btk_props[x])
  Btkd0<-sapply(pPositiond0, function(x) Btk_props[x])
  Btkp1<-sapply(pPositionp1, function(x) Btk_props[x])
  Btkp2<-sapply(pPositionp2, function(x) Btk_props[x])
  Btkp3<-sapply(pPositionp3, function(x) Btk_props[x])
  Btkp4<-sapply(pPositionp4, function(x) Btk_props[x])
  Btkp5<-sapply(pPositionp5, function(x) Btk_props[x])
  Btkp6<-sapply(pPositionp6, function(x) Btk_props[x])
  
  Cskm6<-sapply(pPositionm6, function(x) Csk_props[x])
  Cskm5<-sapply(pPositionm5, function(x) Csk_props[x])
  Cskm4<-sapply(pPositionm4, function(x) Csk_props[x])
  Cskm3<-sapply(pPositionm3, function(x) Csk_props[x])
  Cskm2<-sapply(pPositionm2, function(x) Csk_props[x])
  Cskm1<-sapply(pPositionm1, function(x) Csk_props[x])
  Cskd0<-sapply(pPositiond0, function(x) Csk_props[x])
  Cskp1<-sapply(pPositionp1, function(x) Csk_props[x])
  Cskp2<-sapply(pPositionp2, function(x) Csk_props[x])
  Cskp3<-sapply(pPositionp3, function(x) Csk_props[x])
  Cskp4<-sapply(pPositionp4, function(x) Csk_props[x])
  Cskp5<-sapply(pPositionp5, function(x) Csk_props[x])
  Cskp6<-sapply(pPositionp6, function(x) Csk_props[x])
  
  Fynm6<-sapply(pPositionm6, function(x) Fyn_props[x])
  Fynm5<-sapply(pPositionm5, function(x) Fyn_props[x])
  Fynm4<-sapply(pPositionm4, function(x) Fyn_props[x])
  Fynm3<-sapply(pPositionm3, function(x) Fyn_props[x])
  Fynm2<-sapply(pPositionm2, function(x) Fyn_props[x])
  Fynm1<-sapply(pPositionm1, function(x) Fyn_props[x])
  Fynd0<-sapply(pPositiond0, function(x) Fyn_props[x])
  Fynp1<-sapply(pPositionp1, function(x) Fyn_props[x])
  Fynp2<-sapply(pPositionp2, function(x) Fyn_props[x])
  Fynp3<-sapply(pPositionp3, function(x) Fyn_props[x])
  Fynp4<-sapply(pPositionp4, function(x) Fyn_props[x])
  Fynp5<-sapply(pPositionp5, function(x) Fyn_props[x])
  Fynp6<-sapply(pPositionp6, function(x) Fyn_props[x])
  
  Hckm6<-sapply(pPositionm6, function(x) Hck_props[x])
  Hckm5<-sapply(pPositionm5, function(x) Hck_props[x])
  Hckm4<-sapply(pPositionm4, function(x) Hck_props[x])
  Hckm3<-sapply(pPositionm3, function(x) Hck_props[x])
  Hckm2<-sapply(pPositionm2, function(x) Hck_props[x])
  Hckm1<-sapply(pPositionm1, function(x) Hck_props[x])
  Hckd0<-sapply(pPositiond0, function(x) Hck_props[x])
  Hckp1<-sapply(pPositionp1, function(x) Hck_props[x])
  Hckp2<-sapply(pPositionp2, function(x) Hck_props[x])
  Hckp3<-sapply(pPositionp3, function(x) Hck_props[x])
  Hckp4<-sapply(pPositionp4, function(x) Hck_props[x])
  Hckp5<-sapply(pPositionp5, function(x) Hck_props[x])
  Hckp6<-sapply(pPositionp6, function(x) Hck_props[x])
  
  JAK2m6<-sapply(pPositionm6, function(x) JAK2_props[x])
  JAK2m5<-sapply(pPositionm5, function(x) JAK2_props[x])
  JAK2m4<-sapply(pPositionm4, function(x) JAK2_props[x])
  JAK2m3<-sapply(pPositionm3, function(x) JAK2_props[x])
  JAK2m2<-sapply(pPositionm2, function(x) JAK2_props[x])
  JAK2m1<-sapply(pPositionm1, function(x) JAK2_props[x])
  JAK2d0<-sapply(pPositiond0, function(x) JAK2_props[x])
  JAK2p1<-sapply(pPositionp1, function(x) JAK2_props[x])
  JAK2p2<-sapply(pPositionp2, function(x) JAK2_props[x])
  JAK2p3<-sapply(pPositionp3, function(x) JAK2_props[x])
  JAK2p4<-sapply(pPositionp4, function(x) JAK2_props[x])
  JAK2p5<-sapply(pPositionp5, function(x) JAK2_props[x])
  JAK2p6<-sapply(pPositionp6, function(x) JAK2_props[x])
  
  Lckm6<-sapply(pPositionm6, function(x) Lck_props[x])
  Lckm5<-sapply(pPositionm5, function(x) Lck_props[x])
  Lckm4<-sapply(pPositionm4, function(x) Lck_props[x])
  Lckm3<-sapply(pPositionm3, function(x) Lck_props[x])
  Lckm2<-sapply(pPositionm2, function(x) Lck_props[x])
  Lckm1<-sapply(pPositionm1, function(x) Lck_props[x])
  Lckd0<-sapply(pPositiond0, function(x) Lck_props[x])
  Lckp1<-sapply(pPositionp1, function(x) Lck_props[x])
  Lckp2<-sapply(pPositionp2, function(x) Lck_props[x])
  Lckp3<-sapply(pPositionp3, function(x) Lck_props[x])
  Lckp4<-sapply(pPositionp4, function(x) Lck_props[x])
  Lckp5<-sapply(pPositionp5, function(x) Lck_props[x])
  Lckp6<-sapply(pPositionp6, function(x) Lck_props[x])
  
  Lynm6<-sapply(pPositionm6, function(x) Lyn_props[x])
  Lynm5<-sapply(pPositionm5, function(x) Lyn_props[x])
  Lynm4<-sapply(pPositionm4, function(x) Lyn_props[x])
  Lynm3<-sapply(pPositionm3, function(x) Lyn_props[x])
  Lynm2<-sapply(pPositionm2, function(x) Lyn_props[x])
  Lynm1<-sapply(pPositionm1, function(x) Lyn_props[x])
  Lynd0<-sapply(pPositiond0, function(x) Lyn_props[x])
  Lynp1<-sapply(pPositionp1, function(x) Lyn_props[x])
  Lynp2<-sapply(pPositionp2, function(x) Lyn_props[x])
  Lynp3<-sapply(pPositionp3, function(x) Lyn_props[x])
  Lynp4<-sapply(pPositionp4, function(x) Lyn_props[x])
  Lynp5<-sapply(pPositionp5, function(x) Lyn_props[x])
  Lynp6<-sapply(pPositionp6, function(x) Lyn_props[x])
  
  Pyk2m6<-sapply(pPositionm6, function(x) Pyk2_props[x])
  Pyk2m5<-sapply(pPositionm5, function(x) Pyk2_props[x])
  Pyk2m4<-sapply(pPositionm4, function(x) Pyk2_props[x])
  Pyk2m3<-sapply(pPositionm3, function(x) Pyk2_props[x])
  Pyk2m2<-sapply(pPositionm2, function(x) Pyk2_props[x])
  Pyk2m1<-sapply(pPositionm1, function(x) Pyk2_props[x])
  Pyk2d0<-sapply(pPositiond0, function(x) Pyk2_props[x])
  Pyk2p1<-sapply(pPositionp1, function(x) Pyk2_props[x])
  Pyk2p2<-sapply(pPositionp2, function(x) Pyk2_props[x])
  Pyk2p3<-sapply(pPositionp3, function(x) Pyk2_props[x])
  Pyk2p4<-sapply(pPositionp4, function(x) Pyk2_props[x])
  Pyk2p5<-sapply(pPositionp5, function(x) Pyk2_props[x])
  Pyk2p6<-sapply(pPositionp6, function(x) Pyk2_props[x])
  
  Srcm6<-sapply(pPositionm6, function(x) Src_props[x])
  Srcm5<-sapply(pPositionm5, function(x) Src_props[x])
  Srcm4<-sapply(pPositionm4, function(x) Src_props[x])
  Srcm3<-sapply(pPositionm3, function(x) Src_props[x])
  Srcm2<-sapply(pPositionm2, function(x) Src_props[x])
  Srcm1<-sapply(pPositionm1, function(x) Src_props[x])
  Srcd0<-sapply(pPositiond0, function(x) Src_props[x])
  Srcp1<-sapply(pPositionp1, function(x) Src_props[x])
  Srcp2<-sapply(pPositionp2, function(x) Src_props[x])
  Srcp3<-sapply(pPositionp3, function(x) Src_props[x])
  Srcp4<-sapply(pPositionp4, function(x) Src_props[x])
  Srcp5<-sapply(pPositionp5, function(x) Src_props[x])
  Srcp6<-sapply(pPositionp6, function(x) Src_props[x])
  
  Sykm6<-sapply(pPositionm6, function(x) Syk_props[x])
  Sykm5<-sapply(pPositionm5, function(x) Syk_props[x])
  Sykm4<-sapply(pPositionm4, function(x) Syk_props[x])
  Sykm3<-sapply(pPositionm3, function(x) Syk_props[x])
  Sykm2<-sapply(pPositionm2, function(x) Syk_props[x])
  Sykm1<-sapply(pPositionm1, function(x) Syk_props[x])
  Sykd0<-sapply(pPositiond0, function(x) Syk_props[x])
  Sykp1<-sapply(pPositionp1, function(x) Syk_props[x])
  Sykp2<-sapply(pPositionp2, function(x) Syk_props[x])
  Sykp3<-sapply(pPositionp3, function(x) Syk_props[x])
  Sykp4<-sapply(pPositionp4, function(x) Syk_props[x])
  Sykp5<-sapply(pPositionp5, function(x) Syk_props[x])
  Sykp6<-sapply(pPositionp6, function(x) Syk_props[x])
  
  Yesm6<-sapply(pPositionm6, function(x) Yes_props[x])
  Yesm5<-sapply(pPositionm5, function(x) Yes_props[x])
  Yesm4<-sapply(pPositionm4, function(x) Yes_props[x])
  Yesm3<-sapply(pPositionm3, function(x) Yes_props[x])
  Yesm2<-sapply(pPositionm2, function(x) Yes_props[x])
  Yesm1<-sapply(pPositionm1, function(x) Yes_props[x])
  Yesd0<-sapply(pPositiond0, function(x) Yes_props[x])
  Yesp1<-sapply(pPositionp1, function(x) Yes_props[x])
  Yesp2<-sapply(pPositionp2, function(x) Yes_props[x])
  Yesp3<-sapply(pPositionp3, function(x) Yes_props[x])
  Yesp4<-sapply(pPositionp4, function(x) Yes_props[x])
  Yesp5<-sapply(pPositionp5, function(x) Yes_props[x])
  Yesp6<-sapply(pPositionp6, function(x) Yes_props[x])
  
  FLT3m6<-sapply(pPositionm6, function(x) FLT3_props[x])
  FLT3m5<-sapply(pPositionm5, function(x) FLT3_props[x])
  FLT3m4<-sapply(pPositionm4, function(x) FLT3_props[x])
  FLT3m3<-sapply(pPositionm3, function(x) FLT3_props[x])
  FLT3m2<-sapply(pPositionm2, function(x) FLT3_props[x])
  FLT3m1<-sapply(pPositionm1, function(x) FLT3_props[x])
  FLT3d0<-sapply(pPositiond0, function(x) FLT3_props[x])
  FLT3p1<-sapply(pPositionp1, function(x) FLT3_props[x])
  FLT3p2<-sapply(pPositionp2, function(x) FLT3_props[x])
  FLT3p3<-sapply(pPositionp3, function(x) FLT3_props[x])
  FLT3p4<-sapply(pPositionp4, function(x) FLT3_props[x])
  FLT3p5<-sapply(pPositionp5, function(x) FLT3_props[x])
  FLT3p6<-sapply(pPositionp6, function(x) FLT3_props[x])
  
  ALKm6<-sapply(pPositionm6, function(x) ALK_props[x])
  ALKm5<-sapply(pPositionm5, function(x) ALK_props[x])
  ALKm4<-sapply(pPositionm4, function(x) ALK_props[x])
  ALKm3<-sapply(pPositionm3, function(x) ALK_props[x])
  ALKm2<-sapply(pPositionm2, function(x) ALK_props[x])
  ALKm1<-sapply(pPositionm1, function(x) ALK_props[x])
  ALKd0<-sapply(pPositiond0, function(x) ALK_props[x])
  ALKp1<-sapply(pPositionp1, function(x) ALK_props[x])
  ALKp2<-sapply(pPositionp2, function(x) ALK_props[x])
  ALKp3<-sapply(pPositionp3, function(x) ALK_props[x])
  ALKp4<-sapply(pPositionp4, function(x) ALK_props[x])
  ALKp5<-sapply(pPositionp5, function(x) ALK_props[x])
  ALKp6<-sapply(pPositionp6, function(x) ALK_props[x])
}
#############################
#here's my plan: EITHER
#make each peptide with different values for each kinase's EPM
#OR
#make the peptides as I'm doing now, then use apply functions.  I think the first will be faster because I'm already spending time in the for loop
#so let's draw this out, the which function up above figures out which positions the kinase likes.  Then I need an apply function to turn those into AAs
#I think I need 13 different apply functions, one for each plus or minus position of the AAs, sofor positions m7 every AA because AAm7
#then I need 13 new apply functions, each with 13*20 values in them, which replace those values with individual values in the EPM table
#then I make the combinatorial library
#then I use an apply function to multiply all values together, which is how fisher does the scoring
########################################


total=length(Positionp6)*length(Positionp5)*length(Positionp4)*length(Positionp3)*(length(Positionp2))*length(Positionp1)*
  length(Positiond0)*length(Positionm1)*length(Positionm2)*length(Positionm3)*length(Positionm4)*length(Positionm5)*length(Positionm6)
#this is just a way to doublecheck that the length of the generated peptides vector is correct

GeneratedPeptides<-rep(NA, times=total*13)
GeneratedPeptides<-matrix(data = GeneratedPeptides,ncol = 13)


ThisKinPeptides<-GeneratedPeptides

AblPeptides<-GeneratedPeptides
ArgPeptides<-GeneratedPeptides
BtkPeptides<-GeneratedPeptides
CskPeptides<-GeneratedPeptides
FynPeptides<-GeneratedPeptides
HckPeptides<-GeneratedPeptides
JAK2Peptides<-GeneratedPeptides
LckPeptides<-GeneratedPeptides
LynPeptides<-GeneratedPeptides
Pyk2Peptides<-GeneratedPeptides
SrcPeptides<-GeneratedPeptides
SykPeptides<-GeneratedPeptides
YesPeptides<-GeneratedPeptides
FLT3Peptides<-GeneratedPeptides
ALKPeptides<-GeneratedPeptides

#create an empty vector of correct length by finding the number of each AAs per position and multiplying them
count<-0

# for (t in 1:length(Positionm7)) {
for (s in 1:length(Positionm6)) {
  for (r in 1:length(Positionm5)) {
    for (i in 1:length(Positionm4)) {
      for (j in 1:length(Positionm3)) {
        for (k in 1:length(Positionm2)) {
          for (l in 1:length(Positionm1)) {
            for (m in 1:length(Positiond0)) {
              for (n in 1:length(Positionp1)) {
                for (o in 1:length(Positionp2)) {
                  for (p in 1:length(Positionp3)) {
                    for (q in 1:length(Positionp4)) {
                      for (u in 1:length(Positionp5)) {
                        for (v in 1:length(Positionp6)) {
                          # for (w in 1:length(Positionp7)) {
                          # i=1
                          # j=1
                          # k=1
                          # l=1
                          # m=1
                          # n=1
                          # o=1
                          # p=1
                          # q=1
                          # 
                          #for every single position, increment the count number, create a peptide using the AAs at that position
                          #then put them together into the generated peptides sequencex
                          count<-count+1
                          tabulation<-c(Positionm6[s],Positionm5[r],Positionm4[i],Positionm3[j],Positionm2[k],Positionm1[l],Positiond0[m],Positionp1[n],
                                        Positionp2[o],Positionp3[p],Positionp4[q],Positionp5[u],Positionp6[v])
                          # numeration<-c(number14[s],number13[r],number1[i],number2[j],number3[k],number4[l],number5[m],number6[n],number7[o],number8[p],number9[q],number10[u],number11[v])
                          #tabulation<-paste(tabulation, sep="", collapse="")
                          GeneratedPeptides[count,1:13]<-tabulation
                          # NumeratedPeptides[count,1:13]<-numeration
                          
                          ThisKinTableNumeration<-c(ThisKinTablem6[s],ThisKinTablem5[r],ThisKinTablem4[i],ThisKinTablem3[j],ThisKinTablem2[k],ThisKinTablem1[l],ThisKinTabled0[m],ThisKinTablep1[n],
                                                    ThisKinTablep2[o],ThisKinTablep3[p],ThisKinTablep4[q],ThisKinTablep5[u],ThisKinTablep6[v])
                          
                          AblNumeration<-c(Ablm6[s],Ablm5[r],Ablm4[i],Ablm3[j],Ablm2[k],Ablm1[l],Abld0[m],Ablp1[n],
                                           Ablp2[o],Ablp3[p],Ablp4[q],Ablp5[u],Ablp6[v])
                          ArgNumeration<-c(Argm6[s],Argm5[r],Argm4[i],Argm3[j],Argm2[k],Argm1[l],Argd0[m],Argp1[n],
                                           Argp2[o],Argp3[p],Argp4[q],Argp5[u],Argp6[v])
                          BtkNumeration<-c(Btkm6[s],Btkm5[r],Btkm4[i],Btkm3[j],Btkm2[k],Btkm1[l],Btkd0[m],Btkp1[n],
                                           Btkp2[o],Btkp3[p],Btkp4[q],Btkp5[u],Btkp6[v])
                          CskNumeration<-c(Cskm6[s],Cskm5[r],Cskm4[i],Cskm3[j],Cskm2[k],Cskm1[l],Cskd0[m],Cskp1[n],
                                           Cskp2[o],Cskp3[p],Cskp4[q],Cskp5[u],Cskp6[v])
                          FynNumeration<-c(Fynm6[s],Fynm5[r],Fynm4[i],Fynm3[j],Fynm2[k],Fynm1[l],Fynd0[m],Fynp1[n],
                                           Fynp2[o],Fynp3[p],Fynp4[q],Fynp5[u],Fynp6[v])
                          HckNumeration<-c(Hckm6[s],Hckm5[r],Hckm4[i],Hckm3[j],Hckm2[k],Hckm1[l],Hckd0[m],Hckp1[n],
                                           Hckp2[o],Hckp3[p],Hckp4[q],Hckp5[u],Hckp6[v])
                          JAK2Numeration<-c(JAK2m6[s],JAK2m5[r],JAK2m4[i],JAK2m3[j],JAK2m2[k],JAK2m1[l],JAK2d0[m],JAK2p1[n],
                                            JAK2p2[o],JAK2p3[p],JAK2p4[q],JAK2p5[u],JAK2p6[v])
                          LckNumeration<-c(Lckm6[s],Lckm5[r],Lckm4[i],Lckm3[j],Lckm2[k],Lckm1[l],Lckd0[m],Lckp1[n],
                                           Lckp2[o],Lckp3[p],Lckp4[q],Lckp5[u],Lckp6[v])
                          LynNumeration<-c(Lynm6[s],Lynm5[r],Lynm4[i],Lynm3[j],Lynm2[k],Lynm1[l],Lynd0[m],Lynp1[n],
                                           Lynp2[o],Lynp3[p],Lynp4[q],Lynp5[u],Lynp6[v])
                          Pyk2Numeration<-c(Pyk2m6[s],Pyk2m5[r],Pyk2m4[i],Pyk2m3[j],Pyk2m2[k],Pyk2m1[l],Pyk2d0[m],Pyk2p1[n],
                                            Pyk2p2[o],Pyk2p3[p],Pyk2p4[q],Pyk2p5[u],Pyk2p6[v])
                          SrcNumeration<-c(Srcm6[s],Srcm5[r],Srcm4[i],Srcm3[j],Srcm2[k],Srcm1[l],Srcd0[m],Srcp1[n],
                                           Srcp2[o],Srcp3[p],Srcp4[q],Srcp5[u],Srcp6[v])
                          SykNumeration<-c(Sykm6[s],Sykm5[r],Sykm4[i],Sykm3[j],Sykm2[k],Sykm1[l],Sykd0[m],Sykp1[n],
                                           Sykp2[o],Sykp3[p],Sykp4[q],Sykp5[u],Sykp6[v])
                          YesNumeration<-c(Yesm6[s],Yesm5[r],Yesm4[i],Yesm3[j],Yesm2[k],Yesm1[l],Yesd0[m],Yesp1[n],
                                           Yesp2[o],Yesp3[p],Yesp4[q],Yesp5[u],Yesp6[v])
                          FLT3Numeration<-c(FLT3m6[s],FLT3m5[r],FLT3m4[i],FLT3m3[j],FLT3m2[k],FLT3m1[l],FLT3d0[m],FLT3p1[n],
                                            FLT3p2[o],FLT3p3[p],FLT3p4[q],FLT3p5[u],FLT3p6[v])
                          ALKNumeration<-c(ALKm6[s],ALKm5[r],ALKm4[i],ALKm3[j],ALKm2[k],ALKm1[l],ALKd0[m],ALKp1[n],
                                           ALKp2[o],ALKp3[p],ALKp4[q],ALKp5[u],ALKp6[v])
                          
                          ThisKinPeptides[count,1:13]<-as.numeric(ThisKinTableNumeration)
                          
                          AblPeptides[count,1:13]<-AblNumeration
                          ArgPeptides[count,1:13]<-ArgNumeration
                          BtkPeptides[count,1:13]<-BtkNumeration
                          CskPeptides[count,1:13]<-CskNumeration
                          FynPeptides[count,1:13]<-FynNumeration
                          HckPeptides[count,1:13]<-HckNumeration
                          JAK2Peptides[count,1:13]<-JAK2Numeration
                          LckPeptides[count,1:13]<-LckNumeration
                          LynPeptides[count,1:13]<-LynNumeration
                          Pyk2Peptides[count,1:13]<-Pyk2Numeration
                          SrcPeptides[count,1:13]<-SrcNumeration
                          SykPeptides[count,1:13]<-SykNumeration
                          YesPeptides[count,1:13]<-YesNumeration
                          FLT3Peptides[count,1:13]<-FLT3Numeration
                          ALKPeptides[count,1:13]<-ALKNumeration
                          
                          
                          
                          # }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
# }

ThisKinPeptides<-as.data.frame(ThisKinPeptides)
ThisKinPeptides$V1<-as.numeric(ThisKinPeptides$V1)
ThisKinPeptides$V2<-as.numeric(ThisKinPeptides$V2)
ThisKinPeptides$V3<-as.numeric(ThisKinPeptides$V3)
ThisKinPeptides$V4<-as.numeric(ThisKinPeptides$V4)
ThisKinPeptides$V5<-as.numeric(ThisKinPeptides$V5)
ThisKinPeptides$V6<-as.numeric(ThisKinPeptides$V6)
ThisKinPeptides$V7<-as.numeric(ThisKinPeptides$V7)
ThisKinPeptides$V8<-as.numeric(ThisKinPeptides$V8)
ThisKinPeptides$V9<-as.numeric(ThisKinPeptides$V9)
ThisKinPeptides$V10<-as.numeric(ThisKinPeptides$V10)
ThisKinPeptides$V11<-as.numeric(ThisKinPeptides$V11)
ThisKinPeptides$V12<-as.numeric(ThisKinPeptides$V12)
ThisKinPeptides$V13<-as.numeric(ThisKinPeptides$V13)
ThisKinGeneratedScores<-with(ThisKinPeptides, V1*V2*V3*V4*V5*V6*V7*V8*V9*V10*V11*V12*V13)

AblPeptides<-as.data.frame(AblPeptides)
AblGeneratedScores<-with(AblPeptides, V1*V2*V3*V4*V5*V6*V7*V8*V9*V10*V11*V12*V13)
ArgPeptides<-as.data.frame(ArgPeptides)
ArgGeneratedScores<-with(ArgPeptides, V1*V2*V3*V4*V5*V6*V7*V8*V9*V10*V11*V12*V13)
BtkPeptides<-as.data.frame(BtkPeptides)
BtkGeneratedScores<-with(BtkPeptides, V1*V2*V3*V4*V5*V6*V7*V8*V9*V10*V11*V12*V13)
CskPeptides<-as.data.frame(CskPeptides)
CskGeneratedScores<-with(CskPeptides, V1*V2*V3*V4*V5*V6*V7*V8*V9*V10*V11*V12*V13)
FynPeptides<-as.data.frame(FynPeptides)
FynGeneratedScores<-with(FynPeptides, V1*V2*V3*V4*V5*V6*V7*V8*V9*V10*V11*V12*V13)
HckPeptides<-as.data.frame(HckPeptides)
HckGeneratedScores<-with(HckPeptides, V1*V2*V3*V4*V5*V6*V7*V8*V9*V10*V11*V12*V13)
JAK2Peptides<-as.data.frame(JAK2Peptides)
JAK2GeneratedScores<-with(JAK2Peptides, V1*V2*V3*V4*V5*V6*V7*V8*V9*V10*V11*V12*V13)
LckPeptides<-as.data.frame(LckPeptides)
LckGeneratedScores<-with(LckPeptides, V1*V2*V3*V4*V5*V6*V7*V8*V9*V10*V11*V12*V13)
LynPeptides<-as.data.frame(LynPeptides)
LynGeneratedScores<-with(LynPeptides, V1*V2*V3*V4*V5*V6*V7*V8*V9*V10*V11*V12*V13)
Pyk2Peptides<-as.data.frame(Pyk2Peptides)
Pyk2GeneratedScores<-with(Pyk2Peptides, V1*V2*V3*V4*V5*V6*V7*V8*V9*V10*V11*V12*V13)
SrcPeptides<-as.data.frame(SrcPeptides)
SrcGeneratedScores<-with(SrcPeptides, V1*V2*V3*V4*V5*V6*V7*V8*V9*V10*V11*V12*V13)
SykPeptides<-as.data.frame(SykPeptides)
SykGeneratedScores<-with(SykPeptides, V1*V2*V3*V4*V5*V6*V7*V8*V9*V10*V11*V12*V13)
YesPeptides<-as.data.frame(YesPeptides)
YesGeneratedScores<-with(YesPeptides, V1*V2*V3*V4*V5*V6*V7*V8*V9*V10*V11*V12*V13)
FLT3Peptides<-as.data.frame(FLT3Peptides)
FLT3GeneratedScores<-with(FLT3Peptides, V1*V2*V3*V4*V5*V6*V7*V8*V9*V10*V11*V12*V13)
ALKPeptides<-as.data.frame(ALKPeptides)
ALKGeneratedScores<-with(ALKPeptides, V1*V2*V3*V4*V5*V6*V7*V8*V9*V10*V11*V12*V13)

AblGeneratedScores<-as.matrix(AblGeneratedScores, ncol=1)
AblNorm<-AblNorm<-1/as.numeric(Abl[22,1])
AblNormColumn<-as.matrix(rep(AblNorm,times=nrow(AblGeneratedScores)),ncol=1)
AblGeneratedScores<-cbind(AblGeneratedScores,AblNormColumn)
AblGeneratedScores<-as.data.frame(AblGeneratedScores)
AblGeneratedScores<-with(AblGeneratedScores, V1/(V1+V2))

ArgGeneratedScores<-as.matrix(ArgGeneratedScores, ncol=1)
ArgNorm<-ArgNorm<-1/as.numeric(Arg[22,1])
ArgNormColumn<-as.matrix(rep(ArgNorm,times=nrow(ArgGeneratedScores)),ncol=1)
ArgGeneratedScores<-cbind(ArgGeneratedScores,ArgNormColumn)
ArgGeneratedScores<-as.data.frame(ArgGeneratedScores)
ArgGeneratedScores<-with(ArgGeneratedScores, V1/(V1+V2))

BtkGeneratedScores<-as.matrix(BtkGeneratedScores, ncol=1)
BtkNorm<-BtkNorm<-1/as.numeric(Btk[22,1])
BtkNormColumn<-as.matrix(rep(BtkNorm,times=nrow(BtkGeneratedScores)),ncol=1)
BtkGeneratedScores<-cbind(BtkGeneratedScores,BtkNormColumn)
BtkGeneratedScores<-as.data.frame(BtkGeneratedScores)
BtkGeneratedScores<-with(BtkGeneratedScores, V1/(V1+V2))

CskGeneratedScores<-as.matrix(CskGeneratedScores, ncol=1)
CskNorm<-CskNorm<-1/as.numeric(Csk[22,1])
CskNormColumn<-as.matrix(rep(CskNorm,times=nrow(CskGeneratedScores)),ncol=1)
CskGeneratedScores<-cbind(CskGeneratedScores,CskNormColumn)
CskGeneratedScores<-as.data.frame(CskGeneratedScores)
CskGeneratedScores<-with(CskGeneratedScores, V1/(V1+V2))

FynGeneratedScores<-as.matrix(FynGeneratedScores, ncol=1)
FynNorm<-FynNorm<-1/as.numeric(Fyn[22,1])
FynNormColumn<-as.matrix(rep(FynNorm,times=nrow(FynGeneratedScores)),ncol=1)
FynGeneratedScores<-cbind(FynGeneratedScores,FynNormColumn)
FynGeneratedScores<-as.data.frame(FynGeneratedScores)
FynGeneratedScores<-with(FynGeneratedScores, V1/(V1+V2))

HckGeneratedScores<-as.matrix(HckGeneratedScores, ncol=1)
HckNorm<-HckNorm<-1/as.numeric(Hck[22,1])
HckNormColumn<-as.matrix(rep(HckNorm,times=nrow(HckGeneratedScores)),ncol=1)
HckGeneratedScores<-cbind(HckGeneratedScores,HckNormColumn)
HckGeneratedScores<-as.data.frame(HckGeneratedScores)
HckGeneratedScores<-with(HckGeneratedScores, 100*V1/(V1+V2))

JAK2GeneratedScores<-as.matrix(JAK2GeneratedScores, ncol=1)
JAK2Norm<-JAK2Norm<-1/as.numeric(JAK2[22,1])
JAK2NormColumn<-as.matrix(rep(JAK2Norm,times=nrow(JAK2GeneratedScores)),ncol=1)
JAK2GeneratedScores<-cbind(JAK2GeneratedScores,JAK2NormColumn)
JAK2GeneratedScores<-as.data.frame(JAK2GeneratedScores)
JAK2GeneratedScores<-with(JAK2GeneratedScores, 100*V1/(V1+V2))

LckGeneratedScores<-as.matrix(LckGeneratedScores, ncol=1)
LckNorm<-LckNorm<-1/as.numeric(Lck[22,1])
LckNormColumn<-as.matrix(rep(LckNorm,times=nrow(LckGeneratedScores)),ncol=1)
LckGeneratedScores<-cbind(LckGeneratedScores,LckNormColumn)
LckGeneratedScores<-as.data.frame(LckGeneratedScores)
LckGeneratedScores<-with(LckGeneratedScores, 100*V1/(V1+V2))

LynGeneratedScores<-as.matrix(LynGeneratedScores, ncol=1)
LynNorm<-LynNorm<-1/as.numeric(Lyn[22,1])
LynNormColumn<-as.matrix(rep(LynNorm,times=nrow(LynGeneratedScores)),ncol=1)
LynGeneratedScores<-cbind(LynGeneratedScores,LynNormColumn)
LynGeneratedScores<-as.data.frame(LynGeneratedScores)
LynGeneratedScores<-with(LynGeneratedScores, 100*V1/(V1+V2))

Pyk2GeneratedScores<-as.matrix(Pyk2GeneratedScores, ncol=1)
Pyk2Norm<-Pyk2Norm<-1/as.numeric(Pyk2[22,1])
Pyk2NormColumn<-as.matrix(rep(Pyk2Norm,times=nrow(Pyk2GeneratedScores)),ncol=1)
Pyk2GeneratedScores<-cbind(Pyk2GeneratedScores,Pyk2NormColumn)
Pyk2GeneratedScores<-as.data.frame(Pyk2GeneratedScores)
Pyk2GeneratedScores<-with(Pyk2GeneratedScores, 100*V1/(V1+V2))

SrcGeneratedScores<-as.matrix(SrcGeneratedScores, ncol=1)
SrcNorm<-SrcNorm<-1/as.numeric(Src[22,1])
SrcNormColumn<-as.matrix(rep(SrcNorm,times=nrow(SrcGeneratedScores)),ncol=1)
SrcGeneratedScores<-cbind(SrcGeneratedScores,SrcNormColumn)
SrcGeneratedScores<-as.data.frame(SrcGeneratedScores)
SrcGeneratedScores<-with(SrcGeneratedScores, 100*V1/(V1+V2))

SykGeneratedScores<-as.matrix(SykGeneratedScores, ncol=1)
SykNorm<-SykNorm<-1/as.numeric(Syk[22,1])
SykNormColumn<-as.matrix(rep(SykNorm,times=nrow(SykGeneratedScores)),ncol=1)
SykGeneratedScores<-cbind(SykGeneratedScores,SykNormColumn)
SykGeneratedScores<-as.data.frame(SykGeneratedScores)
SykGeneratedScores<-with(SykGeneratedScores, 100*V1/(V1+V2))

YesGeneratedScores<-as.matrix(YesGeneratedScores, ncol=1)
YesNorm<-YesNorm<-1/as.numeric(Yes[22,1])
YesNormColumn<-as.matrix(rep(YesNorm,times=nrow(YesGeneratedScores)),ncol=1)
YesGeneratedScores<-cbind(YesGeneratedScores,YesNormColumn)
YesGeneratedScores<-as.data.frame(YesGeneratedScores)
YesGeneratedScores<-with(YesGeneratedScores, 100*V1/(V1+V2))

FLT3GeneratedScores<-as.matrix(FLT3GeneratedScores, ncol=1)
FLT3Norm<-FLT3Norm<-1/as.numeric(FLT3[22,1])
FLT3NormColumn<-as.matrix(rep(FLT3Norm,times=nrow(FLT3GeneratedScores)),ncol=1)
FLT3GeneratedScores<-cbind(FLT3GeneratedScores,FLT3NormColumn)
FLT3GeneratedScores<-as.data.frame(FLT3GeneratedScores)
FLT3GeneratedScores<-with(FLT3GeneratedScores, 100*V1/(V1+V2))

ALKGeneratedScores<-as.matrix(ALKGeneratedScores, ncol=1)
ALKNorm<-ALKNorm<-1/as.numeric(ALK[22,1])
ALKNormColumn<-as.matrix(rep(ALKNorm,times=nrow(ALKGeneratedScores)),ncol=1)
ALKGeneratedScores<-cbind(ALKGeneratedScores,ALKNormColumn)
ALKGeneratedScores<-as.data.frame(ALKGeneratedScores)
ALKGeneratedScores<-with(ALKGeneratedScores, 100*V1/(V1+V2))

ThisKinGeneratedScores1<-as.matrix(ThisKinGeneratedScores, ncol=1)
ThisKinNorm<-ThisKinNorm<-1/as.numeric(NormalizationScore)
ThisKinNormColumn<-as.matrix(rep(ThisKinNorm,times=nrow(ThisKinGeneratedScores1)),ncol=1)
ThisKinGeneratedScores1<-cbind(ThisKinGeneratedScores1,ThisKinNormColumn)
ThisKinGeneratedScores1<-as.data.frame(ThisKinGeneratedScores1)
ThisKinGeneratedScores1<-with(ThisKinGeneratedScores1, V1/(V1+V2))

AblThresh<-as.numeric(Abl[24,1])
AblActive<-unlist(AblGeneratedScores)>AblThresh/100
ArgThresh<-as.numeric(Arg[24,1])
ArgActive<-unlist(ArgGeneratedScores)>ArgThresh/100
BtkThresh<-as.numeric(Btk[24,1])
BtkActive<-unlist(BtkGeneratedScores)>BtkThresh/100
CskThresh<-as.numeric(Csk[24,1])
CskActive<-(CskGeneratedScores)>CskThresh/100
FynThresh<-as.numeric(Fyn[24,1])
FynActive<-unlist(FynGeneratedScores)>FynThresh/100
HckThresh<-as.numeric(Hck[24,1])
HckActive<-unlist(HckGeneratedScores)>HckThresh/100
JAK2Thresh<-as.numeric(JAK2[24,1])
JAk2Active<-unlist(JAK2GeneratedScores)>JAK2Thresh/100
LckThresh<-as.numeric(Lck[24,1])
LckActive<-unlist(LckGeneratedScores)>LckThresh/100
LynThresh<-as.numeric(Lyn[24,1])
LynActive<-unlist(LynGeneratedScores)>LynThresh/100
Pyk2Thresh<-as.numeric(Pyk2[24,1])
Pyk2Active<-unlist(Pyk2GeneratedScores)>Pyk2Thresh/100
SrcThresh<-as.numeric(Src[24,1])
SrcActive<-unlist(SrcGeneratedScores)>SrcThresh/100
SykThresh<-as.numeric(Syk[24,1])
SykActive<-unlist(SykGeneratedScores)>SykThresh/100
YesThresh<-as.numeric(Yes[24,1])
YesActive<-unlist(YesGeneratedScores)>YesThresh/100
ALKThresh<-as.numeric(ALK[24,1])
ALKActive<-unlist(ALKGeneratedScores)>ALKThresh/100
FLT3Thresh<-as.numeric(FLT3[24,1])
FLT3Active<-unlist(FLT3GeneratedScores)>FLT3Thresh/100


AllActive<-AblActive+ArgActive+BtkActive+CskActive+FynActive+HckActive+JAk2Active+LckActive+LynActive+Pyk2Active+SrcActive+SykActive+YesActive+ALKActive+FLT3Active
Scores<-ThisKinGeneratedScores
ThresholdValues<-ThisKinGeneratedScores1

FullMotifs<-rep("Z",times=nrow(GeneratedPeptides))
for (i in 1:nrow(GeneratedPeptides)) {
  motif<-GeneratedPeptides[i,1:13]
  motif<-paste(motif,sep = "", collapse = "")
  FullMotifs[i]<-motif
}

Scores<-1/Scores

PeptidesWithRanks<-cbind.data.frame(FullMotifs,GeneratedPeptides,Scores,ThresholdValues)

PeptidesWithRanks<-cbind.data.frame(PeptidesWithRanks,AllActive,AblActive,ArgActive,BtkActive,CskActive,FynActive,HckActive,JAk2Active,LckActive,LynActive,Pyk2Active,SrcActive,SykActive,YesActive)
RanksPeptides<-PeptidesWithRanks[order(PeptidesWithRanks$AllActive,
                                       PeptidesWithRanks$Scores,
                                       decreasing = FALSE),]

RanksPeptides$Scores<-1/RanksPeptides$Scores

#RanksPeptides$Scores<-1/RanksPeptides$Scores

#I want to see how much of the sequence space we still have available.  I should do so

write.table(RanksPeptides,file = "output.csv",append = FALSE,row.names = FALSE,col.names = TRUE,sep = ",")

# })

options(warn=0)