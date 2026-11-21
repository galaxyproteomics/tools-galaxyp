#!/usr/bin/env bash
# Run planemo tests per tool and record the outcome in the round ledger.
#
#   run_tests.sh --all                 every wrapper (round 0 / final round)
#   run_tests.sh --changed             only tools whose fingerprint moved
#                                     since the recorded round (+ unresolved)
#   run_tests.sh --tools A,B,FileConverter
#   options: --jobs N (default 1)  --update  (write ledger rows)
#            --dry-run  --planemo-opts "--biocontainers"
#
# Tools whose result is already known pass are skipped unless --all/--force.
set -uo pipefail

TOOLDIR="$(cd "$(dirname "$0")/../.." && pwd)"
MANIFEST="python3 $TOOLDIR/aux/upgrade/manifest.py"
LOGSDIR="$TOOLDIR/aux/upgrade/testlogs"
JOBS=1
UPDATE=no
DRY=no
FORCE=no
SCOPE=""
TOOLLIST=""
PLANEMO_OPTS="${PLANEMO_OPTS:-}"

while [ $# -gt 0 ]; do
    case "$1" in
    --all) SCOPE=all ;;
    --changed) SCOPE=changed ;;
    --tools) TOOLLIST="$2"; SCOPE=tools; shift ;;
    --jobs) JOBS="$2"; shift ;;
    --update) UPDATE=yes ;;
    --force) FORCE=yes ;;
    --dry-run) DRY=yes ;;
    --planemo-opts) PLANEMO_OPTS="$2"; shift ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
    esac
    shift
done

case "$SCOPE" in
all) mapfile -t TOOLS < <(cd "$TOOLDIR" && ls -1 *.xml | grep -v '^macros\.xml$' | sed 's/\.xml$//') ;;
changed) mapfile -t TOOLS < <(cd "$TOOLDIR" && $MANIFEST changed) ;;
tools) IFS=',' read -r -a TOOLS <<< "$TOOLLIST" ;;
*) echo "usage: run_tests.sh --all|--changed|--tools A,B [--jobs N] [--update] [--dry-run]" >&2; exit 2 ;;
esac

if [ "$DRY" = no ] && ! command -v planemo >/dev/null; then
    echo "planemo not found: pip install planemo (or use --dry-run)" >&2
    exit 1
fi
mkdir -p "$LOGSDIR"

run_one() {
    local tool="$1"
    local log="$LOGSDIR/$tool.log"
    local fp
    fp=$(cd "$TOOLDIR" && $MANIFEST fingerprint --tools "$tool" 2>/dev/null | cut -f2)
    if [ "$DRY" = yes ]; then
        echo "planemo test $PLANEMO_OPTS $tool.xml"
        return 0
    fi
    ( cd "$TOOLDIR" && planemo test $PLANEMO_OPTS "$tool.xml" ) >"$log" 2>&1
    local rc=$?
    if [ $rc -eq 0 ]; then
        [ "$UPDATE" = yes ] && $MANIFEST record --tool "$tool" --status pass --fp "$fp"
        echo "PASS  $tool"
    else
        local cause
        cause=$(grep -m1 -E "ERROR|Error|FAILED|failed|Traceback" "$log" | cut -c1-160 \
                | tr '\t' ' ')
        [ "$UPDATE" = yes ] && $MANIFEST record --tool "$tool" --status fail \
            --cause "${cause:-see aux/upgrade/testlogs/$tool.log}" --fp "$fp"
        echo "FAIL  $tool   ($log)"
    fi
    return 0
}

if [ "$FORCE" = no ] && [ "$SCOPE" != all ] && [ "$DRY" = no ]; then
    # drop tools already recorded as passing with the current fingerprint
    keep=()
    for tool in "${TOOLS[@]}"; do
        fp_now=$(cd "$TOOLDIR" && $MANIFEST fingerprint --tools "$tool" 2>/dev/null | cut -f2)
        fp_old=$(awk -F'\t' -v t="$tool" '$1 == t {print $6}' \
                 "$TOOLDIR/aux/upgrade/teststatus.tsv" 2>/dev/null)
        status=$(awk -F'\t' -v t="$tool" '$1 == t {print $2}' \
                 "$TOOLDIR/aux/upgrade/teststatus.tsv" 2>/dev/null)
        if [ "$status" = pass ] && [ "$fp_now" = "$fp_old" ]; then
            continue
        fi
        keep+=("$tool")
    done
    TOOLS=("${keep[@]}")
fi

echo "testing ${#TOOLS[@]} tool(s), jobs=$JOBS"
printf '%s\n' "${TOOLS[@]}" | xargs -r -P "$JOBS" -I{} bash -c "$(declare -f run_one); TOOLDIR='$TOOLDIR' \
    MANIFEST='$MANIFEST' LOGSDIR='$LOGSDIR' UPDATE='$UPDATE' DRY='$DRY' \
    PLANEMO_OPTS='$PLANEMO_OPTS'; run_one {}"

if [ "$UPDATE" = yes ] && [ "$DRY" = no ]; then
    echo
    ( cd "$TOOLDIR" && $MANIFEST report )
fi
