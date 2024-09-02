
import subprocess

from i2nca.qctools.dependencies import *

from i2nca import combine_datasets_imzml

# instance the parser
parser = argparse.ArgumentParser()

# register positional arguments
parser.add_argument("output", help="Path to output file.")

parser.add_argument("input_paths", help="Paths to imzML files.", type=str, nargs="+")

# register optinal arguments
parser.add_argument("--nor", help="Normalization method", default="None", type=str)
parser.add_argument("--pad", help="Padding distance", default=10, type=int)
parser.add_argument("--col", help="Nr of Columns in joined file", default=2, type=int)
parser.add_argument("--pol", help="Polarity overwriting", default="None", type=str)

# parse arguments from CLI
args = parser.parse_args()

# cut the file into different regions
combine_datasets_imzml(args.input_paths,
                       args.output,
                       args.nor,
                       args.pad,
                       args.col,
                       args.pol)