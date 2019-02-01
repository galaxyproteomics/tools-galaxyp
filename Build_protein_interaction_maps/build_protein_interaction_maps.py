# -*- coding: utf-8 -*-
import csv, json, argparse, re

def get_args() :
    parser = argparse.ArgumentParser()
    parser.add_argument("--species")
    parser.add_argument("--database", help="Humap, Bioplex or Biogrid", required=True)
    parser.add_argument("--dict_path", required=True)
    parser.add_argument("--input_type", help="type of input (list of id or filename)",required=True)
    parser.add_argument("--input", required=True)
    parser.add_argument("--header")
    parser.add_argument("--ncol")
    parser.add_argument("--id_type")
    parser.add_argument("--network_output")
    parser.add_argument("--nodes_output")
    args = parser.parse_args()

    if args.input_type=="file" :
        args.ncol = nb_col_to_int(args.ncol)
        args.header = str2bool(args.header)

    return args

#Turn string into boolean
def str2bool(v):
    if v.lower() in ('yes', 'true', 't', 'y', '1'):
        return True
    elif v.lower() in ('no', 'false', 'f', 'n', '0'):
        return False
    else:
        raise argparse.ArgumentTypeError('Boolean value expected.')

#return the column number in int format
def nb_col_to_int(nb_col):
    try :
        nb_col = int(nb_col.replace("c", "")) - 1
        return nb_col
    except :
        sys.exit("Please specify the column where you would like to apply the filter with valid format")

#return list of (unique) ids from string
def get_input_ids_from_string(input) :
    ids_list = list(set(re.split(r'\s+',input.replace("\r","").replace("\n"," ").replace("\t"," "))))
    if "" in ids_list : ids_list.remove("")
    #if "NA" in ids_list : ids_list.remove("NA")
    return ids_list

#return input_file and list of unique ids from input file path
def get_input_ids_from_file(input,nb_col,header) :
    with open(input, "r") as csv_file :
        input_file= list(csv.reader(csv_file, delimiter='\t'))

    input_file, ids_list = one_id_one_line(input_file,nb_col,header)
    if "" in ids_list : ids_list.remove("")
    #if "NA" in ids_list : ids_list.remove("NA")

    return input_file, ids_list

#return input file by adding lines when there are more than one id per line
def one_id_one_line(input_file,nb_col,header) :

    if header : 
        new_file = [input_file[0]]
        input_file = input_file[1:]
    else : 
        new_file=[]
    ids_list=[]

    for line in input_file :
        if line != [] and set(line) != {''}: 
            line[nb_col] = re.sub(r"\s+","",line[nb_col])
            if ";" in line[nb_col] :
                ids = line[nb_col].split(";")
                for id in ids :
                    new_file.append(line[:nb_col]+[id]+line[nb_col+1:])
                    ids_list.append(id)
            else : 
                new_file.append(line)
                ids_list.append(line[nb_col])

    ids_list= list(set(ids_list))

    return new_file, ids_list

#replace all blank cells to NA
def blank_to_NA(csv_file) :
    tmp=[]
    for line in csv_file :
        line = ["NA" if cell=="" or cell==" " or cell=="NaN" or cell=="-" else cell for cell in line]
        tmp.append(line)
    
    return tmp

def biogrid_output_files(ids,species) :
    network_file=[["Entrez Gene Interactor A","Entrez Gene Interactor B","Gene symbol Interactor A","Gene symbol Interactor B","Experimental System","Experimental Type","Pubmed ID","Interaction Score","Phenotypes"]]
    ids_set= set(ids)
    ids_not_found=set([])
    for id in ids :
        if id in ppi_dict['network'] :
            network_file.extend(ppi_dict['network'][id])
            ids_set.update([interact[1] for interact in ppi_dict['network'][id]])
        else : 
            ids_not_found.add(id)
    
    nodes_file = [["Entrez gene ID","Official Symbol Interactor","Present in user input ids","ID present in Biogrid "+species,"Pathway"]]
    for id in ids_set:
        #get pathway
        if id in ppi_dict['nodes']:
            description_pathway=";".join(ppi_dict['nodes'][id])
        else :
            description_pathway="NA"
        
        #get gene name
        if id in ppi_dict['gene_name']:
            gene_name = ppi_dict['gene_name'][id]
        else : 
            gene_name = "NA"

        #make line
        nodes_file.append([id]+[gene_name]+[id in ids]+[id not in ids_not_found]+[description_pathway])   
    
    return network_file,nodes_file

