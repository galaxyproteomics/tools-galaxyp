"""
The purpose of this script is to create source files from different databases to be used in other tools
"""

import os, sys, argparse, requests, time, csv, re
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

def _add_data_table_entry(data_manager_dict, data_table_entry,data_table):
    data_manager_dict['data_tables'] = data_manager_dict.get('data_tables', {})
    data_manager_dict['data_tables'][data_table] = data_manager_dict['data_tables'].get(data_table, [])
    data_manager_dict['data_tables'][data_table].append(data_table_entry)
    return data_manager_dict

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
    _add_data_table_entry(data_manager_dict, data_table_entry, "protein_atlas")


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
        w.writerow(["Uniprot_AC","nb_obs"])
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



#######################################################################################################
# 3. ID mapping file
#######################################################################################################
import ftplib, gzip
csv.field_size_limit(sys.maxsize) # to handle big files

def id_mapping_sources (data_manager_dict, species, target_directory) :

    human = species == "human"
    species_dict = { "human" : "HUMAN_9606", "mouse" : "MOUSE_10090", "rat" : "RAT_10116" }
    files=["idmapping_selected.tab.gz","idmapping.dat.gz"]

    #header
    if human : tab = [["UniProt-AC","UniProt-ID","GeneID","RefSeq","GI","PDB","GO","PIR","MIM","UniGene","Ensembl_Gene","Ensembl_Transcript","Ensembl_Protein","neXtProt","BioGrid","STRING","KEGG"]]
    else : tab = [["UniProt-AC","UniProt-ID","GeneID","RefSeq","GI","PDB","GO","PIR","MIM","UniGene","Ensembl_Gene","Ensembl_Transcript","Ensembl_Protein","BioGrid","STRING","KEGG"]]

    #print("header ok")

    #selected.tab and keep only ids of interest
    selected_tab_file=species_dict[species]+"_"+files[0]
    tab_path = download_from_uniprot_ftp(selected_tab_file,target_directory)
    with gzip.open(tab_path,"rt") as select :
        tab_reader = csv.reader(select,delimiter="\t")
        for line in tab_reader :
            tab.append([line[i] for i in [0,1,2,3,4,5,6,11,13,14,18,19,20]])
    os.remove(tab_path)

    #print("selected_tab ok")

    """
    Supplementary ID to get from HUMAN_9606_idmapping.dat :
    -NextProt,BioGrid,STRING,KEGG
    """

    if human : ids = ['neXtProt','BioGrid','STRING','KEGG' ]   #ids to get from dat_file
    else : ids = ['BioGrid','STRING','KEGG' ]
    unidict = {}

    #keep only ids of interest in dictionaries
    dat_file=species_dict[species]+"_"+files[1]
    dat_path = download_from_uniprot_ftp(dat_file,target_directory)
    with gzip.open(dat_path,"rt") as dat :
        dat_reader = csv.reader(dat,delimiter="\t")
        for line in dat_reader :
            uniprotID=line[0]       #UniProtID as key
            id_type=line[1]         #ID type of corresponding id, key of sub-dictionnary
            cor_id=line[2]          #corresponding id
            if "-" not in id_type :                                 #we don't keep isoform
                if id_type in ids and uniprotID in unidict :
                    if id_type in unidict[uniprotID] :
                        unidict[uniprotID][id_type]= ";".join([unidict[uniprotID][id_type],cor_id])    #if there is already a value in the dictionnary
                    else :          
                        unidict[uniprotID].update({ id_type : cor_id })
                elif  id_type in ids :
                    unidict[uniprotID]={id_type : cor_id}
    os.remove(dat_path)

    #print("dat_file ok")

    #add ids from idmapping.dat to the final tab
    for line in tab[1:] :
        uniprotID=line[0]
        if human :
            if uniprotID in unidict :
                nextprot = access_dictionary(unidict,uniprotID,'neXtProt')
                if nextprot != '' : nextprot = clean_nextprot_id(nextprot,line[0])
                line.extend([nextprot,access_dictionary(unidict,uniprotID,'BioGrid'),access_dictionary(unidict,uniprotID,'STRING'),
                        access_dictionary(unidict,uniprotID,'KEGG')])
            else :
                line.extend(["","","",""])
        else :
            if uniprotID in unidict :
                line.extend([access_dictionary(unidict,uniprotID,'BioGrid'),access_dictionary(unidict,uniprotID,'STRING'),
                        access_dictionary(unidict,uniprotID,'KEGG')])
            else :
                line.extend(["","",""])

    #print ("tab ok")

    #add missing nextprot ID for human
    if human : 
        #build next_dict
        nextprot_ids = id_list_from_nextprot_ftp("nextprot_ac_list_all.txt",target_directory)
        next_dict = {}
        for nextid in nextprot_ids : 
            next_dict[nextid.replace("NX_","")] = nextid
        os.remove(os.path.join(target_directory,"nextprot_ac_list_all.txt"))

        #add missing nextprot ID
        for line in tab[1:] : 
            uniprotID=line[0]
            nextprotID=line[13]
            if nextprotID == '' and uniprotID in next_dict :
                line[13]=next_dict[uniprotID]

    output_file = species+"_id_mapping_"+ time.strftime("%d-%m-%Y") + ".tsv"
    path = os.path.join(target_directory,output_file)

    with open(path,"w") as out :
        w = csv.writer(out,delimiter='\t')
        w.writerows(tab)

    name_dict={"human" : "Homo sapiens", "mouse" : "Mus musculus", "rat" : "Rattus norvegicus"}
    name = name_dict[species]+" ("+time.strftime("%d-%m-%Y")+")"

    data_table_entry = dict(value = species+"_id_mapping_"+ time.strftime("%d-%m-%Y"), name = name, path = path)
    _add_data_table_entry(data_manager_dict, data_table_entry, "id_mapping")

