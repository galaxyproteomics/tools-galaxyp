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

from Bio.Seq import translate

from bedutil import bed_from_line

import digest

from ensembl_rest import get_cdna

from twobitreader import TwoBitFile


def __main__():
    parser = argparse.ArgumentParser(
        description='Translate from BED')
    parser.add_argument(
        'input_bed', default=None,
        help="BED to translate,  '-' for stdin")
    pg_seq = parser.add_argument_group('Genomic sequence source')
    pg_seq.add_argument(
        '-t', '--twobit', default=None,
        help='Genome reference sequence in 2bit format')
    pg_seq.add_argument(
        '-c', '--column', type=int, default=None,
        help='Column offset containing genomic sequence' +
             'between start and stop (-1) for last column')
    pg_out = parser.add_argument_group('Output options')
    pg_out.add_argument(
        '-f', '--fasta', default=None,
        help='Path to output translations.fasta')
    pg_out.add_argument(
        '-b', '--bed', default=None,
        help='Path to output translations.bed')
    pg_bed = parser.add_argument_group('BED filter options')
    pg_bed.add_argument(
        '-E', '--ensembl', action='store_true', default=False,
        help='Input BED is in 20 column Ensembl format')
    pg_bed.add_argument(
        '-R', '--regions', action='append', default=[],
        help='Filter input by regions e.g.:'
             + ' X,2:20000-25000,3:100-500+')
    pg_bed.add_argument(
        '-B', '--biotypes', action='append', default=[],
        help='For Ensembl BED restrict translations to Ensembl biotypes')
    pg_trans = parser.add_argument_group('Translation filter options')
    pg_trans.add_argument(
        '-m', '--min_length', type=int, default=10,
        help='Minimum length of protein translation to report')
    pg_trans.add_argument(
        '-e', '--enzyme', default=None,
        help='Digest translation with enzyme')
    pg_trans.add_argument(
        '-M', '--start_codon', action='store_true', default=False,
        help='Trim translations to methionine start_codon')
    pg_trans.add_argument(
        '-C', '--cds', action='store_true', default=False,
        help='Only translate CDS')
    pg_trans.add_argument(
        '-A', '--all', action='store_true',
        help='Include CDS protein translations ')
    pg_fmt = parser.add_argument_group('ID format options')
    pg_fmt.add_argument(
        '-r', '--reference', default='',
        help='Genome Reference Name')
    pg_fmt.add_argument(
        '-D', '--fa_db', dest='fa_db', default=None,
        help='Prefix DB identifier for fasta ID line, e.g. generic')
    pg_fmt.add_argument(
        '-s', '--fa_sep', dest='fa_sep', default='|',
        help='fasta ID separator defaults to pipe char, ' +
             'e.g. generic|ProtID|description')
    pg_fmt.add_argument(
        '-P', '--id_prefix', default='',
        help='prefix for the sequence ID')
    parser.add_argument('-v', '--verbose', action='store_true', help='Verbose')
    parser.add_argument('-d', '--debug', action='store_true', help='Debug')
    args = parser.parse_args()

    input_rdr = open(args.input_bed, 'r')\
        if args.input_bed != '-' else sys.stdin
    fa_wtr = open(args.fasta, 'w')\
        if args.fasta is not None and args.fasta != '-' else sys.stdout
    bed_wtr = open(args.bed, 'w') if args.bed is not None else None

    enzyme = digest.expasy_rules.get(args.enzyme, None)

    biotypea = [bt.strip() for biotype in args.biotypes
                for bt in biotype.split(',')]

    twobit = TwoBitFile(args.twobit) if args.twobit else None

    selected_regions = dict()  # chrom:(start, end)
    region_pat = '^(?:chr)?([^:]+)(?::(\d*)(?:-(\d+)([+-])?)?)?'
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

    def filter_by_regions(bed):
        if not selected_regions:
            return True
        ref = re.sub('^(?i)chr', '', bed.chrom)
        if ref not in selected_regions:
            return False
        for reg in selected_regions[ref]:
            (_start, _stop, _strand) = reg
            start = int(_start) if _start else 0
            stop = int(_stop) if _stop else sys.maxint
            if _strand and bed.strand != _strand:
                continue
            if bed.chromEnd >= start and bed.chromStart <= stop:
                return True
        return False

    translations = dict()  # start : end : seq

    def unique_prot(tbed, seq):
        if tbed.chromStart not in translations:
            translations[tbed.chromStart] = dict()
            translations[tbed.chromStart][tbed.chromEnd] = []
            translations[tbed.chromStart][tbed.chromEnd].append(seq)
        elif tbed.chromEnd not in translations[tbed.chromStart]:
            translations[tbed.chromStart][tbed.chromEnd] = []
            translations[tbed.chromStart][tbed.chromEnd].append(seq)
        elif seq not in translations[tbed.chromStart][tbed.chromEnd]:
            translations[tbed.chromStart][tbed.chromEnd].append(seq)
        else:
            return False
        return True

    def get_sequence(chrom, start, end):
        if twobit:
            if chrom in twobit:
                return twobit[chrom][start:end]
            contig = chrom[3:] if chrom.startswith('chr') else 'chr%s' % chrom
            if contig in twobit:
                return twobit[contig][start:end]
        return None

    def write_translation(tbed, prot):
        if args.id_prefix:
            tbed.name = "%s%s" % (args.id_prefix, tbed.name)
        if bed_wtr:
            bed_wtr.write("%s\t%s\n" % (str(tbed), prot))
            bed_wtr.flush()
        location = "chromosome:%s:%s:%s:%s:%s"\
            % (args.reference, tbed.chrom,
               tbed.thickStart, tbed.thickEnd, tbed.strand)
        fa_desc = '%s%s' % (args.fa_sep, location)
        fa_db = '%s%s' % (args.fa_db, args.fa_sep) if args.fa_db else ''
        fa_id = ">%s%s%s\n" % (fa_db, tbed.name, fa_desc)
        fa_wtr.write(fa_id)
        fa_wtr.write(prot)
        fa_wtr.write("\n")
        fa_wtr.flush()

    def translate_bed(bed):
        translate_count = 0
        transcript_id = bed.name
        refprot = None
        if not bed.seq:
            if twobit:
                bed.seq = get_sequence(bed.chrom, bed.chromStart, bed.chromEnd)
            else:
                bed.cdna = get_cdna(transcript_id)
        cdna = bed.get_cdna()
        if cdna is not None:
            cdna_len = len(cdna)
            if args.cds or args.all:
                try:
                    cds = bed.get_cds()
                    if cds:
                        if args.debug:
                            print("cdna:%s" % str(cdna), file=sys.stderr)
                            print("cds: %s" % str(cds), file=sys.stderr)
                        if len(cds) % 3 != 0:
                            cds = cds[:-(len(cds) % 3)]
                        refprot = translate(cds) if cds else None
                except:
                    refprot = None
                if args.cds:
                    if refprot:
                        if args.start_codon:
                            m = refprot.find('M')
                            if m < 0:
                                return 0
                            elif m > 0:
                                bed.trim_cds(m*3)
                                refprot = refprot[m:]
                        stop = refprot.find('*')
                        if stop >= 0:
                            bed.trim_cds((stop - len(refprot)) * 3)
                            refprot = refprot[:stop]
                        if len(refprot) >= args.min_length:
                            write_translation(bed, refprot)
                            return 1
                    return 0
            if args.debug:
                print("%s\n" % (str(bed)), file=sys.stderr)
                print("CDS: %s %d %d" %
                      (bed.strand, bed.cdna_offset_of_pos(bed.thickStart),
                       bed.cdna_offset_of_pos(bed.thickEnd)),
                      file=sys.stderr)
                print("refprot: %s" % str(refprot), file=sys.stderr)
            for offset in range(3):
                seqend = cdna_len - (cdna_len - offset) % 3
                aaseq = translate(cdna[offset:seqend])
                aa_start = 0
                while aa_start < len(aaseq):
                    aa_end = aaseq.find('*', aa_start)
                    if aa_end < 0:
                        aa_end = len(aaseq)
                    prot = aaseq[aa_start:aa_end]
                    if args.start_codon:
                        m = prot.find('M')
                        aa_start += m if m >= 0 else aa_end
                        prot = aaseq[aa_start:aa_end]
                    if enzyme and refprot:
                        frags = digest._cleave(prot, enzyme)
                        for frag in reversed(frags):
                            if frag in refprot:
                                prot = prot[:prot.rfind(frag)]
                            else:
                                break
                    is_cds = refprot and prot in refprot
                    if args.debug:
                        print("is_cds: %s %s" % (str(is_cds), str(prot)),
                              file=sys.stderr)
                    if len(prot) < args.min_length:
                        pass
                    elif not args.all and is_cds:
                        pass
                    else:
                        tstart = aa_start*3+offset
                        tend = aa_end*3+offset
                        prot_acc = "%s_%d_%d" % (transcript_id, tstart, tend)
                        tbed = bed.trim(tstart, tend)
                        if args.all or unique_prot(tbed, prot):
                            translate_count += 1
                            tbed.name = prot_acc
                            write_translation(tbed, prot)
                    aa_start = aa_end + 1
        return translate_count

    if input_rdr:
        translation_count = 0
        transcript_count = 0
        for i, bedline in enumerate(input_rdr):
            try:
                bed = bed_from_line(bedline, ensembl=args.ensembl,
                                    seq_column=args.column)
                if bed is None:
                    continue
                transcript_count += 1
                if bed.biotype and biotypea and bed.biotype not in biotypea:
                    continue
                if filter_by_regions(bed):
                    translation_count += translate_bed(bed)
            except Exception as e:
                print("BED format Error: line %d: %s\n%s"
                      % (i, bedline, e), file=sys.stderr)
                break
        if args.debug or args.verbose:
            print("transcripts: %d\ttranslations: %d"
                  % (transcript_count, translation_count), file=sys.stderr)


if __name__ == "__main__":
    __main__()
