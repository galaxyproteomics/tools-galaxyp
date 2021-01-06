**Description**

This tool allows to retrieve unique proteotypic peptide and related information (from SRMAtlas) 
for building Selected Reaction Monitoring (SRM) method using a list of Uniprot accession number as input. 
The SRMAtlas is a compendium of targeted proteomics assays resulting from high-quality measurements of natural 
and synthetic peptides conducted on a triple quadrupole mass spectrometer, and is intended as a resource 
for building selected/multiple reaction monitoring (SRM/MRM)-based proteomic methods.

-----

**Input**

A list of IDs (entered in a copy/paste mode) or a single-column file, the tool will then return a file containing 
the selected information (peptide sequence/features). If your input is a multiple-column file, the column(s) 
containing the selected information will be added at the end of the input file. Only Uniprot accession number (e.g. P31946) are allowed. 
If your list of IDs is not in this form, please use the ID_Converter tool of ProteoRE.

.. class:: warningmark

Accession numbers with an hyphen ("-") that normally correspond to isoform are not considered as similar to its canonical form.

.. class:: warningmark

In copy/paste mode, the number of IDs considered in input is limited to 5000.

-----

**Parameters**

Release: choose the release you want to use for retrieving peptide sequences/features
Peptide sequence/features: select peptide features you want to retrieve; Peptide sequence 
(amino acid sequence of detected peptide, including any mass modifications); 
SSRT (Sequence Specific Retention Time provides a hydrophobicity measure for each peptide using 
the algorithm of Krohkin et al. SSRCalc); Length (peptide sequence length); MW (molecular weight); 
PeptideAtlas Accession (PA_Acc).

-----

**Output**

A text file containing the selected peptide features (in addition to the original column(s) provided). 
Please, note that a "NA" is returned when there is no match between a source ID and SRM/MRM source file.

-----

**Data sources (release date)**

This tool is using the following source file:

- `HumanSRMAtlasPeptidesFinalAnnotated (2016-04) (Kusebauch et al., 2016, PMID: 27453469) <http://www.srmatlas.org/downloads/HumanSRMAtlasPeptidesFinalAnnotated.xlsx>`_.

-----

.. class:: infomark

**Authors**

David Christiany, Florence Combes, Yves Vandenbrouck CEA, INSERM, CNRS, Grenoble-Alpes University, BIG Institute, FR

Sandra Dérozier, Olivier Rué, Christophe Caron, Valentin Loux INRA, Paris-Saclay University, MAIAGE Unit, Migale Bioinformatics platform, FR

This work has been partially funded through the French National Agency for Research (ANR) IFB project.

Help: contact@proteore.org for any questions or concerns about this tool.