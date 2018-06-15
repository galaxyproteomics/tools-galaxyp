Wrapper for Pathview tool
=============================

**Authors**

David Christiany, Florence Combes, Yves Vandenbrouck CEA, INSERM, CNRS, Grenoble-Alpes University, BIG Institute, FR

Sandra Dérozier, Olivier Rué, Christophe Caron, Valentin Loux INRA, Paris-Saclay University, MAIAGE Unit, Migale Bioinformatics platform

This work has been partially funded through the French National Agency for Research (ANR) IFB project.

Contact support@proteore.org for any questions or concerns about the Galaxy implementation of this tool.

=============================

This tool map a list of Uniprot Accession number or Entrez gene ID to KEGG pathway with pathview R package.

Select an input file containing ids in a column, set header and column number or copy/paste your ids. 

Select your identifier type and a species of interest (for now only human available). 

Select one or several pathways of interest from the dropdown menu or copy/paste KEGG pathway id(s)

Select the graph format : KEGG or graphviz

Uniprot accession number converted to Entrez geneID or Entrez geneID are mapped to each selected pathways.

Output : One file (png or pdf) for each selected pathway. 