#!/usr/bin/env python
"""
#
#------------------------------------------------------------------------------
#                         University of Minnesota
#         Copyright 2017, Regents of the University of Minnesota
#------------------------------------------------------------------------------
# Author:
#
#  James E Johnson
#
#------------------------------------------------------------------------------
"""


import sys

from time import sleep

import requests


server = "https://rest.ensembl.org"
ext = "/info/assembly/homo_sapiens?"
max_region = 4000000
debug = False


def ensembl_rest(ext, headers):
    if debug:
        print >> sys.stderr, "%s" % ext
    r = requests.get(server+ext, headers=headers)
    if r.status_code == 429:
        print >> sys.stderr, "response headers: %s\n" % r.headers
        if 'Retry-After' in r.headers:
            sleep(r.headers['Retry-After'])
            r = requests.get(server+ext, headers=headers)
    if not r.ok:
        r.raise_for_status()
    return r


def get_species():
    results = dict()
    ext = "/info/species"
    req_header = {"Content-Type": "application/json"}
    r = ensembl_rest(ext, req_header)
    for species in r.json()['species']:
        results[species['name']] = species
        print >> sys.stdout,\
            "%s\t%s\t%s\t%s\t%s"\
            % (species['name'], species['common_name'],
               species['display_name'],
               species['strain'],
               species['taxon_id'])
    return results


def get_biotypes(species):
    biotypes = []
    ext = "/info/biotypes/%s?" % species
    req_header = {"Content-Type": "application/json"}
    r = ensembl_rest(ext, req_header)
    for entry in r.json():
        if 'biotype' in entry:
            biotypes.append(entry['biotype'])
    return biotypes


def get_toplevel(species):
    coord_systems = dict()
    ext = "/info/assembly/%s?" % species
    req_header = {"Content-Type": "application/json"}
    r = ensembl_rest(ext, req_header)
    toplevel = r.json()
    for seq in toplevel['top_level_region']:
        if seq['coord_system'] not in coord_systems:
            coord_systems[seq['coord_system']] = dict()
        coord_system = coord_systems[seq['coord_system']]
        coord_system[seq['name']] = int(seq['length'])
    return coord_systems


def get_transcripts_bed(species, refseq, start, length, strand='',
                        params=None):
    bed = []
    param = params if params else ''
    req_header = {"Content-Type": "text/x-bed"}
    regions = range(start, length, max_region)
    if not regions or regions[-1] < length:
        regions.append(length)
    for end in regions[1:]:
        ext = "/overlap/region/%s/%s:%d-%d%s?feature=transcript;%s"\
            % (species, refseq, start, end, strand, param)
        start = end + 1
        r = ensembl_rest(ext, req_header)
        if r.text:
            bed += r.text.splitlines()
    return bed


def get_seq(id, seqtype, params=None):
    param = params if params else ''
    ext = "/sequence/id/%s?type=%s;%s" % (id, seqtype, param)
    req_header = {"Content-Type": "text/plain"}
    r = ensembl_rest(ext, req_header)
    return r.text


def get_cdna(id, params=None):
    return get_seq(id, 'cdna', params=params)


def get_cds(id, params=None):
    return get_seq(id, 'cds', params=params)


def get_genomic(id, params=None):
    return get_seq(id, 'genomic', params=params)


def get_transcript_haplotypes(species, transcript):
    ext = "/transcript_haplotypes/%s/%s?aligned_sequences=1"\
        % (species, transcript)
    req_header = {"Content-Type": "application/json"}
    r = ensembl_rest(ext, req_header)
    decoded = r.json()
    return decoded
