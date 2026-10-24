#!/usr/bin/env python3
"""Metabolic function completeness from eggNOG-mapper KOs, using only the
scoring logic of KEGG-Decoder.

KEGG-Decoder (MIT, B. Tully) is vendored unmodified in
third_party/kegg_decoder/. This module imports its scoring functions and
calls them directly. Its main(), plotting and clustering code never run, so
this module needs only the Python standard library and no network access.

On top of the original scores (kept identical) it adds:
  * which KOs affect each individual function (not just each scoring block),
    found by sensitivity analysis and cached in function_map.json;
  * gene-level evidence: supporting genes, copy number and missing KOs;
  * quality filters on eggNOG hits and optional KofamScan input, with
    union / consensus / single-source scoring modes.
"""

from __future__ import annotations

import argparse
import ast
import csv
import hashlib
import importlib.machinery
import importlib.util
import json
import random
import re
import sys
from pathlib import Path

DECODER_PATH = Path(__file__).resolve().parent / "third_party" / "kegg_decoder" / "KEGG_decoder.py.orig"
MAP_PATH = DECODER_PATH.with_name("function_map.json")
_KO_RE = re.compile(r"^K\d{5}$")
MODES = ("union", "consensus", "eggnog", "kofam")


# --------------------------------------------------------------------------
# Loading the vendored decoder
# --------------------------------------------------------------------------

def _load_decoder(path: Path = DECODER_PATH):
    # the upstream file is kept byte-for-byte as *.py.orig, so loaders and linters
    # that only look at *.py files leave it alone
    loader = importlib.machinery.SourceFileLoader("kegg_decoder_vendored", str(path))
    module = importlib.util.module_from_spec(importlib.util.spec_from_loader(loader.name, loader))
    loader.exec_module(module)  # top level holds only function definitions
    return module


def _introspect(path: Path = DECODER_PATH):
    """Return (function_order, scorer_names, ko_universe_per_scorer) from source."""
    tree = ast.parse(path.read_text(encoding="utf-8"))
    funcs = {n.name: n for n in tree.body if isinstance(n, ast.FunctionDef)}
    main = funcs["main"]

    function_order = None
    scorers = []
    for node in ast.walk(main):
        if (isinstance(node, ast.Assign) and len(node.targets) == 1
                and isinstance(node.targets[0], ast.Name)
                and node.targets[0].id == "function_order"):
            function_order = ast.literal_eval(node.value)
        # pathway_data.update(<scorer>(genome_data[k]))
        if (isinstance(node, ast.Call) and isinstance(node.func, ast.Attribute)
                and node.func.attr == "update" and node.args
                and isinstance(node.args[0], ast.Call)
                and isinstance(node.args[0].func, ast.Name)):
            scorers.append((node.lineno, node.args[0].func.id))
    scorers = [name for _, name in sorted(scorers)]
    if function_order is None or not scorers:
        raise RuntimeError("Unexpected KEGG_decoder.py layout; update decoder_core.py")

    universe = {}
    for name in scorers:
        kos = {c.value for c in ast.walk(funcs[name])
               if isinstance(c, ast.Constant) and isinstance(c.value, str) and _KO_RE.match(c.value)}
        universe[name] = frozenset(kos)
    return function_order, scorers, universe


_DECODER = _load_decoder()
FUNCTION_ORDER, SCORERS, SCORER_KOS = _introspect()
_SCORER_FUNCS = [getattr(_DECODER, name) for name in SCORERS]
# which scoring block produces each function
_FUNC_TO_SCORER = {f: func for func in _SCORER_FUNCS for f in func(set())}


def decoder_sha256(path: Path = DECODER_PATH) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


# --------------------------------------------------------------------------
# Scores (identical to KEGG-Decoder)
# --------------------------------------------------------------------------

