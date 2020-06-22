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
    batch, in_pool_indices = [], []
    for pool_id, grouped_indices in filegroups.items():
        if pool_id == 1:
            pool_id = 'pool0'
        for in_pool_index, total_index in enumerate(grouped_indices):
            batch.append(total_index)
            in_pool_indices.append(in_pool_index)
            if batchsize and len(batch) == int(batchsize):
                yield pool_id, batch, in_pool_indices
                batch, in_pool_indices = [], []
        if len(batch) > 0:
            yield pool_id, batch, in_pool_indices
            batch, in_pool_indices = [], []


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--batchsize', dest='batchsize', default=False)
    parser.add_argument('--real-names', dest='realnames', nargs='+')
    parser.add_argument('--galaxy-files', dest='galaxyfiles', nargs='+')
    parser.add_argument('--pool-ids', dest='poolids', nargs='+', default=False)
    args = parser.parse_args()
    batches = [x for x in get_batches_of_galaxyfiles(args.realnames, args.batchsize, args.poolids)]
    batchdigits = len(str(len(batches)))
    if args.poolids:
        pooldigits = {pid: [] for pid in args.poolids}
        for batchdata in batches:
            pooldigits[batchdata[0]].append(len(batchdata[1]))
        pooldigits = {pid: len(str(sum(batchlengths))) for pid, batchlengths in pooldigits.items()}
    else:
        pooldigits = {'pool0': len(str(len(args.galaxyfiles)))}
    for batchcount, (pool_id, batch, in_pool_indices) in enumerate(batches):
        for fnindex, in_pool_index in zip(batch, in_pool_indices):
            dsetname = '{pid}_batch{bi:0{bd}d}___inputfn{fi:0{pd}d}_{real}.data'.format(pid=pool_id, bi=batchcount, bd=batchdigits, fi=in_pool_index, pd=pooldigits[pool_id], real=args.realnames[fnindex])
            print('producing', dsetname)
            os.symlink(args.galaxyfiles[fnindex], dsetname)


if __name__ == '__main__':
    main()
