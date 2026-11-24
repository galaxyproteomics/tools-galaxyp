#!/usr/bin/env bash

# single source of truth: the version the wrappers declare
VERSION=$(grep -oP '<token name="@TOOL_VERSION@">\K[^<]+' macros.xml)
[ -n "$VERSION" ] || { echo "cannot read @TOOL_VERSION@ from macros.xml" >&2; exit 1; }
# OpenMS switched from release/<version> branches to v<version> tags in 3.6.0
GITTAG="${GITTAG:-v$VERSION.0}"
FILETYPES="aux/filetypes.txt"

if [ -z "$tmp" ]; then
    tmp=$(mktemp -d)
    created="yes"
fi

# everything the generator produces besides the wrappers themselves - the CTD
# snapshot, the generated test macros, the test shell script, the list of real
# fixtures - is a build artefact.  It lives in $ARTIFACTS, not in the tool
# directory: that directory is what goes to the ToolShed, and keeping the
# artefacts out of it means it needs no .gitignore.
ARTIFACTS="${ARTIFACTS:-$tmp/generated}"
mkdir -p "$ARTIFACTS"
export ARTIFACTS

export OPENMSGIT="$tmp/OpenMS$VERSION.0-git"
export OPENMSPKG="$tmp/OpenMS$VERSION-pkg/"
# reuse an existing environment if one is given
# export OPENMSENV=openms36
export OPENMSENV="${OPENMSENV:-OpenMS$VERSION-env}"


# the script is called from aux/generate.sh, i.e. in a subshell: make sure the
# conda shell function (not the bare executable) is available for `conda activate`
type conda >/dev/null 2>&1 || source "$(conda info --base)/etc/profile.d/conda.sh"

if [ -z "$CTDCONVERTER" ]; then
    # same rule as aux/generate.sh: prefer the checkout next to the repository
    # root, fall back to the scratch directory
    CTDCONVERTER=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/CTDConverter
    [ -d "$CTDCONVERTER" ] || CTDCONVERTER="$tmp/CTDConverter"
    export CTDCONVERTER
fi

if [[ -z "$1" ]]; then
	autotests="/dev/null"
else
	autotests="$1"
fi

if type conda > /dev/null; then  
    true
else
    wget https://github.com/conda-forge/miniforge/releases/download/24.9.2-0/Miniforge3-Linux-x86_64.sh
    bash Miniforge3-Linux-x86_64.sh -b -p "$tmp/miniforge"
    source "$tmp/miniforge/bin/activate"
fi
eval "$(conda shell.bash hook)"


###############################################################################
## get 
## - conda environment (for executing the binaries) and 
## - the git clone of OpenMS (for generating the tests)
###############################################################################

if [[ ! -d $OPENMSGIT ]]; then
    echo "Clone OpenMS $VERSION sources"
    if [[ "$created" == "yes" ]]; then
        GIT_DIR=$(mktemp -d --dry-run)
        GIT_EXTRA_OPTS="--separate-git-dir=$GIT_DIR"
    fi
    git clone -b $GITTAG --depth 1 --recurse-submodules=THIRDPARTY --shallow-submodules $GIT_EXTRA_OPTS https://github.com/OpenMS/OpenMS.git $OPENMSGIT
    ## save some space by just keeping the needed binaries
    find $OPENMSGIT/THIRDPARTY/ -type f -not \( -name maracluster -o -name spectrast \) -delete
    find $OPENMSGIT/THIRDPARTY/ -empty -type d -delete
    if [[ "$created" == "yes" ]]; then
        rm -rf $GIT_DIR
    fi
else
    echo "Update OpenMS $VERSION sources"
    cd $OPENMSGIT
    git pull origin $GITTAG
    cd -
fi

echo "Create OpenMS $VERSION conda env"
# TODO currently add lxml (needed by CTDConverter)
# TODO for some reason a to recent openjdk is used
if conda env list | grep "$OPENMSENV"; then
    true
else
    conda create -y --quiet --solver libmamba --override-channels --strict-channel-priority --channel conda-forge --channel bioconda -n $OPENMSENV openms=$VERSION openms-thirdparty=$VERSION ctdopts=1.5 lxml
