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

Inputs are reported but not failed: a multi-file value (`value="a,b"`) cannot
carry a single location - such a test keeps depending on `test-data.sh` (which
CI runs, see .github/workflows/pr.yaml) - and a hand-added input (random.fa) is
tracked in this repository anyway.
"""
import glob
import os
import re
import subprocess
import sys
import xml.etree.ElementTree as ET

HERE = os.path.dirname(os.path.abspath(__file__))
AUX = os.path.dirname(HERE)
TOOLS = os.path.dirname(AUX)

sys.path.insert(0, AUX)
from remote_test_data import fixture_key  # noqa: E402  (the annotator's rule)


def read_table(path):
    rows = {}
    with open(path) as fh:
        for line in fh:
            if line.strip() and not line.startswith("#"):
                fields = line.split("\t")
                rows[fields[0]] = fields[1:]
    return rows


def is_multi_file(value):
    """`value="a.dta,b.dta"`: several files for one flag, no single location."""
    if not value or "," not in value:
        return False
    return any(fixture_key(part.strip()) for part in value.split(","))


def tracked():
    """Files of test-data/ that are part of this repository."""
    try:
        out = subprocess.run(["git", "ls-files", "test-data"], cwd=TOOLS,
                             capture_output=True, text=True, check=True).stdout
    except (OSError, subprocess.CalledProcessError):
        return set()
    return {os.path.basename(line) for line in out.splitlines() if line}


def main():
    fixtures = read_table(os.path.join(AUX, "upstream-fixtures.tsv"))
    expectations = read_table(os.path.join(AUX, "output_expectations.tsv"))
    in_git = tracked()
    problems, counts = [], {"remote": 0, "asserted": 0, "committed": 0, "local": 0,
                            "multi": 0}
    for path in sorted(glob.glob(os.path.join(TOOLS, "*.xml"))):
        name = os.path.basename(path)
        if name.startswith("macros"):
            continue
        root = ET.parse(path).getroot()
        for test in root.iter("test"):
            for output in test.iter("output"):
                value = output.get("value")
                assert_contents = output.find("assert_contents") is not None
                if not value:
                    if assert_contents:
                        counts["asserted"] += 1
                    continue
                key = fixture_key(value)
                if key is None:
                    if is_multi_file(value):
                        counts["multi"] += 1
                    continue
                if key in fixtures:
                    if not output.get("location"):
                        problems.append("%s: %s has an upstream file but no location="
                                        % (name, value))
                    else:
                        counts["remote"] += 1
                elif value in expectations or key in expectations:
                    problems.append("%s: %s should be asserted on, it still compares "
                                    "against a generated fixture" % (name, value))
                elif value in in_git or key in in_git:
                    counts["committed"] += 1
                else:
                    counts["local"] += 1
                    problems.append("%s: %s has no upstream file, no expectation and "
                                    "is not committed" % (name, value))
            for param in test.iter("param"):
                value = param.get("value")
                key = fixture_key(value or "")
                if key is None:
                    if is_multi_file(value):
                        counts["multi"] += 1
                    continue
                if param.get("location"):
                    counts["remote"] += 1
                elif key in fixtures:
                    # the annotator adds location= to every reference it can
                    # resolve - not having one means the wrapper was generated
                    # against a stale manifest or lost it in a merge
                    problems.append("%s: %s has an upstream file but no location="
                                    % (name, value))
                elif value in in_git or key in in_git:
                    counts["committed"] += 1
                else:
                    counts["local"] += 1
    for problem in problems:
        print("FAIL: " + problem, file=sys.stderr)
    print("remote test data: %(remote)d reference(s) by URL, %(asserted)d assertion(s), "
          "%(committed)d committed fixture(s), %(multi)d multi-file reference(s) "
          "(local), %(local)d local reference(s)" % counts)
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
