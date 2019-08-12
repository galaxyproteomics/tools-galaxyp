#!/usr/bin/env python
""" A script to build specific fasta databases """
from __future__ import print_function

import argparse
import re
import sys


class Sequence(object):
    def __init__(self, header, sequence_parts):
        self.header = header
        self.sequence_parts = sequence_parts
        self._sequence = None

    @property
    def sequence(self):
        if self._sequence is None:
            self._sequence = ''.join(self.sequence_parts)
        return self._sequence

    def print(self, fh=sys.stdout):
        print(self.header, file=fh)
        for line in self.sequence_parts:
            print(line, file=fh)


def FASTAReader_gen(fasta_filename):
    with open(fasta_filename) as fasta_file:
        line = fasta_file.readline()
        while True:
            if not line:
                return
            assert line.startswith('>'), "FASTA headers must start with >"
            header = line.rstrip()
            sequence_parts = []
            line = fasta_file.readline()
            while line and line[0] != '>':
                sequence_parts.append(line.rstrip())
                line = fasta_file.readline()
            yield Sequence(header, sequence_parts)


def target_match(targets, search_entry, pattern):
    ''' Matches '''
    search_entry = search_entry.upper()
    m = pattern.search(search_entry)
    if m:
        target = m.group(len(m.groups()))
        if target in targets:
            return target
    else:
        print('No ID match: %s' % search_entry, file=sys.stdout)
    return None


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('-i', required=True, help='Path to input FASTA file')
    parser.add_argument('-o', required=True, help='Path to output FASTA file')
    parser.add_argument('-d', help='Path to discarded entries file')
    header_criteria = parser.add_mutually_exclusive_group()
    header_criteria.add_argument('--id_list', help='Path to the ID list file')
    parser.add_argument('--pattern', help='regex search pattern for ID in FASTA entry')
    header_criteria.add_argument('--header_regexp', help='Regular expression pattern the header should match')
    sequence_criteria = parser.add_mutually_exclusive_group()
    sequence_criteria.add_argument('--min_length', type=int, help='Minimum sequence length')
    sequence_criteria.add_argument('--sequence_regexp', help='Regular expression pattern the sequence should match')
    parser.add_argument('--max_length', type=int, help='Maximum sequence length')
    parser.add_argument('--dedup', action='store_true', default=False, help='Whether to remove duplicate sequences')
    options = parser.parse_args()

    if options.pattern:
        if not re.match('^.*[(](?![?]:).*[)].*$', options.pattern):
            sys.exit('pattern: "%s" did not include capture group "()" in regex ' % options.pattern)
        pattern = re.compile(options.pattern)

    if options.min_length is not None and options.max_length is None:
        options.max_length = sys.maxsize
    if options.header_regexp:
        header_regexp = re.compile(options.header_regexp)
    if options.sequence_regexp:
        sequence_regexp = re.compile(options.sequence_regexp)

    work_summary = {'found': 0, 'discarded': 0}

    if options.dedup:
        used_sequences = set()
        work_summary['duplicates'] = 0

    if options.id_list:
        targets = set()
        with open(options.id_list) as f_target:
            for line in f_target:
                targets.add(line.strip().upper())
        work_summary['wanted'] = len(targets)

    homd_db = FASTAReader_gen(options.i)
    if options.d:
        discarded = open(options.d, 'w')

    with open(options.o, "w") as output:
        for entry in homd_db:
            print_entry = True
            if options.id_list:
                target_matched_results = target_match(targets, entry.header, pattern)
                if target_matched_results:
                    targets.remove(target_matched_results)
                else:
                    print_entry = False
            elif options.header_regexp:
                if header_regexp.search(entry.header) is None:
                    print_entry = False
            if options.min_length is not None:
                sequence_length = len(entry.sequence)
                if not(options.min_length <= sequence_length <= options.max_length):
                    print_entry = False
            elif options.sequence_regexp:
                if sequence_regexp.search(entry.sequence) is None:
                    print_entry = False
            if print_entry:
                if options.dedup:
                    if entry.sequence in used_sequences:
                        work_summary['duplicates'] += 1
                        continue
                    else:
                        used_sequences.add(entry.sequence)
                work_summary['found'] += 1
                entry.print(output)
            else:
                work_summary['discarded'] += 1
                if options.d:
                    entry.print(discarded)

    if options.d:
        discarded.close()

    for parm, count in work_summary.items():
        print('%s ==> %d' % (parm, count))


if __name__ == "__main__":
    main()