def download_from_uniprot_ftp(file,target_directory) :
    ftp_dir = "pub/databases/uniprot/current_release/knowledgebase/idmapping/by_organism/"
    path = os.path.join(target_directory, file)
    ftp = ftplib.FTP("ftp.uniprot.org")
    ftp.login("anonymous", "anonymous") 
    ftp.cwd(ftp_dir)
    ftp.retrbinary("RETR " + file, open(path, 'wb').write)
    ftp.quit()
    return (path)

def id_list_from_nextprot_ftp(file,target_directory) :
    ftp_dir = "pub/current_release/ac_lists/"
    path = os.path.join(target_directory, file)
    ftp = ftplib.FTP("ftp.nextprot.org")
    ftp.login("anonymous", "anonymous") 
    ftp.cwd(ftp_dir)
    ftp.retrbinary("RETR " + file, open(path, 'wb').write)
    ftp.quit()
    with open(path,'r') as nextprot_ids :
        nextprot_ids = nextprot_ids.read().splitlines()
    return (nextprot_ids)

#return '' if there's no value in a dictionary, avoid error
def access_dictionary (dico,key1,key2) :
    if key1 in dico :
        if key2 in dico[key1] :
            return (dico[key1][key2])
        else :
            return ("")
            #print (key2,"not in ",dico,"[",key1,"]")
    else :
        return ('')

#if there are several nextprot ID for one uniprotID, return the uniprot like ID
def clean_nextprot_id (next_id,uniprotAc) :
    if len(next_id.split(";")) > 1 :
        tmp = next_id.split(";")
        if "NX_"+uniprotAc in tmp :
            return ("NX_"+uniprotAc)
        else :
            return (tmp[1])
    else :
        return (next_id)


#######################################################################################################
# Main function
#######################################################################################################
def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--hpa", metavar = ("HPA_OPTION"))
    parser.add_argument("--peptideatlas", metavar=("SAMPLE_CATEGORY_ID"))
    parser.add_argument("--id_mapping", metavar = ("ID_MAPPING_SPECIES"))
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

    ## Download ID_mapping source file from Uniprot
    try:
        id_mapping=args.id_mapping
    except NameError:
        id_mapping = None
    if id_mapping is not None:
        id_mapping = id_mapping .split(",")
        for species in id_mapping :
            id_mapping_sources(data_manager_dict, species, target_directory)
 
    #save info to json file
    filename = args.output
    open(filename, 'wb').write(to_json_string(data_manager_dict))

if __name__ == "__main__":
    main()
