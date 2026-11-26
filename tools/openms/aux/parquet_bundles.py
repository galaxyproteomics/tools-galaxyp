#!/usr/bin/env python3
"""Give the Parquet-directory outputs of the OpenMS wrappers a Galaxy collection form.

CTDConverter turns every `output-file` of the CTDs into a single `<data>`, which
can hold exactly one file. The internal OpenMS bundles (`.idparquet`,
`.featureparquet`, `.consensusparquet`) are *directories* of tables - a Parquet
file carries one schema, so an IdXML needs four of them and a FeatureMap or
ConsensusMap five - and the readers require those file names verbatim
(`PSMArrowIO.h:26-35`, `ProteomicsLFQ.cpp:1445-1448`).

So every bundle-capable output additionally gets a `list` collection of
`parquet` datasets, one dataset per table, the table file name as element
designation - the same shape the QPX outputs already have since round 7c (D29).

The original `<data>` output is *not* touched beyond gaining a `<filter>`: the
collection only appears when the matching `OPTIONAL_OUTPUTS` entry is selected,
so no existing command line, no existing test and no existing output changes.
That is deliberate - 626 tests depend on the current default path.

Run by aux/generate.sh after CTDConverter (route B of D30: the alternative was
a third commit on the CTDConverter branch, which cannot be pushed from here).
`--check` verifies that every entry of aux/parquet_bundles.json landed.

The spec lists only tools that can write a bundle *independently of their
input*. The CTDs cannot tell: they declare the parquet formats for `-out`
wherever OpenMS merely accepts them, while the tool's
`FileHandler::store*()` allowed-types list decides (`PeptideIndexer` rejects
`idparquet` at run time). The spec's `_evidence`, `_mirror_only` and
`_needs_out_type` blocks carry that research; the mirror-only tools need a
bundle *input* first and are stage 8c's problem.
"""

import argparse
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SPEC = os.path.join(HERE, "parquet_bundles.json")

# `pattern` of a bundle element. It keeps the `.parquet` extension: the readers
# require the inner file names verbatim (PSMArrowIO.h:26-35), so a consumer can
# rebuild the directory from the designations alone. (The QPX collections of
# round 7c strip the extension, which is fine there - nobody reconstructs a
# file name from them.) `<` and `>` must be escaped inside an attribute value.
PATTERN = r"(?P&lt;designation&gt;.*\.parquet)"

# The working directory of a bundle is `<param>_<kind>_bundle/`, distinct from
# the output name `out_<kind>`: FeatureFinderIdentification writes two bundles
# and `discover_datasets` must not see both (D30 §3).
DIR_SUFFIX = "_bundle"

VALUE_RE = r"^(\s*)'([\w:]+)/output\.\$\{.*\}'$"


def flag(param, kind):
    return "%s_%s_FLAG" % (param, kind)


def bundle_name(param, kind):
    return "%s_%s" % (param, kind)


def bundle_dir(param, kind):
    return "%s%s" % (bundle_name(param, kind), DIR_SUFFIX)


def in_optional(expr):
    """`<expr>` is a Cheetah expression that is true when the flag is set."""
    return '%s in str($OPTIONAL_OUTPUTS).split(\',\')' % expr


def not_in_optional(exprs, cheetah):
    """`and`-joined "none of these flags is set".

    The command block is Cheetah (where `OPTIONAL_OUTPUTS` is a variable to be
    interpolated), the `<filter>` block is a Python expression over the plain
    parameter name - the two cannot share a template.
    """
    if cheetah:
        return " and ".join(
            '"%s" not in str($OPTIONAL_OUTPUTS).split(\',\')' % e for e in exprs)
    return " and ".join('"%s" not in OPTIONAL_OUTPUTS' % e for e in exprs)


def find_out_value(lines, param):
    """Return (index of the `-param` line, index of its value line, indent)."""
    hits = [i for i, l in enumerate(lines) if l.strip() == "-" + param]
    if len(hits) != 1:
        raise SystemExit(
            "parquet_bundles: %s: expected one `-%s` line, found %d"
            % (param, param, len(hits))
        )
    i = hits[0]
    m = re.match(VALUE_RE, lines[i + 1])
    if not m or m.group(2) != param:
        raise SystemExit(
            "parquet_bundles: %s: unexpected value line after `-%s`: %r"
            % (param, param, lines[i + 1])
        )
    return i, i + 1, m.group(1)


def wrap_own_flag(lines, param, kinds):
    """Widen the `#if "<param>_FLAG" in ...` that guards an optional `-param`.

    An optional output is emitted only inside its own flag block; a bundle run
    has `-out` selected but the XML flag not set, so the condition has to admit
    the bundle flags as well. Returns the list of lines.
    """
    cond = '#if "%s_FLAG" in str($OPTIONAL_OUTPUTS).split(\',\')' % param
    hits = [i for i, l in enumerate(lines) if l.strip() == cond]
    if not hits:
        return lines, False
    # the block that guards `-param` (not the one that guards its `mv`)
    i = None
    for h in hits:
        for j in range(h + 1, min(h + 4, len(lines))):
            if lines[j].strip() == "-" + param:
                i = h
                break
        if i is not None:
            break
    if i is None:
        return lines, False
    lines = list(lines)
    extra = "".join(
        " or \"%s\" in str($OPTIONAL_OUTPUTS).split(',')" % flag(param, k)
        for k in kinds)
    lines[i] = lines[i] + extra
    return lines, True


