#!/usr/bin/env bash
# Gate for the generated wrappers.
#
#   check_generated.sh            static checks (fast, run before every commit)
#   check_generated.sh --regen    regenerate and prove nothing but intended
#                                 files changed (idempotence, slow: needs conda)
#   check_generated.sh --freeze   chmod a-w on generated wrappers
#   check_generated.sh --unfreeze chmod a+w (needed before regenerating)
#
# Rationale: the wrappers are a pure function of aux/* + the CTD files. Any
# hand edit in a generated file is silently reverted by the next generator run,
# which is the main way an upgrade loop starts going in circles. Make it
# impossible to do silently.
set -uo pipefail

cd "$(dirname "$0")/../.." || exit 1   # -> tools/openms
PATTERNS="aux/upgrade/forbidden_patterns.txt"
failures=0

note() { printf '%s\n' "$*"; }
warn() { printf 'WARN: %s\n' "$*" >&2; }
fail() { printf 'FAIL: %s\n' "$*" >&2; failures=$((failures + 1)); }

mapfile -t TOOLS < <(ls -1 *.xml | grep -v '^macros\.xml$')

case "${1:-}" in
--freeze)
    chmod a-w ./*.xml && note "froze ${#TOOLS[@]} wrappers"
    exit 0
    ;;
--unfreeze)
    chmod a+w ./*.xml && note "unfroze ${#TOOLS[@]} wrappers"
    exit 0
    ;;
--regen)
    note "regenerating (aux/generate.sh) ..."
    if ! bash aux/generate.sh >/tmp/generate.log 2>&1; then
        fail "aux/generate.sh returned non-zero (see /tmp/generate.log)"
    fi
    if ! git diff --quiet -- '*.xml'; then
        fail "regeneration changed wrappers -> generator is not idempotent, or a generated file was edited by hand:"
        git diff --stat -- '*.xml' | sed 's/^/  /'
    else
        note "idempotent: regenerated wrappers byte-identical to HEAD"
    fi
    ;;
esac

# 1. debug leftovers and environment leaks in generated files
if [ -f "$PATTERNS" ]; then
    while IFS=$'\t' read -r label pattern severity; do
        case "$label" in ''|'#'*) continue ;; esac
        severity=${severity:-fail}
        hits=$(grep -lE "$pattern" "${TOOLS[@]}" test-data.sh 2>/dev/null | tr '\n' ' ')
        [ -z "$hits" ] && continue
        if [ "$severity" = warn ]; then
            warn "$label: $hits"
        else
            fail "$label: $hits"
        fi
    done < "$PATTERNS"
fi

# 2. XML well-formedness
if command -v xmllint >/dev/null; then
    for f in "${TOOLS[@]}"; do
        xmllint --noout "$f" 2>/dev/null || fail "not well-formed: $f"
    done
else
    note "xmllint not found, skipping XML syntax check"
fi

# 3. version / profile consistency: macros.xml, generator and wrappers must agree,
#    and the help URLs must point at the documentation of that same version
VERSION=$(grep -oP '<token name="@TOOL_VERSION@">\K[^<]+' macros.xml | head -1)
GEN_VERSION=$(grep -oP '^VERSION=\K\S+' aux/generate.sh | head -1)
TD_VERSION=$(grep -oP '^VERSION=\K\S+' test-data.sh | head -1)
GEN_PROFILE=$(grep -oP '^PROFILE="\K[^"]+' aux/generate.sh | head -1)
note "version: macros.xml=${VERSION:-?} generate.sh=${GEN_VERSION:-?} test-data.sh=${TD_VERSION:-?}"
[ "$VERSION" = "$GEN_VERSION" ] && [ "$VERSION" = "$TD_VERSION" ] \
    || fail "OpenMS version differs between macros.xml ($VERSION), aux/generate.sh ($GEN_VERSION) and test-data.sh ($TD_VERSION)"

profiles=$(grep -hoP '^<tool [^>]*profile="\K[^"]+' "${TOOLS[@]}" | sort -u)
[ "$(printf '%s\n' $profiles | wc -l)" -eq 1 ] \
    || fail "wrappers use more than one profile: $(echo $profiles)"
[ -n "$GEN_PROFILE" ] && [ "$(echo $profiles)" != "$GEN_PROFILE" ] \
    && fail "wrapper profile '$(echo $profiles)' != aux/generate.sh PROFILE='$GEN_PROFILE'"

requirements=$(grep -L '@TOOL_VERSION@' "${TOOLS[@]}" 2>/dev/null | tr '\n' ' ')
[ -n "$requirements" ] && fail "wrappers not using @TOOL_VERSION@: $requirements"

if [ -n "$VERSION" ]; then
    if grep -ql "doxygen/release/[0-9]" "${TOOLS[@]}" 2>/dev/null; then
        wrong=$(grep -lP "doxygen/release/(?!$VERSION\.0/)[0-9.]+" "${TOOLS[@]}" 2>/dev/null | tr '\n' ' ')
        [ -n "$wrong" ] && fail "help URLs do not point at documentation version $VERSION.0: $wrong"
    fi
fi

# 4. TestsMissing must be an explicit, counted decision, not an accident
lint_skip=$(tr '\n' ' ' < .lint_skip 2>/dev/null)
untested=()
for f in "${TOOLS[@]}"; do
    grep -q '<test ' "$f" || untested+=("$(basename "$f" .xml)")
done
note "wrappers without <test>: ${#untested[@]}"
case "$lint_skip" in
*TestsMissing*) note "  tolerated by .lint_skip: TestsMissing" ;;
*)
    [ "${#untested[@]}" -ne 0 ] && fail "wrappers without tests and no TestsMissing in .lint_skip: ${untested[*]}"
    ;;
esac

if [ "$failures" -ne 0 ]; then
    printf '\n%d check(s) failed\n' "$failures" >&2
    exit 1
fi
note "all static checks passed"
