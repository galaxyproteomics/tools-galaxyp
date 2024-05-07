#!/usr/bin/env python3
#
# Prefixes sequence headers in the input FASTA file that are not formatted according to the UniProt, NCBI, or ENSEMBL formats with '>generic|' to avoid being misinterpreted by Philosopher.
#

import re
import sys

input_db_file = sys.argv[1]
output_db_file = sys.argv[2]

with open(input_db_file) as f:
    input_db = f.readlines()

subbed_lines = [re.sub(r'^>(?!sp\||tr\||db\||AP_|NP_|YP_|XP_|WP_|ENSP|UniRef|nxp|generic)', '>generic|', l) for l in input_db]

with open(output_db_file, 'w') as f:
    f.writelines(subbed_lines)
