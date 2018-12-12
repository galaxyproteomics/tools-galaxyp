Wrapper for Get expression profiles by tissue Tool
=================================================

**Authors**

T.P. Lien Nguyen, Florence Combes, Yves Vandenbrouck CEA, INSERM, CNRS, Grenoble-Alpes University, BIG Institute, FR

Sandra Dérozier, Olivier Rué, Christophe Caron, Valentin Loux INRA, Paris-Saclay University, MAIAGE Unit, Migale Bioinformatics platform

This work has been partially funded through the French National Agency for Research (ANR) IFB project.

Contact support@proteore.org for any questions or concerns about the Galaxy implementation of this tool.

-------------------------------------------------

This tool retrieve information from Human Protein Atlas (https://www.proteinatlas.org/) regarding the expression profiles of human genes both on the mRNA and protein level. 

A list of ENSG (Ensembl gene) IDs must be entered (either via a copy/paste or by choosing a file), if it's not the case, please use the ID_Convert tool from ProteoRE.

The resources from Human Protein Atlas that can be queried are the following: 

* **Human normal tissue data**: expression profiles for proteins in human tissues based on immunohistochemisty using tissue micro arrays.

  The tab-separated file includes Ensembl gene identifier ("Gene"), tissue name ("Tissue"), annotated cell type ("Cell type"), expression value ("Level"), and the gene reliability of the expression value ("Reliability"). 

  The data is based on The Human Protein Atlas version 18 and Ensembl version 88.38.

* **Human tumor tissue data**: staining profiles for proteins in human tumor tissue based on immunohistochemisty using tissue micro arrays and log-rank P value for Kaplan-Meier analysis of correlation between mRNA expression level and patient survival. 

  The tab-separated file includes Ensembl gene identifier ("Gene"), gene name ("Gene name"), tumor name ("Cancer"), the number of patients annotated for different staining levels ("High", "Medium", "Low" & "Not detected") and log-rank p values for patient survival and mRNA correlation ("prognostic - favourable", "unprognostic - favourable", "prognostic - unfavourable", "unprognostic - unfavourable").

  The data is based on The Human Protein Atlas version 18 and Ensembl version 88.38.