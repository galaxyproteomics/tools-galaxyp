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

export OPENMSGIT="$tmp/OpenMS$VERSION.0-git"
export OPENMSPKG="$tmp/OpenMS$VERSION-pkg/"
# reuse an existing environment if one is given
# export OPENMSENV=openms36
export OPENMSENV="${OPENMSENV:-OpenMS$VERSION-env}"


# the script is called from aux/generate.sh, i.e. in a subshell: make sure the
# conda shell function (not the bare executable) is available for `conda activate`
type conda >/dev/null 2>&1 || source "$(conda info --base)/etc/profile.d/conda.sh"

if [ -z "$CTDCONVERTER" ]; then
    export CTDCONVERTER="$tmp/CTDConverter"
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
cp -r $OPENMSGIT/share/OpenMS/MAPPING/ test-data/
cp -r $OPENMSGIT/share/OpenMS/CHEMISTRY test-data/
cp -r $OPENMSGIT/share/OpenMS/examples/ test-data/
# two FileConverter tests feed class-test data (${DATA_DIR_CLASS_TESTS})
cp $OPENMSGIT/src/tests/class_tests/openms/data/MSPGenericFile_input.msp test-data/ 2> /dev/null
if [ ! -f test-data/MetaboliteSpectralDB.mzML ]; then
    DB_URL=https://raw.githubusercontent.com/sneumann/OpenMS/master/share/OpenMS/CHEMISTRY/MetaboliteSpectralDB.mzML
    # not every machine has wget (this one does not)
    if command -v wget > /dev/null; then
        wget -nc "$DB_URL"
    else
        curl -fsSL -o MetaboliteSpectralDB.mzML "$DB_URL" || exit 1
    fi
    mv MetaboliteSpectralDB.mzML test-data/
fi

#TODO remove? ln -fs TOFCalibration_ref_masses test-data/TOFCalibration_ref_masses.txt
#TODO remove? ln -fs TOFCalibration_const test-data/TOFCalibration_const.csv

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
rm -rf ctd
mkdir -p ctd

for i in $OPENMSPKG/bin/*
do
    b=$(basename $i)
    echo $b
    $b -write_ctd ctd/
    sed -i -e 's/²/^2/' ctd/$b.ctd
done
if [[ -z "$(ls -A ctd)" ]]; then
    echo "no CTD files were written - check the binary list in $OPENMSPKG/bin" >&2
    exit 1
fi
## OpenMS 3.6 CTDs contain parameters of a type that CTDopts cannot parse at all
## (one such parameter breaks the conversion of the whole suite), see the script
python3 aux/strip_output_dirs.py ctd/
###############################################################################
## fix ini files: OpenMS test data contains ini files with outdated ini files.
## e.g. variables might be in different nodes, outdated variables present, new
## variables missing, ...
## OpenMS tools fix this on the fly (so its no problem for the OpenMS tests)
## but it is for the generation of the tests
## see https://github.com/OpenMS/OpenMS/issues/4462
###############################################################################
echo "Update test INI files"
for ini in test-data/*ini
do
    tool=$(cat $ini | grep 'NODE name="' | head -n 1 | sed 's/.*name="\([^"]\+\)".*/\1/')
    bin=$(which $tool)
    if [[ -z $bin ]]; then
          >&2 echo "missing binary to convert $ini"
          continue
    fi
    cp $ini $ini.backup
    $bin -ini $ini -write_ini $ini > $ini.stdout 2> $ini.stderr
    if [[ "$?" -ne "0" ]]; then
        >&2 echo "could not convert $ini"
    fi
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
    # TODO SiriusAdapter depends on online service which may timeout .. so keep disabled https://github.com/OpenMS/OpenMS/pull/5010
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
        sed 's@TOFCalibration_ref_masses @TOFCalibration_ref_masses.txt @g; s@TOFCalibration_const @TOFCalibration_const.csv @'| 
	sed 's/\("TOPP_SiriusAdapter_4".*\)-sirius:database all\(.*\)/\1-sirius:database pubchem\2/' |
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

echo -n "" > prepare_test_data.sh
echo 'export COMET_BINARY="comet"' >> prepare_test_data.sh
echo 'export CRUX_BINARY="crux"' >> prepare_test_data.sh
echo 'export FIDOCHOOSEPARAMS_BINARY="FidoChooseParameters"' >> prepare_test_data.sh
echo 'export FIDO_BINARY="Fido"' >> prepare_test_data.sh
echo 'export LUCIPHOR_BINARY="$(dirname $(realpath $(which luciphor2)))/luciphor2.jar"' >> prepare_test_data.sh

echo 'export MARACLUSTER_BINARY="'"$OPENMSGIT"'/THIRDPARTY/Linux/64bit/MaRaCluster/maracluster"'>> prepare_test_data.sh
# no host paths here: the jar is looked up on PATH (and the test skipped/failed
# loudly if it is missing)
echo 'export MSFRAGGER_BINARY="MSFragger.jar"'>> prepare_test_data.sh
echo 'export MSGFPLUS_BINARY="$(msgf_plus -get_jar_path)"' >> prepare_test_data.sh
echo 'export MYRIMATCH_BINARY="myrimatch"'>> prepare_test_data.sh
echo 'export NOVOR_BINARY="novor.jar"' >> prepare_test_data.sh
echo 'export PERCOLATOR_BINARY="percolator"'>> prepare_test_data.sh
echo 'export SIRIUS_BINARY="$(which sirius)"' >> prepare_test_data.sh
echo 'export SPECTRAST_BINARY="'"$OPENMSGIT"'/THIRDPARTY/Linux/64bit/SpectraST/spectrast"' >> prepare_test_data.sh
echo 'export XTANDEM_BINARY="xtandem"' >> prepare_test_data.sh
echo 'export THERMORAWFILEPARSER_BINARY="ThermoRawFileParser.exe"' >> prepare_test_data.sh
echo 'export SAGE_BINARY=sage' >> prepare_test_data.sh

prepare_test_data >> prepare_test_data.sh #tmp_test_data.sh

echo "Execute test shell script"
chmod u+x prepare_test_data.sh
cd ./test-data || exit
../prepare_test_data.sh
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
for i in $(ls ctd/*ctd)
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
if [[ ! -z "$1" ]]; then
    echo "" > macros_discarded_auto.xml
    for i in OpenSwathFileSplitter IDRipper MzMLSplitter SeedListGenerator MSFraggerAdapter MaRaClusterAdapter NovorAdapter SpectraSTSearchAdapter
    do
        echo "<xml name=\"manutest_$i\">" >>  macros_discarded_auto.xml
        xmlstarlet sel -t -c "/macros/xml[@name='autotest_$i']/test" macros_autotest.xml >>  macros_discarded_auto.xml || exit 1
        echo "</xml>"  >>  macros_discarded_auto.xml
        xmlstarlet ed -d "/macros/xml[@name='autotest_$i']/test" macros_autotest.xml > tmp || exit 1
        [ -s tmp ] || { echo "xmlstarlet produced an empty macro file while discarding $i" >&2; exit 1; }
        mv tmp macros_autotest.xml
    done
    >&2 echo "discarded autogenerated macros for curation in macros_discarded_auto.xml"
fi
conda deactivate

## remove broken symlinks in test-data
find test-data/ -xtype l -delete

if [[ "$created" == "yes" ]]; then
    echo "Removing temporary directory"
    rm -rf "$tmp"
    conda env remove -n "$OPENMSENV"
fi