# chmod -R u-w $OPENMSENV 
fi
###############################################################################
## get the list of OpenMS binaries: link the ones of the conda package rather
## than downloading and unpacking it (a .tar.bz2 for <= 3.5, a .conda since 3.6,
## and the build string changes with every rebuild). Reading conda-meta also
## excludes the third-party binaries in the same prefix, which block on stdin
## when handed -write_ctd.
###############################################################################
echo "Link OpenMS $VERSION binaries from the conda env"
# recreate every time: a half-filled directory from an interrupted run would
# silently make the CTD loop below iterate over a literal "bin/*" glob
rm -rf "$OPENMSPKG/bin"
mkdir -p "$OPENMSPKG/bin"
ENVPREFIX=$(conda run -n "$OPENMSENV" python3 -c 'import sys; print(sys.prefix)')
python3 - "$ENVPREFIX" "$OPENMSPKG/bin" <<'PY'
import glob, json, os, sys
prefix, dest = sys.argv[1], sys.argv[2]
# note: the glob must not pick openms-thirdparty, and older conda did not write
# the "files" key at all - select the record by name and fail loudly
meta = [p for p in glob.glob(os.path.join(prefix, "conda-meta", "*.json"))
        if json.load(open(p)).get("name") == "openms"]
if not meta:
    sys.exit("no openms package in %s" % prefix)
files = json.load(open(meta[-1])).get("files")
if not files:
    sys.exit("%s has no file list" % meta[-1])
for entry in files:
    if entry.startswith("bin/"):
        os.symlink(os.path.join(prefix, entry), os.path.join(dest, os.path.basename(entry)))
PY
if [[ -z "$(ls -A $OPENMSPKG/bin)" ]]; then
    echo "no OpenMS binaries found in $ENVPREFIX" >&2
    exit 1
fi

###############################################################################
## Get python libaries for CTD -> Galaxy conversion
## TODO fix to main repo OR conda packkage if PRs are merged 
###############################################################################
echo "Clone CTDConverter"
if [[ ! -d $CTDCONVERTER ]]; then
    #git clone https://github.com/WorkflowConversion/CTDConverter.git CTDConverter
    git clone -b topic/fix-selects2 https://github.com/bernt-matthias/CTDConverter.git $CTDCONVERTER
else
    cd $CTDCONVERTER
    git pull origin topic/fix-selects2
    cd -
fi
conda activate $OPENMSENV
cd $CTDCONVERTER
python -m pip install . --no-deps
cd -
conda deactivate


# # ###############################################################################
# # ## copy all the test data files to test-data
# # ## most of it (outputs) will be overwritten later, but its needed for
# # ## prepare_test_data
# # ###############################################################################
echo "Get test data"
find test-data -type f,l,d ! -name "*fa" ! -name "*loc" ! -name "test-data" ! -name MetaboliteSpectralDB.mzML -delete

