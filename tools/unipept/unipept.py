#!/usr/bin/env python
"""
#
#------------------------------------------------------------------------------
#                         University of Minnesota
#         Copyright 2015, Regents of the University of Minnesota
#------------------------------------------------------------------------------
# Author:
#
#  James E Johnson
#
#------------------------------------------------------------------------------
"""

import json
import logging
import optparse
from optparse import OptionParser
import os
import sys
import re
import urllib
import urllib2
try:
    import xml.etree.cElementTree as ET
except ImportError:
    import xml.etree.ElementTree as ET

def warn_err(msg,exit_code=1):
    sys.stderr.write(msg)
    if exit_code:
      sys.exit(exit_code)

def read_fasta(fp):
    name, seq = None, []
    for line in fp:
        line = line.rstrip()
        if line.startswith(">"):
            if name: yield (name, ''.join(seq))
            name, seq = line, []
        else:
            seq.append(line)
    if name: yield (name, ''.join(seq))

def read_mzid(fp):
  peptides = []
  for event, elem in ET.iterparse(fp):
    if event == 'end':
      if re.search('PeptideSequence',elem.tag):
        peptides.append(elem.text)
  return peptides

def read_pepxml(fp):
  peptides = []
  for event, elem in ET.iterparse(fp):
    if event == 'end':
      if re.search('search_hit',elem.tag):
        peptides.append(elem.get('peptide'))
  return peptides

