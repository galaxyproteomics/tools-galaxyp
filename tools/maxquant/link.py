"""Link Galaxy datasets to files with Windows-style extensions that MaxQuant accepts.
"""

import argparse
import os

parser = argparse.ArgumentParser()
parser.add_argument('--infiles', '-i' help="Comma-separated list of input files.")
parser.add_argument('--infile_names', '-n', help="The names of the links to be created.")
parser.add_argument('--ftype', '-t', help="The file type extension of the links.")
args = parse.parse_args()

for s, d in zip(args.infiles, args.infile_names):
    if not d.lower().endwith(args.ftype.lower()):
        d = os.path.splitext(d)[0] + '.' + ftype
    os.symlink(s, d)

