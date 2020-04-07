#!/usr/bin/env python3
from argparse import ArgumentParser
from io import StringIO

from CTDopts.CTDopts import (
    CTDModel,
    Parameters,
    ModelTypeError
)

if __name__ == "__main__":
    # note add_help=False since otherwise arguments starting with -h will
    # trigger an error (despite allow_abbreviate)
    parser = ArgumentParser(prog="fill_ctd_clargs",
                            description="fill command line arguments"
                            "into a CTD file and write the CTD file to",
                            add_help=False, allow_abbrev=False)
    parser.add_argument("--ctd", dest="ctd", help="input ctd file",
                        metavar='CTD', default=None, required=True)
    args, cliargs = parser.parse_known_args()
    # load CTDModel
    model = None
    try:
        model = CTDModel(from_file=args.ctd)
    except ModelTypeError:
        pass
    try:
        model = Parameters(from_file=args.ctd)
    except ModelTypeError:
        pass
    assert model is not None, "Could not parse %s, seems to be no CTD/PARAMS" % (args.ctd)

    # get a dictionary of the ctd arguments where the values of the parameters
    # given on the command line are overwritten
    margs = model.parse_cl_args(cl_args=cliargs, ignore_required=True)

    # write the ctd with the values taken from the dictionary
    out = StringIO()
    ctd_tree = model.write_ctd(out, margs)
    print(out.getvalue())
