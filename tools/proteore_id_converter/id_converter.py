import argparse
import csv
import itertools
import sys
import os  # noqa 401
import re


def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("-d", "--ref_file", help="path to reference file: <species>_id_mapping.tsv", required=True)  # noqa 501
    parser.add_argument("--input_type",
                        help="type of input (list of id or filename)",
                        required=True)
    parser.add_argument("-t", "--id_type", help="type of input IDs",
                        required=True)
    parser.add_argument("-i", "--input", help="list of IDs (text or filename)",
                        required=True)
    parser.add_argument("-c", "--column_number",
                        help="list of IDs (text or filename)")
    parser.add_argument("--header",
                        help="true/false if your file contains a header")
    parser.add_argument("--target_ids",
                        help="target IDs to map to", required=True)
    parser.add_argument("-o", "--output",
                        help="output filename", required=True)
    args = parser.parse_args()
    return args

# return list of (unique) ids from string


def get_input_ids_from_string(input):
    ids_list = list(set(re.split(r'\s+', input.replace("\r", "").replace("\n", " ").replace("\t", " "))))  # noqa 501
    if "" in ids_list:
        ids_list.remove("")
    # if "NA" in ids_list : ids_list.remove("NA")
    return ids_list

# return input_file and list of unique ids from input file path


def get_input_ids_from_file(input, nb_col, header):
    with open(input, "r") as csv_file:
        input_file = list(csv.reader(csv_file, delimiter='\t'))

    input_file, ids_list = one_id_one_line(input_file, nb_col, header)
    if "" in ids_list:
        ids_list.remove("")
    # if "NA" in ids_list : ids_list.remove("NA")

    return input_file, ids_list

# return input file by adding lines when there are more than one id per line


def one_id_one_line(input_file, nb_col, header):

    if header:
        new_file = [input_file[0]]
        input_file = input_file[1:]
    else:
        new_file = []
    ids_list = []

    for line in input_file:
        if line != [] and set(line) != {''}:
            line[nb_col] = re.sub(r"\s+", "", line[nb_col])
            if line[nb_col] == "":
                line[nb_col] = 'NA'
            if ";" in line[nb_col]:
                ids = line[nb_col].split(";")
                for id in ids:
                    new_file.append(line[:nb_col] + [id] + line[nb_col + 1:])
                    ids_list.append(id)
            else:
                new_file.append(line)
                ids_list.append(line[nb_col])

    ids_list = list(set(ids_list))

    return new_file, ids_list

# not used


def output_one_id_one_line(line, convert_ids, target_ids):

    # ids_not_processed = ["GI","PDB","GO","PIR","MIM","UniGene","BioGrid","STRING"]  # noqa 501
    # ids with multiple ids per line in output file
    ids_not_processed = ["UniProt-AC",
                         "UniProt-AC_reviewed",
                         "UniProt-ID",
                         "GeneID",
                         "RefSeq",
                         "GI",
                         "PDB",
                         "GO",
                         "PIR",
                         "MIM",
                         "UniGene",
                         "Ensembl_Gene",
                         "Ensembl_Transcript",
                         "Ensembl_Protein",
                         "BioGrid",
                         "STRING",
                         "KEGG"]  # All Ids
    ids_not_processed = [id for id in ids_not_processed if id in target_ids]  # noqa 501
    # ids present in target_ids with multiple ids per line in output file

    for id_not_processed in ids_not_processed:
        index = target_ids.index(id_not_processed)
        convert_ids[index] = [";".join(convert_ids[index])]

# getting all possibilities between lists of ids
    res = itertools.product(*convert_ids)
    res = [list(e) for e in res]   # convert to lists
    res = [line + list(ids) for ids in res]   # adding the rest of the line

    return(res)

# return the column number in int format


def nb_col_to_int(nb_col):
    try:
        nb_col = int(nb_col.replace("c", "")) - 1
        return nb_col
    except(sys):
        sys.exit("Please specify the column where you would like to apply the filter with valid format")  # noqa 501

# replace all blank cells to NA


def blank_to_NA(csv_file):
    tmp = []
    for line in csv_file:
        line = ["NA" if cell == "" or cell == " " or cell == "NaN" else cell for cell in line]  # noqa 501
        tmp.append(line)

    return tmp


def str2bool(v):
    if v.lower() in ('yes', 'true', 't', 'y', '1'):
        return True
    elif v.lower() in ('no', 'false', 'f', 'n', '0'):
        return False
    else:
        raise argparse.ArgumentTypeError('Boolean value expected.')

# return result dictionary


