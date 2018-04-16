#!/usr/bin/env python
"""
#
#------------------------------------------------------------------------------
#                         University of Minnesota
#         Copyright 2018, Regents of the University of Minnesota
#------------------------------------------------------------------------------
# Author:
#
#  James E Johnson
#
#------------------------------------------------------------------------------
"""

import sys,re
from operator import itemgetter, attrgetter
from twobitreader import TwoBitFile


PROBAM_TAGS = ['NH', 'XO', 'XL', 'XP', 'YP', 'XF', 'XI', 'XB', 'XR', 'YB', 'YA', 'XS', 'XQ', 'XC', 'XA', 'XM', 'XN', 'XT', 'XE', 'XG', 'XU']


PROBAM_TYTPES = {
    'NH' : 'i', #number of genomic locations to which the peptide sequence maps
    'XO' : 'Z', #uniqueness of the peptide mapping
    'XL' : 'i', #number of peptides to which the spectrum maps
    'XP' : 'Z', #peptide sequence
    'YP' : 'Z', #Protein accession ID from the original search result
    'XF' : 'Z', #Reading frame of the peptide (0, 1, 2)
    'XI' : 'f', #Peptide intensity
    'XB' : 'Z', #massdiff; experimental mass; calculated mass massdiff can be calculated by experimental mass - calculated mass. If any number is unavailable, the value should be left blank (such as 0.01;;).
    'XR' : 'Z', #reference peptide sequence
    'YB' : 'Z', #Preceding amino acids (2 AA, B stands for before).
    'YA' : 'Z', #Following amino acids (2 AA, A stands for after).
    'XS' : 'f', #PSM score
    'XQ' : 'f', #PSM FDR (i.e. q-value or 1-PEP).
    'XC' : 'i', #peptide charge
    'XA' : 'i', #Whether the peptide is annotated 0:yes; 1:parially unknown; 2:totally unknown;
    'XM' : 'Z', #Modifications
    'XN' : 'i', #Number of missed cleavages in the peptide (XP)
    'XT' : 'i', #Enzyme specificity
    'XE' : 'i', #Enzyme used in the experiment
    'XG' : 'A', #Peptide type
    'XU' : 'Z', #URI
}


PROBAM_DEFAULTS = {
    'NH' : -1, #number of genomic locations to which the peptide sequence maps
    'XO' : '*', #uniqueness of the peptide mapping
    'XL' : -1, #number of peptides to which the spectrum maps
    'XP' : '*', #peptide sequence
    'YP' : '*', #Protein accession ID from the original search result
    'XF' : '*', #Reading frame of the peptide (0, 1, 2)
    'XI' : -1, #Peptide intensity
    'XB' : '*', #massdiff; experimental mass; calculated mass massdiff can be calculated by experimental mass - calculated mass. If any number is unavailable, the value should be left blank (such as 0.01;;).
    'XR' : '*', #reference peptide sequence
    'YB' : '*', #Preceding amino acids (2 AA, B stands for before).
    'YA' : '*', #Following amino acids (2 AA, A stands for after).
    'XS' : -1, #PSM score
    'XQ' : -1, #PSM FDR (i.e. q-value or 1-PEP).
    'XC' : -1, #peptide charge
    'XA' : -1, #Whether the peptide is annotated 0:yes; 1:parially unknown; 2:totally unknown;
    'XM' : '*', #Modifications
    'XN' : -1, #Number of missed cleavages in the peptide (XP)
    'XT' : -1, #Enzyme specificity
    'XE' : -1, #Enzyme used in the experiment
    'XG' : '*', #Peptide type
    'XU' : '*', #URI
}

def cmp_alphanumeric(s1,s2):
    if s1 == s2:
        return 0
    a1 = re.findall("\d+|[a-zA-Z]+",s1)
    a2 = re.findall("\d+|[a-zA-Z]+",s2)
    for i in range(min(len(a1),len(a2))):
        if a1[i] == a2[i]:
            continue
        if a1[i].isdigit() and a2[i].isdigit():
            return int(a1[i]) - int(a2[i])
        return 1 if a1[i] >    a2[i] else -1
    return len(a1) - len(a2)


def sort_chrom_names(names):
    rnames = sorted(names,cmp=cmp_alphanumeric)
    if 'chrM' in rnames:
        rnames.remove('chrM')
        rnames.insert(0,'chrM')
    if 'MT' in rnames:
        rnames.remove('MT')
        rnames.append('MT')
    return rnames


def as_int_list(obj):
    if obj is None:
        return None
    if isinstance(obj, list):
        return [int(x) for x in obj]
    elif isinstance(obj, str):
        return [int(x) for x in obj.split(',')]
    else:  # python2 unicode?
        return [int(x) for x in str(obj).split(',')]