def patch_command(text, param, kinds):
    """Insert mkdir, branch the `-out` value and guard the `mv`."""
    start = text.index("<command")
    end = text.index("</command>", start)
    head, cmd, tail = text[:start], text[start:end], text[end:]
    lines = cmd.split("\n")

    lines, _widened = wrap_own_flag(lines, param, kinds)
    i_flag, i_value, indent = find_out_value(lines, param)

    bundle_dirs = [bundle_dir(param, k) for k in kinds]
    bundle_vals = ["%s/%s.%s" % (d, param, k) for d, k in zip(bundle_dirs, kinds)]

    # 1. the value line becomes a chain of #if/#elif/#else
    new = []
    for n, (kind, value) in enumerate(zip(kinds, bundle_vals)):
        new.append("%s#%s \"%s\" in str($OPTIONAL_OUTPUTS).split(',')"
                   % (indent, "if" if n == 0 else "elif", flag(param, kind)))
        new.append("%s'%s'" % (indent, value))
    new.append("%s#else" % indent)
    new.append(lines[i_value])
    new.append("%s#end if" % indent)
    lines[i_value:i_value + 1] = new

    # 2. a wrapper that names the output file after -out_type
    #    (`out/output.${out_type}`) has to move the select as well: OpenMS merges
    #    -out_type with the extension (getConsistentOutputfileType) and refuses a
    #    mismatch. The command line overrides the value fill_ctd.py wrote into
    #    the ini, which is how -out/-in are passed already.
    if 'argument="-out_type"' in text:
        new = []
        for n, kind in enumerate(kinds):
            new.append('%s#%s "%s" in str($OPTIONAL_OUTPUTS).split(\',\')'
                       % (indent, "if" if n == 0 else "elif", flag(param, kind)))
            new.append("%s-out_type" % indent)
            new.append("%s%s" % (indent, kind))
        new.append("%s#end if" % indent)
        lines[i_flag:i_flag] = new

    # 3. mkdir the bundle directories before the program call
    pipefail = [i for i, l in enumerate(lines) if l.strip() == "set -o pipefail &&"]
    if len(pipefail) != 1:
        raise SystemExit(
            "parquet_bundles: %s: expected one `set -o pipefail &&`, found %d"
            % (param, len(pipefail))
        )
    mk = []
    for d, kind in zip(bundle_dirs, kinds):
        mk.append('#if "%s" in str($OPTIONAL_OUTPUTS).split(\',\')' % flag(param, kind))
        mk.append("  mkdir -p %s &&" % d)
        mk.append("#end if")
    lines[pipefail[0]:pipefail[0]] = mk

    # 4. the `mv` only runs when no bundle of this output was asked for
    mv = [
        i for i, l in enumerate(lines)
        if re.match(r"\s*&& mv '[\w:]+/output\.\$\{.*\}' '\$%s'$" % re.escape(param), l)
    ]
    if len(mv) != 1:
        raise SystemExit(
            "parquet_bundles: %s: expected one `mv ... $%s`, found %d"
            % (param, param, len(mv))
        )
    ind = re.match(r"(\s*)", lines[mv[0]]).group(1)
    lines[mv[0]:mv[0] + 1] = (
        [ind + "#if " + not_in_optional([flag(param, k) for k in kinds], cheetah=True)]
        + [lines[mv[0]]]
        + [ind + "#end if"]
    )

    return head + "\n".join(lines) + tail


def cut_element(text, tag, name):
    """Return (start, end, text) of `<tag name="name" ...>` including children.

    A plain regex is not enough: `<data .../>` and `<data ...>...</data>` both
    occur, and `<data>` children (`<change_format>`, `<filter>`) contain
    self-closing tags - a non-greedy `.*?/>` stops inside `<change_format>`.
    """
    start = text.index('<%s name="%s"' % (tag, name))
    quote, i = None, start
    while True:
        c = text[i]
        if quote:
            if c == quote:
                quote = None
        elif c in "\"'":
            quote = c
        elif c == ">":
            break
        i += 1
    if text[i - 1] == "/":
        return start, i + 1, text[start:i + 1]
    close = "</%s>" % tag
    end = text.index(close, i) + len(close)
    return start, end, text[start:end]


