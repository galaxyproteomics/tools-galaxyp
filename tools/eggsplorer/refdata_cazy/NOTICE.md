# CAZy family to substrate groups (bundled, derived table)

- File: `cazy_substrates.tsv` (family, main group, all groups, dbCAN high-level substrates, excluded flag),
  built with `scripts/build_cazy_substrates.py`.
- Source of the substrate terms: dbCAN-sub family-substrate mapping of dbCAN3
  (`fam-substrate-mapping.tsv`, 75,217 bytes, SHA256
  6ea9910341050da1548d8d88bfb056bc2071ce1a9c76d63845f4d9315f3c5971), retrieved 2026-10-22 from
  https://pro.unl.edu/dbCAN2/browse_download.php?path=dbCAN_tutorial/dataset1-Carter2023/co_assembly/db
  (same content as `fam-substrate-mapping-08012023.tsv` used by run_dbcan). Only the family and its
  high-level substrate terms are kept; enzyme names and EC numbers of the source are not redistributed.
- Main groups: our reading of each family's main activity (`refdata.CAZY_MAIN_SUBSTRATE`), taken from the
  family labels that were checked against the CAZy family pages (`refdata_checks/cazy_check_2026-10.tsv`).
  The build stops when a main group is not among the groups dbCAN lists for that family
  (this removed CBM41, which dbCAN lists only for cellulose).
- Family-level assignments are coarse: many families act on several substrates. The report therefore shows
  genes of families whose main activity is a substrate separately from genes of families that can also act on it.

Cite: Zheng J, Ge Q, Yan Y, Zhang X, Huang L, Yin Y (2023) dbCAN3: automated carbohydrate-active enzyme and
substrate annotation. Nucleic Acids Res 51:W115–W121. Drula E et al. (2022) The carbohydrate-active enzyme
database: functions and literature. Nucleic Acids Res 50:D571–D577.
