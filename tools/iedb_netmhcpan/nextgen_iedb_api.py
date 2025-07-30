#!/usr/bin/env python

"""
This file was adapted from the iedb_apy.py file of the iedb_api tool.
It uses the newer "Next-Generation" IEDB API, and is constrained to
the mhci and mhcii tool groups.
"""

import argparse
import json
import os.path
import re
import sys
import time
import urllib.request
from urllib.error import HTTPError

# IEDB tool groups and predictor methods
mhci_methods = ['netmhcpan_el', 'netmhcpan_ba']
mhcii_methods = ['netmhciipan_el', 'netmhciipan_ba']
tool_group_methods = {'mhci': mhci_methods,
                      'mhcii': mhcii_methods}
all_methods = set(mhci_methods + mhcii_methods)

# Values for polling backoff
max_backoff_count = 25
init_poll_sleep = 10
poll_retries = 50
requests_before_backoff = 5


def parse_alleles(allelefile):
    """Returns a dictionary with alleles from input file."""
    alleles = []
    with open(allelefile, 'r') as fh:
        for line in fh:
            allele = line.strip()
            alleles.append(allele)
    return alleles


def parse_sequence_column(sequence_file_lines, col):
    """Sequences may come from a specific column in a TSV file.

    Parse these sequences out while checking each against a regex for validity.
    """
    aapat = '^[ABCDEFGHIKLMNPQRSTVWY]+$'
    sequences = []
    for i, line in enumerate(sequence_file_lines):
        fields = line.split('\t')
        if len(fields) > col:
            seq = re.sub('[_*]', '', fields[col].strip())
            if not re.match(aapat, seq):
                warn_err(f'Line {i}, Not a peptide: {seq}')
            else:
                sequences.append(seq)
        else:
            warn_err('Invalid value for -c/--column')
            break
    return sequences


def iedb_request(req, timeout, retries, error_retry_sleep, response_fn=None, req_data=None):
    """Handles HTTP request and exceptions. Allows for a callback to parse IEDB response."""
    for retry in range(1, retries + 1):
        response = None
        try:
            response = urllib.request.urlopen(req, req_data, timeout=timeout)
        except HTTPError as e:
            warn_err(f'{retry} of {retries} Error connecting to IEDB server. \
                     HTTP status code: {e.code}')
            time.sleep(error_retry_sleep)
        except Exception as e:
            warn_err(f'Error getting results from IEDB server: {e}')
            return None

        if response and response.getcode() == 200:
            # If no callback, return results
            if not response_fn:
                response_string = response.read().decode('utf-8')
                response_json = json.loads(response_string)
                return response_json

            # Retry if response_fn callback deems necessary, i.e. results from job are not ready.
            response_json = response_fn(response, retry)
            if response_json:
                return response_json
        else:
            code = response.getcode() if response else 1
            warn_err(f'Error connecting to IEDB server. HTTP status code: {code}')

    warn_err(f'No successful response from IEDB in {retries} retries')
    return None


