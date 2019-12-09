#!/bin/bash

# VERSION=2.3
# CONDAPKG=https://anaconda.org/bioconda/openms/2.3.0/download/linux-64/openms-2.3.0-py27h932d754_3.tar.bz2
VERSION=2.4
CONDAPKG=https://anaconda.org/bioconda/openms/2.4.0/download/linux-64/openms-2.4.0-py27h574aadf_1.tar.bz2
# ini to test
# some of the tests specify parameters in an ini file 
# for the auto generated tests these need to be transformed to galaxy test xml
# - values might contain html entities (e.g. &lt;) which are converted -> therefore values are in CDATA
# TODO this might be better to generate w CTDConverter using something similar to --testtest (just that only the test is generated)
# parameters ini file, test generated so far
function ini2test {
	ini=$1
	tes=$2
	tool_id=$3
	nodecn=0
	path=""
	LOOP=$(egrep "NODE|ITEM|ITEMLIST|LISTITEM" "$ini" | sed 's/^\s*//; s/\s*$//')
     	while read -r ini_line; do
		type=$(echo "$ini_line" | cut -d" " -f1)
# 		>&2 echo "$ini_line"
		#get the name from ITEM and ITEMLIST
		if [[ "$type" =~ \<ITEM|\<ITEMLIST|\<NODE ]]; then
			name=$(echo "$path" | sed 's/[:-]/_/g')$(echo "$ini_line" | sed 's/.*name="\([^\"]\+\)".*/\1/' | sed 's/[:-]/_/g; ')

			adv_re="\\\$adv_opts_cond.param_(out_)?$name"
			if grep -Eq ''$adv_re'[:)"'"'"'"]|'$adv_re'$' "./$tool_id.xml"; then
				adv='adv_opts_cond|'
			else
				adv=''
			fi
		fi
		# skip hard coded params and params that are already in the test
		if [[ "$type" =~ \<ITEM|\</ITEMLIST ]]; then
			if grep -lq '<param name="param_'"$name"'"' <<< "$tes"; then
				continue
			fi
# 			>&2 echo 1 jq -e ".$name | .[]? | .value" hardcoded_params.json 
			if jq -e ".$name | .[]? | .value" hardcoded_params.json > /dev/null; then 
				continue
			fi
		fi
		if [[ "$type" == "<ITEM" ]]; then
			value=$(echo "$ini_line" | sed 's/.*value="\([^"]*\)".*/\1/')
			if [[ "$value" != "" ]]; then
				echo '   <param name="'"$adv"'param_'"$name"'" value="'"$value"'"/>'
#  				echo '    <param name="'"$adv"'param_'"$name"'"><value><![CDATA['"$(echo "$value" | recode html..ascii)"']]></value></param>'
			fi
		elif [[ "$type" == "<ITEMLIST" ]]; then
			value=""
		elif [[ "$type" == "<LISTITEM" ]]; then
			value=$value" "$(echo "$ini_line" | sed 's/.*value="\([^"]*\)".*/\1/')
		elif [[ "$type" == "</ITEMLIST>" ]]; then
			if [[ "$value" != "" ]]; then
				echo '   <param name="'"$adv"'param_'"$name"'" value="'"$( sed 's/^ //' <<<"$value")"'"/>'
# 				echo '    <param name="'"$adv"'param_'"$name"'"><value><![CDATA['"$(echo "$value" | recode html..ascii)"']]></value></param>'
			fi
		elif [[ "$type" == "<NODE" ]]; then
			# at least one ini file (see https://github.com/OpenMS/OpenMS/issues/4386)
			# contained two sets of parameters, since OpenMS seems to ignore the 2nd 
			# we do the same
			if [[ "$name" == "2" ]]; then
				break
			fi

			name=$(echo "$ini_line" | sed 's/.*name="\([^"]\+\)".*/\1/' | sed 's/:/_/')
			let nodecnt=nodecnt+1
			if [[ $nodecnt -gt 2 ]]; then
				path=$path$name:
			fi
		elif [[ "$type" == "</NODE>" ]]; then
			path=$(echo $path | sed 's/[^:]\+:$//')
			let nodecnt=nodecnt-1
		fi
	done <<< "$LOOP"
}

