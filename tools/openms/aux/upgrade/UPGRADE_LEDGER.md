# Upgrade ledger — OpenMS 3.2 → 3.6

One row per round. A round is closed when `manifest.py report --gate` is green.
Decisions (D*) are permanent: they explain why something is *not* fixed, so a
later round does not re-litigate it.

## Rounds

| round | date | scope | wrappers | F (fail, not allowlisted) | gate | notes |
|---|---|---|---|---|---|---|
| 0 | 2026-11-12 | pin upstream, snapshot 3.2+3.6 CTDs | 135 | n/a | n/a | **snapshots done** (`ctd-snapshots/3.2`, `/3.6`, provenance committed); the planemo baseline is still open — planemo is not installed here |
| 1 | 2026-11-12 | tool set: 7 deprecations, blacklist dir-output tools | 128 | n/a | n/a | wrappers moved to `deprecated/tools/openms/3.2/`, `MascotAdapterOnline` restored, 4 tools blacklisted; the 15 additions happen on regeneration |
| 2 | todo | params/formats: `filetypes.txt`, `hardcoded_params.json` | todo | n/a | todo | full worklist auto-generated in `ctd-diff-3.2-3.6.md` §Action list |
| 3 | todo | autotest failures by root cause | todo | todo | todo | 2-strike rule applies |
| 4 | todo | manual tests, `.ini` migration, reference refresh | todo | todo | todo | every refreshed reference needs a note below |
| 5 | todo | full run vs. round-0 baseline | todo | 0 expected | todo | |

## Decisions

