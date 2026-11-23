#!/usr/bin/env python3
"""Structural diff between two snapshots of OpenMS CTD files.

A snapshot is a directory of ``<Tool>.ctd`` files as produced by
``<Tool> -write_ctd <dir>`` for one OpenMS version (see ``snapshot_ctds.sh``).

The point of this diff is to look at the *generator input* instead of at the
regenerated wrappers: it names every parameter that was added, removed,
renamed or re-typed, and maps it onto the hand-maintained files that have to
change because of it (``aux/filetypes.txt``, ``aux/hardcoded_params.json``,
``aux/tools_blacklist.txt``, the ``.ini`` fixtures in ``test-data/``).

Usage:
    ctd_diff.py OLD_DIR NEW_DIR [-f md|tsv] [--json FILE]
                [--hardcoded aux/hardcoded_params.json]
                [--filetypes aux/filetypes.txt]
                [--with-descriptions]

Exit status is always 0: this is a report, not a gate.
"""

from __future__ import annotations

import argparse
import difflib
import json
import os
import sys
import xml.etree.ElementTree as ET

FIELDS = ("type", "required", "advanced", "formats", "restrictions", "default")
ATTR = {
    "type": "type",
    "required": "required",
    "advanced": "advanced",
    "formats": "supported_formats",
    "restrictions": "restrictions",
    "default": "value",
}


# --------------------------------------------------------------------------
# parsing
# --------------------------------------------------------------------------
def parse_ctd(path):
    """Return {full_param_name: {field: value, 'desc': str}} for one CTD."""
    root = ET.parse(path).getroot()
    params = {}

    def walk(node, prefix):
        for child in node:
            if child.tag == "ITEM":
                name = prefix + child.get("name", "?")
                rec = {f: child.get(ATTR[f], "") or "" for f in FIELDS}
                rec["desc"] = child.get("description", "") or ""
                params[name] = rec
            elif child.tag == "NODE":
                walk(child, prefix + child.get("name", "?") + ":")

    for parameters in root.iter("PARAMETERS"):
        for node in parameters.findall("NODE"):
            walk(node, node.get("name", "?") + ":")
    meta = {
        "tool": root.get("ctn", os.path.basename(path)[:-4]),
        "version": root.get("version", ""),
        "docurl": root.get("docurl", ""),
    }
    return params, meta


def load_snapshot(directory):
    snap = {}
    for entry in sorted(os.listdir(directory)):
        if not entry.endswith(".ctd"):
            continue
        params, meta = parse_ctd(os.path.join(directory, entry))
        snap[meta["tool"]] = {"params": params, "meta": meta}
    return snap


def load_hardcoded(path):
    """{tool_or_None: {param: [spec, ...]}} from aux/hardcoded_params.json."""
    if not path or not os.path.exists(path):
        return {}
    with open(path) as handle:
        data = json.load(handle)
    index = {}
    for pname, spec in data.items():
        if not isinstance(spec, (list, dict)):   # "\#" comment keys
            continue
        specs = spec if isinstance(spec, list) else [spec]
        for one in specs:
            if not isinstance(one, dict):
                continue
            for tool in one.get("tools") or [None]:
                index.setdefault(tool, {}).setdefault(pname, []).append(one)
    return index


def spec_for(hardcoded, tool, name):
    """The hardcoded_params.json spec(s) that would match this CTD param."""
    short = name.rsplit(":", 1)[-1]
    for key in (tool, None):
        entry = hardcoded.get(key) or {}
        for candidate in (short, name):
            if candidate in entry:
                return entry[candidate]
    return None


def is_ignored(hardcoded, tool, name):
    """True for params CTDConverter drops anyway (hardcoded value == "@")."""
    specs = spec_for(hardcoded, tool, name)
    return bool(specs) and any(spec.get("value") == "@" for spec in specs)


def load_filetypes(path):
    if not path or not os.path.exists(path):
        return None
    names = set()
    with open(path) as handle:
        for line in handle:
            line = line.split("#", 1)[0].strip()
            if not line:
                continue
            names.add(line.split()[0])
    return names


def ctd_formats(value):
    """'*.mzML,*.mzXML' -> ['mzML', 'mzXML'] (bracket suffixes stripped)."""
    out = []
    for item in value.split(","):
        item = item.strip()
        if not item:
            continue
        item = item.lstrip("*.")
        if "[" in item:
            item = item.split("[", 1)[0]
        out.append(item)
    return out


