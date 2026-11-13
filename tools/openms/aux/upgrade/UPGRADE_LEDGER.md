# Upgrade ledger — OpenMS 3.2 → 3.6

One row per round. A round is closed when `manifest.py report --gate` is green.
Decisions (D*) are permanent: they explain why something is *not* fixed, so a
later round does not re-litigate it.

## Rounds

| round | date | scope | wrappers | F (fail, not allowlisted) | gate | notes |
|---|---|---|---|---|---|---|
| 0 | 2026-11-12 | pin upstream, snapshot 3.2+3.6 CTDs | 135 | n/a | n/a | **snapshots done** (`ctd-snapshots/3.2`, `/3.6`, provenance committed); the planemo baseline is still open — planemo is not installed here |
| 1 | 2026-11-12 | tool set: 7 deprecations, blacklist dir-output tools | 128 | n/a | n/a | wrappers moved to `deprecated/tools/openms/3.2/`, `MascotAdapterOnline` restored, 4 tools blacklisted; the 15 additions happen on regeneration |
| 2 | wip | params/formats: `filetypes.txt`, `hardcoded_params.json`; make the generator version-agnostic | 128 | n/a | todo | generator scripts patched (version from `macros.xml`, `v<version>` tag, binaries from conda-meta); the aux/* worklist is prepared but only takes effect on regeneration |
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

## Round 2 — generator scripts (done, verification pending)

The pipeline no longer hardcodes anything that changed with 3.6:

| was | now |
|---|---|
| `VERSION=3.2` in `test-data.sh` *and* `aux/generate.sh` | both read `@TOOL_VERSION@` from `macros.xml` — bumping the suite is a one-line change |
| `git clone -b release/$VERSION.0` | `-b ${GITTAG:-v$VERSION.0}` (OpenMS 3.6.0 dropped `release/*` branches for tags) |
| `wget` the openms `.tar.bz2` conda package and `ls $OPENMSPKG/bin` | symlink the binaries listed in `conda-meta/openms-*.json` of the env — no download, no build-string hardcoding (3.6 ships `.conda`), and no third-party binary that blocks on stdin |
| `export tmp="/tmp/openms-stuff/"` | `export tmp="${tmp:-/tmp/openms-stuff/}"` |

## Round 3 — functional tests (in progress)

Local execution is possible after all: `planemo test` with a prebuilt mull
environment (`planemo 0.75.48`, python 3.12, environment
`mulled-v1-e5fb30be…` under the fake `HOME`), driven by
`/workspace/.openms-tests/run-suite.sh` with
`--no_dependency_resolution --job_config_file /workspace/.openms-tests/job_conf.xml`.
Results land in `/workspace/.openms-tests/results/`, summarised by
`/workspace/.openms-tests/summarize.py`.

### The first real blocker: `${TESTS_TEMP_DIR}`

OpenMS 3.6 moved the intermediate test outputs into `${TESTS_TEMP_DIR}`
(`src/tests/topp/CMakeLists.txt: set(TESTS_TEMP_DIR "${PROJECT_BINARY_DIR}/tmp_path")`,
1783 `add_test` lines) and compares them with FuzzyDiff to the committed
reference in `${DATA_DIR_TOPP}`. `get_tests.py` stripped `${TOPP_BIN_PATH}/`,
`${DATA_DIR_TOPP}/` and `${TMP_RIP_PATH}/` but not the new variable, and
`diff_pairs` is keyed by *basename*, so `fix_tmp_files()` never matched: 2137
references in 87 wrappers pointed at intermediates which cannot exist
(**687 dangling references**, and `prepare_test_data.sh` wrote the wrong names).
Fixed in `fe285644`; the regenerated wrappers (`634145f7`) have **0** dangling
references.

### Where the fixtures come from

`test-data/` is generated, never committed (only 3 files are tracked). The
generators `prepare_test_data.sh` (822 invocations) and
`prepare_test_data_manual.sh` have to be executed after the wrapper generation;
that never happened before, which is why every `${TESTS_TEMP_DIR}` reference
looked "missing".  The first full run left **126** failing invocations, triaged
in `/workspace/.openms-tests/results/testdata-failures-triage.md`:

| n | cause | disposition |
|---|---|---|
| 26 | `\${CMAKE_COMMAND} -E copy …` / `-DINPUT_FILE=… -P …` pseudo-tests | filtered like `WRITEINI`/`DIFF` (`bde0158d`) |
| 47 | chained tests (`set_tests_properties(… DEPENDS …)`): test B consumes test A's `${TESTS_TEMP_DIR}` output | `get_tests.py` skips them (`chained_inputs()`), `test-data.sh` drops the same lines — Galaxy tests cannot express the dependency |
| ? | fixtures generated at build time (e.g. `.idparquet`) | `missing_inputs()` skips tests whose inputs are absent from `test-data/` at generation time |
| 9 | host-path third-party binaries | negative tests are `WILL_FAIL` upstream; jars needed for the real ones |
| 4 | 3.6 validation tightened (`MetaProSIP`, `FileConverter_RAW_1`, `EICExtractor`) | same family as the 11 `TestsCaseValidation` lint findings |
| 3 | `ImageCreator`, `FeatureLinkerWNet` are not in the conda `openms` package | blacklist |
| 2 | `PSMFeatureExtractor`: `Unknown option(s) '[-skip_db_check, -multiple_search_engines]'` | real 3.6 CLI drift |

### Round-2 items closed on the way

* `aux/filetypes.txt`: `fasta peff` → `peff peff` (the first column is the
  OpenMS/CTD extension; `fasta fasta` already wins for FASTA).
* host paths removed from `aux/hardcoded_params.json` (MSFragger, Novor,
  MaRaCluster) and `test-data.sh` (`MSFRAGGER_BINARY`, `NOVOR_BINARY`), so the
  `forbidden_patterns.txt` host-path rule can be flipped from `warn` to `fail`
  once the wrappers are regenerated.

### Status

Suite running over all 142 wrappers (~4 min/tool).
`AssayGeneratorMetaboSirius` (needs `sirius`), `ConsensusID` (`D9`) and
`DIAuditor` error out and are queued for diagnosis with `--no_cleanup`.

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

## Round 1.5 (3.6 regeneration) — closed

Generation now runs end to end against the 3.6.0 CTDs: 152 CTDs -> 141 wrappers
(11 blacklisted) + the hand-maintained `MascotAdapterOnline`. Three casualties of
the jump 3.2 -> 3.6 needed a decision, all recorded here:

* **D7 (CTDConverter, MapAligners)**: 3.6 added `in_spectra_files`/`out_spectra_files`
  to `MapAligner{Identification,PoseClustering,TreeGuided}`. `get_corresponding_input()`
  pairs a *list* output with the single input list of the same arity; with two input
  lists the pairing for `-trafo_out` (one trafoXML per `-in`) is ambiguous, the function
  returns `None`, `create_command()` then concatenates `None` and CTDConverter dies
  (`TypeError ... NoneType ... to str`) instead of degrading. Decision: blacklist
  `-trafo_out` for those three tools (spectra in/out kept) and file the proper fix
  upstream (skip hardcoded/blacklisted params when pairing) — better than patching
  the fork locally, which would make the pipeline unreproducible for others.
* **D8 (formats)**: CTDConverter crashes with `KeyError: 'xic'` when an output has
  several formats of which one is unmapped (`o2g[choice]` in `create_inputs`).
  `aux/filetypes.txt` now maps the 3.6 formats that have an obvious Galaxy type:
  `faa->fasta`, `prot.xml->protxml`, `traml->traml` (case variant), `xic->xml`,
  `xim->xml`. Appended at the end of the file because the Galaxy->CTD direction is
  first-wins (`xml` must stay `xml`, `fasta` must stay `fasta`). Still unmapped and
  therefore silently degraded: `peff` (UniPEFF `out` falls back to `txt`),
  `idparquet`/`featureparquet`/`consensusparquet`, `oswpq`, `fid`, `msalign`,
  `feature`, `cachedMzML` — Galaxy has no datatype for them.
* **23 wrappers without `<test>`** (13 of them new in 3.6) are covered by the global
  `.lint_skip: TestsMissing`; giving them real tests stays deferred (item 4).

Verification for this round: `aux/upgrade/check_generated.sh` -> *all static checks
passed* (one WARN: host paths), `xmllint` clean on all 142 wrappers, all `ftype=`/`format=`
values are Galaxy datatypes, no `type="output-dir"` parameter survived
(`aux/strip_output_dirs.py`).

## Round 0 (baseline) — planemo tooling

`planemo 0.75.48` installed in a dedicated conda env (`~/.pi-home/envs/planemo`,
python 3.12) — needed because the sandbox python (3.14) is too new for the
Galaxy/planemo dependency set, and `$HOME` hit the user disk quota while
installing (`conda env remove -n openms32` + `conda clean --all` freed it;
the 3.2 environment is no longer needed).

`planemo lint --skip_file .lint_skip` over all 142 wrappers: **0 FAILED/ERROR**.
Remaining warnings, all triaged:

| warning | count | disposition |
|---|---|---|
| `CitationsInvalid` (`doi:` prefix) | 129 | fixed — the single occurrence was in `macros.xml` (expanded by every wrapper), now the bare DOI |
| `TestsCaseValidation` | 11 | round 3: autogenerated tests set parameters outside their declared bounds, Galaxy rejects them at test setup. FileConverter 35/37/44/47/48/49, MetaProSIP 2/3, OpenSwathAssayGenerator 5, OpenSwathDecoyGenerator 9, TargetedFileConverter 27 |
| `OutputsFormatSourceReference` | 1 | **D9 (upstream)**: `ConsensusID` gets `format_source="in"` while `in_cond|in` exists twice, so the reference is ambiguous. Curable only in CTDConverter (must qualify the source), not in this repo |

**Functional tests cannot run here**: there is no docker/podman/singularity, and
per-tool conda dependency resolution for 142 tools is not affordable under the
user quota. CI (`galaxyproject/actions` planemo mode test, 15 min/test) stays the
only place the tests execute, so the loop's "test the changed tools" step is
`planemo lint` locally + CI for execution. Recorded here so nobody looks for a
missing local baseline.
