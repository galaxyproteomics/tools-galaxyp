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
import sqlite3 as sqlite
from time import time


from Bio.Seq import reverse_complement, translate


import pysam
from twobitreader import TwoBitFile

from  profmt import PROBAM_DEFAULTS,ProBAM,ProBAMEntry,ProBED,ProBEDEntry


def regex_match(expr, item):
    return re.match(expr, item) is not None


def regex_search(expr, item):
    return re.search(expr, item) is not None


def regex_sub(expr, replace, item):
    return re.sub(expr, replace, item)


def get_connection(sqlitedb_path, addfunctions=True):
    conn = sqlite.connect(sqlitedb_path)
    if addfunctions:
        conn.create_function("re_match", 2, regex_match)
        conn.create_function("re_search", 2, regex_search)
        conn.create_function("re_sub", 3, regex_sub)
    return conn


## Peptide Spectral Match (PSM)s
PSM_QUERY = """\
SELECT 
  pe.dBSequence_ref,
  pe.start,
  pe.end,
  pe.pre,
  pe.post,
  pep.sequence,
  sr.id,
  sr.spectrumTitle,
  si.rank,
  si.chargeState,
  si.calculatedMassToCharge,
  si.experimentalMassToCharge,
  si.peptide_ref
FROM spectrum_identification_results sr 
JOIN spectrum_identification_result_items si ON si.spectrum_identification_result_ref = sr.id
JOIN peptide_evidence pe ON si.peptide_ref = pe.peptide_ref
JOIN peptides pep ON pe.peptide_ref = pep.id
WHERE pe.isDecoy = 'false'
ORDER BY sr.spectrumTitle,si.rank
"""


## Peptide Post Translational Modifications 
PEP_MODS_QUERY = """\
SELECT location, residue, name, modType, '' as "unimod"
FROM peptide_modifications
WHERE peptide_ref = :peptide_ref
ORDER BY location, modType, name
"""


## number of peptides to which the spectrum maps
## spectrum_identification_results => spectrum_identification_result_items -> peptide_evidence 
SPECTRUM_PEPTIDES_QUERY = """\
SELECT count(distinct pep.sequence)
FROM spectrum_identification_results sr
JOIN spectrum_identification_result_items si ON si.spectrum_identification_result_ref = sr.id
JOIN peptide_evidence pe ON si.peptide_ref = pe.peptide_ref
JOIN peptides pep ON pe.peptide_ref = pep.id
WHERE pe.isDecoy = 'false'
AND sr.id = :sr_id
GROUP BY sr.id
"""


## number of genomic locations to which the peptide sequence maps
## uniqueness of the peptide mapping
## peptides => peptide_evidence -> db_sequence -> location
## proteins_by_peptide
PEPTIDE_ACC_QUERY = """\
SELECT 
  pe.dBSequence_ref,
  pe.start,
  pe.end
FROM peptide_evidence pe
JOIN peptides pep ON pe.peptide_ref = pep.id
WHERE pe.isDecoy = 'false'
AND pep.sequence = :sequence
"""


MAP_QUERY = """\
SELECT distinct * 
FROM feature_cds_map 
WHERE name = :acc 
AND :p_start < cds_end 
AND :p_end >= cds_start 
ORDER BY name,cds_start,cds_end
"""


GENOMIC_POS_QUERY = """\
SELECT distinct chrom, CASE WHEN strand = '+' THEN start + :cds_offset - cds_start ELSE end - :cds_offset - cds_start END as "pos"
FROM feature_cds_map
WHERE name = :acc 
AND :cds_offset >= cds_start 
AND :cds_offset < cds_end
"""


