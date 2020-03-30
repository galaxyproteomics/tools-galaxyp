#!/usr/bin/env python
"""
#
#------------------------------------------------------------------------------
#                         University of Minnesota
#         Copyright 2014, Regents of the University of Minnesota
#------------------------------------------------------------------------------
# Author:
#
#  James E Johnson
#
#------------------------------------------------------------------------------

Input:  BED file (12 column) + 13th sequence column appended by extract_genomic_dna
Output: Fasta of 3-frame translations of the spliced sequence
"""

import optparse
import os.path
import re
import sys
import tempfile

from Bio.Seq import reverse_complement, transcribe, back_transcribe, translate


class BedEntry(object):
    def __init__(self, line):
        self.line = line
        try:
            fields = line.rstrip('\r\n').split('\t')
            (chrom, chromStart, chromEnd, name, score, strand, thickStart, thickEnd, itemRgb, blockCount, blockSizes, blockStarts) = fields[0:12]
            seq = fields[12] if len(fields) > 12 else None
            self.chrom = chrom
            self.chromStart = int(chromStart)
            self.chromEnd = int(chromEnd)
            self.name = name
            self.score = int(score)
            self.strand = strand
            self.thickStart = int(thickStart)
            self.thickEnd = int(thickEnd)
            self.itemRgb = itemRgb
            self.blockCount = int(blockCount)
            self.blockSizes = [int(x) for x in blockSizes.split(',')]
            self.blockStarts = [int(x) for x in blockStarts.split(',')]
            self.seq = seq
        except Exception as e:
            sys.stderr.write("Unable to read Bed entry %s\n" % e)
            exit(1)

    def __str__(self):
        return '%s\t%d\t%d\t%s\t%d\t%s\t%d\t%d\t%s\t%d\t%s\t%s%s' % (
               self.chrom, self.chromStart, self.chromEnd, self.name, self.score, self.strand, self.thickStart, self.thickEnd, self.itemRgb, self.blockCount,
               ','.join([str(x) for x in self.blockSizes]),
               ','.join([str(x) for x in self.blockStarts]),
               '\t%s' % self.seq if self.seq else '')

    def get_splice_junctions(self):
        splice_juncs = []
        for i in range(self.blockCount - 1):
            splice_junc = "%s:%d_%d" % (self.chrom, self.chromStart + self.blockSizes[i], self.chromStart + self.blockStarts[i + 1])
            splice_juncs.append(splice_junc)
        return splice_juncs

    def get_exon_seqs(self):
        exons = []
        for i in range(self.blockCount):
            # splice_junc = "%s:%d_%d" % (self.chrom, self.chromStart + self.blockSizes[i], self.chromStart + self.blockStarts[i+1])
            exons.append(self.seq[self.blockStarts[i]:self.blockStarts[i] + self.blockSizes[i]])
        if self.strand == '-':  # reverse complement
            exons.reverse()
            for i, s in enumerate(exons):
                exons[i] = reverse_complement(s)
        return exons

    def get_spliced_seq(self):
        seq = ''.join(self.get_exon_seqs())
        return seq

    def get_translation(self, sequence=None):
        translation = None
        seq = sequence if sequence else self.get_spliced_seq()
        if seq:
            seqlen = int(len(seq) / 3) * 3
            if seqlen >= 3:
                translation = translate(seq[:seqlen])
        return translation

    def get_translations(self):
        translations = []
        seq = self.get_spliced_seq()
        if seq:
            for i in range(3):
                translation = self.get_translation(sequence=seq[i:])
                if translation:
                    translations.append(translation)
        return translations

    def get_subrange(self, tstart, tstop):
        """
        (start, end)
        """
        chromStart = self.chromStart
        chromEnd = self.chromEnd
        r = range(self.blockCount)
        if self.strand == '-':
            r = list(r)
            r.reverse()
        bStart = 0
        for x in r:
            bEnd = bStart + self.blockSizes[x]
            if bStart <= tstart < bEnd:
                if self.strand == '+':
                    chromStart = self.chromStart + self.blockStarts[x] + (tstart - bStart)
                else:
                    chromEnd = self.chromStart + self.blockStarts[x] + (tstart - bStart)
            if bStart <= tstop < bEnd:
                if self.strand == '+':
                    chromEnd = self.chromStart + self.blockStarts[x] + (tstop - bStart)
                else:
                    chromStart = self.chromStart + self.blockStarts[x] + self.blockSizes[x] - (tstop - bStart)
            bStart += self.blockSizes[x]
        return(chromStart, chromEnd)

    def get_blocks(self, chromStart, chromEnd):
        """
        get the blocks for sub range
        """
        tblockCount = 0
        tblockSizes = []
        tblockStarts = []
        for x in range(self.blockCount):
            bStart = self.chromStart + self.blockStarts[x]
            bEnd = bStart + self.blockSizes[x]
            if bStart > chromEnd:
                break
            if bEnd < chromStart:
                continue
            cStart = max(chromStart, bStart)
            tblockStarts.append(cStart - chromStart)
            tblockSizes.append(min(chromEnd, bEnd) - cStart)
            tblockCount += 1
            # print >> sys.stderr, "tblockCount: %d  tblockStarts: %s  tblockSizes: %s" % (tblockCount, tblockStarts, tblockSizes)
        return (tblockCount, tblockSizes, tblockStarts)

    def get_filterd_translations(self, untrimmed=False, filtering=True, ignore_left_bp=0, ignore_right_bp=0, debug=False):
        """
        [(start, end, seq, blockCount, blockSizes, blockStarts), (start, end, seq, blockCount, blockSizes, blockStarts), (start, end, seq, blockCount, blockSizes, blockStarts)]
        filter: ignore translation if stop codon in first exon after ignore_left_bp
        """
        translations = [None, None, None, None, None, None]
        seq = self.get_spliced_seq()
        ignore = int((ignore_left_bp if self.strand == '+' else ignore_right_bp) / 3)
        block_sum = sum(self.blockSizes)
        exon_sizes = [x for x in self.blockSizes]
        if self.strand == '-':
            exon_sizes.reverse()
        splice_sites = [int(sum(exon_sizes[:x]) / 3) for x in range(1, len(exon_sizes))]
        if debug:
            sys.stderr.write("splice_sites: %s\n" % splice_sites)
        junc = splice_sites[0] if len(splice_sites) > 0 else exon_sizes[0]
        if seq:
            for i in range(3):
                translation = self.get_translation(sequence=seq[i:])
                if translation:
                    tstart = 0
                    tstop = len(translation)
                    offset = (block_sum - i) % 3
                    if debug:
                        sys.stderr.write("frame: %d\ttstart: %d  tstop: %d  offset: %d\t%s\n" % (i, tstart, tstop, offset, translation))
                    if not untrimmed:
                        tstart = translation.rfind('*', 0, junc) + 1
                        stop = translation.find('*', junc)
                        tstop = stop if stop >= 0 else len(translation)
                    offset = (block_sum - i) % 3
                    trimmed = translation[tstart:tstop]
                    if debug:
                        sys.stderr.write("frame: %d\ttstart: %d  tstop: %d  offset: %d\t%s\n" % (i, tstart, tstop, offset, trimmed))
                    if filtering and tstart > ignore:
                        continue
                    # get genomic locations for start and end
                    if self.strand == '+':
                        chromStart = self.chromStart + i + (tstart * 3)
                        chromEnd = self.chromEnd - offset - (len(translation) - tstop) * 3
                    else:
                        chromStart = self.chromStart + offset + (len(translation) - tstop) * 3
                        chromEnd = self.chromEnd - i - (tstart * 3)
                    # get the blocks for this translation
                    (tblockCount, tblockSizes, tblockStarts) = self.get_blocks(chromStart, chromEnd)
                    translations[i] = (chromStart, chromEnd, trimmed, tblockCount, tblockSizes, tblockStarts)
                    if debug:
                        sys.stderr.write("tblockCount: %d  tblockStarts: %s  tblockSizes: %s\n" % (tblockCount, tblockStarts, tblockSizes))
                    # translations[i] = (chromStart, chromEnd, trimmed, tblockCount, tblockSizes, tblockStarts)
        return translations

    def get_seq_id(self, seqtype='unk:unk', reference='', frame=None):
        """
        # Ensembl fasta ID format
        >ID SEQTYPE:STATUS LOCATION GENE TRANSCRIPT
        >ENSP00000328693 pep:splice chromosome:NCBI35:1:904515:910768:1 gene:ENSG00000158815:transcript:ENST00000328693 gene_biotype:protein_coding transcript_biotype:protein_coding
        """
        frame_name = ''
        chromStart = self.chromStart
        chromEnd = self.chromEnd
        strand = 1 if self.strand == '+' else -1
        if frame is not None:
            block_sum = sum(self.blockSizes)
            offset = (block_sum - frame) % 3
            frame_name = '_' + str(frame + 1)
            if self.strand == '+':
                chromStart += frame
                chromEnd -= offset
            else:
                chromStart += offset
                chromEnd -= frame
        location = "chromosome:%s:%s:%s:%s:%s" % (reference, self.chrom, chromStart, chromEnd, strand)
        seq_id = "%s%s %s %s" % (self.name, frame_name, seqtype, location)
        return seq_id

    def get_line(self, start_offset=0, end_offset=0):
        if start_offset or end_offset:
            s_offset = start_offset if start_offset else 0
            e_offset = end_offset if end_offset else 0
            if s_offset > self.chromStart:
                s_offset = self.chromStart
            chrStart = self.chromStart - s_offset
            chrEnd = self.chromEnd + e_offset
            blkSizes = self.blockSizes
            blkSizes[0] += s_offset
            blkSizes[-1] += e_offset
            blkStarts = self.blockStarts
            for i in range(1, self.blockCount):
                blkStarts[i] += s_offset
            items = [str(x) for x in [self.chrom, chrStart, chrEnd, self.name, self.score, self.strand, self.thickStart, self.thickEnd, self.itemRgb, self.blockCount, ','.join([str(x) for x in blkSizes]), ','.join([str(x) for x in blkStarts])]]
            return '\t'.join(items) + '\n'
        return self.line


