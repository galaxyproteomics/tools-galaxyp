import argparse, re, csv

def options():
    """
    Parse options:
        -i, --input     Input filename and boolean value if the file contains header ["filename,true/false"]
        --kw            Keyword to be filtered, the column number where this filter applies, 
                        boolean value if the keyword should be filtered in exact ["keyword,ncol,true/false"].
                        This option can be repeated: --kw "kw1,c1,true" --kw "kw2,c1,false" --kw "kw3,c2,true"
        --kwfile        A file that contains keywords to be filter, the column where this filter applies and 
                        boolean value if the keyword should be filtered in exact ["filename,ncol,true/false"]
        --value         The value to be filtered, the column number where this filter applies and the 
                        operation symbol ["value,ncol,=/>/>=/</<=/!="]
        --values_range  range of values to be keep, example : --values_range 5 20 c1 true 
        --operator      The operator used to filter with several keywords/values : AND or OR
        --o --output    The output filename
        --filtered_file    The file contains removed lines
        -s --sort_col   Used column to sort the file, ",true" for reverse sorting, ",false" otherwise example : c1,false
    """
    parser = argparse.ArgumentParser()
    parser.add_argument("-i", "--input", help="Input file", required=True)
    parser.add_argument("--kw", nargs="+", action="append", help="")
    parser.add_argument("--kw_file", nargs="+", action="append", help="")
    parser.add_argument("--value", nargs="+", action="append", help="")
    parser.add_argument("--values_range", nargs="+", action="append", help="")
    parser.add_argument("--operator", default="OR", type=str, choices=['AND','OR'],help='')
    parser.add_argument("-o", "--output", default="output.txt")
    parser.add_argument("--filtered_file", default="filtered_output.txt")
    parser.add_argument("-s","--sort_col", help="")

    args = parser.parse_args()
    filters(args)

def str_to_bool(v):
    if v.lower() in ('yes', 'true', 't', 'y', '1'):
        return True
    elif v.lower() in ('no', 'false', 'f', 'n', '0'):
        return False
    else:
        raise argparse.ArgumentTypeError('Boolean value expected.')

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

#Filter the document
def filters(args):
    filename = args.input.split(",")[0]
    header = str_to_bool(args.input.split(",")[1])
    csv_file = read_file(filename)
    results_dict = {}

    if args.kw:
        keywords = args.kw
        for k in keywords:
            results_dict=filter_keyword(csv_file, header, results_dict, k[0], k[1], k[2])

    if args.kw_file:
        key_files = args.kw_file
        for kf in key_files:
            keywords = read_option(kf[0])
            results_dict=filter_keyword(csv_file, header, results_dict, keywords, kf[1], kf[2])

    if args.value:
        for v in args.value:
            if is_number("float", v[0]):
                results_dict = filter_value(csv_file, header, results_dict, v[0], v[1], v[2])
            else:
                raise ValueError("Please enter a number in filter by value")

    if args.values_range:
        for vr in args.values_range:
            if (is_number("float", vr[0]) or is_number("int", vr[0])) and (is_number("float",vr[1]) or is_number("int",vr[1])):
                results_dict = filter_values_range(csv_file, header, results_dict, vr[0], vr[1], vr[2], vr[3])

    remaining_lines=[]
    filtered_lines=[]

    if header is True : 
        remaining_lines.append(csv_file[0])
        filtered_lines.append(csv_file[0])

    for id_line,line in enumerate(csv_file) :
        if id_line in results_dict :   #skip header and empty lines
            if args.operator == 'OR' :
                if any(results_dict[id_line]) :
                    filtered_lines.append(line)
                else : 
                    remaining_lines.append(line)

            elif args.operator == "AND" :
                if all(results_dict[id_line]) :
                    filtered_lines.append(line)
                else : 
                    remaining_lines.append(line)
    
    #sort of results by column
    if args.sort_col :
        sort_col=args.sort_col.split(",")[0]
        sort_col=column_from_txt(sort_col)
        reverse=str_to_bool(args.sort_col.split(",")[1])
        remaining_lines= sort_by_column(remaining_lines,sort_col,reverse,header)
        filtered_lines = sort_by_column(filtered_lines,sort_col,reverse,header)
    
    # Write results to output
    with open(args.output,"w") as output :
        writer = csv.writer(output,delimiter="\t")
        writer.writerows(remaining_lines)

    # Write filtered lines to filtered_output
    with open(args.filtered_file,"w") as filtered_output :
        writer = csv.writer(filtered_output,delimiter="\t")
        writer.writerows(filtered_lines)