cp $(find $OPENMSGIT/src/tests/topp/ -type f | grep -Ev "third_party_tests.cmake|CMakeLists.txt|check_ini") test-data/
# The parquet bundle fixtures (IDMerger_idparquet_input1.idparquet/ & co) are
# directories and the tests address their members by name
# (IDMerger_idparquet_input1.idparquet/psms.parquet).  Flattening them loses the
# directory, and since every bundle names its tables alike (psms.parquet,
# proteins.parquet, ...) one of them would also shadow the other.
for bundle in $OPENMSGIT/src/tests/topp/*.idparquet/ \
              $OPENMSGIT/src/tests/topp/*.featureparquet/ \
              $OPENMSGIT/src/tests/topp/*.consensusparquet/; do
    if [ -d "$bundle" ]; then
        cp -r "$bundle" test-data/
    fi
done
cp -r $OPENMSGIT/share/OpenMS/MAPPING/ test-data/
cp -r $OPENMSGIT/share/OpenMS/CHEMISTRY test-data/
cp -r $OPENMSGIT/share/OpenMS/examples/ test-data/
# two FileConverter tests feed class-test data (${DATA_DIR_CLASS_TESTS})
cp $OPENMSGIT/src/tests/class_tests/openms/data/MSPGenericFile_input.msp test-data/ 2> /dev/null
# the upstream OpenSwathExport test feeds the shared PyProphet inference OSW, which
# only exists as class-test data (OPENSWATH_SHARED_INFERENCE_OSW, CMakeLists.txt)
cp $OPENMSGIT/src/tests/class_tests/openms/data/PyProphet_inference_test.osw test-data/ 2> /dev/null
if [ ! -f test-data/MetaboliteSpectralDB.mzML ]; then
    DB_URL=https://raw.githubusercontent.com/sneumann/OpenMS/8ede4b6916edddabdda743413b9739d351ef2ca9/share/OpenMS/CHEMISTRY/MetaboliteSpectralDB.mzML
    # not every machine has wget (this one does not)
    if command -v wget > /dev/null; then
        wget -nc "$DB_URL"
    else
        curl -fsSL -o MetaboliteSpectralDB.mzML "$DB_URL" || exit 1
    fi
    mv MetaboliteSpectralDB.mzML test-data/
fi

## everything above is copied from the OpenMS source tree.  prepare_test_data.sh
## afterwards creates all sorts of intermediates in test-data/ (e.g. the parquet
## directories of the FeatureLinker tests), and a test which *consumes* such a
## file cannot be expressed in Galaxy.  Remember what really exists, so
## get_tests.py can tell fixtures from intermediates.
( cd test-data && find . -mindepth 1 -maxdepth 3 ! -name "." \( -type f -o -type l -o -type d \) \
    | sed 's@^\./@@' | sort > "$ARTIFACTS/.upstream-fixtures.txt" ) || exit 1
export OPENMS_UPSTREAM_FIXTURES="$ARTIFACTS/.upstream-fixtures.txt"

## Which fixture lives where in the OpenMS repository.  Galaxy can download a
## test file from a URL ("remote test data", `location="..."` on a test
## <param>/<output>), which is what lets a wrapper be tested without a local
## copy of the fixture.  The manifest is committed as aux/upstream-fixtures.tsv:
## get_tests.py must not depend on the runtime state of test-data/ - or on this
## clone existing - when the wrappers are generated.
##
##   basename <TAB> https://raw.githubusercontent.com/OpenMS/OpenMS/<commit>/<path> <TAB> bytes
##
## The commit, not the tag: raw.githubusercontent.com serves whatever a tag points
## at, so a re-tagged v3.6.0 would silently change what ~1400 references compare
## against.  The tag stays the handle for the clone, `git rev-parse` below turns
## it into the immutable commit.
##
## Baselining by name is safe: the wrapper test attributes reference fixtures by
## basename, and every referenced name resolves to exactly one file here (the
## few ambiguous ones - the parquet tables of the blacklisted parquet tools, the
## SIRIUS project files - are dropped, they stay local fixtures).
echo "Write the upstream fixture manifest"
GITSHA=$(git -C "$OPENMSGIT" rev-parse "$GITTAG^{commit}") || exit 1
echo "  fixtures of $GITTAG ($GITSHA)"
python3 - "$OPENMSGIT" "$ARTIFACTS/upstream-fixtures.tsv" \
    "https://raw.githubusercontent.com/OpenMS/OpenMS/$GITSHA/" <<'PY' || exit 1
import collections, os, sys
root, out, base = sys.argv[1], sys.argv[2], sys.argv[3]
# the directories test-data.sh copies from (share/) or picks single files out of
# (class_tests/openms/data -> class-test data of the FileConverter tests)
roots = ["src/tests/topp", "share/OpenMS/MAPPING", "share/OpenMS/CHEMISTRY",
         "share/OpenMS/examples", "src/tests/class_tests/openms/data"]
skip = {"third_party_tests.cmake", "CMakeLists.txt"}
paths = collections.defaultdict(list)
for r in roots:
    for dirpath, _dirnames, filenames in os.walk(os.path.join(root, r)):
        for name in filenames:
            if name.startswith("."):
                continue
            if r == "src/tests/topp" and (name in skip or "check_ini" in name):
                continue
            paths[name].append(os.path.relpath(os.path.join(dirpath, name), root))
# test-data.sh flattens src/tests/topp into test-data/, so for a name which
# exists in more than one of the roots the topp copy is the one the wrappers
# have always used (e.g. PepXMLFile_test.pepxml is also class test data)
topp = {n: [p for p in ps if p.startswith("src/tests/topp" + os.sep)]
        for n, ps in paths.items()}
rows = {}
for name, ps in paths.items():
    if len(ps) == 1:
        rows[name] = ps[0]
    elif len(topp[name]) == 1:
        rows[name] = topp[name][0]
# not in the OpenMS tree (the spectral library is 30 MB and lives in a fork)
rows["MetaboliteSpectralDB.mzML"] = None
PIN = "8ede4b6916edddabdda743413b9739d351ef2ca9"
with open(out, "w") as fh:
    for name in sorted(rows):
        # pinned: a branch would silently change what the test compares against
        url = ("https://raw.githubusercontent.com/sneumann/OpenMS/%s/"
               "share/OpenMS/CHEMISTRY/MetaboliteSpectralDB.mzML" % PIN if rows[name] is None
               else base + rows[name])
        # the size lets the wrapper compare a remote reference by size at all:
        # Galaxy checks an absolute `delta` (default 10000) *before* `delta_frac`
        size = 0 if rows[name] is None else os.path.getsize(os.path.join(root, rows[name]))
        fh.write("%s\t%s\t%d\n" % (name, url, size))
print("%d unique fixtures, %d ambiguous name(s) dropped"
      % (len(rows), len(paths) - len(rows)))
PY
export OPENMS_FIXTURES_TSV="$ARTIFACTS/upstream-fixtures.tsv"
if [ -f aux/upstream-fixtures.tsv ] && ! diff -q aux/upstream-fixtures.tsv "$OPENMS_FIXTURES_TSV" > /dev/null; then
    echo "WARNING: aux/upstream-fixtures.tsv differs from the manifest just written" >&2
    echo "         (regenerate the wrappers and commit the manifest)" >&2
fi

## The manually curated tests get the same treatment as the generated ones:
## fixtures which exist upstream are referenced by URL, and references we cannot
## download are asserted on.  The source file stays hand maintained and readable
## (check_manual_tests.py validates it); the annotated copy is what the
## conversion consumes.
echo "Annotate the manually curated tests"
python3 aux/remote_test_data.py aux/macros_test.xml -o "$ARTIFACTS/macros_test.xml" || exit 1

# if [ ! -d test-data/pepnovo_models/ ]; then
#     mkdir -p /tmp/pepnovo
#     wget -nc http://proteomics.ucsd.edu/Software/PepNovo/PepNovo.20120423.zip
#     unzip PepNovo.20120423.zip -d /tmp/pepnovo/
#     mv /tmp/pepnovo/Models test-data/pepnovo_models/
#     rm PepNovo.20120423.zip
#     rm -rf /tmp/pepnovo
# fi
###############################################################################
## generate ctd files using the binaries in the conda package 
###############################################################################
echo "Create CTD files"
conda activate $OPENMSENV
ctd="$ARTIFACTS/ctd"
rm -rf "$ctd"
mkdir -p "$ctd"
export OPENMS_CTD_DIR="$ctd"

for i in $OPENMSPKG/bin/*
do
    b=$(basename $i)
    echo $b
    $b -write_ctd "$ctd"/
    sed -i -e 's/²/^2/' "$ctd"/$b.ctd
done
if [[ -z "$(ls -A "$ctd")" ]]; then
    echo "no CTD files were written - check the binary list in $OPENMSPKG/bin" >&2
    exit 1
fi
## OpenMS 3.6 CTDs contain parameters of a type that CTDopts cannot parse at all
## (one such parameter breaks the conversion of the whole suite).  The type is a
## prefix that ends with a separator, so it is retyped rather than dropped - the
## wrapper can then declare a collection for the directory, see the script.
python3 aux/retype_output_dirs.py "$ctd"/
## correct the CTD parameters which upstream left unannotated (e.g. the FASTA
## outputs of DecoyDatabase).  Must happen here, before get_tests.py reads the
## CTDs: it derives the ftype of the expected test outputs from the
## supported_formats, and CTDConverter derives the datatype of the output from
## them.  Patching only before the conversion (i.e. in generate.sh) yields a
## wrapper whose output is 'fasta' while its own test still expects 'txt'.
python3 aux/patch_ctds.py "$ctd"/ || >&2 echo 'patching the CTDs failed'
###############################################################################
## fix ini files: OpenMS test data contains ini files with outdated ini files.
## e.g. variables might be in different nodes, outdated variables present, new
## variables missing, ...
## OpenMS tools fix this on the fly (so its no problem for the OpenMS tests)
## but it is for the generation of the tests
## see https://github.com/OpenMS/OpenMS/issues/4462
###############################################################################
echo "Update test INI files"
KEEP_INI=$(mktemp)
grep -v '^\s*#\|^\s*$' aux/ini_keep_original.txt > $KEEP_INI
for ini in test-data/*ini
do
    tool=$(cat $ini | grep 'NODE name="' | head -n 1 | sed 's/.*name="\([^"]\+\)".*/\1/')
    bin=$(which $tool)
    if [[ -z $bin ]]; then
          >&2 echo "missing binary to convert $ini"
          continue
    fi
    cp $ini $ini.backup
    ## -write_ini writes the *defaults* of the tool; -ini only selects the
    ## parameter set which gets augmented, so a value the tool sets itself does
    ## not survive the round trip.  IsobaricAnalyzer's ':type' is the one that
    ## breaks a test: TMTTenPlexMethod_test.ini came back as 'itraq4plex' and
    ## the produced consensusXML was an iTRAQ file while the upstream reference
    ## is a TMT one (upstream hides this with -whitelist "<map").  Such a file
    ## is listed in aux/ini_keep_original.txt and keeps its original; any other
    ## file is converted, but a changed value is reported.
    $bin -ini $ini -write_ini $ini.converted > $ini.stdout 2> $ini.stderr
    if [[ "$?" -ne "0" ]]; then
        >&2 echo "could not convert $ini"
        rm -f $ini.converted
        continue
    fi
    if ! python3 aux/check_ini_conversion.py $ini $ini.converted > $ini.changed; then
        if grep -qxF "$(basename $ini)" $KEEP_INI; then
            >&2 echo "keeping $ini (aux/ini_keep_original.txt): $(head -n 1 $ini.changed)"
            rm -f $ini.converted
            continue
        fi
        >&2 echo "warning: converting $ini changes $(head -n 1 $ini.changed)"
    else
        rm -f $ini.changed
    fi
    mv $ini.converted $ini
