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
    for pool_id, grouped_indices in filegroups.items():
        if pool_id == 1:
            pool_id = 'pool0'
        for index in grouped_indices:
            batch.append(index)
            if batchsize and len(batch) == int(batchsize):
                yield pool_id, batch
                batch = []
        if len(batch) > 0:
            yield pool_id, batch
            batch = []


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--batchsize', dest='batchsize', default=False)
    parser.add_argument('--real-names', dest='realnames', nargs='+')
    parser.add_argument('--galaxy-files', dest='galaxyfiles', nargs='+')
    parser.add_argument('--pool-ids', dest='poolids', nargs='+', default=False)
    args = parser.parse_args()
    for batchcount, (pool_id, batch) in enumerate(get_batches_of_galaxyfiles(
            args.realnames, args.batchsize, args.poolids)):
        for fncount, batchfile in enumerate([args.galaxyfiles[index] for index in batch]):
            dsetname = '{}_batch{}___inputfn{}.mzid'.format(pool_id, batchcount, fncount)
            print('producing', dsetname)
            os.symlink(batchfile, dsetname)

if __name__ == '__main__':
    main()