FEATURE_QUERY = """\
SELECT distinct seqid,start,end,featuretype,strand,
CAST(frame AS INTEGER) as "frame", CAST(frame AS INTEGER)==:frame as "in_frame", 
CASE WHEN :strand = '+' THEN start - :start ELSE end - :end END as "start_pos",
CASE WHEN :strand = '+' THEN end - :end ELSE start - :start END as "end_pos",
parent as "name"
FROM features JOIN relations ON features.id = relations.child
WHERE seqid = :seqid 
AND parent in (
SELECT id 
FROM features
WHERE seqid = :seqid 
AND featuretype = 'transcript'
AND start <= :tstart AND :tend <= end 
)
AND :end >= start AND :start <= end 
AND featuretype in ('CDS','five_prime_utr','three_prime_utr','transcript')
ORDER BY strand = :strand DESC, featuretype 
"""

##  Use order by to get best matches
##  one_exon     strand, featuretype, contained, inframe, 
##  first_exon   strand, featuretype, contained, end_pos, 
##  middle_exon  strand, featuretype, contained, start_pos, end_pos,
##  last_exon    strand, featuretype, contained, start_pos,

ONLY_EXON_QUERY = FEATURE_QUERY + """,\
start <= :start AND end >= :end DESC,
in_frame DESC, end - start DESC, start DESC, end
"""

FIRST_EXON_QUERY = FEATURE_QUERY + """,\
start <= :start AND end >= :end DESC,
in_frame DESC, abs(end_pos), start DESC, end
"""

MIDDLE_EXON_QUERY = FEATURE_QUERY + """,\
start <= :start AND end >= :end DESC,
in_frame DESC, abs(start_pos), abs(end_pos), start DESC, end
"""

LAST_EXON_QUERY = FEATURE_QUERY + """,\
start <= :start AND end >= :end DESC,
in_frame DESC, abs(start_pos), start DESC, end
"""


