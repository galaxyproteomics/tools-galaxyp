#!/usr/bin/env python3
"""Eggsplorer: an interactive, self-contained HTML report from eggNOG-mapper annotations.

Standard library only, apart from plotly.js, which is read from the plotly
Python package (inline mode, the default for Galaxy) or loaded from cdnjs
(--plotly cdn). No network access is needed in inline mode.
"""

from __future__ import annotations

import argparse
import base64
import csv
import datetime as dt
import html
import json

import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

import decoder_core as dc  # noqa: E402
import refdata as rd  # noqa: E402
import go_core  # noqa: E402

TOOL_VERSION = "1.1.0"
PLOTLY_CDN = "https://cdnjs.cloudflare.com/ajax/libs/plotly.js/2.35.2/plotly.min.js"
COLUMNS = ["query", "seed_ortholog", "evalue", "score", "eggNOG_OGs", "max_annot_lvl",
           "COG_category", "Description", "Preferred_name", "GOs", "EC", "KEGG_ko",
           "KEGG_Pathway", "KEGG_Module", "KEGG_Reaction", "KEGG_rclass", "BRITE", "KEGG_TC",
           "CAZy", "BiGG_Reaction", "PFAMs"]
_CAZY_RE = re.compile(r"^(CBM|GH|GT|PL|CE|AA)(\d+)")


# --------------------------------------------------------------------------
# Reading
# --------------------------------------------------------------------------

def read_annotations(path):
    """Rows as dicts plus the '##' header lines (emapper version, date)."""
    meta_lines, rows, header = [], [], None
    with open(path, encoding="utf-8", newline="") as fh:
        for line in fh:
            if line.startswith("##"):
                meta_lines.append(line[2:].strip())
                continue
            if not line.strip():
                continue
            fields = line.rstrip("\n").split("\t")
            if header is None:
                header = [f.lstrip("#") for f in fields]
                missing = [c for c in ("query", "KEGG_ko", "COG_category") if c not in header]
                if missing:
                    raise SystemExit(f"{path}: not an eggNOG-mapper annotations file "
                                     f"(missing columns: {', '.join(missing)})")
                continue
            fields += ["-"] * (len(header) - len(fields))
            rows.append(dict(zip(header, fields)))
    if header is None:
        raise SystemExit(f"{path}: no header line found")
    return rows, meta_lines


def is_set(value):
    return value not in ("", "-", None)


def split(value):
    return [v.strip() for v in value.split(",") if v.strip()] if is_set(value) else []


def passes(row, max_evalue, min_score):
    try:
        if max_evalue is not None and float(row["evalue"]) > max_evalue:
            return False
        if min_score is not None and float(row["score"]) < min_score:
            return False
    except (KeyError, ValueError):
        return False
    return True


# --------------------------------------------------------------------------
# Summaries
# --------------------------------------------------------------------------

def top(counter, n, other_label=None):
    items = counter.most_common()
    head, tail = items[:n], items[n:]
    if other_label and tail:
        head.append((other_label, sum(c for _, c in tail)))
    return head


EC_PATH = HERE / "refdata_ec" / "ec_names.tsv.gz"


_EC_CACHE = {}


CAZY_SUB_PATH = HERE / "refdata_cazy" / "cazy_substrates.tsv"


def load_cazy_substrates(path=CAZY_SUB_PATH):
    """Family -> (main group, all groups) for degradative CAZy families (see refdata_cazy/NOTICE.md)."""
    out = {}
    with open(path, encoding="utf-8") as fh:
        for r in csv.DictReader(fh, delimiter="\t"):
            if r["excluded"] != "1":
                out[r["family"]] = (r["main_group"], r["groups"].split(","))
    return out


def cazy_by_substrate(cz_genes, bgl):
    """Genes per substrate group: 'main' = a family whose main activity is this substrate,
    'possible' = only families that can also act on it (dbCAN), counted once per gene."""
    sub_map = load_cazy_substrates()
    main_g, poss_g = defaultdict(set), defaultdict(set)
    fam_main, fam_poss = defaultdict(dict), defaultdict(dict)
    for f, genes in cz_genes.items():
        if f not in sub_map:
            continue
        main_group, groups = sub_map[f]
        for g in groups:
            if g == main_group:
                main_g[g] |= genes
                fam_main[g][f] = len(genes)
            else:
                poss_g[g] |= genes
                fam_poss[g][f] = len(genes)
    out = []
    for key, en, bg in rd.CAZY_SUBSTRATE_GROUPS:
        possible = poss_g[key] - main_g[key]
        if main_g[key] or possible:
            order = lambda d: dict(sorted(d.items(), key=lambda x: (-x[1], x[0])))  # noqa: E731
            out.append({"key": key, "label": bg if bgl else en, "main": len(main_g[key]), "possible": len(possible),
                        "main_families": order(fam_main[key]), "possible_families": order(fam_poss[key])})
    return sorted(out, key=lambda d: (-d["main"], -d["possible"]))


def load_ec_table(path=EC_PATH):
    """(names, transfers) from the bundled ENZYME table: EC -> name for current entries,
    EC -> current EC for entries transferred to a single new number."""
    if not _EC_CACHE:
        import gzip
        names, moved = {}, {}
        try:
            with gzip.open(path, "rt", encoding="utf-8") as fh:
                for r in csv.DictReader(fh, delimiter="\t"):
                    if r["obsolete"] == "0":
                        names[r["ec"]] = r["name"]
                    elif r["replaced_by"] and "," not in r["replaced_by"]:
                        moved[r["ec"]] = r["replaced_by"]
        except OSError:
            pass
        _EC_CACHE.update(names=names, moved=moved)
    return _EC_CACHE["names"], _EC_CACHE["moved"]


def load_ec_names(path=EC_PATH):
    return load_ec_table(path)[0]


def current_ec(ec, moved):
    """Follow ENZYME transfers (e.g. 1.6.5.3 -> 7.1.1.2) to the current EC number."""
    seen = set()
    while ec in moved and ec not in seen:
        seen.add(ec)
        ec = moved[ec]
    return ec


