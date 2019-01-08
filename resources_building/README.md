## Synopsis

This data manager is made to update ProteoRE tools.
For now, only resources files for tools listed below are handled: 

* Get MS/MS observations in tissue/fluid [Peptide Atlas]
* Get expression profiles by (normal or tumor) tissue/cell type [Human Protein Atlas]
* ID converter

You can find a tutorial for galaxy data managers here:
https://galaxyproject.org/admin/tools/data-managers/

## How it works overview

Data manager are a special kind of galaxy tool but it still works with an xml and a script (python).
You can find those files in data_manager directory

To works, the data manager needs a data_manager_conf.xml file.
This file defines data tables which will be fill by the data manager.
It is thanks to this file that data tables are updated.

For each by data manager job:

* a command line which run the data manager python script is made (like a regular tool) and a json dictionary
* data manager script (resource_building.xml) will create output(s) file(s) and metadata into a json dictionary
* data_manager_conf.xml use the json dictionary to move output file and list it in the corresponding data table

example of each data table can be found in tool-data directory

## Get expression profiles by (normal or tumor) tissue/cell type [Human Protein Atlas]

Files for this tools are just downloaded and referenced in the data table of Get expression profiles by (normal or tumor) tissue/cell type [Human Protein Atlas].
api used : https://www.proteinatlas.org/about/download

Each file created for Get expression profiles by (normal or tumor) tissue/cell type [Human Protein Atlas] are listed in the "proteore_peptide_atlas" data table
and saved in tool-data/peptide_atlas/ (default galaxy tool-data)

```
tool_data_table_conf:
    <table name="proteore_protein_atlas" comment_char="#">
      <columns>id, name, value, path</columns>
      <file path="tool-data/proteore_protein_atlas.loc" />
    </table>
```

## Get MS/MS observations in tissue/fluid [Peptide Atlas]

Ref files are downloaded for each tissue:

* Human liver 
* Human brain
* Human heart
* Human kidney
* Human plasma
* Human urine
* Human CSF

Example request for peptide atlas api:
```
query = "https://db.systemsbiology.net/sbeams/cgi/PeptideAtlas/GetPeptides?atlas_build_id=" + atlas_build_id + "&display_options=ShowMappings&organism_id=" +
            organism_id + "&sample_category_id=" + sample_category_id + "&QUERY_NAME=AT_GetPeptides&output_mode=tsv&apply_action=QUERY"
```

A dictionary is build from the downloaded file to only keep uniprot accession (not isoform) as key and sum of observations as value
An output file (.tsv) is made with the dictionary.

Each file created for Get MS/MS observations in tissue/fluid [Peptide Atlas] are listed in the "proteore_protein_atlas" data table 
and saved in tool-data/protein_atlas/ (default galaxy tool-data)

```
tool_data_table_conf: 
    <table name='proteore_peptide_atlas' comment_char="#">
      <columns>id, name, tissue, value</columns>
      <file path="tool-data/proteore_peptide_atlas.loc"/>
    </table>
```

## "ID converter"

For Id converter tool, ids are downloaded from the uniprot api.
A tsv file is created from the two files got from uniprot:

* <species>_idmapping_selected.tab: ftp://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/idmapping/by_organism/
* <species>_idmapping.dat: ftp://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/idmapping/by_organism/

For human species, there is a third file used for nextprot ID:

* nextprot_ac_list_all.txt: ftp://ftp.nextprot.org/pub/current_release/ac_lists/

Ids kept in the ref file are listed below:

* neXtProt ID (e.g. NX_P31946)
* UniProt accession number (e.g. P31946)
* UniProt ID (e.g 1433B_HUMAN)
* Entrez gene ID (e.g. 7529)
* RefSeq protein (NCBI) (e.g.  NP_003395.1)
* GI (NCBI GI number) (e.g. 21328448)
* Protein DataBank ID (e.g. 2BR9:A)
* GOterms (Gene Ontology) ID (e.g. GO:0070062)
* Protein Information Resource ID (e.g. S34755)
* OMIM (Online Mendelian Inheritance in Man database) ID (e.g: 601289)
* Unigene ID (e.g. Hs.643544)
* Ensembl gene ID (e.g. ENSG00000166913)
* Ensembl transcript ID (e.g. ENST00000353703)
* Ensembl protein ID (e.g. ENSP00000300161)
* BioGrid (e.g. 113361)
* STRING (e.g. 9606.ENSP00000300161)
* KEGG gene id (e.g. hsa:7529)
* Nextprot and OMIM only applicable to Human species.

First a tsv file is made (list of lists in python)
From this list of lists, a dictionary is made to convert more quickly ids.

Dictionary architecture is the following:

* first key : input id 
* second key : id 
* third key : target input  

For example if we want to convert 'P31946' (Uniprot-AC) into Entrez Gene ID, the path will be:
```
ids_dictionary['UniProt-AC']['P31946']['GeneID']
```

and the result is:
```
['7531']
```

This (big) dictionary is saved with json into a json dictionary.
json is used instead of pickle because it is faster to load a json dictionary than a pickle one.
To save this dictionary with json, sets has been converted into list with the function ```dict_set_to_list()```.

Each file created for Get MS/MS observations in tissue/fluid [Peptide Atlas] are listed in the "proteore_id_mapping_dictionaries" data table 
and saved in tool-data/id_mapping_dictionaries/ (default galaxy tool-data)

```
tool_data_table_conf: 
    <table name="proteore_id_mapping_dictionaries" comment_char="#">
      <columns>id, name, value, path</columns>
      <file path="tool-data/proteore_id_mapping_dictionaries.loc" />
    </table>
```

## Installation

From the main toolshed: 'data_manager_proteore'
It will appears in admin > 'local data'

data tables are created in shed_tool_data_table.xml during installation thanks to tool_data_table_conf.xml.sample

## API Reference

* Protein Atlas: https://www.proteinatlas.org/about/download
* Peptide Atlas: https://db.systemsbiology.net/sbeams/
* ID mapping: https://www.uniprot.org/help/api

## Contributors

David Christiany, Lisa Peru, T.P. Lien Nguyen, Florence Combes, Yves Vandenbrouck CEA, INSERM, CNRS, Grenoble-Alpes University, BIG Institute, FR
Sandra Dérozier, Olivier Rué, Christophe Caron, Valentin Loux INRA, Paris-Saclay University, MAIAGE Unit, Migale Bioinformatics platform
This work has been partially funded through the French National Agency for Research (ANR) IFB project.
Contact support@proteore.org for any questions or concerns about the Galaxy implementation of this tool.