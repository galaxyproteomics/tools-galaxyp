#!/usr/bin/env python3
"""Fail if a generated wrapper gives a *data* input a fixed default value.

CTDConverter turns every CTD parameter of type input-file into a Galaxy data
input and copies the CTD default into it.  For a real parameter of that type
the default is empty, but OpenMS also declares executables as input-file, e.g.

    <param argument="-ThermoRaw_executable" type="data" format="txt"
           optional="true" value="ThermoRawFileParser.exe" .../>

and CTDConverter then writes that default into every generated test:

    <param name="ThermoRaw_executable" value="ThermoRawFileParser.exe"/>

which planemo rejects with

    AssertionError: Test input file (ThermoRawFileParser.exe) cannot be found.

Galaxy datasets cannot default to a file name, and an executable belongs to the
tool's environment (or to aux/hardcoded_params.json) -- so: no data input may
carry a non-empty value attribute.  Wizard-style "value" lists (empty string)
are fine.
"""

import sys
import xml.etree.ElementTree as ET
from pathlib import Path

TOOLS = Path(__file__).resolve().parents[2]
DATA_TYPES = {"data", "data_collection"}


def check(path, verbose=False):
    problems = []
    root = ET.parse(path).getroot()
    for param in root.iter("param"):
        if param.get("type") not in DATA_TYPES:
            continue
        value = param.get("value")
        if not value:
            continue
        problems.append((param.get("name") or param.get("argument"), value))
    if verbose:
        for name, value in problems:
            print(f"    {path.name}: data input {name} defaults to {value!r}")
    return problems


def main():
    verbose = "--verbose" in sys.argv or "--warn" in sys.argv
    total = 0
    wrappers = 0
    for path in sorted(TOOLS.glob("*.xml")):
        if path.name.startswith("macros"):
            continue
        wrappers += 1
        total += len(check(path, verbose))
    if total:
        print(f"data inputs: {total} data input(s) default to a file name")
        return 1
    print(f"data inputs: no data input of {wrappers} wrappers has a fixed default")
    return 0


if __name__ == "__main__":
    sys.exit(main())
