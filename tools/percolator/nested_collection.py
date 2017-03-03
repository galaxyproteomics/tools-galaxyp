import argparse
import os
import re
from collections import OrderedDict


def get_filename_index_with_identifier(realnames, pool_id):
    pool_indices = []
    for index, fn in enumerate(realnames):
        if re.search(pool_id, fn) is not None:
            pool_indices.append(index)
    return pool_indices


def get_batches_of_galaxyfiles(realnames, batchsize, pool_ids):
    """For an amount of input files, pool identifiers and a batch size,
    return batches of files for a list of lists"""
    if pool_ids:
        filegroups = OrderedDict([(p_id, get_filename_index_with_identifier(
                                   realnames, p_id)) for p_id in pool_ids])
    else:
        filegroups = {1: range(len(realnames))}
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
    parser.add_argument('--real-names', dest='realnames', nargs='+')
    parser.add_argument('--galaxy-files', dest='galaxyfiles', nargs='+')
    parser.add_argument('--pool-ids', dest='poolids', nargs='+', default=False)
    args = parser.parse_args()
    for batchcount, batch in enumerate(get_batches_of_galaxyfiles(
            args.realnames, args.batchsize, args.poolids)):
        for fncount, batchfile in enumerate([args.galaxyfiles[index] for index in batch]):
            os.symlink(batchfile, 'pool{}_inputfn{}.mzid'.format(batchcount, fncount))


if __name__ == '__main__':
    main()