def pipeline_request(url, tool_group, sequence_text, alleles, length_range,
                     methods, peptide_shift, timeout=300, retries=3, error_retry_sleep=300):
    """Submits job to IEDB pipeline and polls API until results are ready.

    Returns response JSON from IEDB.
    """

    # Set up input parameters for IEDB NetMHCPan or NetMHCIIPan job
    input_parameters = {
        'alleles': alleles,
        'peptide_length_range': length_range,
        'predictors': [{'type': 'binding', 'method': m} for m in methods],
        'peptide_shift': peptide_shift
    }

    if peptide_shift:
        input_parameters['peptide_shift'] = peptide_shift

    stage = {
        'stage_number': 1,
        'tool_group': tool_group,
        'input_sequence_text': sequence_text,
        'input_parameters': input_parameters
    }

    params = {
        'pipeline_id': "",
        'run_stage_range': [1, 1],
        'stages': [stage]
    }

    req = urllib.request.Request(url, method='POST')
    req_data = json.dumps(params).encode('utf-8')
    req.add_header('Content-Type', 'application/json; charset=utf-8')
    req.add_header('Content-Length', len(req_data))

    # Make an initial request to submit job
    response_json = iedb_request(req, timeout, retries, error_retry_sleep, req_data=req_data)
    if not response_json:
        warn_err('Initial request failed.')
        return None

    # Check response from job submission
    warnings = response_json.get('warnings')
    if warnings and len(warnings) > 0:
        invalid_alleles = False
        for warning in warnings:
            if 'cannot predict binding for allele' in warning:
                warn_err(f"Error: Bad allelle input. {warning}")
                invalid_alleles = True
        if invalid_alleles:
            return None

        warn_err(f'Warnings from IEDB: {warnings}')

    errors = response_json.get('errors')
    if errors:
        warn_err(f'Errors from IEDB: {errors}')
        return None

    results_uri = response_json.get('results_uri')
    if not results_uri:
        warn_err('No results URI provided from IEDB.')
        return None

    # Callback function to rate-limit poll requests
    def poll_response_fn(response, retry):
        response_string = response.read().decode('utf-8')
        response_json = json.loads(response_string)
        if response_json['status'] != 'done':
            if retry == poll_retries:
                warn_err('Job not finished in maximum allowed time.')
            backoff_count = min(retry, max_backoff_count)

            # Double sleep every requests_before_backoff requests
            sleep_duration = init_poll_sleep * 2 ** (backoff_count // requests_before_backoff)
            time.sleep(sleep_duration)
            return None
        return response_json

    # Submit polling for results
    response_json = iedb_request(results_uri, timeout, poll_retries,
                                 error_retry_sleep, response_fn=poll_response_fn)
    if not response_json:
        warn_err('Retrieving results failed.')
    return response_json


def warn_err(msg, exit_code=None):
    sys.stderr.write(f"{msg}\n")
    sys.stderr.flush()
    if exit_code:
        sys.exit(exit_code)


def add_reversed_sequences(file_lines, file_format):
    """Adds a reversed sequence after each input sequence.

    Takes a plain list of sequences, or FASTA file. Each reversed FASTA sequence has
    the same header prefixed with 'reversed_'.
    """
    sequences_with_reversed = []
    if file_format == 'fasta':
        i = 0
        while i < len(file_lines):

            # Validate header from next sequence
            seq_header = file_lines[i]
            if seq_header[0] != '>':
                print('Invalid FASTA. Exiting.', file=sys.stderr)
                sys.exit(1)

            # Aggregate sequence into a single line
            j = i + 1
            seq = ''
            while j < len(file_lines):
                next_line = file_lines[j]
                if next_line[0] == '>':
                    break
                seq = seq + file_lines[j]
                j += 1

            # Add non-reversed sequence
            sequences_with_reversed.append(seq_header)
            sequences_with_reversed.append(seq)

            # Add reversed header and sequence
            rev_header = seq_header.replace('>', '>reversed_')
            sequences_with_reversed.append(rev_header)

            rev_seq = seq[::-1]
            sequences_with_reversed.append(rev_seq)

            # Advance index to what should be the next sequence header
            i = j

    # If not FASTA, should be a simple list of peptides to reverse sequentially
    else:
        for seq in file_lines:

            # Reverse seq
            rev_seq = f'{seq[::-1]}'

            # Add original and reversed sequences
            sequences_with_reversed.append(seq)
            sequences_with_reversed.append(rev_seq)

    return sequences_with_reversed


def __main__():
    # Parse Command Line
    parser = argparse.ArgumentParser()
    parser.add_argument('-T', '--tool-group',
                        dest='tool_group',
                        default='mhci',
                        choices=tool_group_methods.keys(),
                        help='IEDB API Tool Group')
    parser.add_argument('-m', '--method',
                        action="append",
                        required=True,
                        choices=all_methods,
                        help='prediction method')
    parser.add_argument('-A', '--allelefile',
                        required=True,
                        help='File of HLA alleles')
    parser.add_argument('-l', '--lengthrange',
                        help='length range for which to make predictions for alleles')
    parser.add_argument('-P', '--peptide_shift',
                        type=int,
                        default=None,
                        help='Peptide Shift')
    parser.add_argument('-i', '--input',
                        required=True,
                        help='Input file for peptide sequences '
                             + '(fasta or tabular)')
    parser.add_argument('-c', '--column',
                        default=None,
                        help='Zero-indexed peptide column in a tabular input file')
    parser.add_argument('-o', '--output',
                        required=True,
                        help='Output file for query results')
    parser.add_argument('-t', '--timeout',
                        type=int,
                        default=600,
                        help='Seconds to wait for server response')
    parser.add_argument('-r', '--retries',
                        type=int,
                        default=5,
                        help='Number of times to retry failed server query')
    parser.add_argument('-S', '--sleep',
                        type=int,
                        default=300,
                        help='Seconds to wait between failed server query retries')
    parser.add_argument('-R', '--add-reversed',
                        dest='add_reversed',
                        action='store_true',
                        help='Input has every other sequence reversed. Identify in output.')
    args = parser.parse_args()

    allele_string = ','.join(parse_alleles(args.allelefile))

    length_range = [int(i) for i in args.lengthrange.split(',')]

    pipeline_url = 'https://api-nextgen-tools.iedb.org/api/v1/pipeline'

    # If sequences submitted as a file, parse out sequences.
    try:
        with open(args.input) as inf:
            sequence_file_contents = inf.read()
    except Exception as e:
        warn_err(f'Unable to open input file: {e}', exit_code=1)

    sequence_file_lines = sequence_file_contents.splitlines()

    # Pick out sequences if input file has multiple columns,
    # otherwise submit list of sequences as-is.
    if not args.column:
        # IEDB may take FASTA files directly, so input contents as-is
        if args.add_reversed:
            sequence_text = '\n'.join(add_reversed_sequences(sequence_file_lines, 'fasta'))
        else:
            sequence_text = sequence_file_contents
    else:
        sequences = parse_sequence_column(sequence_file_lines, int(args.column))
        if args.add_reversed:
            sequence_text = '\n'.join(add_reversed_sequences(sequences, 'tsv'))
        else:
            sequence_text = '\n'.join(sequences)

    if len(sequence_text) == 0:
        warn_err('Error parsing sequences', exit_code=1)

    # Submit job and return results
    results = pipeline_request(pipeline_url, args.tool_group, sequence_text,
                               allele_string, length_range, args.method,
                               peptide_shift=args.peptide_shift, timeout=args.timeout,
                               retries=args.retries, error_retry_sleep=args.sleep)
    if not results:
        warn_err('Job failed. Exiting.', exit_code=1)

    try:
        peptide_table = [t for t in results['data']['results'] if t['type'] == 'peptide_table'][0]
        peptide_table_data = peptide_table['table_data']
        peptide_table_columns = peptide_table['table_columns']

        # If we reversed peptides prior to IEDB input,
        # find column index of sequence number so we can identify which come from reversed input.
        if args.add_reversed:
            for i, column in enumerate(peptide_table_columns):
                if column['display_name'] == 'seq #':
                    seq_num_index = i
                    break
    except (KeyError, IndexError) as e:
        warn_err(f'Error parsing IEDB results: {e}', exit_code=1)

    output_path = os.path.abspath(args.output)
    with open(output_path, 'w') as output_file:
        # Write column names
        display_names = '\t'.join([c['display_name'] for c in peptide_table_columns] + ['reversed'])
        print(display_names, file=output_file)

        # Write data
        for values in peptide_table_data:
            if args.add_reversed:
                seq_number = values[seq_num_index]
                # Every original input sequence is followed by its reversed sequence,
                # so we know even sequence numbers are reversed.
                reversed_val = str(seq_number % 2 == 0).lower()
            else:
                reversed_val = 'false'
            values = '\t'.join([str(v) for v in values] + [reversed_val])
            print(values, file=output_file)


if __name__ == "__main__":
    __main__()
