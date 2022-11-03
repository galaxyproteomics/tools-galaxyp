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
from requests.adapters import HTTPAdapter
from requests.packages.urllib3.util.retry import Retry

DEFAULT_TIMEOUT = 5  # seconds
retry_strategy = Retry(
    total=5,
    backoff_factor=2,
    status_forcelist=[429, 500, 502, 503, 504],
    allowed_methods=["HEAD", "GET", "OPTIONS", "POST"]
)


class TimeoutHTTPAdapter(HTTPAdapter):
    def __init__(self, *args, **kwargs):
        self.timeout = DEFAULT_TIMEOUT
        if "timeout" in kwargs:
            self.timeout = kwargs["timeout"]
            del kwargs["timeout"]
        super().__init__(*args, **kwargs)

    def send(self, request, **kwargs):
        timeout = kwargs.get("timeout")
        if timeout is None:
            kwargs["timeout"] = self.timeout
        return super().send(request, **kwargs)


def __main__():
    # Parse Command Line
    parser = optparse.OptionParser()
    parser.add_option('-i', '--input', dest='input', default=None, help='Tabular file containing a column of NCBI Taxon IDs')
    parser.add_option('-c', '--column', dest='column', type='int', default=0, help='The column (zero-based) in the tabular file that contains Taxon IDs')
    parser.add_option('-t', '--taxon', dest='taxon', action='append', default=[], help='NCBI taxon ID to download')
    parser.add_option('-r', '--reviewed', dest='reviewed', help='Only uniprot reviewed entries')
    parser.add_option('-f', '--format', dest='format', choices=['xml', 'fasta'], default='xml', help='output format')
    parser.add_option('-k', '--field', dest='field', choices=['taxonomy_name', 'taxonomy_id'], default='taxonomy_name', help='query field')
    parser.add_option('-o', '--output', dest='output', help='file path for the downloaded uniprot xml')
    parser.add_option('-d', '--debug', dest='debug', action='store_true', default=False, help='Turn on wrapper debugging to stderr')
    (options, args) = parser.parse_args()
    taxids = set(options.taxon)
    if options.input:
        with open(options.input, 'r') as inputFile:
            for linenum, line in enumerate(inputFile):
                if line.startswith('#'):
                    continue
                fields = line.rstrip('\r\n').split('\t')
                if len(fields) > abs(options.column):
                    taxid = fields[options.column].strip()
                    if taxid:
                        taxids.add(taxid)
    taxon_queries = [f'{options.field}:"{taxid}"' for taxid in taxids]
    taxon_query = ' OR '.join(taxon_queries)
    if options.output:
        dest_path = options.output
    else:
        dest_path = "uniprot_%s.xml" % '_'.join(taxids)
    reviewed = " reviewed:%s" % options.reviewed if options.reviewed else ''
    try:
        url = 'https://rest.uniprot.org/uniprotkb/stream'
        query = "%s%s" % (taxon_query, reviewed)
        params = {'query': query, 'format': options.format}
        if options.debug:
            print("%s ? %s" % (url, params), file=sys.stderr)
        data = parse.urlencode(params)
        print(f"Retrieving: {url}?{data}")
        adapter = TimeoutHTTPAdapter(max_retries=retry_strategy)

        http = requests.Session()
        http.mount("https://", adapter)
        response = http.get(url, params=params)
        http.close()

        if response.status_code != 200:
            exit(f"Request failed with status code {response.status_code}:\n{response.text}")

        with open(dest_path, 'w') as fh:
            fh.write(response.text)

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
        print("NCBI Taxon ID:%s" % taxids, file=sys.stdout)
        if 'X-UniProt-Release' in response.headers:
            print("UniProt-Release:%s" % response.headers['X-UniProt-Release'], file=sys.stdout)
        if 'X-Total-Results' in response.headers:
            print("Entries:%s" % response.headers['X-Total-Results'], file=sys.stdout)
    except Exception as e:
        exit("%s" % e)


if __name__ == "__main__":
    __main__()
