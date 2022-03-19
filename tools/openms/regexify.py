#!/usr/bin/env python
# transform output files mentioned in a given ctd file
# into files that can be used in Galaxy regex comparisons

import re
from argparse import ArgumentParser
from pathlib import Path

from CTDopts.CTDopts import (
    CTDModel,
    ModelTypeError,
    Parameters,
    _OutFile,
    _OutPrefix,
)

TEST_DATA = sorted(
    [x.name for x in Path('test-data').iterdir() if x.is_file()],
    reverse=True
)

def process(fname):
    with open(fname) as fh:
        content = fh.read()
        content = re.escape(content)

    for td in TEST_DATA:
        td = re.escape(td)
        content = content.replace(td, ".*")

    with open(fname, "w") as fh:
        fh.write(content)

def __main__():
    parser = ArgumentParser(prog="regexify",
                            description="TODO")
    parser.add_argument("--ini_file", dest="ini_file", help="input ini file",
                        metavar='INI', default=None, required=True)
    args, cliargs = parser.parse_known_args()

    ini_model = None
    try:
        ini_model = CTDModel(from_file=args.ini_file)
    except ModelTypeError:
        pass
    try:
        ini_model = Parameters(from_file=args.ini_file)
    except ModelTypeError:
        pass
    assert ini_model is not None, "Could not parse %s, seems to be no CTD/PARAMS" % (args.ini_file)

    for param in ini_model.get_parameters():
        if param.default is None or type(param.default) is _Null:
            continue
        if param.type is _OutFile:
            process(param.default)
        elif param.type is _OutPrefix:
            
            continue
            process_prefix(param.default)