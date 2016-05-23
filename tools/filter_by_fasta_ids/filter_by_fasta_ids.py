#!/usr/bin/env python
""" A script to build specific fasta databases """
from __future__ import print_function
import logging
import optparse


# ===================================== Iterator ===============================
class Sequence:
    ''' Holds protein sequence information '''
    def __init__(self):
        self.header = ""
        self.sequence_parts = []

    def get_sequence(self):
        return "".join([line.rstrip().replace('\n', '').replace('\r', '') for line in self.sequence_parts])


class FASTAReader:
    """
        FASTA db iterator. Returns a single FASTA sequence object.
    """
    def __init__(self, fasta_name):
        self.fasta_file = open(fasta_name)
        self.next_line = self.fasta_file.readline()

    def __iter__(self):
        return self

    def __next__(self):
        ''' Iteration '''
        next_line = self.next_line
        if not next_line:
            raise StopIteration

        seq = Sequence()
        seq.header = next_line.rstrip().replace('\n', '').replace('\r', '')

        next_line = self.fasta_file.readline()
        while next_line and next_line[0] != '>':
            seq.sequence_parts.append(next_line)
            next_line = self.fasta_file.readline()
        self.next_line = next_line
        return seq

    # Python 2/3 compat
    next = __next__


def target_match(target, search_entry):
    ''' Matches '''
    search_entry = search_entry.upper()
    for atarget in target:
        if search_entry.find(atarget) > -1:
            return atarget
    return None


def main():
    ''' the main function'''
    logging.basicConfig(filename='filter_fasta_log',
                        level=logging.INFO,
                        format='%(asctime)s :: %(levelname)s :: %(message)s')

    parser = optparse.OptionParser()
    parser.add_option('--dedup', dest='dedup', action='store_true', default=False, help='Whether to remove duplicate sequences')
    (options, args) = parser.parse_args()

    targets = []

    with open(args[0]) as f_target:
        for line in f_target.readlines():
            targets.append(">%s" % line.strip().upper())

    logging.info('Read target file and am now looking for %d %s', len(targets), 'sequences.')

    work_summary = {'wanted': len(targets), 'found': 0}
    if options.dedup:
        used_sequences = set()
        work_summary['duplicates'] = 0
    homd_db = FASTAReader(args[1])

    with open(args[2], "w") as output:
        for entry in homd_db:
            target_matched_results = target_match(targets, entry.header)
            if target_matched_results:
                work_summary['found'] += 1
                targets.remove(target_matched_results)
                sequence = entry.get_sequence()
                if options.dedup:
                    if sequence in used_sequences:
                        work_summary['duplicates'] += 1
                        continue
                    else:
                        used_sequences.add(sequence)
                print(entry.header, file=output)
                print(sequence, file=output)

    logging.info('Completed filtering')
    for parm, count in work_summary.items():
        logging.info('%s ==> %d', parm, count)

if __name__ == "__main__":
    main()
