library("pathview")

read_file <- function(path,header){
    file <- try(read.table(path,header=TRUE, sep="\t",stringsAsFactors = FALSE),silent=TRUE)
    if (inherits(file,"try-error")){
      stop("File not found !")
    }else{
      return(file)
    }
}

tab <- read_file("/home/dchristiany/proteore_project/ProteoRE/tools/pathview/test-data/Lacombe_et_al_id_converted.csv",TRUE)

data(gse16873.d)
data(demo.paths)

tmp <- gse16873.d[,1][1:nrow(tab)]
names(tmp) <- tab$GeneID
tmp

geneID = tab$GeneID[which(tab$GeneID !="NA")]
geneID = gsub(" ","",geneID)
geneID = unlist(strsplit(geneID,"[;]"))

tmp=c(rep(-1,length(geneID)))
names(tmp) <- geneID

pathview(gene.data = tmp, 
         cpd.data = NULL, 
         pathway.id = "00010",
         #pathway.name = "hsa01200",
         species = "hsa", 
         kegg.dir = "pathways", 
         cpd.idtype = "kegg", 
         gene.idtype = "entrez", 
         gene.annotpkg = NULL, 
         min.nnodes = 3, 
         kegg.native = FALSE,
         map.null = TRUE, 
         expand.node = FALSE, 
         split.group = FALSE, 
         map.symbol = TRUE, 
         map.cpdname = TRUE, 
         node.sum = "sum", 
         discrete=list(gene=FALSE,cpd=FALSE), 
         limit = list(gene = 1, cpd = 1), 
         bins = list(gene = 10, cpd = 10), 
         both.dirs = list(gene = T, cpd = T), 
         trans.fun = list(gene = NULL, cpd = NULL), 
         low = list(gene = "green", cpd = "blue"), 
         mid = list(gene = "gray", cpd = "gray"), 
         high = list(gene = "red", cpd = "yellow"), 
         na.col = "transparent",
         sign.pos="bottomleft",
         key.pos="topright",
         new.signature=TRUE,
         rankdir="LB",
         cex=0.3,
         text.width=15,
         res=600,
         pdf.size=c(7,7),
         is.signal=TRUE)


 #KEGG view: gene data only
i <- 1
pv.out <- pathview(gene.data = gse16873.d[, 1], pathway.id = demo.paths$sel.paths[i], species = "hsa", out.suffix = "gse16873",
                   kegg.native = TRUE)
str(pv.out)
head(pv.out$plot.data.gene)
#result PNG file in current directory

#Graphviz view: gene data only
pv.out <- keggview.native(gene.data = gse16873.d[,1], 
                   pathway.id = demo.paths$sel.paths[1], 
                   species = "hsa", out.suffix = "gse16873",
                   kegg.native = TRUE, sign.pos = "bottomleft")
#result PDF file in current directory




#KEGG view: both gene and compound data
sim.cpd.data=sim.mol.data(mol.type="cpd", nmol=3000)
i <- 3
print(demo.paths$sel.paths[i])
pv.out <- pathview(gene.data = gse16873.d[, 1], cpd.data = sim.cpd.data,
                   pathway.id = demo.paths$sel.paths[i], species = "hsa", out.suffix =
                     "gse16873.cpd", keys.align = "y", kegg.native = TRUE, key.pos = demo.paths$kpos1[i])
str(pv.out)
head(pv.out$plot.data.cpd)

set.seed(10)
sim.cpd.data2 = matrix(sample(sim.cpd.data, 18000, 
                              replace = TRUE), ncol = 6)
pv.out <- pathview(gene.data = gse16873.d[, 1:3], 
                   cpd.data = sim.cpd.data2[, 1:2], pathway.id = demo.paths$sel.paths[i], 
                   species = "hsa", out.suffix = "gse16873.cpd.3-2s", keys.align = "y", 
                   kegg.native = TRUE, match.data = FALSE, multi.state = TRUE, same.layer = TRUE)
str(pv.out)
head(pv.out$plot.data.cpd)
