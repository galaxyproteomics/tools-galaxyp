Wrapper for Jvenn plug-in
=========================

**Authors**

Philippe Bardou, Jérôme Mariette, Frédéric Escudié, Christophe Djemiel and Christophe Klopp. jvenn: an interactive Venn diagram viewer. BMC Bioinformatics 2014, 15:293 doi:10.1186/1471-2105-15-293

**Galaxy integration**

T.P. Lien Nguyen, Florence Combes, Yves Vandenbrouck CEA, INSERM, CNRS, Grenoble-Alpes University, BIG Institute, FR

Sandra Dérozier, Olivier Rué, Christophe Caron, Valentin Loux INRA, Paris-Saclay University, MAIAGE Unit,Migale Bioinformatics platform

Contact support@proteore.org for any questions or concerns about the Galaxy implementation of this tool.

=========================

This tool draw a venn diagram from lists/files using Jvenn plug-in (http://jvenn.toulouse.inra.fr/app/index.html). It also creates output files that contain common or specific elements between query and each compared lists/files.

**Inputs**

* **Query file:** A file containing different information of proteins, could be output of previous components.

* **File of a list of IDs:** .TXT format, each line contains 1 ID
    
    AMY1A
    
 	ALB
 	
 	IGKC
 	
 	CSTA
 	
 	IGHA1
 	
 	ACTG1

* **List of IDs:** IDs separated by a space
    AMY1A ALB IGKC CSTA IGHA1 ACTG1

If you choose a file, it is necessary to specify the column where you would like to perform the comparison.

**Outputs**

* **Summary file** (venn_diagram_summary.html):
    Venn diagram: Could be downloaded as image (PNG, SVG)

* **Venn text output file**
    A text file containing common/specific elements among compared lists/files.
