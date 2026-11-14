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
| 3 | 2026-11-14 | autotest failures by root cause | 142 | 5 (suite 8) -> 0 (suite 9) | - | 3a-3d; one class per iteration, 617 -> 614 tests |
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

### Round 3a — the generator now emits only what Galaxy can run

Iteration over `aux/generate.sh` + `planemo test`, fixing the generator (never a
generated wrapper) until the failing set shrinks. Wrapper test count: **688**
(3.2 baseline) → **656** → **650** → **649**.

| the generator used to emit | disposition |
|---|---|
| tests upstream marks `WILL_FAIL 1` or with `PASS_REGULAR_EXPRESSION` (negative tests: the wrapper would have to assert on a non-zero exit code) | `get_message_tests()` drops them |
| tests reading/writing a parquet file (`FileConverter`, `FeatureLinkerUnlabeled` chains), plus `-out_type consensusparquet` | `UNREADABLE_SUFFIXES` / `PARQUET_FORMATS`: no Galaxy datatype, and 3.6 dropped the writers from `FileConverter -out` |
| tests whose only outputs are blacklisted parameters | `only_blacklisted_outputs()` |
| tests of the form `${CMAKE_COMMAND} -E copy …`, `-DINPUT_FILE=… -P …` | filtered like `WRITEINI`/`WRITECTD` |
| tests consuming an intermediate of another test (`DEPENDS`, `.tmp.`) | `chained_inputs()` |
| tests referencing a file which is not an upstream fixture (`prepare_test_data.sh` intermediates, `${DATA_DIR_CLASS_TESTS}/`, host paths, `MSFragger.jar`, `novor.jar`) | `.upstream-fixtures.txt` snapshot + `is_fixture()` / `missing_inputs()` |
| tests with an unexpanded `${…}` | skip with the variable names in the log |
| `.msp` inputs | `test_unsniffable`: Galaxy sniffed the class-test fixture as `txt` and `FileConverter` rejected the format |
| `-mz_file` tests | `pin_mz_name()`: the ID converters match the pepXML run by the *file name* of the spectra file, and Galaxy stages the upload as `<dataset name>.<ext>`, so `PepXMLFile_test.mzML` arrived as `PepXMLFile_test_mzML.mzML` → `Found no experiment with name …`. Now `-mz_name` is pinned to the fixture stem |
| `TOPP_FileConverter_29_back` (`-out FileConverter_29.back.tmp.mzML`, no DIFF compares it) | `SKIP_LIST` |
| tests of tools needing an external executable the mull env does not have (`${SIRIUS_BINARY}`, `${MSFRAGGER_BINARY}`, `${NOVOR_BINARY}`, `${SPECTRAST_BINARY}`, ...) | skipped; only `EXTERNAL_PROGRAM_NOTFOUND` can come out of them. 22 wrappers are left without a test and stay covered by `.lint_skip: TestsMissing` |

Also fixed on the way: the 3.6 reformatting of `add_test()` over several lines
(closing `)` on its own line) made the joiner drop whole tests — 656 → 619 and
`ProSE`, `IsobaricWorkflow`, `SimpleSearchEngine`, `CometAdapter` lost their
tests entirely. `c8207e8b` accumulates until the statement closes and then drops
the trailing `)`. Parse coverage: 1706 of 1739 `add_test()` statements, the 33
leftovers are the `${i}` loops and the `add_test(NAME … COMMAND …)` form.

`LuciphorAdapter` has no test in 3.6 on purpose (`CMakeLists.txt:1347` is a
comment).


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

Suite 9 — the first full run after round 3c — is **green: 99 tools reporting,
561 passed, 0 failed, 0 errors, all 15 chunks**, with 142 wrappers and 614 tests
(`e4c1eaa0` generator, `6bab5ea4` wrappers, `31074536` ledger).  The three
previously failing tools now report their full test sets:
`OpenSwathWorkflow` 19, `TextExporter` 10, `IsobaricWorkflow` 1.

Suite 9 was **not** as green as it looked: `summarize.py` counted the 99 tools
that reported a result, and `MzMLSplitter` and `SeedListGenerator` were dropped
by planemo altogether because of round 3d.  The driver now writes
`results/requested.txt` and `summarize.py` names every requested tool which never
reported, so a wrapper Galaxy refuses to parse can no longer hide in a green
summary.

