MT2MQ
==========================================

Description
-----------

For multi-omics data analysis of microbiome data, the Galaxy-P team has developed a tool – MT2MQ – which takes in metatranscriptomics gene families 
output from ASaiM workflow and converts it to GO/EC terms. This tool helps transform the metatranscriptomics output which can be then used as an input for 
comparative statistical analysis via metaQuantome.

Authors
-------

Authors and contributors:

* Marie Crane
* Praveen Kumar
* Subina Mehta
* Dihn Duy An Nguyen
* Pratik Jagtap


# Instructions to run MT2MQ:
--------------------------

The ASAIM workflow can be run following the training module on the [GTN](https://training.galaxyproject.org/training-material/topics/metagenomics/tutorials/metatranscriptomics/tutorial.html).
However, for training purposes we have provided inputs in the [test data](https://github.com/galaxyproteomics/tools-galaxyp/tree/master/tools/mt2mq/test-data). 

## Data upload

- Upload the files mentioned below to the Galaxy Europe instance.
```
https://github.com/galaxyproteomics/tools-galaxyp/blob/master/tools/mt2mq/test-data/T4A.tsv
https://github.com/galaxyproteomics/tools-galaxyp/blob/master/tools/mt2mq/test-data/T4B.tsv
https://github.com/galaxyproteomics/tools-galaxyp/blob/master/tools/mt2mq/test-data/T4C.tsv
https://github.com/galaxyproteomics/tools-galaxyp/blob/master/tools/mt2mq/test-data/T7A.tsv
https://github.com/galaxyproteomics/tools-galaxyp/blob/master/tools/mt2mq/test-data/T7B.tsv
https://github.com/galaxyproteomics/tools-galaxyp/blob/master/tools/mt2mq/test-data/T7C.tsv
https://github.com/galaxyproteomics/tools-galaxyp/blob/master/tools/mt2mq/test-data/T4T7_func.tsv

```

## Functional mode:

1. Build a **Dataset list** for the six .tsv files( `T4A`,`T4B`,`T4C`,`T7A`,`T7B`,`T7C`).
   - Click the **Operations on multiple datasets** check box at the top of the history panel.
   - Select the files mentioned above.
   - Click on ** For all selected** drop down menu and select **Build Dataset list**.
   - Once the collection is created, rename the dataset collection as `Input collection`.
   
2. Download the map_go_uniref50.txt file from zenodo.

3. Run the **Regroup a HUMAnN2 generated table by features**(Galaxy Version 0.11.1.0) tool is regrouping table features (abundances or coverage) given a table of feature values and a mapping of groups to component features. It produces a new table with group values in place of feature values.
 - [**Regroup a HUMAnN2 generated table by features**](https://toolshed.g2.bx.psu.edu/repository?repository_id=85391b8d5d7ad39d) with the following parameters:
    
    - *"Gene/pathway table"*: `Input collection`
    - *"How to combine grouped features?"*: `Sum`
    - In *"Use built-in grouping options?"*: `No`
        - *"Custom groups file"*: `map_go_uniref50.txt`
        - *"Is the groups file reversed?"*: `No`
    - *"Decimal places to round to after applying function"*: `3`
    - *"Include an 'UNGROUPED' group to capture features that did not belong to other groups?"*: `Yes`
    - *"Carry through protected features, such as 'UNMAPPED'?"*: `Yes`
    
    Once this tool is run, rename the dataset collection as `Regrouped collection` .
    
4. Run the **Rename features of a HUMAnN2 generated table** (Galaxy Version 0.11.1.0)tool to change the Uniref-50 values to GO term . 
 - [**Rename features of a HUMAnN2 generated table**](https://toolshed.g2.bx.psu.edu/repository?repository_id=c68108109505c2f5) with the following parameters:
    
    - *"Gene/pathway table"*: `Regrouped collection`
    - *"Type of renaming"*: `Standard renaming`
    - *"Table features that can be renamed?"*: `Gene Ontology (GO)`
    - *"Remove non-alphanumeric characters from names?"*: `No`
    
    Once this tool is run, rename the dataset collection as `Renamed collection`.
    
     
5. Run the **Join HUMAnN2 generated tables** (Galaxy Version 0.11.1.1) tool to merge all the files into one.
 - [**Join HUMAnN2 generated tables**](https://toolshed.g2.bx.psu.edu/repository?repository_id=9b27f096128b26ff) with the following parameters:
   
   - *"Gene/pathway table"*: `Renamed collection`
    
    Once this tool is run, rename the dataset collection as `Joined Data`.

6. Run the **Renormalize a HUMAnN2 generated table** (Galaxy Version 0.11.1.0) tool to normalize the data.
 - [**Renormalize a HUMAnN2 generated table**](https://toolshed.g2.bx.psu.edu/repository?repository_id=05a56fcdeac2a25c) with the following parameters:
    
    - *"Gene/pathway table"*: `Joined Data`
    - *"Normalization scheme"*: `Copies per million`
    - *"Normalization level"*: `Normalization of all levels by community total`
    - *"Include the special features UNMAPPED, UNINTEGRATED, and UNGROUPED?"*: `Yes`
    - *"Update '-RPK' in sample names to appropriate suffix?"*: `No`
    
     Once this tool is run, rename the dataset collection as `Renormalized data`.
    

7. Now that the data is ready, we can run **MT2MQ Tool to prepare metatranscriptomic outputs from ASaiM for Metaquantome** (Galaxy Version 1.1.0)on this data.
- [**MT2MQ Tool to prepare metatranscriptomic outputs from ASaiM for Metaquantome**](https://toolshed.g2.bx.psu.edu/repository?repository_id=cab5d81c5f0a2f94) with the 
 following parameters:
    - *"Mode"*: `Function`
    - *"GO namespace"*: `Molecular Function` or `Biological Process` or ` Cellular Component`
    - *"File from HUMAnN2 after regrouping, renaming, joining, and renormalizing"*: `Renormalized data`
  
  **Note** : The MT2MQ tools can be run will all three GO name space.
  
  There are two tabular outputs from this tool.
  
  - A f_int.tabular output which mimics the Intensity input file for metaQuantome.
  - A func.tabular output which mimics the Functional input file for metaQuantome.

The resulting output files can be used as input for metaQuatome's functional mode.
To run metaQuantome Function mode. Follow the [GTN](https://github.com/subinamehta/training-material/tree/metaquantome-2-3/topics/proteomics/tutorials/metaquantome-function).
