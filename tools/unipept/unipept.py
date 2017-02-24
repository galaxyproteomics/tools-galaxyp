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

pept2lca_column_order = ['peptide','taxon_rank','taxon_id','taxon_name']
pept2lca_extra_column_order = ['peptide','superkingdom','kingdom','subkingdom','superphylum','phylum','subphylum','superclass','class','subclass','infraclass','superorder','order','suborder','infraorder','parvorder','superfamily','family','subfamily','tribe','subtribe','genus','subgenus','species_group','species_subgroup','species','subspecies','varietas','forma' ]
pept2lca_all_column_order = pept2lca_column_order + pept2lca_extra_column_order[1:]
pept2prot_column_order = ['peptide','uniprot_id','taxon_id']
pept2prot_extra_column_order = pept2prot_column_order + ['taxon_name','ec_references','go_references','refseq_ids','refseq_protein_ids','insdc_ids','insdc_protein_ids']

def __main__():
  version = '2.0'
  pep_pat = '^([ABCDEFGHIKLMNPQRSTVWXYZ]+)$'

  def read_tabular(filepath,col):
    peptides = []
    with open(filepath) as fp:
      for i,line in enumerate(fp):
        if line.strip() == '' or line.startswith('#'):
          continue
        fields = line.rstrip('\n').split('\t')
        peptide = fields[col]
        if not re.match(pep_pat,peptide):
          warn_err('"%s" is not a peptide (line %d column %d of tabular file: %s)\n' % (peptide,i,col,filepath),exit_code=invalid_ec)
        peptides.append(peptide)
    return peptides

  def get_fasta_entries(fp):
    name, seq = None, []
    for line in fp:
      line = line.rstrip()
      if line.startswith(">"):
        if name: yield (name, ''.join(seq))
        name, seq = line, []
      else:
        seq.append(line)
    if name: yield (name, ''.join(seq))

  def read_fasta(filepath):
    peptides = []
    with open(filepath) as fp:
      for id, peptide in get_fasta_entries(fp):
        if not re.match(pep_pat,peptide):
          warn_err('"%s" is not a peptide (id %s of fasta file: %s)\n' % (peptide,id,filepath),exit_code=invalid_ec)
        peptides.append(peptide)
    return peptides

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

  def best_match(peptide,matches):
    if not matches:
      return None
    elif len(matches) == 1:
      return matches[0].copy()
    else:
      # find the most specific match (peptide is always the first column order field)
      for col in reversed(pept2lca_extra_column_order[1:]):
        col_id = col+"_id" if options.extra else col
        for match in matches:
          if 'taxon_rank' in match and match['taxon_rank'] == col:
            return match.copy()
          if col_id in match and match[col_id]:
            return match.copy()
    return None

  #Parse Command Line
  parser = optparse.OptionParser()
  # unipept API choice
  parser.add_option( '-a', '--api', dest='unipept', default='pept2lca', choices=['pept2lca','pept2taxa','pept2prot'], help='The unipept application: pept2lca, pept2taxa, or pept2prot' )
  # input files
  parser.add_option( '-t', '--tabular', dest='tabular', default=None, help='A tabular file that contains a peptide column' )
  parser.add_option( '-c', '--column', dest='column', type='int', default=0, help='The column (zero-based) in the tabular file that contains peptide sequences' )
  parser.add_option( '-f', '--fasta', dest='fasta', default=None, help='A fasta file containing peptide sequences' )
  parser.add_option( '-m', '--mzid', dest='mzid', default=None, help='A mxIdentML file containing peptide sequences' )
  parser.add_option( '-p', '--pepxml', dest='pepxml', default=None, help='A pepxml file containing peptide sequences' )
  # Unipept Flags
  parser.add_option( '-e', '--equate_il', dest='equate_il', action='store_true', default=False, help='isoleucine (I) and leucine (L) are equated when matching tryptic peptides to UniProt records' )
  parser.add_option( '-x', '--extra', dest='extra', action='store_true', default=False, help='return the complete lineage of the taxonomic lowest common ancestor' )
  parser.add_option( '-n', '--names', dest='names', action='store_true', default=False, help='return the names of all ranks in the lineage of the taxonomic lowest common ancestor' )
  parser.add_option( '-M', '--max_request', dest='max_request', type='int', default=200, help='The maximum number of entries per unipept request' )
  
  # output fields
  parser.add_option( '-A', '--allfields', dest='allfields', action='store_true', default=False, help='inlcude fields: taxon_rank,taxon_id,taxon_name csv and tsv outputs' )
  # Warn vs Error Flag
  parser.add_option( '-S', '--strict', dest='strict', action='store_true', default=False, help='Print exit on invalid peptide' )
  # output files
  parser.add_option( '-J', '--json', dest='json', default=None, help='Output file path for json formatted results')
  parser.add_option( '-T', '--tsv', dest='tsv', default=None, help='Output file path for TAB-separated-values (.tsv) formatted results')
  parser.add_option( '-C', '--csv', dest='csv', default=None, help='Output file path for Comma-separated-values (.csv) formatted results')
  parser.add_option( '-U', '--unmatched', dest='unmatched', default=None, help='Output file path for peptide with no matches' )
  # debug
  parser.add_option( '-d', '--debug', dest='debug', action='store_true', default=False, help='Turning on debugging' )
  parser.add_option( '-v', '--version', dest='version', action='store_true', default=False, help='pring version and exit' )
  (options, args) = parser.parse_args()
  if options.version:
    print >> sys.stdout,"%s" % version
    sys.exit(0)
  invalid_ec = 2 if options.strict else None
  peptides = []
  ## Get peptide sequences
  if options.mzid:
    peptides += read_mzid(options.mzid)
  if options.pepxml:
    peptides += read_pepxml(options.pepxml)
  if options.tabular:
    peptides += read_tabular(options.tabular,options.column) 
  if options.fasta:
    peptides += read_fasta(options.fasta) 
  if args and len(args) > 0:
    for i,peptide in enumerate(args):
      if not re.match(pep_pat,peptide):
        warn_err('"%s" is not a peptide (arg %d)\n' % (peptide,i),exit_code=invalid_ec)
      peptides.append(peptide) 
  if len(peptides) < 1:
    warn_err("No peptides input!",exit_code=1)
  column_order = pept2lca_column_order
  if options.unipept == 'pept2prot':
    column_order = pept2prot_extra_column_order if options.extra else pept2prot_column_order
  else:
    if options.extra or options.names:
      column_order = pept2lca_all_column_order if options.allfields else pept2lca_extra_column_order
    else:
      column_order = pept2lca_column_order
  ## map to tryptic peptides
  pepToParts = {p: re.split("\n", re.sub(r'(?<=[RK])(?=[^P])','\n', p)) for p in peptides}
  partToPeps = {}
  for peptide, parts in pepToParts.iteritems():
    if options.debug: print >> sys.stdout, "peptide: %s\ttryptic: %s\n" % (peptide, parts)
    for part in parts:
      if len(part) > 50:
        warn_err("peptide: %s tryptic fragment len %d > 50 for %s\n" % (peptide,len(part),part),exit_code=None)
      if 5 <= len(part) <= 50:
        partToPeps.setdefault(part,[]).append(peptide)
  trypticPeptides = partToPeps.keys()
  ## unipept
  unipept_resp = []
  idx = range(0,len(trypticPeptides),options.max_request)
  idx.append(len(trypticPeptides))
  for i in range(len(idx)-1):
    post_data = []
    if options.equate_il:
      post_data.append(("equate_il","true"))
    if options.names or options.json:
      post_data.append(("extra","true"))
      post_data.append(("names","true"))
    elif options.extra or options.json:
      post_data.append(("extra","true"))
    post_data += [('input[]', x) for x in trypticPeptides[idx[i]:idx[i+1]]]
    headers = {'Content-Type': 'application/x-www-form-urlencoded',  'Accept': 'application/json'}
    url = 'http://api.unipept.ugent.be/api/v1/%s' % options.unipept
    req = urllib2.Request( url, headers = headers, data = urllib.urlencode(post_data) )
    unipept_resp += json.loads( urllib2.urlopen( req ).read() )
  unmatched_peptides = []
  peptideMatches = []
  if options.debug: print >> sys.stdout,"unipept response: %s\n" % str(unipept_resp)
  if options.unipept == 'pept2prot' or options.unipept == 'pept2taxa':
    dupkey = 'uniprot_id' if options.unipept == 'pept2prot' else 'taxon_id' ## should only keep one of these per input peptide
    ## multiple entries per trypticPeptide for pep2prot or pep2taxa
    mapping = {}
    for match in unipept_resp:
      mapping.setdefault(match['peptide'],[]).append(match)
    for peptide in peptides:
      # Get the intersection of matches to the tryptic parts
      keyToMatch = None
      for part in pepToParts[peptide]:
        if part in mapping:
          temp = {match[dupkey] : match  for match in mapping[part]}
          if keyToMatch:
            dkeys = set(keyToMatch.keys()) - set(temp.keys())
            for k in dkeys:
              del keyToMatch[k]
          else:
            keyToMatch = temp
          ## keyToMatch = keyToMatch.fromkeys([x for x in keyToMatch if x in temp]) if keyToMatch else temp
      if not keyToMatch:
        unmatched_peptides.append(peptide)
      else:
        for key,match in keyToMatch.iteritems():
          match['tryptic_peptide'] = match['peptide']
          match['peptide'] = peptide
          peptideMatches.append(match)
  else:
    ## should be one response per trypticPeptide for pep2lca
    respMap = {v['peptide']:v for v in unipept_resp}
    ## map resp back to peptides
    for peptide in peptides:
      matches = list()
      for part in pepToParts[peptide]:
        if part in respMap:
          matches.append(respMap[part])
      match = best_match(peptide,matches)
      if not match:
        unmatched_peptides.append(peptide)
        longest_tryptic_peptide = sorted(pepToParts[peptide], key=lambda x: len(x))[-1]
        match = {'peptide' : longest_tryptic_peptide}
      match['tryptic_peptide'] = match['peptide']
      match['peptide'] = peptide
      peptideMatches.append(match)
  resp = peptideMatches
  if options.debug: print >> sys.stdout,"\nmapped response: %s\n" % str(resp)
  ## output results
  if not (options.unmatched or options.json or options.tsv or options.csv):
    print >> sys.stdout, str(resp)
  if options.unmatched:
    with open(options.unmatched,'w') as outputFile:
      for peptide in peptides:
        if peptide in unmatched_peptides:
          outputFile.write("%s\n" % peptide)
  if options.json:
    if options.unipept == 'pept2prot':
      with open(options.json,'w') as outputFile:
        outputFile.write(str(resp))
    else:
      found_keys = set()
      for i,pdict in enumerate(resp):
        found_keys |= set(pdict.keys())
      taxa_cols = []
      for col in pept2lca_extra_column_order[-1:0:-1]:
        if col+'_id' in found_keys:
          taxa_cols.append(col)
      id_to_node = dict()
      def get_node(id,name,rank,child,seq):
        if id not in id_to_node:
          data = {'count' : 0, 'self_count' : 0, 'valid_taxon' : 1,  'rank' : rank, 'sequences' : [] }
          node = {'id' : id, 'name' : name, 'children' : [], 'kids': [],'data' : data }
          id_to_node[id] = node
        else:
          node = id_to_node[id]
        node['data']['count'] += 1
        if seq is not None and seq not in node['data']['sequences']:
           node['data']['sequences'].append(seq)
        if child is None:
          node['data']['self_count'] += 1
        elif child['id'] not in node['kids']:
          node['kids'].append(child['id'])
          node['children'].append(child)
        return node
      root = get_node(1,'root','no rank',None,None)   
      for i,pdict in enumerate(resp):
        sequence = pdict.get('peptide',pdict.get('tryptic_peptide',None))
        seq = sequence
        child = None
        for col in taxa_cols:
          col_id = col+'_id'
          if col_id in pdict and pdict.get(col_id): 
            col_name = col if col in found_keys else col+'_name'
            child = get_node(pdict.get(col_id,None),pdict.get(col_name,''),col,child,seq)
            seq = None
        if child:
          get_node(1,'root','no rank',child,None)
      with open(options.json,'w') as outputFile:
        outputFile.write(json.dumps(root))  
  if options.tsv or options.csv:
    # 'pept2lca','pept2taxa','pept2prot'
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
      if vals not in taxa:
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
