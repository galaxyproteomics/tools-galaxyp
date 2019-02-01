# -*- coding: utf-8 -*-
"""
The purpose of this script is to create source files from different databases to be used in other proteore tools
"""

import os, sys, argparse, requests, time, csv, re, json, shutil, zipfile
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
    unzip(url, path)    #download and save file
    tissue_name = tissue_name + " " + time.strftime("%d/%m/%Y")
    tissue_id = tissue_name.replace(" ","_").replace("/","-")

    data_table_entry = dict(id=tissue_id, name = tissue_name, value = tissue, path = path)
    _add_data_table_entry(data_manager_dict, data_table_entry, "proteore_protein_atlas")


#######################################################################################################
# 2. Peptide Atlas
#######################################################################################################
def peptide_atlas_sources(data_manager_dict, tissue, date, target_directory):
    # Define organism_id (here Human) - to be upraded when other organism added to the project
    organism_id = "2"
    # Extract sample_category_id and output filename
    tissue=tissue.split(".")
    sample_category_id = tissue[0]
    tissue_name = tissue[1]
    output_file = tissue_name+"_"+date + ".tsv"

    query="https://db.systemsbiology.net/sbeams/cgi/PeptideAtlas/GetProteins?&atlas_build_id="+ \
    sample_category_id+"&display_options=ShowAbundances&organism_id="+organism_id+ \
    "&redundancy_constraint=4&presence_level_constraint=1%2C2&gene_annotation_level_constraint=leaf\
    &QUERY_NAME=AT_GetProteins&action=QUERY&output_mode=tsv&apply_action=QUERY"

    with requests.Session() as s:
        download = s.get(query)
        decoded_content = download.content.decode('utf-8')
        cr = csv.reader(decoded_content.splitlines(), delimiter='\t')

    uni_dict = build_dictionary(cr)

    #columns of data table peptide_atlas
    tissue_id = tissue_name+"_"+date
    name = tissue_id.replace("-","/").replace("_"," ")
    path = os.path.join(target_directory,output_file)

    with open(path,"w") as out :
        w = csv.writer(out,delimiter='\t')
        w.writerow(["Uniprot_AC","nb_obs"])
        w.writerows(uni_dict.items())
        
    data_table_entry = dict(id=tissue_id, name=name, value = path, tissue = tissue_name)
    _add_data_table_entry(data_manager_dict, data_table_entry, "proteore_peptide_atlas")

#function to count the number of observations by uniprot id
def build_dictionary (csv) :
    uni_dict = {} 
    for line in csv :
        if "-" not in line[0] and check_uniprot_access(line[0]) :
            if line[0] in uni_dict :
                uni_dict[line[0]] += int(line[5])
            else : 
                uni_dict[line[0]] = int(line[5])

    return uni_dict

#function to check if an id is an uniprot accession number : return True or False-
def check_uniprot_access (id) :
    uniprot_pattern = re.compile("[OPQ][0-9][A-Z0-9]{3}[0-9]|[A-NR-Z][0-9]([A-Z][A-Z0-9]{2}[0-9]){1,2}")
    if uniprot_pattern.match(id) :
        return True
    else :
        return False

def check_entrez_geneid (id) :
    entrez_pattern = re.complie("[0-9]+|[A-Z]{1,2}_[0-9]+|[A-Z]{1,2}_[A-Z]{1,4}[0-9]+")
    if entrez_pattern.match(id) :
        return True
    else :
        return False

#######################################################################################################
# 3. ID mapping file
#######################################################################################################
import ftplib, gzip
csv.field_size_limit(sys.maxsize) # to handle big files

def id_mapping_sources (data_manager_dict, species, target_directory) :

    human = species == "Human"
    species_dict = { "Human" : "HUMAN_9606", "Mouse" : "MOUSE_10090", "Rat" : "RAT_10116" }
    files=["idmapping_selected.tab.gz","idmapping.dat.gz"]

    #header
    if human : tab = [["UniProt-AC","UniProt-ID","GeneID","RefSeq","GI","PDB","GO","PIR","MIM","UniGene","Ensembl_Gene","Ensembl_Transcript","Ensembl_Protein","neXtProt","BioGrid","STRING","KEGG"]]
    else : tab = [["UniProt-AC","UniProt-ID","GeneID","RefSeq","GI","PDB","GO","PIR","MIM","UniGene","Ensembl_Gene","Ensembl_Transcript","Ensembl_Protein","BioGrid","STRING","KEGG"]]

    #print("header ok")

    #get selected.tab and keep only ids of interest
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

    #there's more id type for human
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

    name_dict={"Human" : "Homo sapiens", "Mouse" : "Mus musculus", "Rat" : "Rattus norvegicus"}
    name = species +" (" + name_dict[species]+" "+time.strftime("%d/%m/%Y")+")"
    id = species+"_id_mapping_"+ time.strftime("%d-%m-%Y")

    data_table_entry = dict(id=id, name = name, value = species, path = path)
    _add_data_table_entry(data_manager_dict, data_table_entry, "proteore_id_mapping")

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
# 4. Build protein interaction maps files
#######################################################################################################

