# -*- coding: utf-8 -*-
"""
The purpose of this script is to create source files from different databases to be used in other proteore tools
"""

import os, shutil, sys, argparse, requests, time, csv, re, json, shutil, zipfile, subprocess
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
        table = "proteore_protein_atlas_normal_tissue"
    elif tissue == "HPA_pathology":
        tissue_name = "HPA pathology"
        url = "https://www.proteinatlas.org/download/pathology.tsv.zip"
        table = "proteore_protein_atlas_tumor_tissue"
    elif tissue == "HPA_full_atlas":
        tissue_name = "HPA full atlas"
        url = "https://www.proteinatlas.org/download/proteinatlas.tsv.zip"
        table = "proteore_protein_full_atlas"
    elif tissue == "HPA_RNA_tissue":
        tissue_name = "HPA RNA tissue"
        url = "https://www.proteinatlas.org/download/rna_tissue_consensus.tsv.zip"
        table = "proteore_protein_atlas_rna_tissue"
    
    output_file = tissue +"_"+ time.strftime("%d-%m-%Y") + ".tsv"
    path = os.path.join(target_directory, output_file)
    unzip(url, path)    #download and save file
    tissue_name = tissue_name + " " + time.strftime("%d/%m/%Y")
    release = tissue_name.replace(" ","_").replace("/","-")
    id = str(10000000000 - int(time.strftime("%Y%m%d")))


    data_table_entry = dict(id=id, release=release, name = tissue_name, tissue = tissue, value = path)
    _add_data_table_entry(data_manager_dict, data_table_entry, table)


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
    entrez_pattern = re.compile("[0-9]+|[A-Z]{1,2}_[0-9]+|[A-Z]{1,2}_[A-Z]{1,4}[0-9]+")
    if entrez_pattern.match(id) :
        return True
    else :
        return False

#######################################################################################################
# 3. ID mapping file
#######################################################################################################
import ftplib,  gzip
from io import StringIO
csv.field_size_limit(sys.maxsize) # to handle big files

