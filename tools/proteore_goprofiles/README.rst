Galaxy wrappers for goProfiles Tool
===================================

**Authors** 

Sanchez A, Ocana J and Salicru M (2016). goProfiles: goProfiles: an R package for the statistical analysis of functional profiles. R package version 1.38.0.

**Galaxy integration**

T.P. Lien Nguyen, Florence Combes, Yves Vandenbrouck CEA, INSERM, CNRS, Grenoble-Alpes University, BIG Institute, FR

Sandra Dérozier, Olivier Rué, Christophe Caron, Valentin Loux INRA, Paris-Saclay University, MAIAGE Unit,Migale Bioinformatics platform,

Contact support@proteore.org for any questions or concerns about the Galaxy implementation of this tool.

-----------------------------------

This tool, based on the goProfiles R package, performs statistical analysis of functional profiles. It is based on GO ontology and considers either a gene set ('Entrez’ Identifiers) or a protein set (Uniprot ID) as input. 

You can choose one or more GO categories: 

* Biological Process (BP) 
* Cellular Component (CC) 
* Molecular Function (MF) 

Functional profile at a given GO level is obtained by counting the number of identifiers having a hit in each category of this level (2 by default). Results are displayed as bar plots (with absolute or relative frequencies) and can be exported in pdf, png and jpeg formats.  

For more details about GoProfiles, please read: Salicrú et al. Comparison of lists of genes based on functional profiles. BMC Bioinformatics. 2011;12:401.(https://bmcbioinformatics.biomedcentral.com/articles/10.1186/1471-2105-12-401)  

If your type of identifiers is not supported (i.e. different form Uniprot and Entrez), please use the **ID Converter** component in the ProteoRE section to convert your list of IDs first.


**Packages used**
    - bioconductor-org.hs.eg.db v3.5.0
    - bioconductor-org.mm.eg.db v3.5.0
    - bioconductor-annotationdbi v1.40.0
    - bioconductor-biobase v2.98.0
    - goprofiles v1.38.0
