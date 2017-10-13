# moFF #

 * [Introduction](#introduction)
 * [Minimum Requirements](#minimum-requirements)
 * [Input Data](#input-data)
 * [Sample Data](#sample-data)
 * [Match between runs](#match-between-runs)
 * [Apex Intensity](#apex-intensity)
 * [Entire workflow](#entire-workflow)
 * [Output Data](#output-data)

---

## Introduction ##

moFF is an OS independent tool designed to extract apex MS1 intensity using a set of identified MS2 peptides. It currently uses a Go library to directly extract data from Thermo Raw spectrum files, eliminating the need for conversions from other formats.

moFF is built up from two standalone modules :
- *moff_mbr.py* :  match between run (mbr)
- *moff.py*: apex intensity

NOTE : Please use *moff_all.py* script to run the entire pipeline with both MBR and apex strategies.

The version presented here is a commandline tool that can easily be adapted to a cluster environment. A graphical user interface can be found [here](https://github.com/compomics/moff-gui). The latter is designed to be able to use [PeptideShaker](https://github.com/compomics/peptide-shaker) results as an input format.

[Top of page](#moff)

----

## Minimum Requirements ##

Required java version :
- Java Runtime Environment (JRE) 8

Required python libraries :
- Python 2.7
- pandas  > 0.17.
- numpy > 1.10.0
- argparse > 1.2.1 
- scikit-learn > 0.17

Optional requirements :
-When using PeptideShaker results as a source, a PeptideShaker installation (<http://compomics.github.io/projects/peptide-shaker.html>) needs to be availabe.
 

During processing, moFF makes use of a third party algorithm (txic or txic.exe) which allows for the parsing of the Thermo RAW data. 
Txic is compatible with the raw outputfiles originating from any Orbitrap or triple quadrupole Thermo machine. However, Thermo Fusion instruments are currently not supported.

[Top of page](#moff)

---


##Input Data

moFF-GUI requires two types of input for the quantification procedure :
 - Thermo RAW file 
 - MS2 identified peptide information

The MS2 identified peptides can be presented as a tab-delimited file containing mimimal (mandatory) annotation for each peptide (a)

(a) The tab-delimited file must contain the following information for all the peptides:
  - 'peptide' : sequence of the peptide
  - 'prot': protein ID 
  - 'rt': peptide retention time  ( The retention time must be specified in second )
  - 'mz' : mass over charge
  - 'mass' : mass of the peptide
  - 'charge' : charge of the ionized peptide
 
NOTE 1 : In case the tab-delimited file provided by the user contains fields that are not mentioned here (i.e modifications,petides length) the algorithm will retain these in the final output.

NOTE 2 : Users can also provide PeptideShaker output as source material for moFF. Please refer to the [moff-GUI](https://github.com/compomics/moff-gui) manual for more information on how to do this.

[Top of page](#moff)

---

## Sample data  ##

The  *f1_folder* contains a resultset for 3 runs of the CPTAC study 6 (Paulovich, MCP Proteomics, 2010). These MS2  peptides were identified by MASCOT. The [raw files]( https://goo.gl/ukbpCI) for this study are required to apply moFF to the sample data.

---

## Match between runs ##

use :  `python moff_mbr.py -h`
```
	--inputF              the folder where the input files are located 
  	--sample	      filter based on regular expression to define the considered replicates
  	--ext                 file extention of the input file
  	--log_file_name       filename for the log file
  	--filt_width          width value for outlier filtering 
  	--out_filt            filtering (on/off) of the outlier in the training set
  	--weight_comb         combination weighting : 0 for no weight 1 for a weighted schema
```

`python moff_mbr.py --inputF f1_folder/` 

This command runs the MBR modules. The output will be stored in a subfolder ('mbr_output') inside the specified input folder.
The MBR module will consider all the .txt files present in the specified input folder as replicates (to select specific files or different extension, please refer to the example below).
The files in *f1_folder/mbr_output* will be identical to the input files, but they will have an additional field ('matched') that specifies which peptides have match (1) or not (0). The MBR algorithm also produces a log file in the provided input directory.

### Customizing Match between runs ###

In case of a different extension (.list, etc), please use :

`python --inputF f1_folder/ --ext list ` (Provide the extension without the period ('.'))

In case of using only specific input files within the provided directory, please use a regular expression:

`python --inputF f1_folder/  --sample *_6A ` (This can be combined with the aforementioned syntax)


[Top of page](#moff)

---

## Apex intensity ##

use  `python moff.py -h`
````
  --input NAME        the input file with for MS2 peptides
  --tol               the mass tollerance (ppm)
  --rt_w              the rt windows for xic (minutes). Default value is 3  min
  --rt_p     	      the time windows used to get the apex for the ms2 peptide/feature  (minutes). Default value is 0.2
  --rt_p_match 	      the time windows used to get the apex for machted features (minutes). Default value is 0.4
  --raw_repo          the folder containing the raw files
  --output_folder     the target folder for the output (default is the input folder, raw_repo)
```
For example :

`python moff.mbr --input f1_folder/20080311_CPTAC6_07_6A005.txt  --raw_rep f1_folder/ --tol 1O --output_folder output_moff`

WARNING : the raw file names  MUST be the same of the input file otherwise the script give you an error !
NOTE: All the parameters related to the the time windows (rt_w,rt_p, rt_p_match) are basicaly the half of the entire time windows where the apex peak is searched or the XiC is retrieved.

[Top of page](#moff)

---

## Entire workflow ##

use `python moff_all.py -h`
```
	--inputF              the folder containing input files 
  	--sample	      filter based on regular expression to define the considered replicates
  	--ext                 file extension for the input files
  	--log_file_name       a label name to use for the log file
  	--filt_width          width value for  the outlier  filtering 
  	--out_filt            filtering (on/off) of the outlier in the training set
  	--weight_comb         combination weighting : 0 for no weight 1 for a weighted schema
  	--input               the input file for identified MS2 peptides
  	--tol                 the mass tollerance (ppm)
  	--rt_w                the rt windows for xic (minutes). Default value is  3  min
	--rt_p     	      the time windows for the ms2 peptide/feature in apex (minutes). Default value is 0.2
	--rt_p_match 	      the time windows for the matched features in apex ( minutes). Default value is 0.4
	--raw_repo            the folder containing the raw files
```
`python moff_all.py --inputF  f1_folder/   --raw_repo f1_folder/ --output_folder output_moff`

The options are identifcal for both apex and MBR modules. The output for the latter (MBR) is stored in the folder f1_folder/mbr_output, while the former (apex) generates files in the specified output_moff folder. Log files for both algorithms are generated in the respective folders

[Top of page](#moff)

---
## Output data

The output consists of : 

- a tab delimited file (with the same name of the input raw file) containing the apex intensity values and additional information (a)
- a log file specific to the apex module (b) or the MBR module (c)

(a) Description of the fields added by moFF in the output file:

Parameter | Meaning
--- | -------------- | 
*rt_peak* | retention time (in seconds) for the discovered apex peak
*SNR*     | signal-to-noise ratio of the peak intensity.
*log_L_R*'| peak shape. 0 indicates that the peak is centered. Positive or negative values are an indicator for respectively right or left skewness 
*intensity* |  MS1 intensity
*log_int* | log2 transformed MS1 intensity 
*lwhm* | first rt value where the intensity is at least the 50% of the apex peak intensity on the left side
*rwhm* | first rt value where the intensity is at least the 50% of the apex peak intensity on the right side
*5p_noise* | 5th percentile of the intensity values contained in the XiC. This value is used for the *SNR* computation
*10p_noise* |  10th percentile of the intensity values contained in the XiC.
*code_unique* | this field is concatenation of the peptide sequence and mass values. It is used by moFF during the match-between-runs.
*matched* | this value indicated if the featured has been added by the match-between-run (1) or is a ms2 identified features (0) 

(b) A log file is also provided containing the process output. 

(c) A log file where all the information about all the trained linear model are displayed.

NOTE : The log files and the output files are in the output folder specified by the user. 

[Go to top of page](#moff)
