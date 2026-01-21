# -*- coding: utf-8 -*-
#
# Author: Ray W. Sajulga
# 
#

import requests # pipenv requests
import json
import time
import urllib
import sys
import csv
import re
import math
import argparse
from xml.etree import ElementTree as ET
from zipfile import ZipFile
try: #Python 3
    from urllib.request import urlopen
except ImportError: #Python 2
    from urllib2 import urlopen
from io import BytesIO

# initializes blank parameters
chasm_classifier = ''
probed_filename = None
intersected_only = False
vcf_output = None
analysis_type = None

# # Testing Command
# python cravatp_submit.py test-data/Freebayes_two-variants.vcf GRCh38
# test-data/variant.tsv test-data/gene.tsv test-data/noncoding.tsv
# test-data/error.tsv CHASM -—classifier Breast -—proBED
# test-data/MCF7_proBed.bed
parser = argparse.ArgumentParser()
parser.add_argument('cravatInput',help='The filename of the input '
                                       'CRAVAT-formatted tabular file '
                                       '(e.g., VCF)')
parser.add_argument('GRCh', help='The name of the human reference '
                                 'genome used for annotation: '
                                 'GRCh38/hg38 or GRCh37/hg19')
parser.add_argument('variant', help='The filename of the output '
                                     'variant file')
parser.add_argument('gene', help='The filename of the output gene '
                                 'variant report')
parser.add_argument('noncoding', help='The filename of the output '
                                       'non-coding variant report')
parser.add_argument('error', help='The filename of the output error '
                                  'file')
parser.add_argument('analysis', help='The machine-learning algorithm '
                                     'used for CRAVAT annotation (VEST'
                                     ' and/or CHASM)')
parser.add_argument('--classifier', help='The cancer classifier for the'
                                         ' CHASM algorithm')
parser.add_argument('--proBED', help='The filename of the proBED file '
                                     'containing peptides with genomic '
                                     'coordinates')
parser.add_argument('--intersectOnly', help='Specifies whether to '
                                            'analyze only variants '
                                            'intersected between the '
                                            'CRAVAT input and proBED '
                                            'file')
parser.add_argument('--vcfOutput', help='The output filename of the '
                                        'intersected VCF file')

# assigns parsed arguments to appropriate variables
args = parser.parse_args()
input_filename = args.cravatInput
GRCh_build = args.GRCh
output_filename = args.variant
file_3 = args.gene
file_4 = args.noncoding
file_5 = args.error
if args.analysis != 'None':
    analysis_type = args.analysis
if args.classifier:
    chasm_classifier = args.classifier
if args.proBED:
    probed_filename = args.proBED
if args.intersectOnly:
    intersected_only = args.intersectOnly    
if args.vcfOutput:
    vcf_output = args.vcfOutput

if analysis_type and '+' in analysis_type:
    analysis_type = 'CHASM;VEST'

# obtains the transcript's protein sequence using Ensembl API
def getSequence(transcript_id):
    server = 'http://rest.ensembl.org'
    ext = ('/sequence/id/' + transcript_id 
           + '?content-type=text/x-seqxml%2Bxml;'
             'multiple_sequences=1;type=protein')
    req = requests.get(server+ext,
                       headers={ "Content-Type" : "text/plain"})
    
    if not req.ok:
        return None
    
    root = ET.fromstring(req.content)
    for child in root.iter('AAseq'):
        return child.text

# parses the proBED file as a list. 
def loadProBED():
    proBED = []
    with open(probed_filename) as tsvin:
        tsvreader = csv.reader(tsvin, delimiter='\t')
        for i, row in enumerate(tsvreader):
            proBED.append(row)
    return proBED

write_header = True


# Creates an VCF file that only contains variants that overlap with the
# proteogenomic input (proBED) file if the user specifies that they want
# to only include intersected variants or if they want to receive the
# intersected VCF as well.
if probed_filename and (vcf_output or intersected_only == 'true'):
    proBED = loadProBED()
    if not vcf_output:
        vcf_output = 'intersected_input.vcf'
    with open(input_filename) as tsvin, open(vcf_output, 'wb') as tsvout:
        tsvreader = csv.reader(tsvin, delimiter='\t')        
        tsvout = csv.writer(tsvout, delimiter='\t', escapechar=' ',
                            quoting=csv.QUOTE_NONE)

        for row in tsvreader:
            if row == [] or row[0][0] == '#':
                tsvout.writerow(row)
            else:
                genchrom = row[0]
                genpos = int(row[1])

                for peptide in proBED:
                    pepchrom = peptide[0]
                    pepposA = int(peptide[1])
                    pepposB = int(peptide[2])
                    if (genchrom == pepchrom and
                        pepposA <= genpos and
                                   genpos <= pepposB):
                        tsvout.writerow(row)
                        break
if intersected_only == 'true':
    input_filename = vcf_output

