#!/usr/bin/env python3
"""Apply the CTD corrections listed in aux/ctd_patches.json.

The OpenMS CTDs are generated from the C++ parameter definitions, so a parameter
whose format is only known to the tool (or which upstream forgot to annotate)
arrives here without `supported_formats`.  CTDConverter then falls back to
`txt`, the wrapper declares a `txt` output and the tool refuses to write it -
which is a property of the CTD, not of this repo, so it is corrected on the
snapshot instead of in the generated wrapper (same class of decision as
aux/strip_output_dirs.py).

Usage: patch_ctds.py [CTD_DIR]   (default: ctd)
"""
import json
import os
import sys
import xml.etree.ElementTree as ET

HERE = os.path.dirname(os.path.abspath(__file__))
PATCHES = os.path.join(HERE, "ctd_patches.json")


def items(root):
    """Map `Section:param` -> ITEM element."""
    by_path = {}

    def walk(node, prefix):
        for item in node.findall("ITEM"):
            name = item.get("name")
            path = f"{prefix}:{name}" if prefix else name
            by_path[path] = item
            # the CTD nests PARAMETERS > NODE <tool> > NODE 1 > NODE <section>,
            # so also register the short section:param form used in the patches
            if prefix:
                by_path.setdefault(f"{prefix.split(':')[-1]}:{name}", item)
            if item.get("type") in ("select", "select-file"):
                walk(item, path)
            for node_list in item.findall("NODE"):
                walk(node_list, path)
        for section in node.findall("NODE"):
            name = section.get("name")
            walk(section, f"{prefix}:{name}" if prefix else name)

    parameters = root.find("PARAMETERS")
    walk(parameters if parameters is not None else root, "")
    return by_path


def patch(tool, spec, ctd_dir):
    path = os.path.join(ctd_dir, f"{tool}.ctd")
    if not os.path.isfile(path):
        sys.stderr.write(f"patch_ctds: {path} is missing, skipped\n")
        return 1
    tree = ET.parse(path)
    root = tree.getroot()
    by_path = items(root)
    changed = 0
    for target, attributes in spec.items():
        item = by_path.get(target)
        if item is None:
            sys.stderr.write(f"patch_ctds: {tool}: no item {target}, skipped\n")
            continue
        for key, value in attributes.items():
            if item.get(key) == value:
                continue
            sys.stderr.write(f"patch_ctds: {tool}: {target} {key}={value}\n")
            item.set(key, value)
            changed += 1
    if changed:
        tree.write(path, encoding="UTF-8", xml_declaration=True)
    return 0


def main(argv):
    ctd_dir = argv[1] if len(argv) > 1 else os.path.join(
        os.path.dirname(HERE), "ctd"
    )
    with open(PATCHES) as fh:
        patches = json.load(fh)
    failures = 0
    for tool, spec in patches.items():
        if tool.startswith("_"):
            continue
        failures += patch(tool, spec, ctd_dir)
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
