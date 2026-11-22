Wrapper for ID Converter tool
=============================

**Authors**

David Christiany, T.P. Lien Nguyen, Florence Combes, Yves Vandenbrouck CEA, INSERM, CNRS, Grenoble-Alpes University, BIG Institute, FR

Sandra Dérozier, Olivier Rué, Christophe Caron, Valentin Loux INRA, Paris-Saclay University, MAIAGE Unit, Migale Bioinformatics platform

This work has been partially funded through the French National Agency for Research (ANR) IFB project.

Contact support@proteore.org for any questions or concerns about the Galaxy implementation of this tool.

=============================

This tool converts a list of IDs to another identifier type, select the source and target type from the dropdown menus above (see below supported source and target types).

After choosing the type of input IDs, you can choose one or more types of IDs you would like to map to. 

If your input is a list of IDs or a single-column file, the tool will return a file containing the mapped IDs.

If your input is a multiple-column file, the mapped IDs column(s) will be added at the end of the input file.

**Available databases**

* neXtProt ID (e.g. NX_P31946)

* UniProt accession number (e.g. P31946 - reviewed entries only)

* UniProt accession number (e.g. P31946 - reviewed and unreviewed entries)

* Uniprot ID (e.g 1433B_HUMAN)

* Entrez gene ID (e.g. 7529)

* RefSeq (NCBI) protein (e.g.  NP_003395.1; NP_647539.1; XP_016883528.1)

* GI (NCBI GI number) ID assigned to each sequence record processed by NCBI (e.g. 21328448; 377656701; 67464627; 78101741)

* Protein DataBank ID (e.g. 2BR9:A; 3UAL:A;   3UBW:A)

* GOterms (Gene Ontology) ID (e.g. GO:0070062; GO:0005925; GO:0042470; GO:0016020; GO:0005739; GO:0005634)

* Protein Information Resource ID (e.g. S34755)

* OMIM (Online Mendelian Inheritance in Man database) ID (e.g: 601289)

* Unigene ID (e.g. Hs.643544)

* Ensembl gene ID (e.g. ENSG00000166913)

* Ensembl transcript ID (e.g. ENST00000353703; ENST00000372839)

* Ensembl protein ID (e.g. ENSP00000300161; ENSP00000361930)

* BioGrid (e.g. 113361)

* STRING (e.g. 9606.ENSP00000300161)

* KEGG gene id (e.g. hsa:7529)

.. class:: warningmark 

Nextprot and OMIM are only available for Human.

.. class:: warningmark

For Uniprot-AC, only Uniprot-AC reviewed are considered here, except for releases before 27-05-2019 where all uniprot-AC (at the time) are considered.

This tool converts human IDs using file built from:

* Current release of Uniprot, for idmapping_selected.tab and idmapping.dat for Human, Mouse and Rat: ftp://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/idmapping/by_organism
* All previous release of uniprot can be found here: ftp://ftp.uniprot.org/pub/databases/uniprot/previous_releases/
* **nextprot_ac_list_all.txt (Nextprot released on 13/02/2019 - current)**: ftp://ftp.nextprot.org/pub/current_release/ac_lists/
* All previous release of **nextprot_ac_list_all.txt** can be foud here: ftp://ftp.nextprot.org/pub/previous_releases/
* `Human uniprot-AC entries reviewed (05/06/2019) <https://www.uniprot.org/uniprot/?query=reviewed:yes+AND+organism:9606+AND+created:[20120720%20TO%2020190605]&format=list>`_. 
* `Mouse uniprot-AC entries reviewed (05/06/2019) <https://www.uniprot.org/uniprot/?query=reviewed:yes+AND+organism:10090+AND+created:[20120720%20TO%2020190605]&format=list>`_. 
* `Rat uniprot-AC entries reviewed (05/06/2019) <https://www.uniprot.org/uniprot/?query=reviewed:yes+AND+organism:10116+AND+created:[20120720%20TO%2020190605]&format=list>`_.
* `Human uniprot-AC entries reviewed (08/05/2019) <https://www.uniprot.org/uniprot/?query=reviewed:yes+AND+organism:9606+AND+created:[20120720%20TO%2020190508]&format=list>`_. 
* `Mouse uniprot-AC entries reviewed (08/05/2019) <https://www.uniprot.org/uniprot/?query=reviewed:yes+AND+organism:10090+AND+created:[20120720%20TO%2020190508]&format=list>`_. 
* `Rat uniprot-AC entries reviewed (08/05/2019) <https://www.uniprot.org/uniprot/?query=reviewed:yes+AND+organism:10116+AND+created:[20120720%20TO%2020190508]&format=list>`_.
* `Human uniprot-AC entries reviewed (10/10/2018) <https://www.uniprot.org/uniprot/?query=reviewed:yes+AND+organism:9606+AND+created:[20120720%20TO%2020181010]&format=list>`_. 
* `Mouse uniprot-AC entries reviewed (10/10/2018) <https://www.uniprot.org/uniprot/?query=reviewed:yes+AND+organism:10090+AND+created:[20120720%20TO%2020181010]&format=list>`_. 
* `Rat uniprot-AC entries reviewed (10/10/2018) <https://www.uniprot.org/uniprot/?query=reviewed:yes+AND+organism:10116+AND+created:[20120720%20TO%2020181010]&format=list>`_.
