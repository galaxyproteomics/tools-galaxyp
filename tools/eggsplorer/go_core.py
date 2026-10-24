"""Most frequent informative GO terms of a genome (no network, standard library only).

GO data: Gene Ontology Consortium, CC BY 4.0, bundled in refdata_go/.

Steps
1. Map each protein's GO ids to current terms: alternative ids to their primary
   id, obsolete terms to their replacement (or dropped).
2. Propagate to all ancestors (is_a, part_of), so every protein counts once
   per term whatever level eggNOG-mapper reported.
3. Hide terms that are too general: the three roots, terms GO marks as not for
   annotation, and terms closer than MIN_DEPTH steps to the root.
4. Hide a term when a more specific descendant covers at least REDUNDANT of
   its proteins; the descendant says the same with more detail.
5. Rank the remaining terms per namespace by number of proteins.
"""

from __future__ import annotations

import csv
import gzip
from collections import defaultdict
from functools import lru_cache
from pathlib import Path

GO_PATH = Path(__file__).resolve().parent / "refdata_go" / "go_terms.tsv.gz"
ROOTS = {"GO:0008150", "GO:0003674", "GO:0005575"}
MIN_DEPTH = 3
REDUNDANT = 0.9
NAMESPACES = ("BP", "MF", "CC")


@lru_cache(maxsize=1)
def load(path: str = str(GO_PATH)):
    terms, alt = {}, {}
    with gzip.open(path, "rt", encoding="utf-8") as fh:
        for r in csv.DictReader(fh, delimiter="\t"):
            terms[r["go_id"]] = {"name": r["name"], "ns": r["namespace"],
                                 "parents": tuple(p for p in r["parents"].split(",") if p),
                                 "obsolete": r["obsolete"] == "1", "replaced_by": r["replaced_by"],
                                 "general": r["general"] == "1"}
            for a in r["alt_ids"].split(","):
                if a:
                    alt[a] = r["go_id"]
    return terms, alt


def current(go_id, terms, alt):
    """Primary, non-obsolete id for go_id, or None."""
    seen = set()
    while go_id and go_id not in seen:
        seen.add(go_id)
        go_id = alt.get(go_id, go_id)
        t = terms.get(go_id)
        if t is None:
            return None
        if not t["obsolete"]:
            return go_id
        go_id = t["replaced_by"]
    return None


def make_helpers(terms):
    @lru_cache(maxsize=None)
    def ancestors(go_id):
        out = set()
        for p in terms[go_id]["parents"]:
            if p in terms and not terms[p]["obsolete"]:
                out.add(p)
                out |= ancestors(p)
        return frozenset(out)

    @lru_cache(maxsize=None)
    def depth(go_id):
        if go_id in ROOTS:
            return 0
        ps = [p for p in terms[go_id]["parents"] if p in terms and not terms[p]["obsolete"]]
        return 1 + min((depth(p) for p in ps), default=0)

    return ancestors, depth


def top_terms(gene_go: dict[str, list[str]], n: int = 20, min_depth: int = MIN_DEPTH,
              redundant: float = REDUNDANT):
    """gene -> raw GO ids. Returns summary with the top n informative terms per namespace."""
    terms, alt = load()
    ancestors, depth = make_helpers(terms)
    genes_per_term = defaultdict(set)
    annotated = 0
    unmapped = set()
    for gene, ids in gene_go.items():
        mapped = set()
        for g in ids:
            c = current(g, terms, alt)
            if c:
                mapped.add(c)
            else:
                unmapped.add(g)
        if not mapped:
            continue
        annotated += 1
        full = set(mapped)
        for c in mapped:
            full |= ancestors(c)
        for c in full:
            genes_per_term[c].add(gene)

    counts = {t: len(g) for t, g in genes_per_term.items()}
    eligible = {t for t in counts if t not in ROOTS and not terms[t]["general"] and depth(t) >= min_depth}
    hidden = set()
    for t in eligible:
        for a in ancestors(t):
            if a in eligible and counts[t] >= redundant * counts[a]:
                hidden.add(a)
    result = {}
    for ns in NAMESPACES:
        ranked = sorted((t for t in eligible - hidden if terms[t]["ns"] == ns),
                        key=lambda t: (-counts[t], depth(t) * -1, t))[:n]
        result[ns] = [{"id": t, "name": terms[t]["name"], "genes": counts[t],
                       "pct": round(100 * counts[t] / max(1, annotated), 1), "depth": depth(t)}
                      for t in ranked]
    return {"annotated": annotated, "terms": len(counts), "unmapped": len(unmapped),
            "top": result, "min_depth": min_depth, "redundant": redundant}