# --------------------------------------------------------------------------
# diffing
# --------------------------------------------------------------------------
def classify(tool, name, kind, old, new, hardcoded, filetypes, all_params):
    """Impact hints: which hand-maintained file is affected."""
    hints = []
    specs = hardcoded.get(tool, {}).get(name.rsplit(":", 1)[-1])
    if specs is None and ":" in name:
        specs = hardcoded.get(tool, {}).get(name)
    if kind == "added" and specs:
        hints.append("hardcoded_params.json (entry now applies)")
    if kind == "removed":
        if specs:
            hints.append("hardcoded_params.json STALE ENTRY")
        else:
            hints.append("ini fixture/autotest")
    if kind == "changed":
        if specs:
            hints.append("hardcoded_params.json (review)")
        if old["formats"] != new["formats"]:
            hints.append("filetypes.txt")
        for field in ("required", "advanced"):
            if old[field] != new[field]:
                hints.append("wrapper structure")
                break
        if old["default"] != new["default"]:
            hints.append("behaviour")
        if old["type"] != new["type"]:
            hints.append("wrapper structure")
        if not hints:
            hints.append("description only" if set(
                k for k in FIELDS if old[k] != new[k]) == set() else "autotest")
    if kind in ("added", "changed") and filetypes is not None:
        missing = [f for f in ctd_formats(new["formats"]) if f not in filetypes]
        if missing:
            hints.append("filetypes.txt MISSING: " + ",".join(missing))
    return hints


def diff_tool(old_params, new_params, tool, hardcoded, filetypes, with_desc):
    removed = sorted(set(old_params) - set(new_params))
    added = sorted(set(new_params) - set(old_params))
    common = sorted(set(old_params) & set(new_params))

    changes = []
    for name in common:
        o, n = old_params[name], new_params[name]
        fields = [f for f in FIELDS if o[f] != n[f]]
        if with_desc and o["desc"] != n["desc"]:
            fields.append("description")
        if fields:
            changes.append((name, o, n, fields))

    # probable renames: same type, similar name, paired one-to-one greedily so
    # that a batch of moves across subtrees does not produce swapped pairs
    candidates = []
    for gone in removed:
        for came in added:
            if old_params[gone]["type"] != new_params[came]["type"]:
                continue
            if gone.rsplit(":", 1)[-1] == came.rsplit(":", 1)[-1]:
                continue
            ratio = difflib.SequenceMatcher(None, gone, came).ratio()
            if ratio >= 0.75:
                candidates.append((ratio, gone, came))
    renames = []
    for ratio, gone, came in sorted(candidates, reverse=True):
        if gone in removed and came in added:
            renames.append((gone, came, ratio))
            removed.remove(gone)
            added.remove(came)
    renames.sort()
    return {"removed": removed, "added": added, "changed": changes, "renames": renames}


# --------------------------------------------------------------------------
# reporting
# --------------------------------------------------------------------------
def render_actions(old_snap, new_snap, diffs, hardcoded, filetypes):
    """Aggregate the deltas into the concrete edits only a human can decide."""
    formats = {}
    struct = {}
    renames = []
    for tool, d in sorted(diffs.items()):
        for name, o, n, fields in d["changed"]:
            if "formats" in fields and filetypes is not None:
                for fmt in ctd_formats(n["formats"]):
                    if fmt not in filetypes:
                        formats.setdefault(fmt, set()).add(tool)
            structural = sorted(set(fields) & {"type", "required", "advanced"})
            if structural:
                struct.setdefault(tool, []).append("%s (%s)" % (name, ", ".join(structural)))
        for name in d["added"]:
            if filetypes is not None:
                for fmt in ctd_formats(new_snap[tool]["params"][name]["formats"]):
                    if fmt not in filetypes:
                        formats.setdefault(fmt, set()).add(tool)
        renames += [(tool, gone, came) for gone, came, _r in d["renames"]]

    short = {t: {p.rsplit(":", 1)[-1] for p in s["params"]} for t, s in new_snap.items()}
    everywhere = set().union(*short.values()) if short else set()
    stale = []
    for key, entry in hardcoded.items():
        for pname, specs in entry.items():
            if any(spec.get("value") == "@" for spec in specs):
                continue          # dropping a blacklist entry for a vanished param is harmless
            base = pname.rsplit(":", 1)[-1]
            if key is None and base not in everywhere:
                stale.append((pname, "all tools"))
            elif key is None:
                continue
            elif key not in short:
                stale.append((pname, key + " (no such tool any more)"))
            elif base not in short[key]:
                stale.append((pname, key))

    out = ["## Action list", ""]
    if formats:
        out += ["### `aux/filetypes.txt` — Galaxy has no extension for these formats", ""]
        for fmt in sorted(formats):
            out.append("- `%s`: %s" % (fmt, ", ".join(sorted(formats[fmt]))))
        out.append("")
    if stale:
        out += ["### `aux/hardcoded_params.json` — entries whose parameter vanished", ""]
        for pname, where in sorted(stale):
            out.append("- `%s` (%s)" % (pname, where))
        out.append("")
    if renames:
        out += ["### renamed parameters — check `.ini` fixtures, `test-data.sh` seds and hardcoded entries", ""]
        for tool, gone, came in renames:
            out.append("- `%s`: `%s` -> `%s`" % (tool, gone, came))
        out.append("")
    if struct:
        out += ["### type/required/advanced changed — the generator handles it, verify the wrapper diff", ""]
        for tool in sorted(struct):
            out.append("- `%s`: %s" % (tool, "; ".join(struct[tool])))
        out.append("")
    if not (formats or stale or renames or struct):
        out += ["nothing to do for the hand-maintained files.", ""]
    return out


