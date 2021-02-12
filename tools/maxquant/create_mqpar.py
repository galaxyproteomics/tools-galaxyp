"""Create paramter xml file for a specific MaxQuant version from yaml or command line input
and a template parameter file.
"""

import argparse
import os

import yaml
from mqparam import MQParam

parser = argparse.ArgumentParser()

parser.add_argument('--yaml', '-y', help="""Yaml config file. Only those parameters differing
from the template need to be specified.""")

parser.add_argument('--exp_design', '-e', help="Experimental design template as it is created by the MaxQuant GUI.")

parser.add_argument('template', help="Template Parameter File.")

parser.add_argument('--mqpar_out', '-o', help="Output file, will be ./mqpar.xml if omitted.")

parser.add_argument('--substitution_rx', '-s', help="""Regular expression for filename substitution.
Necessary for usage in the Galaxy tool. Can usually be ignored.""")

parser.add_argument('--version', '-v', help="""A version number. Raises exception if it doesn't
match the MaxQuant version of the template. For usage in the Galaxy tool.""")

# in case numThreads is a environment variable, otherwise it can be specified in the yaml file as well
parser.add_argument('--num_threads', '-t', help="Number of threads to specify in mqpar.")
args = parser.parse_args()

# edit file names, working dir is unknown at the time of galaxy tool configfile creation
if args.yaml:
    with open(args.yaml) as f:
        conf_dict = yaml.safe_load(f.read())

        for n, pg in enumerate(conf_dict['paramGroups']):
            for num, fl in enumerate(pg['files']):
                if not fl.startswith('/'):
                    conf_dict['paramGroups'][n]['files'][num] = os.path.join(os.getcwd(), fl)
    with open('yaml', 'w') as f:
        yaml.safe_dump(conf_dict, stream=f)
        args.yaml = 'yaml'

kwargs = dict(yaml=args.yaml)
if args.substitution_rx:
    kwargs['substitution_rx'] = args.substitution_rx
mqparam = MQParam(args.template, args.exp_design, **kwargs)
if args.version and mqparam.version != args.version:
    raise Exception('mqpar version is ' + mqparam.version + '. Tool uses version {}.'.format(args.version))
mqparam.set_simple_param('numThreads', args.num_threads)

mqparam.write(args.mqpar_out if args.mqpar_out else 'mqpar.xml')
