#!/usr/bin/env python3
"""Let the OpenMS wrappers *read* a Parquet-directory bundle (D30, stage 8c).

The counterpart of aux/parquet_bundles.py.  An `.idparquet`,
`.featureparquet` or `.consensusparquet` input is a directory of tables, and
the readers take its *file names* verbatim (`PSMArrowIO.h:26-35`,
`ProteomicsLFQ.cpp:1445-1448`), so a Galaxy `list` collection of `parquet`
datasets has to be reassembled into a directory before the program is called.

Galaxy cannot switch a `<data>` into a `<data_collection>` - the two are
different parameter types - so every affected input is wrapped in a
`<conditional>`: the default case keeps the single-file `<param>` untouched,
the second case adds the collection.  The command then materialises
`<dir>/in.<kind>` by `ln -s` from the elements, using their identifiers as the
inner file names, and passes that directory as `-<param>`.

The original `<data>` input, its `<test>`s and the default command line stay as
they are: the file case is still the selected one and every existing `<test>`
only gains the wrapping `<conditional>` that selects it (a `<test>` that is not
wrapped would move `<param>` out of scope, and Galaxy would report
`num_tests: 0` instead of a tool-loading error).

Run by aux/generate.sh after CTDConverter and after aux/parquet_bundles.py.
`--check` verifies that every entry of aux/parquet_inputs.json landed.
"""

import argparse
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SPEC = os.path.join(HERE, "parquet_inputs.json")

# Names inside a `<conditional>`: fixed, so the command blocks read the same in
# every wrapper.  Only the conditional itself is named after its parameter when
# a tool has more than one bundle input (FeatureFinderIdentification).
FILE_CASE = "file"
BUNDLE_CASE = "bundle"
KIND_PARAM = "in_kind"
COND_PARAM = "input_kind"


def cond_name(param, params):
    return COND_PARAM if len(params) == 1 else "%s_%s" % (COND_PARAM, param)


def coll_name(param, params):
    return "in_bundle" if len(params) == 1 else "%s_bundle" % param


def dir_name(param, kinds, params):
    """The directory the command builds, with the extension OpenMS dispatches on."""
    cond = cond_name(param, params)
    coll = coll_name(param, params)
    if len(kinds) == 1:
        return "%s/in.%s" % (coll, kinds[0])
    return "%s/in.${%s.%s}" % (coll, cond, KIND_PARAM)


def kind_options(kinds, indent):
    names = {
        "idparquet": "identifications",
        "featureparquet": "features",
        "consensusparquet": "consensus features",
    }
    out = []
    for n, k in enumerate(kinds):
        out.append('%s  <option value="%s"%s>%s (%s)</option>'
                   % (indent, k, ' selected="true"' if n == 0 else "",
                      names.get(k, k), k))
    return out


def patch_inputs(text, param, kinds, params):
    """Wrap the single-file `<param>` in a conditional with a bundle case."""
    m = re.search(r'\n([ \t]*)<param argument="-%s" [^\n]*?/>\n' % re.escape(param), text)
    if not m:
        raise SystemExit("parquet_inputs: %s: no self-closing `-%s` input param"
                         % (param, param))
    indent = m.group(1)
    cond = cond_name(param, params)
    coll = coll_name(param, params)
    head = indent
    new = [
        '%s<conditional name="%s">' % (head, cond),
        '%s  <param name="%s" type="select" label="Input kind"'
        ' help="A Parquet bundle is a list collection holding the tables of one'
        ' bundle directory; the element names must be the file names inside it">'
        % (head, COND_PARAM),
        '%s    <option value="%s" selected="true">Single file</option>' % (head, FILE_CASE),
        '%s    <option value="%s">Parquet bundle</option>' % (head, BUNDLE_CASE),
        '%s  </param>' % head,
        '%s  <when value="%s">' % (head, FILE_CASE),
        '%s    %s' % (head, m.group(0).strip()),
        '%s  </when>' % head,
        '%s  <when value="%s">' % (head, BUNDLE_CASE),
    ]
    if len(kinds) > 1:
        new.append('%s    <param name="%s" type="select" label="Bundle kind">' % (head, KIND_PARAM))
        new.extend(kind_options(kinds, head + "    "))
        new.append('%s    </param>' % head)
    new.extend([
        '%s    <param name="%s" type="data_collection" collection_type="list"'
        ' label="Input as a Parquet bundle" help="the tables of one bundle'
        ' directory, one dataset per table"/>' % (head, coll),
        '%s  </when>' % head,
        '%s</conditional>' % head,
    ])
    return text[:m.start()] + "\n" + "\n".join(new) + "\n" + text[m.end():]


