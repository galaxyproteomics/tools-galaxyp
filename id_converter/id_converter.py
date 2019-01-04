#!/home/dchristiany/miniconda3/bin/python
import pickle, sys, os, argparse, re, csv

def get_args() :
    parser = argparse.ArgumentParser()
    parser.add_argument("-d", "--dict_path", help="path to ids dictionary (dictionary.pickle)", required=True)
    parser.add_argument("--input_type", help="type of input (list of id or filename)", required=True)
    parser.add_argument("-t", "--id_type", help="type of input IDs", required=True)
    parser.add_argument("-i", "--input", help="list of IDs (text or filename)", required=True)
    parser.add_argument("-c", "--column_number", help="list of IDs (text or filename)")
    parser.add_argument("--header", help="true/false if your file contains a header")
    parser.add_argument("--target_ids", help="target IDs to map to", required=True)
    parser.add_argument("-o", "--output", help="output filename", required=True)
    args = parser.parse_args()
    return args

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

#return the column number in int format
def nb_col_to_int(nb_col):
    try :
        nb_col = int(nb_col.replace("c", "")) - 1
        return nb_col
    except :
        sys.exit("Please specify the column where you would like to apply the filter with valid format")

#replace all blank cells to NA
def blank_to_NA(csv_file) :
    tmp=[]
    for line in csv_file :
        line = ["NA" if cell=="" or cell==" " or cell=="NaN" else cell for cell in line]
        tmp.append(line)
    
    return tmp

def str2bool(v):
    if v.lower() in ('yes', 'true', 't', 'y', '1'):
        return True
    elif v.lower() in ('no', 'false', 'f', 'n', '0'):
        return False
    else:
        raise argparse.ArgumentTypeError('Boolean value expected.')

#return result dictionary
def map_to_dictionary(ids,ids_dictionary,id_in,id_out) :
    
    result_dict = {}
    for id in ids : 
        for target_id in id_out :
            if id in ids_dictionary[id_in] :
                res = ";".join(ids_dictionary[id_in][id][target_id])
            else :
                res=""
            
            if id in result_dict :
                result_dict[id].append(res)
            else :
                result_dict[id]=[res]

    return result_dict

def main():
    
    #Get args from command line
    args = get_args()
    target_ids = args.target_ids.split(",")
    header=False
    if args.id_type in target_ids : target_ids.remove(args.id_type)
    if args.input_type=="file" :
        args.column_number = nb_col_to_int(args.column_number)
        header = str2bool(args.header)

    #print(args)

    #get ids dictionary
    with open(args.dict_path, 'rb') as handle:
        ids_dictionary = pickle.load(handle)
    #print(ids_dictionary.keys())

    #Get file and/or ids from input 
    if args.input_type == "list" :
        ids = get_input_ids_from_string(args.input)
    elif args.input_type == "file" :
        input_file, ids = get_input_ids_from_file(args.input,args.column_number,args.header)

    #Mapping ids
    result_dict = map_to_dictionary(ids,ids_dictionary,args.id_type,target_ids)
    #print(result_dict)

    #creating output file 
    if header : 
        output_file=[input_file[0]+target_ids]
        input_file = input_file[1:]
    else :
        output_file=[[args.id_type]+target_ids]

    if args.input_type=="file" :
        for line in input_file :
            output_file.append(line+result_dict[line[args.column_number]])
    elif args.input_type=="list" :
        for id in ids :
            output_file.append([id]+result_dict[id])
    #print (output_file)

    #convert blank to NA
    output_file = blank_to_NA(output_file)

    #write output file 
    with open(args.output,"w") as output :
        writer = csv.writer(output,delimiter="\t")
        writer.writerows(output_file)

if __name__ == "__main__":
    main()

