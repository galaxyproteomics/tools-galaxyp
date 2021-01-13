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


class BedEntry(object):
    def __init__(self, chrom=None, chromStart=None, chromEnd=None,
                 name=None, score=None, strand=None,
                 thickStart=None, thickEnd=None, itemRgb=None,
                 blockCount=None, blockSizes=None, blockStarts=None):
        self.chrom = chrom
        self.chromStart = int(chromStart)
        self.chromEnd = int(chromEnd)
        self.name = name
        self.score = int(score) if score is not None else 0
        self.strand = '-' if str(strand).startswith('-') else '+'
        self.thickStart = int(thickStart) if thickStart else self.chromStart
        self.thickEnd = int(thickEnd) if thickEnd else self.chromEnd
        self.itemRgb = str(itemRgb) if itemRgb is not None else r'100,100,100'
        self.blockCount = int(blockCount)
        if isinstance(blockSizes, str):
            self.blockSizes = [int(x) for x in blockSizes.split(',')]
        elif isinstance(blockSizes, list):
            self.blockSizes = [int(x) for x in blockSizes]
        else:
            self.blockSizes = blockSizes
        if isinstance(blockStarts, str):
            self.blockStarts = [int(x) for x in blockStarts.split(',')]
        elif isinstance(blockStarts, list):
            self.blockStarts = [int(x) for x in blockStarts]
        else:
            self.blockStarts = blockStarts

    def sort_exons(self):
        sorted_list = [i for i in sorted(zip(self.blockStarts,self.blockSizes))]
        self.blockStarts = [i[0] for i in sorted_list]
        self.blockSizes = [i[1] for i in sorted_list]

    def __str__(self):
        self.sort_exons()
        return '%s\t%d\t%d\t%s\t%d\t%s\t%d\t%d\t%s\t%d\t%s\t%s' % (
            self.chrom, self.chromStart, self.chromEnd,
            self.name, self.score, self.strand,
            self.thickStart, self.thickEnd, str(self.itemRgb), self.blockCount,
            ','.join([str(x) for x in self.blockSizes]),
            ','.join([str(x) for x in self.blockStarts]))


def __main__():
    parser = argparse.ArgumentParser(
        description='Retrieve Ensembl cDNAs and three frame translate')
    parser.add_argument(
        'input',
        help='GFFCompare annotated GTF file,  (-) for stdin')
    parser.add_argument(
        'output',
        help='BED file,  (-) for stdout')
    parser.add_argument(
        '-C', '--class_code', action='append', default=[],
        help='Restrict output to gffcompare class codes')
    parser.add_argument('-d', '--debug', action='store_true', help='Debug')
    args = parser.parse_args()

    # print >> sys.stderr, "args: %s" % args
    input_rdr = open(args.input, 'r') if args.input != '-' else sys.stdin
    output_wtr = open(args.output, 'w') if args.output != '-' else sys.stdout

    def write_bed_entry(bed):
        if bed.blockCount == 0:
            bed.blockCount = 1
        output_wtr.write("%s\n" % str(bed))

    class_codes = [c.strip() for codes in args.class_code
                   for c in codes.split(',')] if args.class_code else None
    bed = None
    class_code = None
    for i, line in enumerate(input_rdr):
        if line.startswith('#'):
            continue
        fields = line.rstrip('\r\n').split('\t')
        if len(fields) != 9:
            continue
        (seqname, source, feature, start, end,
         score, strand, frame, attributes) = fields
        attribute = {i[0]: i[1].strip('"') for i in [j.strip().split(' ')
                     for j in attributes.rstrip(';').split(';')]}
        if feature == 'transcript':
            if args.debug:
                sys.stderr.write("%s\t%s\n" % ('\t'.join([seqname, source,
                                 feature, start, end, score, strand, frame]),
                                 attribute))
            if bed is not None:
                write_bed_entry(bed)
                bed = None
            class_code = attribute['class_code'].strip('"')\
                if 'class_code' in attribute else None
            if class_codes and class_code not in class_codes:
                continue
            chromStart = int(start) - 1
            chromEnd = int(end)
            cat = '_' + class_code if class_code and class_code != '=' else ''
            bed = BedEntry(chrom=seqname,
                           chromStart=chromStart, chromEnd=chromEnd,
                           name=attribute['transcript_id'] + cat,
                           strand=strand,
                           blockCount=0,
                           blockSizes=[chromEnd - chromStart],
                           blockStarts=[0])
        elif feature == 'exon' and bed is not None:
            chromStart = int(start) - 1
            chromEnd = int(end)
            blockSize = chromEnd - chromStart
            if bed.blockCount == 0:
                bed.blockSizes = []
                bed.blockStarts = []
            bed.blockSizes.append(blockSize)
            bed.blockStarts.append(chromStart - bed.chromStart)
            bed.blockCount += 1
    if bed is not None:
        write_bed_entry(bed)


if __name__ == "__main__":
    __main__()
