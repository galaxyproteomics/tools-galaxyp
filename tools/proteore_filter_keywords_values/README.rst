Wrapper for Filter by keywords or numerical values Tool
=======================================================

**Authors**

T.P. Lien Nguyen, David Christiany, Florence Combes, Yves Vandenbrouck CEA, INSERM, CNRS, Grenoble-Alpes University, BIG Institute, FR

Sandra Dérozier, Olivier Rué, Christophe Caron, Valentin Loux INRA, Paris-Saclay University, MAIAGE Unit, Migale Bioinformatics platform

This work has been partially funded through the French National Agency for Research (ANR) IFB project.

Contact support@proteore.org for any questions or concerns about the Galaxy implementation of this tool.

-------------------------------------------------------

This tool allows to remove unneeded data (e.g. contaminants, non-significant values) from a proteomics results file (e.g. MaxQuant or Proline output).

**Filter by keyword(s)**

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

-------------------------------------------------------

**Filter by values**

You can filter your data by a column of numerical values.
Enter the column to be use and select one operator in the list :

- =
- !=
- <
- <=
- >
- >=

Then enter the value to filter and specify the column to apply that option.
If a row contains a value that correspond to your settings, it will be filtered.

-------------------------------------------------------

**Filter by a range of values**

You can also set a range of values to filter your file.
In opposition to value filter, rows with values inside of the defined range are kept.

Rows with values outside of the defined range will be filtered.

-------------------------------------------------------

**AND/OR operator**

Since you can add as many filters as you want, you can choose how filters apply on your data.

AND or OR operator option works on all filters :

- OR : only one filter to be satisfied to remove one row
- AND : all filters must be satisfied to remove one row

-------------------------------------------------------

**Sort the results files**

You can sort the result file if you wish, it can help you to check results. 

In order to do so : enter the column to be used, all columns will be sorted according to the one filled in.

Rows stay intact, just in different order like excel.
You can also choose ascending or descending order, by default descending order is set.

-------------------------------------------------------

**Output**

The tool will produce 2 output files.

* A text file containing the resulting filtered input file.

* A text file containing the rows removed from the input file.