def bioplex_output_files(ids,id_type,species) :
    network_file=[[id_type+" Interactor A",id_type+" Interactor B","Gene symbol Interactor A","Gene symbol Interactor B","Interaction Score"]]
    ids_set= set(ids)
    ids_not_found=set([])
    for id in ids :
        if id in ppi_dict['network'][id_type] :
            network_file.extend(ppi_dict['network'][id_type][id])
            ids_set.update([interact[1] for interact in ppi_dict['network'][id_type][id]])
        else :
            ids_not_found.add(id)

    if id_type=="UniProt-AC" : nodes_file=[[id_type,"Present in user input ids","ID present in Bioplex "+species,"Pathway"]]
    else: nodes_file=[[id_type,"Official symbol Interactor","Present in user input ids","Present in interactome","Pathway"]]
    for id in ids_set:

        if id in ppi_dict['nodes'][id_type]:
            description_pathway=";".join(ppi_dict['nodes'][id_type][id])
        else :
            description_pathway="NA"

        #make line
        if id_type=="UniProt-AC":
            nodes_file.append([id]+[id in ids]+[id not in ids_not_found]+[description_pathway])  
        elif id_type=="GeneID":
            #get gene_name
            if id in ppi_dict['network'][id_type]: gene_name = ppi_dict['network'][id_type][id][0][2]
            else : gene_name="NA"
            nodes_file.append([id]+[gene_name]+[id in ids]+[id not in ids_not_found]+[description_pathway])
    
    return network_file,nodes_file

def humap_output_files(ids,species) :
    network_file=[["Entrez Gene Interactor A","Entrez Gene Interactor B","Gene symbol Interactor A","Gene symbol Interactor B","Interaction Score"]]
    ids_set= set(ids)
    ids_not_found=set([])
    for id in ids :
        if id in ppi_dict['network'] :
            network_file.extend(ppi_dict['network'][id])
            ids_set.update([interact[1] for interact in ppi_dict['network'][id]])
        else : 
            ids_not_found.add(id)
    
    nodes_file = [["Entrez gene ID","Official Symbol Interactor","Present in user input ids","ID present in Biogrid "+species,"Pathway"]]
    for id in ids_set:
        if id in ppi_dict['nodes']:
            description_pathway=";".join(ppi_dict['nodes'][id])
        else :
            description_pathway="NA"
        
        #get gene_name
        if id in ppi_dict['network']: gene_name = ppi_dict['network'][id][0][2]
        else : gene_name="NA"

        #make line
        nodes_file.append([id]+[gene_name]+[id in ids]+[id not in ids_not_found]+[description_pathway])   
    
    return network_file,nodes_file

#function to sort the csv_file by value in a specific column
def sort_by_column(tab,sort_col,reverse,header):
    
    if len(tab) > 1 : #if there's more than just a header or 1 row
        if header :
            head=tab[0]
            tab=tab[1:]

        #list of empty cells in the column to sort
        unsortable_lines = [i for i,line in enumerate(tab) if (line[sort_col]=='' or line[sort_col] == 'NA')]
        unsorted_tab=[ tab[i] for i in unsortable_lines]
        tab= [line for i,line in enumerate(tab) if i not in unsortable_lines]

        if only_number(tab,sort_col) and any_float(tab,sort_col)  : 
            tab = sorted(tab, key=lambda row: float(row[sort_col]), reverse=reverse)
        elif only_number(tab,sort_col):
            tab = sorted(tab, key=lambda row: int(row[sort_col]), reverse=reverse)      
        else :
            tab = sorted(tab, key=lambda row: row[sort_col], reverse=reverse)
        
        tab.extend(unsorted_tab)
        if header is True : tab = [head]+tab

    return tab

def only_number(tab,col) :

    for line in tab :
        if not (is_number("float",line[col].replace(",",".")) or is_number("int",line[col].replace(",","."))) :
            return False
    return True

#Check if a variable is a float or an integer
def is_number(number_format, n):
    float_format = re.compile(r"^[-]?[0-9][0-9]*.?[0-9]+$")
    int_format = re.compile(r"^[-]?[0-9][0-9]*$")
    test = ""
    if number_format == "int":
        test = re.match(int_format, n)
    elif number_format == "float":
        test = re.match(float_format, n)
    if test:
        return True

#return True is there is at least one float in the column
def any_float(tab,col) :
    
    for line in tab :
        if is_number("float",line[col].replace(",",".")) :
            return True

    return False

def main() :

    #Get args from command line
    global args
    args = get_args()

    #get PPI dictionary
    with open(args.dict_path, 'r') as handle:
        global ppi_dict
        ppi_dict = json.load(handle)

    #Get file and/or ids from input 
    if args.input_type == "text" :
        ids = get_input_ids_from_string(args.input)
    elif args.input_type == "file" :
        input_file, ids = get_input_ids_from_file(args.input,args.ncol,args.header)

    #create output files
    if args.database=="biogrid":
        network_file, nodes_file = biogrid_output_files(ids,args.species)
    elif args.database=="bioplex":
        network_file, nodes_file = bioplex_output_files(ids,args.id_type,args.species)
    elif args.database=="humap":
        network_file, nodes_file = humap_output_files(ids,args.species)

    #convert blank to NA and sort files
    network_file = blank_to_NA(network_file)
    network_file = sort_by_column(network_file,0,False,True)
    nodes_file = sort_by_column(nodes_file,0,False,True)

    #write output files
    with open(args.network_output,"w") as output :
        writer = csv.writer(output,delimiter="\t")
        writer.writerows(network_file)

    with open(args.nodes_output,"w") as output :
        writer = csv.writer(output,delimiter="\t")
        for row in nodes_file:
            writer.writerow([unicode(s).encode("utf-8") for s in row])

if __name__ == "__main__":
    main()