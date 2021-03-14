#!/usr/bin/env python
#
# Author: Praveen Kumar
# University of Minnesota
#
# Get peptide's genomic coordinate from the protein's genomic mapping sqlite file
# (which is derived from the https://toolshed.g2.bx.psu.edu/view/galaxyp/translate_bed/038ecf54cbec)
#
# python peptideGenomicCoordinate.py <peptide_list> <mz_to_sqlite DB> <genomic mapping file DB> <output.bed>
#
import argparse
import sqlite3
import sys


pep_stmt = """\
SELECT dBSequence_ref, start, end, peptide_ref \
FROM peptide_evidence e JOIN peptides p on e.peptide_ref = p.id \
WHERE isDecoy = 'false' AND p.sequence = ?\
"""

map_stmt = """
SELECT name, chrom, start, end, strand, cds_start, cds_end \
FROM feature_cds_map \
WHERE name = ? \
AND cds_end >= ? AND cds_start <= ? \
ORDER BY cds_start\
"""


def main():
    parser = argparse.ArgumentParser(description='BED file for peptides')
    parser.add_argument('peptides_file',
                        metavar='peptides.tabular',
                        type=argparse.FileType('r'),
                        help='List of peptides, one per line')
    parser.add_argument('mz_to_sqlite',
                        metavar='mz.sqlite',
                        help='mz_to_sqlite sqlite database')
    parser.add_argument('genome_mapping',
                        metavar='genome_mapping.sqlite',
                        help='genome_mapping sqlite database')
    parser.add_argument('bed_file',
                        metavar='peptides.bed',
                        type=argparse.FileType('w'),
                        help='BED file of peptide genomic locations')
    parser.add_argument('-a', '--accession',
                        action='store_true',
                        help='Append the accession to the peptide for BED name')
    parser.add_argument('-d', '--debug',
                        action='store_true',
                        help='Debug')
    args = parser.parse_args()

    pconn = sqlite3.connect(args.mz_to_sqlite)
    pc = pconn.cursor()
    mconn = sqlite3.connect(args.genome_mapping)
    mc = mconn.cursor()
    outfh = args.bed_file
    pepfile = args.peptides_file
    for seq in pepfile.readlines():
        seq = seq.strip()
        pc.execute(pep_stmt, (seq,))
        pep_refs = pc.fetchall()
        for pep_ref in pep_refs:
            (acc, pep_start, pep_end, pep_seq) = pep_ref
            cds_start = (pep_start - 1) * 3
            cds_end = pep_end * 3
            if args.debug:
                print('%s\t%s\t%s\t%d\t%d' % (acc, pep_start, pep_end, cds_start, cds_end), file=sys.stdout)
            mc.execute(map_stmt, (acc, cds_start, cds_end))
            exons = mc.fetchall()
            if args.debug:
                print('\n'.join([str(e) for e in exons]), file=sys.stdout)
            if exons:
                chrom = exons[0][1]
                strand = exons[0][4]
                if strand == '+':
                    start = exons[0][2] + cds_start
                    end = exons[-1][2] + cds_end - exons[-1][5]
                    blk_start = []
                    blk_size = []
                    for exon in exons:
                        offset = cds_start if cds_start > exon[5] else 0
                        bstart = exon[2] + offset
                        bsize = min(cds_end, exon[6]) - max(cds_start, exon[5])
                        if args.debug:
                            print('bstart %d\tbsize %d\t %d' % (bstart, bsize, offset), file=sys.stdout)
                        blk_start.append(bstart - start)
                        blk_size.append(bsize)
                else:
                    start = exons[-1][2] + exons[-1][6] - cds_end
                    end = exons[0][3] - cds_start + exons[0][5]
                    blk_start = []
                    blk_size = []
                    for exon in reversed(exons):
                        bstart = exon[2] + exon[6] - min(exon[6], cds_end)
                        bsize = min(cds_end, exon[6]) - max(cds_start, exon[5])
                        # bend = exon[3] - (exon[5] - max(exon[5], cds_start))
                        bend = exon[3] - min(cds_start - exon[5], cds_start)
                        bend = exon[3] - bsize
                        if args.debug:
                            print('bstart %d\tbsize %d\tbend %d' % (bstart, bsize, bend), file=sys.stdout)
                        blk_start.append(bstart - start)
                        blk_size.append(bsize)
                bed_line = [str(chrom), str(start), str(end),
                            '_'.join([seq, acc]) if args.accession else seq,
                            '255', strand,
                            str(start), str(end),
                            '0,0,0',
                            str(len(blk_start)),
                            ','.join([str(b) for b in blk_size]),
                            ','.join([str(b) for b in blk_start])]
                if args.debug:
                    print('\t'.join(bed_line), file=sys.stdout)
                outfh.write('\t'.join(bed_line) + '\n')
    pconn.close()
    mconn.close()
    outfh.close()
    pepfile.close()


if __name__ == '__main__':
    main()