def short_desc(counter):
    """Most frequent eggNOG Description, trimmed to a short label."""
    for desc, _ in counter.most_common():
        if not is_set(desc):
            continue
        d = re.sub(r"^(PFAM|TIGRFAM|COG\d+|Pfam)\s+", "", desc.strip())
        d = re.sub(r"^Belongs to the ", "", d)
        d = d.split(". ")[0].rstrip(".")
        if len(d) > 70:
            d = d[:67].rsplit(" ", 1)[0] + "…"
        if d:
            return d[0].upper() + d[1:]
    return ""


def summarise(rows, lang, top_n, kofam=None, mode="union", max_evalue=None, min_score=None):
    bgl = lang == "bg"
    other = "Други" if bgl else "Other"
    total = len(rows)
    kept = [r for r in rows if passes(r, max_evalue, min_score)] \
        if (max_evalue is not None or min_score is not None) else rows

    # coverage
    coverage = []
    for col in COLUMNS[6:]:
        n = sum(1 for r in kept if is_set(r.get(col, "-")))
        coverage.append({"col": col, "n": n, "pct": round(100 * n / max(1, len(kept)), 1)})
    any_annot = sum(1 for r in kept if is_set(r.get("Description")) or is_set(r.get("KEGG_ko"))
                    or is_set(r.get("COG_category")))

    # taxonomy of annotation transfer
    max_lvl = Counter((r.get("max_annot_lvl") or "-").split("|")[-1] for r in kept)
    narrow = Counter()
    for r in kept:
        ogs = split(r.get("eggNOG_OGs", "-"))
        if ogs:
            narrow[ogs[-1].split("|")[-1]] += 1

    # COG
    cog_letters, multi, unassigned = Counter(), 0, 0
    for r in kept:
        cat = r.get("COG_category", "-")
        if not is_set(cat):
            unassigned += 1
            continue
        letters = {c for c in cat if c in rd.COG_CATEGORIES}
        multi += len(letters) > 1
        cog_letters.update(letters)
    with_cog = len(kept) - unassigned
    cog = [{"letter": L, "group": g, "label": (bg if bgl else en), "n": cog_letters.get(L, 0),
            "pct": round(100 * cog_letters.get(L, 0) / max(1, with_cog), 2)}
           for L, (g, en, bg) in rd.COG_CATEGORIES.items()]
    cog_groups = {k: (bg if bgl else en) for k, (en, bg) in rd.COG_GROUPS.items()}

    # KEGG pathways and modules: genes per map, KOs per map for colouring links
    path_genes, path_kos = defaultdict(set), defaultdict(set)
    mod_genes, mod_kos = defaultdict(set), defaultdict(set)
    for r in kept:
        kos = [k[3:] if k.startswith("ko:") else k for k in split(r.get("KEGG_ko", "-"))]
        maps = {("map" + p[2:]) if p.startswith("ko") else p for p in split(r.get("KEGG_Pathway", "-"))}
        for m in maps:
            if m.startswith("map"):
                path_genes[m].add(r["query"])
                path_kos[m].update(kos)
        for m in split(r.get("KEGG_Module", "-")):
            mod_genes[m].add(r["query"])
            mod_kos[m].update(kos)
    pathways = sorted(({"id": m, "genes": len(g), "kos": sorted(path_kos[m]),
                        "global": m.startswith(rd.KEGG_GLOBAL_MAP_PREFIXES)}
                       for m, g in path_genes.items()), key=lambda d: (-d["genes"], d["id"]))
    modules = sorted(({"id": m, "genes": len(g), "kos": sorted(mod_kos[m])}
                      for m, g in mod_genes.items()), key=lambda d: (-d["genes"], d["id"]))

    # EC hierarchy (genes per node) and complete EC numbers, with ENZYME names
    enzyme_names, ec_moved = load_ec_table()
    ec_nodes, ec_full = Counter(), Counter()
    for r in kept:
        nodes, full = set(), set()
        for ec in split(r.get("EC", "-")):
            ec = current_ec(ec, ec_moved)
            parts = ec.split(".")
            for depth in (1, 2, 3):
                if len(parts) >= depth and all(p not in ("-", "") for p in parts[:depth]):
                    nodes.add(".".join(parts[:depth]))
            if len(parts) == 4 and "-" not in parts:
                full.add(ec)
        ec_nodes.update(nodes)
        ec_full.update(full)
    ec_names = {k: enzyme_names.get(k, "") for k in ec_nodes}
    if bgl:  # class names have Bulgarian translations; deeper levels stay in English
        ec_names.update({k: bg for k, (en, bg) in rd.EC_CLASSES.items() if k in ec_names})
    top_enzymes = [{"ec": e, "name": enzyme_names.get(e, ""), "genes": n} for e, n in ec_full.most_common(top_n)]

    # Transporters (TC system): class -> subclass -> family, genes per family
    fam_genes, fam_desc = defaultdict(set), defaultdict(Counter)
    for r in kept:
        for t in split(r.get("KEGG_TC", "-")):
            parts = t.split(".")
            if len(parts) >= 3:
                f = ".".join(parts[:3])
                fam_genes[f].add(r["query"])
                fam_desc[f][r.get("Description", "-")] += 1
    tc_families = []
    for f, genes in sorted(fam_genes.items(), key=lambda x: (-len(x[1]), x[0])):
        curated = rd.TC_FAMILIES.get(f)
        tc_families.append({"id": f, "genes": len(genes), "curated": bool(curated),
                            "name": curated or short_desc(fam_desc[f]),
                            "subclass": ".".join(f.split(".")[:2]), "class": f.split(".")[0]})
    tc_class_names = {k: (bg if bgl else en) for k, (en, bg) in rd.TC_CLASSES.items()}
    tc_genes_total = len({g for s in fam_genes.values() for g in s})

    # CAZy families with a name: curated summary, else the typical eggNOG description
    cz_genes, cz_desc = defaultdict(set), defaultdict(Counter)
    for r in kept:
        for item in split(r.get("CAZy", "-")):
            m = _CAZY_RE.match(item)
            if m:
                f = m.group(1) + m.group(2)
                cz_genes[f].add(r["query"])
                cz_desc[f][r.get("Description", "-")] += 1
    cazy_families = []
    for f, genes in sorted(cz_genes.items(), key=lambda x: (-len(x[1]), x[0])):
        curated = rd.CAZY_FAMILIES.get(f)
        cazy_families.append({"id": f, "cls": _CAZY_RE.match(f).group(1), "genes": len(genes),
                              "curated": bool(curated), "name": curated or short_desc(cz_desc[f])})
    cazy_class = Counter()
    for f in cazy_families:
        cazy_class[f["cls"]] += f["genes"]
    cazy_names = {k: (bg if bgl else en) for k, (en, bg) in rd.CAZY_CLASSES.items()}

    # Pfam
    pfam, combos = Counter(), Counter()
    for r in kept:
        doms = sorted(set(split(r.get("PFAMs", "-"))))
        pfam.update(doms)
        if len(doms) > 1:
            combos[" + ".join(doms)] += 1

    # Gene Ontology: most frequent informative terms per namespace
    gene_go = {r["query"]: split(r.get("GOs", "-")) for r in kept if is_set(r.get("GOs", "-"))}
    go = go_core.top_terms(gene_go, n=20)

    # KEGG-Decoder functions
    ko_genes = defaultdict(set)
    for r in kept:
        for k in split(r.get("KEGG_ko", "-")):
            k = k[3:] if k.startswith("ko:") else k
            if re.match(r"^K\d{5}$", k):
                ko_genes[k].add(r["query"])
    used, labels = dc.combine(dict(ko_genes), kofam, mode)
    evidence = dc.function_evidence(used, labels)
    grouped = set()
    groups = []
    for key, en, bg, funcs in rd.DECODER_GROUPS:
        groups.append({"key": key, "label": bg if bgl else en,
                       "functions": [f for f in funcs if f in evidence]})
        grouped.update(funcs)
    rest = [f for f in dc.FUNCTION_ORDER if f not in grouped]
    if rest:
        groups.append({"key": "other", "label": other, "functions": rest})

    # gene table (compact rows)
    table = [[r["query"], r.get("Preferred_name", "-"), r.get("Description", "-"),
              r.get("COG_category", "-"),
              ",".join(k[3:] if k.startswith("ko:") else k for k in split(r.get("KEGG_ko", "-"))) or "-",
              r.get("EC", "-"), r.get("CAZy", "-"), r.get("KEGG_TC", "-"), r.get("PFAMs", "-"),
              (r.get("max_annot_lvl") or "-").split("|")[-1]]
             for r in kept]

    return {
        "counts": {"proteins": total, "kept": len(kept), "annotated": any_annot,
                   "kos": len(ko_genes), "ko_genes": sum(1 for r in kept if is_set(r.get("KEGG_ko"))),
                   "cog_multi": multi, "cog_unassigned": unassigned, "with_cog": with_cog,
                   "pathways": len([p for p in pathways if not p["global"]]), "modules": len(modules),
                   "transporters": tc_genes_total},
        "coverage": coverage,
        "taxonomy": {"max_lvl": top(max_lvl, 12, other), "narrow": top(narrow, 12, other)},
        "cog": cog, "cog_groups": cog_groups, "go": go,
        "pathways": pathways, "modules": modules[:max(top_n, 40)],
        "ec": {"nodes": dict(ec_nodes), "names": ec_names, "top_enzymes": top_enzymes},
        "tc": {"families": tc_families, "class_names": tc_class_names, "subclass_names": rd.TC_SUBCLASSES},
        "cazy": {"class": dict(cazy_class), "families": cazy_families, "names": cazy_names,
                 "substrates": cazy_by_substrate(cz_genes, bgl)},
        "pfam": {"top": top(pfam, top_n), "combos": top(combos, 15), "total": len(pfam)},
        "decoder": {"groups": groups, "evidence": evidence, "issues": dc.KNOWN_ISSUES,
                    "mode": mode, "kofam": bool(kofam)},
        "cell": {"kos": {k: sorted(used.get(k, ())) for k in rd.CELL_EXTRA_KOS}},
        "cycles": {"kos": {k: sorted(used.get(k, ())) for k in rd.CYCLE_EXTRA_KOS}},
        "table": table,
    }


