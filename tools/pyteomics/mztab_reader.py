#!/usr/bin/env python

import argparse
import os

import pandas as pd
from pyteomics.mztab import MzTab


def read_mztab(input_path, output_path):
    """
    Read and process mztab file
    """
    mztab = MzTab(input_path)
    mtd = pd.DataFrame.from_dict(mztab.metadata, orient='index')
    mtd.to_csv(os.path.join(output_path, "mtd.tsv"), sep="\t")
    for name, tab in mztab:
        if not tab.empty:
            tab.to_csv(os.path.join(output_path, f"{name.lower()}.tsv"), sep="\t")
        else:
            with open(os.path.join(output_path, f"{name.lower()}.tsv"), "w"):
                pass


if __name__ == "__main__":
    # Create the parser
    my_parser = argparse.ArgumentParser(description='List of paths')
    # Add the arguments
    my_parser.add_argument('--path_in',
                           metavar='path',
                           type=str,
                           required=True,
                           help='the path of input .mztab file')
    my_parser.add_argument('--path_out',
                           metavar='path',
                           type=str,
                           default=os.getcwd(),
                           help='the path of folder for output .tsv file')

    # Execute parse_args()
    args = my_parser.parse_args()

    read_mztab(args.path_in, args.path_out)
