Wrapper for Pathview tool
=============================

**Authors**

David Christiany, Florence Combes, Yves Vandenbrouck CEA, INSERM, CNRS, Grenoble-Alpes University, BIG Institute, FR

Sandra Dérozier, Olivier Rué, Christophe Caron, Valentin Loux INRA, Paris-Saclay University, MAIAGE Unit, Migale Bioinformatics platform

This work has been partially funded through the French National Agency for Research (ANR) IFB project.

Contact support@proteore.org for any questions or concerns about the Galaxy implementation of this tool.

=============================

This tool map a list of Uniprot Accession number or Entrez gene ID to KEGG pathway with pathview R package.

Select a species of interest. 

Select one or several pathways of interest from the dropdown menu or copy/paste KEGG pathway id(s) or import it from a file.

Select an input file containing ids in a column, set header and column number or copy/paste your ids. 

You can import 1 to 3 column(s) of expression values if you are importing ids from a file.

Select your identifier type : UniprotAC or Entrez gene ID

Select the graph format : KEGG (jpg) or graphviz (pdf)

Uniprot accession number converted to Entrez geneID or Entrez geneID are mapped to each selected pathways.

Output : One file (png or pdf) for each selected pathway. 
