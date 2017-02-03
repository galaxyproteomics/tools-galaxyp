#!/usr/bin/env python
import os
import sys
import re

class Sequence:
    ''' Holds protein sequence information '''
    def __init__(self):
        self.header = ""
        self.accession = ""
        self.sequence = ""

class FASTAReader:
    """
        FASTA db iterator. Returns a single FASTA sequence object.
    """
    def __init__(self, fasta_name, accession_parser):
        self.fasta_file = open(fasta_name)
        self.accession_parser = accession_parser

    def __iter__(self):
        return self

    def __next__(self):
        ''' Iteration '''
        while True:
            line = self.fasta_file.readline()
            if not line:
                raise StopIteration
            if line[0] == '>':
                break

        seq = Sequence()
        seq.header = line.rstrip().replace('\n','').replace('\r','')

        m = re.search(self.accession_parser, seq.header)
        if not m or len(m.groups()) < 1 or len(m.group(1)) == 0:
          sys.exit("Could not parse accession from '%s'" % seq.header)
        seq.accession = m.group(1)

        while True:
            tail = self.fasta_file.tell()
            line = self.fasta_file.readline()
            if not line:
                break
            if line[0] == '>':
                self.fasta_file.seek(tail)
                break
            seq.sequence = seq.sequence + line.rstrip().replace('\n','').replace('\r','')
        return seq

    # Python 2/3 compat
    next = __next__


def main():
    seen_sequences = dict([])
    seen_accessions = set([])

    out_file = open(sys.argv[1], 'w')
    if sys.argv[2] == "sequence":
        unique_sequences = True
    elif sys.argv[2] == "accession":
        unique_sequences = False
    else:
        sys.exit("2nd argument must be 'sequence' or 'accession'")

    accession_parser = sys.argv[3]
    for key, value in { '\'' :'__sq__', '\\' : '__backslash__' }.items():
      accession_parser = accession_parser.replace(value, key)

    for fasta_file in sys.argv[4:]:
        print("Reading entries from '%s'" % fasta_file)
        fa_reader = FASTAReader(fasta_file, accession_parser)
        for protein in fa_reader:
            if unique_sequences:
                if protein.accession in seen_accessions:
                    print("Skipping protein '%s' with duplicate accession" % protein.header)
                    continue
                elif hash(protein.sequence) in seen_sequences:
                    print("Skipping protein '%s' with duplicate sequence (first seen as '%s')" % (protein.header, seen_sequences[hash(protein.sequence)]))
                    continue
                else:
                    seen_sequences[hash(protein.sequence)] = protein.accession
                    seen_accessions.add(protein.accession)
            else:
                if protein.accession in seen_accessions:
                    print("Skipping protein '%s' with duplicate accession" % protein.header)
                    continue
                else:
                    seen_accessions.add(protein.accession)
            out_file.write(protein.header)
            out_file.write(os.linesep)
            out_file.write(protein.sequence)
            out_file.write(os.linesep)
    out_file.close()

if __name__ == "__main__":
    main()
