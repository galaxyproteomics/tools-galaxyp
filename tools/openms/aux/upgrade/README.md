# OpenMS version upgrade loop

Upgrading the OpenMS wrappers is a **fixpoint iteration over a generator**. This
directory holds the tooling that keeps the iteration monotone and terminating.

## Model

| | |
|---|---|
| **Inputs (the state)** | `aux/*` (`filetypes.txt`, `hardcoded_params.json`, `tools_blacklist.txt`, `macros_test.xml`), `macros.xml`, `test-data/**` (regenerated locally by `test-data.sh`, *not* versioned), and a *frozen* upstream: OpenMS tag + exact conda build string + a CTD snapshot of both versions |
| **Derived (never edit)** | every generated `<Tool>.xml`, `test-data.sh` output, `ctd/` |
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

## Files

| file | purpose |
|---|---|
| `ctd_diff.py` | structural CTD diff + impact hints |
| `manifest.py` | fingerprints, "what changed", decision ledger, round gate |
| `check_generated.sh` | static gate, idempotence check, freeze/unfreeze |
| `snapshot_ctds.sh` | one CTD snapshot per OpenMS version (+ provenance) |
| `run_tests.sh` | planemo per tool, records into the ledger |
| `teststatus.tsv`, `fingerprints.json` | machine-written loop state, commit at round ends (small, and it is the reviewer's evidence); `testlogs/` is git-ignored |
| `allowlist.txt` | known-broken tools that are not our doing, with reason |
| `UPGRADE_LEDGER.md` | per-round log, decisions, output-refresh justifications |
| `pre-commit` | optional hook: `cp aux/upgrade/pre-commit ../../.git/hooks/` |
| `selftest.sh` | self-test of `ctd_diff.py`/`manifest.py` on synthetic CTDs; run after touching them |

`aux/` is excluded from the ToolShed upload (`.shed.yml`), so none of this
ships with the wrappers.
