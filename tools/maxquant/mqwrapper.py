"""
Run MaxQuant on a modified mqpar.xml.
Use maxquant conda package.
TODO: add support for parameter groups
      add reporter ion MS2
      add support for custom modifications/labels

Authors: Damian Glaetzer <d.glaetzer@mailbox.org>

based on the maxquant galaxy tool by John Chilton
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
              'exp_design',
              'output_all',
              'infile_names',
              'version',
              'substitution_rx')

# result files
output = ('evidence', 'msms', 'parameters',
          'peptides', 'proteinGroups', 'allPeptides',
          'libraryMatch', 'matchedFeatures',
          'modificationSpecificPeptides', 'ms3Scans',
          'msmsScans', 'mzRange', 'peptideSection',
          'summary', 'mqpar', 'mzTab')

# ---arguments for mqparam---
# global
global_flags = ('calc_peak_properties',
                'write_mztab',
                'ibaq',
                'ibaq_log_fit',
                'separate_lfq',
                'lfq_stabilize_large_ratios',
                'lfq_require_msms',
                'advanced_site_intensities',
                'match_between_runs')

global_simple_args = ('min_unique_pep',
                      'num_threads',
                      'min_peptide_len',
                      'max_peptide_mass')

# parameter group specific
param_group_flags = ('lfq_skip_norm',)

param_group_simple_args = ('missed_cleavages',
                           'lfq_mode',
                           'lfq_min_edges_per_node',
                           'lfq_avg_edges_per_node',
                           'lfq_min_ratio_count')

param_group_silac_args = ('light_mods', 'medium_mods', 'heavy_mods')

list_args = ('fixed_mods', 'var_mods', 'proteases')

arguments = ['--' + el for el in (output
                                  + global_simple_args
                                  + param_group_simple_args
                                  + list_args
                                  + param_group_silac_args
                                  + other_args)]

flags = ['--' + el for el in global_flags + param_group_flags]

for arg in arguments:
    parser.add_argument(arg)
for flag in flags:
    parser.add_argument(flag, action="store_true")

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
mqpar = os.path.join(os.getcwd(), 'mqpar.xml')

exp_design = args['exp_design'] if args['exp_design'] != 'None' else None
m = mqparam.MQParam(mqpar, mqpar, exp_design,
                    substitution_rx=args['substitution_rx'])
if m.version != args['version']:
    raise Exception('mqpar version is ' + m.version +
                    '. Tool uses version {}.'.format(args['version']))

# modify parameters, interactive mode
m.add_infiles([os.path.join(os.getcwd(), name) for name in fnames_with_ext], True)
m.add_fasta_files(args['fasta_files'].split(','),
                  identifier=args['identifier_parse_rule'],
                  description=args['description_parse_rule'])

for e in (global_simple_args
          + param_group_simple_args
          + global_flags
          + param_group_flags):
    if args[e]:
        m.set_simple_param(e, args[e])

for e in list_args:
    if args[e]:
        m.set_list_params(e, args[e].split(','))

if args['light_mods'] or args['medium_mods'] or args['heavy_mods']:
    m.set_silac(args['light_mods'].split(',') if args['light_mods'] else None,
                args['medium_mods'].split(',') if args['medium_mods'] else None,
                args['heavy_mods'].split(',') if args['heavy_mods'] else None)

m.write()

# run MaxQuant command
subprocess.run(('maxquant', mqpar), check=True, cwd='./')

# copy results to galaxy database
for el in output:
    destination = args[el]
    ext = 'mzTab' if el == 'mzTab' else 'xml' if el == 'mqpar' else 'txt'
    source = os.path.join(os.getcwd(), 'combined', 'txt', '{}.{}'.format(el, ext))
    if destination != 'None' and os.path.isfile(source):
        shutil.copy(source, destination)
