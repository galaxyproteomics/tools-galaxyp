#!/usr/bin/env python3
#
# Prefixes sequence headers in the input FASTA file that are not formatted according to the UniProt, NCBI, or ENSEMBL formats with '>generic|' to avoid being misinterpreted by Philosopher.
#

import re
import sys

input_db_file = sys.argv[1]
output_db_file = sys.argv[2]


def sub_header(line):
    return re.sub(r'^>(?!sp\||tr\||db\||AP_|NP_|YP_|XP_|WP_|ENSP|UniRef|nxp|generic)', '>generic|', line)


with open(input_db_file) as in_file, open(output_db_file, 'w') as out_file:
    for line in in_file:
        out_file.write(sub_header(line))