`planemo lint --skip_file .lint_skip *.xml` over all 142 wrappers found the one
known warning (`ConsensusID` `OutputsFormatSourceReference`, `D9`) and two new
`ERROR (XSD)` for `MzMLSplitter` and `SeedListGenerator`
(`<output_collection count="">`), which round 3d fixes — the round 0 lint
baseline was taken before the wrappers were regenerated, so these slipped
through.  After round 3d both tools are lint-clean and their 28 tests pass
(`MzMLSplitter` 4, `SeedListGenerator` 6, `FileInfo` 18 for control).

`AssayGeneratorMetaboSirius` (needs the `sirius` binary and a directory
fixture), `ConsensusID` (`D9`), `DIAuditor` and `FeatureLinkerUnlabeled` (the
parquet directory fixture) are queued for a per-case decision.

### Round 3d — an output collection Galaxy can express

`planemo lint` on the regenerated wrappers flags two `ERROR (XSD)`

    Element 'output_collection', attribute 'count': '' is not a valid value
    of the atomic type 'xs:integer'

for `MzMLSplitter` (`out`, 2 tests) and `SeedListGenerator` (`out_prefix`, 3
tests).  Upstream compares those members one by one through a templated name
(`-out <prefix>` writes `<prefix>_part<N>of<M>.mzML`, and the DIFF steps name
`..._part1of2.mzML`), which CTDConverter cannot map back to the fixture, so it
emits `count=""` - a test Galaxy refuses to parse.  The fix is in the generator,
`drop_empty_collection_count()`: the attribute is removed instead of guessed, so
the test asserts that the collection was produced, which is the most specific
statement available without inventing a member list (same principle as
`strip_uncomparable_outputs()`).  Static check 7 of `check_generated.sh` now
fails on `count=""`.

### Round 3b — one more class per iteration, and a static gate for each

Suite 7 (all 142 wrappers) had to be thrown away: editing `run-suite.sh` while
bash was still reading it (`line 91: unexpected EOF while looking for matching
'"'`) killed the parser mid-run, so chunk 08/13 wrote no report and 41 tools
were never counted.  Lesson: the driver is not edited while it drives.
What it did show was one *class* of failure per tool, all of them in the
generator, none in a wrapper:

