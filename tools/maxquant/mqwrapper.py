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
arguments = ["--raw_files", "--mzxml_files", "--fasta_files", "--fixed_mods",
             "--var_mods", "--proteases", "--exp_design",
             "--missed_cleavages", "--min_unique_pep", "--mqpar_in",
             "--num_threads", "--output_all", "--mqpar_out",
             "--infile_names", "--mzTab", "--light_mods", "--medium_mods",
             "--heavy_mods", "--version", "--substitution_rx",
             "--min_peptide_len", "--max_peptide_mass", "--lfq_mode",
             "--lfq_min_edges_per_node", "--lfq_avg_edges_per_node",
             "--lfq_min_ratio_count"]

flags = (  # global opts
         "--calc_peak_properties", "--write_mztab",
         "--ibaq", "--ibaq_log_fit",
         "--separate_lfq", "--lfq_stabilize_large_ratios",
         "--lfq_require_msms", "--advanced_site_intensities",
         "--lfq_skip_norm")


txt_output = ("evidence", "msms", "parameters",
              "peptides", "proteinGroups", "allPeptides",
              "libraryMatch", "matchedFeatures",
              "modificationSpecificPeptides", "ms3Scans",
              "msmsScans", "mzRange", "peptideSection", "summary")

arguments += ['--' + el for el in txt_output]

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
    os.link(f, l)

# arguments for mqparam
simple_args = ('missed_cleavages', 'min_unique_pep',
               'num_threads', 'calc_peak_properties',
               'write_mztab', 'min_peptide_len',
               'max_peptide_mass', 'lfq_mode',
               'lfq_min_edges_per_node',
               'lfq_avg_edges_per_node', 'lfq_min_ratio_count',
               'ibaq', 'ibaq_log_fit', 'separate_lfq',
               'lfq_stabilize_large_ratios', 'lfq_require_msms',
               'advanced_site_intensities', 'lfq_skip_norm')

list_args = ('fixed_mods', 'var_mods', 'proteases')

# build mqpar.xml
mqpar_temp = os.path.join(os.getcwd(), 'mqpar.xml')
if args['mqpar_in']:
    mqpar_in = args['mqpar_in']
else:
    # create mqpar template
    subprocess.run(('maxquant', '-c', mqpar_temp))
    mqpar_in = mqpar_temp
mqpar_out = args['mqpar_out'] if args['mqpar_out'] != 'None' else mqpar_temp

exp_design = args['exp_design'] if args['exp_design'] != 'None' else None
m = mqparam.MQParam(mqpar_out, mqpar_in, exp_design,
                    substitution_rx=args['substitution_rx'])
if m.version != args['version']:
    raise Exception('mqpar version is ' + m.version +
                    '. Tool uses version {}.'.format(args['version']))

# modify parameters, interactive mode if no mqpar_in was specified
m.add_infiles([os.path.join(os.getcwd(), name) for name in fnames_with_ext],
              not args['mqpar_in'])
m.add_fasta_files(args['fasta_files'].split(','))

for e in simple_args:
    if args[e]:
        m.set_simple_param(e, args[e])

for e in list_args:
    if args[e]:
        m.set_list_params(e, args[e].split(','))

m.set_silac(args['light_mods'].split(',') if args['light_mods'] else None,
            args['medium_mods'].split(',') if args['medium_mods'] else None,
            args['heavy_mods'].split(',') if args['heavy_mods'] else None)

m.write()

# build and run MaxQuant command
cmd = ['maxquant', mqpar_out]

subprocess.run(cmd, check=True, cwd='./')

# copy results to galaxy database
for el in txt_output:
    destination = args[el]
    source = os.path.join(os.getcwd(), "combined", "txt", "{}.txt".format(el))
    if destination != 'None' and os.path.isfile(source):
        shutil.copy(source, destination)

if args['mzTab'] != 'None':
    source = os.path.join(os.getcwd(), "combined", "txt", "mzTab.mzTab")
    if os.path.isfile(source):
        shutil.copy(source, args['mzTab'])

if args['output_all'] != 'None':
    subprocess.run(('tar', '-zcf', args['output_all'], './combined/txt/'))
