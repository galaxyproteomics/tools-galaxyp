#!/home/dchristiany/miniconda3/bin/python
import csv, json

with open("/home/dchristiany/proteore_project/ProteoRE/tools/Build_protein_interaction_maps/test-data/BIOGRID-ORGANISM-Rattus_norvegicus-3.5.167.tab2.txt","r") as handle :
    tab_file = csv.reader(handle,delimiter="\t")
    dico_network = {}
    GeneID_index=1
    network_cols=[1,2,7,8,11,12,18,20]
    for line in tab_file : 
        dico_network[line[GeneID_index]]=[line[i] for i in network_cols]

with open("/home/dchristiany/proteore_project/ProteoRE/tools/Build_protein_interaction_maps/test-data/NCBI2Reactome.txt","r") as handle :
    tab_file = csv.reader(handle,delimiter="\t")
    dico_nodes = {}
    GeneID_index=0
    pathway_description_index=3
    species_index=5
    for line in tab_file :
        if line[species_index]=="Homo sapiens":
            if line[GeneID_index] in dico_nodes :
                dico_nodes[line[GeneID_index]].append(line[pathway_description_index])
            else :
                dico_nodes[line[GeneID_index]] = [line[pathway_description_index]]

dico={}
dico['network']=dico_network
dico['nodes']=dico_nodes

with open('rat_biogrid_dict.json', 'w') as handle:
    json.dump(dico, handle, sort_keys=True)