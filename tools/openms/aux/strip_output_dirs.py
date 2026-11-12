#!/usr/bin/env python3
"""Strip parameters of CTD type "output-dir" from OpenMS CTD files.

OpenMS 3.6 introduced ``type="output-dir"`` for parameters that name a directory
of output files (``out_qpx``, ``out_dir``, ``feat_dir``, ...). CTDopts 1.5 knows
neither the type nor how to ignore it: parsing any CTD that contains one raises
``KeyError: 'output-dir'`` and CTDConverter then dies with an unhelpful
``'UnsupportedTypeError' object has no attribute 'msg'``, failing the whole
conversion over a single tool.

Galaxy datasets are single files, so such a parameter cannot be represented in a
wrapper anyway - dropping it is the honest translation, and it keeps one
directory-output tool from breaking the conversion of all the others. Tools whose
*only* output is a directory are blacklisted in ``aux/tools_blacklist.txt``.

Usage: strip_output_dirs.py CTD_DIR [CTD_DIR ...]
"""

import sys
import xml.etree.ElementTree as ET
from pathlib import Path

TYPE = "output-dir"
# OpenMS 3.6 writes the new type on ITEM/ITEMLIST as well as on PARAM
PARAM_TAGS = {"PARAM", "ITEM", "ITEMLIST"}


def strip(path: Path) -> list[str]:
    tree = ET.parse(path)
    root = tree.getroot()
    dropped = []

    def walk(node):
        for child in list(node):
            if child.tag in PARAM_TAGS and child.get("type") == TYPE:
                node.remove(child)
                dropped.append(child.get("name", "?"))
            else:
                walk(child)

    walk(root)
    if dropped:
        tree.write(path, encoding="utf-8", xml_declaration=True)
    return dropped


def main(argv: list[str]) -> int:
    if not argv:
        print(__doc__.strip().splitlines()[0], file=sys.stderr)
        return 2
    files = sorted(p for d in argv for p in Path(d).glob("*.ctd"))
    if not files:
        print("strip_output_dirs.py: no CTD files found", file=sys.stderr)
        return 1
    total = 0
    for path in files:
        for name in strip(path):
            print(f"  {path.stem}: dropped output-dir parameter {name}")
            total += 1
    print(f"strip_output_dirs.py: {len(files)} CTD(s), {total} output-dir parameter(s) dropped")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
