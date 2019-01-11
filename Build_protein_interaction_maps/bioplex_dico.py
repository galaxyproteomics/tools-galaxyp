#!/home/dchristiany/miniconda3/bin/python
import csv, json

with open("/home/dchristiany/proteore_project/ProteoRE/tools/Build_protein_interaction_maps/test-data/BioPlex_interactionList_v4a.tsv") as handle :
    bioplex = csv.reader(handle,delimiter="\t") 
    dico_network = {}
    dico_network["GeneID"]={}
    network_geneid_cols=[0,1,4,5,8]
    dico_network["UniProt-AC"]={}
    network_uniprot_cols=[2,3,4,5,8]
    dico_GeneID_to_UniProt = {}
    dico_nodes = {}
    for line in bioplex :
        dico_network["GeneID"][line[0]]=[line[i] for i in network_geneid_cols]
        dico_network["UniProt-AC"][line[2]]=[line[i] for i in network_uniprot_cols]
        dico_GeneID_to_UniProt[line[0]]=line[2]

with open("/home/dchristiany/proteore_project/ProteoRE/tools/Build_protein_interaction_maps/test-data/UniProt2Reactome.txt","r") as handle :
    tab_file = csv.reader(handle,delimiter="\t")
    dico_nodes = {}
    uniProt_index=0
    pathway_description_index=3
    species_index=5
    for line in tab_file :
        if line[species_index]=="Mus musculus":
            if line[uniProt_index] in dico_nodes :
                dico_nodes[line[uniProt_index]].append(line[pathway_description_index])
            else :
                dico_nodes[line[uniProt_index]] = [line[pathway_description_index]]


for id in dico_nodes:
    print(id,dico_nodes[id])

dico={}
dico['network']=dico_network
dico['nodes']=dico_nodes
dico['convert']=dico_GeneID_to_UniProt

with open('mouse_bioplex_dict.json', 'w') as handle:
    json.dump(dico, handle, sort_keys=True)
