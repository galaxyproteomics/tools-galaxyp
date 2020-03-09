"Modify a given mqpar.xml to run Galaxy MaxQuant with it."

import argparse
import os

from mqparam import MQParam

parser = argparse.ArgumentParser()

arguments = ('--infiles',
             '--version',
             '--num_threads',
             '--substitution_rx',
             '--fasta_files',
             '--description_parse_rule',
             '--identifier_parse_rule',
             'mqpar')

for arg in arguments:
    parser.add_argument(arg)

args = parser.parse_args()

mqpar_out = os.path.join(os.getcwd(), 'mqpar.xml')
infiles = [os.path.join(os.getcwd(), f) for f in args.infiles]
print("preparing mqpar file...")
mqparam = MQParam(args.mqpar, None, substitution_rx=args['substitution_rx'])
print("checking version...")
if mqparam.version != args['version']:
    raise Exception('mqpar version is ' + m.version +
                    '. Tool uses version {}.'.format(args['version']))
print("translating infile names...")
mqparam.translate(infiles)
print("adding fasta files...")
mqparam.add_fasta_files(args.fasta_files.split(',')
                  identifier=args['identifier_parse_rule'],
                  description=args['description_parse_rule'])
print("setting numThreds parameter...")
mqparam.set_simple_param('numThreads', args.num_threads)
print("writing mqpar file...")
mqparam.write(args.mqpar_out if args.mqpar_out else 'mqpar.xml')
