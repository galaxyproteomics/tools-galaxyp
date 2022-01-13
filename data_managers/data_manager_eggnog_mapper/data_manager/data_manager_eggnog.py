#!/usr/bin/env python

from __future__ import print_function

import argparse
import json
import os.path
import sqlite3
import sys
from sqlite3 import OperationalError


def _get_db_version(sqlitedb_path):
    version = '5.0'
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
    args = parser.parse_args()

    eggnog_db_path = os.path.join(args.install_path, 'eggnog.db')
    if not os.path.exists(eggnog_db_path):
        print('Can not open: %s' % eggnog_db_path, file=sys.stderr)
        exit(1)
    db_version = _get_db_version(eggnog_db_path)

    # params = json.loads(open(args.config_file).read())
    dm_dict = {}
    dm_dict['data_tables'] = dm_dict.get('data_tables', {})
    data_table = 'eggnog_mapper_db_versioned'
    dm_dict['data_tables'][data_table]\
        = dm_dict['data_tables'].get(data_table, [])
    # Versionning is super confusing:
    # eggnog-mapper 1.* needed a db v4.5 (based on eggnog v4.5)
    # eggnog-mapper 2.0 needs a db v2.0 (based on eggnog v5.0)
    # db v4.5 are not compatible with eggnog-mapper 2.0
    version = "2.0"
    if "4.5" in db_version:
        version = "1.0"
    data_table_entry = dict(value=db_version, name=db_version,
                            path=args.install_path, version=version)
    dm_dict['data_tables'][data_table].append(data_table_entry)

    # save info to json file
    open(args.config_file, 'w').write(json.dumps(dm_dict))


if __name__ == "__main__":
    main()
