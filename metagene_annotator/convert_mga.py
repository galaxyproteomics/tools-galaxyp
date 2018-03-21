#!/usr/bin/env python

from __future__ import print_function

import argparse
import math
import re
import sys


def __main__():
    parser = argparse.ArgumentParser(
        description='Convert mga output to bed and tsv')
    parser.add_argument(
        'input_mga',
        help="mga output to convert,  '-' for stdin")
    parser.add_argument(
        '-t', '--tsv', default=None,
        help='Path to output mga.tsv')
    parser.add_argument(
        '-b', '--bed', default=None,
        help='Path to output mga.bed')
    parser.add_argument('-v', '--verbose', action='store_true', help='Verbose')
    args = parser.parse_args()

    input_rdr = open(args.input_mga, 'r')\
        if args.input_mga != '-' else sys.stdin

    bed_wtr = open(args.bed, 'w') if args.bed is not None else None
    tsv_wtr = open(args.tsv, 'w') if args.bed is not None else None
    if tsv_wtr:
        tsv_wtr.write('#%s\n' % '\t'.join([
            'seq_id', 'seq_model', 'seq_gc', 'seq_rbs',
            'gene ID', 'start pos', 'end pos', 'strand', 'frame',
            'complete/partial', 'gene score', 'used model',
            'rbs start', 'rbs end', 'rbs score']))

    seq_count = 0
    gene_count = 0
    for i, line in enumerate(input_rdr):
        # 1317/1
        # gc = 0.272955, rbs = -1
        # self: -
        if line.startswith('# gc'):
            try:
                m = re.match('# gc = (-?[0-9]*[.]?[0-9]+)',
                             'rbs = (-?[0-9]*[.]?[0-9]+)',
                             line.strip())
                seq_gc, seq_rbs = m.groups()
            except:
                seq_gc = seq_rbs = ''
        elif line.startswith('# self:'):
            seq_type = re.sub('# self:', '', line.rstrip())
        elif line.startswith('# '):
            seq_name = re.sub('# (\S+).*$', '\\1', line.rstrip())
            seq_count += 1
        else:
            fields = line.split('\t')
            if len(fields) == 11:
                gene_count += 1
                start = int(fields[1]) - 1
                end = int(fields[2])
                if tsv_wtr:
                    tsv_wtr.write('%s\t%s\t%s\t%s\t%s' % (
                        seq_name,
                        seq_type,
                        seq_gc,
                        seq_rbs,
                        line))
                if bed_wtr:
                    bed_wtr.write(
                        '%s\t%d\t%d\t%s\t%s\t%s\t%d\t%d\t%s\t%s\t%s\t%s\n' % (
                            seq_name,
                            start,
                            end,
                            '%s:%s' % (seq_name, fields[0]),
                            int(math.ceil(float(fields[6]))),
                            fields[3],
                            start,
                            end,
                            0,
                            1,
                            abs(end - start),
                            0))

    if args.verbose:
        print("sequences: %d\tgenes: %d"
              % (seq_count, gene_count), file=sys.stdout)


if __name__ == "__main__":
    __main__()