# --------------------------------------------------------------------------
# Text
# --------------------------------------------------------------------------

STRINGS = {
    "en": {
        "lang": "en", "title": "Functional profile", "proteins": "proteins",
        "nav_overview": "Overview", "nav_tax": "Taxonomy", "nav_cog": "COG", "nav_go": "GO",
        "cog_short": {"A": "RNA processing", "B": "Chromatin", "C": "Energy production", "D": "Cell cycle, division", "E": "Amino acid metabolism", "F": "Nucleotide metabolism", "G": "Carbohydrate metabolism", "H": "Coenzyme metabolism", "I": "Lipid metabolism", "J": "Translation", "K": "Transcription", "L": "Replication and repair", "M": "Cell wall and membrane", "N": "Cell motility", "O": "Protein turnover, chaperones", "P": "Inorganic ion transport", "Q": "Secondary metabolites", "R": "General function prediction", "S": "Function unknown", "T": "Signal transduction", "U": "Secretion, vesicles", "V": "Defense mechanisms", "W": "Extracellular structures", "X": "Mobilome", "Y": "Nuclear structure", "Z": "Cytoskeleton"},
        "nav_cell": "Cell overview",
        "cell_title": "Cell overview",
        "cell_note": "Components found in this genome, placed where they act in the cell: respiratory chain on top, uptake systems on the left, secretion and export on the right, the largest transporter families and motility at the bottom, metabolic function groups inside. Colours show completeness, as in Metabolic functions. A component is drawn when its score is at least 0.50; components with fewer genes or none are listed under the drawing.",
        "cell_zone_resp": "respiratory chain and ATP synthase", "cell_zone_up": "uptake", "cell_zone_ex": "secretion and export",
        "cell_zone_bot": "transporter families · motility and attachment",
        "cell_nf": "Not found in this genome", "cell_nf_all": "Every component of the template was found.",
        "cell_nf_resp": "Respiratory chain", "cell_nf_up": "Uptake", "cell_nf_ex": "Secretion and export",
        "cell_nf_surf": "Motility and attachment", "cell_nf_groups": "Functional groups",
        "cell_frag": "Only a few genes found (score below 0.50, not drawn)",
        "cell_nf_shared": "Same proteins as a drawn component", "cell_without": "without {g}",
        "cell_wallless": "No cell wall", "cell_wallless_s": "no peptidoglycan genes",
        "cell_complete": "complete", "cell_partial": "partial", "cell_genes": "genes",
        "cell_diderm": "Diderm envelope", "cell_monoderm": "Monoderm envelope", "cell_diderm_s": "lpxC · lptD · bamA", "cell_monoderm_s": "no LPS markers",
        "cell_l_full": "complete", "cell_l_mid": "0.50–0.99", "cell_l_low": "below 0.50", "cell_l_tc": "transporter family",
        "cell_l_wall": "cell wall (monoderm)", "cell_l_peri": "periplasm (diderm)",
        "cell_caveat": "Genetic potential, not activity. A component may be missing because the genome or its annotation is incomplete. The envelope is drawn as diderm when BamA is found together with lipid A synthesis (LpxA, LpxC, LpxD) or LPS transport (LptD), and a cell wall only with peptidoglycan synthesis (Mur enzymes, MraY); this says nothing about Gram staining or mycolic-acid membranes. When every gene of a component also belongs to a better-scoring one (one gene can carry several KOs), only the better one is drawn. Methanogenesis is drawn only with methyl-coenzyme M reductase (mcrABG). Carbohydrate-active enzymes are not drawn as secreted, because that needs a signal-peptide prediction that eggNOG does not provide.",
        "cell_tiles": {"carbon": "Central carbon", "ferment": "Fermentation", "fixation": "C fixation and C1", "methano": "Methanogenesis",
                       "photo": "Phototrophy", "nitrogen": "Nitrogen cycle", "sulfur": "Sulfur cycle", "hydrogen": "Hydrogenases",
                       "polysacch": "Polysaccharides", "storage": "Storage", "amino": "Amino acids", "vitamins": "B vitamins",
                       "terpen": "Terpenoids", "degrade": "Detoxification"},
        "nav_cy": "Element cycles",
        "cy_title": "Nitrogen, sulfur and carbon cycle steps",
        "cy_note": "Each arrow is one step of the cycle, coloured by the corrected completeness score of its genes (the same scores as in Metabolic functions).",
        "cy_n": "Nitrogen", "cy_s": "Sulfur", "cy_c": "Carbon fixation, C1 and hydrogen",
        "cy_read_t": "How to read it",
        "cy_read": "Colour and width give the completeness of the genes for a step; the label names the genes and the number of proteins found. Dashed grey arrows are steps with no genes found. Hover an arrow for details. The diagrams show genetic potential, not activity.",
        "cy_caveat": "Nitrite oxidation (nxrAB) and nitrate reduction (narGH) share the same KOs, so both arrows light up together; the direction cannot be told from KOs alone. Ammonia and methane monooxygenases (amoABC, pmoABC) also share KOs, so ammonia and methane oxidation light up together. DNRA is drawn only with the respiratory nitrite reductase NrfA; with NirBD or NirA alone the arrow is nitrite assimilation, and nitrate reduction by NasA or NarB alone is nitrate assimilation. A step whose catalytic subunit is missing (for example phsA, soxB, norB) is drawn pale whatever its score. In the sulfur diagram the outer arrows are dissimilatory sulfate reduction and the inner ones assimilation (KEGG module M00176); ATP sulfurylase (sat) serves both, so the outer sulfate ⇄ APS arrow also lights in genomes that only assimilate sulfate, and sulfate reduction also needs aprAB and dsrAB. TsdA and DoxDA oxidise thiosulfate to tetrathionate, the Sox system to sulfate. Partial scores for the 3-hydroxypropionate routes usually come from enzymes shared with central metabolism and do not by themselves indicate CO₂ fixation; the CBB cycle needs RuBisCO and phosphoribulokinase (prk; RuBisCO-like proteins share the RuBisCO KO), the serine pathway malyl-CoA lyase (mcl), the RuMP pathway Hps and Phi (hxlAB), and methanogenesis methyl-coenzyme M reductase (mcrABG).",
        "cy_l_full": "complete (1.00)", "cy_l_mid": "0.50–0.99", "cy_l_low": "below 0.50", "cy_absent": "absent", "cy_na": "not scored",
        "cy_gene": "gene", "cy_genes": "genes",
        "cy_shared": "In this genome these steps rest on the same proteins, so the KOs alone cannot tell which of them the proteins perform (dashed when both are drawn):",
        "cy_nocore": "no {k}", "cy_l_shared": "same proteins as another step",
        "nav_func": "Metabolic functions", "nav_tr": "Transporters",
        "nav_enz": "Enzymes and CAZy", "nav_dom": "Domains", "nav_table": "Genes",
        "kpi_proteins": "Proteins", "kpi_annotated": "Functionally annotated",
        "kpi_ko": "With a KEGG KO", "kpi_kos": "Unique KOs", "kpi_func": "Metabolic functions present", "kpi_complete": "complete",
        "cov_title": "Coverage by column", "cov_note": "Share of proteins with at least one value in each eggNOG-mapper column.",
        "tax_title": "Level of annotation transfer",
        "tax_maxlvl": "max_annot_lvl: broadest level the annotation was taken from",
        "tax_narrow": "Narrowest orthologous group (last in eggNOG_OGs)",
        "tax_note": "If nearly everything sits at one level, annotations were transferred from one taxonomic group. A large share at Bacteria or root means broader, less certain annotations.",
        "cog_title": "COG functional categories",
        "cog_note": "Share of proteins with a COG category. A protein with several letters (e.g. 'KT') is counted in each of them.",
        "cog_multi": "proteins with more than one category", "cog_unassigned": "without a COG category",
        "cog_hover": "Point at a category for its full name, number of proteins and share.",
        "cog_letter": "COG", "cog_cat": "Category", "cog_n": "Proteins", "cog_pct": "%",
        "go_title": "Most frequent GO terms",
        "go_note": "Top 20 terms per ontology among the {n} proteins with GO annotations ({pct} of all). Annotations are mapped to current GO terms and propagated to all parents. Very general terms are hidden (fewer than {d} steps from the root, or marked by GO as not for annotation), and so is any term when a more specific term covers at least {r} of its proteins. This is a frequency profile, not an enrichment test.",
        "go_euk": "eggNOG transfers GO terms from orthologs, so eukaryotic compartments can appear for bacterial genomes.",
        "go_bp": "Biological process", "go_mf": "Molecular function", "go_cc": "Cellular component",
        "go_term": "Term", "go_id": "GO ID", "go_n": "Proteins", "go_pct": "% of GO-annotated", "go_none": "No GO annotations.",
        "func_title": "Metabolic function completeness",
        "func_note": "Functions with at least one step present, scored with the pathway definitions of Graham et al. (2018), corrected for known issues and rescaled so that a complete function reads 100%. Click a function for its genes, KOs and missing steps.",
        "func_pick": "Choose a function to see its evidence.",
        "func_score": "Completeness", "func_found": "KOs found", "func_gaps": "Missing steps (would raise the score)",
        "func_missing": "Other checked KOs that are absent", "func_genes": "genes",
        "func_copies": "copies", "func_copy": "copy", "func_issue": "Note on the original definition", "func_twins": "Decided by the same KOs as",
        "func_none": "none", "func_legend": "Completeness", "func_count": "functions with at least one step",
        "kegg_genes": "Genes",
        "tr_title": "Transporters", "tr_note": "Genes per TC class, subclass and family (TC system, IUBMB). Band width is the number of genes; hover for details.",
        "shown_families": "The {n} largest of {total} families are shown; all are in the table below.",
        "tr_family": "Family", "tr_name": "Name", "tr_genes": "Genes", "tr_src": "Names of common families are shortened from TCDB (checked October 2026); others show the most frequent eggNOG description (marked *).",
        "enz_title": "Enzymes and carbohydrate-active enzymes", "ec_title": "Enzyme classification (EC)",
        "ec_note": "Genes per EC class, subclass and sub-subclass, named after the ENZYME nomenclature. EC numbers that were transferred are counted under their current number, so for example transport ATPases appear in class 7 (translocases).",
        "shown_ec": "The {s} largest subclasses and their {l} largest sub-subclasses are shown.",
        "ec_top": "Most frequent enzymes", "ec_name": "Enzyme", "ec_genes": "Genes",
        "cazy_title": "CAZy families", "cazy_none": "No CAZy annotations.",
        "csub_title": "Carbohydrate-active enzymes by substrate",
        "csub_note": "Degradative CAZy families grouped by the glycans they act on (GH, PL, CE, AA, CBM; glycosyltransferases build glycans and are left out). Solid: genes in families whose main activity is this substrate. Hatched: genes only in families that can also act on it. A gene is counted once per substrate. Substrates per family from dbCAN-sub (Zheng et al. 2023); family-level assignments are approximate.",
        "csub_main": "main activity", "csub_possible": "possible (multi-substrate families)", "csub_none": "No degradative CAZy families found.",
        "cazy_family": "Family", "cazy_name": "Main activity", "cazy_genes": "Genes", "cazy_link": "CAZy",
        "cazy_src": "Main activities are short summaries checked against the CAZy family pages (October 2026); families without one show the most frequent eggNOG description (marked *). The CAZy link lists all known activities.",
        "dom_title": "Pfam domains", "dom_top": "Most frequent domains (proteins)",
        "dom_combos": "Most frequent domain combinations", "dom_note": "eggNOG-mapper lists domains alphabetically, so these are combinations, not ordered architectures.",
        "table_title": "Genes", "table_search": "Search ID, gene, description, KO, EC, TC, domain…",
        "table_cog": "COG", "table_all": "All", "table_rows": "rows", "table_prev": "Previous", "table_next": "Next",
        "cols": ["ID", "Gene", "Description", "COG", "KO", "EC", "CAZy", "TC", "Pfam", "Level"],
        "footer": "Generated with Eggsplorer", "params": "Parameters",
        "sample": "Sample", "src_version": "Eggsplorer version",
        "src_file": "File", "src_emapper": "eggNOG-mapper", "src_date": "Annotation date", "other": "Other",
    },
    "bg": {
        "lang": "bg", "title": "Функционален профил", "proteins": "протеина",
        "nav_overview": "Обзор", "nav_tax": "Таксономия", "nav_cog": "COG", "nav_go": "GO",
        "cog_short": {"A": "Обработка на РНК", "B": "Хроматин", "C": "Енергиен метаболизъм", "D": "Клетъчен цикъл, делене", "E": "Метаболизъм на аминокиселини", "F": "Метаболизъм на нуклеотиди", "G": "Метаболизъм на въглехидрати", "H": "Метаболизъм на коензими", "I": "Метаболизъм на липиди", "J": "Транслация", "K": "Транскрипция", "L": "Репликация и поправка", "M": "Клетъчна стена и мембрана", "N": "Клетъчна подвижност", "O": "Белтъчен оборот, шаперони", "P": "Транспорт на неорганични йони", "Q": "Вторични метаболити", "R": "Обща функционална прогноза", "S": "Неизвестна функция", "T": "Сигнална трансдукция", "U": "Секреция, везикули", "V": "Защитни механизми", "W": "Извънклетъчни структури", "X": "Мобилом", "Y": "Ядрена структура", "Z": "Цитоскелет"},
        "nav_cell": "Клетка",
        "cell_title": "Обзор на клетката",
        "cell_note": "Компонентите, намерени в този геном, разположени там, където действат в клетката: дихателната верига отгоре, системите за поемане вляво, секрецията и изнасянето вдясно, най-големите семейства транспортери и подвижността отдолу, групите метаболитни функции вътре. Цветовете показват пълнотата, както в Метаболитни функции. Компонент се показва при оценка поне 0.50; тези с по-малко гени или без гени са изброени под схемата.",
        "cell_zone_resp": "дихателна верига и ATP синтаза", "cell_zone_up": "поемане", "cell_zone_ex": "секреция и изнасяне",
        "cell_zone_bot": "семейства транспортери · подвижност и прикрепване",
        "cell_nf": "Не са намерени в този геном", "cell_nf_all": "Всички компоненти от шаблона са намерени.",
        "cell_nf_resp": "Дихателна верига", "cell_nf_up": "Поемане", "cell_nf_ex": "Секреция и изнасяне",
        "cell_nf_surf": "Подвижност и прикрепване", "cell_nf_groups": "Функционални групи",
        "cell_frag": "Намерени са само отделни гени (оценка под 0.50, не са показани)",
        "cell_nf_shared": "Същите протеини като нарисуван компонент", "cell_without": "без {g}",
        "cell_wallless": "Без клетъчна стена", "cell_wallless_s": "няма гени за пептидогликан",
        "cell_complete": "пълни", "cell_partial": "частични", "cell_genes": "гена",
        "cell_diderm": "Двумембранна обвивка", "cell_monoderm": "Едномембранна обвивка", "cell_diderm_s": "lpxC · lptD · bamA", "cell_monoderm_s": "без LPS маркери",
        "cell_l_full": "пълна", "cell_l_mid": "0.50–0.99", "cell_l_low": "под 0.50", "cell_l_tc": "семейство транспортери",
        "cell_l_wall": "клетъчна стена (едномембранни)", "cell_l_peri": "периплазма (двумембранни)",
        "cell_caveat": "Генетичен потенциал, а не активност. Компонент може да липсва, защото геномът или анотацията са непълни. Обвивката е двумембранна, когато BamA е намерен заедно със синтез на липид A (LpxA, LpxC, LpxD) или транспорт на LPS (LptD), а клетъчна стена се рисува само при синтез на пептидогликан (Mur ензими, MraY); това не казва нищо за оцветяването по Грам или за мембрани с миколови киселини. Когато всички гени на даден компонент принадлежат и на друг с по-висока оценка (един ген може да има няколко KO), се рисува само той. Метаногенезата се рисува само при наличие на метил-коензим M редуктаза (mcrABG). Въглехидрат-активните ензими не са показани като секретирани, защото за това е нужно предсказване на сигнален пептид, което eggNOG не дава.",
        "cell_tiles": {"carbon": "Централен C", "ferment": "Ферментация", "fixation": "Фиксация на C, C1", "methano": "Метаногенеза",
                       "photo": "Фототрофия", "nitrogen": "Цикъл на азота", "sulfur": "Цикъл на сярата", "hydrogen": "Хидрогенази",
                       "polysacch": "Полизахариди", "storage": "Запасни вещества", "amino": "Аминокиселини", "vitamins": "Витамини B",
                       "terpen": "Терпеноиди", "degrade": "Детоксикация"},
        "nav_cy": "Кръговрати",
        "cy_title": "Стъпки от кръговратите на азот, сяра и въглерод",
        "cy_note": "Всяка стрелка е една стъпка, оцветена по коригираната оценка за пълнота на гените ѝ (същите оценки като в Метаболитни функции).",
        "cy_n": "Азот", "cy_s": "Сяра", "cy_c": "Фиксация на въглерод, C1 и водород",
        "cy_read_t": "Как се чете",
        "cy_read": "Цветът и дебелината показват пълнотата на гените за стъпката; надписът дава гените и броя намерени протеини. Сивите пунктирни стрелки са стъпки без намерени гени. Посочете стрелка за подробности. Схемите показват генетичен потенциал, а не активност.",
        "cy_caveat": "Окислението на нитрит (nxrAB) и редукцията на нитрат (narGH) имат едни и същи KO, затова двете стрелки светват заедно; посоката не може да се определи само по KO. Амоняк- и метан-монооксигеназите (amoABC, pmoABC) също имат общи KO, затова окислението на амоняк и на метан светват заедно. DNRA се рисува само при дихателната нитритредуктаза NrfA; само с NirBD или NirA стрелката е асимилация на нитрит, а редукцията на нитрат само с NasA или NarB е асимилация на нитрат. Стъпка без каталитичната си субединица (например phsA, soxB, norB) се рисува бледо, каквато и да е оценката ѝ. В схемата на сярата външните стрелки са дисимилационната редукция на сулфат, а вътрешните – асимилацията (KEGG модул M00176); ATP сулфурилазата (sat) участва и в двете, затова външната стрелка сулфат ⇄ APS светва и в геноми, които само асимилират сулфат, а за редукция на сулфат са нужни и aprAB и dsrAB. TsdA и DoxDA окисляват тиосулфат до тетратионат, а системата Sox – до сулфат. Частичните оценки за 3-хидроксипропионатните пътища обикновено идват от ензими, общи с централния метаболизъм, и сами по себе си не означават фиксация на CO₂; цикълът на Калвин изисква RuBisCO и фосфорибулокиназа (prk; RuBisCO-подобните протеини имат същия KO като RuBisCO), серинов път – малил-CoA лиаза (mcl), RuMP пътят – Hps и Phi (hxlAB), а метаногенезата – метил-коензим M редуктаза (mcrABG).",
        "cy_l_full": "пълна (1.00)", "cy_l_mid": "0.50–0.99", "cy_l_low": "под 0.50", "cy_absent": "липсва", "cy_na": "без оценка",
        "cy_gene": "ген", "cy_genes": "гена",
        "cy_shared": "В този геном тези стъпки се базират на едни и същи протеини, затова само по KO не може да се каже коя от тях извършват (с прекъсната линия, когато и двете са нарисувани):",
        "cy_nocore": "без {k}", "cy_l_shared": "същите протеини като друга стъпка",
        "nav_func": "Метаболитни функции", "nav_tr": "Транспортери",
        "nav_enz": "Ензими и CAZy", "nav_dom": "Домейни", "nav_table": "Гени",
        "kpi_proteins": "Протеини", "kpi_annotated": "С функционална анотация",
        "kpi_ko": "С KEGG KO", "kpi_kos": "Уникални KO", "kpi_func": "Налични метаболитни функции", "kpi_complete": "пълни",
        "cov_title": "Покритие по колони", "cov_note": "Дял на протеините с поне една стойност във всяка колона на eggNOG-mapper.",
        "tax_title": "Ниво на пренос на анотацията",
        "tax_maxlvl": "max_annot_lvl: най-широкото ниво, от което е взета анотацията",
        "tax_narrow": "Най-тясна ортоложна група (последната в eggNOG_OGs)",
        "tax_note": "Ако почти всичко е на едно ниво, анотацията е пренесена от една таксономична група. Голям дял на Bacteria или root означава по-обща и по-несигурна анотация.",
        "cog_title": "COG функционални категории",
        "cog_note": "Дял от протеините с COG категория. Протеин с няколко букви (напр. „KT“) се брои във всяка от тях.",
        "cog_multi": "протеина с повече от една категория", "cog_unassigned": "без COG категория",
        "cog_hover": "Посочете категория за пълното ѝ име, броя протеини и дела.",
        "cog_letter": "COG", "cog_cat": "Категория", "cog_n": "Протеини", "cog_pct": "%",
        "go_title": "Най-чести GO термини",
        "go_note": "Топ 20 термина за всяка онтология сред {n} протеина с GO анотация ({pct} от всички). Анотациите са приведени към текущите GO термини и разпространени към всички родители. Скрити са твърде общите термини (по-близо от {d} стъпки до корена или отбелязани от GO като неподходящи за анотация), както и термин, когато по-специфичен термин покрива поне {r} от протеините му. Това е честотен профил, не тест за обогатяване.",
        "go_euk": "eggNOG пренася GO термини от ортолози, затова при бактериални геноми може да се появят и еукариотни компартменти.",
        "go_bp": "Биологичен процес", "go_mf": "Молекулна функция", "go_cc": "Клетъчен компонент",
        "go_term": "Термин", "go_id": "GO ID", "go_n": "Протеини", "go_pct": "% от тези с GO", "go_none": "Няма GO анотации.",
        "func_title": "Пълнота на метаболитни функции",
        "func_note": "Функции с поне една налична стъпка, оценени по дефинициите на пътищата от Graham et al. (2018), с поправени известни грешки и мащабирани така, че пълна функция да е 100%. Кликни функция за гените, KO и липсващите стъпки.",
        "func_pick": "Избери функция, за да видиш доказателствата.",
        "func_score": "Пълнота", "func_found": "Намерени KO", "func_gaps": "Липсващи стъпки (биха повишили стойността)",
        "func_missing": "Други проверявани KO, които липсват", "func_genes": "гена",
        "func_copies": "копия", "func_copy": "копие", "func_issue": "Бележка за оригиналната дефиниция", "func_twins": "Решава се от същите KO като",
        "func_none": "няма", "func_legend": "Пълнота", "func_count": "функции с поне една стъпка",
        "kegg_genes": "Гени",
        "tr_title": "Транспортери", "tr_note": "Гени по TC клас, подклас и семейство (TC система, IUBMB). Ширината на лентата е броят гени; посочи за подробности.",
        "shown_families": "Показани са най-големите {n} от {total} семейства; всички са в таблицата по-долу.",
        "tr_family": "Семейство", "tr_name": "Име", "tr_genes": "Гени", "tr_src": "Имената на честите семейства са съкратени от TCDB (сверени през октомври 2026); за останалите е показано най-честото описание от eggNOG (със *).",
        "enz_title": "Ензими и въглехидрат-активни ензими", "ec_title": "Класификация на ензимите (EC)",
        "ec_note": "Гени по EC клас, подклас и под-подклас, с имена по номенклатурата ENZYME. Прехвърлените EC номера се броят под текущия си номер, затова например транспортните ATPази са в клас 7 (транслокази).",
        "shown_ec": "Показани са най-големите {s} подкласа и техните {l} най-големи под-подкласа.",
        "ec_top": "Най-чести ензими", "ec_name": "Ензим", "ec_genes": "Гени",
        "cazy_title": "CAZy семейства", "cazy_none": "Няма CAZy анотации.",
        "csub_title": "Въглехидрат-активни ензими по субстрат",
        "csub_note": "Разграждащите CAZy семейства, групирани по гликаните, върху които действат (GH, PL, CE, AA, CBM; гликозилтрансферазите синтезират и са изключени). Плътно: гени от семейства с основна активност върху този субстрат. Щриховано: гени само от семейства, които могат да действат и върху него. Всеки ген се брои веднъж за субстрат. Субстратите по семейства са от dbCAN-sub (Zheng et al. 2023); отнасянето на ниво семейство е приблизително.",
        "csub_main": "основна активност", "csub_possible": "възможна (семейства с няколко субстрата)", "csub_none": "Няма разграждащи CAZy семейства.",
        "cazy_family": "Семейство", "cazy_name": "Основна активност", "cazy_genes": "Гени", "cazy_link": "CAZy",
        "cazy_src": "Основните активности са кратки обобщения, сверени със страниците на семействата в CAZy (октомври 2026); за семейства без такова е показано най-честото описание от eggNOG (със *). Линкът към CAZy показва всички известни активности.",
        "dom_title": "Pfam домейни", "dom_top": "Най-чести домейни (брой протеини)",
        "dom_combos": "Най-чести комбинации от домейни", "dom_note": "eggNOG-mapper изброява домейните по азбучен ред, затова това са комбинации, а не подредени архитектури.",
        "table_title": "Гени", "table_search": "Търси по ID, ген, описание, KO, EC, TC, домейн…",
        "table_cog": "COG", "table_all": "Всички", "table_rows": "реда", "table_prev": "Назад", "table_next": "Напред",
        "cols": ["ID", "Ген", "Описание", "COG", "KO", "EC", "CAZy", "TC", "Pfam", "Ниво"],
        "footer": "Генерирано с Eggsplorer", "params": "Параметри",
        "sample": "Проба", "src_version": "Версия на Eggsplorer",
        "src_file": "Файл", "src_emapper": "eggNOG-mapper", "src_date": "Дата на анотацията", "other": "Други",
    },
}


