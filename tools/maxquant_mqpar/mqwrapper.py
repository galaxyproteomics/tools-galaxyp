"""
Run MaxQuant on a modified mqpar.xml.
Use maxquant conda package.
TODO: add support for parameter groups

Authors: Damian Glaetzer <d.glaetzer@mailbox.org>

based on the maxquant galaxy tool by John Chilton:
https://github.com/galaxyproteomics/tools-galaxyp/tree/master/tools/maxquant
"""

import argparse
import os
import shutil
import subprocess

import mqparam

# build parser
parser = argparse.ArgumentParser()

# input, special outputs and others
other_args = ('raw_files',
              'mzxml_files',
              'fasta_files',
              'description_parse_rule',
              'identifier_parse_rule',
              'mqpar_in',
              'output_all',
              'infile_names',
              'version',
              'substitution_rx')

# txt result files
output = ('evidence', 'msms', 'parameters',
          'peptides', 'proteinGroups', 'allPeptides',
          'libraryMatch', 'matchedFeatures',
          'modificationSpecificPeptides', 'ms3Scans',
          'msmsScans', 'mzRange', 'peptideSection',
          'summary', 'mqpar', 'mzTab')

global_simple_args = ('num_threads',)

arguments = ['--' + el for el in (output
                                  + other_args
                                  + global_simple_args)]

for arg in arguments:
    parser.add_argument(arg)

args = vars(parser.parse_args())

# link infile datasets to names with correct extension
# for maxquant to accept them
files = (args['raw_files'] if args['raw_files']
         else args['mzxml_files']).split(',')
ftype = ".thermo.raw" if args['raw_files'] else ".mzXML"
filenames = args['infile_names'].split(',')
fnames_with_ext = [(a if a.endswith(ftype)
                    else os.path.splitext(a)[0] + ftype)
                   for a in filenames]

for f, l in zip(files, fnames_with_ext):
    os.symlink(f, l)

# build mqpar.xml
mqpar_out = os.path.join(os.getcwd(), 'mqpar.xml')
mqpar_in = args['mqpar_in']
exp_design = None
m = mqparam.MQParam(mqpar_out, mqpar_in, exp_design,
                    substitution_rx=args['substitution_rx'])
if m.version != args['version']:
    raise Exception('mqpar version is ' + m.version +
                    '. Tool uses version {}.'.format(args['version']))

# modify parameters, non-interactive mode
m.add_infiles([os.path.join(os.getcwd(), name) for name in fnames_with_ext], False)
m.add_fasta_files(args['fasta_files'].split(','),
                  identifier=args['identifier_parse_rule'],
                  description=args['description_parse_rule'])

m.write()

subprocess.run(('maxquant', mqpar_out), check=True, cwd='./')

# copy results to galaxy database
for el in output:
    destination = args[el]
    ext = 'mzTab' if el == 'mzTab' else 'xml' if el == 'mqpar' else 'txt'
    source = os.path.join(os.getcwd(), 'combined', 'txt', '{}.{}'.format(el, ext))
    if destination != 'None' and os.path.isfile(source):
        shutil.copy(source, destination)
