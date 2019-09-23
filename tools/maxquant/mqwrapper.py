"""
Run MaxQuant on a modified mqpar.xml.
Use maxquant conda package.
TODO: add support for custom modifications/labels

Authors: Damian Glaetzer <d.glaetzer@mailbox.org>
"""

import argparse
import os
import shutil
import subprocess

import mqparam

# build parser
global_parser = argparse.ArgumentParser()

# input, special outputs and others
other_args = ('infiles',
              'ftype',
              'infile_names',
              'paramGroups'
              'fasta_files',
              'description_parse_rule',
              'identifier_parse_rule',
              'exp_design',
              'output_all',
              'version',
              'substitution_rx')

# result files
output = ('evidence', 'msms', 'parameters',
          'peptides', 'proteinGroups', 'allPeptides',
          'libraryMatch', 'matchedFeatures',
          'modificationSpecificPeptides', 'ms3Scans',
          'msmsScans', 'mzRange', 'peptideSection',
          'summary', 'mqpar', 'mzTab')

# arguments for mqparam
global_flags = ('calcPeakProperties',
                'writeMzTab',
                'ibaq',
                'ibaqLogFit',
                'separateLfq',
                'lfqStabilizeLargeRatios',
                'lfqRequireMsms',
                'advancedSiteIntensities',
                'matchBetweenRuns')

global_simple_args = ('minUniquePeptides',
                      'numThreads',
                      'minPepLen',
                      'maxPeptideMass')

global_arguments = ['--' + el for el in (output
                                         + global_simple_args
                                         + other_args)]

for arg in global_arguments:
    global_parser.add_argument(arg)
for flag in ['--' + el for el in global_flags]:
    global_parser.add_argument(flag, action="store_true")

args = vars(global_parser.parse_args())

# link infile datasets to names with correct extension
# for maxquant to accept them
ftype = args['ftype']
filenames = args['infile_names'].split(';')

cwd = os.getcwd()
files_and_paramgroups = []
for i, pg in enumerate(filenames):
    files_and_paramgroups.append([])
    for f in pg.split(','):
        name = a if a.endswith(ftype) else os.path.splitext(a)[0] + '.' + ftype
        path = os.path.join(cwd, name)
        files_and_paramgroups[i].append(path)

for s, d in zip(args['infiles'], [f for l in files_and_paramgroups for f in l]):
    os.symlink(s, d)

# build mqpar.xml
mqpar = os.path.join(os.getcwd(), 'mqpar.xml')

exp_design = args['exp_design'] if args['exp_design'] != 'None' else None
m = mqparam.MQParam(mqpar, mqpar, exp_design,
                    substitution_rx=args['substitution_rx'])
if m.version != args['version']:
    raise Exception('mqpar version is ' + m.version +
                    '. Tool uses version {}.'.format(args['version']))

# modify parameters
# adding infiles also creates parameter groups
m.add_infiles(files_and_paramgroups)
m.add_fasta_files(args['fasta_files'].split(','),
                  identifier=args['identifier_parse_rule'],
                  description=args['description_parse_rule'])

for e in (global_simple_args + global_flags):
    if args[e]:
        m.set_simple_param(e, args[e])


# parameter group arguments
param_group_flags = ('lfqSkipNorm',)

simple_args = ('maxMissedCleavages',
               'lfq_mode',
               'lfq_min_edges_per_node',
               'lfq_avg_edges_per_node',
               'lfq_min_ratio_count')

silac_args = ('light_mods', 'medium_mods', 'heavy_mods')

list_args = ('fixed_mods', 'var_mods', 'proteases')

pg_arguments = ['--' + el for el in (simle_args + silac_args + list_args)]

param_group_parser = argparse.ArgumentParser()

for arg in pg_arguments:
    param_group_parser.add_argument(arg)
for flag in ['--' + el for el in param_group_flags]:
    param_group_parser.add_argument(flag, action="store_true")
# for isobaric label definitions
param_group_parser.add_argument('--ilabel', action='append')

for i, l in enumerate(args['paramGroups'].split(';')):

    pg_args = vars(param_group_parser.parse_args(l.split(',')))

    for e in list_args:
        if pg_args[e]:
            m[i].set_list_params(e, pg_args[e].split(','))

    for e in param_group_flags + simple_args:
        m[i].set_simple_param(e, pg_args[e])

    for l in pg_args['ilabel']:
        m[i].set_isobaric_label(*l.split('/'))

    if pg_args['light_mods'] or pg_args['medium_mods'] or pg_args['heavy_mods']:
        m.set_silac(pg_args['light_mods'].split(',') if pg_args['light_mods'] else None,
                    pg_args['medium_mods'].split(',') if pg_args['medium_mods'] else None,
                    pg_args['heavy_mods'].split(',') if pg_args['heavy_mods'] else None)

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