def score_kos(kos, corrected: bool = False) -> dict[str, float | None]:
    """Completeness (0–1) of every KEGG-Decoder function for one genome.

    corrected=False gives exactly the published KEGG-Decoder values.
    corrected=True fixes the known bugs (see KNOWN_ISSUES), returns None for
    functions the original never evaluates, and rescales each score to its
    achievable maximum so that a complete function reads 1.0, not 0.99.
    """
    kos = set(kos)
    if corrected:
        kos |= {part for fused, parts in FUSED_KOS.items() if fused in kos for part in parts}
    result: dict[str, float] = {}
    for func in _SCORER_FUNCS:
        result.update(func(kos))
    missing = [f for f in FUNCTION_ORDER if f not in result]
    if missing:
        raise RuntimeError(f"Scorers did not return: {missing[:5]}")
    scores = {f: result[f] for f in FUNCTION_ORDER}
    return _correct(scores, kos) if corrected else scores


# --------------------------------------------------------------------------
# Improvement 1: which KOs affect each individual function
# --------------------------------------------------------------------------

def _analyse(seed: int = 0, per_density: int = 60, densities=(0.1, 0.3, 0.5, 0.7, 0.9)):
    """Sensitivity analysis of every scoring block -> (KO map, score ceilings).

    For every scoring block, each of its KOs is added to and removed from many
    background sets (empty, full and random subsets of the block). A KO is
    assigned to a function if toggling it changes that function's score in
    any background. This follows the real code paths, including AND/OR
    combinations, conditional steps and 'not in' checks. The highest score
    seen for a function is its ceiling (the original often tops out at 0.99).
    """
    rng = random.Random(seed)
    fmap: dict[str, set[str]] = {f: set() for f in FUNCTION_ORDER}
    ceiling: dict[str, float] = {f: 0.0 for f in FUNCTION_ORDER}
    for name, func in zip(SCORERS, _SCORER_FUNCS):
        universe = sorted(SCORER_KOS[name])
        backgrounds = [set(), set(universe)]
        backgrounds += [{k for k in universe if rng.random() < d}
                        for d in densities for _ in range(per_density)]
        for bg in backgrounds:
            for ko in universe:
                with_ko, without_ko = func(bg | {ko}), func(bg - {ko})
                for f, value in with_ko.items():
                    if f not in fmap:  # e.g. 'thiosulfate disproportionation': never set, not output
                        continue
                    ceiling[f] = max(ceiling[f], value, without_ko[f])
                    if value != without_ko[f]:
                        fmap[f].add(ko)
    return {f: sorted(v) for f, v in fmap.items()}, ceiling


def build_function_map(seed: int = 0, per_density: int = 60) -> dict[str, list[str]]:
    """Function -> KOs whose presence can change its score."""
    return _analyse(seed, per_density)[0]


def unassigned_kos(fmap: dict[str, list[str]]) -> dict[str, list[str]]:
    """KOs written in a scoring block that no function responds to."""
    assigned = set().union(*map(set, fmap.values()))
    return {name: sorted(kos - assigned) for name, kos in SCORER_KOS.items() if kos - assigned}


_ANALYSIS_CACHE: dict = {}


def _load_analysis(path: Path = MAP_PATH) -> dict:
    """Cached analysis, rebuilt if missing or made for a different decoder file."""
    if _ANALYSIS_CACHE:
        return _ANALYSIS_CACHE
    sha = decoder_sha256()
    data = None
    try:
        cached = json.loads(path.read_text(encoding="utf-8"))
        if cached.get("decoder_sha256") == sha and "ceilings" in cached:
            data = cached
    except (OSError, ValueError):
        pass
    if data is None:
        fmap, ceilings = _analyse()
        data = {"decoder_sha256": sha, "functions": fmap, "ceilings": ceilings}
        try:
            path.write_text(json.dumps(data, indent=1), encoding="utf-8")
        except OSError:
            pass  # read-only install: keep it in memory
    _ANALYSIS_CACHE.update(data)
    return _ANALYSIS_CACHE


def load_function_map() -> dict[str, list[str]]:
    return _load_analysis()["functions"]


def load_ceilings() -> dict[str, float]:
    return _load_analysis()["ceilings"]