def id_mapping_sources (data_manager_dict, species, target_directory, tool_data_path) :

    human = species == "Human"
    species_dict = { "Human" : "HUMAN_9606", "Mouse" : "MOUSE_10090", "Rat" : "RAT_10116" }
    files=["idmapping_selected.tab.gz","idmapping.dat.gz"]
    archive = os.path.join(tool_data_path, "id_mapping/ID_mapping_archive_"+species+"_"+str(time.strftime("%Y%m%d")))
    if os.path.isdir(archive) is False : os.mkdir(archive)

    #header
    if human : tab = [["UniProt-AC","UniProt-AC_reviewed","UniProt-ID","GeneID","RefSeq","GI","PDB","GO","PIR","MIM","UniGene","Ensembl_Gene","Ensembl_Transcript","Ensembl_Protein","neXtProt","BioGrid","STRING","KEGG",'Gene_Name']]
    else : tab = [["UniProt-AC","UniProt-AC_reviewed","UniProt-ID","GeneID","RefSeq","GI","PDB","GO","PIR","MIM","UniGene","Ensembl_Gene","Ensembl_Transcript","Ensembl_Protein","BioGrid","STRING","KEGG",'Gene_Name']]

    #get selected.tab and keep only ids of interest
    selected_tab_file=species_dict[species]+"_"+files[0]
    tab_path = download_from_uniprot_ftp(selected_tab_file,target_directory)
    with gzip.open(tab_path,"rt") as select :
        tab_reader = csv.reader(select,delimiter="\t")
        for line in tab_reader :
            tab.append([line[0]]+[line[i] for i in [0,1,2,3,4,5,6,11,13,14,18,19,20]])
    if os.path.exists(os.path.join(archive,tab_path.split("/")[-1])) : os.remove(os.path.join(archive,tab_path.split("/")[-1]))
    shutil.move(tab_path, archive)
    #print("selected_tab ok")

    #get uniprot-AC reviewed
    organism = species_dict[species].split("_")[1]
    query = "https://www.uniprot.org/uniprot/?query=reviewed:yes+AND+organism:"+organism+"&format=list"

    with requests.Session() as s:
        download = s.get(query)
        decoded_content = download.content.decode('utf-8')
        uniprot_reviewed_list = decoded_content.splitlines()

    #save reviewed list
    reviewed_list_path = os.path.join(archive,'uniprot_reviewed_list.txt')
    with open(reviewed_list_path,'w') as reviewed_list_file:
        for id in uniprot_reviewed_list:
            reviewed_list_file.write(id+"\n")

    #remove unreviewed uniprot-AC
    for line in tab[1:]:
        UniProtAC = line[1]
        if UniProtAC not in uniprot_reviewed_list :
            line[1]=""

    """
    Supplementary ID to get from HUMAN_9606_idmapping.dat :
    -NextProt,BioGrid,STRING,KEGG
    """

    #there's more id type for human
    if human : ids = ['neXtProt','BioGrid','STRING','KEGG','Gene_Name' ]   #ids to get from dat_file
    else : ids = ['BioGrid','STRING','KEGG','Gene_Name' ]
    unidict = {}

    #keep only ids of interest in dictionaries
    dat_file = species_dict[species]+"_"+files[1]
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
    if os.path.exists(os.path.join(archive,dat_path.split("/")[-1])) : os.remove(os.path.join(archive,dat_path.split("/")[-1]))
    shutil.move(dat_path, archive)

    #print("dat_file ok")

    #add ids from idmapping.dat to the final tab
    for line in tab[1:] :
        uniprotID=line[0]
        if human :
            if uniprotID in unidict :
                nextprot = access_dictionary(unidict,uniprotID,'neXtProt')
                if nextprot != '' : nextprot = clean_nextprot_id(nextprot,line[0])
                line.extend([nextprot,access_dictionary(unidict,uniprotID,'BioGrid'),access_dictionary(unidict,uniprotID,'STRING'),
                        access_dictionary(unidict,uniprotID,'KEGG'),access_dictionary(unidict,uniprotID,'Gene_Name')])
            else :
                line.extend(["","","","",""])
        else :
            if uniprotID in unidict :
                line.extend([access_dictionary(unidict,uniprotID,'BioGrid'),access_dictionary(unidict,uniprotID,'STRING'),
                        access_dictionary(unidict,uniprotID,'KEGG'),access_dictionary(unidict,uniprotID,'Gene_Name')])
            else :
                line.extend(["","","",""])

    #print ("tab ok")

    #add missing nextprot ID for human or replace old ones
    if human : 
        #build next_dict
        nextprot_path = download_from_nextprot_ftp("nextprot_ac_list_all.txt",target_directory)
        with open(nextprot_path,'r') as nextprot_ids :
            nextprot_ids = nextprot_ids.read().splitlines()
        if os.path.exists(os.path.join(archive,nextprot_path.split("/")[-1])) : os.remove(os.path.join(archive,nextprot_path.split("/")[-1]))
        shutil.move(nextprot_path,archive)
        next_dict = {}
        for nextid in nextprot_ids : 
            next_dict[nextid.replace("NX_","")] = nextid
        #os.remove(os.path.join(target_directory,"nextprot_ac_list_all.txt"))

        #add missing nextprot ID
        for line in tab[1:] : 
            uniprotID=line[0]
            nextprotID=line[14]
            if uniprotID in next_dict and (nextprotID == '' or (nextprotID != "NX_"+uniprotID and next_dict[uniprotID] == "NX_"+uniprotID)) :
                line[14]=next_dict[uniprotID]

    output_file = species+"_id_mapping_"+ time.strftime("%d-%m-%Y") + ".tsv"
    path = os.path.join(target_directory,output_file)

    with open(path,"w") as out :
        w = csv.writer(out,delimiter='\t')
        w.writerows(tab)
    
    subprocess.call(['tar', '-czvf', archive+".tar.gz", archive])
    shutil.rmtree(archive, ignore_errors=True)

    name_dict={"Human" : "Homo sapiens", "Mouse" : "Mus musculus", "Rat" : "Rattus norvegicus"}
    name = species +" (" + name_dict[species]+" "+time.strftime("%d/%m/%Y")+")"
    release = species+"_id_mapping_"+ time.strftime("%d-%m-%Y")
    id = str(10000000000 - int(time.strftime("%Y%m%d")))    #new ids must be inferior to previous id -> sort by <filter> in xml only in descending order

    data_table_entry = dict(id=id, release=release , name = name, species = species, value = path)
    _add_data_table_entry(data_manager_dict, data_table_entry, "proteore_id_mapping_"+species)

