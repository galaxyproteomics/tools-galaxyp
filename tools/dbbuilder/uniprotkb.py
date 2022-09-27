#!/usr/bin/env python

import argparse
import sys

import requests

uniprotkb_url = 'https://rest.uniprot.org/uniprotkb/stream?compressed=true&format=fasta&query='


def __main__():
    parser = argparse.ArgumentParser(
        description='Retrieve Uniprot data using streaming')
    parser.add_argument('-u', '--url', help="Uniprot rest api URL")
    parser.add_argument('-q', '--query', help="UniprotKB Query")
    parser.add_argument('-o', '--output', type=argparse.FileType('wb'), default=sys.stdout, help='data')
    parser.add_argument('-d', '--debug', action='store_true', help='Debug')
    args = parser.parse_args()
    if args.url:
        url = args.url
    else:
        url = uniprotkb_url + args.query
    with requests.get(url, stream=True) as request:
        request.raise_for_status()
        for chunk in request.iter_content(chunk_size=2**20):
            args.output.write(chunk)


if __name__ == "__main__":
    __main__()
