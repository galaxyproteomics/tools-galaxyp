Wrapper for Filter by keywords or numerical values Tool
=======================================================

**Authors**

T.P. Lien Nguyen, Florence Combes, Yves Vandenbrouck CEA, INSERM, CNRS, Grenoble-Alpes University, BIG Institute, FR

Sandra Dérozier, Olivier Rué, Christophe Caron, Valentin Loux INRA, Paris-Saclay University, MAIAGE Unit, Migale Bioinformatics platform

This work has been partially funded through the French National Agency for Research (ANR) IFB project.

Contact support@proteore.org for any questions or concerns about the Galaxy implementation of this tool.

-------------------------------------------------------

This tool allows to remove unneeded data (e.g. contaminants, non-significant values) from a proteomics results file (e.g. MaxQuant or Proline output).

**For each row, if there are more than one protein IDs/protein names/gene names, only the first one will be considered in the output**

**Filter the file by keywords**

Several options can be used. For each option, you can fill in the field or upload a file which contains the keywords.

- If you choose to fill in the field, the keywords should be separated by ";", for example: A8K2U0;Q5TA79;O43175

- If you choose to upload a file in a text format in which each line is a keyword, for example:

REV

TRYP_PIG

ALDOA_RABBIT

**The line that contains these keywords will be eliminated from input file.**

**Keywords search can be applied by performing either exact match or partial one by using the following option**

- If you choose **Yes**, only the fields that contains exactly the same content will be removed.

- If you choose **No**, all the fields containing the keyword will be removed.

For example:

**Yes** option (exact match) selected using the keyword "kinase": only lines which contain exactly "kinase" is removed.

**No** option (partial match) for "kinase": not only lines which contain "kinase" but also lines with "alpha-kinase" (and so  on) are removed.

**Filter the file by values**

You can choose to use one or more options (e.g. to filter out peptides of low intensity value, by q-value, etc.).

* For each option, you can choose between "=", ">", ">=", "<" and "<=", then enter the value to filter and specify the column to apply that option.

**Output**

The tool will produce 2 output files.

* A text file containing the resulting filtered input file.

* A text file containing the rows removed from the input file.