#!/home/dchristiany/miniconda3/bin/python
import csv, json

with open("/home/dchristiany/proteore_project/ProteoRE/tools/Build_protein_interaction_maps/test-data/BioPlex_interactionList_v4a.tsv") as handle :
    bioplex = csv.reader(handle,delimiter="\t") 
    dico_network = {}
    dico_network["GeneID"]={}
    network_geneid_cols=[0,1,4,5,8]
    dico_network["UniProt-AC"]={}
    network_uniprot_cols=[2,3,4,5,8]
    dico_nodes = {}
    for line in bioplex :
        dico_network["GeneID"][line[0]]=[line[i] for i in network_geneid_cols]
        dico_network["UniProt-AC"][line[2]]=[line[i] for i in network_uniprot_cols]

with open('human_bioplex_network_dict.json', 'w') as handle:
    json.dump(dico_network, handle, sort_keys=True)