# Problems in KEGG-Decoder V1.3 found by the analysis above. Scores in the
# default mode keep them, so results match the published tool; corrected
# mode (score_kos(..., corrected=True)) fixes or flags them.
_ADH_KOS = ("K13951", "K13980", "K13952", "K13953", "K13954", "K00001",
            "K00121", "K04072", "K18857", "K00114", "K00002", "K04022")
KNOWN_ISSUES = {
    "Mixed acid: Ethanol, Acetylaldehyde to Ethanol":
        "alcohol dehydrogenases are not counted in the original definition because of a coding "
        "error ('==' instead of '='); the corrected score counts them",
    "pectinesterase": "no KO is defined for this function in the original definitions, so it is not scored",
    "exo-poly-alpha-galacturonosidase": "no KO is defined for this function in the original definitions, so it is not scored",
    "nitrite oxidation": "uses the same KOs as nitrate reductase NarGH (K00370, K00371), so genomes with "
                         "a nitrate reductase also score here",
    "NADH-quinone oxidoreductase": "nuoC and nuoD are one fused gene in many Proteobacteria (nuoCD, K13378; nuoBCD, "
                                   "K13380), which the original definition does not count; the corrected score counts "
                                   "the fused gene for each of its subunits",
    "Sec-SRP": "the original definition counts the Sec and SRP genes only when secD/secF (K03072, K03074 or K12257) "
               "are present, so genomes without SecDF, for example streptococci, score 0 despite SecYEG, SecA, Ffh "
               "and FtsY; the corrected score counts these genes without that condition",
}
# Sec-SRP: genes KEGG-Decoder counts, and the secD/secF KOs it requires before counting any of them
_SEC_GATE = ("K03072", "K03074", "K12257")
_SEC_REST = ("K03073", "K03075", "K03076", "K03210", "K03217", "K03070", "K13301", "K03110", "K03071", "K03106")
NOT_EVALUATED = ("pectinesterase", "exo-poly-alpha-galacturonosidase")
# fused genes that carry several subunits of one complex (corrected mode counts them for each subunit)
FUSED_KOS = {"K13378": ("K00332", "K00333"),            # nuoCD
             "K13380": ("K00331", "K00332", "K00333")}  # nuoBCD


def same_kos_groups(fmap: dict[str, list[str]] | None = None) -> dict[str, list[str]]:
    """Function -> other functions decided by exactly the same KOs."""
    fmap = fmap or load_function_map()
    groups: dict[tuple, list[str]] = {}
    for f, kos in fmap.items():
        if kos:
            groups.setdefault(tuple(kos), []).append(f)
    return {f: [g for g in members if g != f]
            for members in groups.values() if len(members) > 1 for f in members}


def _correct(scores: dict[str, float], kos: set[str]) -> dict[str, float | None]:
    """Fix the mixed-acid bug, flag unevaluated functions, rescale to the ceiling."""
    fixed: dict[str, float | None] = dict(scores)
    if any(k in kos for k in _ADH_KOS):
        fixed["Mixed acid: Ethanol, Acetylaldehyde to Ethanol"] = 1.0
    if not any(k in kos for k in _SEC_GATE):  # same weight per gene as the original (0.083)
        fixed["Sec-SRP"] = 0.083 * sum(k in kos for k in _SEC_REST)
    ceilings = load_ceilings()
    for f, value in fixed.items():
        if f in NOT_EVALUATED:
            fixed[f] = None
        elif f != "Mixed acid: Ethanol, Acetylaldehyde to Ethanol" or value != 1.0:
            top = ceilings.get(f) or 1.0
            scaled = min(1.0, value / top)
            # weights like 3 x 0.33 or 11 x 0.09 leave complete paths at 0.99
            fixed[f] = 1.0 if scaled >= ROUNDING_SNAP else round(scaled, 2)
    return fixed


ROUNDING_SNAP = 0.985


# --------------------------------------------------------------------------
# Improvement 2 & 3: gene-level input, quality filters, KofamScan
# --------------------------------------------------------------------------

def _clean_ko(item: str) -> str | None:
    item = item.strip()
    if item.startswith("ko:"):
        item = item[3:]
    return item if _KO_RE.match(item) else None


