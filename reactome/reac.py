import os
import re
import json
import argparse

CURRENT_DIR = os.path.dirname(os.path.abspath(__file__))

def id_valid(identifiers):
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

def data_json(identifiers):
    trash = []
    if identifiers[1] == "list":
        ids = "\n".join(id_valid(identifiers[0].split())[0])
        #print(ids)
        #print("curl -H \"Content-Type: text/plain\" -d \"$(printf '%s')\" -X POST --url www.reactome.org/AnalysisService/identifiers/projection/\?pageSize\=1\&page\=1" % ids)
        json_string = os.popen("curl -H \"Content-Type: text/plain\" -d \"$(printf '%s')\" -X POST --url www.reactome.org/AnalysisService/identifiers/projection/\?pageSize\=1\&page\=1" % ids).read()
        if len(id_valid(identifiers[0].split())[1]) > 0:
            trash = id_valid(identifiers[0].split())[1]
    #elif identifiers[1] == "file":
        #file = open(identifiers[0]).readlines()
        #ids = "\n".join(id_valid(file)[0])
        #print(ids)
        #print("curl -H \"Content-Type: text/plain\" -d \"$(printf '%s')\" -X POST --url www.reactome.org/AnalysisService/identifiers/projection/\?pageSize\=1\&page\=1" % ids)
        #json_string = os.popen("curl -H \"Content-Type: text/plain\" -d \"$(printf '%s')\" -X POST --url www.reactome.org/AnalysisService/identifiers/projection/\?pageSize\=1\&page\=1" % ids).read()
        #if len(id_valid(file)[1]) > 0:
            #trash = id_valid(file)[1]
    elif identifiers[1] == "mq_file":
        header = identifiers[2]
        mq = open(identifiers[0]).readlines()
        if isnumber("int", identifiers[3].replace("c", "")):
            if header == "true":
                idens = [x.split("\t")[int(identifiers[3].replace("c", ""))-1] for x in mq[1:]]
            else:
                idens = [x.split("\t")[int(identifiers[3].replace("c", ""))-1] for x in mq]
            ids = "\n".join(id_valid(idens)[0])
            #print(ids)
            #print("curl -H \"Content-Type: text/plain\" -d \"$(printf '%s')\" -X POST --url www.reactome.org/AnalysisService/identifiers/projection/\?pageSize\=1\&page\=1" % ids)
            json_string = os.popen("curl -H \"Content-Type: text/plain\" -d \"$(printf '%s')\" -X POST --url www.reactome.org/AnalysisService/identifiers/projection/\?pageSize\=1\&page\=1" % ids).read()
            if len(id_valid(idens)[1]) > 0:
                trash = id_valid(idens)[1]
    print(json_string)
    return json_string, trash

def write_output(filename, json_string, trash_file, trash):
    template = open(os.path.join(CURRENT_DIR, "template.html"))
    output = open(filename, "w")
    for line in template:
        if "{token}" in line:
            line = line.replace("{token}", json.loads(json_string)["summary"]["token"])
        output.write(line)
    template.close()
    output.close()
    
    trash_out = open(trash_file, "w")
    trash_out.write("\n".join(trash))
    trash_out.close()

def options():
    parser = argparse.ArgumentParser()
    argument = parser.add_argument("--json", nargs="+", required=True)
    argument = parser.add_argument("--output", default="output.html")
    argument = parser.add_argument("--trash", default="trash.txt")
    args = parser.parse_args()
    filename = args.output
    json_string, trash = data_json(args.json)
    write_output(filename, json_string, args.trash, trash)

if __name__ == "__main__":
    options()
