## Synopsis

This data manager is made to update ProteoRE tools.
For now, only resources files for tools listed below are handled: 

* Get MS/MS observations in tissue/fluid [Peptide Atlas]
* Get expression profiles by (normal or tumor) tissue/cell type [Human Protein Atlas]
* ID converter
* Build Protein-Protein interaction network
* Add protein features

You can find a tutorial for galaxy data managers here:
https://galaxyproject.org/admin/tools/data-managers/

## How it works overview

Data manager are a special kind of galaxy tool but it still works with an xml and a script (python).
You can find those files in data_manager directory

To works, the data manager needs a data_manager_conf.xml file.
This file defines data tables which will be fill by the data manager.
It is thanks to this file that data tables are updated.

For each data manager job:

* a command line which run the data manager python script is made (like a regular tool) and a json dictionary
* data manager script (resource_building.xml) will create output(s) file(s) and metadata into a json dictionary
* data_manager_conf.xml use the json dictionary to move output file and list it in the corresponding data table

example of each data table can be found in tool-data directory

## Get expression profiles by (normal or tumor) tissue/cell type [Human Protein Atlas]

Files for this tools are just downloaded and referenced in the data table of Get expression profiles by (normal or tumor) tissue/cell type [Human Protein Atlas].
api used : https://www.proteinatlas.org/about/download

Each file created for Get expression profiles by (normal or tumor) tissue/cell type [Human Protein Atlas] are listed respectively in "proteore_peptide_atlas_normal_tissue" data table and in "proteore_peptide_atlas_tumor_tissue" data table
and saved in tool-data/peptide_atlas/ (default galaxy tool-data)

```
tool_data_table_conf:
    <table name="proteore_protein_atlas_normal_tissue" comment_char="#">
      <columns>id, release, name, tissue, value</columns>
      <file path="tool-data/proteore_protein_atlas_normal_tissue.loc" />
    </table>
    <table name="proteore_protein_atlas_tumor_tissue" comment_char="#">
      <columns>id, release, name, tissue, value</columns>
      <file path="tool-data/proteore_protein_atlas_tumor_tissue.loc" />
    </table>
  </tables>
```

## Get MS/MS observations in tissue/fluid [Peptide Atlas]

Ref files are downloaded for each tissue:

