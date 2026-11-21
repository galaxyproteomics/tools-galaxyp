#!/usr/bin/env python3
"""Point the generated Galaxy tests at remote OpenMS test data.

Two review comments drive this file:

  * "could you use the 'remote test data' feature of Galaxy? i.e. reference data
    at e.g. https://github.com/OpenMS/OpenMS/tree/master/src/tests/topp directly
    in the tests"
  * "maybe also replace the sim_size comparisons by filetype specific test
    assertions"

Galaxy downloads a test file when the test attributes carry a URL, for inputs
(`location` on a `<param>`, `tools/parameters/basic.py`) and for expected
outputs (`location` on an `<output>`, `tool_util/verify/interactor.py`).  A URL
*replaces* the local fixture instead of falling back to it, so the mapping from
fixture name to URL lives in a committed manifest (`aux/upstream-fixtures.tsv`,
written by test-data.sh) and the wrappers stay a pure function of versioned
state (one row per fixture: name, URL, size).

Files without an upstream counterpart - the references upstream only compares
through FuzzyDiff tolerances, which the wrappers regenerate locally from
`prepare_test_data.sh` - are turned into assertions instead, using the
expectations table (`aux/output_expectations.tsv`, one row per such reference):

  <output name="out" value="CometAdapter_1_out2.tmp.tsv" compare="sim_size"
          delta_frac="0.7" ftype="tabular"/>
  ->
  <output name="out" ftype="tabular">
    <assert_contents>
      <has_size min="210" max="1190"/>
      <has_n_lines min="1" max="6"/>
    </assert_contents>
  </output>

The bounds mirror the tolerance the wrappers used before (`sim_size` with
`delta_frac="0.7"` accepts 0.3 .. 1.7 times the reference size); the line count
gets a factor of two because it is a *content* assertion and formatting changes
between OpenMS releases must not break it.

Usage:
  remote_test_data.py FILE [-o OUT]            # annotate FILE in place
  remote_test_data.py --check FILE ...         # report, do not write
"""
import argparse
import os
import re
import sys

# fixtures whose content is text: a line count is a meaningful assertion
TEXT_FTYPES = {
    "csv", "fasta", "html", "idxml", "json", "mzml", "mztab", "mgf", "paramxml",
    "peff", "qcml", "spec.xml", "tabular", "traml", "tsv", "txt", "xml", "yaml",
    "consensusxml", "mzxml", "trafoXML", "pepXML", "xquest.xml", "splib",
}
# ... of which these are XML, so `is_valid_xml` is the cheap filetype assertion
XML_FTYPES = {
    "idxml", "featurexml", "mzml", "qcml", "traml", "xml", "spec.xml",
    "consensusxml", "mzxml", "trafoXML", "pepXML", "xquest.xml", "paramxml",
}
# attributes that describe a comparison against a reference file: pointless
# (and confusing) once the reference is replaced by an assertion
DROP_ON_ASSERT = {"value", "compare", "delta", "delta_frac", "lines_diff", "sort"}

FILE_SUFFIX = re.compile(r"\.[A-Za-z][A-Za-z0-9]{1,15}$")
ELEMENT = re.compile(r"<(param|output)\b([^>]*?)/>")
# an <output> with children (e.g. a hand-written <assert_contents>) is a second
# form: only its comparison attributes have to go, the assertions stay
# (the open tag must not end with "/", otherwise the non-greedy children
# match would swallow the next element's closing tag)
ELEMENT_WITH_CHILDREN = re.compile(r"<(output)\b([^>]*?[^/>])>(.*?)</output>", re.S)
ATTR = re.compile(r'\s+([\w:.-]+)="([^"]*)"')


def read_tsv(path):
    """basename -> first column value, for a two-column TSV (comments with #)."""
    rows = {}
    if not path:
        return rows
    with open(path) as fh:
        for line in fh:
            line = line.rstrip("\n")
            if not line or line.startswith("#"):
                continue
            fields = line.split("\t")
            rows[fields[0]] = fields[1:]
    return rows


def fixture_key(value):
    """The manifest key of a test reference, or None.

    A `<param value="CHEMISTRY/XLMOD.obo">` is a single file that happens to
    carry the directory test-data.sh copied it to; the manifest is keyed by
    basename (that is what the wrapper has always referenced and what a
    download can be named after).  A comma separated value is several files
    for one flag - those stay local, one URL cannot stand for them.
    """
    if not value or "," in value or "\n" in value or "\t" in value:
        return None
    name = os.path.basename(value)
    return name if FILE_SUFFIX.search(name) else None


def assertions(name, expectation):
    """The <assert_contents> body for a reference we cannot download."""
    ftype, size, lines = (expectation + ["", "", ""])[:3]
    body = []
    if ftype in XML_FTYPES:
        body.append("<is_valid_xml/>")
    if size and int(size) > 0:
        size = int(size)
        body.append('<has_size min="%d" max="%d"/>' % (int(size * 0.3), int(size * 1.7)))
    if ftype in TEXT_FTYPES and lines and lines not in ("-", "0"):
        lines = int(lines)
        body.append('<has_n_lines min="%d" max="%d"/>' % (max(1, int(lines * 0.5)), int(lines * 2) + 1))
    if not body:
        return None
    return "<assert_contents>%s</assert_contents>" % "".join(body)