def get_interactant_name(line):

    if line[0] in dico_geneid_to_gene_name :
        print line[0]
        interactant_A = dico_geneid_to_gene_name[line[0]]
    else :
        interactant_A = "NA"

    if line[1] in dico_geneid_to_gene_name :
        interactant_B = dico_geneid_to_gene_name[line[1]]
    else :
        interactant_B = "NA"

    return interactant_A, interactant_B

def PPI_ref_files(data_manager_dict, species, interactome, target_directory):

    species_dict={'Human':'Homo sapiens',"Mouse":"Mus musculus","Rat":"Rattus norvegicus"}

    ##BioGRID
    if interactome=="biogrid":

        tab2_link="https://downloads.thebiogrid.org/Download/BioGRID/Release-Archive/BIOGRID-3.5.167/BIOGRID-ORGANISM-3.5.167.tab2.zip"

        #download zip file
        r = requests.get(tab2_link)
        with open("BioGRID.zip", "wb") as code:
            code.write(r.content)
    
        #unzip files
        with zipfile.ZipFile("BioGRID.zip", 'r') as zip_ref:
            if not os.path.exists("tmp_BioGRID"): os.makedirs("tmp_BioGRID")
            zip_ref.extractall("tmp_BioGRID")

        #import file of interest and build dictionary
        file_path="tmp_BioGRID/BIOGRID-ORGANISM-"+species_dict[species].replace(" ","_")+"-3.5.167.tab2.txt"
        with open(file_path,"r") as handle :
            tab_file = csv.reader(handle,delimiter="\t")
            dico_network = {}
            GeneID_index=1
            network_cols=[1,2,7,8,11,12,14,18,20]
            for line in tab_file : 
                if line[GeneID_index] not in dico_network:
                    dico_network[line[GeneID_index]]=[[line[i] for i in network_cols]]
                else:
                    dico_network[line[GeneID_index]].append([line[i] for i in network_cols])

        #delete tmp_BioGRID directory
        os.remove("BioGRID.zip")
        shutil.rmtree("tmp_BioGRID", ignore_errors=True) 
        
        #download NCBI2Reactome.txt file and build dictionary
        with requests.Session() as s:
            r = s.get('https://www.reactome.org/download/current/NCBI2Reactome.txt')
            r.encoding ="utf-8"
            tab_file = csv.reader(r.content.splitlines(), delimiter='\t')

        dico_nodes = {}
        geneid_index=0
        pathway_description_index=3
        species_index=5
        for line in tab_file :
            if line[species_index]==species_dict[species]:
                if line[geneid_index] in dico_nodes :
                    dico_nodes[line[geneid_index]].append(line[pathway_description_index])
                else :
                    dico_nodes[line[geneid_index]] = [line[pathway_description_index]]

        dico={}
        dico['network']=dico_network
        dico['nodes']=dico_nodes

    ##Bioplex
    elif interactome=="bioplex":

        with requests.Session() as s:
            r = s.get('http://bioplex.hms.harvard.edu/data/BioPlex_interactionList_v4a.tsv')
            r = r.content.decode('utf-8')
            bioplex = csv.reader(r.splitlines(), delimiter='\t')

        dico_network = {}
        dico_network["GeneID"]={}
        network_geneid_cols=[0,1,4,5,8]
        dico_network["UniProt-AC"]={}
        network_uniprot_cols=[2,3,4,5,8]
        dico_GeneID_to_UniProt = {}
        for line in bioplex :
            if line[0] not in dico_network["GeneID"]:
                dico_network["GeneID"][line[0]]=[[line[i] for i in network_geneid_cols]]
            else :
                dico_network["GeneID"][line[0]].append([line[i] for i in network_geneid_cols])
            if line[1] not in dico_network["UniProt-AC"]:
                dico_network["UniProt-AC"][line[2]]=[[line[i] for i in network_uniprot_cols]]
            else:
                dico_network["UniProt-AC"][line[2]].append([line[i] for i in network_uniprot_cols])
            dico_GeneID_to_UniProt[line[0]]=line[2]

        with requests.Session() as s:
            r = s.get('https://reactome.org/download/current/UniProt2Reactome.txt')
            r.encoding ="utf-8"
            tab_file = csv.reader(r.content.splitlines(), delimiter='\t')

        dico_nodes_uniprot = {}
        uniProt_index=0
        pathway_description_index=3
        species_index=5
        for line in tab_file :
            if line[species_index]==species_dict[species]:
                if line[uniProt_index] in dico_nodes_uniprot :
                    dico_nodes_uniprot[line[uniProt_index]].append(line[pathway_description_index])
                else :
                    dico_nodes_uniprot[line[uniProt_index]] = [line[pathway_description_index]]

        with requests.Session() as s:
            r = s.get('https://www.reactome.org/download/current/NCBI2Reactome.txt')
            r.encoding ="utf-8"
            tab_file = csv.reader(r.content.splitlines(), delimiter='\t')

        dico_nodes_geneid = {}
        geneid_index=0
        pathway_description_index=3
        species_index=5
        for line in tab_file :
            if line[species_index]==species_dict[species]:
                if line[geneid_index] in dico_nodes_geneid :
                    dico_nodes_geneid[line[geneid_index]].append(line[pathway_description_index])
                else :
                    dico_nodes_geneid[line[geneid_index]] = [line[pathway_description_index]]

        dico={}
        dico_nodes={}
        dico_nodes['GeneID']=dico_nodes_geneid
        dico_nodes['UniProt-AC']=dico_nodes_uniprot
        dico['network']=dico_network
        dico['nodes']=dico_nodes
        dico['convert']=dico_GeneID_to_UniProt

    ##Humap
    elif interactome=="humap":

        with requests.Session() as s:
            r = s.get('http://proteincomplexes.org/static/downloads/nodeTable.txt')
            r = r.content.decode('utf-8')
            humap_nodes = csv.reader(r.splitlines(), delimiter=',')

        dico_geneid_to_gene_name={}
        for line in humap_nodes :
            if check_entrez_geneid(line[5]):
                if line[5] not in dico_geneid_to_gene_name:
                    dico_geneid_to_gene_name[line[5]]=[line[4]]
                else :
                    if line[4] not in dico_geneid_to_gene_name[line[5]] :
                        dico_geneid_to_gene_name[line[5]].append(line[4])

        with requests.Session() as s:
            r = s.get('http://proteincomplexes.org/static/downloads/pairsWprob.txt')
            r = r.content.decode('utf-8')
            humap = csv.reader(r.splitlines(), delimiter='\t')

        dico_network = {}
        for line in humap :
            if check_entrez_geneid(line[0]) and check_entrez_geneid(line[1]):

                interactant_A, interactant_B = get_interactant_name(line,dico_geneid_to_gene_name)

                if line[0] not in dico_network:
                    dico_network[line[0]]=[line[:2]+[interactant_A,interactant_B,line[2]]]
                else :
                    dico_network[line[0]].append(line[:2]+[interactant_A,interactant_B,line[2]])

        with requests.Session() as s:
            r = s.get('https://www.reactome.org/download/current/NCBI2Reactome.txt')
            r.encoding ="utf-8"
            tab_file = csv.reader(r.content.splitlines(), delimiter='\t')

        dico_nodes = {}
        geneid_index=0
        pathway_description_index=3
        species_index=5
        for line in tab_file :
            if line[species_index]==species_dict[species]:
                #Fill dictionary with pathways
                if line[geneid_index] in dico_nodes :
                    dico_nodes[line[geneid_index]].append(line[pathway_description_index])
                else :
                    dico_nodes[line[geneid_index]] = [line[pathway_description_index]]

        dico={}
        dico['network']=dico_network
        dico['nodes']=dico_nodes
        dico['gene_name']=dico_geneid_to_gene_name

    #writing output
    output_file = species+'_'+interactome+'_'+ time.strftime("%d-%m-%Y") + ".json"
    path = os.path.join(target_directory,output_file)
    name = species+" ("+species_dict[species]+") "+time.strftime("%d/%m/%Y")
    id = species+"_"+interactome+"_"+ time.strftime("%d-%m-%Y")

    with open(path, 'w') as handle:
        json.dump(dico, handle, sort_keys=True)

    data_table_entry = dict(id=id, name = name, value = species, path = path)
    _add_data_table_entry(data_manager_dict, data_table_entry, "proteore_"+interactome+"_dictionaries")


