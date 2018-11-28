# Usage : 
# python interactomicsCyJS.py --inputtype copypaste --input Q6ZMN8 Q8N1S5
# P40855 P00813 --column c1 --interactome BioPlex_interactionList_v4a.tsv --jsonoutput output.json
# --taboutput TRUE --interactometype bioplex --addReactome TRUE --reactomeFile
# UniProt2Reactome.txt --header FALSE



import argparse
import numpy as np
import re
import json
import pandas as pd


parser = argparse.ArgumentParser(description="Map a list of uniprot Accession IDs on a given interactome")
parser.add_argument('--inputtype',action='store', dest='inputtype')
parser.add_argument('--input',action='store',dest='input',nargs='*')
parser.add_argument('--column',action='store',dest='column')
parser.add_argument('--interactome',action='store',dest='interactome')
parser.add_argument('--jsonoutput',action='store',dest='jsonfile')
parser.add_argument('--taboutput',action='store',dest='taboutput')
parser.add_argument('--interactometype',action='store',dest='interactometype')
parser.add_argument('--addReactome',action='store',dest='addreactome')
parser.add_argument('--reactomeFile',action='store',dest='reactomefile')
parser.add_argument('--header',action='store',dest='header')

args = parser.parse_args()
# Open the file containing the list of uniprot ids or split the ids given as an
# input 

if args.inputtype=="copypaste":
    inputids = args.input
    inputids = inputids[0].split(" ")
    inputids = pd.DataFrame(inputids)

    inputids = inputids.iloc[:,0]

else:
	
    if args.header=="FALSE":
        inputfile = pd.read_csv(args.input[0],delimiter="\t",header=None)
    else:
        inputfile = pd.read_csv(args.input[0],delimiter="\t")
    column = int(re.sub("c","",args.column))-1
    inputids = pd.DataFrame(inputfile)
    inputids = inputids.iloc[:,column]
# Open the interactome file
interactome = pd.read_csv(args.interactome, delimiter="\t",comment="#")
interactome = pd.DataFrame(interactome)


# function to get the PPIs in the interactome
def getProtPPIs(inputids,interactome,interactometype):
    if interactometype=="bioplex":
        # if the interactome is bioplex then we have to select the columns
        # 3 and 4 for the interactants and column 9 for the scores 
       colstokeep = [2,3,8] # columns in panda dataframe begin at 0 and not 1
       colsnames = ["Protein1","Protein2","Interaction score"]
    if interactometype=="humap":
        colstokeep = [3,4,2]
        colsnames = ["Protein1","Protein2","Interaction score"]

    lines = interactome.iloc[:,colstokeep[0]].isin(inputids)

    ppis1 = interactome.loc[lines,:]
    ppis1 = ppis1.iloc[:,colstokeep] 

    lines = interactome.iloc[:,colstokeep[1]].isin(inputids)

    ppis2 = interactome.loc[lines,:]
    ppis2 = ppis2.iloc[:,colstokeep] 
    
    ppis1.columns = colsnames
    ppis2.columns = colsnames
    
    frames = [ppis1,ppis2]
    ppis = pd.concat(frames)
    return ppis

def getNodesAttributes(inputids,interactome,ppis,interactometype,addReactome,reactomeFile):
    # get all unique interactants from the ppis dataframe created before
    allinteractants = pd.DataFrame(pd.unique(ppis.iloc[:,[0,1]].values.ravel()))
    inputids = pd.DataFrame(inputids)
    # some ids given by the user may not be present in the interactome
    # these ids will be added to the nodes'list dataframe and their respective lines in the column "Found in interactome" will be filled with the FALSE value 
    in_interactome = inputids.iloc[:,0].isin(allinteractants.iloc[:,0]) 
    ids_not_in_interactome = inputids.loc[~in_interactome,:]
 
    if len(ids_not_in_interactome)!=0:
    	ids_not_in_interactome = ids_not_in_interactome.iloc[:,0].tolist() 
    	allinteractants = allinteractants.append(ids_not_in_interactome)

    # get if the ids were originally from the user input
    origins = allinteractants.iloc[:,0].isin(inputids.iloc[:,0])
    # concatenate the two
    data = pd.concat([allinteractants,origins],axis=1)
   

    # add a column TRUE/FALSE to determine if the id was found in the interactome   
    
    found_in_interactome = data.iloc[:,0].isin(pd.unique(ppis.iloc[:,[0,1]].values.ravel())) 
    
    data = pd.concat([data,found_in_interactome],axis=1)
    # rename columns   
    data.columns = ["Protein","From user input","Found in interactome"]

    # add if needed the pathway info 
    if addReactome=="TRUE":
        reactome = pd.read_csv(reactomeFile,header=None, delimiter="\t")
        reactome = pd.DataFrame(reactome)
        lines = reactome.iloc[:,0].isin(data.iloc[:,0])
        reactomedata = reactome.loc[lines.values,:]
        reactomedata = reactomedata.iloc[:,[0,3]]
        reactomedata.columns = ["ProteinR","Pathway"]
        reactomedata = reactomedata.groupby('ProteinR')['Pathway'].apply(list) 
        reactomedata = pd.DataFrame(reactomedata)
        reactomedata['ProteinR']=reactomedata.index  
        # merge data and reactome data with a left join on the Protein column
        data = data.merge(reactomedata,how='left',left_on='Protein',right_on='ProteinR')
        del data['ProteinR']

    
    return data

def getJSON(ppis,nodes_attributes,jsonfile,addReactome):
    
    elements = {}
    nodes = []
    edges = []

    for row in range(len(nodes_attributes.iloc[:,0])):
        if addReactome=="TRUE":
            node = {"data" : {"id" : str(nodes_attributes["Protein"][row]),"from_user_input" : str(nodes_attributes["From user input"][row]), "pathway" : str(nodes_attributes["Pathway"][row])}}
            nodes.append(node)
        else:
            node = {"data" : {"id" : str(nodes_attributes["Protein"][row]),"from_user_input" : str(nodes_attributes["From user input"][row])}}
            nodes.append(node)

    for row in range(len(ppis.iloc[:,0])):
        ident = str(ppis.iloc[row,0])+"_"+str(ppis.iloc[row,1])
        edge = {"data" : {"id" : ident,"source" : str(ppis.iloc[row,0]),"target": str(ppis.iloc[row,1]), "score" : str(ppis.iloc[row,2])}}
        edges.append(edge)

    elements["nodes"] = nodes
    elements["edges"] = edges
    data = {"elements" : elements}
    with open(jsonfile,'w') as outfile:
        json.dump(data,outfile)

ppis = getProtPPIs(inputids,interactome,args.interactometype)
nodes_attributes = getNodesAttributes(inputids,interactome,ppis,args.interactometype,args.addreactome,args.reactomefile)

getJSON(ppis,nodes_attributes,args.jsonfile,args.addreactome)
if args.taboutput=="TRUE":
    nodes_attributes.to_csv("nodes_attributes.csv",sep="\t",index=False,na_rep="Na")
    ppis.to_csv("ppis.csv",sep="\t",index=False,na_rep="Na")

