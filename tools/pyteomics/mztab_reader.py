#!/usr/bin/env python

import argparse
import os

import pandas as pd
from pyteomics.mztab import MzTab


def read_mztab(input_path, output_path):
    """
    Read mztab file
    """
    mztab = MzTab(input_path)
    if mztab.variant == 'P':
        return read_mztab_p(mztab, output_path)
    elif mztab.variant == 'M':
        return read_mztab_m(mztab, output_path)


def read_mztab_p(mztab, output_path):
    """
    Processing mztab "P"
    """
    mtd = pd.DataFrame.from_dict(mztab.metadata, orient='index')
    mtd.to_csv(os.path.join(output_path, "mtd.tsv"), sep="\t")
    prt = mztab.protein_table
    prt.to_csv(os.path.join(output_path, "prt.tsv"), sep="\t")
    pep = mztab.peptide_table
    pep.to_csv(os.path.join(output_path, "pep.tsv"), sep="\t")
    psm = mztab.spectrum_match_table
    psm.to_csv(os.path.join(output_path, "psm.tsv"), sep="\t")
    sml = mztab.small_molecule_table
    sml.to_csv(os.path.join(output_path, "sml.tsv"), sep="\t")


def read_mztab_m(mztab, output_path):
    """
    Processing mztab "M"
    """
    mtd = pd.DataFrame.from_dict(mztab.metadata, orient='index')
    mtd.to_csv(os.path.join(output_path, "mtd.tsv"), sep="\t")
    sml = mztab.small_molecule_table
    sml.to_csv(os.path.join(output_path, "sml.tsv"), sep="\t")
    smf = mztab.small_molecule_feature_table
    smf.to_csv(os.path.join(output_path, "smf.tsv"), sep="\t")
    sme = mztab.small_molecule_evidence_table
    sme.to_csv(os.path.join(output_path, "sme.tsv"), sep="\t")


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