#some tests use the same file twice which does not work in planemo tests
#hence we create symlinks for each file used twice
function unique_files {
	if [[ $# -eq 0 ]]; then
		echo ""
		exit 0
	fi
	if [[ ! -f "test-data/$1" ]]; then
		echo "$@"
		exit 0
	fi

	while read -r line 
	do
		c=$(echo "$line" | cut -d" " -f 1)
		f=$(echo "$line" | cut -d" " -f 2)
		echo -n "$f "
		for i in $(seq 2 "$c")
		do
			if [[ ! -f test-data/$f-$i ]]; then
				ln -fs "$f" "test-data/$f-$i"
			fi
			echo -n "$f-$i"
		done
	done <<< $(echo "$@" | tr ' ' '\n' | uniq -c )
	echo
}


# parse test definitions from OpenMS sources for a tool with a given id
function get_tests {
	id=$1
	>&2 echo "generate $id"
	echo '<xml name="autotest_'"$id"'">'

	# get the tests from the CMakeLists.txt
        # 1st remove some tests
	# - Filefilter with empty select_palarity value (empty is not in the list of allowed options)
	# - MassTraceExtractor with outdated ini file leading to wrong parameters https://github.com/OpenMS/OpenMS/issues/4386
	# - OpenSwathMzMLFileCacher with -convert_back argumen https://github.com/OpenMS/OpenMS/issues/4399t
	# some input files are originally in a subdir (degenerated cases/), but not in test-data
	CMAKE=$(cat OpenMS-git/src/tests/topp/CMakeLists.txt OpenMS-git/src/tests/topp/THIRDPARTY/third_party_tests.cmake  |
		grep -v 'FileFilter.*-spectra:select_polarity ""' |
		grep -v 'MassTraceExtractor_2.ini ' |
		grep -v 'OpenSwathMzMLFileCacher .*-convert_back' | 
		sed 's@degenerate_cases/@@g')
		# 1st part is a dirty hack to join lines containing a single function call, e.g.
	# addtest(....
	#         ....)
	echo "$CMAKE" | sed 's/#.*//; s/^\s*//; s/\s*$//' | grep -v "^#" | grep -v "^$"  | awk '{printf("%s@NEWLINE@", $0)}' | sed 's/)@NEWLINE@/)\n/g' | sed 's/@NEWLINE@/ /g' | 
		grep -E "add_test\(\"(TOPP|UTILS)_$id\_" | egrep -v "_prep|_convert|WRITEINI|WRITECTD|INVALIDVALUE"  | while read line
	do
		ini=""
		line=$(sed 's/add_test("//; s/)$//; s/\${TOPP_BIN_PATH}\///g;s/\${DATA_DIR_TOPP}\///g; s/-test//; s#THIRDPARTY/##g' <<< "$line")
		test_id=$(cut -d" " -f 1 <<< "$line")
		tool_id=$(cut -d" " -f 2 <<< "$line")
		if [[ $test_id =~ _out_?[0-9]? ]]; then
			continue
		fi
		if [[ $id != $tool_id ]]; then
			>&2 echo "skip $test_id ($id != $tool_id) $line"
			continue
		fi

		#remove tests with set_tests_properties(....PROPERTIES WILL_FAIL 1)
		if grep -lq "$test_id"'.* PROPERTIES WILL_FAIL 1' OpenMS-git/src/tests/topp/CMakeLists.txt OpenMS-git/src/tests/topp/THIRDPARTY/third_party_tests.cmake; then
			>&2 echo "skip failing "$test_id
			continue
		fi
		tes="  <test>\n"

		#split parameter value pairs to lines (assuming there is a
		# space befor each parameter and the parameter does not start with a digit)
		LOOP=$(cut -d" " -f3- <<< "$line" | sed "s/^-\([^0-9]\)/\n\1/g; s/ -\([^0-9]\)/\n\1/g" | grep -v "^$")
 		adv_param=''
		while read -r param
		do
			if [[ -z "$param" ]]; then continue; fi
			param_name=$(cut -d" " -f1 <<< "$param" | sed 's/[:-]/_/g')
			param_value=$(cut -d" " -f 2- <<< "$param")
			# skip hardcoded parameters
# 			>&2 echo 2 jq -e ".$param_name | .[]? | .value" hardcoded_params.json 
			if jq -e ".$param_name | .[]? | .value" hardcoded_params.json > /dev/null; then 
				continue
			fi
# 			# check if the parameter is advanced
			adv=''	
			adv_re="\\\$adv_opts_cond.param_(out_)?$param_name"
			if grep -Eq ''$adv_re'[:)"'"'"'"]|'$adv_re'$' ./$tool_id.xml; then
				adv='adv_opts_cond|'
			fi
			# treat flag/boolean parameters (param_name and param_value becomes equal for them)
			# (note the search and replace of : -> _ in the value which we don't want to to in
			# general for the value)
			if [[ "$param_name" == "${param_value//:/_}" ]]; then
				param_value="true" #"-"$param_value
			fi

			# solve problems created by tests using the same file multiple times		
			param_value=$(unique_files $param_value | sed 's/ $//')
			if [[ $param_value =~ .ini$ ]]; then
				ini="test-data/$param_value"
			elif grep -lq '<data name="param_out_'"$param_name"'"' "./$tool_id.xml"
			then
				# for optional outputs: add bool parameter that triggers it
				if grep -lq '<param name="param_'"$param_name"'"' "./$tool_id.xml"
				then
					tes="$tes"'    <param name="'"$adv"'param_'"$param_name"'" value="true"/>\n'
				fi
				param_value=${param_value//\"/}
				#TODO maybe make compare more specific (using file ... | grep text)
				#TODO sim_size should be temporary to detect real tool errors
				tes="$tes"'    <output name="param_out_'"$param_name"'" value="'"$param_value"'" compare="sim_size"/>\n'
			elif grep -lq '<collection .* name="param_out_'"$param_name"'"' "./$tool_id.xml"
			then
				# for optional outputs: add bool parameter that triggers it
				if grep -lq '<param name="param_'"$param_name"'"' "./$tool_id.xml"
				then
					tes="$tes"'    <param name="'"$adv"'param_'"$param_name"'" value="true"/>\n'
				fi
				param_value=${param_value//\"/}
				# since I have no idea on how to determine the element names in a generic way
				# test just for the correct number of outputs
				tes="$tes"'    <output_collection name="param_out_'"$param_name"'" type="list" count="'"$(wc -l <<< ${param_value// /$'\n'})"'"/>\n'
				#tes="$tes"'    <output_collection name="param_out_'$param_name'" type="list">\n'
				#while read -r elem
				#do
				#	tes="$tes"'        <element name="'"$elem"'" file="'"$elem"'" ftype="gff" />\n'
				#done <<< ${param_value// /$'\n'}
				#tes="$tes"'    </output_collection>\n'
			else
				# make input comma separated (A B "C D" -> A,B,"C D")
				# - for selects with multiple true
				if grep -lq '<param name="'"$adv"'param_'"$param_name"'".*multiple="true"' "./$tool_id.xml"; then
					param_value=$(awk 'BEGIN{FPAT = "([^[:space:]]+)|(\"[^\"]+\")"}{for(i=1;i<NF;i++){printf("%s,",$i)} printf("%s", $NF)}' <<<"$param_value")
				fi
				param_value=${param_value//\"/}
				tes="$tes"'    <param name="'"$adv"'param_'"$param_name"'" value="'"$param_value"'"/>\n'
			fi

		done <<< "$LOOP"
		if [[ ! -z "$ini" ]]; then
			tes="$tes"$(ini2test "$ini" "$tes" "$tool_id")
		fi

		# if out_type is required by the tool and the command line does not set 
		# then extract it from the extension of the argument to -out

		if jq -e '.out_type | .[]| .tools | index("'"$tool_id"'")' hardcoded_params.json > /dev/null; then

			if ! grep -lq '\-out_type' <<<"$line"; then
				out_type=$(sed 's/.*-out [^ ]\+\.\([^ \.]\+\).*/\1/' <<<"$line")
				if [ ! -z "$out_type" ]; then
					tes="$tes"'    <param name="param_out_type" value="'"$out_type"'"/>\n'
				fi
			fi	
		fi

		if grep -q "adv_opts_cond" <<< "$tes"; then
			tes="$tes"'\n    <param name="adv_opts_cond|adv_opts_selector" value="advanced"/>'
		fi
		tes="$tes  </test>"

		# output final test, but remove all data parameters linking to default files from Openms/share
		echo -e "$tes" | grep -v 'CHEMISTRY/'
	done 
	echo '</xml>'
}  

# parse data preparation calls from OpenMS sources for a tool with a given id
function prepare_test_data {
	id=$1

	cat OpenMS-git/src/tests/topp/CMakeLists.txt  OpenMS-git/src/tests/topp/THIRDPARTY/third_party_tests.cmake | sed 's/#.*$//'| sed 's/^\s*//; s/\s*$//' | grep -v "^$"  | awk '{printf("%s@NEWLINE@", $0)}' | sed 's/)@NEWLINE@/)\n/g' | sed 's/@NEWLINE@/ /g' | 
		egrep -v "WRITEINI|WRITECTD|INVALIDVALUE|DIFF" | egrep "$id\_.*[0-9]+(_prep|_convert)?" | grep add_test | egrep "TOPP|UTILS" | while read line
	do
		line=$(echo "$line" | sed 's/add_test("//; s/)[^)]*$//; s/\${TOPP_BIN_PATH}\///g;s/\${DATA_DIR_TOPP}\///g; s/-test//; s#THIRDPARTY/##g' | cut -d" " -f2-)
		echo "$line" 
	done 
}
#reset old data
# rm -rf ctd
# mkdir -p ctd
# echo "<macros></macros>" > ./macros_autotest.xml
# echo "" > prepare_test_data.sh

# #get the 
# #- conda package (for easy access and listing of the OpenMS binaries), 
# #- conda environment (for executing the binaries) and 
# #- the git clone of OpenMS
# if [ ! -d OpenMS$VERSION-pkg/ ]; then
# 	mkdir OpenMS$VERSION-pkg/
# 	wget -P OpenMS$VERSION-pkg/ "$CONDAPKG"
# 	tar -xf OpenMS$VERSION-pkg/"$(basename $CONDAPKG)" -C OpenMS$VERSION-pkg/
# fi
# 
# if [ -d OpenMS-git ]; then
# 	cd OpenMS-git || exit
# 	git fetch --all
# 	git checkout release/$VERSION.0
# 	git pull origin release/$VERSION.0
# 	cd - || exit
# else
# 	git clone -b release/$VERSION.0 https://github.com/OpenMS/OpenMS.git OpenMS-git
# fi
# 
# if [ ! -d OpenMS$VERSION-env ]; then
# 	conda create -y --quiet --override-channels --channel iuc --channel conda-forge --channel bioconda --channel defaults -p OpenMS$VERSION-env openms=$VERSION
# fi
# 
# #generate ctd files using the binaries in the conda package 
# conda activate ./OpenMS$VERSION-env
# for i in OpenMS$VERSION-pkg/bin/*
# do
# 	b=$(basename $i)
# 	echo $b
# 	$b -write_ctd ctd/
# 	sed -i -e 's/²/^2/' ctd/$b.ctd
# done
# conda deactivate
# 
# #git clone https://github.com/genericworkflownodes/CTDopts CTDOpts
# #git clone https://github.com/WorkflowConversion/CTDConverter.git CTDConverter
# git clone -b topic/empty_numeric_defaults https://github.com/bernt-matthias/CTDopts CTDOpts
# git clone -b topic/cdata https://github.com/bernt-matthias/CTDConverter.git CTDConverter
# export PYTHONPATH=$(pwd)/CTDOpts
# 
# python2 CTDConverter/convert.py galaxy -i ctd/*ctd -o ./ -s tools_blacklist.txt -f filetypes.txt -m macros.xml -t tool.conf  -p hardcoded_params.txt --test-macros macros_autotest.xml --test-macros-prefix autotest_ --tool-version $VERSION
# #-b version log debug test in_type executable pepnovo_executable param_model_directory rt_concat_trafo_out param_id_pool

# prepare_test_data OpenSwathMzMLFileCacher
# 
# echo "" > prepare_test_data.sh
# echo 'CRUX_BINARY="crux"' >> prepare_test_data.sh
# echo 'FIDOCHOOSEPARAMS_BINARY="FidoChooseParameters"' >> prepare_test_data.sh
# echo 'FIDO_BINARY="Fido"' >> prepare_test_data.sh
# echo 'COMET_BINARY="comet"' >> prepare_test_data.sh
# echo 'MSGFPLUS_BINARY="$(msgf_plus -get_jar_path)"' >> prepare_test_data.sh
# echo 'SIRIUS_BINARY="$(which sirius)"' >> prepare_test_data.sh
# echo 'XTANDEM_BINARY="xtandem"' >> prepare_test_data.sh
# echo 'NOVOR_BINARY="/home/berntm/Downloads/novor/lib/novor.jar"' >> prepare_test_data.sh
# for i in OpenMS$VERSION-pkg/bin/*
# do
# 	b=$(basename "$i")
# 	echo "echo '$b'" >> prepare_test_data.sh
# 	prepare_test_data "$b" >> prepare_test_data.sh
# done
# ##copy test data from OpenMS sources
#rm -rf test-data
#mkdir test-data
##( ( grep "<param" ./macros_autotest.xml | sed 's/.*value="\([^"]\+\)".*/\1/')  &&  (sed 's/ /\n/g' prepare_test_data.sh )) | grep "\." | grep -v "^-" | grep -v "^[:-]\?[0-9]\+\.[0-9]\+" | sort -u | while read line
# sed 's/ /\n/g' prepare_test_data.sh | grep -v "^-" | grep -v "^[:-]\?[0-9]" | grep -v '[",]' | grep -v "'" | sort -u | while read -r line
# do
# 	b=$(basename "$line")
# 	f=$(find OpenMS-git/ -name "$b" | head -n 1)
# 	if [[ ! -z $f ]]; then
# 		cp "$f" test-data/
# 	else
# 		>&2 echo "could not find $b"
# 	fi	
# done

# conda activate ./OpenMS$VERSION-env
# chmod u+x prepare_test_data.sh
# cd ./test-data || exit
# ../prepare_test_data.sh
# cd - || exit
# conda deactivate

# get_tests SimpleSearchEngine
# exit
echo "<macros>" > ./macros_autotest.xml
for i in [A-Z]*xml
do
	b=$(basename "$i" .xml)
	get_tests "$b" >> ./macros_autotest.xml
done
echo "</macros>" >> ./macros_autotest.xml

# planemo t --no_cleanup --galaxy_source https://github.com/bernt-matthias/galaxy.git --galaxy_branch topic/openms-datatypes


# mods for all xml files
# - add aggressive error checks
# - make command and help CDATA
# - remove trailing # chars that are introduced via CTDConverter for hard coded boolean parameters
# - add requirements for tools with -...executable parameter
# - fix in_type (using link with the proper extension)
# for i in ./*xml
# do
# 
# 	id=$(basename "$i" .xml)
# 
# 	#if [[ $id != "PercolatorAdapter" ]]; then
# 	#	continue
# 	#fi
# 	echo postprocessing "$id"
# 
# 	# move references below help and add CDATA to help
# 	sed -i -e '/.*<expand macro="references"/d' "$i"
# 	sed -i -e 's#<help>#<help><![CDATA[#g' "$i"
# 	sed -i -e 's#</help>#]]></help>\n<expand macro="references"/>#g' "$i"
# 
# 	# remove empty comment lines	
# 	sed -i -e 's/#$//' "$i"
# 
# 	# make it possible to extend requirements
# 	sed -i -e 's#<expand macro="requirements"/>#<expand macro="requirements">\n  </expand>#' "$i"
# 
# 	# add R requirement to tools that need it (i.e. have a parameter -rscript_executable / -r_executable)
# 	if grep -lq '\-r.*_executable' "$i"
# 	then
# 		sed -i -e 's#<expand macro="requirements">#&\n    <requirement type="package" version="3.3.1">r-base</requirement>#' "$i"
# 	fi
# 
# 	# add requirements for external programs
# 	if grep -lq "percolator_executable" "$i"
# 	then
# 		sed -i -e 's#<expand macro="requirements">#&\n    <requirement type="package" version="3.2.1">percolator</requirement>#' "$i"
# 	fi
# 	if grep -lq "comet_executable" "$i"
# 	then
# 		sed -i -e 's#<expand macro="requirements">#&\n    <requirement type="package" version="2018014">comet-ms</requirement>#' "$i"
# 	fi
# 	if grep -lq "fido_executable" "$i"
# 	then
# 		sed -i -e 's#<expand macro="requirements">#&\n    <requirement type="package" version="1.0">fido</requirement>#' "$i"
# 	fi
# 	if grep -lq "xtandem_executable" "$i"
# 	then
# 		sed -i -e 's#<expand macro="requirements">#&\n    <requirement type="package" version="15.12.15.2">xtandem</requirement>\n#' "$i"
# 	fi
# 	#TODO requirements for ommsa, myrimatch, luciphor (also -executable)
# 	#TODO requirements for java?
# 
# 	# remove the in_type parameter (which allows the user to set the type of the input 
# 	# manually) from the tools and stick to the default bahaviour to determine it from 
# 	# file extension or content
# 	# TODO maybe use this parameter instead of setting the extension
# 	if grep -lq "in_type" "$i"
# 	then
# 		sed -i -e '/in_type/d' "$i"
# 	fi
# 
# 	# process all data parameters (loops over all names)
# 	# - add a command for linking the data set to the workdir (param_name.extension)
# 	# - adapt the parameter to use the link
# 	for x in $(grep 'type="data"' "$i" | sed 's/.*name="\([^"]\+\)".*/\1/' | uniq)
# 	do
# 		X=$(echo "$x" | sed 's/param_//')
# 		sed -i -e "s@\(<command>\)@\1#if str(\$$x)!=\"None:\"\nln -s \$$x '\${$x.element_identifier}.\${$x.ext}' \&\&\n#end if\n@" "$i"
# 		sed -i -e "s#^-$X .*#-$X '\${$x.element_identifier}.\${$x.ext}'\n#" "$i"
# 
# 	done
# 
# #	# TODO???
# # 	if grep -lq "out_type" "$i"
# # 	then
# # 		sed -i -e 's#<data name="param_out" .*"/>#<data name="param_out" metadata_source="param_in" auto_format="true"/>#' "$i"
# # 	fi
# 
# 	# TODO remove empty advanced options section
# 
# 	# add tests and scripts to create test data
# 	sed -i -e "s#\(</outputs>\)#\1\n  <tests>\n    <expand macro=\"tests_$id\"/>\n  </tests>#" "$i"
# 	sed -i -e "s#\(</macros>\)#    <import>macros_test.xml</import>\n  \1#" "$i"
# 	get_tests "$id" >> ./macros_test.xml
# 	prepare_test_data "$id" >> prepare_test_data.sh
# 
# 	# add CDATA to command and add aggressive error checks 
# 	sed -i -e 's#<command>#<command detect_errors="aggressive"><![CDATA[\n#g' "$i"
# 	sed -i -e 's#</command>#]]></command>#g' "$i"
# done
# 
# ## tool specific changes 
# # AccurateMassSearch db_mapping|db_struct|positive_adducts|negative_adducts are documented as mandatory, but they are optional 
# for i in db_mapping db_struct positive_adducts negative_adducts
# do
# 	sed -i -e 's/\(<param name="param_'$i'".*\)optional="False"/\1optional="True"/' ./AccurateMassSearch.xml
#         sed -i -e 's/\(<param name="param_'$i'".*\)value="[^"]\+"/\1/' ./AccurateMassSearch.xml
# done
# 
# # TODO the following tools need output data sets (in tests, but probably also in outputs as well)
# # PrecursorIonSelector
# # RTPredict
# 
# cp ../macros.xml ./
# 
