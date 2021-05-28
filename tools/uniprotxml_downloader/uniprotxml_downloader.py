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
import sys
import re
import optparse
import urllib.request, urllib.parse, urllib.error
import urllib.request, urllib.error, urllib.parse


def __main__():
    # Parse Command Line
    parser = optparse.OptionParser()
    parser.add_option('-i', '--input', dest='input', default=None, help='Tabular file containing a column of NCBI Taxon IDs')
    parser.add_option('-c', '--column', dest='column', type='int', default=0, help='The column (zero-based) in the tabular file that contains Taxon IDs' )
    parser.add_option('-t', '--taxon', dest='taxon', action='append', default=[], help='NCBI taxon ID to download')
    parser.add_option('-r', '--reviewed', dest='reviewed', help='Only uniprot reviewed entries')
    parser.add_option('-f', '--format', dest='format', choices=['xml', 'fasta'], default='xml', help='output format')
    parser.add_option('-o', '--output', dest='output', help='file path for the downloaded uniprot xml')
    parser.add_option('-v', '--verbose', dest='verbose', action='store_true', default=False, help='Print UniProt Info')
    parser.add_option('-d', '--debug', dest='debug', action='store_true', default=False, help='Turn on wrapper debugging to stderr')
    (options, args) = parser.parse_args()
    taxids = set(options.taxon)
    if options.input:
        with open(options.input,'r') as inputFile:
            for linenum,line in enumerate(inputFile):
                if line.startswith('#'):
                    continue
                fields = line.rstrip('\r\n').split('\t')
                if len(fields) > abs(options.column):
                    taxid = fields[options.column].strip()
                    if taxid:
                      taxids.add(taxid)
    taxon_queries = ['taxonomy:"%s"' % taxid for taxid in taxids]
    taxon_query = ' OR '.join(taxon_queries)
    if options.output:
        dest_path = options.output
    else:
        dest_path = "uniprot_%s.xml" % '_'.join(taxids)
    reviewed = " reviewed:%s" % options.reviewed if options.reviewed else ''
    try:
        def reporthook(n1,n2,n3):
            pass   
        url = 'https://www.uniprot.org/uniprot/'
        query = "%s%s" % (taxon_query, reviewed)
        params = {'query' : query, 'force' : 'yes' , 'format' : options.format}
        if options.debug:
            print("%s ? %s" % (url,params), file=sys.stderr)
        data = urllib.parse.urlencode(params)
        print(f"url {url} dest_path {dest_path} data {data}")
        (fname, msg) = urllib.request.urlretrieve(url, dest_path, reporthook, data.encode())
        print("retrieved")
        headers = {j[0]: j[1].strip() for j in [i.split(':', 1) for i in str(msg).strip().splitlines()]}
        if 'Content-Length' in headers and headers['Content-Length'] == 0:
            print(url, file=sys.stderr)
            print(msg, file=sys.stderr)
            exit(1)
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
                    pattern = '^<(\w*:)?uniprot'
                    if re.match(pattern, line):
                        break
                    else:
                        print("failed: Not a uniprot xml file", file=sys.stderr)
                        exit(1)
        if options.verbose:
            print("NCBI Taxon ID:%s" % taxids, file=sys.stdout)
            if 'X-UniProt-Release' in headers:
                print("UniProt-Release:%s" % headers['X-UniProt-Release'], file=sys.stdout)
            if 'X-Total-Results' in headers:
                print("Entries:%s" % headers['X-Total-Results'], file=sys.stdout)
            print("%s" % url, file=sys.stdout)
    except Exception as e:
        print("failed: %s" % e, file=sys.stderr)


if __name__ == "__main__":
    __main__()