def __main__():
  #Parse Command Line
  parser = optparse.OptionParser()
  # unipept API
  parser.add_option( '-A', '--api', dest='unipept', default='pept2lca', choices=['pept2lca','pept2taxa','pept2prot'], help='The unipept application: pept2lca, pept2taxa, or pept2prot' )
  # files
  parser.add_option( '-t', '--tabular', dest='tabular', default=None, help='A tabular file that contains a peptide column' )
  parser.add_option( '-c', '--column', dest='column', type='int', default=0, help='The column (zero-based) in the tabular file that contains peptide sequences' )
  parser.add_option( '-f', '--fasta', dest='fasta', default=None, help='A fasta file containing peptide sequences' )
  parser.add_option( '-m', '--mzid', dest='mzid', default=None, help='A mxIdentML file containing peptide sequences' )
  parser.add_option( '-p', '--pepxml', dest='pepxml', default=None, help='A pepxml file containing peptide sequences' )
  # Unipept Flags
  parser.add_option( '-e', '--equate_il', dest='equate_il', action='store_true', default=False, help='isoleucine (I) and leucine (L) are equated when matching tryptic peptides to UniProt records' )
  parser.add_option( '-x', '--extra', dest='extra', action='store_true', default=False, help='return the complete lineage of the taxonomic lowest common ancestor' )
  parser.add_option( '-n', '--names', dest='names', action='store_true', default=False, help='return the names of all ranks in the lineage of the taxonomic lowest common ancestor' )
  # Warn vs Error Flag
  parser.add_option( '-S', '--strict', dest='strict', action='store_true', default=False, help='Print exit on invalid peptide' )
  # outputs
  parser.add_option( '-J', '--json', dest='json', default=None, help='Output file path for json formatted results')
  parser.add_option( '-T', '--tsv', dest='tsv', default=None, help='Output file path for TAB-separated-values (.tsv) formatted results')
  parser.add_option( '-C', '--csv', dest='csv', default=None, help='Output file path for Comma-separated-values (.csv) formatted results')
  parser.add_option( '-M', '--mismatch', dest='mismatch', default=None, help='Output file path for peptide with no matches' )
  (options, args) = parser.parse_args()
  invalid_ec = 2 if options.strict else None
  peptides = []
  pep_pat = '^([ABCDEFGHIKLMNPQRSTVWXYZ]+)$'
  ## Get peptide sequences
  if options.mzid:
    peptides += read_mzid(options.mzid)
  if options.pepxml:
    peptides += read_pepxml(options.pepxml)
  if options.tabular:
    with open(options.tabular) as fp:
      for i,line in enumerate(fp):
        if line.strip() == '' or line.startswith('#'):
          continue
        fields = line.rstrip('\n').split('\t')
        peptide = fields[options.column]
        if not re.match(pep_pat,peptide):
          warn_err('"%s" is not a peptide (line %d column %d of tabular file: %s)\n' % (peptide,i,options.column,options.tabular),exit_code=invalid_ec)
        peptides.append(peptide) 
  if options.fasta:
    with open(options.fasta) as fp:
      for id, peptide in read_fasta(fp):
        if not re.match(pep_pat,peptide):
          warn_err('"%s" is not a peptide (id %s of fasta file: %s)\n' % (peptide,id,options.fasta),exit_code=invalid_ec)
        peptides.append(peptide) 
  if args and len(args) > 0:
    for i,peptide in enumerate(args):
      if not re.match(pep_pat,peptide):
        warn_err('"%s" is not a peptide (arg %d)\n' % (peptide,i),exit_code=invalid_ec)
      peptides.append(peptide) 
  if len(peptides) < 1:
    warn_err("No peptides input!",exit_code=1)
  ## unipept
  post_data = []
  if options.equate_il:
    post_data.append(("equate_il","true"))
  if options.names:
    post_data.append(("extra","true"))
    post_data.append(("names","true"))
  elif options.extra:
    post_data.append(("extra","true"))
  post_data += [('input[]', x) for x in peptides]
  headers = {'Content-Type': 'application/x-www-form-urlencoded',  'Accept': 'application/json'}
  url = 'http://api.unipept.ugent.be/api/v1/%s' % options.unipept
  req = urllib2.Request( url, headers = headers, data = urllib.urlencode(post_data) )
  resp = json.loads( urllib2.urlopen( req ).read() )
  ## output results
  if not (options.mismatch or options.json or options.tsv or options.csv):
    print >> sys.stdout, str(resp)
  if options.mismatch:
    peptides_matched = []
    for i,pdict in enumerate(resp):
      peptides_matched.append(pdict['peptide'])
    with open(options.mismatch,'w') as outputFile:
      for peptide in peptides:
        if not peptide in peptides_matched:
          outputFile.write("%s\n" % peptide)
  if options.json:
    with open(options.json,'w') as outputFile:
      outputFile.write(str(resp))  
  if options.tsv or options.csv:
    # 'pept2lca','pept2taxa','pept2prot'
    pept2lca_column_order = [ 'peptide','superkingdom','kingdom','subkingdom','superphylum','phylum','subphylum','superclass','class_','subclass','infraclass','superorder','order','suborder','infraorder','parvorder','superfamily','family','subfamily','tribe','subtribe','genus','subgenus','species_group','species_subgroup','species','subspecies','varietas','forma' ]
    pept2prot_column_order = [ 'peptide','uniprot_id','taxon_id','taxon_name','ec_references','go_references','refseq_ids','refseq_protein_ids','insdc_ids','insdc_protein_ids']
    column_order = pept2prot_column_order if options.unipept == 'pept2prot' else pept2lca_column_order
    found_keys = set()
    results = []
    for i,pdict in enumerate(resp):
      results.append(pdict)
      found_keys |= set(pdict.keys())
      # print >> sys.stderr, "%s\n%s" % (pdict.keys(),found_keys)
    column_names = []
    column_keys = []
    for col in column_order:
      if col in found_keys:
        column_names.append(col)
        column_keys.append(col)
      elif options.extra or options.names:
        col_id = col+'_id'
        col_name = col+'_name'
        if options.extra:
          if col_id in found_keys:
            column_names.append(col_id)
            column_keys.append(col_id)
        if options.names:
          if col_name in found_keys:
            column_names.append(col)
            column_keys.append(col_name)
      else:
        if col+'_name' in found_keys:
          column_names.append(col)
          column_keys.append(col+'_name')
        elif col+'_id' in found_keys:
          column_names.append(col)
          column_keys.append(col+'_id')
    # print >> sys.stderr, "%s\n%s" % (column_names,column_keys)
    taxa = []
    for i,pdict in enumerate(results):
      vals = [str(pdict[x]) if x in pdict and pdict[x] else '' for x in column_keys]
      taxa.append(vals)
    if options.tsv:
      with open(options.tsv,'w') as outputFile:
        outputFile.write("#%s\n"% '\t'.join(column_names))
        for vals in taxa:
          outputFile.write("%s\n"% '\t'.join(vals))
    if options.csv:
      with open(options.csv,'w') as outputFile:
        outputFile.write("%s\n"% ','.join(column_names))
        for vals in taxa:
          outputFile.write("%s\n"% ','.join(['"%s"' % (v if v else '') for v in vals]))

if __name__ == "__main__" : __main__()