def render_md(old_snap, new_snap, diffs, old_ver, new_ver, hardcoded, filetypes):
    lines = [f"# CTD diff: {old_ver} -> {new_ver}", ""]

    gone_tools = sorted(set(old_snap) - set(new_snap))
    new_tools = sorted(set(new_snap) - set(old_snap))
    lines += ["## Tool set", ""]
    lines.append("- removed: " + (", ".join(f"`{t}`" for t in gone_tools) or "none"))
    lines.append("- added: " + (", ".join(f"`{t}`" for t in new_tools) or "none"))
    lines.append("")

    lines += ["## Summary", "",
              "| tool | + | - | ~ | rename | flags |",
              "|---|---|---|---|---|---|"]
    flagged = []
    slim = {}
    ignored_total = 0
    for tool in sorted(diffs):
        d = diffs[tool]

        def keep(name, _tool=tool):
            return not is_ignored(hardcoded, _tool, name)
        d = {"added": [n for n in d["added"] if keep(n)],
             "removed": [n for n in d["removed"] if keep(n)],
             "changed": [x for x in d["changed"] if keep(x[0])],
             "renames": d["renames"]}
        ignored_total += len(diffs[tool]["changed"]) - len(d["changed"])
        if not any(d[k] for k in ("removed", "added", "changed", "renames")):
            continue
        slim[tool] = d
        flags = set()
        for name in d["added"]:
            flags.update(classify(tool, name, "added", {}, new_snap[tool]["params"][name],
                                  hardcoded, filetypes, new_snap[tool]["params"]))
        for name in d["removed"]:
            flags.update(classify(tool, name, "removed", old_snap[tool]["params"][name], {},
                                  hardcoded, filetypes, new_snap[tool]["params"]))
        for name, o, n, _fields in d["changed"]:
            flags.update(classify(tool, name, "changed", o, n, hardcoded, filetypes,
                                  new_snap[tool]["params"]))
        for gone, came, _ratio in d["renames"]:
            flags.update(classify(tool, gone, "removed", old_snap[tool]["params"][gone],
                                  {}, hardcoded, filetypes, new_snap[tool]["params"]))
            flags.add("ini fixture/autotest")
        short = sorted(f.split(" ")[0] for f in flags)
        lines.append("| `%s` | %d | %d | %d | %d | %s |" % (
            tool, len(d["added"]), len(d["removed"]), len(d["changed"]),
            len(d["renames"]), ", ".join(sorted(set(short))) or "-"))
        flagged.append(tool)
    lines.append("")
    if ignored_total:
        lines.append(f"({ignored_total} parameter change(s) ignored: they are blacklisted in "
                     "`aux/hardcoded_params.json` and never reach the wrapper.)")
        lines.append("")
    lines += render_actions(old_snap, new_snap, slim, hardcoded, filetypes)

    lines += ["## Per tool", ""]
    for tool in flagged:
        d = slim[tool]
        lines.append(f"### `{tool}`")
        lines.append("")
        for gone, came, ratio in d["renames"]:
            hints = classify(tool, gone, "removed", old_snap[tool]["params"][gone], {},
                             hardcoded, filetypes, new_snap[tool]["params"])
            hints = [h for h in hints if h != "ini fixture/autotest"] or hints
            lines.append(f"- **rename** `{gone}` -> `{came}` (similarity {ratio:.2f})"
                         + (f"  [{'; '.join(hints)}]" if hints else ""))
        for name in d["added"]:
            p = new_snap[tool]["params"][name]
            hints = classify(tool, name, "added", {}, p, hardcoded, filetypes, {})
            lines.append(f"- **+** `{name}` ({p['type']})"
                         + (f"  [{'; '.join(hints)}]" if hints else ""))
        for name in d["removed"]:
            p = old_snap[tool]["params"][name]
            hints = classify(tool, name, "removed", p, {}, hardcoded, filetypes, {})
            lines.append(f"- **-** `{name}` ({p['type']})"
                         + (f"  [{'; '.join(hints)}]" if hints else ""))
        for name, o, n, fields in d["changed"]:
            hints = classify(tool, name, "changed", o, n, hardcoded, filetypes, {})
            detail = "; ".join(f"{f}: `{o[f] or '-'}` -> `{n[f] or '-'}`" for f in fields
                               if f != "description")
            if "description" in fields:
                detail = (detail + "; " if detail else "") + "description"
            lines.append(f"- **~** `{name}`  {detail}"
                         + (f"  [{'; '.join(hints)}]" if hints else ""))
        lines.append("")
    return "\n".join(lines) + "\n"


