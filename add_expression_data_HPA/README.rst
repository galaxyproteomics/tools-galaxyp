Wrapper for Add expression data to your protein list Tool
=========================================================
**Authors**

Lisa Peru, T.P. Lien Nguyen, Florence Combes, Yves Vandenbrouck CEA, INSERM, CNRS, Grenoble-Alpes University, BIG Institute, FR

Sandra Dérozier, Olivier Rué, Christophe Caron, Valentin Loux INRA, Paris-Saclay University, MAIAGE Unit, Migale Bioinformatics platform

This work has been partially funded through the French National Agency for Research (ANR) IFB project.

Contact support@proteore.org for any questions or concerns about the Galaxy implementation of this tool.

---------------------------------------------------------

This tool adds expression information (RNAseq- or antibody-based experiments) from the Human Protein Atlas (HPA) database (https://www.proteinatlas.org/) to your protein list.

**Input**

Input can be either a list of Ensembl gene ids (copy/paste) or a file containing multiple fields but with **at least one column of Ensembl gene IDs**. If your input file contains other type of IDs, please use the ID_Converter tool to create a column of Ensembl gene IDs.  

**Databases**

HPA source file:  http://www.proteinatlas.org/download/proteinatlas.tab.gz

**Annotation**

- Gene name: according to the HGNC (Hugo Gene Nomenclature Committee) 

- Gene description: entry description (full text)  

- Evidence: at protein level, at transcript level or no evidence

- Antibody reference: reference of the HPA antibody used for immunohistochemistry and immunocytochemistry/IF

- RNA tissue category: categories based on RNA-Seq data to estimate the transcript abundance of each protein-coding gene in tissues. For more information, please refer to http://www.proteinatlas.org/about/assays+annotation#rna .

- IH detection level: level of detection of the protein associated to the coding gene tissues based on immunofluorescency. For more information, please refer to http://www.proteinatlas.org/about/assays+annotation#if .

- IF detection level:level of detection of the protein associated to the coding gene tissues based on immunohistochemistry. For more information, please refer to http://www.proteinatlas.org/about/assays+annotation#ih .

- Subcellular location:according to HPA data. For more information, please refer to https://www.proteinatlas.org/about/assays+annotation#ifa

- RNA tissue specificity abundance in 'Transcript Per Million': For each gene is reported the tissue specificity abundance in 'Transcript Per Million' (TPM) as the sum of the TPM values of all its protein-coding transcripts.

- RNA non-specific tissue abundance in 'Transcript Per Million': please refer to http://www.proteinatlas.org/about/assays+annotation#rna.

**Outputs**

The output is a tabular file. The initial columns are kept and new columns are added according to what type of annotation data you chose. 