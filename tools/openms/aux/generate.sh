#!/usr/bin/env bash

# set -x

# single source of truth: the version the wrappers declare
VERSION=$(grep -oP '<token name="@TOOL_VERSION@">\K[^<]+' macros.xml)
[ -n "$VERSION" ] || { echo "cannot read @TOOL_VERSION@ from macros.xml" >&2; exit 1; }
FILETYPES="aux/filetypes.txt"
# same trick: the profile is a token, so the wrappers carry '@PROFILE@' and a
# bump is one line in macros.xml (Galaxy expands the token when it loads the
# tool, CTDConverter writes the attribute verbatim)
PROFILE=$(grep -oP '<token name="@PROFILE@">\K[^<]+' macros.xml)
[ -n "$PROFILE" ] || { echo "cannot read @PROFILE@ from macros.xml" >&2; exit 1; }
## FILETYPES_RE=$(grep -v "^#" $FILETYPES | grep -v "^$" | cut -f 1 -d" " | tr '\n' '|' | sed 's/|$//'| sed 's/|/\\|/g')

# export tmp=$(mktemp -d)
# override for hosts where /tmp is small
# export tmp="/tmp/openms-stuff/"
export tmp="${tmp:-/tmp/openms-stuff/}"
# build artefacts (CTD snapshot, generated test macros, test shell script) go
# here, never into the tool directory (see test-data.sh)
export ARTIFACTS="${ARTIFACTS:-$tmp/generated}"
mkdir -p "$ARTIFACTS"
# export CTDCONVERTER="$tmp/CTDConverter"
###############################################################################
## reset old data
###############################################################################
rm $(ls *xml |grep -v macros)

###############################################################################
## generate tests
## also creates 
## - conda environment (for executing the binaries) and 
## - the git clone of OpenMS (for generating the tests)
## - ctd files
###############################################################################
# test-data.sh curates the test macros; when it fails halfway the wrappers are
# generated from a partial state (and silently lose or gain tests), so stop.
bash ./test-data.sh "$ARTIFACTS/macros_autotest.xml" || exit 1

###############################################################################
## get the 
## - conda package (for easy access and listing of the OpenMS binaries), 
###############################################################################
# if [ ! -d $OPENMSPKG ]; then
# 	mkdir $OPENMSPKG/
# 	wget -P $OPENMSPKG/ "$CONDAPKG"
# 	tar -xf $OPENMSPKG/"$(basename $CONDAPKG)" -C OpenMS$VERSION-pkg/
#   rm $OPENMSPKG/"$(basename $CONDAPKG)"
# fi

###############################################################################
## Get python libaries for CTD -> Galaxy conversion
## TODO fix to main repo OR conda packkage if PRs are merged 
###############################################################################
# if [ ! -d CTDopts ]; then
# 	# git clone https://github.com/genericworkflownodes/CTDopts CTDopts
# 	git clone -b topic/no-1-2x https://github.com/bernt-matthias/CTDopts CTDopts
# fi
if [ ! -d $CTDCONVERTER ]; then
	#git clone https://github.com/WorkflowConversion/CTDConverter.git CTDConverter
	git clone -b topic/fix-selects2 https://github.com/bernt-matthias/CTDConverter.git $CTDCONVERTER
fi

###############################################################################
## conversion ctd->xml 
###############################################################################

# correct the CTD parameters which upstream left unannotated (e.g. the FASTA
# outputs of DecoyDatabase), before CTDConverter turns them into Galaxy types
python3 aux/patch_ctds.py "$ARTIFACTS"/ctd/ || >&2 echo 'patching the CTDs failed'

>&2 echo "generate tool xml from ctd files"
find . -maxdepth 0 -name "[A-Z]*xml" -delete
source $(dirname $(which conda))/../etc/profile.d/conda.sh
conda activate "${OPENMSENV:-OpenMS$VERSION-env}"
CTDConverter galaxy -i "$ARTIFACTS"/ctd/*ctd -o ./ -s aux/tools_blacklist.txt -f "$FILETYPES" \
	-m macros.xml -p aux/hardcoded_params.json \
	--test-macros "$ARTIFACTS"/macros_autotest.xml --test-macros-prefix autotest_  --test-macros "$ARTIFACTS"/macros_test.xml --test-macros-prefix manutest_ \
	--tool-version $VERSION --tool-profile '@PROFILE@' --bump-file aux/bump.json \
	> "$ARTIFACTS"/convert.out 2> "$ARTIFACTS"/convert.err
if [[ "$?" -ne "0" ]]; then >&2 echo 'CTD -> XML conversion failed'; >&2 echo -e "stderr:\n$(cat "$ARTIFACTS"/convert.err)"; fi
conda deactivate

sed -i -e 's@http://www.openms.de/doxygen/nightly/html/@https://openms.de/doxygen/release/'$VERSION'.0/html/@' ./*xml

# Parquet-directory outputs cannot be a single <data>; CTDConverter knows nothing
# about the bundle layout, so the collections are added afterwards (D30).
python3 aux/parquet_bundles.py || { >&2 echo 'adding the parquet bundle outputs failed'; exit 1; }

# the build artefacts in $ARTIFACTS are kept for inspection; remove them with
#   rm -rf "$ARTIFACTS"
# or let test-data.sh delete them via `tmp=$(mktemp -d)`