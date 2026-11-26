#!/usr/bin/env python3
"""Retype CTD parameters of type "output-dir" to "output-prefix".

OpenMS 3.6 introduced ``type="output-dir"`` for parameters that name a directory
of output files (``out_qpx``, ``out_dir``, ``feat_dir``, ...). CTDopts 1.5 knows
neither the type nor how to ignore it: parsing any CTD that contains one raises
``KeyError: 'output-dir'`` and CTDConverter then dies with an unhelpful
``'UnsupportedTypeError' object has no attribute 'msg'``, failing the whole
conversion over a single tool.

The two types differ only in whether the tool names the files it writes: a prefix
is a path stem the tool appends its own suffixes to, a directory is one it fills
with files nobody declares. CTDConverter treats a prefix as exactly that - it
creates the directory, passes it with a trailing separator (``-out_txt:directory
out_txt.directory/``) and declares a ``<collection>`` whose ``discover_datasets``
picks up whatever the tool wrote. So retyping a directory to a prefix, i.e. to a
prefix that ends with a separator, keeps the parameter usable instead of dropping
it, and the wrapper gets a real output on top.

Which outputs are actually declared is decided per tool: parameters whose content
we cannot describe (ProSE's modification analysis) stay hidden through
``aux/hardcoded_params.json``, a parameter that needs a format the CTD does not
declare is annotated in ``aux/ctd_patches.json``, and tools whose only output is
a directory are blacklisted in ``aux/tools_blacklist.txt``.

Usage: retype_output_dirs.py CTD_DIR [CTD_DIR ...]
"""

import sys
import xml.etree.ElementTree as ET
from pathlib import Path

TYPE = "output-dir"
NEW_TYPE = "output-prefix"
# OpenMS 3.6 writes the new type on ITEM/ITEMLIST as well as on PARAM
PARAM_TAGS = {"PARAM", "ITEM", "ITEMLIST"}


def retype(path: Path) -> list[str]:
    tree = ET.parse(path)
    root = tree.getroot()
    retyped = []

    def walk(node):
        for child in list(node):
            if child.tag in PARAM_TAGS and child.get("type") == TYPE:
                child.set("type", NEW_TYPE)
                retyped.append(child.get("name", "?"))
            else:
                walk(child)

    walk(root)
    if retyped:
        tree.write(path, encoding="utf-8", xml_declaration=True)
    return retyped


def main(argv: list[str]) -> int:
    if not argv:
        print(__doc__.strip().splitlines()[0], file=sys.stderr)
        return 2
    files = sorted(p for d in argv for p in Path(d).glob("*.ctd"))
    if not files:
        print("retype_output_dirs.py: no CTD files found", file=sys.stderr)
        return 1
    total = 0
    for path in files:
        for name in retype(path):
            print(f"  {path.stem}: output-dir -> output-prefix: {name}")
            total += 1
    print(f"retype_output_dirs.py: {len(files)} CTD(s), {total} parameter(s) retyped")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
