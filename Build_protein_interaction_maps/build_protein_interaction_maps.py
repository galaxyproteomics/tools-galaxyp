import csv, json, argparse, re

def get_args() :
    parser = argparse.ArgumentParser()
    parser.add_argument("--database", help="Humap, Bioplex or Biogrid", required=True)
    parser.add_argument("--dict_path", required=True)
    parser.add_argument("--input_type", help="type of input (list of id or filename)",required=True)
    parser.add_argument("--input", required=True)
    parser.add_argument("--header")
    parser.add_argument("--ncol")
    parser.add_argument("--id_type")
    parser.add_argument("--network_output")
    parser.add_argument("--nodes_output")
    parser.add_argument("--pathway_info")
    args = parser.parse_args()

    args.pathway_info=str2bool(args.pathway_info)
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
                    ids_list.appen(id)
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

def biogrid_output_files(ids) :
    network_file=[["Entrez Gene Interactor A","Entrez Gene Interactor B","Gene symbol Interactor A","Gene symbol Interactor B","Experimental System","Experimental Type","Interaction Score","Phenotypes"]]
    ids_set= set(ids)
    ids_not_found=set([])
    for id in ids :
        if id in ppi_dict['network'] :
            network_file.append(ppi_dict['network'][id])
            ids_set.add(ppi_dict['network'][id][1])
        else : 
            ids_not_found.add(id)
    
    nodes_file = [["Protein","Present in user input ids","Present in interactome","Pathway"]]
    for id in ids_set:
        if id in ppi_dict['nodes']:
            description_pathway=";".join(ppi_dict['nodes'][id])
        else :
            description_pathway="NA"

        nodes_file.append([id]+[id in ids]+[id not in ids_not_found]+[description_pathway])   
    
    return network_file,nodes_file

def bioplex_output_files(ids,id_type) :
    network_file=[[id_type+" Interactor A",id_type+" Interactor B","Gene symbol Interactor A","Gene symbol Interactor B","Interaction Score"]]
    ids_set= set(ids)
    ids_not_found=set([])
    for id in ids :
        if id in ppi_dict['network'][id_type] :
            network_file.append(ppi_dict['network'][id_type][id])
            ids_set.add(ppi_dict['network'][id_type][id][1])
        else :
            ids_not_found.add(id)
    #print(network_file)
    #print(ids_not_found)

    if args.pathway_info: nodes_file=[["Protein","Present in user input ids","Present in interactome","Pathway"]]
    else: nodes_file=[["Protein","Present in user input ids","Present in interactome"]]
    for id in ids_set:
        if args.pathway_info:
            if id in ppi_dict['nodes']:
                description_pathway=";".join(ppi_dict['nodes'][id])
            else :
                description_pathway="NA"
            nodes_file.append([id]+[id in ids]+[id not in ids_not_found]+[description_pathway]) 
        else:
            nodes_file.append([id]+[id in ids]+[id not in ids_not_found])   
    
    return network_file,nodes_file

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
        network_file, nodes_file = biogrid_output_files(ids)
    elif args.database=="bioplex":
        network_file, nodes_file = bioplex_output_files(ids,args.id_type)

    #convert blank to NA
    network_file = blank_to_NA(network_file)

    #write output files
    with open(args.network_output,"w") as output :
        writer = csv.writer(output,delimiter="\t")
        writer.writerows(network_file)

    with open(args.nodes_output,"w") as output :
        writer = csv.writer(output,delimiter="\t")
        writer.writerows(nodes_file)

if __name__ == "__main__":
    main()