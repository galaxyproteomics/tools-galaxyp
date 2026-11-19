#!/usr/bin/env python3
"""Apply the CTD corrections listed in aux/ctd_patches.json.

The OpenMS CTDs are generated from the C++ parameter definitions, so a parameter
whose format is only known to the tool (or which upstream forgot to annotate)
arrives here without `supported_formats`.  CTDConverter then falls back to
`txt`, the wrapper declares a `txt` output and the tool refuses to write it -
which is a property of the CTD, not of this repo, so it is corrected on the
snapshot instead of in the generated wrapper (same class of decision as
aux/strip_output_dirs.py).

Two kinds of corrections:

* `"<Tool>": {"<Section>:<param>": {"<attribute>": "<value>"}}` - set attributes
  of one parameter (the supported_formats / input-file fixes).
* `"_substitutions": [["<regex>", "<replacement>"], ...]` - rewrite the
  `description` of *every* parameter of *every* tool, for wording upstream
  generates from C++ type names (`std::string that is appended ...` is not
  something a Galaxy user should have to read).

and one normalisation that applies to every CTD, whether or not a patch names
it: the value list of a `restrictions` attribute is sorted.  OpenMS writes the
enumerable values of a parameter (the enzyme select being the prominent one) in
the order its own container produces them, and that order is not stable across
environments: the same 3.6.0 package here wrote
`colicin_E5,no cleavage,...,RNase_T1` in one run and
`RNase_T1,colicin_E5,no cleavage,...` in the next, i.e. a rotation of the same
list.  CTDConverter turns that list into the wrapper's <option> elements, so a
regeneration would show a diff that is not a change of the generator.

Usage: patch_ctds.py [CTD_DIR]   (default: ctd)
"""
import glob
import json
import os
import re
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
            # a patch may also name the parameter alone ("out_qpx"): the CTD nests
            # it in a numbered NODE (PARAMETERS > NODE 1 > ITEM out_qpx), which is
            # an implementation detail of the C++ parameter registration
            by_path.setdefault(name, item)
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


def substitute(root, rules, tool):
    """Rewrite description/label attributes with the `_substitutions` rules."""
    changed = 0
    for item in root.iter():
        for attribute in ("description", "label"):
            value = item.get(attribute)
            if not value:
                continue
            new = value
            for pattern, replacement in rules:
                new = re.sub(pattern, replacement, new)
            if new != value:
                sys.stderr.write(
                    f"patch_ctds: {tool}: {item.get('name')} {attribute}: "
                    f"{new!r}\n"
                )
                item.set(attribute, new)
                changed += 1
    return changed


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


def sort_restrictions(root, tool):
    """Sort the comma separated value list of every `restrictions` attribute."""
    changed = 0
    for item in root.iter("ITEM"):
        value = item.get("restrictions")
        # a single value (e.g. the numeric range of an int) has nothing to sort
        if not value or "," not in value:
            continue
        # an empty entry is a value of its own (`<option value=""/>`, i.e. "use
        # the tool's default"), so it must survive the sort
        ordered = ",".join(sorted(v.strip() for v in value.split(",")))
        if ordered != value:
            sys.stderr.write(
                f"patch_ctds: {tool}: {item.get('name')} restrictions sorted\n"
            )
            item.set("restrictions", ordered)
            changed += 1
    return changed


def substitute_ctd(path, rules):
    """Apply the `_substitutions` rules to one CTD file and sort its value lists."""
    tool = os.path.basename(path)[:-4]
    tree = ET.parse(path)
    root = tree.getroot()
    changed = substitute(root, rules, tool)
    changed += sort_restrictions(root, tool)
    if changed:
        tree.write(path, encoding="UTF-8", xml_declaration=True)


def main(argv):
    ctd_dir = argv[1] if len(argv) > 1 else os.path.join(
        os.path.dirname(HERE), "ctd"
    )
    with open(PATCHES) as fh:
        patches = json.load(fh)
    rules = patches.get("_substitutions", [])
    failures = 0
    for tool, spec in patches.items():
        if tool.startswith("_"):
            continue
        failures += patch(tool, spec, ctd_dir)
    # the substitutions and the sorted value lists are not per tool: they clean
    # up wording upstream generates from C++ type names and an order that
    # upstream's containers produce, in every CTD the loop above did not touch
    for path in sorted(glob.glob(os.path.join(ctd_dir, "*.ctd"))):
        substitute_ctd(path, rules)
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