done

###############################################################################
## create script to create results for the tests and run it
###############################################################################
# parse data preparation calls from OpenMS sources for a tool with a given id
function prepare_test_data {
#     id=$1
# | egrep -i "$id\_.*[0-9]+(_prepare\"|_convert)?"

    BL="$(mktemp)"
    grep -v "^#\|^$" aux/tools_blacklist.txt > $BL

    OLD_OSW_PARAM=$(cat $OPENMSGIT/src/tests/topp/CMakeLists.txt |sed 's/#.*$//'| sed 's/^\s*//; s/\s*$//' |awk '{printf("%s@NEWLINE@", $0)}' |  sed 's/)@NEWLINE@/)\n/g' | sed 's/@NEWLINE@/ /g' | grep OLD_OSW_PARAM | head -n 1 | sed 's/^[^"]\+//; s/)$//; s/"//g')
    cat $OPENMSGIT/src/tests/topp/CMakeLists.txt  $OPENMSGIT/src/tests/topp/THIRDPARTY/third_party_tests.cmake |
        sed "s/\${OLD_OSW_PARAM}/$OLD_OSW_PARAM/" |
        grep -v "\.ini\.json" |
        grep -v -f "$BL" |
        sed 's/.ini.json /ini /' | 
        sed 's/#.*$//'| 
        sed 's/^\s*//; s/\s*$//' | 
        grep -v "^$"  | 
        awk '{printf("%s@NEWLINE@", $0)}' | 
        sed 's/)@NEWLINE@/)\n/g' | sed 's/@NEWLINE@/ /g' | 
        sed 's/degenerate_cases\///' | 
        # CMAKE_COMMAND tests are cmake scripts (${CMAKE_COMMAND} -E copy ...,
        # ${CMAKE_COMMAND} -DINPUT_FILE=... -P ...), not tool invocations
        egrep -v "WRITEINI|WRITECTD|INVALIDVALUE|DIFF|CMAKE_COMMAND" | 
        grep add_test | 
        egrep "TOPP|UTILS" |
        sed 's@${DATA_DIR_SHARE}/@@g;'|
        sed 's@${DATA_DIR_CLASS_TESTS}/@@g'|
        # some tests name the build directory directly instead of using ${TESTS_TEMP_DIR}
        sed 's@\btmp_path/@@g'|
        # since 3.6 intermediates live in ${TESTS_TEMP_DIR}: same as above, the
        # wrapper tests refer to the reference file in test-data
        sed 's@${TESTS_TEMP_DIR}/@@g'|
        # chained tests (upstream: set_tests_properties(... DEPENDS ...)) take an
        # intermediate of another test as input; that intermediate does not exist
        # here and the corresponding wrapper test is skipped as well
        egrep -v -- '-in[0-9]* [^ ]*\.tmp\.'|
        # negative tests which check that a missing parameter is rejected
        grep -v 'requires_'|
        sed 's@${TMP_RIP_PATH}@./@g'|
    while read line
    do
        test_id=$(echo "$line" | sed 's/add_test(//; s/"//g;  s/)[^)]*$//; s/\${TOPP_BIN_PATH}\///g;s/\${DATA_DIR_TOPP}\///g; s#THIRDPARTY/##g' | cut -d" " -f1)

        # WILL_FAIL and PASS_REGULAR_EXPRESSION mark negative tests: the tool is
        # expected to refuse the input, so the non-zero exit code below is not a
        # problem (and the test has no comparable output)
        if grep -Eq "$test_id\"[^)]*(WILL_FAIL 1|PASS_REGULAR_EXPRESSION)" $OPENMSGIT/src/tests/topp/CMakeLists.txt $OPENMSGIT/src/tests/topp/THIRDPARTY/third_party_tests.cmake; then
            >&2 echo "    skip negative test "$test_id
            continue
        fi

        line=$(echo "$line" | sed 's/add_test("//; s/)[^)]*$//; s/\${TOPP_BIN_PATH}\///g;s/\${DATA_DIR_TOPP}\///g; s#THIRDPARTY/##g' | cut -d" " -f2-)
        # the external-binary tests pass the program as
        #   -comet_executable "${COMET_BINARY}"
        # and upstream wraps the whole block in
        #   if (NOT (${COMET_BINARY} STREQUAL "COMET_BINARY-NOTFOUND"))
        # so CMake leaves the variable unset here.  The *_BINARY variables are
        # exported at the top of this script, hence the shell form resolves at
        # run time: the fixtures for those tests are produced by exactly the
        # program the wrapper will pin later (get_tests.py drops the flag, the
        # wrapper gets it from aux/hardcoded_params.json).
        line=$(echo "$line" | sed -E 's/\$\{([A-Za-z_][A-Za-z0-9_]*_BINARY)\}/$\1/g')
        unresolved=$(echo "$line" | grep -oE '\$\{[A-Za-z_]+\}' | sort -u | tr '\n' ' ')
        if [ -n "$unresolved" ]; then
            >&2 echo "    skip $test_id (unresolved variable(s): $unresolved)"
            continue
        fi
        # line="$(fix_tmp_files $line)"
        echo 'echo executing "'$test_id'"'
        echo "$line > $test_id.stdout 2> $test_id.stderr"
        echo "if [[ \"\$?\" -ne \"0\" ]]; then >&2 echo '$test_id failed'; >&2 echo -e \"stderr:\n\$(cat $test_id.stderr | sed 's/^/    /')\"; echo -e \"stdout:\n\$(cat $test_id.stdout)\";fi"    
    done
}

