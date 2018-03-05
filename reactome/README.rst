Wrapper for Reactome Tool
=========================

Reactome web service (https://reactome.org)

**Galaxy integration**

T.P. Lien Nguyen, Florence Combes, Yves Vandenbrouck CEA, INSERM, CNRS, Grenoble-Alpes University, BIG Institute, FR

Sandra Dérozier, Olivier Rué, Christophe Caron, Valentin Loux INRA, Paris-Saclay University, MAIAGE Unit,Migale Bioinformatics platform

Contact support@proteore.org for any questions or concerns about the Galaxy implementation of this tool.

-------------------------

Reactome software provides service of creating diagram representing the relations between the biological processes. 
This tool allows linking to Reactome web service with pre-loaded data from a list of IDs, a file containing IDs or from a column of a complexed file.

**For the rows that have more than 1 ID, only the first one is taken into account.**

**Supported IDs: Uniprot accession number (e.g. P01023), Entrez gene ID (e.g.7157), gene name (e.g. AQP7). If there is any ID containing invalid characters, it will be removed from the queue and placed in "Invalid identifiers" file.**