def render_tsv(old_snap, new_snap, diffs):
    rows = ["tool\tchange\tparam\tfield\told\tnew\thints"]
    for tool in sorted(diffs):
        d = diffs[tool]
        for name in d["added"]:
            rows.append(f"{tool}\tadded\t{name}\t\t\t")
        for name in d["removed"]:
            rows.append(f"{tool}\tremoved\t{name}\t\t\t")
        for gone, came, _ in d["renames"]:
            rows.append(f"{tool}\trenamed\t{gone}\t\t{came}\t")
        for name, o, n, fields in d["changed"]:
            for field in fields:
                rows.append(f"{tool}\tchanged\t{name}\t{field}\t{o[field]}\t{n[field]}")
    return "\n".join(rows) + "\n"


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("old", help="snapshot dir of the old version")
    parser.add_argument("new", help="snapshot dir of the new version")
    parser.add_argument("-f", "--format", choices=("md", "tsv"), default="md")
    parser.add_argument("--json", help="also write the raw diff as JSON")
    parser.add_argument("--hardcoded", default="aux/hardcoded_params.json")
    parser.add_argument("--filetypes", default="aux/filetypes.txt")
    parser.add_argument("--with-descriptions", action="store_true",
                        help="also report description-only changes (noisy)")
    args = parser.parse_args(argv)

    old_snap = load_snapshot(args.old)
    new_snap = load_snapshot(args.new)
    if not old_snap or not new_snap:
        sys.exit(f"empty snapshot: {args.old if not old_snap else args.new}")
    hardcoded = load_hardcoded(args.hardcoded)
    filetypes = load_filetypes(args.filetypes)

    diffs = {}
    for tool in sorted(set(old_snap) & set(new_snap)):
        diffs[tool] = diff_tool(old_snap[tool]["params"], new_snap[tool]["params"],
                                tool, hardcoded, filetypes, args.with_descriptions)

    old_ver = next(iter(old_snap.values()))["meta"]["version"]
    new_ver = next(iter(new_snap.values()))["meta"]["version"]
    if args.format == "tsv":
        sys.stdout.write(render_tsv(old_snap, new_snap, diffs))
    else:
        sys.stdout.write(render_md(old_snap, new_snap, diffs, old_ver, new_ver,
                                   hardcoded, filetypes))

    if args.json:
        payload = {
            "old_version": old_ver,
            "new_version": new_ver,
            "removed_tools": sorted(set(old_snap) - set(new_snap)),
            "added_tools": sorted(set(new_snap) - set(old_snap)),
            "tools": {
                tool: {
                    "added": d["added"],
                    "removed": d["removed"],
                    "renamed": [{"from": g, "to": c, "similarity": round(r, 3)}
                                for g, c, r in d["renames"]],
                    "changed": [{"param": name, "fields": f,
                                 "old": {k: o[k] for k in f},
                                 "new": {k: nn[k] for k in f}} for name, o, nn, f in d["changed"]
                                if not is_ignored(hardcoded, tool, name)],
                }
                for tool, d in diffs.items()
            },
        }
        with open(args.json, "w") as handle:
            json.dump(payload, handle, indent=2, sort_keys=True)
            handle.write("\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