def __main__():
    parser = argparse.ArgumentParser(
        description='Generate proBED and proBAM from mz.sqlite')
    parser.add_argument('mzsqlite', help="mz.sqlite converted from mzIdentML")
    parser.add_argument('genomic_mapping_sqlite', help="genomic_mapping.sqlite with feature_cds_map table")
    parser.add_argument(
        '-R', '--genomeReference', default='Unknown',
        help='Genome reference sequence in 2bit format')
    parser.add_argument(
        '-t', '--twobit', default=None,
        help='Genome reference sequence in 2bit format')
    parser.add_argument(
        '-r', '--reads_bam', default=None,
        help='reads alignment bam path')
    parser.add_argument(
        '-g', '--gffutils_sqlite', default=None,
        help='gffutils GTF sqlite DB')
    parser.add_argument(
        '-B', '--probed', default=None,
        help='proBed path')
    parser.add_argument(
        '-s', '--prosam', default=None,
        help='proSAM path')
    parser.add_argument(
        '-b', '--probam', default=None,
        help='proBAM path')
    parser.add_argument(
        '-l', '--limit', type=int, default=None,
        help='limit numbers of PSMs for testing')
    parser.add_argument('-v', '--verbose', action='store_true', help='Verbose')
    parser.add_argument('-d', '--debug', action='store_true', help='Debug')
    args = parser.parse_args()

    def get_sequence(chrom, start, end):
        if twobit:
            if chrom in twobit and 0 <= start < end < len(twobit[chrom]):
                return twobit[chrom][start:end]
            contig = chrom[3:] if chrom.startswith('chr') else 'chr%s' % chrom
            if contig in twobit and 0 <= start < end < len(twobit[contig]):
                return twobit[contig][start:end]
            return ''
        return None

    twobit = TwoBitFile(args.twobit) if args.twobit else None
    samfile = pysam.AlignmentFile(args.reads_bam, "rb" ) if args.reads_bam else None
    seqlens = twobit.sequence_sizes()

    probed = open(args.probed,'w') if args.probed else sys.stdout
    
    gff_cursor = get_connection(args.gffutils_sqlite).cursor() if args.gffutils_sqlite else None
    map_cursor = get_connection(args.genomic_mapping_sqlite).cursor()
    mz_cursor = get_connection(args.mzsqlite).cursor()

    unmapped_accs = set()
    timings = dict()
    def add_time(name,elapsed):
        if name in timings:
            timings[name] += elapsed
        else:
            timings[name] = elapsed

    XG_TYPES = ['N','V','W','J','A','M','C','E','B','O','T','R','I','G','D','U','X','*']
    FT_TYPES = ['CDS','five_prime_utr','three_prime_utr','transcript']
    def get_exon_features(exons):
        efeatures = None
        transcript_features = dict()
        t_start = min(exons[0][2],exons[-1][2])
        t_end = max(exons[0][3],exons[-1][3])
        if gff_cursor:
            ts = time()
            (acc,gc,gs,ge,st,cs,ce) = exons[0]
            ft_params = {"seqid" : str(gc).replace('chr',''), 'strand' : st, 'tstart': t_start, 'tend': t_end}
            efeatures = [None] * len(exons)
            for i,exon in enumerate(exons):
                (acc,gc,gs,ge,st,cs,ce) = exon
                fr = cs % 3
                if args.debug:
                    print('exon:\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s' % (acc,gc,gs,ge,st,cs,ce,fr),file=sys.stderr)
                ft_params = {"seqid" : str(gc).replace('chr',''), "start" : gs + 1, "end" : ge, 'strand' : st, 'frame' : fr, 'tstart': t_start, 'tend': t_end}
                if len(exons) == 1:
                    q = ONLY_EXON_QUERY
                elif i == 0:
                    q = FIRST_EXON_QUERY
                elif len(exons) - i == 1:
                    q = LAST_EXON_QUERY
                else:
                    q = MIDDLE_EXON_QUERY
                features = [f for f in gff_cursor.execute(q,ft_params)]
                transcripts = []
                efeatures[i] = []
                for j,f in enumerate(features):
                    transcript = f[-1]
                    ftype = f[3]
                    if ftype == 'transcript':
                        if i > 0 or efeatures[i]:
                            continue
                    if i == 0:
                        if transcript not in transcript_features:
                            transcript_features[transcript] = [[] for _ in range(len(exons))]
                        transcript_features[transcript][i].append(f)
                        efeatures[i].append(f)
                    else:
                        if transcript in transcript_features:
                            transcript_features[transcript][i].append(f)
                            efeatures[i].append(f)
                        else:
                            del transcript_features[transcript]
                if not efeatures[i]:
                    
                    efeatures[i] = transcripts
                for f in efeatures[i]:
                    (seqid,start,end,featuretype,strand,frame,in_frame,start_offset,end_offset,parent) = f
                    if args.debug:
                        print('feat%d:\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s' % \
                              (i,seqid,start,end,featuretype,strand,frame,str(in_frame) == '1',start_offset,end_offset,parent),file=sys.stderr)
            if args.debug:
                print('fmap:\t%s' % transcript_features,file=sys.stderr)
        return (efeatures,transcript_features)

    def is_structural_variant(exons):
        if len(exons) > 1:
            (acc,gc,gs,ge,st,cs,ce) = exons[0]
            for i in range(1,len(exons)):
                if gc != exons[i][1] or st != exons[i][4]:
                    return True
        return False

    XG_TYPES = ['N','V','W','J','A','M','C','E','B','O','T','R','I','G','D','U','X','*']
    FT_TYPES = ['CDS','five_prime_utr','three_prime_utr','transcript']
    def classify_transcript(exons,transcript_features,ref_prot,peptide):
        etypes = ['*'] * len(exons)
        features = transcript_features[0]
        (acc,gc,gs,ge,st,cs,ce) = exons[0]
        if len(features) == 1:
            (seqid,start,end,featuretype,strand,frame,in_frame,start_offset,end_offset,parent) = features[0]
            if strand == st:
                if featuretype == 'CDS':
                    if start <= gs and ge <= end:
                        if in_frame:
                            if ref_prot == peptide:
                                if len(exons) > 1:
                                    pass
                                return 'N'
                            elif len(ref_prot) != len(peptide):
                                return 'W'
                            else:
                                return 'V'
                        else:
                            return 'O'
                    elif strand == '+' and start <= gs or ge > end:
                        return 'C'
                    elif strand == '-' and start <= gs and ge <= end:
                        return 'C'
                elif featuretype == 'five_prime_utr':
                        return 'E'
                elif featuretype == 'three_prime_utr':
                        return 'B'
                elif featuretype == 'transcript':
                        return 'I'
            else:
                return 'R'
        elif len(features) > 1:
            ftypes = [f[3] for f in features]
            if 'five_prime_utr' in ftypes:
                return 'E'
            elif 'three_prime_utr' in ftypes:
                return 'B'
            else:
                return 'C'
        return '*'    
        
    def classify_peptide(exons,ref_prot,peptide,pep_cds,probam_dict):
        if ref_prot != peptide and samfile:
            try:
                if args.debug:
                    print('name: %s \nref: %s\npep: %s\n' % (scan_name,ref_prot,peptide), file=sys.stderr)
                ts = time()
                for exon in exons:
                   (acc,chrom,start,end,strand,c_start,c_end) = exon
                   a_start = c_start / 3 * 3
                   a_end = c_end / 3 * 3
                   if ref_prot[a_start:a_end] != peptide[a_start:a_end]:
                       pileup = get_exon_pileup(chrom,start,end)
                       for i, (bi,ai,ao) in enumerate([(i,i / 3, i % 3) for i in range(c_start, c_end)]):
                           if ao == 0 or i == 0:
                               if ref_prot[ai] != peptide[ai]:
                                   codon = get_pep_codon(pileup, bi - c_start, peptide[ai], ao)
                                   if args.debug:
                                       print('%d %d %d   %s :  %s %s %s' % (bi,ai,ao,  peptide[ai], str(pep_cds[:bi]), str(codon), str(pep_cds[bi+3:])), file=sys.stderr)
                                   if codon:
                                       pep_cds = pep_cds[:bi] + codon + pep_cds[bi+3:]
                te = time()
                add_time('var_cds',te - ts)
            except Exception as e:
                print('name: %s \nref: %s\npep: %s\n%s\n' % (scan_name,ref_prot,peptide,e), file=sys.stderr)
        probam_dict['XG'] = '*'
        if is_structural_variant(exons): 
            probam_dict['XG'] = 'G'
        else:
            (efeatures,transcript_features) = get_exon_features(exons)
            n = len(exons)
            if efeatures and efeatures[0]:
                for f in efeatures[0]:
                    transcript = f[9]
                    features = transcript_features[transcript]
                    xg = classify_transcript(exons,features,ref_prot,peptide)
                    if xg != '*':
                        probam_dict['XG'] = xg
                        break    
        return pep_cds

    def get_variant_cds(exons,ref_prot,peptide,pep_cds):
        if ref_prot != peptide and samfile:
            try:
                if args.debug:
                    print('name: %s \nref: %s\npep: %s\n' % (scan_name,ref_prot,peptide), file=sys.stderr)
                ts = time()
                for exon in exons:
                   (acc,chrom,start,end,strand,c_start,c_end) = exon
                   a_start = c_start / 3 * 3
                   a_end = c_end / 3 * 3
                   if ref_prot[a_start:a_end] != peptide[a_start:a_end]:
                       pileup = get_exon_pileup(chrom,start,end)
                       for i, (bi,ai,ao) in enumerate([(i,i / 3, i % 3) for i in range(c_start, c_end)]):
                           if ao == 0 or i == 0:
                               if ref_prot[ai] != peptide[ai]:
                                   codon = get_pep_codon(pileup, bi - c_start, peptide[ai], ao)
                                   if args.debug:
                                       print('%d %d %d   %s :  %s %s %s' % (bi,ai,ao,  peptide[ai], str(pep_cds[:bi]), str(codon), str(pep_cds[bi+3:])), file=sys.stderr)
                                   if codon:
                                       pep_cds = pep_cds[:bi] + codon + pep_cds[bi+3:]
                te = time()   
                add_time('var_cds',te - ts)
            except Exception as e:
                print('name: %s \nref: %s\npep: %s\n%s\n' % (scan_name,ref_prot,peptide,e), file=sys.stderr)
        return pep_cds

    def get_mapping(acc,pep_start,pep_end):
        ts = time()
        p_start = (pep_start - 1) * 3
        p_end = pep_end * 3
        map_params = {"acc" : acc, "p_start" : p_start, "p_end" : p_end}
        if args.debug:
            print('%s' % map_params, file=sys.stderr)
        locs = [l for l in map_cursor.execute(MAP_QUERY,map_params)]
        exons = []
        ##       =========	pep
        ##  ---			continue
        ##      ---		trim
        ##          ---		copy
        ##              ---	trim
        ##                 ---  break
        c_end = 0
        for i, (acc,chrom,start,end,strand,cds_start,cds_end) in enumerate(locs):
            if args.debug:
                print('Prot: %s\t%s:%d-%d\t%s\t%d\t%d' % (acc,chrom,start,end,strand,cds_start,cds_end),file=sys.stderr)
            c_start = c_end
            if cds_end < p_start:
                continue
            if cds_start >= p_end:
                break
            if strand == '+':
                if cds_start < p_start:
                    start += p_start - cds_start
                if cds_end > p_end:
                    end -= cds_end - p_end
            else:
                if cds_start < p_start:
                    end -= p_start - cds_start
                if cds_end > p_end:
                    start += cds_end - p_end
            c_end = c_start + abs(end - start)
            if args.debug:
                print('Pep:  %s\t%s:%d-%d\t%s\t%d\t%d' % (acc,chrom,start,end,strand,cds_start,cds_end),file=sys.stderr)
            exons.append([acc,chrom,start,end,strand,c_start,c_end])
        te = time()   
        add_time('get_mapping',te - ts)
        return exons 

    def get_cds(exons):
        ts = time()
        seqs = []
        for i, (acc,chrom,start,end,strand,cds_start,cds_end) in enumerate(exons):
            seq = get_sequence(chrom, min(start,end), max(start,end))
            if strand == '-': 
                seq = reverse_complement(seq)
            seqs.append(seq)
        te = time()   
        add_time('get_cds',te - ts)
        if args.debug:
            print('CDS:  %s' % str(seqs),file=sys.stderr)
        return ''.join(seqs) if seqs else ''

    def genomic_mapping_count(peptide):
        ts = time()
        params = {"sequence" : peptide}
        acc_locs = [l for l in mz_cursor.execute(PEPTIDE_ACC_QUERY,params)]
        te = time()   
        add_time('PEPTIDE_ACC_QUERY',te - ts)
        if acc_locs:
            if len(acc_locs)  == 1:
                return 1
            locations = set()
            for i,acc_loc in enumerate(acc_locs):
                (acc,pep_start,pep_end) = acc_loc            
                if acc in unmapped_accs:
                    continue
                try:
                    add_time('GENOMIC_POS_QUERY_COUNT',1)
                    ts = time()
                    p_start = pep_start * 3
                    p_end = pep_end * 3
                    params = {"acc" : acc, "cds_offset" : p_start}
                    (start_chrom,start_pos) = map_cursor.execute(GENOMIC_POS_QUERY, params).fetchone()
                    params = {"acc" : acc, "cds_offset" : p_end}
                    (end_chrom,end_pos) = map_cursor.execute(GENOMIC_POS_QUERY, params).fetchone()
                    locations.add('%s:%s-%s:%s' % (start_chrom,start_pos,end_chrom,end_pos))
                    te = time()   
                    add_time('GENOMIC_POS_QUERY',te - ts)
                except:
                    unmapped_accs.add(acc)
                    if args.debug:
                        print('Unmapped: %s' % acc, file=sys.stderr)
            return len(locations)
        return -1
        
    def spectrum_peptide_count(spectrum_id):
        ts = time()
        params = {"sr_id" : spectrum_id}
        pep_count = mz_cursor.execute(SPECTRUM_PEPTIDES_QUERY, params).fetchone()[0]
        te = time()   
        add_time('SPECTRUM_PEPTIDES_QUERY',te - ts)
        return pep_count

    def get_exon_pileup(chrom,chromStart,chromEnd):
        cols = []
        for pileupcolumn in samfile.pileup(chrom, chromStart, chromEnd):
            if chromStart <= pileupcolumn.reference_pos <= chromEnd:
                bases = dict()
                col = {'depth' : 0, 'cov' : pileupcolumn.nsegments, 'pos': pileupcolumn.reference_pos, 'bases' : bases}
                for pileupread in pileupcolumn.pileups:
                    if not pileupread.is_del and not pileupread.is_refskip:
                        col['depth'] += 1
                        base = pileupread.alignment.query_sequence[pileupread.query_position]
                        if base not in bases:
                            bases[base] = 1
                        else:
                            bases[base] += 1
                cols.append(col)
        return cols

    codon_map = {"TTT":"F", "TTC":"F", "TTA":"L", "TTG":"L",
                 "TCT":"S", "TCC":"S", "TCA":"S", "TCG":"S",
                 "TAT":"Y", "TAC":"Y", "TAA":"*", "TAG":"*",
                 "TGT":"C", "TGC":"C", "TGA":"*", "TGG":"W",
                 "CTT":"L", "CTC":"L", "CTA":"L", "CTG":"L",
                 "CCT":"P", "CCC":"P", "CCA":"P", "CCG":"P",
                 "CAT":"H", "CAC":"H", "CAA":"Q", "CAG":"Q",
                 "CGT":"R", "CGC":"R", "CGA":"R", "CGG":"R",
                 "ATT":"I", "ATC":"I", "ATA":"I", "ATG":"M",
                 "ACT":"T", "ACC":"T", "ACA":"T", "ACG":"T",
                 "AAT":"N", "AAC":"N", "AAA":"K", "AAG":"K",
                 "AGT":"S", "AGC":"S", "AGA":"R", "AGG":"R",
                 "GTT":"V", "GTC":"V", "GTA":"V", "GTG":"V",
                 "GCT":"A", "GCC":"A", "GCA":"A", "GCG":"A",
                 "GAT":"D", "GAC":"D", "GAA":"E", "GAG":"E",
                 "GGT":"G", "GGC":"G", "GGA":"G", "GGG":"G",}

    aa_codon_map = dict()
    for c,a in codon_map.items():
        aa_codon_map[a] = [c] if a not in aa_codon_map else aa_codon_map[a] + [c]

    aa_na_map =  dict()   # m[aa]{bo : {b1 : [b3]
    for c,a in codon_map.items():
        if a not in aa_na_map:
            aa_na_map[a] = dict()
        d = aa_na_map[a]
        for i in range(3):
            b = c[i]
            if i < 2:
                if b not in d:
                    d[b] = dict() if i < 1 else set()
                d = d[b]
            else:
                d.add(b)

    def get_pep_codon(pileup, idx, aa, ao):
        try:
            ts = time()
            bases = []
            for i in range(3):
                if i < ao:
                    bases.append(list(set([c[i] for c in aa_codon_map[aa]])))
                else:
                    bases.append([b for b, cnt in reversed(sorted(pileup[idx + i]['bases'].iteritems(), key=lambda (k,v): (v,k)))])
                if args.debug:
                    print('%s' % bases,file=sys.stderr)
            for b0 in bases[0]:
                if b0 not in aa_na_map[aa]:
                    continue
                for b1 in bases[1]:
                    if b1 not in aa_na_map[aa][b0]:
                        continue
                    for b2 in bases[2]:
                        if b2 in aa_na_map[aa][b0][b1]:
                            return '%s%s%s' % (b0,b1,b2)
            te = time()   
            add_time('pep_codon',te - ts)
        except Exception as e:
            print("get_pep_codon: %s %s %s %s"
                      % (aa, ao, idx, pileup), file=sys.stderr)
            raise e
        return None  

    def write_probed(chrom,chromStart,chromEnd,strand,blockCount,blockSizes,blockStarts,
                     spectrum,protacc,peptide,uniqueness,genomeReference,score=1000,
                     psmScore='.', fdr='.', mods='.', charge='.',
                     expMassToCharge='.', calcMassToCharge='.',
                     psmRank='.', datasetID='.', uri='.'):
        probed.write('%s\t%d\t%d\t%s\t%d\t%s\t%d\t%d\t%s\t%d\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' % \
            (chrom,chromStart,chromEnd,spectrum,score,strand,chromStart,chromEnd,'0',blockCount,
             ','.join([str(v) for v in blockSizes]),
             ','.join([str(v) for v in blockStarts]),
             protacc,peptide,uniqueness, genomeReference,
             psmScore, fdr, mods, charge, expMassToCharge, calcMassToCharge, psmRank, datasetID, uri))

    def get_genomic_location(exons):
        chrom = exons[0][1]
        strand = exons[0][4]
        pos = [exon[2] for exon in exons] + [exon[3] for exon in exons]
        chromStart = min(pos)
        chromEnd = max(pos)
        blockCount = len(exons)
        blockSizes = [abs(exon[3] - exon[2]) for exon in exons]
        blockStarts = [min(exon[2],exon[3])  - chromStart for exon in exons]
        return (chrom,chromStart,chromEnd,strand,blockCount,blockSizes,blockStarts)

    def get_psm_modifications(peptide_ref):
        mods = []
        ts = time()
        params = {"peptide_ref" : peptide_ref}
        pepmods = [m for m in mz_cursor.execute(PEP_MODS_QUERY, params)]
        if pepmods:
            for (location, residue, name, modType, unimod) in pepmods:
                mods.append('%s-%s' % (location, unimod if unimod else '%s%s' % (name,residue)))
        te = time()
        add_time('PEP_MODS_QUERY',te - ts)
        return ';'.join(mods)

    ## iterate through PSMs
    psm_cursor = get_connection(args.mzsqlite).cursor()
    ts = time()
    psms = psm_cursor.execute(PSM_QUERY)
    te = time()   
    add_time('PSM_QUERY',te - ts)
    proBAM = ProBAM(species=None,assembly=args.genomeReference,seqlens=seqlens,comments=[]) if args.prosam or args.probam else None
    proBED = ProBED(species=None,assembly=args.genomeReference,comments=[]) if args.probed else None
    for i, psm in enumerate(psms):
        probam_dict = PROBAM_DEFAULTS.copy()
        (acc,pep_start,pep_end,aa_pre,aa_post,peptide,spectrum_id,spectrum_title,rank,charge,calcmass,exprmass,pepref) = psm
        scan_name = spectrum_title if spectrum_title else spectrum_id
        if args.debug:
            print('\nPSM: %d\t%s' % (i, '\t'.join([str(v) for v in (acc,pep_start,pep_end,peptide,spectrum_id,scan_name,rank,charge,calcmass,exprmass)])), file=sys.stderr)
        exons = get_mapping(acc,pep_start,pep_end)
        if args.debug:
            print('%s' % exons, file=sys.stderr)
        if not exons:
            continue
        mods = get_psm_modifications(pepref)
        (chrom,chromStart,chromEnd,strand,blockCount,blockSizes,blockStarts) = get_genomic_location(exons)
        ref_cds = get_cds(exons)
        if args.debug:
            print('%s' % ref_cds, file=sys.stderr)
        ref_prot = translate(ref_cds)
        if args.debug:
            print('%s' % ref_prot, file=sys.stderr)
            print('%s' % peptide, file=sys.stderr)
        spectrum_peptides = spectrum_peptide_count(spectrum_id)
        peptide_locations = genomic_mapping_count(peptide)
        if args.debug:
            print('spectrum_peptide_count: %d\tpeptide_location_count: %d' % (spectrum_peptides,peptide_locations), file=sys.stderr)
        uniqueness = 'unique' if peptide_locations == 1 else 'not-unique[unknown]'
        if proBED is not None:
            ts = time()
            proBEDEntry = ProBEDEntry(chrom,chromStart,chromEnd,
                                      '%s_%s' % (acc,scan_name),
                                      1000,strand,
                                      blockCount,blockSizes,blockStarts,
                                      acc,peptide,uniqueness,args.genomeReference,
                                      charge=charge,expMassToCharge=exprmass,calcMassToCharge=calcmass,
                                      mods=mods if mods else '.', psmRank=rank)
            proBED.add_entry(proBEDEntry)
            te = time()   
            add_time('add_probed',te - ts)
        if proBAM is not None:
            if len(ref_prot) != len(peptide):
                pass
                # continue
            ts = time()
            probam_dict['NH'] = peptide_locations
            probam_dict['XO'] = uniqueness 
            probam_dict['XL'] = peptide_locations 
            probam_dict['XP'] = peptide
            probam_dict['YP'] = acc
            probam_dict['XC'] = charge
            probam_dict['XB'] = '%f;%f;%f' % (exprmass - calcmass, exprmass, calcmass)
            probam_dict['XR'] = ref_prot  # ? dbSequence
            probam_dict['YA'] = aa_post
            probam_dict['YB'] = aa_pre
            probam_dict['XM'] = mods if mods else '*'
            flag = 16 if strand == '-' else 0
            if str(rank)!=str(1) and rank!='*' and rank!=[] and rank!="":
                flag += 256
            probam_dict['XF'] = ','.join([str(e[2] % 3) for e in exons])
            ## what if structural variant, need to split into multiple entries
            ## probam_dict['XG'] = peptide_type
            pep_cds = classify_peptide(exons,ref_prot,peptide,ref_cds,probam_dict)
            ## probam_dict['MD'] = peptide
    
            ## FIX  SAM sequence is forward strand
            seq = pep_cds if strand == '+' else reverse_complement(pep_cds)
            ## cigar based on plus strand
            cigar = ''
            if strand == '+':
                blkStarts = blockStarts
                blkSizes = blockSizes
            else:
                blkStarts = [x for x in reversed(blockStarts)]
                blkSizes = [x for x in reversed(blockSizes)]
            for j in range(blockCount):
                if j > 0:
                     intron = blkStarts[j] - (blkStarts[j-1] + blkSizes[j-1])
                     if intron > 0:
                         cigar += '%dN' % intron
                cigar += '%dM' % blkSizes[j]
            proBAMEntry = ProBAMEntry(qname=scan_name, flag=flag, rname=chrom, pos=chromStart+1,
                                      cigar=cigar,seq=seq,optional=probam_dict)
            proBAM.add_entry(proBAMEntry)
            te = time()   
            add_time('add_probam',te - ts)
            if args.debug:
                print('%s' % probam_dict, file=sys.stderr)
        if args.limit and i >= args.limit: 
            break
    if args.probed:
        ts = time()
        with open(args.probed,'w') as fh:
            proBED.write(fh)
        te = time()   
        add_time('write_probed',te - ts)
    if args.prosam or args.probam:
        samfile = args.prosam if args.prosam else 'temp.sam'
        ts = time()
        with open(samfile,'w') as fh:
            proBAM.write(fh)
        te = time()   
        add_time('write_prosam',te - ts)
        if args.probam:
            ts = time()
            bamfile = args.prosam.replace('.sam','.bam')
            pysam.view(samfile, '-b', '-o', args.probam, catch_stdout=False)
            te = time()   
            add_time('write_probam',te - ts)
            pysam.index(args.probam)

    if args.verbose:
        print('\n%s\n' % str(timings), file=sys.stderr)

if __name__ == "__main__":
    __main__()
