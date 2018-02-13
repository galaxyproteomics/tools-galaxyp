import argparse
import os
import re
import random
import math

def main():
    ps = parserCLI()
    args = vars(ps.parse_args())
    if args["ftype"] == "tabular" and args["by"] == "col":
        args["match"] = replaceMappedChars(args["match"])
        args["sub"] = replaceMappedChars(args["sub"])
        splitByColumn(args)
    else:
        splitByRecord(args)

def parserCLI():
    parser = argparse.ArgumentParser(description = "split a file into multiple files. Can split on the column of a tabular file,  with custom and useful names based on column value")
    parser.add_argument('--in', '-i', required=True, help="The input file")
    parser.add_argument('--out_dir', '-o', default=os.getcwd(), help="The output directory", required = True)
    parser.add_argument('--file_names', '-a', help="If not splitting by column, the base name of the new files")
    parser.add_argument('--file_ext', '-e', help="If not splitting by column, the extention of the new files (without a period)")
    parser.add_argument('--ftype', '-f', help="The type of the file to split", required = True,
        choices=["mgf", "fastq", "fastqsanger", "fasta", "tabular"])
    parser.add_argument('--by', '-b', help="Split by line or by column (tabular only)",
        default = "row", choices = ["col", "row"])
    parser.add_argument('--top', '-t', type = int, default = 0, help="Number of header lines to carry over to new files. " + 
        "(tabular only).")
    parser.add_argument('--rand', '-r', help="Divide records randomly into new files", action='store_true')
    parser.add_argument('--seed', '-x', help="Provide a seed for the random number generator. If not provided and args[\"rand\"]==True, then date is used", type=int)
    parser.add_argument('--numnew', '-n', type=int, default = 1, help="Number of output files desired. Not valid for splitting on a column")
    bycol = parser.add_argument_group('If splitting on a column')
    bycol.add_argument('--match', '-m', default = "(.*)", help="The regular expression to match id column entries")
    bycol.add_argument('--sub', '-s', default = r'\1', help="The regular expression to substitute in for the matched pattern.")
    bycol.add_argument('--id_column', '-c', default="1", help="Column that is used to name output files. Indexed starting from 1.", type=int)
    return parser

def replaceMappedChars(pattern):
    """
    handles special escaped characters when coming from galaxy
    """
    mapped_chars = { '\'' :'__sq__', '\\' : '__backslash__' }
    for key, value in mapped_chars.items():
        pattern = pattern.replace(value, key)
    return pattern

class fileTypes:
    seps = {'fasta': '^>',
            'fastq': '^@',
            'fastqsanger': '^@',
            'tabular': '^.*',
            'mgf': '^BEGIN IONS'}
 
def splitByRecord(args):
    
    infile = args["in"]
    ftype = args["ftype"]
    
    # get record separator for given filetype
    sep = re.compile(fileTypes.seps[ftype])

    numnew = args["numnew"]
    outdir = args["out_dir"]
    
    # if tabular, get top info 
    if ftype == "tabular":
        top = args["top"]

    # random division
    rand = args["rand"]
    seed = args["seed"]
    if seed is not None:
        random.seed(seed)
    else:
        random.seed()
    
    # make new files
    # strip extension of old file and add number
    customNewFileName = args["file_names"]
    customNewFileExt = "." + args["file_ext"]
    if customNewFileName is None:
        newFileBase = os.path.splitext(os.path.basename(infile))
    else:
        newFileBase = [customNewFileName, customNewFileExt]
    newfiles = [open(outdir + "/" +  newFileBase[0] + "_" + str(count) + newFileBase[1], "w+") \
        for count in range(0, numnew)] 
    newFileCounter = 0
    
    # open file
    linecounter = 0
    with open(infile, "r") as file:
        record = ""
        for line in file:
            # check if beginning of line is record sep
            # if beginning of line is record sep, either start record or finish one
            if re.match(sep, line) is not None:
                # this only happens first time through
                if record == "":
                    record += line
                else:
                    newfiles[newFileCounter].write(record)
                    record = line 
                    # change destination file
                    if rand:
                        newFileCounter = int(math.floor(random.random() * numnew))
                    else:
                        newFileCounter = (newFileCounter + 1) % numnew
            #if beginning of line is not record sep, we must be inside a record
            #so just append
            else: 
                record += line
        # after loop, write final record to file
        newfiles[newFileCounter].write(record)

def splitByColumn(args):
    # get and validate
    inpath = args["in"]
    if not os.path.isfile(args["in"]):
        raise FileNotFoundError('Input file does not exist')

    # shift to 0-based indexing
    id_col = int(args["id_column"]) - 1

    try:
        match = re.compile(args["match"])
    except re.error:
        print("ERROR: Match (-m) supplied is not valid regex.")
        raise

    sub = args["sub"]

    out_dir = args["out_dir"]
    if not os.path.isdir(args["out_dir"]):
        raise FileNotFoundError('out_dir is not a directory')

    top = args["top"]
    if top < 0:
        print("ERROR: Number of header lines cannot be negative")
        exit(1)

    # set of file names
    new_files = dict()

    # keep track of how many lines have been read
    nRead = 0
    header = ""
    with open(inpath) as file:
        for line in file:
            # if still in top, save to header
            nRead += 1
            if nRead <= top:
                header += line
                continue
            # split into columns, on tab
            fields = re.split(r'\t', line.strip('\n'))

            # get id column value
            id_col_val = fields[id_col]

            # use regex to get new file name
            out_file_name = re.sub(match, sub, id_col_val)
            out_file_path = os.path.join(out_dir, out_file_name)

            # write
            if out_file_name not in new_files.keys():
                # open file (new, so not already open)
                current_new_file = open(out_file_path, "w+")
                current_new_file.write(header)
                current_new_file.write(line)
                # add to dict
                new_files[out_file_name] = current_new_file
            else:
                # file is already open, so just write to it
                new_files[out_file_name].write(line)

    # finally, close all files
    for open_file in new_files.values():
        open_file.close()

if __name__=="__main__":
    main()
