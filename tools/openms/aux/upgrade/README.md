# OpenMS version upgrade loop

Upgrading the OpenMS wrappers is a **fixpoint iteration over a generator**. This
directory holds the tooling that keeps the iteration monotone and terminating.

## Model

| | |
|---|---|
| **Inputs (the state)** | `aux/*` (`filetypes.txt`, `hardcoded_params.json`, `tools_blacklist.txt`, `macros_test.xml`), `macros.xml`, `test-data/**` (regenerated locally by `test-data.sh`, *not* versioned), and a *frozen* upstream: OpenMS tag + exact conda build string + a CTD snapshot of both versions |
| **Derived (never edit)** | every generated `<Tool>.xml`, the artefacts `test-data.sh` produces (`ctd/`, `macros_autotest.xml`, `macros_discarded_auto.xml`, `prepare_test_data.sh`, `.upstream-fixtures.txt`) - all in `$ARTIFACTS`, never in the tool directory |
| **Progress measure** | the number of tools in the failure set `F`, where `F` = (wrappers without a passing test) − allowlist |
| **Termination rule** | each round either shrinks `F` or moves one tool into the allowlist with a recorded decision |

A round is only meaningful if the state ⇒ wrapper mapping is deterministic, so
*regenerate twice and diff* is a hard gate, not a nicety.

## Rounds

| Round | Goal | Gate |
|---|---|---|
| 0 | Pin upstream, snapshot the **old** CTDs, record a **baseline** test manifest on the current branch | `manifest.py fingerprint --out fingerprints.json`, full `run_tests.sh --all --update` |
| 1 | Tool-set diff only: add new tools, move removed ones to `deprecated/`, blacklist directory-output tools | `ctd_diff.py` tool set section is empty of surprises, `check_generated.sh` |
| 2 | Param/format churn: `filetypes.txt`, `hardcoded_params.json` | `ctd_diff.py` has no unexplained `MISSING`/`STALE` hints |
| 3 | Autotest failures, bucketed by root cause | `run_tests.sh --changed --update`, `manifest.py report --gate` |
| 4 | Manual tests (`.ini` migration, `manutest_*`), expected-output refresh with justification | `report --gate` |
| 5 | Full run, compare against the round-0 baseline | `report --gate` green, `check_generated.sh --regen` clean |

Do not interleave: rounds 1–2 never run tests, rounds 3–4 never touch the tool
set. Fixing "whatever changed since the last commit" mixes both and is what makes
the loop feel circular.

## Commands

```sh
cd tools/openms

# the two environments the loop needs (conda env *prefixes* work too)
conda create -y -p ~/envs/openms32 -c conda-forge -c bioconda openms=3.2.0
conda create -y -p ~/envs/openms36 -c conda-forge -c bioconda openms=3.6.0
# planemo is not part of the images, install it once:
python -m pip install --user planemo

# round 0, while the old version is still installed
aux/upgrade/snapshot_ctds.sh 3.2 ~/envs/openms32
aux/upgrade/run_tests.sh --all --update

# after switching the generator to the new version (needs a 3.6 env)
aux/upgrade/snapshot_ctds.sh 3.6 ~/envs/openms36
python3 aux/upgrade/ctd_diff.py aux/upgrade/ctd-snapshots/3.2 \
        aux/upgrade/ctd-snapshots/3.6 --json aux/upgrade/ctd-diff-3.2-3.6.json \
        > aux/upgrade/ctd-diff-3.2-3.6.md

# every round
aux/upgrade/check_generated.sh          # static gate (fast, pre-commit)
aux/upgrade/run_tests.sh --changed --update
python3 aux/upgrade/manifest.py report --gate

# only when the aux/* inputs changed materially (slow: needs conda + OpenMS env)
aux/upgrade/check_generated.sh --regen
```

The CTD snapshots are read from the `openms` conda package's file list, not from
`bin/`: the same prefix also holds third-party binaries that block on stdin when
handed `-write_ctd`. `.ctd` files are git-ignored, `provenance.txt` is not, so a
diff stays reproducible.