def read_emapper(path, max_evalue: float | None = None,
                 min_score: float | None = None) -> dict[str, set[str]]:
    """KO -> genes from an emapper.annotations file, optionally filtering hits."""
    ko_genes: dict[str, set[str]] = {}
    with open(path, encoding="utf-8", newline="") as fh:
        header = None
        for line in fh:
            if line.startswith("##") or not line.strip():
                continue
            fields = line.rstrip("\n").split("\t")
            if header is None:
                header = {name.lstrip("#"): i for i, name in enumerate(fields)}
                if "KEGG_ko" not in header:
                    raise ValueError(f"{path}: no KEGG_ko column in header")
                continue
            ko_field = fields[header["KEGG_ko"]] if header["KEGG_ko"] < len(fields) else "-"
            if ko_field in ("", "-"):
                continue
            try:
                if max_evalue is not None and float(fields[header["evalue"]]) > max_evalue:
                    continue
                if min_score is not None and float(fields[header["score"]]) < min_score:
                    continue
            except (KeyError, ValueError, IndexError):
                continue  # filter requested but the value is missing or unreadable
            gene = fields[header.get("query", 0)]
            for item in ko_field.split(","):
                ko = _clean_ko(item)
                if ko:
                    ko_genes.setdefault(ko, set()).add(gene)
    return ko_genes


def read_emapper_kos(path) -> set[str]:
    """K numbers in an emapper.annotations file (no filters)."""
    return set(read_emapper(path))


def read_kofam(path, significant_only: bool = True) -> dict[str, set[str]]:
    """KO -> genes from KofamScan output (detail-tsv or mapper format).

    detail-tsv: hits above the KO's adaptive threshold are marked with '*'
    in the first column; only those are kept unless significant_only=False.
    mapper: every listed assignment is already significant.
    """
    ko_genes: dict[str, set[str]] = {}
    with open(path, encoding="utf-8", newline="") as fh:
        for line in fh:
            if line.startswith("#") or not line.strip():
                continue
            parts = line.rstrip("\n").split("\t")
            if len(parts) >= 6 and _clean_ko(parts[2]):  # detail-tsv
                if significant_only and parts[0].strip() != "*":
                    continue
                gene, kos = parts[1].strip(), [parts[2]]
            else:  # mapper
                gene, kos = parts[0].strip(), parts[1:]
            for item in kos:
                ko = _clean_ko(item)
                if ko:
                    ko_genes.setdefault(ko, set()).add(gene)
    return ko_genes


def combine(eggnog: dict[str, set[str]], kofam: dict[str, set[str]] | None = None,
            mode: str = "union"):
    """Merge sources gene by gene. Returns (KO -> genes used, KO -> source label).

    union      gene–KO pairs from either tool
    consensus  only gene–KO pairs both tools agree on
    eggnog     eggNOG only (KofamScan, if given, is used just for labels)
    kofam      KofamScan only
    """
    if mode not in MODES:
        raise ValueError(f"mode must be one of {MODES}")
    kofam = kofam or {}
    if mode in ("consensus", "kofam") and not kofam:
        raise ValueError(f"mode '{mode}' needs KofamScan input")

    used: dict[str, set[str]] = {}
    labels: dict[str, str] = {}
    for ko in set(eggnog) | set(kofam):
        e, k = eggnog.get(ko, set()), kofam.get(ko, set())
        genes = {"union": e | k, "consensus": e & k, "eggnog": e, "kofam": k}[mode]
        if genes:
            used[ko] = genes
        if kofam:
            labels[ko] = "both" if e & k else ("eggNOG only" if e else "KOfam only")
        else:
            labels[ko] = "eggNOG"
    return used, labels


