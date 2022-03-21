#!/usr/bin/env python
# transform output files mentioned in a given ctd file
# into files that can be used in Galaxy regex comparisons

import re
import sys
from argparse import ArgumentParser
from pathlib import Path

from CTDopts.CTDopts import (
    CTDModel,
    ModelTypeError,
    Parameters,
    _Null,
    _OutFile,
    _OutPrefix,
)

TEST_DATA = sorted(
    [x.name for x in Path('test-data').iterdir() if x.is_file()],
    reverse=True
)


def process(fname):
    path = Path('test-data/') / Path(str(fname))
    with open(path) as fh:
        try:
            content = fh.read()
        except UnicodeDecodeError:
            return
        content = re.escape(content)
    wd = str(Path.cwd() / Path("test-data/"))
    wd = re.escape(wd)
    content = content.replace(wd, ".*")
    for td in TEST_DATA:
        td = re.escape(td)
        content = content.replace(td, ".*")
    # varying offsets in (indexed)MzML
    # - <offset idRef="spectrum=1">8283</offset>
    # - <offset idRef="index=0">3751</offset>
    content = re.sub(r'<offset\\ idRef="(spectrum|index)=(\d+)">\d+<', r'<offset\\ idRef="\1=\2">\\d+<', content)
    # - <indexListOffset>15169</indexListOffset>
    content = re.sub(r'<indexListOffset>\d+</indexListOffset>', r'<indexListOffset>\\d+</indexListOffset>', content)
    # mzXML
    # - <offset id = "1" >1617</offset>
    content = re.sub(r'<offset\\ id\\ =\\ ?"(\d+)"\\ >\d+<', r'<offset\\ id\\ =\\ "\1"\\ >\\d+<', content)
    # - <indexOffset>39125</indexOffset>
    content = re.sub(r'<indexOffset>\d+</indexOffset>', r'<indexOffset>\\d+</indexOffset>', content)
    with open(path, "w") as fh:
        fh.write(content)


if __name__ == "__main__":
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
            try:
                if isinstance(param.default, list):
                    for d in param.default:
                        process(d)
                else:
                    process(str(param.default))
            except Exception:
                sys.stderr.write(f"\tcould not regexify {param.name}={param.default}\n")
                raise
        elif param.type is _OutPrefix:
            
            continue
            process_prefix(param.default)