class ProBEDEntry (object): 
    def __init__(self, chrom, chromStart, chromEnd, name, score, strand, 
                 blockCount, blockSizes, blockStarts, 
                 protacc, peptide, uniqueness, genomeReference,
                 psmScore='.',  fdr='.',  mods='.',  charge='.', 
                 expMassToCharge='.',  calcMassToCharge='.', 
                 psmRank='.',  datasetID='.',  uri='.'):
        self.chrom = chrom
        self.chromStart = int(chromStart)
        self.chromEnd = int(chromEnd)
        self.name = name
        self.score = int(score) if score is not None else 0
        self.strand = '-' if str(strand).startswith('-') else '+'
        self.thickStart = self.chromStart
        self.thickEnd = self.chromEnd
        self.itemRgb = '0'
        self.blockCount = int(blockCount)
        self.blockSizes = as_int_list(blockSizes)
        self.blockStarts = as_int_list(blockStarts)
        self.protacc = protacc
        self.peptide = peptide
        self.uniqueness = uniqueness
        self.genomeReference = genomeReference
        self.psmScore = psmScore
        self.fdr = fdr
        self.mods = mods
        self.charge = charge
        self.expMassToCharge = expMassToCharge
        self.calcMassToCharge = calcMassToCharge
        self.psmRank = psmRank
        self.datasetID = datasetID
        self.uri = uri

    def __str__(self):
        return '%s\t%d\t%d\t%s\t%d\t%s\t%d\t%d\t%s\t%d\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' % \
            (self.chrom, self.chromStart, self.chromEnd,
             self.name, self.score, self.strand,
             self.thickStart, self.thickEnd, self.itemRgb,
             self.blockCount, 
             ','.join([str(x) for x in self.blockSizes]),
             ','.join([str(x) for x in self.blockStarts]),
             self.protacc, self.peptide, self.uniqueness,
             self.genomeReference,
             self.psmScore, self.fdr, self.mods,
             self.charge, self.expMassToCharge, self.calcMassToCharge,
             self.psmRank, self.datasetID, self.uri)


class ProBED ( object ): 
    def __init__(self,species=None,assembly=None,comments=[]):
        self.species = species
        self.assembly = assembly
        self.comments = comments
        self.entries = dict()
    
    def add_entry(self,entry):
        if not entry.chrom in self.entries:
            self.entries[entry.chrom] = []
        self.entries[entry.chrom].append(entry)

    def write(self,fh):
        rnames = sort_chrom_names(self.entries.keys())
        for sn in rnames:
            if sn not in self.entries:
                continue
            for pbe in sorted(self.entries[sn], key=attrgetter('chromStart','chromEnd')):
                fh.write(str(pbe))


class ProBAMEntry (object): 
    def __init__(self, qname='', flag=0, rname='', pos=0, mapq=255, cigar='', rnext='*', pnext='0', tlen='0', seq='*', qual='*', optional=PROBAM_DEFAULTS):
        self.qname = qname
        self.flag = flag
        self.rname = rname
        self.pos = pos
        self.mapq = mapq 
        self.cigar = cigar
        self.rnext = rnext
        self.pnext = pnext
        self.tlen = tlen
        self.seq = seq
        self.qual = qual 
        self.optional = optional
    def __str__(self):
        opt_cols = '\t%s' % '\t'.join(['%s:%s:%s' % (t,PROBAM_TYTPES[t],self.optional[t]) for t in PROBAM_TAGS]) if self.optional else ''
        return '%s\t%d\t%s\t%d\t%d\t%s\t%s\t%s\t%s\t%s\t%s%s' % (
            self.qname,self.flag,self.rname,self.pos,self.mapq,self.cigar,
            str(self.rnext) if self.rnext else '',
            str(self.pnext) if self.pnext else '',
            str(self.tlen) if self.tlen else '',
            self.seq,
            self.qual, opt_cols)
    def add_optional(self,tag,value):
        self.optional[tag] = value

    
class ProBAM ( object ): 
    def __init__(self,species=None,assembly=None,seqlens={},comments=[]):
        self.species = species
        self.assembly = assembly
        self.seqlens = seqlens    
        self.comments = comments
        self.entries = dict()
        self.opt_columns = set()
        self.rg = []
    
    def add_entry(self,pb_entry):
        if not pb_entry.rname in self.entries:
            self.entries[pb_entry.rname] = []
        self.entries[pb_entry.rname].append(pb_entry)
        if pb_entry.optional:
            self.opt_columns | set(pb_entry.optional.keys())

    def add_entry_from_bed(self,bed_entry,optional=dict()):
        if bed_entry.pep:
            optional['XP:Z'] = bed_entry.pep    
        qname=bed_entry.name
        flag = 0 if bed_entry.strand == '+' else 16
        rname = bed_entry.chrom
        pos = bed_entry.chromStart + 1
        cigar = bed_entry.get_cigar()
        seq = bed_entry.get_spliced_seq(strand='+') if bed_entry.seq else '*'
        pb_entry = ProBAMEntry(qname=qname, flag=flag, rname=rname, pos=pos,cigar=cigar,seq=seq,optional=optional)
        self.add_entry(pb_entry)

    def write(self,fh):
        fh.write('@HD	VN:1.0	SO:coordinate\n')
        rnames = sort_chrom_names(self.seqlens.keys())
        for sn in rnames:
            fh.write('@SQ\tSN:%s\tLN:%d\n' % (sn,self.seqlens[sn]))
        for rg in self.rg:
            fh.write('@RG\tID:%s\n' % (rg))
        fh.write('@PG\tID:SampleSpecificGenerator\n')
        for comment in self.comments:
            fh.write('@CO\t%s\n' % comment)
        for sn in rnames:
            if sn not in self.entries:
                continue
            for pbe in sorted(self.entries[sn], key=attrgetter('pos')):
                fh.write('%s\n' % str(pbe))