def preprocessing_block(lines, param):
    """Return (start, end) of the `mkdir`/`cp` block that stages `-<param>`.

    Two shapes occur: a plain pair of `&&`-joined lines, and an optional input
    whose staging sits inside `#if $<param>:` ... `#end if`.
    """
    cp = [i for i, l in enumerate(lines)
          if re.match(r"\s*cp '\$%s' " % re.escape(param), l)]
    if len(cp) != 1:
        raise SystemExit("parquet_inputs: %s: expected one `cp '$%s'`, found %d"
                         % (param, param, len(cp)))
    start = cp[0]
    while (start > 0 and lines[start - 1].rstrip().endswith("&&")
           and not lines[start - 1].strip().startswith("#")):
        start -= 1
    guard = "#if $%s:" % param
    if start > 0 and lines[start - 1].strip() == guard:
        start -= 1
        depth, end = 0, None
        for j in range(start, len(lines)):
            s = lines[j].strip()
            if re.match(r"#(if|for|while|try)\b", s):
                depth += 1
            elif s in ("#end if", "#end for", "#end while", "#end try"):
                depth -= 1
                if depth == 0:
                    end = j
                    break
        if end is None:
            raise SystemExit("parquet_inputs: %s: unbalanced `#if $%s:`" % (param, param))
    else:
        end = cp[0]
    return start, end


def patch_command(text, param, kinds, params):
    """Skip the staging in the bundle case and pass the rebuilt directory."""
    start = text.index("<command")
    end = text.index("</command>", start)
    head, cmd, tail = text[:start], text[start:end], text[end:]
    lines = cmd.split("\n")
    cond = cond_name(param, params)
    cond_expr = "$%s.%s" % (cond, COND_PARAM)
    bundle = "$%s.%s" % (cond, coll_name(param, params))
    directory = dir_name(param, kinds, params)

    i0, i1 = preprocessing_block(lines, param)
    block = lines[i0:i1 + 1]

    # the `-<param>` value follows the same switch; an optional input has its
    # own `#if $<param>:` around it, which belongs to the file case
    hits = [i for i, l in enumerate(lines) if l.strip() == "-" + param]
    if len(hits) != 1:
        raise SystemExit("parquet_inputs: %s: expected one `-%s` line, found %d"
                         % (param, param, len(hits)))
    vi = hits[0]
    v0 = vi - 1 if lines[vi - 1].strip() == "#if $%s:" % param else vi
    v1 = vi + 2 if vi + 2 < len(lines) and lines[vi + 2].strip() == "#end if" else vi + 1
    chunk = lines[v0:v1 + 1]
    value = lines[vi + 1]
    ind = re.match(r"(\s*)", value).group(1)
    if "$%s" % param not in value:
        raise SystemExit("parquet_inputs: %s: unexpected value line %r" % (param, value))

    # neither the staging node nor the `-<param>` value may be referenced
    # anywhere else: both are out of scope in the bundle case, so a third
    # reference (another command line, a metadata) has to be a hard error
    # instead of a silent `NameMapper.NotFound` at run time
    refs = r"\$%s\b" % re.escape(param)
    if len(re.findall(refs, cmd)) != len(re.findall(refs, "\n".join(block + chunk))):
        raise SystemExit(
            "parquet_inputs: %s: `$%s` is used outside the staging block and the"
            " `-%s` value; patching it by hand is needed" % (param, param, param))

    # splice bottom-up so the indices of the upper block stay valid
    lines[v0:v1 + 1] = (
        ["#if %s == '%s'" % (cond_expr, BUNDLE_CASE),
         "%s-%s" % (ind, param),
         "%s'%s'" % (ind, directory),
         "#else"]
        + chunk
        + ["#end if"]
    )
    lines[i0:i1 + 1] = (
        ["#if %s == '%s'" % (cond_expr, BUNDLE_CASE),
         "mkdir -p '%s' &&" % directory,
         "#for $e in %s" % bundle,
         "ln -s '$e' '%s/${e.element_identifier}' &&" % directory,
         "#end for",
         "#else"]
        + block
        + ["#end if"]
    )

    return head + "\n".join(lines) + tail


