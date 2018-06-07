Wrapper for Protein Features tool
=================================

**Authors**

Lisa Peru, T.P. Lien Nguyen, Florence Combes, Yves Vandenbrouck CEA, INSERM, CNRS, Grenoble-Alpes University, BIG Institute, FR

Sandra Dérozier, Olivier Rué, Christophe Caron, Valentin Loux INRA, Paris-Saclay University, MAIAGE Unit, Migale Bioinformatics platform

This work has been partially funded through the French National Agency for Research (ANR) IFB project.

Contact support@proteore.org for any questions or concerns about the Galaxy implementation of this tool.

---------------------------------

This tool add annotation (protein features) from neXtProt database (knowledge base on human proteins) to your protein IDs list.

**Input**

Input can be a file containing multiple fields but with **at least one column of Uniprot accession number or neXtProt IDs**. If your input file contains other type of IDs, please use the ID_Converter tool.  

**Databases**

Annotations have been retrieved from the neXtProt released on 21/02/2018 using the latest data from peptideAtlas (release Human 2018-1)

using a REST API (https://academic.oup.com/nar/article/43/D1/D764/2439066#40348985) (Gaudet et  al., 2017)

**Outputs**

The output is a tabular file. The initial columns are kept and columns are be added according to which annotation you have selected. 