# --------------------------------------------------------------------------
# Output
# --------------------------------------------------------------------------

def plotly_script(mode):
    if mode == "cdn":
        return f'<script src="{PLOTLY_CDN}"></script>'
    import plotly  # only used to locate the bundled plotly.min.js
    js = (Path(plotly.__file__).parent / "package_data" / "plotly.min.js").read_text(encoding="utf-8")
    return "<script>" + js.replace("</script", "<\\/script") + "</script>"


FONTS = [  # family, weight, file in fonts/ (IBM Plex, SIL OFL 1.1, embedded unchanged)
    ("IBM Plex Sans", 400, "IBMPlexSans-Regular"), ("IBM Plex Sans", 500, "IBMPlexSans-Medium"),
    ("IBM Plex Sans", 600, "IBMPlexSans-SemiBold"), ("IBM Plex Sans Condensed", 500, "IBMPlexSansCondensed-Medium"),
    ("IBM Plex Sans Condensed", 600, "IBMPlexSansCondensed-SemiBold"), ("IBM Plex Mono", 400, "IBMPlexMono-Regular"),
    ("IBM Plex Mono", 500, "IBMPlexMono-Medium"),
]


def font_faces():
    """@font-face rules with the bundled fonts as data URIs, so the report loads no web fonts."""
    rules = []
    for family, weight, name in FONTS:
        data = base64.b64encode((HERE / "fonts" / f"{name}.woff2").read_bytes()).decode("ascii")
        rules.append(f"@font-face{{font-family:'{family}';font-style:normal;font-weight:{weight};font-display:swap;"
                     f"src:url(data:font/woff2;base64,{data}) format('woff2');}}")
    return "<style>" + "".join(rules) + "</style>"