`ctd_diff.py` is the highest-value piece: it turns "the regenerated XML diff is
huge" into a per-tool list of renamed/added/removed parameters with hints at the
file that has to change (`filetypes.txt`, `hardcoded_params.json` stale entries,
`.ini` fixtures).

## Rules

1. **Never edit a generated wrapper.** If a fix is not expressible in `aux/*`,
   it is a decision (round-3 escalation), not a patch. Temporary tests are fine
   but belong in an untracked file that regeneration deletes.
2. **Two strikes → decide.** A tool that failed twice for different causes gets
   a decision recorded in `UPGRADE_LEDGER.md`: `blacklist`, `deprecated/`,
   `lint_skip`, or a hand-written `manutest_*`. No third attempt.
3. **Never refresh expected outputs to make a test pass.** Reference files are
   regenerated only with a one-line justification in the ledger (FuzzyDiff
   tolerance, algorithm change, renamed column). Otherwise the round converges
   by weakening the safety net — which is how 108 empty `manutest_*` stubs and a
   global `TestsMissing` skip happen.
4. **Commit by nature, not by round**: (a) `aux/` + `test-data/` changes —
   reviewable by a human, (b) regenerated wrappers — machine output,
   `git diff --stat` must be explainable by (a), (c) refreshed reference files
   with justifications. Then `git checkout -- . && aux/generate.sh && git diff`
   is a two-command idempotence proof.
5. **`macros*.xml`, `filetypes.txt`, `hardcoded_params.json` have global blast
   radius** — any change there invalidates every recorded test result;
   `manifest.py changed` says so explicitly.

## Test data

The wrappers do not ship the OpenMS test data. A reference which exists in the
OpenMS source tree is fetched by Galaxy itself:

```xml
<param name="in" value="FileFilter_1_input.mzML"
       location="https://raw.githubusercontent.com/OpenMS/OpenMS/v3.6.0/src/tests/topp/FileFilter_1_input.mzML"/>
```

* `aux/upstream-fixtures.tsv` (committed, written by `test-data.sh`) maps the
  fixture basename to its URL and byte size, so `get_tests.py` needs neither
  network nor an OpenMS clone and the wrappers stay a pure function of versioned
  state. The tag comes from `macros.xml` (`@TOOL_VERSION@` → `v3.6.0`).
* the size is not decoration: Galaxy's `sim_size` checks an absolute `delta`
  (default **10000**) *before* it checks `delta_frac`
  (`tool_util/verify/__init__.py`, `assert_size`), so `delta_frac="0.7"` on its
  own rejects any reference more than 10 kB away. The annotator therefore also
  writes the matching `delta` (`0.7 x reference size`) next to the `location`.
  Without it a real upstream reference failed the comparison that a locally
  regenerated fixture had always passed (both were the same file).
* a basename which occurs in more than one of the copied directories resolves
  to the `src/tests/topp` copy - that is the one `test-data.sh` has always
  flattened into `test-data/` (e.g. `PepXMLFile_test.pepxml` is also class-test
  data).
* everything a download cannot provide - the intermediates a test writes for a
  later test, and the 89 outputs upstream only compares through FuzzyDiff
  tolerances - is *asserted on* instead of compared: the bounds live in
  `aux/output_expectations.tsv` (written by `aux/make_expectations.py`),
  `aux/remote_test_data.py` turns them into `has_size`/`has_n_lines`/
  `is_valid_xml`. Written out by hand only when the expected numbers must
  change (version bump, reviewed output change) and justified in the ledger:
  regenerating them automatically would let a regression rewrite its own
  expectation.
* a value with several files for one flag
  (`<param name="in" value="a.dta,b.dta"/>`, 56 of them) keeps using
  `test-data/`: the test attribute is one element, so a single `location` cannot
  describe two files. They are the reason CI still runs `test-data.sh`; check 9
  counts them separately instead of demanding a `location`.