| failure | root cause | fix |
|---|---|---|
| `DecoyDatabase #5`: `Dataset metadata verification for [file_ext] failed, expected [txt] but found [fasta]` | `generate.sh` patched the CTDs right before CTDConverter, but `test-data.sh` -> `get_tests.py` had already derived the expected ftype from the unpatched `supported_formats` | `patch_ctds.py` moved into `test-data.sh`, directly after `strip_output_dirs.py` (`efc0e601`) |
| `IsobaricWorkflow`/`MS1LabeledWorkflow` (exit 1): `CTDopts.py: KeyError: 'output-dir'` | the wrapper calls `<tool> -write_ctd` at *run time*, so the CTD CTDopts parses still contains 3.6's `out_qpx type="output-dir"`; `strip_output_dirs.py` only cleans the build snapshots | `fill_ctd.py: strip_unknown_ctd_types()` drops every `ITEM`/`ITEMLIST` whose type is not in `CTDTYPE_TO_TYPE`, writes `<tool>.stripped.ctd`, logs it, and `write_ctd()` still writes to the original name (so `-ini <tool>.ctd` works) |
| `OpenNuXL` (6 errors): `AssertionError: Test input file (ThermoRawFileParser.exe) cannot be found` | `ThermoRaw_executable` is an `input-file` whose CTD default is the literal executable name; CTDConverter copies the default into every test | global `ThermoRaw_executable` entry in `aux/hardcoded_params.json`, plus **check 6** of `check_generated.sh`: `aux/upgrade/check_test_fixtures.py` fails if any data input carries a fixed value |
| `OpenSwathWorkflow` (20 failures): `Error: File not found (the file 'OpenSwathWorkflow_1_input.trafoXML' could not be found)` | `-Calibration:rt_norm` names an RT normalization file but the CTD types it `string`, so the wrapper passes the bare name through and Galaxy never stages it | `aux/ctd_patches.json`: `Calibration:rt_norm` -> `input-file` + `supported_formats: "*.trafoXML,*.TraML"` |
| `OpenSwathWorkflow #21/#27` (`linear_irt_file`) | `-Calibration:files:linear_irt_file` is a *space separated list* of iRT files in one string | `get_tests.py: text_params_with_files()` skips a test which hands a known fixture to a CTD parameter that is not a file parameter (`ctd_arguments()` builds `-Section:param -> type` from the CTD `<NODE>` nesting) |
| `TextExporter #2`: `Test output file (tmp_path/TextExporter_2_consensus_tsv.tmp.tsv) is missing` | a test which passes `-ini` gets its parameters from that ini; the migrated fixture still names the build intermediate, and `fix_tmp_files()` only rewrites the command line | `get_tests.py: map_output_references()` applies the same `diff_pairs` mapping to `<output value=...>` after conversion; a leftover `tmp_path/` skips the test |
| `IDRipper #2/#3` (2 failures) | hand-maintained tests (`aux/macros_test.xml` — the generator *discards* IDRipper's autotests because of its `output_prefix` parameter): OpenMS compares XML attributes as numbers, Galaxy's `compare="diff"` compares text, and 3.6 writes `significance_threshold="0.0"` where the reference has `"0"` | the two `IDRipper_2` tests removed from `manutest_IDRipper`, with the reason in place |
| `OpenSwathAssayGenerator`/`OpenSwathDecoyGenerator`/`TargetedFileConverter`: `Parameter 'out_type': an invalid option ('oswpq')` | `.oswpq` is the OpenSWATH parquet flavour and 3.6 dropped those writers, like the other parquet formats | `.oswpq` added to `UNREADABLE_SUFFIXES` |
| `PercolatorAdapter #1-#3` (exit 9) | the percolator shipped in `openms-thirdparty=3.6.0` aborts inside the external binary: `Setting an empty value for primary MS runs paths` | `SKIP_LIST` |
| `UniPEFF` (17 failures) | it needs `in` staged as `*.xml` and writes `*.peff`; `macros.xml: gxy2omsext()` maps the Galaxy *xml* dataset to `*.bioml` (what the BioML readers need) and the Galaxy *peff* dataset to `*.fasta` (what every other tool needs), so the tool gets `in/UniPEFF_1_input_xml.bioml` and is asked to write `out/output.fasta` | `SKIP_LIST` (D10) |

Consequence for the generator: **617** wrapper tests (was 644), 24 wrappers
without a test (was 22), still covered by `.lint_skip: TestsMissing`.

Two dead ends worth recording:

* a `missing_outputs()` guard (skip a test whose `<output value=...>` is not in
  `test-data/`) looked right for `TextExporter` but also killed
  `GNPSExport_2/3/4`, `OpenSwathWorkflow_1_library_prefilter` and others: the
  *presence* of a fixture is a property of the mutable `test-data/` directory,
  not of the CMake file, so generation would depend on whether
  `prepare_test_data.sh` ran. Replaced by the `SKIP_LIST` entries and by
  `map_output_references()`, which is a pure function of the CMake input.
* ordering `chained_inputs()` before `fix_tmp_files()` fixed
  `FileFilter #42` but silently broke `ProteinQuantifier`,
  `MapAlignerIdentification`, `InternalCalibration`, `IDSplitter` (their
  inputs were rewritten to reference names); `fix_tmp_files()` therefore never
  rewrites a token preceded by `-in*`.

### Round 3c — FuzzyDiff tolerance and multi-file inputs

Suite 8 finished all 15 chunks: **99 tools reported, 559 passed, 5 failed,
0 errors** (96 tools fully green).  The remaining five are three new classes,
again all of them in the generator:

| failure | root cause | fix |
|---|---|---|
| `IsobaricWorkflow #1/#2` (exit 3): `Error: Unable to read file (Error: Spectra file does not exist: 'TMTTenPlexMethod_test.mzML' in: exp_design/IsobaricWorkflow_1_design_tsv.tsv)` | `-exp_design` names its spectra *by file name*, but the wrapper stages a data set as `<sanitized element identifier>.<openms extension>` in a directory of its own, so the design file can never resolve.  The design file would have to be rewritten per test | `SKIP_LIST: -exp_design` (also affects `Epifany` if it ever gains such a test; only `IsobaricWorkflow` and `Epifany` have the parameter) |
| `OpenSwathWorkflow #17` (`out_chrom`, `_22_output.chrom.mzML` 33677 b vs 21751 b) | `TOPP_OpenSwathWorkflow_22_out2` compares with `${ZLIB_NG_MZML_WHITELIST}` = `"encodedLength" "<binary>" "<offset"`, i.e. upstream throws the whole payload away because zlib-ng produces different (but equivalent) compressed mzML.  Galaxy can only compare size, and the size is a function of the compression, not of the computation | `strip_uncomparable_outputs()`: the DIFF line decides; an output whose whitelist removes `<binary>`/`<offset` becomes a presence+format assertion (`<output name="out_chrom" ftype="mzml"/>`) |
| `OpenSwathWorkflow #20` (`out_features`, `_25_output.featureXML` 42500 b vs 25714 b) | `TOPP_OpenSwathWorkflow_25` passes **two** files to `-in`, `-27` the same file six times; `aux/hardcoded_params.json` forces `CTD:is_list: false` for `OpenSwathWorkflow:in`, so the wrapper takes one run per invocation and the emitted test carried only `MRMMapping_output.chrom.mzML` and the tool legitimately produced half the features | `check_multi_inputs()` verifies that every parameter which got several files upstream carries all of them in the emitted test and skips the test otherwise (`_25`, `_27`).  `ctd_arguments()` now also collects `ITEMLIST` |
| `TextExporter #2` (`consensus_elements` 35326 b vs 61741 b) | reproduced locally: identical rows and columns, but OpenMS 3.6 writes doubles with full precision and in scientific notation (`826.031` -> `826.030999999999949`, `928753024` -> `9.28753e08`), which grows these 2011 era references by ~75%.  Upstream passes because FuzzyDiff parses numbers with a relative tolerance; Galaxy compares by size | `PUBLISH_ONLY_OUTPUTS` — `TextExporter: consensus_centroids/elements/features` keep the existence and `csv` format assertion only |

The first attempt at the multi-file class was wrong in both directions, which is
why the check verifies instead of rewrites.  A CTD `ITEMLIST` becomes a Galaxy
`multiple="true"` data parameter, and CTDConverter already writes its files as
one comma separated `value` that Galaxy splits, so `IDMerger` (7 tests),
`FileMerger` (10), `MapAlignerPoseClustering` (3) and the other list-taking tools
keep every test.  Only a parameter which the wrapper *declares* as single valued
loses information.  Rewriting the value into `values="a,b"` on such a parameter
would produce an invalid test (Galaxy would offer a list to a single data input),
so the check compares the emitted value with the upstream command line and skips
when they differ.  Net effect of round 3c on the test count: 617 -> 614.

Two findings that change how reference mismatches must be handled from here on:

1. **`tools/openms/test-data/` is a clone of the upstream test-data repository**
   (only the 45 hand-maintained files below `CHEMISTRY/` etc. are tracked;
   `prepare_test_data.sh` fetches the rest).  A reference file therefore
   **cannot be refreshed in this repository** — whatever we wrote would
   disappear with the next `prepare_test_data.sh` and never reach CI.  Any test
   which upstream only passes through FuzzyDiff's numeric tolerance or through
   a payload whitelist has to be relaxed in the wrapper, not "fixed" by
   rewriting the expectation.  The `## Reference-file refreshes` table stays
   what it was: a log of upstream reference changes we had to follow.
2. `OpenSwathWorkflow -test` is not the reason for the `_22` mismatch: a run
   without `-ini` writes the same 243 `<userParam name="parameter: ...">`
   entries (59 kB vs the 33 kB reference), and a `-test` run (32.8 kB) differs
   from the reference only in the intensity arrays.  The interesting part is
   invisible to a size comparison: `sim_size` cannot tell a parameter dump from
   a chromatogram.

### D10 — UniPEFF stays unwrappable until the extension is per tool

`macros.xml: gxy2omsext()` is one global map from Galaxy datatype to OpenMS
extension, and it is *almost* injective: Galaxy `xml` -> `.bioml` is right for
the BioML readers (`CVInspector`, `SemanticValidator`, the old `-in bioml`
tools) and wrong for UniPEFF's plain UniProt XML; Galaxy `peff` -> `.fasta` is
right for every consumer of a PEFF file and wrong for UniPEFF, which writes
PEFF and refuses annotations to a `.fasta` name.  Galaxy has no `bioml`
datatype (`galaxy/tool_util/linters/datatypes_conf.xml.sample` has no
`bioml`), so there is no second datatype to split the mapping on, and
`aux/filetypes.txt` maps CTD patterns to Galaxy types globally (first wins).
The fix is a per-tool extension override in the generator (e.g.
`aux/extensions.json` keyed by `<tool>:<argument>`); until then UniPEFF's 17
tests are skipped and the tool is not wrapped-in-tested state.  This is a
pre-existing wrapper defect, not a 3.6 regression: 3.2 had the same mapping.

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