def patch_outputs(text, param, kinds):
    """Add the collections and hide the `<data>` while a bundle is selected."""
    start, end, block = cut_element(text, "data", param)
    line_start = text.rindex("\n", 0, start) + 1
    indent = text[line_start:start]
    assert indent.strip() == "", "unexpected indentation before <data>: %r" % indent

    colls = []
    for kind in kinds:
        b = bundle_name(param, kind)
        colls.extend([
            '%s<collection type="list" name="%s" label="${tool.name} on ${on_string}: %s (%s bundle)">'
            % (indent, b, param, kind),
            '%s  <discover_datasets directory="%s/%s.%s" recurse="true" format="parquet" pattern="%s"/>'
            % (indent, bundle_dir(param, kind), param, kind, PATTERN),
            '%s  <filter>OPTIONAL_OUTPUTS is not None and "%s_FLAG" in OPTIONAL_OUTPUTS</filter>'
            % (indent, b),
            '%s</collection>' % indent,
        ])

    hide = not_in_optional([flag(param, k) for k in kinds], cheetah=False)
    if block.rstrip().endswith("/>"):
        new_block = (block.rstrip()[:-2].rstrip() + ">\n"
                     + indent + "  <filter>" + "OPTIONAL_OUTPUTS is None or ("
                     + hide + ")</filter>\n" + indent + "</data>")
    else:
        fl = re.search(r"<filter>(.*?)</filter>", block, re.S)
        if fl:
            new_block = block[:fl.start()] + (
                "<filter>" + " ".join(fl.group(1).split()) + " and " + hide + "</filter>"
            ) + block[fl.end():]
        else:
            cut = block.rindex("</data>")
            new_block = (block[:cut].rstrip() + "\n"
                         + indent + "  <filter>OPTIONAL_OUTPUTS is None or (" + hide
                         + ")</filter>\n" + indent + block[cut:])

    return (text[:line_start] + "\n".join(colls) + "\n"
            + indent + new_block + text[end:])


def patch_optional_select(text, param, kinds):
    """Offer the new outputs in the OPTIONAL_OUTPUTS multi-select."""
    m = re.search(r'(\s*)<param name="OPTIONAL_OUTPUTS".*?</param>', text, re.S)
    if not m:
        raise SystemExit("parquet_bundles: no OPTIONAL_OUTPUTS param")
    block = m.group(0)
    indent = re.match(r"(\s*)", block.split("\n")[1] if "\n" in block else block).group(1)
    added = []
    for kind in kinds:
        b = bundle_name(param, kind)
        added.append('%s  <option value="%s_FLAG">%s (%s bundle)</option>'
                     % (indent, b, param, kind))
    # append after the last <option> of the select
    opts = list(re.finditer(r'\s*<option value="[^"]*_FLAG">.*?</option>', block))
    if not opts:
        raise SystemExit("parquet_bundles: OPTIONAL_OUTPUTS has no <option>")
    last = opts[-1].end()
    new_block = block[:last] + "\n" + "\n".join(added) + block[last:]
    return text[:m.start()] + new_block + text[m.end():]


def applied(text, param, kinds):
    """True when the patch is already in the file.

    Not the `<flag>` string: the manual tests of `aux/macros_test.xml` select
    exactly that flag, so a flag check would skip a wrapper whose command block
    was never patched (the generator emitted the tests first).
    """
    return all(
        '<discover_datasets directory="%s/%s.%s"' % (bundle_dir(param, k), param, k) in text
        for k in kinds
    )


def apply_params(text, params):
    """Apply every entry of the spec once; idempotent by construction."""
    for param, kinds in params.items():
        if applied(text, param, kinds):
            continue  # already applied
        text = patch_command(text, param, kinds)
        text = patch_outputs(text, param, kinds)
        text = patch_optional_select(text, param, kinds)
    return text


def check_file(path, params, problems):
    """The post-processor is a pure function: check it is a no-op on this file."""
    before = open(path).read()
    after = apply_params(before, params)
    if after != before:
        missing = [param for param, kinds in params.items()
                   if not applied(before, param, kinds)]
        problems.append("%s: bundle output missing for %s"
                        % (os.path.basename(path), ", ".join(missing) or "?"))


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--check", action="store_true",
                    help="verify only, do not write")
    ap.add_argument("wrappers", nargs="*", help="wrapper XML files (default: all)")
    a = ap.parse_args()

    spec = json.load(open(SPEC))["tools"]
    files = a.wrappers or sorted(
        f for f in os.listdir(".") if f.endswith(".xml") and not f.startswith("macros"))
    problems, touched = [], []
    for f in files:
        tool = f[:-len(".xml")]
        if tool not in spec:
            continue
        if a.check:
            check_file(f, spec[tool], problems)
        else:
            before = open(f).read()
            after = apply_params(before, spec[tool])
            if after != before:
                open(f, "w").write(after)
                touched.append(tool)
    if a.check:
        for p in problems:
            print("parquet_bundles: " + p, file=sys.stderr)
        covered = len([t for t in spec if os.path.exists(t + ".xml")])
        print("parquet_bundles: %d wrapper(s) checked, %d problem(s)"
              % (covered, len(problems)))
        return 1 if problems else 0
    print("parquet_bundles: %d wrapper(s) changed%s"
          % (len(touched), (": " + ", ".join(touched)) if touched else ""))
    return 0


if __name__ == "__main__":
    sys.exit(main())
