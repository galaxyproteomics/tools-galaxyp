# Upgrade ledger — OpenMS 3.2 → 3.6

One row per round. A round is closed when `manifest.py report --gate` is green.
Decisions (D*) are permanent: they explain why something is *not* fixed, so a
later round does not re-litigate it.

## Rounds

| round | date | scope | wrappers | F (fail, not allowlisted) | gate | notes |
|---|---|---|---|---|---|---|
| 0 | todo | pin upstream, snapshot 3.2 CTDs, baseline manifest | 135 | todo | todo | baseline must be taken on `openms3.2` **before** switching versions |
| 1 | todo | tool set: 7 deprecations, ~13 additions, blacklist dir-output tools | todo | n/a | todo | see `ctd-diff-3.2-3.6.md` tool set section |
| 2 | todo | params/formats: `filetypes.txt`, `hardcoded_params.json` | todo | n/a | todo | driven by `ctd_diff.py` hints only |
| 3 | todo | autotest failures by root cause | todo | todo | todo | 2-strike rule applies |
| 4 | todo | manual tests, `.ini` migration, reference refresh | todo | todo | todo | every refreshed reference needs a note below |
| 5 | todo | full run vs. round-0 baseline | todo | 0 expected | todo | |

## Decisions

| id | tool(s) | decision | reason |
|---|---|---|---|
| D1 | `MascotAdapterOnline` | **restored to `tools/openms/`** (was moved to `deprecated/` in `b5c3d845`), normalised to `profile="23.0"` + docs 3.2.0 | it is *not* removed: `MascotAdapter` went away in 3.4.0, `MascotAdapterOnline` exists through 3.6.0 (`src/topp/executables.cmake`). It stays in `aux/tools_blacklist.txt` (broken upstream, #4412) and is therefore **not regenerated** — the file is hand-maintained until round 3 re-evaluates un-blacklisting it. |
| D2 | `ParquetConverter`, `ParquetDiff`, `*-out_qpx` | blacklist / do not wrap | their outputs are *directories* of parquet files; Galaxy datasets are single files. Needs collection-in/collection-out support before it can be wrapped. |
| D3 | `Decharger`, `MetaboliteAdductDecharger`, `MaRaClusterAdapter`, `FLASHDeconv`, `IDDecoyProbability`, `ProteomicsLFQ` | keep blacklisted | pre-existing reasons in `aux/tools_blacklist.txt`, unrelated to the version jump. |
| D4 | `FileConverter` raw path | open | 3.6 moved raw handling into `RawToMzML:*` and added `-RawToMzML:reader` (`inprocess` default on Linux). The hardcoded `RawToMzML:NET_executable=mono` / `ThermoRaw_executable=ThermoRawFileParser.exe` are ignored unless `reader=external`, and `mono` is no longer a recipe dependency. Decide in round 2. |

## Reference-file refreshes (must be justified)

| file | round | justification |
|---|---|---|
| — | — | e.g. "MzTabExporter assay semantics changed (#9868); old reference baked in the 1:1 sample/assay assumption" |

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
