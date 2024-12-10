#!/usr/bin/env python
"""
#
#------------------------------------------------------------------------------
#                         University of Minnesota
#         Copyright 2016, Regents of the University of Minnesota
#------------------------------------------------------------------------------
# Author:
#
#  James E Johnson
#
#------------------------------------------------------------------------------
"""
import optparse
import re
import sys
from urllib import parse

import requests
from requests.adapters import HTTPAdapter, Retry


def __main__():
    # Parse Command Line
    parser = optparse.OptionParser()
    parser.add_option('-i', '--input', dest='input', default=None, help='Tabular file containing a column of search search_ids')
    parser.add_option('-c', '--column', dest='column', type='int', default=0, help='The column (zero-based) in the tabular file that contains search search_ids')
    parser.add_option('-s', '--search-id', dest='search_id', action='append', default=[], help='ID to search in Uniprot')
    parser.add_option('-r', '--reviewed', dest='reviewed', help='Only uniprot reviewed entries')
    parser.add_option('-f', '--format', dest='format', choices=['xml', 'fasta', 'tsv'], default='xml', help='output format')
    parser.add_option('-k', '--field', dest='field', choices=['taxonomy_name', 'taxonomy_id', 'accession'], default='taxonomy_name', help='query field')
    parser.add_option('-o', '--output', dest='output', help='file path for the downloaded uniprot xml')
    parser.add_option('--output_columns', dest='output_columns', help='Columns to include in output (tsv)')
    parser.add_option('-d', '--debug', dest='debug', action='store_true', default=False, help='Turn on wrapper debugging to stderr')
    (options, args) = parser.parse_args()
    search_ids = set(options.search_id)
    if options.input:
        with open(options.input, 'r') as inputFile:
            for linenum, line in enumerate(inputFile):
                if line.startswith('#'):
                    continue
                fields = line.rstrip('\r\n').split('\t')
                if len(fields) > abs(options.column):
                    search_id = fields[options.column].strip()
                    if search_id:
                        search_ids.add(search_id)
    search_queries = [f'{options.field}:"{search_id}"' for search_id in search_ids]
    search_query = ' OR '.join(search_queries)
    if options.output:
        dest_path = options.output
    else:
        dest_path = "uniprot_%s.xml" % '_'.join(search_ids)
    reviewed = " reviewed:%s" % options.reviewed if options.reviewed else ''
    try:
        re_next_link = re.compile(r'<(.+)>; rel="next"')
        retries = Retry(total=5, backoff_factor=0.25, status_forcelist=[500, 502, 503, 504])
        session = requests.Session()
        session.mount("https://", HTTPAdapter(max_retries=retries))

        def get_next_link(headers):
            if "Link" in headers:
                match = re_next_link.match(headers["Link"])
                if match:
                    return match.group(1)

        def get_batch(batch_url):
            while batch_url:
                response = session.get(batch_url)
                response.raise_for_status()
                total = response.headers["x-total-results"]
                release = response.headers["x-uniprot-release"]
                yield response, total, release
                batch_url = get_next_link(response.headers)

        params = {'size': 500, 'format': options.format, 'query': search_query + reviewed}
        if options.output_columns:
            params['fields'] = options.output_columns
        url = f'https://rest.uniprot.org/uniprotkb/search?{parse.urlencode(params)}'
        print(f"Downloading from:{url}")

        with open(dest_path, 'w') as fh:
            for batch, total, release in get_batch(url):
                fh.write(batch.text)

        if options.format == 'xml':
            with open(dest_path, 'r') as contents:
                while True:
                    line = contents.readline()
                    if options.debug:
                        print(line, file=sys.stderr)
                    if line is None:
                        break
                    if line.startswith('<?'):
                        continue
                    # pattern match <root or <ns:root for any ns string
                    pattern = r'^<(\w*:)?uniprot'
                    if re.match(pattern, line):
                        break
                    else:
                        print("failed: Not a uniprot xml file", file=sys.stderr)
                        exit(1)
        print(f"Search IDs:{search_ids}")
        print(f"UniProt-Release:{release}")
        print(f"Entries:{total}")
    except Exception as e:
        exit("%s" % e)


if __name__ == "__main__":
    __main__()
