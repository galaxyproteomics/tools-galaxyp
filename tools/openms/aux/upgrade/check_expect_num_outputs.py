#!/usr/bin/env python3
"""Check that every test declares as many outputs as it expects.

Galaxy compares `expect_num_outputs` with the outputs the job produced and fails
the test with

    Incorrect number of outputs - expected 1, found 2
    (dataset(s): ctd_out collection(s): out)

which says nothing about the tool.  CTDConverter derives the number from the
outputs it could resolve, so a collection with unknown members leaves it one too
low; `get_tests.py: fix_expect_num_outputs()` raises it to the number of outputs
the test declares.  Declaring *fewer* outputs than the tool writes is a
legitimate assertion (TOPP_FileInfo_12 compares only the CTD dump) and is not
reported.
This script guards the generator: it counts the `<output>` and
`<output_collection>` elements of each `<test>` and compares them with the
attribute.

    python3 aux/upgrade/check_expect_num_outputs.py [wrapper.xml ...]

Without arguments every wrapper in the current directory is checked.
"""
import glob
import pathlib
import re
import sys

TEST = re.compile(r"<test\b[^>]*>")
OUTPUT = re.compile(r"<output(?:_collection)?\s")


def check(path):
    problems = []
    text = pathlib.Path(path).read_text()
    for match in TEST.finditer(text):
        tag = match.group(0)
        end = text.find("</test>", match.end())
        body = text[match.end():end if end != -1 else len(text)]
        declared = len(OUTPUT.findall(body))
        expected = re.search(r'expect_num_outputs="([^"]*)"', tag)
        if not expected:
            continue
        # only a too small number is a bug: a test may deliberately compare
        # fewer outputs than the tool writes (see fix_expect_num_outputs)
        if declared > int(expected.group(1)):
            problems.append(
                f"{path}: test declares {declared} output(s) but expects "
                f"{expected.group(1)!r}"
            )
    return problems


def main():
    paths = sys.argv[1:] or sorted(
        p for p in glob.glob("*.xml") if not p.startswith("macros")
    )
    problems = []
    for path in paths:
        problems.extend(check(path))
    for problem in problems:
        print(problem)
    print(f"expect_num_outputs: {len(paths)} wrappers checked, "
          f"{len(problems)} problem(s)")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
