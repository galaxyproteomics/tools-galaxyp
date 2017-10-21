#!/usr/bin/env python
import sys
import argparse
from numpy import median
from contextlib import ExitStack

from peptide_pi_annotator import get_col_by_pattern


def main():
    if sys.argv[1:] == []:
        sys.argv.append('-h')
    args = parse_commandline()
    locfun = {False: locatefraction,
              True: reverse_locatefraction}[args.reverse]
    # Column nrs should start from 0
    # If negative, -1 is last item in list, etc
    if args.fdrcol > 0:
        fdrcol = args.fdrcol - 1
    elif args.fdrcol:
        fdrcol = args.fdrcol
    elif args.fdrcolpattern:
        fdrcol = get_col_by_pattern(args.train_peptable, args.fdrcolpattern)
    else:
        fdrcol = False
    if args.deltapicol > 0:
        deltapicol = args.deltapicol - 1
    elif args.deltapicol:
        deltapicol = args.deltapicol
    elif args.deltapicolpattern:
        deltapicol = get_col_by_pattern(args.train_peptable,
                                        args.deltapicolpattern)
    else:
        deltapicol = False
    pishift = get_pishift(args.train_peptable, fdrcol, deltapicol,
                          args.fdrcutoff, args.picutoff)
    binarray = get_bin_array(args.fr_amount, args.fr_width, args.intercept,
                             args.tolerance, pishift)
    write_fractions(args.pipeps, args.fr_amount, args.prefix,
                    binarray, locfun, args.minlen, args.maxlen)


def locatefraction(pep_pi, bins):
    index = []
    for pibin in bins:
        if pep_pi > pibin[2]:
            continue
        elif pep_pi >= pibin[1]:
            index.append(pibin[0])
        else:
            return index
    return index


def reverse_locatefraction(pep_pi, bins):
    index = []
    for pibin in bins:
        if pep_pi < pibin[1]:
            continue
        elif pep_pi < pibin[2]:
            index.append(pibin[0])
        else:
            return index
    return index


