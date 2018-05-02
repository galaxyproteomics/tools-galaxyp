"""
The purpose of this script is to create source files from different databases to be used in other tools
"""

import argparse
import requests
from io import BytesIO
from zipfile import ZipFile

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
def HPA_sources(tissue):
    if tissue == "HPA_normal_tissue":
        url = "https://www.proteinatlas.org/download/normal_tissue.tsv.zip"
    elif tissue == "HPA_pathology":
        url = "https://www.proteinatlas.org/download/pathology.tsv.zip"
    elif tissue == "HPA_full_atlas":
        url = "https://www.proteinatlas.org/download/proteinatlas.tsv.zip"
    output_file = tissue + ".tsv"
    unzip(url, output_file)

#######################################################################################################
# 2. Peptide Atlas
#######################################################################################################
def peptide_atlas_sources(tissue):
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
    output = open(output_file, "w")
    output.write(content.content)
    output.close()

#######################################################################################################
# Main function
#######################################################################################################
def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--hpa", metavar = ("HPA_OPTION"))
    parser.add_argument("--peptideatlas", metavar=("SAMPLE_CATEGORY_ID"))
    args = parser.parse_args()

    ## Download source files from HPA
    try:
        hpa = args.hpa
    except NameError:
        hpa = None
    if hpa is not None:
        hpa = hpa.split(",")
        for hpa_tissue in hpa:
            HPA_sources(hpa_tissue)
    
    ## Download source file from Peptide Atlas query
    try:
        peptide_atlas = args.peptideatlas
    except NameError:
        peptide_atlas = None
    if peptide_atlas is not None:
        peptide_atlas = peptide_atlas.split(",")
        for pa_tissue in peptide_atlas:
            peptide_atlas_sources(pa_tissue)

if __name__ == "__main__":
    main()
