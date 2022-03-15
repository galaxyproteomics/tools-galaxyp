#!/usr/bin/env bash

VERSION=2.8
FILETYPES="filetypes.txt"
# TODO make 21.01
PROFILE="20.05"
## FILETYPES_RE=$(grep -v "^#" $FILETYPES | grep -v "^$" | cut -f 1 -d" " | tr '\n' '|' | sed 's/|$//'| sed 's/|/\\|/g')

export tmp=$(mktemp -d)
export tmp="/tmp/openms-stuff/"

export CTDCONVERTER="$tmp/CTDConverter"
###############################################################################
## reset old data
###############################################################################
# rm $(ls *xml |grep -v macros)
# rm -rf ctd
# mkdir -p ctd
# echo "" > prepare_test_data.sh

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

find . -maxdepth 0 -name "[A-Z]*xml" -delete
source $(dirname $(which conda))/../etc/profile.d/conda.sh
conda activate OpenMS$VERSION-env
CTDConverter galaxy -i ctd/*ctd -o ./ -s tools_blacklist.txt -f "$FILETYPES" -m macros.xml -t tool.conf  -p hardcoded_params.json --test-macros macros_autotest.xml --test-macros-prefix autotest_  --test-macros macros_test.xml --test-macros-prefix manutest_ --tool-version $VERSION --tool-profile $PROFILE --bump-file bump.json > convert.out 2> convert.err
if [[ "$?" -ne "0" ]]; then >&2 echo 'CTD -> XML conversion failed'; >&2 echo -e "stderr:\n$(cat convert.err)"; fi
conda deactivate

patch PepNovoAdapter.xml < PepNovoAdapter.patch
patch OMSSAAdapter.xml < OMSSAAdapter.patch

# https://github.com/OpenMS/OpenMS/pull/4984
sed -i -e 's@http://www.openms.de/doxygen/nightly/html/@http://www.openms.de/doxygen/release/2.8.0/html/@' ./*xml
# # https://github.com/OpenMS/OpenMS/pull/4984#issuecomment-702641976
# patch -p0 < 404-urls.patch

# #-b version log debug test in_type executable pepnovo_executable param_model_directory rt_concat_trafo_out param_id_pool

# for i in A-E F-H I-L M-N O-P Q-Z
# do
# 	planemo t [$i]*xml --galaxy_branch release_20.05 --galaxy_python_version 3.7 --test_output $i.html --test_output_json $i.json &
# done
