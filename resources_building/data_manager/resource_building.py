"""
The purpose of this script is to create source files from different databases to be used in other tools
"""

import os
import argparse
import requests
import time
import csv
import re
from io import BytesIO
from zipfile import ZipFile
from galaxy.util.json import from_json_string, to_json_string

#######################################################################################################
# General functions
#######################################################################################################
def unzip(url, output_file):
    """
    Get a zip file content from a link and unzip
    """
    content = requests.get(url)
    zipfile = ZipFile(BytesIO(content.content))
    output_content = ""
    output_content += zipfile.open(zipfile.namelist()[0]).read()
    output = open(output_file, "w")
    output.write(output_content)
    output.close()

#######################################################################################################
# 1. Human Protein Atlas
#    - Normal tissue
#    - Pathology
#    - Full Atlas
#######################################################################################################
def HPA_sources(data_manager_dict, tissue, target_directory):
    if tissue == "HPA_normal_tissue":
        tissue_name = "HPA normal tissue"
        url = "https://www.proteinatlas.org/download/normal_tissue.tsv.zip"
    elif tissue == "HPA_pathology":
        tissue_name = "HPA pathology"
        url = "https://www.proteinatlas.org/download/pathology.tsv.zip"
    elif tissue == "HPA_full_atlas":
        tissue_name = "HPA full atlas"
        url = "https://www.proteinatlas.org/download/proteinatlas.tsv.zip"
    output_file = tissue +"_"+ time.strftime("%d-%m-%Y") + ".tsv"
    path = os.path.join(target_directory, output_file)
    unzip(url, path)
    print(str(os.path.isfile(path)))
    tmp=open(path,"r").readlines()
    tissue_name = tissue_name + " " + time.strftime("%d/%m/%Y")
    data_table_entry = dict(value = tissue, name = tissue_name, path = path)
    _add_data_table_entry(data_manager_dict, data_table_entry, "proteinatlas")

#######################################################################################################
# 2. Peptide Atlas
#######################################################################################################
def peptide_atlas_sources(data_manager_dict, tissue, target_directory):
    # Define PA Human build released number (here  early 2018)
    atlas_build_id = "472"
    # Define organism_id (here Human) - to be upraded when other organism added to the project
    organism_id = "2"
    # Extract sample_category_id and output filename
    sample_category_id = tissue.split("-")[0]
    output_file = tissue.split("-")[1] +"_"+ time.strftime("%d-%m-%Y") + ".tsv"
    query = "https://db.systemsbiology.net/sbeams/cgi/PeptideAtlas/GetPeptides?atlas_build_id=" + \
            atlas_build_id + "&display_options=ShowMappings&organism_id= " + \
            organism_id + "&sample_category_id=" + sample_category_id + \
            "&QUERY_NAME=AT_GetPeptides&output_mode=tsv&apply_action=QUERY"
    download = requests.get(query)
    decoded_content = download.content.decode('utf-8')
    cr = csv.reader(decoded_content.splitlines(), delimiter='\t')

    #build dictionary by only keeping uniprot accession (not isoform) as key and sum of observations as value
    uni_dict = build_dictionary(cr)

    tissue_id = "_".join([atlas_build_id, organism_id, sample_category_id,time.strftime("%d-%m-%Y")])
    tissue_value = tissue.split("-")[1]
    tissue = tissue.split("-")[1] + "_" +time.strftime("%d-%m-%Y")
    tissue_name = " ".join(tissue_value.split("_")) + " " + time.strftime("%d/%m/%Y")
    path = os.path.join(target_directory,output_file)

    with open(path,"wb") as out :
        w = csv.writer(out,delimiter='\t')
        w.writerows(uni_dict.items())
        
    data_table_entry = dict(value = path, name = tissue_name, tissue = tissue)
    _add_data_table_entry(data_manager_dict, data_table_entry, "peptide_atlas")

#function to count the number of observations by uniprot id
def build_dictionary (csv) :
    uni_dict = {} 
    for line in csv :
        if "-" not in line[2] and check_uniprot_access(line[2]) :
            if line[2] in uni_dict :
                uni_dict[line[2]] += int(line[4])
            else : 
                uni_dict[line[2]] = int(line[4])

    return uni_dict

#function to check if an id is an uniprot accession number : return True or False-
def check_uniprot_access (id) :
    uniprot_pattern = re.compile("[OPQ][0-9][A-Z0-9]{3}[0-9]|[A-NR-Z][0-9]([A-Z][A-Z0-9]{2}[0-9]){1,2}")
    if uniprot_pattern.match(id) :
        return True
    else :
        return False


def _add_data_table_entry(data_manager_dict, data_table_entry,data_table):
    data_manager_dict['data_tables'] = data_manager_dict.get('data_tables', {})
    data_manager_dict['data_tables'][data_table] = data_manager_dict['data_tables'].get(data_table, [])
    data_manager_dict['data_tables'][data_table].append(data_table_entry)
    return data_manager_dict

#######################################################################################################
# Main function
#######################################################################################################
def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--hpa", metavar = ("HPA_OPTION"))
    parser.add_argument("--peptideatlas", metavar=("SAMPLE_CATEGORY_ID"))
    parser.add_argument("-o", "--output")
    args = parser.parse_args()

    data_manager_dict = {}
    # Extract json file params
    filename = args.output
    params = from_json_string(open(filename).read())
    target_directory = params[ 'output_data' ][0]['extra_files_path']
    os.mkdir(target_directory)

    ## Download source files from HPA
    try:
        hpa = args.hpa
    except NameError:
        hpa = None
    if hpa is not None:
        #target_directory = "/projet/galaxydev/galaxy/tools/proteore/ProteoRE/tools/resources_building/test-data/"
        hpa = hpa.split(",")
        for hpa_tissue in hpa:
            HPA_sources(data_manager_dict, hpa_tissue, target_directory)
    
    ## Download source file from Peptide Atlas query
    try:
        peptide_atlas = args.peptideatlas
    except NameError:
        peptide_atlas = None
    if peptide_atlas is not None:
        #target_directory = "/projet/galaxydev/galaxy/tools/proteore/ProteoRE/tools/resources_building/test-data/"
        peptide_atlas = peptide_atlas.split(",")
        for pa_tissue in peptide_atlas:
            peptide_atlas_sources(data_manager_dict, pa_tissue, target_directory)
 
    #save info to json file
    filename = args.output
    open(filename, 'wb').write(to_json_string(data_manager_dict))

if __name__ == "__main__":
    main()
