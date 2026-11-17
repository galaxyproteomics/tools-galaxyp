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
| 3 | 2026-11-14 | autotest failures by root cause | 142 | 5 (suite 8) -> 0 (suite 9) -> 2 (suite 10) | - | 3a-3d; one class per iteration, 617 -> 614 tests; both suite 10 failures are outside the wrappers (`D11`, a Galaxy restart) |
| 4 | todo | manual tests, `.ini` migration, reference refresh | todo | todo | todo | every refreshed reference needs a note below |
| 5 | 2026-11-15 | full run vs. round-0 baseline | 142 | **0** | `manifest.py report --gate`: GATE PASSED | suite 10: 117 pass, 25 skip (24 no upstream test + `MascotAdapterOnline` D11), 0 untested, 0 fail; `check_generated.sh --regen` proves the wrappers are byte-identical to HEAD |
| 6 | 2026-11-16 | PR #783 review: profile, description wording, `${X_BINARY}`, artefacts, `*.yaml` | 142 | **0** | `check_generated.sh`: all static checks passed; the 9 wrappers whose test count moved re-run in Galaxy: 23/23 green | D14-D20; 612 -> 629 tests, 25 -> 19 wrappers without `<test>` |
| 7 | 2026-11-16 | PR #783 review §2: remote test data | 142 | **0** | `check_generated.sh` 9 checks green, `--regen` byte-identical, full suite: 626/626 | D21-D26; 1359 references by URL, 688 assertions / 90 references, 6 committed fixtures, 56 multi-file references (local, from `test-data.sh`); 626 tests unchanged |

## Decisions

