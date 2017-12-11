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

moFF is an OS independent tool designed to extract apex MS1 intensity using a set of identified MS2 peptides. It currently uses a Go library to directly extract data from Thermo Raw spectrum files, eliminating the need for conversions from other formats. Moreover, moFF also allows to work directly with mzML files.

moFF is built up from two standalone modules :
- *moff_mbr.py* :  match between run (mbr)
- *moff.py*: apex intensity

NOTE : Please use *moff_all.py* script to run the entire pipeline with both MBR and apex strategies.

The version presented here is a commandline tool that can easily be adapted to a cluster environment. A graphical user interface can be found [here](https://github.com/compomics/moff-gui). The latter is designed to be able to use [PeptideShaker](https://github.com/compomics/peptide-shaker) results as an input format. Please refer to the [moff-GUI](https://github.com/compomics/moff-gui) manual for more information on how to do this.

[Top of page](#moff)

----

## moFF Publication:
  * [Argentini et al. Nature Methods. 2016 12(13):964–966](http://www.nature.com/nmeth/journal/v13/n12/full/nmeth.4075.html).
  * If you use moFF as part of a publication, please include this reference.

---

## Minimum Requirements ##

Required java version :
- Java Runtime Environment (JRE) 8

Required python libraries :
- Python 2.7
- pandas  > 0.20.
- numpy > 1.10.0
- argparse > 1.2.1 
- scikit-learn > 0.18
- pymzML > 0.7.7


Required linux library:
- Mono version 4.2.1

Required windows library:
- .NET Framework 4.6.2


Optional requirements :
-When using PeptideShaker results as a source, a PeptideShaker installation (<http://compomics.github.io/projects/peptide-shaker.html>) needs to be availabe.
 

During processing, moFF makes use of a third party algorithm (txic or txic.exe) which allows for the parsing of the Thermo RAW data. 
Txic is compatible with the raw outputfiles originating from any Orbitrap or triple quadrupole Thermo machine. However, Thermo Fusion instruments are currently not supported.


[Top of page](#moff)

---


## Input Data ##

moFF requires two types of input for the quantification procedure :
 - Thermo RAW file or mzML file
 - MS2 identified peptide information

The MS2 identified peptides can be presented as a tab-delimited file containing mimimal (mandatory) annotation for each peptide (a)

(a) The tab-delimited file must contain the following information for all the peptides:
  - 'peptide' : peptide-spectrum-match  sequence
  - 'prot' : protein ID 
  - 'mod_peptide' :  peptide-spectrum-match  sequence that contains also possible modification (i.e `NH2-M<Mox>LTKFESK-COOH` )
  - 'rt': peptide-spectrum-match retention time  (i.e the retention time contained in the mgf file; The retention time must be specified in second)
  - 'mz' : mass over charge
  - 'mass' : mass of the peptide
  - 'charge' : charge of the ionized peptide
 
NOTE 1 : In case the tab-delimited file provided by the user contains fields that are not mentioned here (i.e petides length, search engines score) the algorithm will retain these in the final output. The peptide-spectrum-match sequence with its modications  and the protein id  and  informations are used only in the match-between-run module.

NOTE 2 : Users can also provide the default PSM export provided by  PeptideShaker as source material for moFF.


[Top of page](#moff)

---

## Sample data  ##

The  *sample_folder* contains a resultset for 3 runs of the CPTAC study 6 (Paulovich, MCP Proteomics, 2010). These MS2  peptides were identified by MASCOT. The [raw files]( https://goo.gl/ukbpCI) for this study are required to apply moFF to the sample data.

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

`python moff_mbr.py --inputF sample_folder/` 

This command runs the MBR modules. The output will be stored in a subfolder ('mbr_output') inside the specified input folder.
The MBR module will consider all the .txt files present in the specified input folder as replicates (to select specific files or different extension, please refer to the example below).
The files in *sample_folder/mbr_output* will be identical to the input files, but they will have an additional field ('matched') that specifies which peptides have match (1) or not (0). The MBR algorithm also produces a log file in the provided input directory.


### Customizing Match between runs ###

In case of a different extension (.list, etc), please use :

`python --inputF sample_folder/ --ext list ` (Provide the extension without the period ('.'))

In case of using only specific input files within the provided directory, please use a regular expression:

`python --inputF sample_folder/  --sample *_6A` (This can be combined with the aforementioned syntax)


[Top of page](#moff)

---

## Apex intensity ##

use `python moff.py -h`
```
  --inputtsv         the input file with for MS2 peptides
  --inputraw	      specify directly the  raw file
  --tol               the mass tollerance (ppm)
  --rt_w              the rt windows for xic (minutes). Default value is 3  min
  --rt_p     	      the time windows used to get the apex for the ms2 peptide/feature  (minutes). Default value is 0.4
  --rt_p_match 	      the time windows used to get the apex for machted features (minutes). Default value is 0.6
  --raw_repo          the folder containing the raw files
  --peptide_summary   flag that allows have as output the peptided summary intensity file. Default is disable (0)
  --tag_pep_sum_file  tag string that will be part of the  peptided summary intensity file name. Default value is moFF_run
  --output_folder     the target folder for the output (default is the input folder, raw_repo)
```
For example :

`python moff.py --inputtsv sample_folder/20080311_CPTAC6_07_6A005.txt  --raw_repo sample_folder/ --tol 1O --output_folder output_moff --peptide_summary 1 `

WARNING : the raw file names MUST be the same of the input file otherwise the script gives you an error !
NOTE: All the parameters related to the the time windows (rt_w,rt_p, rt_p_match) are basicaly the half of the entire time windows where the apex peak is searched or the XiC is retrieved.

You can also specify directly the raw file using: 
`python moff.py --inputtsv sample_folder/20080311_CPTAC6_07_6A005.txt  --inputraw sample_folder/20080311_CPTAC6_07_6A005.raw --tol 1O --output_folder output_moff`

WARNING: if the user need to use Thermo RAW file can specify them using   `--inputraw` or  `--raw_rep`. In case of **mzML** file the user can ONLY specify them using   `--inputraw`



[Top of page](#moff)

---


## Entire workflow ##

use `python moff_all.py -h`
```
	--inputF		the folder containing input files 
	--inputtsv		specify the input file as a list separated by a space
	--inputraw		specify the raw file as a list separated by space
  	--sample		filter based on regular expression to define the considered replicates
  	--ext			file extension for the input files
  	--log_file_name		a label name to use for the log file
  	--filt_width		width value for  the outlier  filtering 
  	--out_filt		filtering (on/off) of the outlier in the training set
  	--weight_comb		combination weighting : 0 for no weight 1 for a weighted schema
  	--tol			the mass tollerance (ppm)
  	--rt_w			the rt windows for xic (minutes). Default value is  3  min
	--rt_p			the time windows for the ms2 peptide/feature in apex (minutes). Default value is 1
	--rt_p_match		the time windows for the matched features in apex ( minutes). Default value is 1.5
	--peptide_summary   flag that allows have as output the peptided summary intensity file. Default is disable (0)
  	--tag_pep_sum_file  tag string that will be part of the  peptided summary intensity file name. Default value is moFF_run
	--raw_repo		the folder containing the raw files
```
For a correct rt windows, we suggest to set the rt_p value equal or slighly greater to the dynamic exclusion duration set in your machine.
We suggest also to set the rt_p_match always slightly bigger than the rt windows used the MS2 fetures (rt_p )

  

`python moff_all.py --inputF  sample_folder/   --raw_repo sample_folder/ --tol 10  --output_folder output_moff --peptide_summary 1`

The options are identifcal for both apex and MBR modules. The output for the latter (MBR) is stored in the folder sample_folder/mbr_output, while the former (apex) generates files in the specified output_moff folder. Log files for both algorithms are generated in the respective folders.

You can also specify a list of input and raw files using:

`python moff_all.py --inputtsv  sample_folder/input_file1.txt sample_folder/input_file2.txt  --inputraw sample_folder/input_file1.raw sample_folder/input_file2.raw --tol 10 --output_folder output_moff --peptide_summary 1 `

Using `--inputtsv | --inputraw`  you can not filterted the input file using `--sample --ext` like in the case with `--inputF | --raw_repo`

 mzML raw file  MUST be specified  using `--inputtsv | --inputraw`. The `--raw_repo` option is not available for mzML files.

[Top of page](#moff)

---
## Output data ##

The output consists of : 

- a tab delimited file (with the same name of the input raw file) containing the apex intensity values and additional information (a)
- a log file specific to the apex module (b) or the MBR module (c)
- peptide summary intensity file (when peptide summary option is enabled) (d) 

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

(d) The peptide summary intensity is a tab delimited file where for each  peptide sequence the MS1 intensities are summed for all the occurences in each runs (aggregated by charge states and modification). In case you run the entire workflow this file will contains the summed intensity for all the runs, insted of just a selected run in case of the apex module. Along with peptide sequences also the protein ids are provided. The file could be used for downstream statistical analysis   

NOTE : The log files and the output files are in the output folder specified by the user. 

[Go to top of page](#moff)