| id | tool(s) | decision | reason |
|---|---|---|---|
| D1 | `MascotAdapterOnline` | **restored to `tools/openms/`** (was moved to `deprecated/` in `b5c3d845`), normalised to `profile="23.0"` + docs 3.2.0 | it is *not* removed: `MascotAdapter` went away in 3.4.0, `MascotAdapterOnline` exists through 3.6.0 (`src/topp/executables.cmake`). It stays in `aux/tools_blacklist.txt` (broken upstream, #4412) and is therefore **not regenerated** — the file is hand-maintained until round 3 re-evaluates un-blacklisting it. |
| D2 | `ParquetConverter`, `ParquetDiff`, `*-out_qpx` | blacklist / do not wrap | their outputs are *directories* of parquet files; Galaxy datasets are single files. Needs collection-in/collection-out support before it can be wrapped. |
| D3 | `Decharger`, `MetaboliteAdductDecharger`, `MaRaClusterAdapter`, `FLASHDeconv`, `IDDecoyProbability`, `ProteomicsLFQ` | keep blacklisted | pre-existing reasons in `aux/tools_blacklist.txt`, unrelated to the version jump. |
| D6 | layout of `deprecated/` | one subdirectory per archived suite state (`3.1/`, `3.2/`), each with its own `macros.xml` + `fill_ctd.py` | a wrapper's `<requirement>` pin must match the suite it was generated from. The 7 wrappers dropped in this upgrade are 3.2-generated, the 15 older ones are 3.1-generated; one shared `macros.xml` would have made one of the two groups install the wrong OpenMS. `<import>` resolves relative to the importing file, so this needs no edit to any wrapper. |
| D5 | nested/stale `hardcoded_params.json` entries | prune in round 2 | `ctd_diff.py` lists 18 entries whose parameter no longer exists in 3.6 (`xml_out`, `separator`, `algorithm:tryptic_only`, `comet_version`, `sirius_executable`, ...). Pruning them cannot change any wrapper, so it is a pure cleanup commit. |
| D4 | `FileConverter` raw path | open | 3.6 moved raw handling into `RawToMzML:*` and added `-RawToMzML:reader` (`inprocess` default on Linux). The hardcoded `RawToMzML:NET_executable=mono` / `ThermoRaw_executable=ThermoRawFileParser.exe` are ignored unless `reader=external`, and `mono` is no longer a recipe dependency. Decide in round 2. |

## Reference-file refreshes (must be justified)

| file | round | justification |
|---|---|---|
| — | — | e.g. "MzTabExporter assay semantics changed (#9868); old reference baked in the 1:1 sample/assay assumption" |

## Round 0 — frozen upstream (done)

| what | value |
|---|---|
| old version | OpenMS `3.2.0-pre-exported-20241011`, env `~/.pi-home/envs/openms32` |
| new version | OpenMS `3.6.0` `hc52dbad_0` (bioconda), `libopenms 3.6.0 h6901f15_0`, env `~/.pi-home/envs/openms36` |
| CTD source | `<tool> -write_ctd`, one snapshot per version, `snapshot_ctds.sh` |
| coverage | 143/143 (3.2) and 152/152 (3.6) binaries of the `openms` conda package — taken from `conda-meta/openms-*.json`, not from `bin/`, because third-party binaries in the same prefix block on stdin |
| diff | `ctd-diff-3.2-3.6.{md,tsv,json}` (committed; the raw `.ctd` files are git-ignored and reproducible via the committed `provenance.txt`) |

Still open in round 0: the `planemo test --all` baseline of the 3.2 state.

## Round 1 — tool set (done)

* **deprecated** (removed upstream, moved to `deprecated/tools/openms/3.2/`):
  `IDMassAccuracy`, `MascotAdapter`, `OpenPepXLLF`, `SpecLibCreator`,
  `SpecLibSearcher`, `TriqlerConverter`, `XTandemAdapter` — 135 -> 128 wrappers.
* **blacklisted** for directory outputs (D2): `ParquetConverter`, `ParquetDiff`
  (parquet directories), `OpenSwathExport`, `OpenSwathPeakMapExtractor` (their
  only output is `out_dir`). Their `out_qpx`/`out_parquet`/`out_mod_analysis_dir`
  parameters are blacklisted in `aux/hardcoded_params.json` as well, so that
  `ProSE` etc. remain wrappable with just the file outputs.
* **new tools, not wrapped yet**: `DIAuditor`, `FeatureFinderLFQ`, `INIUpdater`,
  `IsobaricWorkflow`, `MS1LabeledWorkflow`, `OpenNuXL`, `OpenSwathExport`,
  `OpenSwathInfer`, `OpenSwathPeakMapExtractor`, `OpenSwathPercolatorScoring`,
  `ParquetConverter`, `ParquetDiff`, `PeakPickerIM`, `ProSE`, `Resampler`,
  `TransitionListEvidenceFilter`, `UniPEFF`.
  `ParquetConverter`/`ParquetDiff` are excluded by D2.
* `Resampler` and `INIUpdater` were *not* in the 3.2 conda package (they are new
  binaries), so they are genuinely new rather than forgotten wrappers.

## Round 2 — `aux/*` worklist (auto-generated)

`ctd-diff-3.2-3.6.md` §Action list carries the four buckets; the shape of it:

* `aux/filetypes.txt` misses 13 extensions that 3.6 now offers: the parquet family
  (`idparquet`, `featureparquet`, `consensusparquet`), `oswpq`, `xic`, plus
  long-standing gaps (`faa`, `ini`, `traml`, `fid`, `feature`, `msalign`,
  `cachedMzML`, `prot.xml`). Decide per format: map it (add a `gxy2omsext`
  entry) or leave unmapped (Galaxy then hides that conversion branch).
* `aux/hardcoded_params.json`: 18 vanished parameters (D5), plus new `-out_qpx`
  parameters on `ProteinQuantifier`/`ProteomicsLFQ` which D2 says to blacklist.
* renames to check in `.ini` fixtures / `test-data.sh` seds: `ProteinQuantifier:best_charge_and_fraction`,
  `MultiplexResolver`/`FeatureFinderMultiplex:missed_cleavages`, the whole
  `OpenSwathWorkflow` `RTNormalization:*` -> `Calibration:RTNormalization:*`
  move, and `FeatureFinderCentroided:debug` -> `write_debug`.
* 67 of 135 tools change structurally, but only 5 change `type`/`required`/`advanced`
  in a way that alters the generated form (`MultiplexResolver` int->double,
  `PercolatorAdapter:percolator_executable` required->optional,
  `ProteomicsLFQ:out` required->optional, `...:EMGScoring:init_mom` bool->string,
  `OpenSwathWorkflow:use_ion_mobility_scores` bool->string).

## WIP notes

* Scaffolding landed on branch `openms3.6`: `aux/upgrade/{ctd_diff.py,manifest.py,check_generated.sh,
  snapshot_ctds.sh,run_tests.sh,selftest.sh}` + this ledger. `check_generated.sh` and
  `selftest.sh` pass; no round has been closed yet.
* `check_generated.sh` currently reports one **WARN**: host paths (`/home/berntm/...`) in
  `MSFraggerAdapter.xml`, `NovorAdapter.xml` and `test-data.sh`, coming from
  `aux/hardcoded_params.json`. Cannot be fixed without regenerating, so it is a warn until
  round 2 prunes the entries, then flip the pattern in `forbidden_patterns.txt` to `fail`.

## Pre-existing gaps (carried over, not caused by this upgrade)

* 108 empty `manutest_*` stubs; `.lint_skip: TestsMissing` is global. Narrowing
  this is deliberately out of scope (deferred item 4).
* `aux/hardcoded_params.json` still contains host-specific paths
  (`maracluster_executable` → `/home/berntm/...`), `mascot_directory: TODO`, and
  entries for tools removed long ago (`xtandem_executable`, `fido_*`,
  `algorithm:tryptic_only` → `CompNovo`, `xml_out` → `XTandemAdapter`,
  `separator` → `IDMassAccuracy`). Round 2 should prune what `ctd_diff.py` flags
  as `STALE ENTRY`.
* `get_tests.py` `SKIP_LIST` still references removed tools
  (`TOPP_SiriusAdapter_*`), and `test-data.sh` carries commented `TOFCalibration`
  symlinks plus a `SiriusAdapter` sed hack.
