#!/usr/bin/env python
import sys
import os
import argparse
import re
from Bio import SeqIO


def create_spectra_maps(specfiles, dbfiles, frregex, firstfr):
    """Output something like
    {'fr01', 'fr04'} # Normal filename set
    and
    {'fr03': ['fr02', 'fr03']}  # pool definition
    and
    {'fr04': 'fr04', 'fr04b': 'fr04'}  # rerun fraction, rerun may also be pool
    """
    specrange = get_fn_fractionmap(specfiles, frregex)
    to_pool = []
    poolmap, rerun_map, normal_fns = {}, [], set()
    for i in range(0, len(dbfiles)):
        num = i + firstfr
        if num not in specrange:
            to_pool.append(i)
        elif to_pool and num in specrange:
            to_pool.append(i)
            poolmap[specrange[num][0]] = to_pool
            to_pool = []
        if not to_pool and specrange[num][0] in poolmap:
            if poolmap[specrange[num][0]][-1] != i:
                normal_fns.add((dbfiles[num - 1],
                                specfiles[specrange[num][0]]))
        elif not to_pool:
            normal_fns.add((dbfiles[num - 1], specfiles[specrange[num][0]]))
    for num in sorted(specrange.keys()):
        if len(specrange[num]) > 1:
            rerun_map.append(specrange[num])
    return normal_fns, rerun_map, poolmap


def get_fn_fractionmap(files, frregex):
    fnfrmap = {}
    for f_ix, fn in enumerate(files):
        fnum = int(re.sub(frregex, '\\1', fn))
        try:
            fnfrmap[fnum].append(f_ix)
        except KeyError:
            fnfrmap[fnum] = [f_ix]
    return fnfrmap


def pool_fasta_files(poolfiles):
    acc_seq = {}
    for fr in poolfiles:
        for seq in SeqIO.parse(fr, 'fasta'):
            sequence = str(seq.seq.upper())
            try:
                if sequence in acc_seq[seq.id]:
                    continue
            except KeyError:
                acc_seq[seq.id] = {sequence: 1}
                yield seq
            else:
                acc_seq[seq.id][sequence] = 1
                yield seq


def write_pooled_fasta(poolmap, specnames, dbfiles):
    """Runs through poolmap and pooles output files, filtering out
    duplicates"""
    for outfr, infrs in poolmap.items():
        outfn = os.path.join('aligned_out', os.path.basename(specnames[outfr]))
        print('Pooling FASTA files {} - {} into: {}'.format(
            dbfiles[infrs[0]], dbfiles[infrs[-1]], outfn))
        with open(outfn, 'w') as fp:
            SeqIO.write(pool_fasta_files([dbfiles[x] for x in infrs]), fp,
                        'fasta')


def write_nonpooled_fasta(fractions):
    """Symlinks nonpooled db files"""
    print('Symlinking non-pooled non-rerun files',
          [(fr[0], os.path.join('aligned_out', os.path.basename(fr[1])))
           for fr in fractions])
    [os.symlink(fr[0], os.path.join('aligned_out', os.path.basename(fr[1])))
     for fr in fractions]


def copy_rerun_fasta(rerun_map, specnames):
    for dst_indices in rerun_map:
        src = os.path.join(specnames[dst_indices[0]])
        for outfn in [specnames[x] for x in dst_indices[1:]]:
            print('Symlinking {} to {}'.format(src, outfn))
            os.symlink(src, os.path.join('aligned_out', outfn))


def main():
    args = parse_commandline()
    with open(args.spectranames) as fp:
        spectranames = [x.strip() for x in fp.read().strip().split('\n')]
    vanilla_fr, rerun_map, poolmap = create_spectra_maps(spectranames,
                                                         args.dbfiles,
                                                         args.frspecregex,
                                                         args.firstfr)
    write_pooled_fasta(poolmap, spectranames, args.dbfiles)
    write_nonpooled_fasta(vanilla_fr)
    copy_rerun_fasta(rerun_map, spectranames)


def parse_commandline():
    parser = argparse.ArgumentParser(
        formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument('--specnames', dest='spectranames', help='File '
                        'containing spectra filenames with fractions. '
                        'Test data example illustrates reruns (fr03b, 09b) and'
                        ' pooled samples (fr05-09 are inside fr09 and fr09b).',
                        required=True)
    parser.add_argument('--dbfiles', dest='dbfiles', help='FASTA db files',
                        nargs='+', required=True)
    parser.add_argument('--frspec', dest='frspecregex', help='Fraction regex '
                        'to detect spectra fraction numbers', required=True)
    parser.add_argument('--firstfr', dest='firstfr', help='First fraction nr',
                        type=int, required=True)
    return parser.parse_args(sys.argv[1:])


if __name__ == '__main__':
    main()
