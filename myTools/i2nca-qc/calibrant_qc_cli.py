import subprocess

from i2nca.qctools.dependencies import *

from i2nca import report_calibrant_qc

# instance the parser
parser = argparse.ArgumentParser()

# register the positional arguments
parser.add_argument("input_path", help="Path to imzML file.")
parser.add_argument("output", help="Path to output file.")
parser.add_argument("calibrants_path", help="Path to csv file containing annotations of signals to monitor.")


#register optional arguments:
parser.add_argument("--ppm", help="The allowed accuracy cutoff. Given in ppm.")
parser.add_argument("--sample_size", help="Percentage of sample that is plotted in the raw data overview.")

# parse arguments from CLI
args = parser.parse_args()

# parse dataset
I = m2.ImzMLReader(args.input_path)
# report QC
report_calibrant_qc(I, args.output, args.calibrants_path, float(args.ppm), float(args.sample_size))