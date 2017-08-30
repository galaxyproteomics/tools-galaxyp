#!/usr/bin/env python2.7
#
# Copyright (C) 2017 INRA
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

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
    float_format = re.compile("^[\-]?[1-9][0-9]*\.?[0-9]+$")
    int_format = re.compile("^[\-]?[1-9][0-9]*$")
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
    comp_dict = {}
    title_dict = {}
    #print(len(comp_files), comp_files[0])
    c = ["A", "B", "C", "D", "E", "F"]  
    for i in range(len(inputs)):
        input_file = inputs[i][0]        
        name = inputs[i][1]
        input_type = inputs[i][2]
        title = c[i]
        title_dict[title] = name
        ids = set()
        if input_type == "mq_file":
            header = inputs[i][3]
            ncol = inputs[i][4]
            file_content = open(input_file, "r").readlines()
            
            if isnumber("int", ncol.replace("c", "")):
                if header == "true":
                    file_content = [x for x in [line.split("\t")[int(ncol.replace("c", ""))-1].split(";")[0] for line in file_content[1:]]]     # take only first IDs
                else:
                    file_content = [x for x in [line.split("\t")[int(ncol.replace("c", ""))-1].split(";")[0] for line in file_content]]     # take only first IDs
                #print(file_content[1:13])
            else:
                raise ValueError("Please fill in the right format of column number")
        #elif input_type == "file":
         #   file_content = open(input_file, "r").readlines()
          #  file_content = [x.replace("\n", "") for x in file_content]
           # file_content = [x.replace("\r", "") for x in file_content]         
        else:
            ids = set()
            file_content = inputs[i][0].split()
            
        ids.update(file_content)
        comp_dict[title] = ids
 
    return comp_dict, title_dict
    
def intersect(comp_dict):
    names = set(comp_dict)
    for i in range(1, len(comp_dict) + 1):
        for group in combinations(sorted(comp_dict), i):
            others = set()
            [others.add(name) for name in names if name not in group]
            difference = []
            print(group, others)
            intersected = set.intersection(*(comp_dict[k] for k in group))
            n = "".join(group)
            if len(others) > 0:
                difference = intersected.difference(set.union(*(comp_dict[k] for k in others)))
                #difference[n] = dif
            yield group, list(intersected), list(difference)    

def diagram(comp_dict, title_dict):
    # Extract protein IDs in MQfile
    prot_ids = set()
    #print(prot_ids)

    result = {}
    result["name"] = {}
    #print(comp_dict.keys())
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
    #print(result)
    return result

def write_text_venn(json_result):
    for data in json_result["data"].keys():
        name = "_".join([json_result["name"][x] for x in data])
        filename = name + "_venn.txt"
        output = open(filename, "w")
        output.write("\n".join(json_result["data"][data]))
        output.close()

def write_summary( summary_file, inputs):
    a, b = input_to_dict(inputs)
    data = diagram(a, b)
    write_text_venn(data)

    to_replace = {
    	"series": [data],
    	"displayStat": "true",
    	"displaySwitch": "true",
        "shortNumber": "true",
    }
    #print(to_replace)

    # Global before filters
    FH_summary_tpl = open( os.path.join(CURRENT_DIR, "jvenn_tpl.html") )
    FH_summary_out = open( summary_file, "w" )
    for line in FH_summary_tpl:
        if "###JVENN_DATA###" in line:
            line = line.replace("###JVENN_DATA###", json.dumps(to_replace))
            print(line)
        FH_summary_out.write( line )
    
    FH_summary_out.close()
    FH_summary_tpl.close()
   
def process( args ):
    write_summary( args.summary, args.input)


##################################################################################################################################################
# MAIN
##################################################################################################################################################
if __name__ == '__main__':
    # Parameters
    parser = argparse.ArgumentParser(description='Filters an abundance file')
    group_input = parser.add_argument_group( 'Inputs' )
    group_input.add_argument('--input', nargs="+", action="append", required=True, help="The input tabular file.")
    group_output = parser.add_argument_group( 'Outputs' )
    group_output.add_argument('--summary', default="summary.html", help="The HTML file containing the graphs. [Default: %(default)s]")
    args = parser.parse_args()
    #print(args.input)

    # Process
    process( args )