# sets up the parameters for submission to the CRAVAT API
parameters = {'email':'rsajulga@umn.edu',
              'hg19': 'on' if GRCh_build == 'GRCh37' else 'off',
              'functionalannotation': 'on',
              'tsvreport' : 'on',
              'mupitinput' : 'on'}
if analysis_type:
    parameters['analyses'] = analysis_type
if chasm_classifier:
    parameters['chasmclassifier'] = chasm_classifier
    
# plugs in params to given URL
submit = requests.post('http://www.cravat.us/CRAVAT/rest/service/submit',
                       files = {'inputfile':open(input_filename)},
                       data = parameters)

# makes the data a json dictionary; takes out only the job ID
jobid = json.loads(submit.text)['jobid']

# loops until we find a status equal to Success, then breaks
while True:
    check = requests.get(
                'http://www.cravat.us/CRAVAT/rest/service/status',
                params = {'jobid' : jobid})
    status = json.loads(check.text)['status']
    resultfileurl = json.loads(check.text)['resultfileurl']
    #out_file.write(str(status) + ', ')
    if status == 'Success':
        #out_file.write('\t' + resultfileurl)
        break
    else:
        time.sleep(2)

# obtains the zipfile created by CRAVAT and loads the variants and VAD
# file for processing
r = requests.get(resultfileurl, stream=True)
url = urlopen(resultfileurl)
zipfile = ZipFile(BytesIO(r.content))
variants = zipfile.open(jobid + '/Variant.Result.tsv').readlines()
vad = zipfile.open(jobid + '/Variant_Additional_Details.Result.tsv').readlines()

# reads and writes the gene, noncoding, and error files
open(file_3, 'wb').write(zipfile.read(jobid + '/Gene_Level_Analysis.Result.tsv'))
open(file_4, 'wb').write(zipfile.read(jobid + '/Variant_Non-coding.Result.tsv'))
open(file_5, 'wb').write(zipfile.read(jobid + '/Input_Errors.Result.tsv'))



if probed_filename and not vcf_output:
    proBED = loadProBED()

if probed_filename:
    with open(output_filename, 'w') as tsvout:
        tsvout = csv.writer(tsvout,
                            delimiter='\t',
                            escapechar=' ',
                            quoting=csv.QUOTE_NONE)
        n = 11 #Index for proteogenomic column start
        reg_seq_change = re.compile('([A-Z]+)(\d+)([A-Z]+)')
        SOtranscripts = re.compile('([A-Z]+[\d\.]+):([A-Z]+\d+[A-Z]+)')
        pep_muts = {}
        pep_map = {}
        rows = []
        for row in vad:
            row = row.decode().split('\t')
            row[-1] = row[-1].replace('\n','')
            if row and row[0] and not row[0].startswith('#'):
                # checks if the row begins with input line
                if row[0].startswith('Input line'):
                    vad_headers = row
                    
                else:
                    # Initially screens through the output Variant
                    # Additional Details to catch mutations on
                    # same peptide region
                    genchrom = row[vad_headers.index('Chromosome')]
                    genpos = int(row[vad_headers.index('Position')])
                    aa_change = row[vad_headers.index('Protein sequence change')]
                    input_line = row[vad_headers.index('Input line')]
                    
                    for peptide in proBED:
                        pepseq = peptide[3]
                        pepchrom = peptide[0]
                        pepposA = int(peptide[1])
                        pepposB = int(peptide[2])
                        if genchrom == pepchrom and pepposA <= genpos and genpos <= pepposB:
                            strand = row[vad_headers.index('Strand')]
                            transcript_strand = row[vad_headers.index('S.O. transcript strand')]

                            # Calculates the position of the variant
                            # amino acid(s) on peptide
                            if transcript_strand == strand:                               
                                aa_peppos = int(math.ceil((genpos - pepposA)/3.0) - 1)
                            if (strand == '-' or transcript_strand == '-'
                                    or aa_peppos >= len(pepseq)):
                                aa_peppos = int(math.floor((pepposB - genpos)/3.0))
                            if pepseq in pep_muts:
                                if aa_change not in pep_muts[pepseq]:
                                    pep_muts[pepseq][aa_change] = [aa_peppos]
                                else:
                                    if aa_peppos not in pep_muts[pepseq][aa_change]:
                                        pep_muts[pepseq][aa_change].append(aa_peppos)
                            else:
                                pep_muts[pepseq] = {aa_change : [aa_peppos]}
                            # Stores the intersect information by mapping
                            # Input Line (CRAVAT output) to peptide sequence.
                            if input_line in pep_map:
                                if pepseq not in pep_map[input_line]:
                                    pep_map[input_line].append(pepseq)
                            else:
                                pep_map[input_line] = [pepseq]
                            # TODO: Need to obtain strand information as
                            # well i.e., positive (+) or negative (-)

                            
