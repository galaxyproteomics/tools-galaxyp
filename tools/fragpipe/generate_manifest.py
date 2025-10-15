#!/usr/bin/env python3

#
# Generates a FragPipe Manifest file.
#

import argparse
import csv

# The three columns for each scanfile are "Experiment, Bioreplicate, and Data type
columns = ('exp', 'bio', 'type')
output_filename = 'fp.manifest'


# Add column values to a list of rows for each scan file.
def add_column(column_type, args, rows):
    nfiles = len(args.scanfiles)

    # Each scan file is numbered 1 through n in column
    if getattr(args, f'{column_type}_consec'):
        vals = range(1, nfiles + 1)

    # All scan files have same value in column
    elif getattr(args, f'{column_type}_assign_all'):
        vals = [getattr(args, f'{column_type}_assign_all')] * nfiles

    # Values are provided for scan files in a comma-delimited list
    elif getattr(args, f'{column_type}_col'):
        vals = getattr(args, f'{column_type}_col').split(',')

    # Otherwise, this column remains empty.
    else:
        vals = [''] * nfiles

    for i, row in enumerate(rows):
        row.append(vals[i])


def main():
    parser = argparse.ArgumentParser()

    # Each column has the same methods for populating
    for prefix in columns:
        parser.add_argument(f'--{prefix}-consec', action='store_true')
        parser.add_argument(f'--{prefix}-assign-all')
        parser.add_argument(f'--{prefix}-col')

    # This script will be called once for each scan group
    parser.add_argument('--append', action='store_true')

    # Scanfile names, which should be identical to history identifiers
    parser.add_argument('scanfiles', nargs='+')

    args = parser.parse_args()

    # Create and populate data structure for tabular output
    rows = [[scanfile] for scanfile in args.scanfiles]
    for column in columns:
        add_column(column, args, rows)

    # Write out manifest file
    mode = 'a' if args.append else 'w'
    with open(output_filename, mode) as outf:
        manifest_writer = csv.writer(outf, delimiter='\t')
        for row in rows:
            manifest_writer.writerow(row)


if __name__ == "__main__":
    main()
