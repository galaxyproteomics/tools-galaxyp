Wrapper for clusterProfiler Tool
================================

**Authors**
 
clusterProfiler R package reference : 
G Yu, LG Wang, Y Han, QY He. clusterProfiler: an R package for comparing biological themes among gene clusters. 
OMICS: A Journal of Integrative Biology 2012, 16(5):284-287. 
doi:[10.1089/omi.2011.0118](http://dx.doi.org/10.1089/omi.2011.0118)

	
**Galaxy integration**

T.P. Lien Nguyen, Florence Combes, Yves Vandenbrouck CEA, INSERM, CNRS, Grenoble-Alpes University, BIG Institute, FR

Sandra Dérozier, Olivier Rué, Christophe Caron, Valentin Loux INRA, Paris-Saclay University, MAIAGE Unit, Migale Bioinformatics platform

This work has been partially funded through the French National Agency for Research (ANR) IFB project.

Contact support@proteore.org for any questions or concerns about the Galaxy implementation of this tool.


--------------------------------

**Galaxy component based on R package clusterProfiler (see ref below)**
 	
This component allows to perform GO enrichment-analyses. 
Given a list of IDs, the tool either 
(i)  performs gene classification based on GO distribution at a specific level, or
(ii) calculates GO categories enrichment (over- or under-representation) for the IDs of the input list, 
compared to a background (whole organism or user-defined list). 

**Input required**
    
This component works with Gene ids (e.g : 4151, 7412) or Uniprot accession number (e.g. P31946). 
You can copy/paste these identifiers or supply a tabular file (.csv, .tsv, .txt, .tab) where there are contained.

 
**Output**

Text (tables) and graphics representing the repartition and/or enrichment of GO categories. 

**Packages used** 
    - bioconductor-org.hs.eg.db v3.5.0
    - bioconductor-org.mm.eg.db v3.5.0
    - bioconductor-org.rn.eg.db v3.5.0
    - dose v3.2.0
    - clusterpofiler v 3.4.4

**User manual / Documentation** of the clusterProfiler R package (functions and parameters):
https://bioconductor.org/packages/3.7/bioc/vignettes/clusterProfiler/inst/doc/clusterProfiler.html
(Very well explained)