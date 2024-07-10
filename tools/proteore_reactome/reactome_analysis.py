#!/usr/bin/env python

import argparse
import csv
import json
import os
import re

CURRENT_DIR = os.path.dirname(os.path.abspath(__file__))


def id_valid(identifiers):
    """
    Validate IDs if they contain special characters
    """
    res = []
    remove = []
    for id in identifiers:
        id = id.split(";")[0]
        if re.match("^[A-Za-z0-9_-]*$", id):
            res.append(id)
        else:
            remove.append(id)
    return res, remove


def isnumber(format, n):
    """
    Check if an variable is numeric
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


def data_json(identifiers):
    """
    Submit IDs list to Reactome and return results in json format
    Return error in HTML format if web service is not available
    """
    trash = []
    if identifiers[1] == "list":
        ids = identifiers[0].split()
        ids = [x.split(";") for x in ids]
        ids = [item.strip() for sublist in ids for item in sublist if item != '']  # noqa 501
        json_string = os.popen("curl -H \"Content-Type: text/plain\" -d \"$(printf '%s')\" -X POST --url www.reactome.org/AnalysisService/identifiers/\?pageSize\=1\&page\=1" % ids).read()  # noqa 501
        if len(id_valid(identifiers[0].split())[1]) > 0:
            trash = id_valid(identifiers[0].split())[1]
    elif identifiers[1] == "file":
        header = identifiers[2]
        with open(identifiers[0], "r") as mq:
            file_content = csv.reader(mq, delimiter="\t")
            file_content = list(file_content)   # csv object to list
            ncol = identifiers[3]
            if isnumber("int", ncol.replace("c", "")):
                if header == "true":
                    idens = [x for x in [line[int(ncol.replace("c", ""))-1].split(";") for line in file_content[1:]]]  # noqa 501
                else:
                    idens = [x for x in [line[int(ncol.replace("c", ""))-1].split(";") for line in file_content]]  # noqa 501
                # flat list of list of lists, remove empty items
                idens = [item.strip() for sublist in idens for item in sublist if item != '']  # noqa 501
                ids = "\n".join(id_valid(idens)[0])
                json_string = os.popen("curl -H \"Content-Type: text/plain\" -d \"$(printf '%s')\" -X POST --url www.reactome.org/AnalysisService/identifiers/\?pageSize\=1\&page\=1 2> stderr" % ids).read()  # noqa 501
                if len(id_valid(idens)[1]) > 0:
                    trash = id_valid(idens)[1]
    # print(json_string)
    j = json.loads(json_string)
    print("Identifiers not found: " + str(j["identifiersNotFound"]))
    print("Pathways found: " + str(j["pathwaysFound"]))
    return json_string, trash


def write_output(filename, json_string, species, trash_file, trash):
    """
    Replace json result in template and print to output
    """
    template = open(os.path.join(CURRENT_DIR, "template.html"))
    output = open(filename, "w")
    try:
        for line in template:
            if "{token}" in line:
                line = line.replace("{species}", species)
                line = line.replace("{token}", json.loads(json_string)["summary"]["token"])  # noqa 501
            output.write(line)
    except ValueError:
        output.write("An error occurred due to unavailability of Reactome web service. Please return later.")  # noqa 501
    template.close()
    output.close()

    if trash:
        # print(trash)
        trash_out = open(trash_file, "w")
        trash_out.write("\n".join(trash))
        trash_out.close()


def options():
    parser = argparse.ArgumentParser()
    argument = parser.add_argument("--json", nargs="+", required=True)
    argument = parser.add_argument("--output", default="output.html")
    argument = parser.add_argument("--trash", default="trash.txt")
    argument = parser.add_argument("--species", default="48887")  # noqa 841
    args = parser.parse_args()
    filename = args.output
    json_string, trash = data_json(args.json)
    write_output(filename, json_string, args.species, args.trash, trash)


if __name__ == "__main__":
    options()