* [Human Adrenal gland proteome](https://db.systemsbiology.net/sbeams/cgi/PeptideAtlas/GetProteins?&atlas_build_id=432&display_options=ShowAbundances&organism_id=2&redundancy_constraint=4&presence_level_constraint=1%2C2&gene_annotation_level_constraint=leaf&QUERY_NAME=AT_GetProteins&action=QUERY&output_mode=tsv&apply_action=QUERY)
* [Human Brain proteome](https://db.systemsbiology.net/sbeams/cgi/PeptideAtlas/GetProteins?&atlas_build_id=441&display_options=ShowAbundances&organism_id=2&redundancy_constraint=4&presence_level_constraint=1%2C2&gene_annotation_level_constraint=leaf&QUERY_NAME=AT_GetProteins&action=QUERY&output_mode=tsv&apply_action=QUERY)
* [Human Breast Proteome](https://db.systemsbiology.net/sbeams/cgi/PeptideAtlas/GetProteins?&atlas_build_id=427&display_options=ShowAbundances&organism_id=2&redundancy_constraint=4&presence_level_constraint=1%2C2&gene_annotation_level_constraint=leaf&QUERY_NAME=AT_GetProteins&action=QUERY&output_mode=tsv&apply_action=QUERY)
* [Human CSF proteome](https://db.systemsbiology.net/sbeams/cgi/PeptideAtlas/GetProteins?&atlas_build_id=434&display_options=ShowAbundances&organism_id=2&redundancy_constraint=4&presence_level_constraint=1%2C2&gene_annotation_level_constraint=leaf&QUERY_NAME=AT_GetProteins&action=QUERY&output_mode=tsv&apply_action=QUERY)
* [Human Digestive System proteome](https://db.systemsbiology.net/sbeams/cgi/PeptideAtlas/GetProteins?&atlas_build_id=429&display_options=ShowAbundances&organism_id=2&redundancy_constraint=4&presence_level_constraint=1%2C2&gene_annotation_level_constraint=leaf&QUERY_NAME=AT_GetProteins&action=QUERY&output_mode=tsv&apply_action=QUERY)
* [Human female reproductive system proteome](https://db.systemsbiology.net/sbeams/cgi/PeptideAtlas/GetProteins?&atlas_build_id=430&display_options=ShowAbundances&organism_id=2&redundancy_constraint=4&presence_level_constraint=1%2C2&gene_annotation_level_constraint=leaf&QUERY_NAME=AT_GetProteins&action=QUERY&output_mode=tsv&apply_action=QUERY)
* [Human Heart proteome](https://db.systemsbiology.net/sbeams/cgi/PeptideAtlas/GetProteins?&atlas_build_id=418&display_options=ShowAbundances&organism_id=2&redundancy_constraint=4&presence_level_constraint=1%2C2&gene_annotation_level_constraint=leaf&QUERY_NAME=AT_GetProteins&action=QUERY&output_mode=tsv&apply_action=QUERY)
* [Human Kidney man Kidney Proteome](https://db.systemsbiology.net/sbeams/cgi/PeptideAtlas/GetProteins?&atlas_build_id=424&display_options=ShowAbundances&organism_id=2&redundancy_constraint=4&presence_level_constraint=1%2C2&gene_annotation_level_constraint=leaf&QUERY_NAME=AT_GetProteins&action=QUERY&output_mode=tsv&apply_action=QUERY)
* [Human Liver proteome](https://db.systemsbiology.net/sbeams/cgi/PeptideAtlas/GetProteins?&atlas_build_id=425&display_options=ShowAbundances&organism_id=2&redundancy_constraint=4&presence_level_constraint=1%2C2&gene_annotation_level_constraint=leaf&QUERY_NAME=AT_GetProteins&action=QUERY&output_mode=tsv&apply_action=QUERY)
* [Human Lung proteome](https://db.systemsbiology.net/sbeams/cgi/PeptideAtlas/GetProteins?&atlas_build_id=419&display_options=ShowAbundances&organism_id=2&redundancy_constraint=4&presence_level_constraint=1%2C2&gene_annotation_level_constraint=leaf&QUERY_NAME=AT_GetProteins&action=QUERY&output_mode=tsv&apply_action=QUERY)
* [Human Male Reproductive System proteome](https://db.systemsbiology.net/sbeams/cgi/PeptideAtlas/GetProteins?&atlas_build_id=431&display_options=ShowAbundances&organism_id=2&redundancy_constraint=4&presence_level_constraint=1%2C2&gene_annotation_level_constraint=leaf&QUERY_NAME=AT_GetProteins&action=QUERY&output_mode=tsv&apply_action=QUERY)
* [Human Pancreas proteome](https://db.systemsbiology.net/sbeams/cgi/PeptideAtlas/GetProteins?&atlas_build_id=420&display_options=ShowAbundances&organism_id=2&redundancy_constraint=4&presence_level_constraint=1%2C2&gene_annotation_level_constraint=leaf&QUERY_NAME=AT_GetProteins&action=QUERY&output_mode=tsv&apply_action=QUERY)
* [Human Plasma Non-Glyco proteome](https://db.systemsbiology.net/sbeams/cgi/PeptideAtlas/GetProteins?&atlas_build_id=465&display_options=ShowAbundances&organism_id=2&redundancy_constraint=4&presence_level_constraint=1%2C2&gene_annotation_level_constraint=leaf&QUERY_NAME=AT_GetProteins&action=QUERY&output_mode=tsv&apply_action=QUERY)
* [Human Spleen proteome](https://db.systemsbiology.net/sbeams/cgi/PeptideAtlas/GetProteins?&atlas_build_id=421&display_options=ShowAbundances&organism_id=2&redundancy_constraint=4&presence_level_constraint=1%2C2&gene_annotation_level_constraint=leaf&QUERY_NAME=AT_GetProteins&action=QUERY&output_mode=tsv&apply_action=QUERY)
* [Human Testis and spermatozoa samples](https://db.systemsbiology.net/sbeams/cgi/PeptideAtlas/GetProteins?&atlas_build_id=463&display_options=ShowAbundances&organism_id=2&redundancy_constraint=4&presence_level_constraint=1%2C2&gene_annotation_level_constraint=leaf&QUERY_NAME=AT_GetProteins&action=QUERY&output_mode=tsv&apply_action=QUERY)
* [Human Urinary Bladder proteome](https://db.systemsbiology.net/sbeams/cgi/PeptideAtlas/GetProteins?&atlas_build_id=422&display_options=ShowAbundances&organism_id=2&redundancy_constraint=4&presence_level_constraint=1%2C2&gene_annotation_level_constraint=leaf&QUERY_NAME=AT_GetProteins&action=QUERY&output_mode=tsv&apply_action=QUERY)
* [Human Urine proteome](https://db.systemsbiology.net/sbeams/cgi/PeptideAtlas/GetProteins?&atlas_build_id=423&display_options=ShowAbundances&organism_id=2&redundancy_constraint=4&presence_level_constraint=1%2C2&gene_annotation_level_constraint=leaf&QUERY_NAME=AT_GetProteins&action=QUERY&output_mode=tsv&apply_action=QUERY)


Example request for peptide atlas api:
```
query="https://db.systemsbiology.net/sbeams/cgi/PeptideAtlas/GetProteins?&atlas_build_id="+ sample_category_id +
  "&display_options=ShowAbundances&organism_id=" + organism_id + 
  "&redundancy_constraint=4&presence_level_constraint=1%2C2&gene_annotation_level_constraint=leaf" + 
  "&QUERY_NAME=AT_GetProteins&action=QUERY&output_mode=tsv&apply_action=QUERY"
```

A dictionary is build from the downloaded file to only keep uniprot accession (not isoform) as key and sum of observations as value
An output file (.tsv) is made with the dictionary.

Each file created for Get MS/MS observations in tissue/fluid [Peptide Atlas] are listed in the "proteore_protein_atlas" data table 
and saved in tool-data/protein_atlas/ (default galaxy tool-data)

```
tool_data_table_conf: 
  <tables>
    <table name='proteore_peptide_atlas' comment_char="#">
      <columns>id, name, tissue, value</columns>
      <file path="tool-data/proteore_peptide_atlas.loc"/>
    </table>
  </tables>
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


Only reviewed Uniprot-AC are kept. 
(query = "https://www.uniprot.org/uniprot/?query=reviewed:yes+AND+organism:"+organism+"&format=list")

A tsv file is made (list of lists in python) from those files and saved.
This tsv file will be load by id_converter and a python dictionary will be created from it (for each run of id_converter).
Only a partial dictionary is made instead of a complete one. Only the dictionary for the input id type is made.
This is the fastest solution found.

Each tsv file created for ID converter (once per species) is listed in a "proteore_id_mapping" loc file 
and saved in tool-data/id_mapping/ (default galaxy tool-data)
Files are located in tool-data/id_mapping
There are one loc file per species :

```
tool_data_table_conf: 
  <tables>
    <table name="proteore_id_mapping_Human" comment_char="#">
      <columns>id, release, name, species, value</columns>
      <file path="tool-data/proteore_id_mapping_Human.loc" />
    </table>
    <table name="proteore_id_mapping_Mouse" comment_char="#">
      <columns>id, release, name, species, value</columns>
      <file path="tool-data/proteore_id_mapping_Mouse.loc" />
    </table>
    <table name="proteore_id_mapping_Rat" comment_char="#">
      <columns>id, release, name, species, value</columns>
      <file path="tool-data/proteore_id_mapping_Rat.loc" />
    </table>
  </tables>
```

## Build Protein-Protein interaction network (PPI)

Three different interactome sources:

* BioGRID
* Bioplex
* Humap

For each interactome, a python dictionary is made and saved into a json dictionary.
This dictionary will be used by 'Build Protein-Protein interaction network' tool.

For BioGRID, the following two files are used to build a dictionary:

* "https://downloads.thebiogrid.org/Download/BioGRID/Release-Archive/BIOGRID-3.5.167/BIOGRID-ORGANISM-3.5.167.tab2.zip"
* "https://www.reactome.org/download/current/NCBI2Reactome.txt"

For Bioplex, the following files are used to build a dictionary:

* "http://bioplex.hms.harvard.edu/data/BioPlex_interactionList_v4a.tsv"
* "https://reactome.org/download/current/UniProt2Reactome.txt"

One dictionary per interactome and one per species (human_biogrid, mouse_biogrid, human_bioplex, mouse_bioplex, ...)

For Humap, the following files are used to build a dictionary:

* "http://proteincomplexes.org/static/downloads/nodeTable.txt"
* "http://proteincomplexes.org/static/downloads/pairsWprob.txt"
* "https://www.reactome.org/download/current/NCBI2Reactome.txt"

There is one data table per interactome: 
Files are located in tool-data/PPI_dictionaries

```
tool_data_table_conf: 
  <tables>
    <table name="proteore_biogrid_dictionaries" comment_char="#">
      <columns>id, release, name, value, path</columns>
      <file path="tool-data/proteore_biogrid_dictionaries.loc" />
    </table>
    <table name="proteore_bioplex_dictionaries" comment_char="#">
      <columns>id, release, name, value, path</columns>
      <file path="tool-data/proteore_bioplex_dictionaries.loc" />
    </table>
    <table name="proteore_humap_dictionaries" comment_char="#">
      <columns>id, release, name, value, path</columns>
      <file path="tool-data/proteore_bioplex_dictionaries.loc" />
    </table>
  </tables>
```

## Add protein features

One nextprot ref file is made for "Add protein features" tool.
NeXtProt ids are downloaded from ftp://ftp.nextprot.org/pub/current_release/ac_lists/nextprot_ac_list_all.txt

For each neXtProt ID, associated informations are collected with the neXtProt API :
query="https://api.nextprot.org/entry/"+id+".json"

The reference file created are referenced in "proteore_nextprot_ref" loc file and located in tool-data/proteore_nextprot_ref

```
tool_data_table_conf: 
  <tables>
    <table name='proteore_nextprot_ref' comment_char="#">
      <columns>id, release, name, value</columns>
      <file path="tool-data/proteore_nextprot_ref.loc"/>
    </table>
  </tables>
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