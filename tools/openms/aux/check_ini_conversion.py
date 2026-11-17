#!/usr/bin/env python3
"""Check that converting an OpenMS ``.ini`` file kept its explicit values.

``test-data.sh`` upgrades the ini files of the OpenMS test data with
``<tool> -ini <old> -write_ini <new>``.  ``-write_ini`` however writes the
*defaults* of the tool: ``-ini`` only selects the parameter set which gets
augmented, so a value the tool itself fills in does not survive the round trip.
``IsobaricAnalyzer`` sets ``:type``, and ``TMTTenPlexMethod_test.ini`` came back
as ``itraq4plex`` - the tool then writes an iTRAQ consensusXML while the
upstream reference is a TMT one, which the wrapper's ``sim_size`` /
``delta_frac`` comparison rejects.  Upstream does not notice, because
``TOPP_IsobaricAnalyzer_2`` compares with ``-whitelist "id=" "<map"
"?xml-stylesheet"``.

So: convert, then run this script against the original.  Its exit status is 1
and stdout lists the parameters whose value changed, which is the signal to keep
the original file instead of the dump.  Numbers are compared numerically: the
round trip re-formats every float, which is not a change of meaning.

Usage: ``aux/check_ini_conversion.py ORIGINAL CONVERTED``
"""

import sys
import xml.etree.ElementTree as ET

#: written by every tool, and two versions never agree on it
IGNORED = {"version"}


def values(path):
    """Map ``NODE/NODE/ITEM`` -> value for every plain parameter."""
    root = ET.parse(path).getroot()
    found = {}

    def walk(node, prefix):
        for child in node:
            if child.tag == "NODE":
                walk(child, prefix + [child.get("name", "?")])
            elif child.tag == "ITEM":
                name = child.get("name")
                if name in IGNORED:
                    continue
                found["/".join(prefix + [name])] = child.get("value", "")

    walk(root, [])
    return found


def same(one, other):
    """Compare two parameter values, numerically when both are numbers.

    The round trip re-formats numbers (``1`` -> ``1.0``, ``10000000`` ->
    ``1.0e07``, ``123.3965`` -> ``123.396500000000003``), which is not a
    semantic change and must not mask a real one.
    """
    if one == other:
        return True
    try:
        return float(one) == float(other)
    except ValueError:
        return False


def main(old, new):
    before, after = values(old), values(new)
    changed = sorted(k for k, v in before.items() if k in after and not same(v, after[k]))
    for key in changed:
        print(f"{key}: {before[key]!r} -> {after[key]!r}")
    return 1 if changed else 0


if __name__ == "__main__":
    sys.exit(main(*sys.argv[1:3]))
