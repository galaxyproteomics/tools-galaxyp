Wrapper for Pathview tool
=============================

**Authors**

David Christiany, Florence Combes, Yves Vandenbrouck CEA, INSERM, CNRS, Grenoble-Alpes University, BIG Institute, FR

Sandra Dérozier, Olivier Rué, Christophe Caron, Valentin Loux INRA, Paris-Saclay University, MAIAGE Unit, Migale Bioinformatics platform

This work has been partially funded through the French National Agency for Research (ANR) IFB project.

Contact support@proteore.org for any questions or concerns about the Galaxy implementation of this tool.

=============================

This tool map a list of Uniprot Accession number or Entrez gene ID to KEGG pathway with pathview R package.

You can map Entrez gene IDs / Uniprot accession number from three species : human, mouse and rat.

If your input have another type of IDs, please use the ID_Converter tool.

**Input:**


- KEGG Pathways IDs to be used for mapping can be set by:
    - chosing from the KEGG pathways name list 
    - giving a list (copy/paste)
    - importing a list from a dataset (column) - output of KEGG pathways identification and coverage can be used (1st column)
- Genes/proteins ids to map can be either a list of Entrez genes IDs / Uniprot accession number or a file (tabular, tsv, txt) containing at least one column of Entrez genes IDs / Uniprot accession number. 
- fold change values (up to three columns) from a dataset (same dataset as for Genes/proteins ids to map)

You can see below an example of an input file with identifiers (uniprot_AC) and fold_change values.

.. csv-table:: Simulated data
   :header: "Uniprot_AC","Protein.name","Number_of_peptides","fc_values 1","fc_values 2","fc_values 3"

   "P15924","Desmoplakin","69","0.172302292051025","-0.757435966487116","0.0411240398990759"
   "P02538","Keratin, type II cytoskeletal 6A","53","-0.988842456122076","0.654626325100182","-0.219153396366064"
   "P02768","Serum albumin","44","-0.983493243315454","0.113752002761474","-0.645886132600729"
   "P08779","Keratin, type I cytoskeletal 16","29","0.552302597284443","-0.329045605110646","2.10616106806788"

|

**Output:**

- a **collection dataset** named 'KEGG pathways map from <dataset>', one file (png or pdf) for each given pathway.
- a **summary text file** (.tsv) of the mapping(s) with the following columns
    - **KEGG pathway ID**: KEGG pathway(s) used to map given genes/proteins ids
    - **pathway name**: name(s) of KEGG pathway(s) used for mapping
    - **nb of Uniprot_AC used** (only when Uniprot accession number is given): number of Uniprot accession number which will be converted to Entrez genes IDs
    - **nb of Entrez gene ID used**: number of Entrez gene IDs used for mapping
    - **nb of Entrez gene ID mapped**: number of Entrez gene IDs mapped on a given pathway
    - **nb of Entrez gene ID in the pathway**: number total of Entrez gene IDs in a given pathway
    - **ratio of Entrez gene ID mapped**: number of Entrez gene IDs mapped / number total of Entrez gene IDs
    - **Entrez gene ID mapped**: list of mapped Entrez gene IDs
    - **uniprot_AC mapped** (only when Uniprot accession number is given): list of Uniprot accession number corresponding to the mapped Entrez gene IDs

-----

.. class:: infomark

**Database:**

KEGG Pathways names list are from  http://rest.kegg.jp/list/pathway/

User manual / Documentation: http://www.bioconductor.org/packages/release/bioc/html/pathview.html
