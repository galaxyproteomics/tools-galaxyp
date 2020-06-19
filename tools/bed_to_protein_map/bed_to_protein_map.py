#!/usr/bin/env python
"""
#
#------------------------------------------------------------------------------
#                         University of Minnesota
#         Copyright 2017, Regents of the University of Minnesota
#------------------------------------------------------------------------------
# Author:
#
#  James E Johnson
#
#------------------------------------------------------------------------------
"""

import argparse
import sys


def __main__():
    parser = argparse.ArgumentParser(
        description='Convert BED file to protein mapping')
    parser.add_argument(
        'input',
        help='A BED file (12 column)')
    parser.add_argument(
        'output',
        help='Output file  (-) for stdout')
    parser.add_argument('-d', '--debug', action='store_true', help='Debug')
    args = parser.parse_args()

    input_rdr = open(args.input, 'r') if args.input != '-' else sys.stdin
    output_wtr = open(args.output, 'w') if args.output != '-' else sys.stdout

    try:
        for linenum, line in enumerate(input_rdr):
            if args.debug:
                sys.stderr.write("%d: %s\n" % (linenum, line))
            if line.startswith('#'):
                continue
            if line.strip() == '':
                continue
            fields = line.rstrip('\r\n').split('\t')
            if len(fields) < 12:
                sys.stderr.write("%d: %s\n" % (linenum, line))
                continue
            (chrom, _chromStart, _chromEnd, name, score, strand,
             _thickStart, _thickEnd, itemRgb,
             _blockCount, blockSizes, blockStarts) = fields[0:12]
            chromStart = int(_chromStart)
            thickStart = int(_thickStart)
            thickEnd = int(_thickEnd)
            blockCount = int(_blockCount)
            blockSizes = [int(x) for x in blockSizes.split(',')]
            blockStarts = [int(x) for x in blockStarts.split(',')]
            if strand == '+':
                cds_start = 0
                cds_end = 0
                for i in range(blockCount):
                    start = chromStart + blockStarts[i]
                    end = start + blockSizes[i]
                    if end < thickStart:
                        continue
                    if start > thickEnd:
                        break
                    if start < thickStart:
                        start = thickStart
                    if end > thickEnd:
                        end = thickEnd
                    cds_end = cds_start + (end - start)
                    output_wtr.write('%s\t%s\t%d\t%d\t%s\t%d\t%d\n'
                                     % (name, chrom, start, end,
                                        strand, cds_start, cds_end))
                    cds_start = cds_end
            elif strand == '-':
                cds_start = 0
                cds_end = 0
                for i in reversed(range(blockCount)):
                    start = chromStart + blockStarts[i]
                    end = start + blockSizes[i]
                    if end < thickStart:
                        break
                    if start > thickEnd:
                        continue
                    if start < thickStart:
                        start = thickStart
                    if end > thickEnd:
                        end = thickEnd
                    cds_end = cds_start + (end - start)
                    output_wtr.write('%s\t%s\t%d\t%d\t%s\t%d\t%d\n'
                                     % (name, chrom, start, end,
                                        strand, cds_start, cds_end))
                    cds_start = cds_end
                pass
    except Exception as e:
        sys.stderr.write("failed: %s\n" % e)
        exit(1)


if __name__ == "__main__":
    __main__()
