#!/usr/bin/env python

from __future__ import print_function

import argparse
import json
import os.path
import sqlite3
import sys
from sqlite3 import OperationalError


def _get_db_version(sqlitedb_path):
    version = '4.5'
    try:
        query = 'select version from version'
        conn = sqlite3.connect(sqlitedb_path)
        cur = conn.cursor()
        cur.execute(query)
        version = cur.fetchone()[0]
    except OperationalError as e:
        print('Assuming eggnog version %s because %s   %s' %
              (version, sqlitedb_path, e), file=sys.stderr)
    return version


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--config_file')
    parser.add_argument('--install_path')
    parser.add_argument('--dbs', default='')
    args = parser.parse_args()

    eggnog_db_path = os.path.join(args.install_path, 'eggnog.db')
    if not os.path.exists(eggnog_db_path):
        print('Can not open: %s' % eggnog_db_path, file=sys.stderr)
        exit(1)
    db_version = _get_db_version(eggnog_db_path)

    # params = json.loads(open(args.config_file).read())
    dm_dict = {}
    dm_dict['data_tables'] = dm_dict.get('data_tables', {})
    data_table = 'eggnog_mapper_db'
    dm_dict['data_tables'][data_table]\
        = dm_dict['data_tables'].get(data_table, [])
    data_table_entry = dict(value=db_version, name=db_version,
                            path=args.install_path)
    dm_dict['data_tables'][data_table].append(data_table_entry)
    data_table = 'eggnog_mapper_hmm_dbs'
    dm_dict['data_tables'][data_table]\
        = dm_dict['data_tables'].get(data_table, [])
    if args.dbs:
        dbs = [x.strip() for x in args.dbs.split(',')]
        for db in dbs:
            key = '%s_%s' % (db_version, db)
            data_table_entry = dict(key=key, db_version=db_version,
                                    value=db, name=db, path=db)
            dm_dict['data_tables'][data_table].append(data_table_entry)

    # save info to json file
    open(args.config_file, 'wb').write(json.dumps(dm_dict))


if __name__ == "__main__":
    main()
