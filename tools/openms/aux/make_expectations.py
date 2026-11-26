#!/usr/bin/env python3
"""Write aux/output_expectations.tsv: what to assert for references we cannot download.

Every `<output value="X">` in the wrappers whose `X` has no upstream counterpart
(see aux/upstream-fixtures.tsv) is compared against a file that only exists
because `prepare_test_data.sh` ran the tool locally.  Those references become
assertions (`aux/remote_test_data.py`), and this script records the numbers they
are derived from.

Deliberately *not* part of the generator
----------------------------------------
The table is a snapshot of the current test-data/ directory, i.e. of what the
tools produce today.  Recreating it silently on every regeneration would mean
that a regression in a wrapper rewrites its own expectation - the same trap the
wrappers' `sim_size` references were meant to avoid.  Regenerate it only on
purpose (OpenMS version bump, or a reviewed change of an output), and say why in
the commit message.

Usage:  ./make_expectations.py [-o FILE] [--fixtures FILE] [--testdata DIR]
Columns: name <TAB> ftype <TAB> size <TAB> lines   ('-' where there is no line
count: binary formats and files too large to count quickly)

The names are the *content* of the table, not what can be rediscovered: after
the first annotation pass the wrappers no longer carry `value=` for these
outputs (that is the point), so a row is only dropped by deleting it here.  A
reference that is neither a URL nor an assertion has no fixture to be compared
against, so it fails the annotation pass and its row is added by this script; a
row whose fixture is not in test-data/ keeps its recorded numbers.
"""
import argparse
import glob
import os
import sys
import xml.etree.ElementTree as ET

HERE = os.path.dirname(os.path.abspath(__file__))
TOOLS = os.path.dirname(HERE)          # tools/openms
DEFAULT_OUT = os.path.join(HERE, "output_expectations.tsv")
MAX_LINES_BYTES = 32 << 20             # do not count lines of huge files


def read_fixtures(path):
    names = set()
    with open(path) as fh:
        for line in fh:
            if line.strip() and not line.startswith("#"):
                names.add(line.split("\t")[0])
    return names


def collect(tools_dir):
    """output reference -> the ftype(s) the wrappers declare for it."""
    refs = {}
    for path in sorted(glob.glob(os.path.join(tools_dir, "*.xml"))):
        if os.path.basename(path) in ("macros.xml", "macros_test.xml"):
            continue
        root = ET.parse(path).getroot()
        for test in root.iter("test"):
            for output in test.iter("output"):
                value, ftype = output.get("value"), output.get("ftype")
                if not value or "," in value:
                    continue
                refs.setdefault(value, set()).add(ftype or "")
    return refs


def read_existing(path):
    """The rows of an existing table: name -> [ftype, size, lines]."""
    rows = {}
    if not os.path.exists(path):
        return rows
    with open(path) as fh:
        for line in fh:
            if line.strip() and not line.startswith("#"):
                fields = line.rstrip("\n").split("\t")
                rows[fields[0]] = fields[1:]
    return rows


def measure(path):
    size = os.path.getsize(path)
    lines = "-"
    if size <= MAX_LINES_BYTES:
        try:
            with open(path, "rb") as fh:
                lines = str(sum(1 for _ in fh))
        except OSError:
            lines = "-"
    return size, lines


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("-o", "--output", default=DEFAULT_OUT)
    parser.add_argument("--fixtures", default=os.path.join(HERE, "upstream-fixtures.tsv"))
    parser.add_argument("--testdata", default=os.path.join(TOOLS, "test-data"))
    parser.add_argument("--tools", default=TOOLS)
    args = parser.parse_args(argv)

    upstream = read_fixtures(args.fixtures)
    known = read_existing(args.output)
    refs = collect(args.tools)
    # new references: still declared with a value= in a wrapper, no upstream file
    for name, ftypes in refs.items():
        if name in upstream or name in known:
            continue
        ftypes = sorted(f for f in ftypes if f)
        if len(ftypes) > 1:
            sys.stderr.write("warning: %s is declared with several ftypes: %s\n"
                             % (name, ", ".join(ftypes)))
        known[name] = [ftypes[0] if ftypes else ""]
    rows, missing = [], []
    for name in sorted(known):
        if name in upstream:
            sys.stderr.write("warning: %s has an upstream file - drop it from the "
                             "table, the wrapper should reference it instead\n" % name)
            continue
        ftype, size, lines = (known[name] + ["", "", "-"])[:3]
        path = os.path.join(args.testdata, name)
        if not os.path.exists(path):
            missing.append(name)
            rows.append((name, ftype, size, lines))
            continue
        size, lines = measure(path)
        rows.append((name, ftype, str(size), lines))
    if missing:
        sys.stderr.write("kept the recorded numbers, fixture not in test-data/ "
                         "(run prepare_test_data.sh to refresh):\n  %s\n"
                         % "\n  ".join(missing))
    with open(args.output, "w") as fh:
        fh.write("# references without an upstream file: assert, do not compare\n")
        fh.write("# name\tftype\tsize\tlines\n")
        fh.write("#\n")
        fh.write("# Written by aux/make_expectations.py from test-data/ and the wrappers.\n")
        fh.write("# Regenerate deliberately (OpenMS version bump or a reviewed output\n")
        fh.write("# change) and record the reason in the commit message: the\n")
        fh.write("# numbers are the current behaviour, so an automatic refresh would let a\n")
        fh.write("# regression rewrite its own expectation.\n")
        for row in rows:
            fh.write("\t".join(row) + "\n")
    print("%d assertion reference(s) written to %s" % (len(rows), args.output))
    return 0


if __name__ == "__main__":
    sys.exit(main())