def render(data, strings, plotly_mode, fragment):
    template = (HERE / "report_template.html").read_text(encoding="utf-8")
    shown = {k: v for k, v in data.items() if k not in ("pathways", "modules")}  # pathways/modules go to the tables only
    payload = json.dumps({"d": shown, "t": strings}, ensure_ascii=False, separators=(",", ":"))
    payload = payload.replace("</", "<\\/")  # safe inside <script>
    page = (template.replace("__TITLE__", html.escape(f'{data["meta"]["sample"]} · {strings["title"]}'))
            .replace("__LANG__", strings["lang"])
            .replace("__FONTS__", font_faces())
            .replace("__PLOTLY__", plotly_script(plotly_mode))
            .replace("__DATA__", payload))
    if fragment:
        return page
    head, body = page.split("<!-- head-end -->", 1)
    return ("<!doctype html>\n<html lang=\"" + strings["lang"] + "\">\n<head>\n<meta charset=\"utf-8\">\n"
            "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1, viewport-fit=cover\">\n"
            + head + "</head>\n<body>\n" + body + "\n</body>\n</html>\n")


def write_tables(data, out_dir):
    out = Path(out_dir)
    out.mkdir(parents=True, exist_ok=True)

    def tsv(name, header, rows):
        with open(out / name, "w", encoding="utf-8", newline="") as fh:
            w = csv.writer(fh, delimiter="\t", lineterminator="\n")
            w.writerow(header)
            w.writerows(rows)

    tsv("cog_categories.tsv", ["letter", "group", "description", "proteins"],
        [[c["letter"], c["group"], c["label"], c["n"]] for c in data["cog"]])
    tsv("kegg_pathways.tsv", ["map_id", "genes", "global_map", "kos"],
        [[p["id"], p["genes"], int(p["global"]), ",".join(p["kos"])] for p in data["pathways"]])
    tsv("kegg_modules.tsv", ["module_id", "genes", "kos"],
        [[m["id"], m["genes"], ",".join(m["kos"])] for m in data["modules"]])
    tsv("ec_hierarchy.tsv", ["ec_node", "name", "genes"],
        [[k, data["ec"]["names"].get(k, ""), v] for k, v in sorted(data["ec"]["nodes"].items())])
    tsv("cazy_substrates.tsv", ["substrate", "genes_main", "genes_possible_only", "main_families", "possible_families"],
        [[c["label"], c["main"], c["possible"], ",".join(f"{k}:{v}" for k, v in c["main_families"].items()),
          ",".join(f"{k}:{v}" for k, v in c["possible_families"].items())] for c in data["cazy"]["substrates"]])
    tsv("cazy_families.tsv", ["family", "class", "name", "name_source", "proteins"],
        [[f["id"], f["cls"], f["name"], "curated" if f["curated"] else "eggNOG", f["genes"]]
         for f in data["cazy"]["families"]])
    tsv("tc_families.tsv", ["tc_family", "subclass", "name", "name_source", "proteins"],
        [[f["id"], f["subclass"], f["name"], "TCDB" if f["curated"] else "eggNOG", f["genes"]]
         for f in data["tc"]["families"]])
    tsv("pfam_domains.tsv", ["domain", "proteins"], data["pfam"]["top"])
    tsv("go_top_terms.tsv", ["namespace", "go_id", "name", "proteins", "pct_of_go_annotated", "depth"],
        [[ns, t["id"], t["name"], t["genes"], t["pct"], t["depth"]]
         for ns, items in data["go"]["top"].items() for t in items])
    ev = data["decoder"]["evidence"]
    tsv("metabolic_functions.tsv",
        ["function", "score", "score_corrected", "genes", "kos_found", "gaps"],
        [[f, e["score"], "NA" if e["score_corrected"] is None else e["score_corrected"],
          e["genes"], ",".join(x["ko"] for x in e["found"]), ",".join(e["gaps"])]
         for f, e in ev.items()])


