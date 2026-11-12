#!/usr/bin/env bash
# Snapshot the CTD files of one OpenMS version, for ctd_diff.py.
#
#   snapshot_ctds.sh 3.2   [ENV]     env defaults to openms32 / $CONDA_PREFIX
#   snapshot_ctds.sh 3.6   [ENV]
#
# Round 0 of an upgrade needs the *old* snapshot taken while the old version is
# still installed: without it there is no structural diff and every round is
# guesswork.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
TOOLDIR="$(cd "$HERE/../.." && pwd)"
VERSION="${1:?usage: snapshot_ctds.sh VERSION [ENV]}"
ENVNAME="${2:-}"
DEST="$TOOLDIR/aux/upgrade/ctd-snapshots/$VERSION"

if [ -d "$DEST" ] && [ "${FORCE:-0}" != "1" ]; then
    echo "$DEST already exists (set FORCE=1 to overwrite)" >&2
    exit 1
fi

if [ -n "$ENVNAME" ]; then
    eval "$(conda shell.bash hook)"
    conda activate "$ENVNAME"
fi
PREFIX="${CONDA_PREFIX:-}"
[ -n "$PREFIX" ] || { echo "no active conda env and none given" >&2; exit 1; }
export OPENMS_DATA_PATH="$PREFIX/share/OpenMS/"

mkdir -p "$DEST"
# Prefer the file list of the openms conda package: iterating bin/ also hits
# third-party binaries (percolator, msgf_plus, ...) that either block on stdin
# or dump core when given -write_ctd.
mapfile -t BINS < <(python3 - "$PREFIX" <<'PY'
import glob, json, os, sys
prefix = sys.argv[1]
meta = [p for p in glob.glob(os.path.join(prefix, "conda-meta", "*.json"))
        if json.load(open(p)).get("name") == "openms"]
if meta:
    pkg = json.load(open(meta[-1]))
    for entry in pkg["files"]:
        if entry.startswith("bin/"):
            print(os.path.join(prefix, entry))
else:  # not a conda install: fall back to everything executable in bin/
    for entry in sorted(glob.glob(os.path.join(prefix, "bin", "*"))):
        print(entry)
PY
)
ok=0 skipped=0
for bin in "${BINS[@]}"; do
    [ -x "$bin" ] || continue
    out=$(timeout 120 "$bin" -write_ctd "$DEST" </dev/null 2>&1)
    rc=$?
    if [ "$rc" -eq 0 ] && [ -f "$DEST/$(basename "$bin").ctd" ]; then
        ok=$((ok + 1))
    else
        skipped=$((skipped + 1))
        echo "  no CTD from $(basename "$bin") (rc=$rc): $(printf '%s' "$out" | head -1)" >&2
    fi
done
[ "${#BINS[@]}" -gt 0 ] || { echo "no OpenMS binaries found in $PREFIX" >&2; exit 1; }
# OpenMS writes some unit characters as a non-ASCII superscript
sed -i -e 's/²/^2/' "$DEST"/*.ctd

{
    echo "# CTD snapshot provenance"
    echo "version:  $VERSION"
    echo "prefix:   $PREFIX"
    echo "date:     $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "binaries: $ok wrote a CTD ($skipped did not, see stderr)"
    echo
    echo "## openms package"
    conda list openms 2>/dev/null | grep -E '^openms\s' || true
    echo
    echo "## relevant packages"
    timeout 120 conda list 2>/dev/null | grep -E '^(openms|libopenms|openms-thirdparty|thermorawfileparser|sirius|comet-ms|msgf_plus|sage-proteomics|percolator|luciphor2|mono|dotnet)' || true
} > "$DEST/provenance.txt"

echo "$ok CTD files -> $DEST"
echo "next: python3 aux/upgrade/ctd_diff.py aux/upgrade/ctd-snapshots/<old> $DEST"