echo "Create test shell script"

prep="$ARTIFACTS/prepare_test_data.sh"
echo -n "" > "$prep"
echo 'export COMET_BINARY="comet"' >> "$prep"
echo 'export LUCIPHOR_BINARY="$(dirname $(realpath $(which luciphor2)))/luciphor2.jar"' >> "$prep"

echo 'export MARACLUSTER_BINARY="'"$OPENMSGIT"'/THIRDPARTY/Linux/64bit/MaRaCluster/maracluster"'>> "$prep"
# no host paths here: the jar is looked up on PATH (and the test skipped/failed
# loudly if it is missing)
echo 'export MSFRAGGER_BINARY="MSFragger.jar"'>> "$prep"
echo 'export MSGFPLUS_BINARY="$(msgf_plus -get_jar_path)"' >> "$prep"
echo 'export NOVOR_BINARY="novor.jar"' >> "$prep"
echo 'export PERCOLATOR_BINARY="percolator"'>> "$prep"
echo 'export SPECTRAST_BINARY="'"$OPENMSGIT"'/THIRDPARTY/Linux/64bit/SpectraST/spectrast"' >> "$prep"
echo 'export SAGE_BINARY=sage' >> "$prep"

prepare_test_data >> "$prep" #tmp_test_data.sh

echo "Execute test shell script"
chmod u+x "$prep"
cd ./test-data || exit
"$prep"
cd - || exit


