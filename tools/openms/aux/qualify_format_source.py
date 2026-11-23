#!/usr/bin/env python3
"""Qualify `format_source`/`metadata_source` references to a nested input.

CTDConverter writes the *bare* input name into `format_source` and
`metadata_source` of an output that mirrors its input
(`ctdconverter/galaxy/converter.py`, `get_galaxy_parameter_name`).  That is
fine for a top level input, but ConsensusID takes its input through a
conditional whose two `<when>` branches both define `-in`, so
`format_source="in"` is ambiguous and Galaxy's `OutputsFormatSourceReference`
linter says

  Output 'out' uses ambiguous unqualified format_source='in' matching multiple
  inputs: in_cond|in, in_cond|in. Use a qualified name.

which fails `planemo lint --fail_level warn` (the CI setting).

Galaxy resolves the reference by the expanded state name, and neither
`format_source` nor that name contains the `<when>` value - `in_cond|in` names
both branches, i.e. the qualified form is correct and unambiguous.  So: replace
the bare name with the qualified one whenever *all* inputs of that name agree on
it, and leave everything else (a real ambiguity) for the linter.

Usage:
  qualify_format_source.py FILE ...            # rewrite in place
  qualify_format_source.py --check FILE ...    # report, do not write
"""
import argparse
import os
import re
import sys
import xml.etree.ElementTree as ET

# the attributes of an <output> which name another parameter
REFERENCES = ("format_source", "metadata_source")
CONTAINERS = ("conditional", "section")
SUFFIX = re.compile(r'\b(format_source|metadata_source)="([^"]*)"')


def name_of(param):
    """The Galaxy parameter name of a CTDConverter input element."""
    name = param.get("name")
    if not name:
        name = (param.get("argument") or "").lstrip("-").replace("-", "_")
    return name


def qualified(param, parent_map):
    """The expanded state name of a parameter (`in_cond|in`)."""
    parts = [name_of(param)]
    current = param
    while True:
        ancestor = parent_map.get(current)
        if ancestor is None or ancestor.tag in ("inputs", "tool"):
            break
        if ancestor.tag in CONTAINERS and ancestor.get("name"):
            parts.insert(0, ancestor.get("name"))
        current = ancestor
    return "|".join(parts)


def input_names(root):
    """{unqualified name: [qualified name, ...]} for every input parameter."""
    parent_map = {child: parent for parent in root.iter() for child in parent}
    names = {}
    for param in root.findall("./inputs//param"):
        name = name_of(param)
        if name:
            names.setdefault(name, []).append(qualified(param, parent_map))
    return names


def replacements(xml):
    """The {attribute value -> qualified value} rewrites of one wrapper."""
    root = ET.fromstring(xml)
    names = input_names(root)
    fixed = {}
    for output in root.findall("./outputs/data") + root.findall("./outputs/collection"):
        for attribute in REFERENCES:
            reference = output.get(attribute)
            if not reference or "|" in reference:
                continue
            matches = names.get(reference, [])
            # a top level input needs no qualification, and two *different*
            # qualified names are a real ambiguity: leave both to the linter
            if reference in matches or not matches or len(set(matches)) != 1:
                continue
            fixed.setdefault(attribute, {})[reference] = matches[0]
    return fixed


def annotate(xml, stats):
    """Rewrite the reference attributes of the <outputs> block of one wrapper."""
    fixed = replacements(xml)
    if not fixed:
        return xml
    start = xml.find("<outputs>")
    if start < 0:
        return xml
    head, tail = xml[:start], xml[start:]

    def repl(match):
        attribute, value = match.group(1), match.group(2)
        new = fixed.get(attribute, {}).get(value)
        if new is None:
            return match.group(0)
        stats["fixed"] += 1
        return '%s="%s"' % (attribute, new)

    return head + SUFFIX.sub(repl, tail)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("files", nargs="+", help="tool XML (rewritten in place)")
    parser.add_argument("--check", action="store_true",
                        help="report what would change instead of writing")
    args = parser.parse_args(argv)
    status = 0
    for path in args.files:
        if os.path.basename(path).startswith("macros"):
            continue
        with open(path) as handle:
            xml = handle.read()
        stats = {"fixed": 0}
        new = annotate(xml, stats)
        if new != xml:
            sys.stderr.write("%s: %d qualified reference(s)\n" % (path, stats["fixed"]))
            if args.check:
                status = 1
            else:
                with open(path, "w") as handle:
                    handle.write(new)
    return status


if __name__ == "__main__":
    sys.exit(main())
