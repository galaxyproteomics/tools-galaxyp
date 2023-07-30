#!/usr/bin/env python
"""
based on https://github.com/kinestetika/Calisp/blob/master/benchmarking/sip%20benchmarking.ipynb
"""

import argparse
import os

import pandas as pd


def load_calisp_data(filename):

    # (1) load data
    if os.path.isdir(filename):
        file_data = []
        for f in os.listdir(filename):
            if not f.endswith(".feather"):
                continue
            f = os.path.join(filename, f)
            file_data.append(pd.read_feather(f))
            base, _ = os.path.splitext(f)
            file_data[-1].to_csv(f"{base}.tsv", sep="\t")
        data = pd.concat(file_data)
    else:
        data = pd.read_feather(filename)
        base, _ = os.path.splitext(filename)
        data.to_csv(f"{base}.tsv", sep="\t")


parser = argparse.ArgumentParser(description='feather2tsv')
parser.add_argument('--calisp_output', required=True, help='feather file')
args = parser.parse_args()

data = load_calisp_data(args.calisp_output)
