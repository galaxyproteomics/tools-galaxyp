Wrapper for Reactome web service
================================

Reactome web service (https://reactome.org)

**Galaxy integration**

T.P. Lien Nguyen, Florence Combes, Yves Vandenbrouck CEA, INSERM, CNRS, Grenoble-Alpes University, BIG Institute, FR

Sandra Dérozier, Olivier Rué, Christophe Caron, Valentin Loux INRA, Paris-Saclay University, MAIAGE Unit,Migale Bioinformatics platform

Contact support@proteore.org for any questions or concerns about the Galaxy implementation of this tool.

================================

Reactome software provides service of creating diagram representing the relations between the biological processes. This tool allows linking to Reactome web service with pre-loaded data from a list of IDs, a file containing IDs or from a column of a complexed file.

**For the rows that have more than 1 ID, only the first one is taken into account**

**This tool only accepts letters (a-z or A-Z), numbers (0-9) and 3 characters "." "-" "_" for IDs. If there is ID containing other than these characters, it will be removed from the queue and placed in "Invalid identifiers" file**