def main(argv=None):
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("-i", "--input", required=True, help="eggNOG-mapper .emapper.annotations")
    p.add_argument("-n", "--name", help="sample name shown in the report")
    p.add_argument("-o", "--output", required=True, help="HTML report")
    p.add_argument("--tables", help="directory for summary TSV tables")
    p.add_argument("-k", "--kofam", help="optional KofamScan output (detail-tsv or mapper)")
    p.add_argument("-m", "--mode", choices=dc.MODES, default="union")
    p.add_argument("--max-evalue", type=float)
    p.add_argument("--min-score", type=float)
    p.add_argument("--top-n", type=int, default=25)
    p.add_argument("--lang", choices=sorted(STRINGS), default="en")
    p.add_argument("--plotly", choices=("inline", "cdn"), default="inline")
    p.add_argument("--fragment", action="store_true", help="write the page body only (no <html> wrapper)")
    p.add_argument("--version", action="version", version=f"Eggsplorer {TOOL_VERSION}")
    a = p.parse_args(argv)

    if a.mode in ("consensus", "kofam") and not a.kofam:
        p.error(f"--mode {a.mode} needs --kofam")
    rows, meta_lines = read_annotations(a.input)
    kofam = dc.read_kofam(a.kofam) if a.kofam else None
    data = summarise(rows, a.lang, a.top_n, kofam, a.mode, a.max_evalue, a.min_score)

    version = next((m for m in meta_lines if m.startswith("emapper")), "")
    date = meta_lines[0] if meta_lines and not meta_lines[0].startswith("emapper") else ""
    name = a.name or Path(a.input).name.split(".")[0]
    data["meta"] = {"sample": name, "file": Path(a.input).name, "emapper": version, "date": date,
                    "generated": dt.date.today().isoformat(), "tool_version": TOOL_VERSION,
                    "decoder_sha256": dc.decoder_sha256()[:12],
                    "params": {"mode": a.mode, "max_evalue": a.max_evalue, "min_score": a.min_score,
                               "kofam": bool(a.kofam), "top_n": a.top_n}}

    Path(a.output).parent.mkdir(parents=True, exist_ok=True)
    Path(a.output).write_text(render(data, STRINGS[a.lang], a.plotly, a.fragment), encoding="utf-8")
    if a.tables:
        write_tables(data, a.tables)
    return 0


if __name__ == "__main__":
    sys.exit(main())