* a reference the OpenMS checkout brings with it may not be replaced by the
  intermediate the test writes: `fix_tmp_files()` symlinks `test-data/<reference>`
  onto that intermediate (a *build artifact*, compared with itself). An existing
  regular file in `test-data/` therefore wins; only a symlink (or nothing) is
  replaced.
* the `.ini` files are upgraded with `<tool> -ini <old> -write_ini <new>`, which
  writes the tool's **defaults** - so a value the tool sets itself would be
  lost. `aux/check_ini_conversion.py` compares the values under their node path,
  `aux/ini_keep_original.txt` lists the fixtures that must keep their original
  (`IsobaricAnalyzer:type` came back as `itraq4plex`, which turned the TMT test
  into an iTRAQ one; the two `PPHiRes_invalidValue*` fixtures must stay invalid)
  and every other changed value is printed as a warning.
* `*.xic` / `*.xim` are **Parquet**, not XML (they start with `PAR1`), so
  `aux/filetypes.txt` maps them to Galaxy's `binary` - declaring them `xml` made
  Galaxy run its XML validator over a binary file.
* `check_generated.sh` check 9 fails the gate when a reference is neither
  remote, asserted on nor committed to `test-data/`.

The two directions are not symmetric (`tool_util/verify/interactor.py`):

* an **input** with `location` is uploaded from the URL and the local file is
  ignored (`_get_path_or_location`), so a fresh clone needs no `test-data/`;
* an **expected output** with `location` is compared against the *local*
  `test-data/<value>` when that file exists, and only downloaded when it does
  not (`__test_data_downloader.test_data_download_from_location`). CI fills
  `test-data/` (`test-data.sh`), so CI keeps comparing against its own fixtures
  and a fresh clone compares against the upstream reference - both are real
  checks, they just cannot be the same file.

`planemo test` therefore needs network for the inputs. Offline:

```bash
aux/generate.sh                 # as always: creates the fixtures in test-data/
sed -i -E 's/ location="https:\/\/raw\.githubusercontent\.com[^"]*"//g' ./*.xml
planemo test ...
git checkout -- .               # never commit this, the wrappers are generated
```

The assertions do not need a reference, so offline only the inputs have to
exist.

## Files

| file | purpose |
|---|---|
| `ctd_diff.py` | structural CTD diff + impact hints |
| `manifest.py` | fingerprints (per fixture, with clock/timing tokens washed out), "what changed", decision ledger, round gate |
| `check_generated.sh` | static gate, idempotence check, freeze/unfreeze |
| `check_manual_tests.py` | the hand-written material (fixtures, and the macro tests as they ended up in the wrappers) |
| `snapshot_ctds.sh` | one CTD snapshot per OpenMS version (+ provenance) |
| `../remote_test_data.py` | adds `location=` / `assert_contents` to the generated tests (also applied to `aux/macros_test.xml`) |
| `../upstream-fixtures.tsv` | fixture basename → upstream URL (committed, written by `test-data.sh`) |
| `../make_expectations.py`, `../output_expectations.tsv` | what to assert for references without an upstream file |
| `run_tests.sh` | planemo per tool, records into the ledger |
| `teststatus.tsv`, `fingerprints.json` | machine-written loop state, commit at round ends (small, and it is the reviewer's evidence); `testlogs/` is git-ignored |
| `allowlist.txt` | known-broken tools that are not our doing, with reason |
| `unstable_fixtures.txt` | fixtures `test-data.sh` regenerates that are *not* reproducible (Epifany's EM, `-threads 4` order); the fingerprint records their existence, not their bytes |
| `UPGRADE_LEDGER.md` | per-round log, decisions, output-refresh justifications |
| `pre-commit` | optional hook: `cp aux/upgrade/pre-commit ../../.git/hooks/` |
| `selftest.sh` | self-test of `ctd_diff.py`/`manifest.py` on synthetic CTDs; run after touching them |

`aux/` is excluded from the ToolShed upload (`.shed.yml`), so none of this
ships with the wrappers.