def parse_commandline():
    parser = argparse.ArgumentParser(
        formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument('-p', dest='train_peptable', help='Peptide table with '
                        'peptides, FDR, and fraction numbers. Used to '
                        'calculate pI shift. Leave emtpy for no shift. '
                        'Tab separated file.')
    parser.add_argument('--deltacol', dest='deltapicol', help='Delta pI column'
                        ' number in peptide table. First column is nr. 1. '
                        'Negative number for counting from last col '
                        '(-1 is last).', default=False, type=int)
    parser.add_argument('--deltacolpattern', dest='deltapicolpattern',
                        help='Delta pI column header pattern in peptide '
                        'table.', default=False, type=str)
    parser.add_argument('--picutoff', dest='picutoff',
                        help='delta pI value to filter experimental peptides'
                        ' when calculating pi shift.', default=0.2, type=float)
    parser.add_argument('--fdrcolpattern', dest='fdrcolpattern',
                        help='FDR column header pattern in peptide table.',
                        default=False, type=str)
    parser.add_argument('--fdrcol', dest='fdrcol', help='FDR column number in '
                        'peptide table. First column is nr. 1. Empty includes '
                        'all peptides', default=False, type=int)
    parser.add_argument('--fdrcutoff', dest='fdrcutoff',
                        help='FDR cutoff value to filter experimental peptides'
                        ' when calculating pi shift.', default=0, type=float)
    parser.add_argument('-i', dest='pipeps', help='A tab-separated txt file '
                        'with accession, peptide seq, pI value')
    parser.add_argument('--prefix', dest='prefix', default='pisep',
                        help='Prefix for target/decoy output files')
    parser.add_argument('--tolerance', dest='tolerance',
                        help='Strip fraction tolerance pi tolerance represents'
                        ' 2.5/97.5 percentile', type=float)
    parser.add_argument('--amount', dest='fr_amount',
                        help='Strip fraction amount', type=int)
    parser.add_argument('--reverse', dest='reverse', help='Strip is reversed',
                        action='store_const', const=True, default=False)
    parser.add_argument('--intercept', dest='intercept',
                        help='pI Intercept of strip', type=float)
    parser.add_argument('--width', dest='fr_width',
                        help='Strip fraction width in pI', type=float)
    parser.add_argument('--minlen', dest='minlen', help='Minimal peptide length',
                        type=int)
    parser.add_argument('--maxlen', dest='maxlen', help='Maximal peptide length',
                        type=int, default=False)
    return parser.parse_args(sys.argv[1:])


def get_pishift(peptable, fdrcol, deltapicol, fdrcutoff, delta_pi_cutoff):
    delta_pis = []
    with open(peptable) as fp:
        next(fp)  # skip header
        for line in fp:
            line = line.strip('\n').split('\t')
            if fdrcol:
                try:
                    fdr = float(line[fdrcol])
                except ValueError:
                    continue
                if fdr > fdrcutoff:
                    continue
            try:
                delta_pi = float(line[deltapicol])
            except ValueError:
                continue
            if delta_pi < delta_pi_cutoff:
                delta_pis.append(delta_pi)
    shift = median(delta_pis)
    print('pI shift (median of delta pIs): {}'.format(shift))
    return shift


def get_bin_array(amount_fractions, fr_width, intercept, tolerance, pi_shift):
    frnr = 1
    bin_array = []
    while frnr <= amount_fractions:
        pi_center = fr_width * frnr + intercept
        bin_left = pi_center - fr_width / 2 - tolerance - pi_shift
        bin_right = pi_center + fr_width / 2 + tolerance - pi_shift
        print('Bins in fraction', frnr, bin_left, bin_right)
        bin_array.append((frnr, bin_left, bin_right))
        frnr += 1
    return bin_array


def write_fractions(pi_peptides_fn, amount_fractions, out_prefix,
                    bin_array, locate_function, minlen, maxlen):
    amountpad = len(str(amount_fractions))
    with ExitStack() as stack:
        target_out_fp = {frnr: ([], stack.enter_context(
            open('{p}_fr{i:0{pad}}.fasta'.format(p=out_prefix, i=frnr,
                                                 pad=amountpad), 'w')))
            for frnr in range(1, amount_fractions + 1)}
        decoy_out_fp = {frnr: ([], stack.enter_context(
            open('decoy_{p}_fr{i:0{pad}}.fasta'.format(p=out_prefix, i=frnr,
                                                       pad=amountpad), 'w')))
            for frnr in range(1, amount_fractions + 1)}
        input_fp = stack.enter_context(open(pi_peptides_fn))
        pepcount = 0
        for line in input_fp:
            accs, pep, pi = line.strip().split("\t")
            pi = float(pi)
            if maxlen and len(pep) > maxlen:
                continue
            elif len(pep) >= minlen:
                pepcount += 1
                if pep[-1] in {'K', 'R'}:
                    rev_pep = pep[::-1][1:] + pep[-1]
                else:
                    rev_pep = pep[::-1]
                for i in locate_function(pi, bin_array):
                    target_out_fp[i][0].append('>{}\n{}\n'.format(accs, pep))
                    # write pseudoReversed decoy peptide at the same time
                    decoy_out_fp[i][0].append('>decoy_{}\n{}\n'.format(
                        accs, rev_pep))
            if pepcount > 1000000:
                # write in chunks to make it go faster
                pepcount = 0
                [fp.write(''.join(peps)) for peps, fp in
                 target_out_fp.values()]
                [fp.write(''.join(peps)) for peps, fp in decoy_out_fp.values()]
                target_out_fp = {fr: ([], pep_fp[1])
                                 for fr, pep_fp in target_out_fp.items()}
                decoy_out_fp = {fr: ([], pep_fp[1])
                                for fr, pep_fp in decoy_out_fp.items()}
        [fp.write(''.join(peps)) for peps, fp in target_out_fp.values()]
        [fp.write(''.join(peps)) for peps, fp in decoy_out_fp.values()]


if __name__ == '__main__':
    main()
