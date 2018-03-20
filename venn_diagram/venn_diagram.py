#!/usr/bin/env python2.7

import os
import sys
import json
import operator
import argparse
import re
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
            file_content = open(input_file, "r").readlines()
            
            # Check if column number is in right form
            if isnumber("int", ncol.replace("c", "")):
                if header == "true":
                    file_content = [x.strip() for x in [line.split("\t")[int(ncol.replace("c", ""))-1].split(";")[0] for line in file_content[1:]]]     # take only first IDs
                else:
                    file_content = [x.strip() for x in [line.split("\t")[int(ncol.replace("c", ""))-1].split(";")[0] for line in file_content]]     # take only first IDs
            else:
                raise ValueError("Please fill in the right format of column number")        
        else:
            ids = set()
            file_content = inputs[i][0].split()
            
        ids.update(file_content)
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

def write_text_venn(json_result):
    """
    Write intersections of input to text output file
    """
    output = open("venn_diagram_text_output.txt", "w")
    string = ""
    lines = []
    result = dict((k, v) for k, v in json_result["data"].iteritems() if v != [])
    max_count = max(len(v) for v in result.values())
    for i in range(max_count):
        lines.append("")
        
    for i in range(max_count):
        header = ""
        for d in range(len(result.keys())):
            data = result.keys()[d]
            name = "_".join([json_result["name"][x] for x in data])
            header += name + "\t"
            if len(result[data]) > i:
                print("a", result[data][i])
                lines[i] += result[data][i] + "\t"
            else:
                lines[i] += "\t"
    # Strip last tab in the end of the lines
    header = header.rstrip()
    lines = [line.rstrip() for line in lines]
    string += header + "\n"
    string += "\n".join(lines)
    output.write(string)
    output.close()

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