#function to sort the csv_file by value in a specific column
def sort_by_column(tab,sort_col,reverse,header):
    if header is True :
        head=tab[0]
        tab=tab[1:]

    if is_number("int",tab[0][sort_col]) :
        tab = sorted(tab, key=lambda row: int(row[sort_col]), reverse=reverse)
    elif is_number("float",tab[0][sort_col]) :
        tab = sorted(tab, key=lambda row: float(row[sort_col]), reverse=reverse)
    else :
        tab = sorted(tab, key=lambda row: row[sort_col], reverse=reverse)
    
    if header is True : tab = [head]+tab

    return tab

#Read the keywords file to extract the list of keywords
def read_option(filename):
    with open(filename, "r") as f:
        filter_list=f.read().splitlines()
    filter_list=[key for key in filter_list if len(key.replace(' ',''))!=0]
    filters=";".join(filter_list)

    return filters

# Read input file
def read_file(filename):
    with open(filename,"r") as f :
        reader=csv.reader(f,delimiter="\t")
        tab=list(reader)

    # Remove empty lines (contain only space or new line or "")
    #[tab.remove(blank) for blank in tab if blank.isspace() or blank == ""]
    tab=[line for line in tab if len("".join(line).replace(" ","")) !=0 ]
    
    return tab

#seek for keywords in rows of csvfile, return a dictionary of boolean (true if keyword found, false otherwise) 
def filter_keyword(csv_file, header, results_dict, keywords, ncol, match):
    match=str_to_bool(match)
    ncol=column_from_txt(ncol)

    keywords = keywords.upper().split(";")                                            # Split list of filter keyword
    [keywords.remove(blank) for blank in keywords if blank.isspace() or blank == ""]  # Remove blank keywords
    keywords = [k.strip() for k in keywords]        # Remove space from 2 heads of keywords

    for id_line,line in enumerate(csv_file):
        if header is True and id_line == 0 : continue
        #line = line.replace("\n", "")
        keyword_inline = line[ncol].replace('"', "").split(";")
        #line = line + "\n"

        #Perfect match or not
        if match is True :
            found_in_line = any(pid.upper() in keywords for pid in keyword_inline)
        else: 
            found_in_line = any(ft in pid.upper() for pid in keyword_inline for ft in keywords)     

        #if the keyword is found in line
        if id_line in results_dict : results_dict[id_line].append(found_in_line)
        else : results_dict[id_line]=[found_in_line]

    return results_dict

#filter ba determined value in rows of csvfile, return a dictionary of boolean (true if value filtered, false otherwise)
def filter_value(csv_file, header, results_dict, filter_value, ncol, opt):

    filter_value = float(filter_value)
    ncol=column_from_txt(ncol)

    for id_line,line in enumerate(csv_file):
        if header is True and id_line == 0 : continue
        value = line[ncol].replace('"', "").strip()
        if value.replace(".", "", 1).isdigit():
            to_filter=value_compare(value,filter_value,opt)
            
            #adding the result to the dictionary
            if id_line in results_dict : results_dict[id_line].append(to_filter)
            else : results_dict[id_line]=[to_filter]
            
    return results_dict

#filter ba determined value in rows of csvfile, return a dictionary of boolean (true if value filtered, false otherwise)
def filter_values_range(csv_file, header, results_dict, bottom_value, top_value, ncol, inclusive):
    inclusive=str_to_bool(inclusive)
    bottom_value = float(bottom_value)
    top_value=float(top_value)
    ncol=column_from_txt(ncol)

    for id_line, line in enumerate(csv_file):
        if header is True and id_line == 0 : continue
        value = line[ncol].replace('"', "").strip()
        if value.replace(".", "", 1).isdigit():
            value=float(value)
            if inclusive is True:
                in_range = not (bottom_value <= value <= top_value)
            else : 
                in_range = not (bottom_value < value < top_value)

            #adding the result to the dictionary
            if id_line in results_dict : results_dict[id_line].append(in_range)
            else : results_dict[id_line]=[in_range]

    return results_dict 

def column_from_txt(ncol):
    if is_number("int", ncol.replace("c", "")): 
        ncol = int(ncol.replace("c", "")) - 1 
    else:
        raise ValueError("Please specify the column where "
                         "you would like to apply the filter "
                         "with valid format")
    return ncol

#return True if value is in the determined values, false otherwise
def value_compare(value,filter_value,opt):
    test_value=False

    if opt == "<":
        if float(value) < filter_value:
            test_value = True
    elif opt == "<=":
        if float(value) <= filter_value:
            test_value = True
    elif opt == ">":
        if float(value) > filter_value:
            test_value = True
    elif opt == ">=":
        if float(value) >= filter_value:
            test_value = True
    elif opt == "=":
        if float(value) == filter_value:
            test_value = True
    elif opt == "!=": 
        if float(value) != filter_value:
            test_value = True

    return test_value

if __name__ == "__main__":
    options()
