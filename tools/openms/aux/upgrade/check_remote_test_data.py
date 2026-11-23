#!/usr/bin/env python3
"""Check 9: every test reference is either downloadable, asserted on or committed.

The wrappers no longer need a local copy of the upstream test data ("remote
test data", review point #2): a reference that exists in the OpenMS source tree
is fetched by Galaxy from `aux/upstream-fixtures.tsv`, and a reference which
only exists because `prepare_test_data.sh` ran the tool is replaced by an
assertion from `aux/output_expectations.tsv`.

Broken states this catches:

  * an output whose fixture is upstream but whose `<output>` carries no
    `location=` - the test would fall back to a local file that is not there
  * an output whose fixture is generated AND which still compares against a
    file - it would be a `sim_size` comparison against a fixture that only
    exists after the (long) prepare step, i.e. exactly the dependency the
    remote test data is supposed to remove
  * an `<output>` asserting on a reference which no longer has a row in the
    expectation table (stale assertion, silently weaker than intended)

A multi-file value (`value="a,b"` for a `multiple="true"` data parameter) gets
one URL per file in `location`; Galaxy splits it (`tool_util/verify/parse.py`,
`_process_raw_inputs`, since release 24.2).  A hand-added input (random.fa) is
tracked in this repository and stays local by design.

No step of the CI populates `test-data/` any more, so a test that still needs a
local fixture fails there - which is why the local references are counted.
"""
import glob
import os
import subprocess
import sys
import xml.etree.ElementTree as ET

HERE = os.path.dirname(os.path.abspath(__file__))
AUX = os.path.dirname(HERE)
TOOLS = os.path.dirname(AUX)

sys.path.insert(0, AUX)
from remote_test_data import _fixture_url, fixture_keys  # noqa: E402


def read_table(path):
    rows = {}
    with open(path) as fh:
        for line in fh:
            if line.strip() and not line.startswith("#"):
                fields = line.split("\t")
                rows[fields[0]] = fields[1:]
    return rows


def reference(element):
    """The file a test element points at; Galaxy takes `value` or `file`."""
    return element.get("value") or element.get("file") or ""


def keys(element, tag):
    """The manifest keys of one reference, or None if it is not a fixture.

    An `<output>` stands for exactly one file, so a comma separated value there
    is not remote-able even though a `multiple="true"` input is.
    """
    found = fixture_keys(reference(element))
    if not found or (tag == "output" and len(found) > 1):
        return None
    return found


def tracked():
    """Files of test-data/ that are part of this repository."""
    out = subprocess.run(["git", "ls-files", "test-data"], cwd=TOOLS,
                         capture_output=True, text=True, check=True).stdout
    return {os.path.basename(line) for line in out.splitlines() if line}


ASSERTIONS = ("assert_contents", "has_size", "has_n_lines", "has_text",
              "is_valid_xml")


def main():
    fixtures = read_table(os.path.join(AUX, "upstream-fixtures.tsv"))
    expectations = read_table(os.path.join(AUX, "output_expectations.tsv"))
    in_git = tracked()
    problems, counts = [], {"remote": 0, "asserted": 0, "committed": 0}
    for path in sorted(glob.glob(os.path.join(TOOLS, "*.xml"))):
        name = os.path.basename(path)
        if name.startswith("macros"):
            continue
        for test in ET.parse(path).getroot().iter("test"):
            for element in test.iter():
                if element.tag not in ("param", "output", "element"):
                    continue
                value = reference(element)
                if not value:
                    if element.find("assert_contents") is not None:
                        counts["asserted"] += 1
                    continue
                # `keys()` is the annotator's own rule: a comma separated value
                # of a multiple parameter is several files, one output is one
                found = keys(element, "output" if element.tag != "param"
                             else "param")
                if found is None:
                    continue
                if element.get("location"):
                    counts["remote"] += 1
                elif any(element.find(tag) is not None for tag in ASSERTIONS):
                    counts["asserted"] += 1
                elif element.tag != "param" and (value in expectations
                                                 or found[0] in expectations):
                    problems.append("%s: %s should be asserted on, it still "
                                    "compares against a generated fixture"
                                    % (name, value))
                elif all(key in in_git for key in found):
                    # a committed copy wins over the upstream file: the test
                    # rewrites the reference in place (INIUpdater_1_noupdate_0)
                    counts["committed"] += 1
                elif any(_fixture_url(key, fixtures, name[:-len(".xml")])
                         for key in found):
                    # the annotator resolves every reference it can - no
                    # location= here means a stale manifest or a lost attribute
                    problems.append("%s: %s has an upstream file but no location="
                                    % (name, value))
                else:
                    problems.append("%s: %s has no upstream file, is not asserted "
                                    "on and is not committed" % (name, value))
    for problem in problems:
        print("FAIL: " + problem, file=sys.stderr)
    print("remote test data: %(remote)d reference(s) by URL, %(asserted)d "
          "assertion(s), %(committed)d committed fixture(s)" % counts)
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
