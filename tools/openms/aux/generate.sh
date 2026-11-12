#!/usr/bin/env bash

# set -x

VERSION=3.2
FILETYPES="aux/filetypes.txt"
PROFILE="23.0"
## FILETYPES_RE=$(grep -v "^#" $FILETYPES | grep -v "^$" | cut -f 1 -d" " | tr '\n' '|' | sed 's/|$//'| sed 's/|/\\|/g')

# export tmp=$(mktemp -d)
export tmp="/tmp/openms-stuff/"
# export CTDCONVERTER="$tmp/CTDConverter"
###############################################################################
## reset old data
###############################################################################
rm $(ls *xml |grep -v macros)
rm -rf ctd
mkdir -p ctd
echo "" > prepare_test_data.sh

###############################################################################
## generate tests
## also creates 
## - conda environment (for executing the binaries) and 
## - the git clone of OpenMS (for generating the tests)
## - ctd files
###############################################################################
bash ./test-data.sh ./macros_autotest.xml

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

>&2 echo "generate tool xml from ctd files"
find . -maxdepth 0 -name "[A-Z]*xml" -delete
source $(dirname $(which conda))/../etc/profile.d/conda.sh
conda activate OpenMS$VERSION-env
CTDConverter galaxy -i ctd/*ctd -o ./ -s aux/tools_blacklist.txt -f "$FILETYPES" \
	-m macros.xml -p aux/hardcoded_params.json \
	--test-macros macros_autotest.xml --test-macros-prefix autotest_  --test-macros aux/macros_test.xml --test-macros-prefix manutest_ \
	--tool-version $VERSION --tool-profile $PROFILE --bump-file aux/bump.json > convert.out 2> convert.err
if [[ "$?" -ne "0" ]]; then >&2 echo 'CTD -> XML conversion failed'; >&2 echo -e "stderr:\n$(cat convert.err)"; fi
conda deactivate

sed -i -e 's@http://www.openms.de/doxygen/nightly/html/@https://openms.de/doxygen/release/'$VERSION'.0/html/@' ./*xml

# rm -rf macros_autotest.xml macros_discarded_auto.xml prepare_test_data.sh ctd