#######################################################################################################
# Main function
#######################################################################################################
def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--hpa", metavar = ("HPA_OPTION"))
    parser.add_argument("--peptideatlas", metavar=("SAMPLE_CATEGORY_ID"))
    parser.add_argument("--id_mapping", metavar = ("ID_MAPPING_SPECIES"))
    parser.add_argument("--interactome", metavar = ("PPI"))
    parser.add_argument("--species")
    parser.add_argument("--date")
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
        date = args.date
    except NameError:
        peptide_atlas = None
    if peptide_atlas is not None:
        #target_directory = "/projet/galaxydev/galaxy/tools/proteore/ProteoRE/tools/resources_building/test-data/"
        peptide_atlas = peptide_atlas.split(",")
        for pa_tissue in peptide_atlas:
            peptide_atlas_sources(data_manager_dict, pa_tissue, date, target_directory)

    ## Download ID_mapping source file from Uniprot
    try:
        id_mapping=args.id_mapping
    except NameError:
        id_mapping = None
    if id_mapping is not None:
        id_mapping = id_mapping .split(",")
        for species in id_mapping :
            id_mapping_sources(data_manager_dict, species, target_directory)

    ## Download PPI ref files from biogrid/bioplex/humap
    try:
        interactome=args.interactome
        if interactome == "biogrid" :
            species=args.species
        else :
            species="Human"
    except NameError:
        interactome=None
        species=None
    if interactome is not None and species is not None:
        PPI_ref_files(data_manager_dict, species, interactome, target_directory)
 
    #save info to json file
    filename = args.output
    open(filename, 'wb').write(to_json_string(data_manager_dict))

if __name__ == "__main__":
    main()