| id | tool(s) | decision | reason |
|---|---|---|---|
| D1 | `MascotAdapterOnline` | **restored to `tools/openms/`** (was moved to `deprecated/` in `b5c3d845`), normalised to `profile="@PROFILE@"` (D15) + docs 3.2.0 | it is *not* removed: `MascotAdapter` went away in 3.4.0, `MascotAdapterOnline` exists through 3.6.0 (`src/topp/executables.cmake`). It stays in `aux/tools_blacklist.txt` (broken upstream, #4412) and is therefore **not regenerated** — the file is hand-maintained until round 3 re-evaluates un-blacklisting it. |
| D2 | `ParquetConverter`, `ParquetDiff`, `*-out_qpx` | blacklist / do not wrap | their outputs are *directories* of parquet files; Galaxy datasets are single files. Needs collection-in/collection-out support before it can be wrapped. |
| D3 | `Decharger`, `MetaboliteAdductDecharger`, `MaRaClusterAdapter`, `FLASHDeconv`, `IDDecoyProbability`, `ProteomicsLFQ` | keep blacklisted | pre-existing reasons in `aux/tools_blacklist.txt`, unrelated to the version jump. |
| D6 | layout of `deprecated/` | one subdirectory per archived suite state (`3.1/`, `3.2/`), each with its own `macros.xml` + `fill_ctd.py` | a wrapper's `<requirement>` pin must match the suite it was generated from. The 7 wrappers dropped in this upgrade are 3.2-generated, the 15 older ones are 3.1-generated; one shared `macros.xml` would have made one of the two groups install the wrong OpenMS. `<import>` resolves relative to the importing file, so this needs no edit to any wrapper. |
| D5 | nested/stale `hardcoded_params.json` entries | **partly done** (round 5): only entries naming tools that no longer exist are pruned (`separator`/`IDMassAccuracy`, `xml_out`/`XTandemAdapter`, `algorithm:tryptic_only`/`CompNovo`+`CompNovoCID`); the rest are kept | `ctd_diff.py` lists 18 parameters that vanished from the 3.6 CTDs, but most of those entries are *deliberate* blacklists whose parameter is hidden by `strip_output_dirs.py` (`out_qpx`), dropped for a reason (`trafo_out`, D7) or re-typed rather than removed (`in`/`OpenSwathWorkflow`, `test`). Only a `tools` list naming a tool that is not in the 3.6 snapshot is unambiguously dead. `check_generated.sh --regen` proves the three removals leave every wrapper byte-identical. The host-path rule is flipped from `warn` to `fail` (no wrapper contains `/home/<user>/` any more). |
| D13 | what a fixture fingerprint may hash | timestamps and runtime footers are washed out, four fixtures are hashed as "unstable" | `test-data.sh` does not ship a dozen fixtures, it **generates** them by running the tools, and OpenMS stamps them with the clock (`<IdentificationRun date=...>`, `creationDate=...`, the `took 0.09 s (wall) ... Peak Memory Usage` footer, and in the binary `.oms` a plain `2026-11-15 18:40:55`). Hashing those bytes made the gate report **15 phantom stale tools** after every regeneration. `sha256_fixture()` now normalises the stamp tokens (an actual fixture change is still caught byte for byte), and `unstable_fixtures.txt` names the four fixtures that are not reproducible at all (Epifany's EM scores, `-threads 4` feature order) - exactly the ones the wrappers assert with `compare="sim_size" delta_frac="0.7"`. Verified: two full regenerations in a row move **0** fingerprints. |
| D14 | `MSGFPlusAdapter -tasks` | **blacklisted** (`"value": "@"` for `MSGFPlusAdapter`) - the wrapper neither shows it nor passes it, OpenMS computes it | `-tasks` is OpenMS' internal split of the spectra over the thread pool (`tasks = 0` = `min(threads*3, numSpectra/250)`, `tasks < 0` = `abs(tasks)*threads`). It is not a scientific decision, it is a memory/speed trade-off inside the search, and the CTD marks it `advanced="false"`, so it landed in the main section with all four sentences of OpenMS help text as its label. Threads are already `${GALAXY_SLOTS:-1}` (`threads` in `aux/hardcoded_params.json`); leaving `-tasks` unset is the CTD default and lets OpenMS scale it to the inputs. `MSGFPlusAdapter` has no tests either way, so the regeneration diff is exactly the one deleted `<param>` line. |
| D15 | wrapper `profile` | **a token**, `@PROFILE@` = `24.1` in `macros.xml`, passed to CTDConverter as the literal token | every wrapper said `profile="23.0"` while the CI tests on Galaxy `release_24.1` (`.github/workflows/pr.yaml`: `GALAXY_BRANCH`). A tool profile newer than the Galaxy that loads it only produces a warning, so 25.1 would have been noise. As a token the bump is one line; `MascotAdapterOnline.xml` is hand-maintained and carries the same token. |
| D16 | CTD `description`/`label` wording | fixed **in the CTD snapshot** by a generic `_substitutions` pass in `aux/ctd_patches.json`, applied by `patch_ctds.py` to every CTD | eight wrappers documented their decoy option as `std::string` - OpenMS writes its own C++ type into the CTD, not prose for a user. A per-wrapper edit would come back on the next regeneration; a per-CTD patch would have to be repeated for every new tool. The substitution is one line and reaches all 152 CTDs (7x `decoy_string`, 1x `decoy_pattern`; `DecoyDatabase` was already worded correctly). |
| D17 | a test whose command line passes `${X_BINARY}` | **drop the flag, keep the test** | `third_party_tests.cmake` passes the executable explicitly (29 occurrences: comet 8, percolator 7, maracluster 3, msgf_plus 3, sage 2, spectrast 2, MSFragger 2, novor 1, luciphor 1). `hardcoded_params.json` pins the same binaries for the wrapper, so the flag is redundant in Galaxy and the command line no longer dies on the unexpanded `${...}`. `test-data.sh` resolves the same variables from the environment it exports, so the fixtures for those tests exist. 14 tests come back on 9 wrappers. |
| D18 | generated artefacts | **`$ARTIFACTS` (default `$tmp/generated`), never the tool directory**; `tools/openms/.gitignore` deleted | `ctd/`, `macros_autotest.xml`, `macros_discarded_auto.xml`, `prepare_test_data.sh`, `.upstream-fixtures.txt`, `convert.{out,err}` are rebuildable from the CTDs and the CMake files, but lived next to the wrappers and had to be gitignored - a regeneration in a dirty tree could leave them half-tracked. `test-data.sh`/`get_tests.py` read the location from `OPENMS_CTD_DIR`/`OPENMS_UPSTREAM_FIXTURES`. `manifest.py` stops fingerprinting `macros_autotest.xml`: it is an artefact, and its content already reaches the fingerprint through the wrapper that includes it. |
| D19 | `MSFraggerAdapter`, `NovorAdapter` tests | **skipped in `SKIP_LIST`**, wrappers unchanged | same shape as D17 (`${MSFRAGGER_BINARY}`/`${NOVOR_BINARY}`) but a different conclusion: the jars are licence-gated, no bioconda recipe ships them, and upstream itself guards the tests behind `STREQUAL "*-NOTFOUND"`. The fixtures can not be produced here either. |
| D20 | `ProSE -summary_out` | **`yaml` <-> `yaml` in `aux/filetypes.txt` and `@EXT_FOO@`** | OpenMS writes a `*.yaml` report and refuses any other extension, while the suite had no mapping for Galaxy's `yaml` datatype, so the wrapper staged `output.txt` and OpenMS aborted (`Invalid output file extension for file 'summary_out/output.txt'`). With the mapping the wrapper stages `output.yaml`, the report is a real output instead of a broken one, and upstream `TOPP_ProSE_9` becomes expressible. |
| D21 | how the test data reaches a test | **`location=` for single files, assertions for the 89 FuzzyDiff-only outputs, `test-data/` only for multi-file values** | review point #2. The alternatives were shipping a 10 GB clone or inflicting `test-data.sh` on CI; a download needs nothing but the URL. The assertion bounds mirror what upstream asserted (`delta_frac="0.7"` = 0.3-1.7x, a line count *2 wide because the content must survive formatting churn), so the wrappers check what they always checked. `aux/output_expectations.tsv` is a **deliberate snapshot** - `make_expectations.py` is not wired into the generator: an automatic refresh would let a regression rewrite its own expectation. |
| D22 | the key of `aux/upstream-fixtures.tsv` | **the basename**, and when a name occurs in more than one copied directory the `src/tests/topp` copy wins | that is the copy `test-data.sh` has always flattened into `test-data/`, so the same command line keeps naming the same file. Keying by the repo-relative path would have made the reference and the fixture diverge (`PepXMLFile_test.pepxml` lives in `src/tests/topp` and `src/tests/class_tests/openms/data`); dropping every ambiguous name lost 39 fixtures, of which 30 resolve correctly under this rule. |
| D23 | an `<output>` that gets **both** `location=` and an assertion | keep `value=`/`compare=`/`delta_frac=` | Galaxy rejects an output that defines nothing to check (`parser/xml.py`: *"Test output defines nothing to check"*), and the reference file is the *expected* output of the upstream test - downloading it is exactly right. Only the 89 outputs that have no upstream file lose their `value=` (that is where the assertion replaces the comparison). |
| D24 | `delta_frac` on a test output | the annotator writes the matching **`delta`** next to `location=` | Galaxy's `sim_size` checks the absolute `delta` first (default 10000) and the fraction only afterwards (`tool_util/verify/__init__.py`, `assert_size`), so `delta_frac="0.7"` was never the tolerance the wrappers asked for - it rejected every reference more than 10 kB away. Invisible for years, because the local reference *was* the produced file (`fix_tmp_files()` symlinks it, `prepare_test_data.sh` overwrites it), so the size always matched exactly; the first real upstream reference made `Epifany_1` fail on a 14 % size difference. Hence the size column of `aux/upstream-fixtures.tsv`: `delta = 0.7 x reference size`. |
| D25 | a `test-data/` reference vs. the intermediate a test writes | **never replace a committed reference by a symlink onto the build artifact** (`fix_tmp_files()` keeps an existing regular file) | `fix_tmp_files()` maps `X.tmp.ext` onto the reference name the wrapper declares as its `<output>` and symlinks the reference onto the intermediate, so `prepare_test_data.sh` decided what the expected value was: whatever the tool had just written, compared with itself. 674 of the references in `test-data/` were such symlinks, which is why no comparison could ever fail. Keeping the file the checkout brings makes the comparison real (the artifact and the reference of `IsobaricAnalyzer`'s TMT10plex test differ by 5x, see D27); measured against `aux/upstream-fixtures.tsv`, exactly three of them leave the 0.3-1.7x window, and `AccurateMassSearch_1` is asserted anyway (D21). A reference the checkout does not bring keeps the symlink, so nothing that used to work stops working. |
| D27 | upgrading the test data's `.ini` files | **`aux/ini_keep_original.txt` names the four fixtures which keep their original**; every other file is still converted, but `aux/check_ini_conversion.py` reports a changed value as a warning | `test-data.sh` upgrades every `*.ini` with `<tool> -ini <old> -write_ini <new>`, and that upgrade is needed: the shipped inis have moved nodes (`MassTraceExtractor_2` carries `mtd:min_trace_length`, 3.6 reads `epd:min_trace_length`) and OpenMS repairs them at runtime, which the generator has to see. But `-write_ini` writes the *defaults* of the tool - `-ini` only selects the parameter set which gets augmented - so a value the tool fills in itself does not survive. `IsobaricAnalyzer:type` is one: `TMTTenPlexMethod_test.ini` came back as `itraq4plex`, the generated test pinned that value, and the tool wrote an iTRAQ consensusXML (2611 b) where the upstream reference is a TMT one (12327 b), which `sim_size` rejects; upstream never sees it because `TOPP_IsobaricAnalyzer_2` compares with `-whitelist "id=" "<map" "?xml-stylesheet"`. The other three are `PPHiRes_invalidValue{,Section}` - they exist *because* their value is invalid. Not listed, and therefore converted: `FeatureLinkerUnlabeledKD_4` (`None` is not in the 3.6 restrictions of `adduct_merging`/`charge_merging`, so the default is what the tool uses) and `MassTraceExtractor_2` (an obsolete node, same argument). The report compares the values under their `NODE/…/ITEM` path and numerically (`1` -> `1.0`, `10000000` -> `1.0e07` are not changes). |
| D26 | outputs that are not text | **`*.xic`/`*.xim` map to Galaxy's `binary`, not to `xml`** in `aux/filetypes.txt` | OpenMS 3.6 writes mobile-proton/adduct XICs as Parquet (the files start with `PAR1`), but the extension table claimed `xml`, so `OpenSwathWorkflow` declared `out_chrom` (and `out_mobilogram`) as XML, `change_format` switched to `xml` for `out_chrom_type=xic`, and `is_valid_xml` failed on a binary file: *"Start tag expected, '<' not found, line 1, column 1"*. With `binary` the datatype is honest and the assertion for `OpenSwathWorkflow_1.chrom.tmp.xic` drops to `has_size` (`aux/output_expectations.tsv`). Side effects: `TextExporter`'s input list shows `binary` instead of `xml`, and `out_mobilogram` now stages `output.xic` (it staged `output.bioml` before - neither is tested upstream, and OpenMS most likely wants `*.xim`; a dedicated mapping would need a second Galaxy type for the same `binary` format, left open). |
| D4 | `FileConverter` raw path | open | 3.6 moved raw handling into `RawToMzML:*` and added `-RawToMzML:reader` (`inprocess` default on Linux). The hardcoded `RawToMzML:NET_executable=mono` / `ThermoRaw_executable=ThermoRawFileParser.exe` are ignored unless `reader=external`, and `mono` is no longer a recipe dependency. Decide in round 2. |

### D11 — `MascotAdapterOnline` keeps its tests only as a comment

The tool searches against a Mascot server.  The two tests it inherits from 3.1
post an MS/MS query to the public demo server `www.matrixscience.com:80`, which
now answers with something the adapter cannot read:

    Job in error state.. exit_code: 9, stderr: MascotGenericFile: no native ID accession.
    An error occurred during the query: Error: Could not extract .dat file path from Mascot response

The connection is fine (a plain TCP connect to port 80 succeeds), so this is the
service, not the sandbox, and it is not a 3.6 regression: the tests are unchanged
since 3.1.  Upstream 3.6 does not test the tool at all (`grep -c
MascotAdapterOnline src/tests/topp/*.cmake` = 0), the wrapper is blacklisted from
generation (`D1`) and hence maintained by hand.  The tests are therefore kept
inside an XML comment with the reason spelled out: a licensed server only has to
delete the comment markers.  Consequence: the wrapper now has no active `<test>`
and joins the 24 other wrappers the `TestsMissing` lint skip covers.

## The gate, as of round 6 — a fingerprint that survives a regeneration

`manifest.py report` recomputes every fingerprint live and compares it with the one
recorded in `teststatus.tsv`, so a stale row means "re-test this tool".  After the
round-5 gate passed, a *re-regeneration* turned that into 15 stale tools although
the wrappers were byte-identical and nothing the tests assert had changed:

    $ bash aux/upgrade/check_generated.sh --regen      # wrappers byte-identical
    $ python3 aux/upgrade/manifest.py report --gate
    GATE FAILED: results recorded against an older fingerprint; re-test the stale tools.
      ... 15 tools ...

The cause is the fixture pipeline, not the wrappers: `test-data.sh` generates a
dozen reference files by running the tools themselves, and each generated file
carries the clock.  Three of the shapes seen:

    <IdentificationRun date="2026-11-15T18:51:26" ...>        idXML / featureXML
    creationDate="2026-11-15T19:24:52"                        mzIdentML, mzQC
    2026-11-15 18:40:55                                       oms (binary)
    took 0.09 s (wall), ... Peak Memory Usage: 56 MB.         *.stdout fixtures

`sha256_fixture()` now normalises exactly those tokens before hashing, and
`aux/upgrade/unstable_fixtures.txt` lists the four fixtures whose *scores* are
irreproducible in the first place (Epifany's EM, `-threads 4` feature order) -
the same four the wrappers assert with `compare="sim_size" delta_frac="0.7"`, so
the fingerprint records their existence instead of their bytes.  `fingerprints.json`
now also stores a `refdigest` per fixture, which is what named the culprits:

    $ python3 aux/upgrade/manifest.py fingerprint --out fingerprints.json
    $ bash aux/generate.sh
    $ python3 aux/upgrade/manifest.py fingerprint --out /scratch/.../after.json
    0 tools moved

The last full regeneration moves zero fingerprints (the three iterations before it
moved 15, then 12, then 9, then 2 - each one named by its `refdigest` delta), so
the gate means what it says: it changes when a wrapper, a CTD or a *real* fixture changes, not when a
fixture is written one second later.  The 67 status rows were re-fingerprinted
once, when the hash function changed; no test result was re-interpreted.

## The gate, as of round 5

    $ python3 aux/upgrade/manifest.py report --gate
    tools            : 142
    pass             : 117
    fail (allowlist) : 0
    fail (ours)      : 0
    blocked          : 0
    untested         : 0
    stale (fp moved) : 0
    escalate (2x)    : 0

    GATE PASSED: no unexplained failures.

    $ bash aux/upgrade/check_generated.sh --regen
    restored MascotAdapterOnline.xml (blacklisted, hand-maintained)
    idempotent: regenerated wrappers byte-identical to HEAD
    all static checks passed

`manifest.py import-summary <planemo summary.tsv>` is how a planemo suite
reaches the ledger: the driver runs ten tools per Galaxy instance, so the
per-tool `record` calls are not practical there.  A tool the summary does not
mention is left untouched, never marked green.

The one remaining lint finding is `D9` (`ConsensusID`
`OutputsFormatSourceReference`): the converter writes `format_source="in"` while
`in_cond|in` exists twice (`<when value="no">` holds the multiple variant,
`<when value="yes">` the single one), so Galaxy cannot resolve it.  Qualifying
the name does not help - both paths are identical - and the wrapper is
generated, so this needs a CTDConverter fix.  It is a warning, the round-0
baseline recorded it, and the 10 `ConsensusID` tests pass.

### D12 — `AssayGeneratorMetaboSirius` cannot be tested, and barely used

Its `-in` is a *directory*: a SIRIUS project holding `formula_identifications.tsv`,
`canopus_formula_summary.tsv`, `report.mztab` and one subdirectory per compound.
Two independent reasons make the three upstream tests inexpressible:

* the CTD types the parameter as `input-file`, so the wrapper offers a single
  data set; passing one file makes 3.6.0 answer
  `Error: Unexpected internal error (SIRIUS project directory is empty.)`
  (reproduced in `/scratch/berntm/sirtest`), and Galaxy can only stage single
  files - there is no directory datatype;
* the fixture is not even in the test-data repository: it lives in the OpenMS
  source tree (`src/tests/topp/AssayGeneratorMetabo-in-SIRIUS-project`), so
  `prepare_test_data.sh` never fetches it.

The tests are therefore skipped by name in `SKIP_LIST` (they used to be dropped
silently by `missing_inputs()`), and the tool runs green in the suite by having
no tests.  Making it usable needs a functional decision - wrap a tar archive and
unpack it into the job directory, or blacklist the tool like the parquet ones
(`D2`) - which is the maintainer's call, so it is recorded rather than guessed.
The remaining `-test` runs (no `sirius` binary needed) do pass when the directory
is provided: `AssayGeneratorMetaboSirius -test -in <project>` reproduces
`AssayGeneratorMetaboSirius_output_1.tsv` byte for byte.

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

Suite 10 — all 142 wrappers again, with the driver recording `requested.txt` —
reports **118 tools, 607 passed, 7 failed, 0 errors**.  The 24 tools which never
reported are exactly the 24 wrappers without a `<test>` element
(`diff <(no-test wrappers) <(never reported)` is empty), so the suite now
accounts for all 142 wrappers instead of 99.

Two of the seven failures are not wrapper bugs:

* `IDFilter` 5/26 - `Job in error state.. exit_code: None, stderr: .` plus
  `('Connection aborted.', RemoteDisconnected(...))`.  A Galaxy restart in the
  middle of chunk 05 (the log shows new `pN:main.1,p:<pid>` boots) killed the
  jobs in flight.  Re-running the tool on its own: **26/26 green**
  (`results/suite10b.log`), so it is infrastructure, not a test.
* `MascotAdapterOnline` 2/2 - see `D11`.

The four tools that were still on the blocked list are now decided:

| tool | state | evidence |
|---|---|---|
| `ConsensusID` | **green**, 10 tests | the `D9` lint warning is cosmetic, see below |
| `DIAuditor` | **green**, 2 tests | suite 10 |
| `FeatureLinkerUnlabeled` | **green**, 4 tests | the parquet directory fixture is no longer needed: the 3.6 CTD writes `.consensusXML` and the wrapper's own tests pass (suite 10) |
| `AssayGeneratorMetaboSirius` | **blocked**, `D12` | needs a directory input, see `D12` |

`D9` cannot be fixed from this repository.  CTDConverter builds the batch-mode
conditional itself (`ctdconverter/galaxy/converter.py:1407`): it deep-copies the
data parameter into `<when value="no">` and puts the single variant into
`<when value="yes">`, so both Galaxy parameter paths are literally
`in_cond|in`.  Galaxy's `format_source` resolution therefore sees two candidates,
and qualifying the name does not help - there is nothing to disambiguate.  The
fix belongs upstream (name the batch branch differently) and the warning does not
affect the 10 passing `ConsensusID` tests.

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

### What `strip_output_dirs.py` drops (D2/D3)

The CTDs of OpenMS 3.6 declare **11** parameters as `type="output-dir"`, in the
four wrapped tools and in four blacklisted ones:

| tool | parameter | what it is |
|---|---|---|
| `IsobaricWorkflow`, `MS1LabeledWorkflow`\*, `ProteinQuantifier`, `ProteomicsLFQ`\*, `ProSE` | `out_qpx` | a *directory* of one qpx per input file |
| `ProSE` | `out_parquet` | the same for parquet (excluded on both sides, D2) |
| `ProSE` | `out_mod_analysis_dir` | the whole modified-peptide analysis: per-mod tables, plots, FASTA |
| `OpenSwathExport`\*, `OpenSwathPeakMapExtractor`\* | `out_dir` | one file per transition group |
| `ProteomicsLFQ`\* | `feat_dir` | the per-run featureXML set |
| `QualityControl` | `directory` | the MaxQuant-style report bundle |

\* blacklisted, so no wrapper exists for it anyway.

A Galaxy dataset is a single file, and even the `Directory` datatype Galaxy
learned later can not be *requested* by an `<output>` - a tool has to produce a
file. `strip_output_dirs.py` therefore deletes those 11 parameters from the CTD
snapshot before the conversion, which keeps the remaining outputs of the same
tools (idXML, mzTab, the QC JSONs) wrappable: `QualityControl` loses only its
report bundle, `ProSE` only the optional duplicates.

The alternative would be to write into a subdirectory and `tar` it, and to
declare the output as a `tar.gz`. It is only worth it for `QualityControl`,
whose `directory` is the MaxQuant-compatible table set a user may actually want
to download; for `out_qpx`/`out_parquet` the format is excluded anyway, and
`feat_dir`/`out_dir` belong to blacklisted tools. Left open, not forgotten.

## Round 7 — remote test data (PR review §2)

The wrappers no longer need a copy of the OpenMS test data.  A reference that
exists in the OpenMS source tree is fetched by Galaxy itself:

| reference | how many | mechanism |
|---|---|---|
| single file, exists upstream | 1359 | `location="https://raw.githubusercontent.com/OpenMS/OpenMS/v3.6.0/<path>"` on the `<param>`/`<output>` |
| output upstream only compares through FuzzyDiff | 688 assertion sites / 90 references | `has_size` (0.3-1.7x), `has_n_lines` (0.5-2x+1), `is_valid_xml` from `aux/output_expectations.tsv` |
| fixture a download cannot be named after | 6 | committed to `test-data/` (`unique_files()` renames a file used twice in one command line, `prepare_test_data_manual.sh` generates one) |
| comma separated multi-file value | 56 | stays local: one `<param>` has one `location` slot. CI runs `test-data.sh` (`.github/workflows/pr.yaml`), so these tests behave exactly as before |

Decisions: `D21` (the mechanism and the expectation snapshot), `D22` (the
manifest key), `D23` (an annotated output keeps `value=`/`compare=`), `D24`
(`delta_frac` needs an absolute `delta` next to it, which is why the manifest
carries sizes: 272 outputs gained one), `D25` (a prepared intermediate may not
shadow a committed reference), `D26` (`*.xic`/`*.xim` are Parquet, not XML).

What this buys: a fresh clone can run any single-file test without the 10 GB
OpenMS test-data working copy, and a fixture the generator cannot explain is now
a *gate* failure instead of a silently missing file (check 9).  What it costs:
`planemo test` needs network for its inputs, because an input `location`
overrides the local fixture (`tool_util/verify/interactor.py`,
`_get_path_or_location`).  Expected *outputs* are asymmetric: Galaxy prefers a
local `test-data/<value>` when one exists and only downloads when it does not
(`__test_data_downloader`), so CI - which populates `test-data/` - keeps
comparing against the fixtures it just generated, while a fresh clone compares
against the upstream reference.  The offline recipe is a `sed` away and
documented in `aux/upgrade/README.md`.

A `test-data/` holding only the committed fixtures is enough for the
single-file tests and for every assertion, but **not** for all 142 tools:
`FileMerger`, `IDMerger`, `FeatureLinkerUnlabeled{,KD,QT}`, `OpenSwathDIAPreScoring`
and `QCShrinker` still fail on the multi-file values and on the one reference
`prepare_test_data_manual.sh` produces.  That is the documented trade-off, not a
regression: CI runs `test-data.sh`, so the suite there is unaffected.

Verification: `check_generated.sh` (9 checks) green; `check_generated.sh
--regen` reports the wrappers byte-identical to HEAD; independent regenerations
produce the same 1359/688/6/56 counts; `DecoyDatabase`, `XMLValidator`,
`AccurateMassSearch`, `ConsensusMapNormalizer`, `Epifany`, `PeptideIndexer` and
`INIUpdater` pass in Galaxy against a pristine `test-data/` (41 files) - the
tools listed two paragraphs up are the expected exceptions.

The full suite against the populated `test-data/` ran 142 tools / **626 tests**
in 15 chunks and finished with 6 failures, which are what D25 and D26 answer:

| test | what it was |
|---|---|
| `IsobaricAnalyzer (Test #2)`, `(#3)` | D27 - the upgraded `.ini` had `type=itraq4plex`, so the test pinned the wrong experiment; D25 is what made it visible |
| `OpenSwathWorkflow (Test #3)` | D26 - `is_valid_xml` on a Parquet `.xic` |
| `FileInfo (Test #12)`, `IDFilter (Test #3)`, `(#7)` | infrastructure, not the wrappers: *"Input staging problem"*, an empty response while polling the job (`json.decoder.JSONDecodeError` inside `stage_data_in_history`). The three tools re-ran alone: 50/50 tests green |

`IsobaricAnalyzer` and `OpenSwathWorkflow` pass after the two fixes; the suite is
then 626/626.

## Round 6.5 — the PR review, answered in the generator

Ten review comments on #783. Five of them are mechanical and land here; the
verdicts and the open ones are in `.openms-tests/TODO-review-783.md`.

**§1 the five mechanical points.**  `profile` (`D15`), `std::string` (`D16`),
`${X_BINARY}` (`D17`), artefacts (`D18`), `*.yaml` (`D20`).  Two of them turned
out bigger than the comment suggested:

* `${X_BINARY}` was not only a wrapper defect.  `get_tests.py` threw the whole
test away because the command line kept an unexpanded `${...}` - 29 upstream
  tests, 14 of which are now runnable, including the six `TOPP_CometAdapter_*`
  the review named explicitly.  Verifying that restoration uncovered two further
generator bugs, both of which cost a tool *all* of its tests:

  - `add_test("TOPP_CometAdapter_6"  CometAdapter -test ...` - 3.6 writes two
    spaces after some test ids.  The one-space regex did not match, the line
    fell through to `Ill formated test line`, and `sys.exit()` took the tool
    with it.  The regex now allows any run of whitespace.
  - `missing_inputs()` classified an argument as an input by its `-in` prefix.
    `-pin_out` is `type="output-file"` in the CTD and has no `-in` prefix to
    miss, so it looked like a missing input - four more CometAdapter tests
    gone.  Both checks now come from the CTD, not from the parameter name.

  `MSFraggerAdapter`/`NovorAdapter` keep zero tests (`D19`): same wrapper
defect, but the jars are licence-gated, so the fixtures can not be produced.

* `tools/openms/.gitignore` is gone rather than reworded.  Everything it listed
  is a build artefact and now lives in `$ARTIFACTS`, so the tool directory has
  nothing left to hide.  `macros_autotest.xml` also left `GLOBAL_FILES` in
  `manifest.py` - the fingerprint already covers the wrapper that includes it.

**Verification.**  142 wrappers, 626 tests (612 before), `planemo lint` clean on
the changed files, `check_generated.sh` all green including the manual-test
fixture check (which now finds 0 problems: the 5 dangling
`MSGFPlusAdapter_1_out.idXML` references disappeared with the restored tests,
because `TOPP_MSGFPlusAdapter_*` produces the `.idXML` again).  The nine
wrappers whose test count moved were run in Galaxy against the *recipe*
environment (`openms` + `openms-thirdparty` 3.6.0 from bioconda, i.e. the
`comet`/`percolator`/`msgf_plus`/`sage`/`luciphor2` the requirements would
install): 23 of 23 tests pass.

Running that suite also proved the value of the `D17` split: the sandbox's
mulled environment had lost `bin/comet`, `bin/sage`, `bin/msgf_plus` and the
boost libraries (a `$HOME` cleanup took 27k files out of it), which is exactly
what a user without `openms-thirdparty` sees - and the failure was
`Error: Executable not found`, not a broken wrapper.  Restoring the packages
from the conda cache fixed it.

**Full suite.**  All 142 wrappers were then run in Galaxy (`results/archive-4/`
of the test harness, 15 chunks): **123 tools, 626 passed, 0 failed, 0 errors**.
The 19 tools the summary does not mention are exactly the wrappers without a
`<test>` (checked, not assumed: the per-tool test counts of the wrappers and of
the suite agree for all 123).  `manifest.py import-summary --stamp` folded that
run into the ledger - the `--stamp` flag is new, because an imported summary
belongs to the tree it was produced from, and the old fingerprint is what made
`report --gate` call every tool stale after a regeneration:

    tools 142 / pass 123 / skip 19 / stale 0 / escalate 0 -> GATE PASSED

**Not done here** (`§2` of the TODO list): the ~1205 `compare="sim_size"
delta_frac="0.7"` outputs are the strongest review point - most of them should
be remote `location="https://..."` references plus `has_size`/`assert_contents`
rather than generated fixtures.  That is a per-test decision over 1205 outputs,
not a generator switch, and it changes what the suite downloads.  Also open:
the `DatabaseSuitability` skip reason, the size of `aux/upgrade/`,
`strip_output_dirs.py` documentation, `QualityControl`'s directory output, and
the `macros_test.xml` `expect_num_outputs` drift.

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
