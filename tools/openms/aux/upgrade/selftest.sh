#!/usr/bin/env bash
# Self-test for the upgrade tooling: builds two tiny CTD snapshots with known
# deltas and asserts that ctd_diff.py classifies them as expected. Cheap, needs
# no conda, run it after touching ctd_diff.py or manifest.py.
#
#   aux/upgrade/selftest.sh
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
TOOLDIR="$(cd "$HERE/../.." && pwd)"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
fails=0

ck() { if eval "$2"; then echo "ok   $1"; else echo "FAIL $1"; fails=$((fails + 1)); fi }

mkdir -p "$TMP/old" "$TMP/new"
sed 's/@@VERSION@@/3.2.0/' > "$TMP/old/Foo.ctd" <<'CTD'
<?xml version="1.0" encoding="UTF-8"?>
<tool ctn="Foo" name="Foo" version="@@VERSION@@" docurl="http://example.org/Foo">
  <PARAMETERS version="1.7.0" xsi:noNamespaceSchemaLocation="CTD.xsd"
              xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <NODE name="Foo" description="Foos things.">
      <ITEM name="in" value="" type="input-file" description="Input file"
            required="true" advanced="false" supported_formats="*.mzML"/>
      <ITEM name="xml_out" value="" type="output-file" description="Output file"
            required="false" advanced="true" supported_formats="*.xml"/>
      <ITEM name="threads" value="1" type="int" description="Threads"
            required="false" advanced="true" restrictions="1:"/>
      <NODE name="RawToMzML">
        <ITEM name="NET_executable" value="" type="input-file" description=".NET"
              required="false" advanced="true" supported_formats="*"/>
      </NODE>
    </NODE>
  </PARAMETERS>
</tool>
CTD
sed 's/@@VERSION@@/3.6.0/' > "$TMP/new/Foo.ctd" <<'CTD'
<?xml version="1.0" encoding="UTF-8"?>
<tool ctn="Foo" name="Foo" version="@@VERSION@@" docurl="http://example.org/Foo">
  <PARAMETERS version="1.7.0" xsi:noNamespaceSchemaLocation="CTD.xsd"
              xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <NODE name="Foo" description="Foos things, now better.">
      <ITEM name="in" value="" type="input-file" description="Input file"
            required="true" advanced="false" supported_formats="*.mzML,*.mzPeak"/>
      <ITEM name="threads" value="0" type="int" description="Threads"
            required="false" advanced="true" restrictions="0:"/>
      <NODE name="RawToMzML">
        <ITEM name="dotnet_executable" value="" type="input-file" description=".NET"
              required="false" advanced="true" supported_formats="*"/>
        <ITEM name="reader" value="inprocess" type="string" description="Reader"
              required="false" advanced="true" restrictions="inprocess,external"/>
      </NODE>
    </NODE>
  </PARAMETERS>
</tool>
CTD
# the new version also drops a whole tool
sed 's/Foo/Bar/g; s/@@VERSION@@/3.2.0/' "$TMP/old/Foo.ctd" > "$TMP/old/Bar.ctd"

cat > "$TMP/hardcoded.json" <<'JSON'
{"xml_out": [{"CTD:required": true, "tools": ["Foo"]}],
 "NET_executable": [{"value": "mono", "tools": ["Foo"]}]}
JSON
printf 'txt\ttxt\nxml\txml\nmzML\tmzml\n' > "$TMP/filetypes.txt"

OUT=$(python3 "$HERE/ctd_diff.py" --with-descriptions "$TMP/old" "$TMP/new" \
      --hardcoded "$TMP/hardcoded.json" --filetypes "$TMP/filetypes.txt" 2>&1)
TSV=$(python3 "$HERE/ctd_diff.py" -f tsv "$TMP/old" "$TMP/new" \
      --hardcoded "$TMP/hardcoded.json" --filetypes "$TMP/filetypes.txt" 2>&1)
JSONOUT=$(python3 "$HERE/ctd_diff.py" "$TMP/old" "$TMP/new" --json "$TMP/diff.json" \
      --hardcoded "$TMP/hardcoded.json" --filetypes "$TMP/filetypes.txt" >/dev/null 2>&1; echo $?)

ck "tool set: Bar detected as removed"      'grep -q "removed: .*Bar" <<<"$OUT"'
ck "added param reader"                     'grep -q "\*\*+\*\* \`Foo:RawToMzML:reader\`" <<<"$OUT"'
ck "rename NET_executable -> dotnet"        'grep -q "rename\*\* \`Foo:RawToMzML:NET_executable\` -> \`Foo:RawToMzML:dotnet_executable\`" <<<"$OUT"'
ck "stale hardcoded entry (xml_out)"        'grep -q "Foo:xml_out.*STALE ENTRY" <<<"$OUT"'
ck "renamed hardcoded entry is stale (NET)"  'grep -q "NET_executable.*STALE ENTRY" <<<"$OUT"'
ck "formats change flagged"                 'grep -q "filetypes.txt" <<<"$OUT"'
ck "missing galaxy format mzPeak"           'grep -q "MISSING: mzPeak" <<<"$OUT"'
ck "default change flagged as behaviour"    'grep -q "behaviour" <<<"$OUT"'
ck "tsv mentions renamed"                   'grep -q "^Foo	renamed" <<<"$TSV"'
ck "json written and valid"                 '[ "$JSONOUT" = 0 ] && python3 -c "import json;d=json.load(open(\"$TMP/diff.json\"));assert d[\"removed_tools\"]==[\"Bar\"]"'

# manifest.py: fingerprints are stable across runs and detect a wrapper edit
FP1=$(cd "$TOOLDIR" && python3 aux/upgrade/manifest.py fingerprint --tools FileConverter)
FP2=$(cd "$TOOLDIR" && python3 aux/upgrade/manifest.py fingerprint --tools FileConverter)
ck "fingerprint is stable"                  '[ "$FP1" = "$FP2" ]'
ck "fingerprint reports fixture count"     'grep -q "refs=[0-9]" <<<"$FP1"'

if [ "$fails" -ne 0 ]; then
    echo
    echo "--- ctd_diff output ---"
    echo "$OUT"
    echo "$fails self-test(s) failed"
    exit 1
fi
echo "all self-tests passed"
