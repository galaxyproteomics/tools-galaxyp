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

from __future__ import print_function

import argparse
import re
import sys

from bedutil import bed_from_line

from ensembl_rest import get_toplevel, get_transcripts_bed, max_region


def __main__():
    parser = argparse.ArgumentParser(
        description='Retrieve Ensembl cDNAs in BED format')
    parser.add_argument(
        '-s', '--species', default='human',
        help='Ensembl Species to retrieve')
    parser.add_argument(
        '-R', '--regions', action='append', default=[],
        help='Restrict Ensembl retrieval to regions e.g.:'
             + ' X,2:20000-25000,3:100-500+')
    parser.add_argument(
        '-B', '--biotypes', action='append', default=[],
        help='Restrict Ensembl biotypes to retrieve')
    parser.add_argument(
        '-X', '--extended_bed', action='store_true', default=False,
        help='Include the extended columns returned from Ensembl')
    parser.add_argument(
        '-U', '--ucsc_chrom_names', action='store_true', default=False,
        help='Use the UCSC names for Chromosomes')
    parser.add_argument(
        '-t', '--toplevel', action='store_true',
        help='Print Ensembl toplevel for species')
    parser.add_argument(
        'output',
        help='Output BED filepath, or for stdout: "-"')
    parser.add_argument('-v', '--verbose', action='store_true', help='Verbose')
    parser.add_argument('-d', '--debug', action='store_true', help='Debug')
    args = parser.parse_args()
    species = args.species
    out_wtr = open(args.output, 'w') if args.output != '-' else sys.stdout
    biotypes = ';'.join(['biotype=%s' % bt.strip()
                         for biotype in args.biotypes
                         for bt in biotype.split(',') if bt.strip()])

    selected_regions = dict()  # chrom:(start, end)
    region_pat = '^([^:]+)(?::(\d*)(?:-(\d+)([+-])?)?)?'
    if args.regions:
        for entry in args.regions:
            if not entry:
                continue
            regs = [x.strip() for x in entry.split(',') if x.strip()]
            for reg in regs:
                m = re.match(region_pat, reg)
                if m:
                    (chrom, start, end, strand) = m.groups()
                    if chrom:
                        if chrom not in selected_regions:
                            selected_regions[chrom] = []
                        selected_regions[chrom].append([start, end, strand])
        if args.debug:
            print("selected_regions: %s" % selected_regions, file=sys.stderr)

    def retrieve_region(species, ref, start, stop, strand):
        transcript_count = 0
        regions = list(range(start, stop, max_region))
        if not regions or regions[-1] < stop:
            regions.append(stop)
        for end in regions[1:]:
            bedlines = get_transcripts_bed(species, ref, start, end,
                                           strand=strand, params=biotypes)
            if args.debug:
                print("%s\t%s\tstart: %d\tend: %d\tcDNA transcripts:%d" %
                      (species, ref, start, end, len(bedlines)),
                      file=sys.stderr)
            # start, end, seq
            for i, bedline in enumerate(bedlines):
                if args.debug:
                    print("%s\n" % (bedline), file=sys.stderr)
                if not args.ucsc_chrom_names:
                    bedline = re.sub('^[^\t]+', ref, bedline)
                try:
                    if out_wtr:
                        out_wtr.write(bedline.replace(',\t', '\t')
                                      if args.extended_bed
                                      else str(bed_from_line(bedline)))
                        out_wtr.write("\n")
                        out_wtr.flush()
                except Exception as e:
                    print("BED error (%s) : %s\n" % (e, bedline),
                          file=sys.stderr)
            start = end + 1
        return transcript_count

    coord_systems = get_toplevel(species)
    if 'chromosome' in coord_systems:
        ref_lengths = dict()
        for ref in sorted(coord_systems['chromosome'].keys()):
            length = coord_systems['chromosome'][ref]
            ref_lengths[ref] = length
            if args.toplevel:
                print("%s\t%s\tlength: %d" % (species, ref, length),
                      file=sys.stderr)
        if selected_regions:
            transcript_count = 0
            for ref in sorted(selected_regions.keys()):
                if ref in ref_lengths:
                    for reg in selected_regions[ref]:
                        (_start, _stop, _strand) = reg
                        start = int(_start) if _start else 0
                        stop = int(_stop) if _stop else ref_lengths[ref]
                        strand = '' if not _strand else ':1'\
                            if _strand == '+' else ':-1'
                        transcript_count += retrieve_region(species, ref,
                                                            start, stop,
                                                            strand)
                        if args.debug or args.verbose:
                            length = stop - start
                            print("%s\t%s:%d-%d%s\tlength: %d\ttrancripts:%d" %
                                  (species, ref, start, stop, strand,
                                   length, transcript_count),
                                  file=sys.stderr)
        else:
            strand = ''
            start = 0
            for ref in sorted(ref_lengths.keys()):
                length = ref_lengths[ref]
                transcript_count = 0
                if args.debug:
                    print("Retrieving transcripts: %s\t%s\tlength: %d" %
                          (species, ref, length), file=sys.stderr)
                transcript_count += retrieve_region(species, ref, start,
                                                    length, strand)
                if args.debug or args.verbose:
                    print("%s\t%s\tlength: %d\ttrancripts:%d" %
                          (species, ref, length, transcript_count),
                          file=sys.stderr)


if __name__ == "__main__":
    __main__()
