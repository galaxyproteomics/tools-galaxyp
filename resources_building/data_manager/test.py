#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os, sys, argparse, requests, time, csv, re
from io import BytesIO
from zipfile import ZipFile
from galaxy.util.json import from_json_string, to_json_string
import ftplib, gzip
csv.field_size_limit(sys.maxsize) # to handle big files

def download_from_uniprot_ftp(file,target_directory) :
    ftp_dir = "pub/databases/uniprot/current_release/knowledgebase/idmapping/by_organism/"
    path = os.path.join(target_directory, file)
    #print (path)
    ftp = ftplib.FTP("ftp.uniprot.org")
    ftp.login("anonymous", "anonymous") 
    ftp.cwd(ftp_dir)
    ftp.retrbinary("RETR " + file, open(path, 'wb').write)
    ftp.quit()
    return (path)

def id_list_from_nextprot_ftp(file,target_directory) :
    ftp_dir = "pub/current_release/ac_lists/"
    path = os.path.join(target_directory, file)
    #print (path)
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

species="rat"
target_directory="/home/dchristiany"

human = species == "human"
print ("human",human)
species_dict = { "human" : "HUMAN_9606", "mouse" : "MOUSE_10090", "rat" : "RAT_10116" }
species = species_dict[species]

target_directory="/home/dchristiany"
files=["idmapping_selected.tab.gz","idmapping.dat.gz"]

#header
if human : tab = [["UniProt-AC","UniProt-ID","GeneID","RefSeq","GI","PDB","GO","PIR","MIM","UniGene","Ensembl_Gene","Ensembl_Transcript","Ensembl_Protein","neXtProt","BioGrid","STRING","KEGG"]]
else : tab = [["UniProt-AC","UniProt-ID","GeneID","RefSeq","GI","PDB","GO","PIR","MIM","UniGene","Ensembl_Gene","Ensembl_Transcript","Ensembl_Protein","BioGrid","STRING","KEGG"]]

print("header ok")

#selected.tab and keep only ids of interest
selected_tab_file=species+"_"+files[0]
tab_path = download_from_uniprot_ftp(selected_tab_file,target_directory)
#tab_path = "/home/dchristiany/HUMAN_9606_idmapping_selected.tab.gz"
with gzip.open(tab_path,"rt") as select :
    tab_reader = csv.reader(select,delimiter="\t")
    for line in tab_reader :
        tab.append([line[i] for i in [0,1,2,3,4,5,6,11,13,14,18,19,20]])

print("selected_tab ok")

"""
Supplementary ID to get from HUMAN_9606_idmapping.dat :
-NextProt,BioGrid,STRING,KEGG
"""

if human : ids = ['neXtProt','BioGrid','STRING','KEGG' ]   #ids to get from dat_file
else : ids = ['BioGrid','STRING','KEGG' ]
unidict = {}

#keep only ids of interest in dictionaries
dat_file=species+"_"+files[1]
dat_path = download_from_uniprot_ftp(dat_file,target_directory)
#dat_path="/home/dchristiany/HUMAN_9606_idmapping.dat.gz"
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

print("dat_file ok")

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

#add missing nextprot ID for human
if human : 
    #build next_dict
    nextprot_ids = id_list_from_nextprot_ftp("nextprot_ac_list_all.txt",target_directory)
    next_dict = {}
    for nextid in nextprot_ids : 
        next_dict[nextid.replace("NX_","")] = nextid

    #add missing nextprot ID
    for line in tab[1:] : 
        uniprotID=line[0]
        nextprotID=line[13]
        if nextprotID == '' and uniprotID in next_dict :
            line[13]=next_dict[uniprotID]

path="/home/dchristiany/proteore_project/ProteoRE/tools/resources_building/data_manager/rat.tsv"
with open(path,"w") as out :
    w = csv.writer(out,delimiter='\t')
    w.writerows(tab)