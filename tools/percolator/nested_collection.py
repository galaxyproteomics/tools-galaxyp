import argparse
import os
import re
from collections import OrderedDict


def get_filename_index_with_identifier(spectrafiles, pool_id):
    pool_indices = []
    for index, fn in enumerate(spectrafiles):
        if re.search(pool_id, fn) is not None:
            pool_indices.append(index)
    return pool_indices


def get_perco_batches_from_spectrafiles(spectrafiles, batchsize, ppool_ids):
    """For an amount of input spectra files, pool identifiers and a batch size,
    return batches of files that can be percolated together"""
    if ppool_ids:
        filegroups = OrderedDict([(p_id, get_filename_index_with_identifier(
                                   spectrafiles, p_id)) for p_id in ppool_ids])
    else:
        filegroups = {1: range(len(spectrafiles))}
    batch = []
    for grouped_indices in filegroups.values():
        for index in grouped_indices:
            batch.append(index)
            if len(batch) == int(batchsize):
                yield batch
                batch = []
        if len(batch) > 0:
            yield batch
            batch = []


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--batchsize', dest='batchsize')
    parser.add_argument('--spectrafiles', dest='spectrafiles', nargs='+')
    parser.add_argument('--searchfiles', dest='searchfiles', nargs='+')
    parser.add_argument('--percolator-pool-ids', dest='percopoolids', nargs='+', default=False)
    args = parser.parse_args()
    for batchcount, batch in enumerate(get_perco_batches_from_spectrafiles(
            args.spectrafiles, args.batchsize, args.percopoolids)):
        for fncount, batchfile in enumerate([args.searchfiles[index] for index in batch]):
            os.symlink(batchfile, 'ppool{}_mzidfn{}.mzid'.format(batchcount, fncount))


if __name__ == '__main__':
    main()