def map_to_dictionary(ids, ids_dictionary, id_in, id_out):

    result_dict = {}
    for id in ids:
        for target_id in id_out:
            if id in ids_dictionary:
                res = ids_dictionary[id][target_id]
            else:
                res = ""

            if id in result_dict:
                result_dict[id].append(res)
            else:
                result_dict[id] = [res]

    return result_dict

# create empty dictionary with index for tab


def create_ids_dictionary(ids_list):
    ids_dictionary = {}
    ids_dictionary_index = {}
    for i, id in enumerate(ids_list):
        ids_dictionary_index[i] = id

    return(ids_dictionary, ids_dictionary_index)


def create_header(input_file, ncol, id_type, target_ids):
    col_names = list(range(1, len(input_file[0]) + 1))
    col_names = ["col" + str(e) for e in col_names]
    col_names[ncol] = id_type
    col_names = col_names + target_ids
    return(col_names)


def main():

    # Get args from command line
    args = get_args()
    target_ids = args.target_ids.split(",")
    header = False
    if args.id_type in target_ids:
        target_ids.remove(args.id_type)
    if args.input_type == "file":
        args.column_number = nb_col_to_int(args.column_number)
        header = str2bool(args.header)

    # Get ref file to build dictionary
    csv.field_size_limit(sys.maxsize)  # to handle big files
    with open(args.ref_file, "r") as csv_file:
        tab = csv.reader(csv_file, delimiter='\t')
        tab = [line for line in tab]

    ids_list = tab[0]

    # create empty dictionary and dictionary index
    ids_dictionary, ids_dictionary_index = create_ids_dictionary(ids_list)

    # fill dictionary and sub dictionaries with ids
    id_index = ids_list.index(args.id_type)
    for line in tab[1:]:
        ref_ids = line[id_index]
        other_id_type_index = [accession_id for accession_id in ids_dictionary_index.keys() if accession_id!=id_index]  # noqa 501
        # if there's more than one id, one key per id (example : GO)
        for id in ref_ids.replace(" ", "").split(";"):
            if id not in ids_dictionary:    # if the key is not created yet
                ids_dictionary[id] = {}
            for other_id_type in other_id_type_index:
                if ids_dictionary_index[other_id_type] not in ids_dictionary[id]:  # noqa 501
                    ids_dictionary[id][ids_dictionary_index[other_id_type]] = set(line[other_id_type].replace("NA","").replace(" ","").split(";"))  # noqa 501
                else:
                    ids_dictionary[id][ids_dictionary_index[other_id_type]] |= set(line[other_id_type].replace("NA","").replace(" ","").split(";"))  # noqa 501
                if len(ids_dictionary[id][ids_dictionary_index[other_id_type]]) > 1 and '' in ids_dictionary[id][ids_dictionary_index[other_id_type]]:  # noqa 501 
                    ids_dictionary[id][ids_dictionary_index[other_id_type]].remove('')  # noqa 501

    # Get file and/or ids from input
    if args.input_type == "list":
        ids = get_input_ids_from_string(args.input)
    elif args.input_type == "file":
        input_file, ids = get_input_ids_from_file(args.input,
                                                  args.column_number,
                                                  header)

    # Mapping ids
    result_dict = map_to_dictionary(ids, ids_dictionary,
                                    args.id_type, target_ids)

    # creating output file
    with open(args.output, "w") as output:
        writer = csv.writer(output, delimiter="\t")
        # writer.writerows(output_file)

        # write header
        if header:
            writer.writerow(input_file[0] + target_ids)
            input_file = input_file[1:]
        elif args.input_type == "file":
            col_names = create_header(input_file, args.column_number,
                                      args.id_type, target_ids)
            writer.writerow(col_names)
        else:
            writer.writerow([args.id_type] + target_ids)

        # write lines
        previous_line = ""
        if args.input_type == "file":
            for line in input_file:
                res = [";".join(list(res_ids)) for res_ids in result_dict[line[args.column_number]]]  # noqa 501
                line = ["NA" if cell=="" or cell==" " or cell=="NaN" else cell for cell in line+res]  # noqa 501
                if previous_line != line:
                    writer.writerow(line)
                    previous_line = line
        elif args.input_type == "list":
            for id in ids:
                res = [";".join(list(res_ids)) for res_ids in result_dict[id]]
                line = ["NA" if cell=="" or cell==" " or cell=="NaN" else cell for cell in [id]+res]  # noqa 501
                if previous_line != line:
                    writer.writerow(line)
                    previous_line = line

        # print ("output file created")


if __name__ == "__main__":
    main()
