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
"""

"""
Input: list of protein_accessions, peptide_sequence
       GFF3 with fasta 
Output: GFF3 of peptides

Filter: Must cross splice boundary
  
"""

import sys,re,os.path
import tempfile
import optparse
from optparse import OptionParser
from Bio.Seq import reverse_complement, transcribe, back_transcribe, translate

class BedEntry( object ):
  def __init__(self, line):
    self.line = line
    try:
      fields = line.rstrip('\r\n').split('\t')
      (chrom,chromStart,chromEnd,name,score,strand,thickStart,thickEnd,itemRgb,blockCount,blockSizes,blockStarts) = fields[0:12]
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
    except Exception, e:
      print >> sys.stderr, "Unable to read Bed entry" % e
      exit(1)
  def __str__(self):
    return '%s\t%d\t%d\t%s\t%d\t%s\t%d\t%d\t%s\t%d\t%s\t%s%s' % (
      self.chrom, self.chromStart, self.chromEnd, self.name, self.score, self.strand, self.thickStart, self.thickEnd, self.itemRgb, self.blockCount, 
      ','.join([str(x) for x in self.blockSizes]), 
      ','.join([str(x) for x in self.blockStarts]), 
      '\t%s' % self.seq if self.seq else '')
  def get_splice_junctions(self): 
    splice_juncs = []
    for i in range(self.blockCount  - 1):
      splice_junc = "%s:%d_%d" % (self.chrom, self.chromStart + self.blockSizes[i], self.chromStart + self.blockStarts[i+1])
      splice_juncs.append(splice_junc)
    return splice_juncs
  def get_exon_seqs(self):
    exons = []
    for i in range(self.blockCount):
      # splice_junc = "%s:%d_%d" % (self.chrom, self.chromStart + self.blockSizes[i], self.chromStart + self.blockStarts[i+1])
      exons.append(self.seq[self.blockStarts[i]:self.blockStarts[i] + self.blockSizes[i]])
    if self.strand == '-':  #reverse complement
      exons.reverse()
      for i,s in enumerate(exons):
        exons[i] = reverse_complement(s)
    return exons
  def get_spliced_seq(self):
    seq = ''.join(self.get_exon_seqs())
    return seq
  def get_translation(self,sequence=None):
    translation = None
    seq = sequence if sequence else self.get_spliced_seq()
    if seq:
      seqlen = len(seq) / 3 * 3;
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
  ## (start,end)
  def get_subrange(self,tstart,tstop):
    chromStart = self.chromStart
    chromEnd = self.chromEnd
    r = range(self.blockCount)
    if self.strand == '-':
      r.reverse()
    bStart = 0
    for x in r:
      bEnd = bStart + self.blockSizes[x]
      ## print >> sys.stderr, "%d chromStart: %d  chromEnd: %s  bStart: %s  bEnd: %d" % (x,chromStart,chromEnd,bStart,bEnd)
      if bStart <= tstart < bEnd:
        if self.strand == '+':
          chromStart = self.chromStart + self.blockStarts[x] + (tstart - bStart)
        else:
          chromEnd = self.chromStart + self.blockStarts[x] + self.blockSizes[x] - (tstart - bStart)
      if bStart <= tstop < bEnd:
        if self.strand == '+':
          chromEnd = self.chromStart + self.blockStarts[x] + (tstop - bStart)
        else:
          chromStart = self.chromStart + self.blockStarts[x] + self.blockSizes[x] - (tstop - bStart)
      bStart += self.blockSizes[x]
    return(chromStart,chromEnd)
  #get the blocks for sub range
  def get_blocks(self,chromStart,chromEnd):
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
      cStart = max(chromStart,bStart)
      tblockStarts.append(cStart - chromStart)
      tblockSizes.append(min(chromEnd,bEnd) - cStart)
      tblockCount += 1
      print >> sys.stderr, "tblockCount: %d  tblockStarts: %s  tblockSizes: %s" % (tblockCount,tblockStarts,tblockSizes)
    return (tblockCount,tblockSizes,tblockStarts)
    
  ## [[start,end,seq,blockCount,blockSizes,blockStarts],[start,end,seq,blockCount,blockSizes,blockStarts],[start,end,seq,blockCount,blockSizes,blockStarts]]
  ## filter: ignore translation if stop codon in first exon after ignore_left_bp
  def get_filterd_translations(self,untrimmed=False,filtering=True,ignore_left_bp=0,ignore_right_bp=0):
    translations = [None,None,None,None,None,None]
    seq = self.get_spliced_seq()
    ignore = (ignore_left_bp if self.strand == '+' else ignore_right_bp) / 3
    block_sum = sum(self.blockSizes)
    exon_sizes = self.blockSizes
    if self.strand == '-':
      exon_sizes.reverse()
    splice_sites = [sum(exon_sizes[:x]) / 3 for x in range(1,len(exon_sizes))]
    print >> sys.stderr, "splice_sites: %s" % splice_sites
    junc = splice_sites[0] if len(splice_sites) > 0 else exon_sizes[0]
    if seq:
      for i in range(3):
        translation = self.get_translation(sequence=seq[i:])
        if translation:
          tstart = 0
          tstop = len(translation)
          if not untrimmed:
            tstart = translation.rfind('*',0,junc) + 1
            stop = translation.find('*',junc)
            tstop = stop if stop >= 0 else len(translation)
          if filtering and tstart > ignore:
            continue
          trimmed = translation[tstart:tstop]
          #get genomic locations for start and end 
          offset = (block_sum - i) % 3
          print >> sys.stderr, "tstart: %d  tstop: %d  offset: %d" % (tstart,tstop,offset)
          if self.strand == '+':
            chromStart = self.chromStart + i + (tstart * 3)
            chromEnd = self.chromEnd - offset - (len(translation) - tstop) * 3
          else:
            chromStart = self.chromStart + offset + (len(translation) - tstop) * 3
            chromEnd = self.chromEnd - i - (tstart * 3)
          #get the blocks for this translation
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
            cStart = max(chromStart,bStart)
            tblockStarts.append(cStart - chromStart)
            tblockSizes.append(min(chromEnd,bEnd) - cStart)
            tblockCount += 1
          print >> sys.stderr, "tblockCount: %d  tblockStarts: %s  tblockSizes: %s" % (tblockCount,tblockStarts,tblockSizes)
          translations[i] = [chromStart,chromEnd,trimmed,tblockCount,tblockSizes,tblockStarts]
    return translations
  def get_seq_id(self,seqtype='unk:unk',reference='',frame=None):
    ## Ensembl fasta ID format
    # >ID SEQTYPE:STATUS LOCATION GENE TRANSCRIPT
    # >ENSP00000328693 pep:splice chromosome:NCBI35:1:904515:910768:1 gene:ENSG00000158815:transcript:ENST00000328693 gene_biotype:protein_coding transcript_biotype:protein_coding
    frame_name = ''
    chromStart = self.chromStart
    chromEnd = self.chromEnd
    strand = 1 if self.strand == '+' else -1
    if frame != None:
      block_sum = sum(self.blockSizes)
      offset = (block_sum - frame) % 3
      frame_name = '_' + str(frame + 1)
      if self.strand == '+':
        chromStart += frame
        chromEnd -= offset
      else:
        chromStart += offset
        chromEnd -= frame
    location = "chromosome:%s:%s:%s:%s:%s" % (reference,self.chrom,chromStart,chromEnd,strand)
    seq_id = "%s%s %s %s" % (self.name,frame_name,seqtype,location)
    return seq_id
  def get_line(self, start_offset = 0, end_offset = 0):
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
      for i in range(1,self.blockCount):
        blkStarts[i] += s_offset
      items = [str(x) for x in [self.chrom,chrStart,chrEnd,self.name,self.score,self.strand,self.thickStart,self.thickEnd,self.itemRgb,self.blockCount,','.join([str(x) for x in blkSizes]),','.join([str(x) for x in blkStarts])]]
      return '\t'.join(items) + '\n'
    return self.line

def __main__():
  #Parse Command Line
  parser = optparse.OptionParser()
  parser.add_option( '-t', '--translated_bed', dest='translated_bed', default=None, help='A bed file with added 13th column having a translation'  )
  parser.add_option( '-i', '--input', dest='input', default=None, help='Tabular file with peptide_sequence column' )
  parser.add_option( '-p', '--peptide_column', type='int', dest='peptide_column', default=1, help='column ordinal with peptide sequence' )
  parser.add_option( '-n', '--name_column', type='int', dest='name_column', default=2, help='column ordinal with protein name' )
  parser.add_option( '-s', '--start_column', type='int', dest='start_column', default=None, help='column with peptide start position in protein' )
  parser.add_option( '-B', '--bed', dest='bed', default=None, help='Output a bed file with added 13th column having translation'  )
  ## parser.add_option( '-G', '--gff3', dest='gff', default=None, help='Output translations to a GFF3 file'  )
  ## parser.add_option( '-f', '--fasta', dest='fasta', default=None, help='Protein fasta'  )
  parser.add_option( '-T', '--gffTags', dest='gffTags', action='store_true', default=False, help='Add #gffTags to bed output for IGV'  )
  parser.add_option( '-d', '--debug', dest='debug', action='store_true', default=False, help='Turn on wrapper debugging to stderr'  )
  (options, args) = parser.parse_args()
  # Input files
  if options.input != None:
    try:
      inputPath = os.path.abspath(options.input)
      inputFile = open(inputPath, 'r')
    except Exception, e:
      print >> sys.stderr, "failed: %s" % e
      exit(2)
  else:
    inputFile = sys.stdin
  inputBed = None
  if options.translated_bed != None:
    inputBed = open(os.path.abspath(options.translated_bed),'r')
  peptide_column = options.peptide_column - 1
  name_column = options.name_column - 1 if options.name_column else None 
  start_column = options.start_column - 1 if options.start_column else None 
  # Read in peptides
  # peps[prot_name] = [seq]
  prot_peps = dict()
  unassigned_peps = set()
  try:
    for i, line in enumerate( inputFile ):
      ## print >> sys.stderr, "%3d\t%s" % (i,line)
      if line.startswith('#'):
        continue
      fields = line.rstrip('\r\n').split('\t')
      ## print >> sys.stderr, "%3d\t%s" % (i,fields)
      if peptide_column < len(fields): 
        peptide = fields[peptide_column]
        prot_name = fields[name_column] if name_column is not None and name_column < len(fields) else None
        if prot_name:
          offset = fields[start_column] if start_column is not None and start_column < len(fields) else -1
          if prot_name not in prot_peps:
            prot_peps[prot_name] = dict()
          prot_peps[prot_name][peptide] = offset
        else:
          unassigned_peps.add(peptide)  
    if options.debug:
      print >> sys.stderr, "prot_peps: %s" % prot_peps
      print >> sys.stderr, "unassigned_peps: %s" % unassigned_peps
  except Exception, e:
    print >> sys.stderr, "failed: Error reading %s - %s" % (options.input if options.input else 'stdin',e)
    exit(1)
  # Output files
  bed_fh = None
  ## gff_fh = None
  ## gff_fa_file = None
  gff_fa = None
  outFile = None
  if options.bed:
    bed_fh = open(options.bed,'w')
    bed_fh.write('track name="%s" type=bedDetail description="%s" \n' % ('novel_junction_peptides','test'))
    if options.gffTags:
      bed_fh.write('#gffTags\n')
  ## if options.gff:
  ##   gff_fh = open(options.gff,'w')
  ##   gff_fh.write("##gff-version 3.2.1\n")
  ##   if options.reference:
  ##    gff_fh.write("##genome-build %s %s\n" % (options.refsource if options.refsource else 'unknown', options.reference))
  try:
    for i, line in enumerate( inputBed ):
      ## print >> sys.stderr, "%3d:\t%s" % (i,line)
      if line.startswith('track'):
        continue
      entry = BedEntry(line)
      if entry.name in prot_peps:
        for (peptide,offset) in prot_peps[entry.name].iteritems():
          if offset < 0:
            offset = entry.seq.find(peptide)
            if options.debug:
              print >> sys.stderr, "%s\t%s\t%d\t%s\n" % (entry.name, peptide,offset,entry.seq)
          if offset >= 0:
            tstart = offset * 3
            tstop = tstart + len(peptide) * 3
            if options.debug:
              print >> sys.stderr, "%d\t%d\t%d" % (offset,tstart,tstop)
            (pepStart,pepEnd) = entry.get_subrange(tstart,tstop)
            if options.debug:
              print >> sys.stderr, "%d\t%d\t%d" % (offset,pepStart,pepEnd)
            if bed_fh:
              entry.thickStart = pepStart
              entry.thickEnd = pepEnd
              bedfields = str(entry).split('\t')
              if options.gffTags:
                bedfields[3] = "ID=%s;Name=%s" % (entry.name,peptide) 
              bed_fh.write("%s\t%s\t%s\n" % ('\t'.join(bedfields[:12]),peptide,entry.seq))
  except Exception, e:
    print >> sys.stderr, "failed: Error reading %s - %s" % (options.input if options.input else 'stdin',e)

if __name__ == "__main__" : __main__()

