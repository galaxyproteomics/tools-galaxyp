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
ok=0 skipped=0
for bin in "$PREFIX"/bin/*; do
    [ -x "$bin" ] || continue
    if "$bin" -write_ctd "$DEST" >/dev/null 2>&1; then
        ok=$((ok + 1))
    else
        skipped=$((skipped + 1))
    fi
done
# OpenMS writes some unit characters as a non-ASCII superscript
sed -i -e 's/²/^2/' "$DEST"/*.ctd

{
    echo "# CTD snapshot provenance"
    echo "version:  $VERSION"
    echo "prefix:   $PREFIX"
    echo "date:     $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "tools:    $ok (skipped $skipped non-TOPP executables)"
    echo
    echo "## relevant packages"
    conda list 2>/dev/null | grep -E '^(openms|libopenms|openms-thirdparty|thermorawfileparser|sirius|comet-ms|msgf_plus|sage-proteomics|percolator|luciphor2|mono|dotnet)' || true
} > "$DEST/provenance.txt"

echo "$ok CTD files -> $DEST"
echo "next: python3 aux/upgrade/ctd_diff.py aux/upgrade/ctd-snapshots/<old> $DEST"
