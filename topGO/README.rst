Wrapper for topGO Tool
======================

**Authors**

Alexa A and Rahnenfuhrer J (2016). topGO: Enrichment Analysis for Gene Ontology. R package version 2.30.0.

**Galaxy integration**

Lisa Perus, T.P. Lien Nguyen, Florence Combes, Yves Vandenbrouck CEA, INSERM, CNRS, Grenoble-Alpes University, BIG Institute, FR

Sandra Dérozier, Olivier Rué, Christophe Caron, Valentin Loux INRA, Paris-Saclay University, MAIAGE Unit, Migale Bioinformatics platform

This work has been partially funded through the French National Agency for Research (ANR) IFB project.

Contact support@proteore.org for any questions or concerns about the Galaxy implementation of this tool.

----------------------

**Galaxy component based on R package topGO.** 

**Input required**

This component works with Ensembl gene ids (e.g : ENSG0000013618). You can
copy/paste these identifiers or supply a tabular file (.csv, .tsv, .txt, .tab)
where there are contained. 

**Principle**

This component provides the GO terms representativity of a gene list in one ontology category (Biological Process "BP", Cellular Component "CC", Molecular Function "MF"). This representativity is evaluated in comparison to the background list of all human genes associated associated with GO terms of the chosen category (BP,CC,MF). This background is given by the R package "org.Hs.eg.db", which is a genome wide association package for **human**.

**Output**

Three kind of outputs are available : a textual output, a barplot output and
a dotplot output. 

*Textual output* :
The text output lists all the GO-terms that were found significant under the specified threshold.    


The different fields are as follow :

- Annotated : number of genes in org.Hs.eg.db which are annotated with the GO-term.

- Significant : number of genes belonging to your input which are annotated with the GO-term. 

- Expected : show an estimate of the number of genes a node of size Annotated would have if the significant genes were to be randomly selected from the gene universe.  

- pvalues : pvalue obtained after the test 

- ( qvalues  : additional column with adjusted pvalues ) 

 
**Tests**

topGO provides a classic fisher test for evaluating if some GO terms are over-represented in your gene list, but other options are also provided (elim, weight01,parentchild). For the merits of each option and their algorithmic descriptions, please refer to topGO manual : 
https://bioconductor.org/packages/release/bioc/vignettes/topGO/inst/doc/topGO.pdf

**Multiple testing corrections**
    
Furthermore, the following corrections for multiple testing can also be applied : 
- holm
- hochberg
- hommel
- bonferroni
- BH
- BY
- fdr

**Packages used**
    - bioconductor-org.hs.eg.db v3.5.0
    - bioconductor-org.mm.eg.db v3.5.0
    - bioconductor-org.rn.eg.db v3.5.0
    - bioconductor-annotationdbi v1.40.0
    - bioconductor-go.db v3.5.0
    - bioconductor-graph v1.56.0
    - bioconductor-topgo v2.30.0