def download_from_uniprot_ftp(file,target_directory) :
    ftp_dir = "pub/databases/uniprot/current_release/knowledgebase/idmapping/by_organism/"
    path = os.path.join(target_directory, file)
    ftp = ftplib.FTP("ftp.uniprot.org")
    ftp.login("anonymous", "anonymous") 
    ftp.cwd(ftp_dir)
    ftp.retrbinary("RETR " + file, open(path, 'wb').write)
    ftp.quit()
    return (path)

def download_from_nextprot_ftp(file,target_directory) :
    ftp_dir = "pub/current_release/ac_lists/"
    path = os.path.join(target_directory, file)
    ftp = ftplib.FTP("ftp.nextprot.org")
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

def get_interactant_name(line,dico):

    if line[0] in dico :
        interactant_A = dico[line[0]]
    else :
        interactant_A = "NA"

    if line[1] in dico :
        interactant_B = dico[line[1]]
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
        dico_protein_name={}
        for line in humap_nodes :
            if check_entrez_geneid(line[4]):
                if line[4] not in dico_geneid_to_gene_name:
                    dico_geneid_to_gene_name[line[4]]=line[3]
                if line[4] not in dico_protein_name:
                    dico_protein_name[line[4]]=line[5]
            
        with requests.Session() as s:
            r = s.get('http://proteincomplexes.org/static/downloads/pairsWprob.txt')
            r = r.content.decode('utf-8')
            humap = csv.reader(r.splitlines(), delimiter='\t')

        dico_network = {}
        for line in humap :
            if check_entrez_geneid(line[0]) and check_entrez_geneid(line[1]):

                interactant_A, interactant_B = get_interactant_name(line,dico_geneid_to_gene_name)

                #first interactant (first column)
                if line[0] not in dico_network:
                    dico_network[line[0]]=[line[:2]+[interactant_A,interactant_B,line[2]]]
                else :
                    dico_network[line[0]].append(line[:2]+[interactant_A,interactant_B,line[2]])

                #second interactant (second column)
                if line[1] not in dico_network:
                    dico_network[line[1]]=[[line[1],line[0],interactant_B,interactant_A,line[2]]]
                else :
                    dico_network[line[1]].append([line[1],line[0],interactant_B,interactant_A,line[2]])

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
        dico['protein_name']=dico_protein_name

    #writing output
    output_file = species+'_'+interactome+'_'+ time.strftime("%Y-%m-%d") + ".json"
    path = os.path.join(target_directory,output_file)
    name = species+" ("+species_dict[species]+") "+time.strftime("%d/%m/%Y")
    release = species+"_"+interactome+"_"+ time.strftime("%Y-%m-%d")
    id = str(10000000000 - int(time.strftime("%Y%m%d")))

    with open(path, 'w') as handle:
        json.dump(dico, handle, sort_keys=True)

    data_table_entry = dict(id=id, release=release, name = name, species = species, value = path)
    _add_data_table_entry(data_manager_dict, data_table_entry, "proteore_"+interactome+"_dictionaries")

#######################################################################################################
# 5. nextprot (add protein features)
#######################################################################################################

