# Gene Ontology (bundled, derived table)

- File: `go_terms.tsv.gz`, built with `scripts/build_go_table.py`
- Source: Gene Ontology Consortium, `src/ontology/go-edit.obo` from
  https://github.com/geneontology/go-ontology (branch master), retrieved 2026-10-22
- Source SHA256: b94a2618011ce2ffaa5885603f51aa55e5bc9c69ee577d3be13709efedde49e8
- Licence: Creative Commons Attribution 4.0 (CC BY 4.0), https://geneontology.org/docs/go-citation-policy/

Kept per term: id, name, namespace, parents (is_a, part_of, genus of
intersection_of), obsolete flag, replaced_by, alternative ids and the
gocheck_do_not_annotate flag. No other content is included.

Cite: Gene Ontology Consortium (2023) The Gene Ontology knowledgebase in 2023.
Genetics 224(1):iyad031; Ashburner et al. (2000) Nat Genet 25:25–29.
