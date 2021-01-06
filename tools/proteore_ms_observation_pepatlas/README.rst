Wrapper for Number of MS/MS observations in a tissue (from Peptide Atlas) tool
==============================================================================

**Authors**

T.P. Lien Nguyen, Florence Combes, Yves Vandenbrouck CEA, INSERM, CNRS, Grenoble-Alpes University, BIG Institute, FR

Sandra Dérozier, Olivier Rué, Christophe Caron, Valentin Loux INRA, Paris-Saclay University, MAIAGE Unit, Migale Bioinformatics platform

This work has been partially funded through the French National Agency for Research (ANR) IFB project.

Contact support@proteore.org for any questions or concerns about the Galaxy implementation of this tool.

==============================================================================

Given a list of Uniprot accession number this tool indicates the number of times a protein has(ve) been observed in a given sample using LC-MS/MS proteomics approach. Could be of interest for people who wants to know to what extent a protein is detectable (and to roughly estimate its level) in a given sample using proteomics. Available human biological samples are the following: brain, heart, kidney, liver, plasma, urine and cerebrospinal fluid (CSF). Data were retrieved from Peptide Atlas release (Jan 2018).

**Input required**

A list of Uniprot accession number (e.g. Q12860) provided either in the form of a file (if you choose a file, it is necessary to specify the column where are your Uniprot accession number) or in a copy/paste mode. If your input file or list contains other type of IDs, please use the ID_Converter tool to convert yours into Uniprot accession number.

**Output**

Additional columns are created for each selected proteomics sample reporting the number of times all peptides corresponding to a protein have been observed by LC-MS/MS according to Peptide Atlas. “NA” means that no information has been reported suggesting that this protein has not been observed in the sample of interest.