with open(output_filename, 'w') as tsvout:
    tsvout = csv.writer(tsvout, delimiter='\t', escapechar='',
                        quoting=csv.QUOTE_NONE)
    headers = []
    duplicate_indices = []
            
    # loops through each row in the Variant Additional Details (VAD) file
    for x, row in enumerate(variants):
        row = row.decode().split('\t')
        row[-1] = row[-1].replace('\n','')
        # sets row_2 equal to the same row in Variant Result (VR) file
        row_2 = vad[x].decode().split('\t')
        row_2[-1] = row_2[-1].replace('\n','')
        
        # checks if row is empty or if the first term contains '#'
        if not row or not row[0] or row[0].startswith('#'):
            if row[0]:
                tsvout.writerow(row)
        else:
            if row[0].startswith('Input line'):
                # goes through each value in the headers list in VAD
                headers = row
                # loops through the Keys in VR
                for i,value in enumerate(row_2):
                    #Checks if the value is already in headers
                    if value in headers:
                        duplicate_indices.append(i)
                        continue
                    #else adds the header to headers
                    else:
                        headers.append(value)
                # adds appropriate headers when proteomic input is supplied
                if probed_filename:
                    headers.insert(n, 'Variant peptide')
                    headers.insert(n, 'Reference peptide')
                tsvout.writerow(headers)
            else:
                cells = []
                # goes through each value in the next list
                for value in row:
                    #adds it to cells
                    cells.append(value)
                # goes through each value from the VR file after position
                # 11 (After it is done repeating from VAD file)
                for i,value in enumerate(row_2):
                    # adds in the rest of the values to cells
                    if i not in duplicate_indices:
                        # Skips the initial 11 columns and the
                        # VEST p-value (already in VR file)
                        cells.append(value)

                # Verifies the peptides intersected previously through
                # sequences obtained from Ensembl's API
                if probed_filename:
                    cells.insert(n,'')
                    cells.insert(n,'')
                    input_line = cells[headers.index('Input line')]
                    if input_line in pep_map:
                        pepseq = pep_map[input_line][0]
                        aa_changes = pep_muts[pepseq]
                        transcript_id = cells[headers.index('S.O. transcript')]
                        ref_fullseq = getSequence(transcript_id)
                        # Checks the other S.O. transcripts if the primary
                        # S.O. transcript has no sequence available
                        if not ref_fullseq:
                            transcripts = cells[headers.index('S.O. all transcripts')]
                            for transcript in transcripts.split(','):
                                if transcript:
                                    mat = SOtranscripts.search(transcript)
                                    ref_fullseq = getSequence(mat.group(1))
                                    if ref_fullseq:
                                        aa_changes = {mat.group(2): [aa_changes.values()[0][0]]}
                                        break
                        # Resubmits the previous transcripts without
                        # extensions if all S.O. transcripts fail to
                        # provide a sequence
                        if not ref_fullseq:
                            transcripts = cells[headers.index('S.O. all transcripts')]
                            for transcript in transcripts.split(','):
                                if transcript:
                                    mat = SOtranscripts.search(transcript)
                                    ref_fullseq = getSequence(mat.group(1).split('.')[0])
                                    if ref_fullseq:
                                        aa_changes = {mat.group(2): [aa_changes.values()[0][0]]}
                                        break
                        if ref_fullseq:
                            # Sorts the amino acid changes
                            positions = {}
                            for aa_change in aa_changes:
                                m = reg_seq_change.search(aa_change)
                                aa_protpos = int(m.group(2))
                                aa_peppos = aa_changes[aa_change][0]
                                aa_startpos = aa_protpos - aa_peppos - 1
                                if aa_startpos in positions:
                                    positions[aa_startpos].append(aa_change)
                                else:
                                    positions[aa_startpos] = [aa_change]
                            # Goes through the sorted categories to mutate the Ensembl peptide
                            # (uses proBED peptide as a reference)
                            for pep_protpos in positions:
                                ref_seq = ref_fullseq[pep_protpos:pep_protpos+len(pepseq)]
                                muts = positions[pep_protpos]
                                options = []
                                mut_seq = ref_seq
                                for mut in muts:
                                    m = reg_seq_change.search(mut)
                                    ref_aa = m.group(1)
                                    mut_pos = int(m.group(2))
                                    alt_aa = m.group(3)
                                    pep_mutpos = mut_pos - pep_protpos - 1
                                    if (ref_seq[pep_mutpos] == ref_aa
                                            and (pepseq[pep_mutpos] == alt_aa
                                            or pepseq[pep_mutpos] == ref_aa)):
                                        if pepseq[pep_mutpos] == ref_aa:
                                            mut_seq = (mut_seq[:pep_mutpos] + ref_aa
                                                       + mut_seq[pep_mutpos+1:])
                                        else:
                                            mut_seq = (mut_seq[:pep_mutpos] + alt_aa
                                                       + mut_seq[pep_mutpos+1:])
                                    else:
                                        break
                                # Adds the mutated peptide and reference peptide if mutated correctly
                                if pepseq == mut_seq:
                                    cells[n+1] = pepseq
                                    cells[n] = ref_seq
                tsvout.writerow(cells)