def Build_nextprot_ref_file(data_manager_dict,target_directory):
    nextprot_ids_file = "nextprot_ac_list_all.txt"
    ids = id_list_from_nextprot_ftp(nextprot_ids_file,target_directory)
    
    output_file = 'nextprot_ref_'+ time.strftime("%d-%m-%Y") + ".tsv"
    path = os.path.join(target_directory,output_file)
    name = "neXtProt release "+time.strftime("%d-%m-%Y")
    release_id = "nextprot_ref_"+time.strftime("%d-%m-%Y")
    
    output = open('test.csv', 'w')
    writer = csv.writer(output,delimiter="\t")
        
    nextprot_file=[["NextprotID","MW","SeqLength","IsoPoint","Chr","SubcellLocations","Diseases","TMDomains","ProteinExistence","ProteinName","Function","PostTranslationalModifications","ProteinFamily","Pathway"]]
    writer.writerows(nextprot_file)
    
    for id in ids :
        query="https://api.nextprot.org/entry/"+id+".json"
        try:
            resp = requests.get(url=query)
        except :
            print ("waiting 10 minutes before trying again")
            time.sleep(600)
            resp = requests.get(url=query)
        data = resp.json()

        #get info from json dictionary
        mass_mol = data["entry"]["isoforms"][0]["massAsString"]
        seq_length = data['entry']["isoforms"][0]["sequenceLength"]
        iso_elec_point = data['entry']["isoforms"][0]["isoelectricPointAsString"]
        chr_loc = data['entry']["chromosomalLocations"][0]["chromosome"]        
        protein_existence = "PE"+str(data['entry']["overview"]['proteinExistence']['level'])
        protein_name = data['entry']["overview"]['proteinNames'][0]['name']

        #get families description
        if 'families' in data['entry']["overview"] and len(data['entry']["overview"]['families']) > 0:
            families = data['entry']["overview"]['families']
            families = [entry['description'] for entry in families]
            protein_family = ";".join(families)
        else: 
            protein_family = 'NA'

        #get Protein function
        if 'function-info' in data['entry']['annotationsByCategory'].keys():
            function_info = data['entry']['annotationsByCategory']['function-info']
            function_info = [entry['description'] for entry in function_info if entry['qualityQualifier'] == 'GOLD']
            function = ';'.join(function_info)
        else : 
            function = 'NA'

        #Get ptm-info
        post_trans_mod = 'NA'
        if 'ptm-info' in data['entry']['annotationsByCategory'].keys():
            ptm_info = data['entry']['annotationsByCategory']['ptm-info']
            infos = [entry['description'] for entry in ptm_info if entry['qualityQualifier'] == 'GOLD']
            post_trans_mod = ";".join(infos)
        
        #Get pathway(s)
        if 'pathway' in data['entry']['annotationsByCategory'].keys():
            pathways = data['entry']['annotationsByCategory']['pathway']
            pathways = [entry['description'] for entry in pathways if entry['qualityQualifier'] == 'GOLD']
            pathway = ";".join(pathways)
        else : 
            pathway = 'NA'

        #put all subcell loc in a set
        if "subcellular-location" in data['entry']["annotationsByCategory"].keys() :
            subcell_locs = data['entry']["annotationsByCategory"]["subcellular-location"]
            all_subcell_locs = set()
            for loc in subcell_locs :
                all_subcell_locs.add(loc['cvTermName'])
            all_subcell_locs.discard("")
            all_subcell_locs = ";".join(all_subcell_locs)
        else :
            all_subcell_locs = "NA"
        
        #put all subcell loc in a set
        if ('disease') in data['entry']['annotationsByCategory'].keys() :
            diseases = data['entry']['annotationsByCategory']['disease']
            all_diseases = set()
            for disease in diseases :
                if (disease['cvTermName'] is not None and disease['cvTermName'] != ""):
                    all_diseases.add(disease['cvTermName'])
            if len(all_diseases) > 0 : all_diseases = ";".join(all_diseases)
            else : all_diseases="NA"
        else :
            all_diseases="NA"

        #get all tm domain 
        nb_domains = 0
        if  "transmembrane-region" in data['entry']['annotationsByCategory'].keys():
            tm_domains = data['entry']['annotationsByCategory']["transmembrane-region"]
            all_tm_domains = set()
            for tm in tm_domains :
                all_tm_domains.add(tm['cvTermName'])
                nb_domains+=1
                #print "nb domains ++"
                #print (nb_domains)

        nextprot_file[:] = [] 
        nextprot_file.append([id,mass_mol,str(seq_length),iso_elec_point,chr_loc,all_subcell_locs,all_diseases,str(nb_domains),protein_existence,protein_name,function,post_trans_mod,protein_family,pathway])
        writer.writerows(nextprot_file)

    id = str(10000000000 - int(time.strftime("%Y%m%d")))

    data_table_entry = dict(id=id, release=release_id, name = name, value = path)
    _add_data_table_entry(data_manager_dict, data_table_entry, "proteore_nextprot_ref")

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
    parser.add_argument("--database")
    parser.add_argument("--tool_data_path")
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
        id_mapping = args.id_mapping
    except NameError:
        id_mapping = None
    if id_mapping is not None:
        id_mapping = id_mapping .split(",")
        for species in id_mapping :
            id_mapping_sources(data_manager_dict, species, target_directory, args.tool_data_path)

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

    ## Build nextprot ref file for add protein features
    try:
        database=args.database
    except NameError:
        database=None
    if database is not None :
        Build_nextprot_ref_file(data_manager_dict,target_directory)

    #save info to json file
    filename = args.output
    open(filename, 'wb').write(to_json_string(data_manager_dict))

if __name__ == "__main__":
    main()
