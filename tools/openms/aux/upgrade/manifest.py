#!/usr/bin/env python3
"""Test-loop bookkeeping: fingerprints + decision ledger for an OpenMS upgrade.

State of the loop is the versioned, hand-maintained part of the tool directory
(``aux/*`` and ``test-data/*``); the generated ``*.xml`` wrappers are a pure
function of it.  This script keeps the loop monotone:

* ``fingerprint`` records, per tool, a hash over the generated wrapper *and*
  every test-data file it references.  Two runs of the generator with unchanged
  inputs must reproduce the same fingerprints -- otherwise the loop cannot
  converge and you have nondeterminism or a manual edit in a generated file.
* ``changed`` names exactly the tools whose fingerprint differs from the last
  recorded round, so a round only tests those (plus everything not yet passing).
* ``record`` stores one row per tool: status, attempts, cause, decision.
  Two failed attempts without a recorded decision is the escalation trigger.
* ``report --gate`` is the exit criterion of a round.

Files (all under ``aux/upgrade/``):
  fingerprints.json   tool -> {fp, wrapper, refs, ctd}   (commit at round ends)
  teststatus.tsv      tool -> status, attempts, cause, decision, fp
  allowlist.txt       tool<TAB>reason   known-broken, not attributable to us
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
TOOLDIR = os.path.abspath(os.path.join(HERE, "..", ".."))
FINGERPRINTS = os.path.join(HERE, "fingerprints.json")
STATUS = os.path.join(HERE, "teststatus.tsv")
ALLOWLIST = os.path.join(HERE, "allowlist.txt")

# files that, when they change, invalidate every tool's result
GLOBAL_FILES = ("macros.xml", "aux/macros_test.xml", "aux/macros_autotest.xml",
                "aux/filetypes.txt", "aux/hardcoded_params.json",
                "aux/tools_blacklist.txt")

STATUS_FIELDS = ("tool", "status", "attempts", "cause", "decision", "fp", "updated")
FILENAME_RE = re.compile(r"^[\w.+\-]+\.(?:[A-Za-z0-9]{1,12}|xml|XML|raw)$")


def sha256_file(path):
    """Hash a fixture.  A directory counts as its sorted listing: 3.6 writes
    parquet outputs as directories, and prepare_test_data.sh leaves them in
    test-data/ (see get_tests.py: those intermediates are skipped, but the
    fingerprint must not crash on them)."""
    digest = hashlib.sha256()
    if os.path.isdir(path):
        for name in sorted(os.listdir(path)):
            digest.update(name.encode())
            digest.update(b"\0")
            digest.update(str(os.path.getsize(os.path.join(path, name))).encode())
        return digest.hexdigest()
    with open(path, "rb") as handle:
        for chunk in iter(lambda: handle.read(1 << 20), b""):
            digest.update(chunk)
    return digest.hexdigest()


def wrapper_paths(only=None):
    tools = []
    for entry in sorted(os.listdir(TOOLDIR)):
        if not entry.endswith(".xml") or entry == "macros.xml":
            continue
        name = entry[:-4]
        if only and name not in only:
            continue
        tools.append((name, os.path.join(TOOLDIR, entry)))
    return tools


def referenced_testdata(wrapper):
    """All basenames mentioned in the wrapper that exist in test-data/."""
    testdata = os.path.join(TOOLDIR, "test-data")
    with open(wrapper, encoding="utf-8", errors="replace") as handle:
        text = handle.read()
    candidates = set()
    for match in re.finditer(r'(?:value|file|path)="([^"]+)"', text):
        candidates.add(os.path.basename(match.group(1)))
    keep = []
    for name in sorted(candidates):
        if os.path.exists(os.path.join(testdata, name)):
            keep.append(name)
    return keep


def tool_fingerprint(tool, wrapper):
    refs = referenced_testdata(wrapper)
    digest = hashlib.sha256()
    digest.update(sha256_file(wrapper).encode())
    testdata = os.path.join(TOOLDIR, "test-data")
    for name in refs:
        digest.update(b"\0")
        digest.update(name.encode())
        digest.update(sha256_file(os.path.join(testdata, name)).encode())
    ctd = os.path.join(TOOLDIR, "ctd", tool + ".ctd")
    return {
        "fp": digest.hexdigest(),
        "wrapper": sha256_file(wrapper),
        "refs": len(refs),
        "ctd": sha256_file(ctd) if os.path.exists(ctd) else None,
    }


def cmd_fingerprint(args):
    only = set(args.tools.split(",")) if args.tools else None
    data = {"_global": {name: sha256_file(os.path.join(TOOLDIR, name))
                        for name in GLOBAL_FILES
                        if os.path.exists(os.path.join(TOOLDIR, name))},
            "tools": {}}
    for tool, wrapper in wrapper_paths(only):
        data["tools"][tool] = tool_fingerprint(tool, wrapper)

    if args.out:
        with open(args.out, "w") as handle:
            json.dump(data, handle, indent=1, sort_keys=True)
            handle.write("\n")
        print(f"{len(data['tools'])} fingerprints -> {args.out}")
        return 0

    if args.check:
        return check_idempotent(data, args.check)
    for tool, rec in sorted(data["tools"].items()):
        print(f"{tool}\t{rec['fp'][:16]}\trefs={rec['refs']}")
    return 0


def check_idempotent(current, baseline_path):
    """Fail if two generator runs produced different wrappers."""
    with open(baseline_path) as handle:
        baseline = json.load(handle)
    bad = []
    for tool, rec in current["tools"].items():
        old = baseline.get("tools", {}).get(tool)
        if old is None:
            continue
        if old["wrapper"] != rec["wrapper"]:
            bad.append(tool)
    missing = sorted(set(baseline.get("tools", {})) - set(current["tools"]))
    for tool in bad:
        print(f"NONDETERMINISTIC/EDITED: {tool}")
    for tool in missing:
        print(f"DISAPPEARED: {tool}")
    if bad or missing:
        print("\ngenerated wrappers do not match the recorded round: either the "
              "generator is not idempotent, a generated file was edited by hand, "
              "or inputs changed without regenerating everything.")
        return 1
    print(f"OK: {len(current['tools'])} wrappers byte-identical to {baseline_path}")
    return 0


def cmd_changed(args):
    baseline = args.baseline
    if not os.path.exists(baseline):
        print(f"no baseline {baseline}: everything counts as changed", file=sys.stderr)
        for tool, _ in wrapper_paths():
            print(tool)
        return 0
    with open(baseline) as handle:
        old = json.load(handle)
    with open(args.out or os.devnull, "w") as handle:
        current = {"_global": {}, "tools": {}}
        for name in GLOBAL_FILES:
            path = os.path.join(TOOLDIR, name)
            if os.path.exists(path):
                current["_global"][name] = sha256_file(path)
        for tool, wrapper in wrapper_paths():
            current["tools"][tool] = tool_fingerprint(tool, wrapper)
        json.dump(current, handle, indent=1, sort_keys=True)

    changed_global = [name for name, digest in current["_global"].items()
                      if old.get("_global", {}).get(name) != digest]
    unresolved = unresolved_tools()
    changed = []
    for tool, rec in current["tools"].items():
        oldrec = old.get("tools", {}).get(tool)
        if oldrec is None or oldrec["fp"] != rec["fp"] or tool in unresolved:
            changed.append(tool)
    if changed_global:
        print("GLOBAL CHANGE (" + ", ".join(changed_global) + "): every tool must "
              "be re-tested, not only the ones listed below.", file=sys.stderr)
        changed = sorted(current["tools"])
    for tool in sorted(changed):
        print(tool)
    return 0


def read_status():
    rows = {}
    if not os.path.exists(STATUS):
        return rows
    with open(STATUS) as handle:
        header = handle.readline().rstrip("\n").split("\t")
        for line in handle:
            if not line.strip():
                continue
            values = line.rstrip("\n").split("\t")
            row = dict(zip(header, values))
            rows[row["tool"]] = row
    return rows


def write_status(rows):
    with open(STATUS, "w") as handle:
        handle.write("\t".join(STATUS_FIELDS) + "\n")
        for tool in sorted(rows):
            row = rows[tool]
            handle.write("\t".join(str(row.get(f, "")) for f in STATUS_FIELDS) + "\n")


def read_allowlist():
    allowed = {}
    if not os.path.exists(ALLOWLIST):
        return allowed
    with open(ALLOWLIST) as handle:
        for line in handle:
            line = line.rstrip("\n")
            if not line.strip() or line.lstrip().startswith("#"):
                continue
            parts = line.split("\t")
            allowed[parts[0]] = parts[1] if len(parts) > 1 else ""
    return allowed


def unresolved_tools():
    rows = read_status()
    allowed = read_allowlist()
    out = set()
    for tool, row in rows.items():
        if row["status"] == "pass":
            continue
        if tool in allowed:
            continue
        out.add(tool)
    for tool, _ in wrapper_paths():
        if tool not in rows and tool not in allowed:
            out.add(tool)
    return out


def cmd_record(args):
    rows = read_status()
    row = rows.get(args.tool, {})
    attempts = int(row.get("attempts") or 0)
    if args.status == "fail":
        attempts = attempts + 1 if not args.reset_attempts else 1
    elif args.status == "pass":
        attempts = 0 if args.reset_attempts or args.attempt is None else args.attempt
    elif args.attempt is not None:
        attempts = args.attempt
    old = rows.get(args.tool, {})
    rows[args.tool] = {
        "tool": args.tool,
        "status": args.status,
        "attempts": attempts,
        "cause": args.cause or "",
        "decision": args.decision if args.decision is not None else old.get("decision", ""),
        "fp": args.fp or old.get("fp", ""),
        "updated": args.date,
    }
    write_status(rows)
    print(f"{args.tool}: {args.status} (attempts={attempts}, decision="
          f"{rows[args.tool]['decision'] or '-'})")
    return 0


def cmd_report(args):
    rows = read_status()
    allowed = read_allowlist()
    tools = [tool for tool, _ in wrapper_paths()]
    known = {tool: tool_fingerprint(tool, os.path.join(TOOLDIR, tool + ".xml"))
             for tool in tools}

    untested = [t for t in tools if t not in rows and t not in allowed]
    passed = [t for t in tools if rows.get(t, {}).get("status") == "pass"]
    failing = [t for t in tools if rows.get(t, {}).get("status") == "fail"]
    blocked = [t for t in tools if rows.get(t, {}).get("status") == "blocked"]
    stale = [t for t in tools
             if rows.get(t, {}).get("fp") and rows[t]["fp"] != known[t]["fp"]]
    expected_fail = [t for t in failing if t in allowed]
    real_fail = [t for t in failing if t not in allowed]
    escalate = [t for t in real_fail
                if int(rows[t]["attempts"] or 0) >= 2 and not rows[t].get("decision")]
    ghost_allow = [t for t in allowed if t not in tools]

    if not args.quiet:
        print(f"tools            : {len(tools)}")
        print(f"pass             : {len(passed)}")
        print(f"fail (allowlist) : {len(expected_fail)}")
        print(f"fail (ours)      : {len(real_fail)}")
        print(f"blocked          : {len(blocked)}")
        print(f"untested         : {len(untested)}")
        print(f"stale (fp moved) : {len(stale)}")
        print(f"escalate (2x)    : {len(escalate)}")
        if ghosts := ghost_allow:
            print(f"allowlist entries for unknown tools: {', '.join(ghosts)}")
        for label, group in (("ESCALATE", escalate), ("UNTESTED", untested),
                             ("STALE", stale), ("FAIL", real_fail)):
            if group:
                print(f"\n{label}:")
                for tool in sorted(group):
                    row = rows.get(tool, {})
                    cause = row.get("cause", "")
                    print(f"  {tool}"
                          + (f"\t{row.get('status')}" if row else "")
                          + (f"\tattempts={row.get('attempts')}" if row else "")
                          + (f"\t{cause}" if cause else ""))

    if not args.gate:
        return 0
    if escalate:
        print("\nGATE FAILED: two attempts without a recorded decision "
              "(blacklist / deprecated / lint_skip / manual test).", file=sys.stderr)
        return 1
    if real_fail:
        print("\nGATE FAILED: tools failing that are not on the allowlist.", file=sys.stderr)
        return 1
    if stale:
        print("\nGATE FAILED: results recorded against an older fingerprint; "
              "re-test the stale tools.", file=sys.stderr)
        return 1
    if untested:
        print(f"\nGATE FAILED: {len(untested)} tools never tested "
              f"(run run_tests.sh --all, or allowlist them).", file=sys.stderr)
        return 1
    print("\nGATE PASSED: no unexplained failures.")
    return 0


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--date", default=os.environ.get("ROUND", ""),
                        help="stamp for the ledger row (default: $ROUND)")
    sub = parser.add_subparsers(dest="command", required=True)

    fp = sub.add_parser("fingerprint", help="compute/verify per-tool fingerprints")
    fp.add_argument("--out", help="write JSON here instead of printing")
    fp.add_argument("--tools", help="comma separated subset")
    fp.add_argument("--check", metavar="BASELINE",
                    help="compare against a recorded fingerprints.json")
    fp.set_defaults(func=cmd_fingerprint)

    ch = sub.add_parser("changed", help="tools needing a test this round")
    ch.add_argument("--baseline", default=FINGERPRINTS)
    ch.add_argument("--out", help="write the fresh fingerprints here")
    ch.set_defaults(func=cmd_changed)

    rec = sub.add_parser("record", help="record one test outcome")
    rec.add_argument("--tool", required=True)
    rec.add_argument("--status", required=True,
                     choices=("pass", "fail", "blocked", "skip"))
    rec.add_argument("--cause", default="")
    rec.add_argument("--decision", default=None,
                     help="blacklist|deprecated|lint_skip|manual|... (escalation outcome)")
    rec.add_argument("--attempt", type=int, default=None)
    rec.add_argument("--reset-attempts", action="store_true")
    rec.add_argument("--fp", default="")
    rec.set_defaults(func=cmd_record)

    rep = sub.add_parser("report", help="round status / exit criterion")
    rep.add_argument("--gate", action="store_true", help="non-zero exit if not converged")
    rep.add_argument("--quiet", action="store_true")
    rep.set_defaults(func=cmd_report)

    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
