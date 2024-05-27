#!/usr/bin/env bash

# set -x

VERSION=3.1
FILETYPES="aux/filetypes.txt"
CONDAPKG="https://anaconda.org/bioconda/openms/3.1.0/download/linux-64/openms-3.1.0-h8964181_1.tar.bz2"

# import the magic
. ./generate-foo.sh

# install conda
if [ -z "$tmp" ]; then
    tmp=$(mktemp -d)
    created="yes"
fi

export OPENMSGIT="$tmp/OpenMS$VERSION.0-git"
export OPENMSPKG="$tmp/OpenMS$VERSION-pkg/"
export OPENMSENV="OpenMS$VERSION-env"

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
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
    bash Miniconda3-latest-Linux-x86_64.sh -b -p "$tmp/miniconda"
    source "$tmp/miniconda/bin/activate"
fi
eval "$(conda shell.bash hook)"


###############################################################################
## get 
## - conda environment (for executing the binaries) and 
## - the git clone of OpenMS (for generating the tests)
###############################################################################

echo "Clone OpenMS $VERSION sources"
if [[ ! -d $OPENMSGIT ]]; then
    if [[ "$created" == "yes" ]]; then
        GIT_DIR=$(mktemp -d --dry-run)
        GIT_EXTRA_OPTS="--separate-git-dir=$GIT_DIR"
    fi
    git clone -b release/$VERSION.0 --depth 1 --recurse-submodules=THIRDPARTY --shallow-submodules $GIT_EXTRA_OPTS https://github.com/OpenMS/OpenMS.git $OPENMSGIT
    ## save some space by just keeping the needed binaries
    find $OPENMSGIT/THIRDPARTY/ -type f -not \( -name maracluster -o -name spectrast \) -delete
    find $OPENMSGIT/THIRDPARTY/ -empty -type d -delete
    if [[ "$created" == "yes" ]]; then
        rm -rf $GIT_DIR
    fi
else
    cd $OPENMSGIT
    git pull origin release/$VERSION.0
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
## get the 
## - conda package (for easy access and listing of the OpenMS binaries), 
###############################################################################
echo "Download OpenMS $VERSION package $CONDAPKG"

if [[ ! -d $OPENMSPKG ]]; then
    mkdir $OPENMSPKG
    wget -q -P $OPENMSPKG/ "$CONDAPKG"
    tar -xf $OPENMSPKG/"$(basename $CONDAPKG)" -C $OPENMSPKG/
    rm $OPENMSPKG/"$(basename $CONDAPKG)"
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
if [ ! -f test-data/MetaboliteSpectralDB.mzML ]; then 
    wget -nc https://raw.githubusercontent.com/sneumann/OpenMS/master/share/OpenMS/CHEMISTRY/MetaboliteSpectralDB.mzML
    # wget -nc https://abibuilder.cs.uni-tuebingen.de/archive/openms/Tutorials/Data/latest/Example_Data/Metabolomics/databases/MetaboliteSpectralDB.mzML
    mv MetaboliteSpectralDB.mzML test-data/
fi
ln -fs TOFCalibration_ref_masses test-data/TOFCalibration_ref_masses.txt
ln -fs TOFCalibration_const test-data/TOFCalibration_const.csv

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
echo "Create test shell script"

echo -n "" > prepare_test_data.sh
echo 'export COMET_BINARY="comet"' >> prepare_test_data.sh
echo 'export CRUX_BINARY="crux"' >> prepare_test_data.sh
echo 'export FIDOCHOOSEPARAMS_BINARY="FidoChooseParameters"' >> prepare_test_data.sh
echo 'export FIDO_BINARY="Fido"' >> prepare_test_data.sh
echo 'export LUCIPHOR_BINARY="$(dirname $(realpath $(which luciphor2)))/luciphor2.jar"' >> prepare_test_data.sh

echo 'export MARACLUSTER_BINARY="'"$OPENMSGIT"'/THIRDPARTY/Linux/64bit/MaRaCluster/maracluster"'>> prepare_test_data.sh
echo 'export MSFRAGGER_BINARY="/home/berntm/Downloads/MSFragger-3.5/MSFragger-3.5.jar"'>> prepare_test_data.sh
echo 'export MSGFPLUS_BINARY="$(msgf_plus -get_jar_path)"' >> prepare_test_data.sh
echo 'export MYRIMATCH_BINARY="myrimatch"'>> prepare_test_data.sh
echo 'export NOVOR_BINARY="/home/berntm/Downloads/novor/lib/novor.jar"' >> prepare_test_data.sh
echo 'export PERCOLATOR_BINARY="percolator"'>> prepare_test_data.sh
echo 'export SIRIUS_BINARY="$(which sirius)"' >> prepare_test_data.sh
echo 'export SPECTRAST_BINARY="'"$OPENMSGIT"'/THIRDPARTY/Linux/64bit/SpectraST/spectrast"' >> prepare_test_data.sh
echo 'export XTANDEM_BINARY="xtandem"' >> prepare_test_data.sh
echo 'export THERMORAWFILEPARSER_BINARY="ThermoRawFileParser.exe"' >> prepare_test_data.sh
echo 'export SAGE_BINARY=sage' >> prepare_test_data.sh

prepare_test_data >> prepare_test_data.sh #tmp_test_data.sh

## prepare_test_data > tmp_test_data.sh
## # remove calls not needed for the tools listed in any .list file
## echo LIST $LIST
## if [ ! -z "$LIST" ]; then
##     REX=$(echo $LIST | sed 's/ /\n/g' | sed 's@.*/\([^/]\+\).xml$@\1@' | tr '\n' '|' | sed 's/|$//')
## else
##     REX=".*"
## fi
## echo REX $REX
## cat tmp_test_data.sh | egrep "($REX)" >> prepare_test_data.sh
## rm tmp_test_data.sh

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
    ./get_tests.py --id "$b" --cmake "$OPENMSGIT"/src/tests/topp/CMakeLists.txt "$OPENMSGIT"/src/tests/topp/THIRDPARTY/third_party_tests.cmake >> "$autotests"
    # get_tests2 "$b" >> "$autotests"
    wc -l "$autotests"
done
echo "</macros>" >> "$autotests"

# echo "Create test data links"
# Breaks DecoyDatabase
# link_tmp_files

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
        xmlstarlet sel -t -c "/macros/xml[@name='autotest_$i']/test" macros_autotest.xml >>  macros_discarded_auto.xml
        echo "</xml>"  >>  macros_discarded_auto.xml
        xmlstarlet ed -d "/macros/xml[@name='autotest_$i']/test" macros_autotest.xml > tmp
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
fi
