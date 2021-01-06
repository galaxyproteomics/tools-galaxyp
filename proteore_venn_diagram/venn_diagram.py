#!/usr/bin/env python2.7

import os
import sys
import json
import operator
import argparse
import re, csv
from itertools import combinations

CURRENT_DIR = os.path.dirname(os.path.abspath(__file__))

##################################################################################################################################################
# FUNCTIONS
##################################################################################################################################################
 
def isnumber(format, n):
    """
    Check if an element is integer or float
    """
    float_format = re.compile(r"^[-]?[1-9][0-9]*.?[0-9]+$")
    int_format = re.compile(r"^[-]?[1-9][0-9]*$")
    test = ""
    if format == "int":
        test = re.match(int_format, n)
    elif format == "float":
        test = re.match(float_format, n)
    if test:
        return True
    else:
        return False
        
def input_to_dict(inputs):
    """
    Parse input and return a dictionary of name and data of each lists/files
    """
    comp_dict = {}
    title_dict = {}
    c = ["A", "B", "C", "D", "E", "F"]  
    for i in range(len(inputs)):
        input_file = inputs[i][0]        
        name = inputs[i][1]
        input_type = inputs[i][2]
        title = c[i]
        title_dict[title] = name
        ids = set()
        if input_type == "file":
            header = inputs[i][3]
            ncol = inputs[i][4]
            with open(input_file,"r") as handle :
                file_content = csv.reader(handle,delimiter="\t")
                file_content = list(file_content)   #csv object to list
            
                # Check if column number is in right form
                if isnumber("int", ncol.replace("c", "")):
                    if header == "true":
                        file_content = [x for x in [line[int(ncol.replace("c", ""))-1].split(";") for line in file_content[1:]]]     # gets ids from defined column
                    else:
                        file_content = [x for x in [line[int(ncol.replace("c", ""))-1].split(";") for line in file_content]] 
                else:
                    raise ValueError("Please fill in the right format of column number")        
        else:
            ids = set()
            file_content = inputs[i][0].split()
            file_content = [x.split(";") for x in file_content]
            
        file_content = [item.strip() for sublist in file_content for item in sublist if item != '']   #flat list of list of lists, remove empty items    
        ids.update(file_content)
        if 'NA' in ids : ids.remove('NA')
        comp_dict[title] = ids
 
    return comp_dict, title_dict
    
def intersect(comp_dict):
    """
    Calculate the intersections of input
    """
    names = set(comp_dict)
    for i in range(1, len(comp_dict) + 1):
        for group in combinations(sorted(comp_dict), i):
            others = set()
            [others.add(name) for name in names if name not in group]
            difference = []
            intersected = set.intersection(*(comp_dict[k] for k in group))
            if len(others) > 0:
                difference = intersected.difference(set.union(*(comp_dict[k] for k in others)))
            yield group, list(intersected), list(difference)    

def diagram(comp_dict, title_dict):
    """
    Create json string for jvenn diagram plot
    """
    result = {}
    result["name"] = {}
    for k in comp_dict.keys():
        result["name"][k] = title_dict[k]
        
    result["data"] = {}
    result["values"] = {}    
    for group, intersected, difference in intersect(comp_dict):
        if len(group) == 1:
            result["data"]["".join(group)] = difference
            result["values"]["".join(group)] = len(difference)
        elif len(group) > 1 and len(group) < len(comp_dict):
	        result["data"]["".join(group)] = difference
	        result["values"]["".join(group)] = len(difference)               
        elif len(group) == len(comp_dict):
            result["data"]["".join(group)] = intersected
            result["values"]["".join(group)] = len(intersected)

    return result

#Write intersections of input to text output file
def write_text_venn(json_result):
    lines = []
    result = dict((k, v) for k, v in json_result["data"].iteritems() if v != [])
    for key in result :
        if 'NA' in result[key] : result[key].remove("NA")
    list_names = dict((k, v) for k, v in json_result["name"].iteritems() if v != [])
    nb_lines_max = max(len(v) for v in result.values())

    #get list names associated to each column
    column_dict = {}
    for key in result :
        if key in list_names :
            column_dict[key] = list_names[key]
        else : 
            keys= list(key)
            column_dict[key] = "_".join([list_names[k] for k in keys])

    #construct tsv
    for key in result :
        line = result[key]
        if len(line) < nb_lines_max :
            line.extend(['NA']*(nb_lines_max-len(line)))
        line = [column_dict[key]] + line                #add header
        lines.append(line)  
    #transpose tsv
    lines=zip(*lines)
    
    with open("venn_diagram_text_output.tsv", "w") as output:
        tsv_output = csv.writer(output, delimiter='\t')
        tsv_output.writerows(lines)

def write_summary(summary_file, inputs):
    """
    Paste json string into template file
    """
    a, b = input_to_dict(inputs)
    data = diagram(a, b)
    write_text_venn(data)

    to_replace = {
    	"series": [data],
    	"displayStat": "true",
    	"displaySwitch": "true",
        "shortNumber": "true",
    }

    FH_summary_tpl = open(os.path.join(CURRENT_DIR, "jvenn_template.html"))
    FH_summary_out = open(summary_file, "w" )
    for line in FH_summary_tpl:
        if "###JVENN_DATA###" in line:
            line = line.replace("###JVENN_DATA###", json.dumps(to_replace))
        FH_summary_out.write(line)
    
    FH_summary_out.close()
    FH_summary_tpl.close()
   
def process(args):
    write_summary(args.summary, args.input)


##################################################################################################################################################
# MAIN
##################################################################################################################################################
if __name__ == '__main__':
    # Parse parameters
    parser = argparse.ArgumentParser(description='Filters an abundance file')
    group_input = parser.add_argument_group( 'Inputs' )
    group_input.add_argument('--input', nargs="+", action="append", required=True, help="The input tabular file.")
    group_output = parser.add_argument_group( 'Outputs' )
    group_output.add_argument('--summary', default="summary.html", help="The HTML file containing the graphs. [Default: %(default)s]")
    args = parser.parse_args()

    # Process
    process( args )
