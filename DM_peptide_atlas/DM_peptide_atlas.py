"""
The purpose of this script is to create source files from peptide atlas for the tool : 'number of MS/MS in a tissue sample'
"""

import os
import argparse
import requests
import time
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
# Peptide Atlas
#######################################################################################################
def peptide_atlas_sources(data_manager_dict, tissue, target_directory):
    # Define PA Human build released number (here  early 2018)
    atlas_build_id = "472"
    # Define organism_id (here Human) - to be upraded when other organism added to the project
    organism_id = "2"
    # Extract sample_category_id and output filename
    sample_category_id = tissue.split("-")[0]
    output_file = tissue.split("-")[1] + ".tsv"
    query = "https://db.systemsbiology.net/sbeams/cgi/PeptideAtlas/GetPeptides?atlas_build_id=" + \
            atlas_build_id + "&display_options=ShowMappings&organism_id= " + \
            organism_id + "&sample_category_id=" + sample_category_id + \
            "&QUERY_NAME=AT_GetPeptides&output_mode=tsv&apply_action=QUERY"
    content = requests.get(query)
    tissue_id = "_".join([atlas_build_id, organism_id, sample_category_id])
    tissue_value = " ".join(tissue.split("-")[1].split("_"))
    tissue_name = tissue_value + " " + time.strftime("%d/%m/%Y")
    path = os.path.join(target_directory, output_file)
    output = open(path, "w")
    output.write(content.content)
    output.close()
    data_table_entry = dict(value = tissue_value, name = tissue_name, path = path)
    _add_data_table_entry(data_manager_dict, data_table_entry)

def _add_data_table_entry(data_manager_dict, data_table_entry):
    data_manager_dict['data_tables'] = data_manager_dict.get('data_tables', {})
    data_manager_dict['data_tables']['peptide_atlas'] = data_manager_dict['data_tables'].get('peptide_atlas', [])
    data_manager_dict['data_tables']['peptide_atlas'].append(data_table_entry)
    return data_manager_dict

#######################################################################################################
# Main function
#######################################################################################################
def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--peptideatlas", metavar=("SAMPLE_CATEGORY_ID"))
    parser.add_argument("-o", "--output")
    args = parser.parse_args()

    data_manager_dict = {}
    # Extract json file params
    filename = args.output
    params = from_json_string(open(filename).read())
    target_directory = params[ 'output_data' ][0]['extra_files_path']
    print (target_directory)
    os.mkdir(target_directory)
    
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