def __main__():
    # Parse Command Line
    parser = optparse.OptionParser()
    parser.add_option('-i', '--input', dest='input', help='BED file (tophat junctions.bed) with sequence column added')
    parser.add_option('-o', '--output', dest='output', help='Translations of spliced sequence')
    parser.add_option('-b', '--bed_format', dest='bed_format', action='store_true', default=False, help='Append translations to bed file instead of fasta')
    parser.add_option('-D', '--fa_db', dest='fa_db', default=None, help='Prefix DB identifier for fasta ID line, e.g. generic')
    parser.add_option('-s', '--fa_sep', dest='fa_sep', default='|', help='fasta ID separator defaults to pipe char, e.g. generic|ProtID|description')
    parser.add_option('-B', '--bed', dest='bed', default=None, help='Output a bed file with added 13th column having translation')
    parser.add_option('-G', '--gff3', dest='gff', default=None, help='Output translations to a GFF3 file')
    parser.add_option('-S', '--seqtype', dest='seqtype', default='pep:splice', help='SEQTYPE:STATUS for fasta ID line')
    parser.add_option('-P', '--id_prefix', dest='id_prefix', default='', help='prefix for the sequence ID')
    parser.add_option('-R', '--reference', dest='reference', default=None, help='Genome Reference Name for fasta ID location ')
    parser.add_option('-r', '--refsource', dest='refsource', default=None, help='Source for Genome Reference, e.g. Ensembl, UCSC, or NCBI')
    parser.add_option('-Q', '--score_name', dest='score_name', default=None, help='include in the fasta ID line score_name:score ')
    parser.add_option('-l', '--leading_bp', dest='leading_bp', type='int', default=None, help='leading number of base pairs to ignore when filtering')
    parser.add_option('-t', '--trailing_bp', dest='trailing_bp', type='int', default=None, help='trailing number of base pairs to ignore when filtering')
    parser.add_option('-U', '--unfiltered', dest='filtering', action='store_false', default=True, help='Do NOT filterout translation with stop codon in the first exon')
    parser.add_option('-u', '--untrimmed', dest='untrimmed', action='store_true', default=False, help='Do NOT trim from splice site to stop codon')
    parser.add_option('-L', '--min_length', dest='min_length', type='int', default=None, help='Minimun length (to first stop codon)')
    parser.add_option('-M', '--max_stop_codons', dest='max_stop_codons', type='int', default=None, help='Filter out translations with more than max_stop_codons')
    parser.add_option('-d', '--debug', dest='debug', action='store_true', default=False, help='Turn on wrapper debugging to stdout')
    (options, args) = parser.parse_args()
    # Input files
    if options.input is not None:
        try:
            inputPath = os.path.abspath(options.input)
            inputFile = open(inputPath, 'r')
        except Exception as e:
            sys.stderr.write("failed: %s\n" % e)
            exit(2)
    else:
        inputFile = sys.stdin
    # Output files
    bed_fh = None
    gff_fh = None
    gff_fa_file = None
    gff_fa = None
    outFile = None
    if options.output is None:
        # write to stdout
        outFile = sys.stdout
        if options.gff:
            gff_fa_file = tempfile.NamedTemporaryFile(prefix='gff_fasta_', suffix=".fa", dir=os.getcwd()).name
            gff_fa = open(gff_fa_file, 'w')
    else:
        try:
            outPath = os.path.abspath(options.output)
            outFile = open(outPath, 'w')
        except Exception as e:
            sys.stderr.write("failed: %s\n" % e)
            exit(3)
        if options.gff:
            gff_fa_file = outPath
    if options.bed:
        bed_fh = open(options.bed, 'w')
        bed_fh.write('track name="%s" description="%s" \n' % ('novel_junctioni_translations', 'test'))
    if options.gff:
        gff_fh = open(options.gff, 'w')
        gff_fh.write("##gff-version 3.2.1\n")
        if options.reference:
            gff_fh.write("##genome-build %s %s\n" % (options.refsource if options.refsource else 'unknown', options.reference))
    leading_bp = 0
    trailing_bp = 0
    if options.leading_bp:
        if options.leading_bp >= 0:
            leading_bp = options.leading_bp
        else:
            sys.stderr.write("failed: leading_bp must be positive\n")
            exit(5)
    if options.trailing_bp:
        if options.trailing_bp >= 0:
            trailing_bp = options.trailing_bp
        else:
            sys.stderr.write("failed: trailing_bp must be positive\n")
            exit(5)
    # Scan bed file
    try:
        for i, line in enumerate(inputFile):
            if line.startswith('track'):
                if outFile and options.bed_format:
                    outFile.write(line)
                continue
            entry = BedEntry(line)
            strand = 1 if entry.strand == '+' else -1
            translations = entry.get_translations()
            if options.debug:
                exon_seqs = entry.get_exon_seqs()
                exon_sizes = [len(seq) for seq in exon_seqs]
                splice_sites = [int(sum(exon_sizes[:x]) / 3) for x in range(1, len(exon_sizes))]
                sys.stderr.write("%s\n" % entry.name)
                sys.stderr.write("%s\n" % line.rstrip('\r\n'))
                sys.stderr.write("exons:  %s\n" % exon_seqs)
                sys.stderr.write("%s\n" % splice_sites)
                for i, translation in enumerate(translations):
                    sys.stderr.write("frame %d:  %s\n" % (i + 1, translation))
                    sys.stderr.write("splice:   %s\n" % (''.join(['^' if int(((j * 3) + i) / 3) in splice_sites else '-' for j in range(len(translation))])))
                sys.stderr.write("\n")
            if options.bed_format:
                tx_entry = "%s\t%s\n" % (line.rstrip('\r\n'), '\t'.join(translations))
                outFile.write(tx_entry)
            else:
                translations = entry.get_filterd_translations(untrimmed=options.untrimmed, filtering=options.filtering, ignore_left_bp=leading_bp, ignore_right_bp=trailing_bp, debug=options.debug)
                for i, tx in enumerate(translations):
                    if tx:
                        (chromStart, chromEnd, translation, blockCount, blockSizes, blockStarts) = tx
                        if options.min_length is not None and len(translation) < options.min_length:
                            continue
                        if options.max_stop_codons is not None and translation.count('*') > options.max_stop_codons:
                            continue
                        frame_name = '_%s' % (i + 1)
                        pep_id = "%s%s%s" % (options.id_prefix, entry.name, frame_name)
                        if bed_fh:
                            bed_fh.write('%s\t%d\t%d\t%s\t%d\t%s\t%d\t%d\t%s\t%d\t%s\t%s\t%s\n' % (str(entry.chrom), chromStart, chromEnd, pep_id, entry.score, entry.strand, chromStart, chromEnd, entry.itemRgb, blockCount, ','.join([str(x) for x in blockSizes]), ','.join([str(x) for x in blockStarts]), translation))
                        location = "chromosome:%s:%s:%s:%s:%s" % (options.reference, entry.chrom, chromStart, chromEnd, strand)
                        score = " %s:%s" % (options.score_name, entry.score) if options.score_name else ''
                        seq_description = "%s %s%s" % (options.seqtype, location, score)
                        seq_id = "%s " % pep_id
                        if options.fa_db:
                            seq_id = "%s%s%s%s" % (options.fa_db, options.fa_sep, pep_id, options.fa_sep)
                        fa_id = "%s%s" % (seq_id, seq_description)
                        fa_entry = ">%s\n%s\n" % (fa_id, translation)
                        outFile.write(fa_entry)
                        if gff_fh:
                            if gff_fa:
                                gff_fa.write(fa_entry)
                            gff_fh.write("##sequence-region %s %d %d\n" % (entry.chrom, chromStart + 1, chromEnd - 1))
                            gff_fh.write("%s\t%s\t%s\t%s\t%s\t%s\t%s\t%d\tID=%s\n" % (entry.chrom, 'splice_junc', 'gene', chromStart + 1, chromEnd - 1, entry.score, entry.strand, 0, pep_id))
                            for x in range(blockCount):
                                start = chromStart + blockStarts[x] + 1
                                end = start + blockSizes[x] - 1
                                phase = (3 - sum(blockSizes[:x]) % 3) % 3
                                gff_fh.write("%s\t%s\t%s\t%s\t%s\t%s\t%s\t%d\tParent=%s;ID=%s_%d\n" % (entry.chrom, 'splice_junc', 'CDS', start, end, entry.score, entry.strand, phase, pep_id, pep_id, x))
                            # ##gff-version 3
                            # ##sequence-region 19 1 287484
                            # 19      MassSpec        peptide 282299  287484  10.0    -       0       ID=TEARLSFYSGHSSFGMYCMVFLALYVQ
                            # 19      MassSpec        CDS     287474  287484  .       -       0       Parent=TEARLSFYSGHSSFGMYCMVFLALYVQ;transcript_id=ENST00000269812
                            # 19      MassSpec        CDS     282752  282809  .       -       1       Parent=TEARLSFYSGHSSFGMYCMVFLALYVQ;transcript_id=ENST00000269812
                            # 19      MassSpec        CDS     282299  282310  .       -       0       Parent=TEARLSFYSGHSSFGMYCMVFLALYVQ;transcript_id=ENST00000269812
        if bed_fh:
            bed_fh.close()
        if gff_fh:
            if gff_fa:
                gff_fa.close()
            else:
                outFile.close()
            gff_fa = open(gff_fa_file, 'r')
            gff_fh.write("##FASTA\n")
            for i, line in enumerate(gff_fa):
                gff_fh.write(line)
            gff_fh.close()
    except Exception as e:
        sys.stderr.write("failed: Error reading %s - %s\n" % (options.input if options.input else 'stdin', e))
        raise
        exit(1)


if __name__ == "__main__":
    __main__()