DELTA_FRAC_DEFAULT = 0.05


def with_delta(tag, attrs_text, adict, fixtures, key):
    """Add the `delta` that makes a `delta_frac` comparison work.

    Galaxy's `sim_size` checks an absolute `delta` first - default 10000, i.e.
    minute - and only then the fraction (`tool_util/verify/__init__.py`,
    `assert_size`).  A wrapper that says `delta_frac="0.7"` therefore rejected
    any reference whose size is more than 10 kB away, which was invisible while
    the reference *was* the produced file (the local test data is created by
    running the tool).  With a real upstream reference the fraction has to be
    spelled out as an absolute delta too.
    """
    if tag != "output" or "delta" in adict or "delta_frac" not in adict:
        return attrs_text
    size = int(fixtures[key][1] or 0) if len(fixtures[key]) > 1 else 0
    if not size:
        return attrs_text
    try:
        frac = float(adict["delta_frac"])
    except ValueError:
        return attrs_text
    if not frac or frac >= 1:
        return attrs_text
    delta = int(size * frac)
    if delta <= 10000:
        return attrs_text
    return '%s delta="%d"' % (attrs_text, delta)


def rewrite(match, fixtures, expectations):
    """A self-closing <param>/<output .../> element."""
    return _rewrite(match.group(1), match.group(2), match.group(0), fixtures, expectations)


def _rewrite(tag, attrs_text, original, fixtures, expectations, children=None):
    """Annotate one element; `children` is set for <output ...>...</output>."""
    attrs = ATTR.findall(attrs_text)
    adict = dict(attrs)
    value = adict.get("value", "")
    key = fixture_key(value)
    if key is None:
        return original
    closing = "" if children is None else ">%s</%s>" % (children, tag)
    # an expectation row wins over the manifest for an OUTPUT: the row exists
    # because the upstream file is not what the tool produces (AccurateMassSearch_1
    # is compared upstream with -whitelist "", i.e. not at all, and the committed
    # copy is stale).  Asserting on the output is the honest check.
    if tag == "output" and expectations.get(value, expectations.get(key)) is not None:
        return _assert_on(tag, attrs, adict, value, key, expectations, children)
    if key in fixtures:
        if "location" in adict:
            return original
        url = fixtures[key][0]
        attrs_text = with_delta(tag, attrs_text, adict, fixtures, key)
        if children is None:
            return '<%s%s location="%s"/>' % (tag, attrs_text, url)
        return '<%s%s location="%s"%s' % (tag, attrs_text, url, closing)
    return original


def _assert_on(tag, attrs, adict, value, key, expectations, children):
    """Replace the comparison of an <output> with an assertion on its content."""
    expectation = expectations.get(value, expectations.get(key))
    if children is None:
        body = assertions(value, expectation)
        if body is None:
            return original
    elif "assert_contents" in children:
        # the author already asserts on the content: only drop the comparison
        body = ""
    else:
        body = assertions(value, expectation) or ""
    kept = "".join(' %s="%s"' % (k, v) for k, v in attrs if k not in DROP_ON_ASSERT)
    return "<output%s>%s%s</output>" % (kept, "" if children is not None else body,
                                        children or "")


def annotate(xml, fixtures, expectations, stats):
    def repl(match):
        new = rewrite(match, fixtures, expectations)
        if new != match.group(0):
            stats["location" if 'location="' in new else "assert"] += 1
        return new

    def repl_children(match):
        new = _rewrite(match.group(1), match.group(2), match.group(0), fixtures,
                       expectations, children=match.group(3))
        if new != match.group(0):
            stats["location" if 'location="' in new else "assert"] += 1
        return new

    xml = ELEMENT_WITH_CHILDREN.sub(repl_children, xml)
    return ELEMENT.sub(repl, xml)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("files", nargs="+", help="test macro XML (annotated in place)")
    parser.add_argument("-o", "--output", help="write here instead of in place")
    parser.add_argument("--fixtures",
                        default=os.environ.get("OPENMS_FIXTURES_TSV")
                        or "aux/upstream-fixtures.tsv",
                        help="fixture name -> upstream URL manifest")
    parser.add_argument("--expectations",
                        default=os.environ.get("OPENMS_EXPECTATIONS_TSV")
                        or "aux/output_expectations.tsv",
                        help="references to assert on instead of comparing")
    parser.add_argument("--check", action="store_true",
                        help="report what would change instead of writing")
    args = parser.parse_args(argv)

    fixtures = read_tsv(args.fixtures)
    expectations = read_tsv(args.expectations)
    if not fixtures:
        sys.stderr.write("%s: no fixtures read - the wrappers would lose their "
                         "remote test data\n" % args.fixtures)
    status = 0
    for path in args.files:
        with open(path) as fh:
            xml = fh.read()
        stats = {"location": 0, "assert": 0}
        new = annotate(xml, fixtures, expectations, stats)
        where = args.output or path
        if args.output:
            with open(where, "w") as fh:
                fh.write(new)
        elif not args.check and new != xml:
            with open(where, "w") as fh:
                fh.write(new)
        sys.stderr.write("%s: %d remote reference(s), %d assertion(s)%s\n"
                         % (path, stats["location"], stats["assert"],
                            " (checked)" if args.check else ""))
        if args.check and new != xml:
            status = 1
    return status


if __name__ == "__main__":
    sys.exit(main())