# ###############################################################################
# ## create/update test data for the manually generated tests
# ## - run convert once with the manual tests only and 
# ## - update test-data (needs to run 2x)
# ###############################################################################
echo "Execute test shell script for manually curated tests"
chmod u+x prepare_test_data_manual.sh
cd ./test-data || exit
../prepare_test_data_manual.sh
cd - || exit


###############################################################################
## auto generate tests
###############################################################################

echo "Write test macros to $autotests"
echo "<macros>" > "$autotests"
for i in "$ctd"/*ctd
do
    b=$(basename "$i" .ctd)
    ./get_tests.py --id "$b" --version "$VERSION" --cmake "$OPENMSGIT"/src/tests/topp/CMakeLists.txt "$OPENMSGIT"/src/tests/topp/THIRDPARTY/third_party_tests.cmake >> "$autotests"
    wc -l "$autotests"
done
echo "</macros>" >> "$autotests"

# tests for tools using output_prefix parameters can not be auto generated
# hence we output the tests for manual curation in macros_test.xml
# and remove them from the autotests
# -> OpenSwathFileSplitter IDRipper MzMLSplitter SeedListGenerator
# TODO reevaluate in >2.8 
# - https://github.com/OpenMS/OpenMS/pull/5873
# - https://github.com/OpenMS/OpenMS/pull/5912
#
# Furthermore we remove tests for tools without binaries in conda
# -> MSFragger MaRaClusterAdapter NovorAdapter 
#
# not able to specify composite test data  
# -> SpectraSTSearchAdapter 
echo "Discard some tests"
command -v xmlstarlet > /dev/null || { echo "xmlstarlet not found - install the xtools env or put it on PATH" >&2; exit 1; }
if [[ ! -z "$1" ]]; then
    echo "" > "$ARTIFACTS/macros_discarded_auto.xml"
    for i in OpenSwathFileSplitter IDRipper MzMLSplitter SeedListGenerator MSFraggerAdapter MaRaClusterAdapter NovorAdapter SpectraSTSearchAdapter
    do
        # xmlstarlet sel exits 1 when the expression selects nothing, which is
        # the normal case for a tool whose upstream tests were all skipped (a
        # tool without a test has nothing to discard and must not abort the run)
        n=$(xmlstarlet sel -t -v "count(/macros/xml[@name='autotest_$i']/test)" "$autotests") \
            || { echo "xmlstarlet failed on $autotests" >&2; exit 1; }
        if [ "$n" = 0 ]; then
            >&2 echo "$i has no autogenerated test, nothing to discard"
            continue
        fi
        echo "<xml name=\"manutest_$i\">" >>  "$ARTIFACTS/macros_discarded_auto.xml"
        xmlstarlet sel -t -c "/macros/xml[@name='autotest_$i']/test" "$autotests" >>  "$ARTIFACTS/macros_discarded_auto.xml" || exit 1
        echo "</xml>"  >>  "$ARTIFACTS/macros_discarded_auto.xml"
        xmlstarlet ed -d "/macros/xml[@name='autotest_$i']/test" "$autotests" > "$ARTIFACTS/tmp" || exit 1
        [ -s "$ARTIFACTS/tmp" ] || { echo "xmlstarlet produced an empty macro file while discarding $i" >&2; exit 1; }
        mv "$ARTIFACTS/tmp" "$autotests"
    done
    >&2 echo "discarded autogenerated macros for curation in $ARTIFACTS/macros_discarded_auto.xml"
fi
conda deactivate

## remove broken symlinks in test-data
find test-data/ -xtype l -delete

if [[ "$created" == "yes" ]]; then
    echo "Removing temporary directory"
    rm -rf "$tmp"
    conda env remove -n "$OPENMSENV"
fi

