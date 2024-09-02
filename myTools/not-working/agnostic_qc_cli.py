import subprocess

from i2nca.qctools.dependencies import *

from i2nca import report_agnostic_qc


# instance the parser
parser = argparse.ArgumentParser()

# register the positional arguments
parser.add_argument("input_path", help="Path to imzML file.")

#register optional arguments
parser.add_argument("output", help="Path to output file.")

# parse arguments from CLI
args = parser.parse_args()

# parse dataset
I = m2.ImzMLReader(args.input_path)
# report QC
report_agnostic_qc(I, args.output)