def function_evidence(ko_genes: dict[str, set[str]], labels: dict[str, str] | None = None,
                      fmap: dict[str, list[str]] | None = None) -> dict[str, dict]:
    """Per function: both scores, KOs found (genes, copy number, source),
    KOs missing, functions decided by the same KOs, and known issues."""
    fmap = fmap or load_function_map()
    labels = labels or {}
    original = score_kos(ko_genes)
    corrected = score_kos(ko_genes, corrected=True)
    twins = same_kos_groups(fmap)
    present = set(ko_genes)
    out = {}
    for f in FUNCTION_ORDER:
        found = [{"ko": ko, "genes": sorted(ko_genes[ko]), "copies": len(ko_genes[ko]),
                  "source": labels.get(ko, "")}
                 for ko in fmap[f] if ko in ko_genes]
        for fused, parts in FUSED_KOS.items():  # subunits carried by a fused gene (corrected score only)
            if fused in ko_genes:
                found += [{"ko": ko, "genes": sorted(ko_genes[fused]), "copies": len(ko_genes[fused]),
                           "source": f"fused gene {fused}"} for ko in parts if ko in fmap[f] and ko not in ko_genes]
        missing = [ko for ko in fmap[f] if ko not in {x["ko"] for x in found}]
        scorer = _FUNC_TO_SCORER[f]
        # missing KOs that would raise the score of this genome if found (the real gaps)
        gaps = [ko for ko in missing if scorer(present | {ko})[f] > original[f]]
        out[f] = {"score": original[f], "score_corrected": corrected[f],
                  "found": found, "missing": missing, "gaps": gaps,
                  "genes": len({g for item in found for g in item["genes"]}),
                  "same_kos_as": twins.get(f, []), "issue": KNOWN_ISSUES.get(f, "")}
    return out


def write_matrix(samples: dict, out_path, corrected: bool = False) -> None:
    """TSV in KEGG-Decoder's layout: header 'Function' + names, one row per sample.
    Functions that cannot be evaluated (corrected mode) are written as NA."""
    with open(out_path, "w", encoding="utf-8", newline="") as fh:
        writer = csv.writer(fh, delimiter="\t", lineterminator="\n")
        writer.writerow(["Function", *FUNCTION_ORDER])
        for name, kos in samples.items():
            scores = score_kos(kos, corrected)
            writer.writerow([name, *("NA" if scores[f] is None else scores[f]
                                     for f in FUNCTION_ORDER)])


def main(argv=None) -> int:
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("-i", "--input", nargs="+", required=True, help="emapper.annotations file(s)")
    p.add_argument("-k", "--kofam", nargs="+", help="KofamScan output per sample, same order as --input")
    p.add_argument("-n", "--names", nargs="+", help="sample names (default: file stems)")
    p.add_argument("-m", "--mode", choices=MODES, default="union")
    p.add_argument("--max-evalue", type=float, help="drop eggNOG hits above this e-value")
    p.add_argument("--min-score", type=float, help="drop eggNOG hits below this bit score")
    p.add_argument("-o", "--output", required=True, help="output TSV (KEGG-Decoder layout)")
    p.add_argument("-e", "--evidence", help="optional JSON with per-function evidence")
    p.add_argument("--corrected", action="store_true",
                   help="fix known KEGG-Decoder issues and rescale to achievable maximum")
    a = p.parse_args(argv)

    names = a.names or [Path(f).name.split(".")[0] for f in a.input]
    if len(names) != len(a.input):
        p.error("--names must match --input in length")
    if a.kofam and len(a.kofam) != len(a.input):
        p.error("--kofam must match --input in length")

    used_by_sample, evidence = {}, {}
    fmap = load_function_map() if a.evidence else None
    for idx, (name, path) in enumerate(zip(names, a.input)):
        egg = read_emapper(path, a.max_evalue, a.min_score)
        kof = read_kofam(a.kofam[idx]) if a.kofam else None
        used, labels = combine(egg, kof, a.mode)
        used_by_sample[name] = used
        if a.evidence:
            evidence[name] = function_evidence(used, labels, fmap)

    write_matrix(used_by_sample, a.output, a.corrected)
    if a.evidence:
        meta = {"mode": a.mode, "corrected": a.corrected, "max_evalue": a.max_evalue,
                "min_score": a.min_score, "decoder_sha256": decoder_sha256()}
        Path(a.evidence).write_text(json.dumps({**meta, "samples": evidence}, indent=1),
                                    encoding="utf-8")
    return 0


if __name__ == "__main__":
    sys.exit(main())
