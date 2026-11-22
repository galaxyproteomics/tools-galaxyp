import argparse
import csv
import gzip
import re


def get_args():

    parser = argparse.ArgumentParser()
    parser.add_argument("--input_type", help="type of input (list of id or filename)", required=True)  # noqa 501
    parser.add_argument("-i", "--input", help="list of IDs (text or filename)", required=True)  # noqa 501
    parser.add_argument("--header", help="true/false if your file contains a header")  # noqa 501
    parser.add_argument("-c", "--column_number", help="list of IDs (text or filename)")  # noqa 501
    parser.add_argument("-f", "--features", help="Protein features to return from SRM Atlas", required=True)  # noqa 501
    parser.add_argument("-d", "--ref_file", help="path to reference file", required=True)  # noqa 501
    parser.add_argument("-o", "--output", help="output filename", required=True)  # noqa 501
    args = parser.parse_args()
    return args

# return the column number in int format


def nb_col_to_int(nb_col):
    try:
        nb_col = int(nb_col.replace("c", "")) - 1
        return nb_col
    except:  # noqa 722
        sys.exit("Please specify the column where you would like to apply the filter with valid format")  # noqa 501, 821

# replace all blank cells to NA


def blank_to_NA(csv_file):
    tmp = []
    for line in csv_file:
        line = ["NA" if cell == "" or cell == " " or cell == "NaN" else cell for cell in line]  # noqa 501
        tmp.append(line)

    return tmp

# convert string to boolean


def str2bool(v):
    if v.lower() in ('yes', 'true', 't', 'y', '1'):
        return True
    elif v.lower() in ('no', 'false', 'f', 'n', '0'):
        return False
    else:
        raise argparse.ArgumentTypeError('Boolean value expected.')

# return list of (unique) ids from string


def get_input_ids_from_string(input):

    ids_list = list(set(re.split(r'\s+', input.replace("_SNP", "").replace("d_", "").replace("\r", "").replace("\n", " ").replace("\t", " "))))  # noqa 501
    if "" in ids_list:
        ids_list.remove("")

    return ids_list

# return input_file and list of unique ids from input file path


def get_input_ids_from_file(input, nb_col, header):
    with open(input, "r") as csv_file:
        input_file = list(csv.reader(csv_file, delimiter='\t'))

    input_file, ids_list = one_id_one_line(input_file, nb_col, header)
    if "" in ids_list:
        ids_list.remove("")

    return input_file, ids_list

# function to check if an id is an uniprot accession number:
# return True or False


def check_uniprot(id):
    uniprot_pattern = re.compile("[OPQ][0-9][A-Z0-9]{3}[0-9]|[A-NR-Z][0-9]([A-Z][A-Z0-9]{2}[0-9]){1,2}")  # noqa 501
    if uniprot_pattern.match(id):
        return True
    else:
        return False

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

    ids_list = [e.replace("_SNP", "").replace("d_", "") for e in ids_list]
    ids_list = list(set(ids_list))

    return new_file, ids_list


def create_srm_atlas_dictionary(features, srm_atlas_csv):

    srm_atlas = {}
    features_index = {"PeptideSeq": 0, "SSRT": 1, "Length": 2, "type":3, "PA_AccNum": 4, "MW": 5}  # noqa 501
    features_to_get = [features_index[feature] for feature in features]
    for line in srm_atlas_csv[1:]:
        id = line[9].replace("_SNP", "").replace("d_", "")
        if id not in srm_atlas:
            srm_atlas[id] = [[line[i] for i in features_to_get]]
        else:
            srm_atlas[id].append([line[i] for i in features_to_get])
    return srm_atlas


def retrieve_srm_features(srm_atlas, ids):

    result_dict = {}
    for id in ids:
        if id in srm_atlas:
            res = srm_atlas[id]
        else:
            res = ""
        result_dict[id] = res
    return result_dict


def create_header(input_file, ncol, features):
    col_names = list(range(1, len(input_file[0]) + 1))
    col_names = ["col" + str(e) for e in col_names]
    col_names[ncol] = "Uniprot-AC"
    col_names = col_names + features
    return(col_names)


def main():

    # Get args from command line
    args = get_args()
    features = args.features.split(",")
    header = False
    if args.input_type == "file":
        column_number = nb_col_to_int(args.column_number)
        header = str2bool(args.header)

    # Get reference file (Human SRM Atlas)
    with gzip.open(args.ref_file, "rt", newline='') as csv_file:
        srm_atlas_csv = csv.reader(csv_file, delimiter='\t')
        srm_atlas_csv = [line for line in srm_atlas_csv]

    # Create srm Atlas dictionary
    srm_atlas = create_srm_atlas_dictionary(features, srm_atlas_csv)

    # Get file and/or ids from input
    if args.input_type == "list":
        ids = get_input_ids_from_string(args.input)
    elif args.input_type == "file":
        input_file, ids = get_input_ids_from_file(args.input,
                                                  column_number, header)

    # Check Uniprot-AC
    if not any([check_uniprot(id) for id in ids]):
        print("No Uniprot-AC found, please check your input")
        exit()

    # retrieve features
    result_dict = retrieve_srm_features(srm_atlas, ids)

    # write output
    with open(args.output, "w") as output:
        writer = csv.writer(output, delimiter="\t")

        # write header
        if header:
            writer.writerow(input_file[0] + features)
            input_file = input_file[1:]
        elif args.input_type == "file":
            col_names = [create_header(input_file, column_number, features)]
            writer.writerow(col_names)
        else:
            writer.writerow(["Uniprot-AC"] + features)

        # write lines
        previous_line = ""
        if args.input_type == "file":
            for line in input_file:
                for res in result_dict[line[column_number]]:
                    output_line = ["NA" if cell == "" or cell == " " or cell == "NaN" else cell for cell in line+res]  # noqa 501
                    if previous_line != output_line:
                        writer.writerow(output_line)
                        previous_line = output_line
        elif args.input_type == "list":
            for id in ids:
                for res in result_dict[id]:
                    line = ["NA" if cell == "" or cell == " " or cell == "NaN" else cell for cell in [id]+res]  # noqa 501
                    if previous_line != line:
                        writer.writerow(line)
                        previous_line = line


if __name__ == "__main__":
    main()
