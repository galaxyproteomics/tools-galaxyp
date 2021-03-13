#!/usr/bin/env python3

import operator
from argparse import ArgumentParser
from functools import reduce  # forward compatibility for Python 3
from io import StringIO

from CTDopts.CTDopts import (
    _Null,
    CTDModel,
    ModelTypeError,
    Parameters
)


def getFromDict(dataDict, mapList):
    return reduce(operator.getitem, mapList, dataDict)


def setInDict(dataDict, mapList, value):
    getFromDict(dataDict, mapList[:-1])[mapList[-1]] = value


if __name__ == "__main__":
    # note add_help=False since otherwise arguments starting with -h will
    # trigger an error (despite allow_abbreviate)
    parser = ArgumentParser(prog="fill_ctd_clargs",
                            description="fill command line arguments"
                            "into a CTD file and write the CTD file to stdout",
                            add_help=False, allow_abbrev=False)
    parser.add_argument("--ini_file", dest="ini_file", help="input ini file",
                        metavar='INI', default=None, required=True)
    parser.add_argument("--ctd_file", dest="ctd_file", help="input ctd file"
                        "if given then optional parameters from the ini file"
                        "will be filled with the defaults from this CTD file",
                        metavar='CTD', default=None, required=False)
    args, cliargs = parser.parse_known_args()

    # load CTDModel
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

    # get a dictionary of the ctd arguments where the values of the parameters
    # given on the command line are overwritten
    ini_values = ini_model.parse_cl_args(cl_args=cliargs, ignore_required=True)

    if args.ctd_file:
        ctd_model = CTDModel(from_file=args.ctd_file)
        ctd_values = ctd_model.get_defaults()
        for param in ini_model.get_parameters():
            if not param.required and (param.default is None or type(param.default) is _Null):
                lineage = param.get_lineage(name_only=True)
                try:
                    default = getFromDict(ctd_values, lineage)
                except KeyError:
                    continue
                setInDict(ini_values, lineage, default)

    # write the ctd with the values taken from the dictionary
    out = StringIO()
    ctd_tree = ini_model.write_ctd(out, ini_values)
    print(out.getvalue())