def wrap_tests(text, param, params):
    """Every `<test>` that sets `<param>` has to select the file case first."""
    cond = cond_name(param, params)
    start = text.index("<tests>")
    end = text.index("</tests>", start)
    head, body, tail = text[:start], text[start:end], text[end:]
    lines = body.split("\n")
    out, wrapped = [], 0
    for n, line in enumerate(lines):
        m = re.match(r'([ \t]*)<param name="%s" ' % re.escape(param), line)
        if not m:
            out.append(line)
            continue
        # already inside the conditional (a manual bundle test, or a second run)
        prev = [l for l in out if l.strip()][-2:]
        if any(('<conditional name="%s">' % cond) in l for l in prev):
            out.append(line)
            continue
        ind = m.group(1)
        out.extend([
            '%s<conditional name="%s">' % (ind, cond),
            '%s  <param name="%s" value="%s"/>' % (ind, COND_PARAM, FILE_CASE),
            '%s  %s' % (ind, line.strip()),
            '%s</conditional>' % ind,
        ])
        wrapped += 1
    return head + "\n".join(out) + tail, wrapped


def applied(text, param, kinds, params):
    """True when the input, its command block and every `<test>` are patched."""
    cond = cond_name(param, params)
    if '<param name="%s" type="data_collection"' % coll_name(param, params) not in text:
        return False
    if dir_name(param, kinds, params) not in text:
        return False
    start = text.index("<tests>")
    body = text[start:text.index("</tests>", start)]
    for m in re.finditer(r'[ \t]*<param name="%s" ' % re.escape(param), body):
        before = body[:m.start()].rstrip("\n").split("\n")[-2:]
        if not any(('<conditional name="%s">' % cond) in l for l in before):
            return False
    return True


def apply_params(text, params):
    for param, kinds in params.items():
        if applied(text, param, kinds, params):
            continue
        text = patch_inputs(text, param, kinds, params)
        text = patch_command(text, param, kinds, params)
        text, _ = wrap_tests(text, param, params)
    return text


def check_file(path, params, problems):
    before = open(path).read()
    after = apply_params(before, params)
    if after != before:
        missing = [p for p, k in params.items() if not applied(before, p, k, params)]
        problems.append("%s: bundle input missing for %s"
                        % (os.path.basename(path), ", ".join(missing) or "?"))


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--check", action="store_true", help="verify only, do not write")
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
            print("parquet_inputs: " + p, file=sys.stderr)
        covered = len([t for t in spec if os.path.exists(t + ".xml")])
        print("parquet_inputs: %d wrapper(s) checked, %d problem(s)"
              % (covered, len(problems)))
        return 1 if problems else 0
    print("parquet_inputs: %d wrapper(s) changed%s"
          % (len(touched), (": " + ", ".join(touched)) if touched else ""))
    return 0


if __name__ == "__main__":
    sys.exit(main())
