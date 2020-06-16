#!/usr/bin/env bash

# parse test definitions from OpenMS sources for a tool with a given id
function get_tests2 {
	id=$1
	>&2 echo "generate tests for $id"
	echo '<xml name="autotest_'"$id"'">'

	# get the tests from the CMakeLists.txt
	# 1st remove some tests
	# - Filefilter with empty select_palarity value (empty is not in the list of allowed options)
	# - MassTraceExtractor with outdated ini file leading to wrong parameters https://github.com/OpenMS/OpenMS/issues/4386
	# - OpenSwathMzMLFileCacher with -convert_back argumen https://github.com/OpenMS/OpenMS/issues/4399
    # - IDRipper PATH gets empty causing problems. TODO But overall the option needs to be handled differentlt
	# - several tools with duplicated input (leads to conflict when linking)
	# - TOFCalibration inputs we extension (also in prepare_test_data) https://github.com/OpenMS/OpenMS/pull/4525
	# - MaRaCluster with -consensus_out (parameter blacklister: https://github.com/OpenMS/OpenMS/issues/4456)
	# - FileMerger with mixed dta dta2d input (ftype can not be specified in the test, dta can not be sniffed)
	# some input files are originally in a subdir (degenerated cases/), but not in test-data
	CMAKE=$(cat $OPENMSGIT/src/tests/topp/CMakeLists.txt $OPENMSGIT/src/tests/topp/THIRDPARTY/third_party_tests.cmake  |
		sed 's@${DATA_DIR_SHARE}/@@g' |
		grep -v 'OpenSwathMzMLFileCacher .*-convert_back' |
	    sed 's/${TMP_RIP_PATH}/""/' |
		sed 's@TOFCalibration_ref_masses @TOFCalibration_ref_masses.txt @g; s@TOFCalibration_const @TOFCalibration_const.csv @' |
		grep -v "MaRaClusterAdapter.*-consensus_out"|
 		grep -v "FileMerger_1_input1.dta2d.*FileMerger_1_input2.dta " |
		sed 's@degenerate_cases/@@g')


# 		grep -v 'FileFilter.*-spectra:select_polarity ""' |
# 		grep -v 'MassTraceExtractor_2.ini ' |
# 		grep -v "FileMerger_6_input2.mzML.*FileMerger_6_input2.mzML" |
# 		grep -v "IDMerger_1_input1.idXML.*IDMerger_1_input1.idXML" |
# 		grep -v "degenerated_empty.idXML.*degenerated_empty.idXML" |
# 		grep -v "FeatureLinkerUnlabeledKD_1_output.consensusXML.*FeatureLinkerUnlabeledKD_1_output.consensusXML" |
# 		grep -v "FeatureLinkerUnlabeledQT_1_output.consensusXML.*FeatureLinkerUnlabeledQT_1_output.consensusXML" |

	# 1st part is a dirty hack to join lines containing a single function call, e.g.
	# addtest(....
	#         ....)
	echo "$CMAKE" | sed 's/#.*//; s/^\s*//; s/\s*$//' | grep -v "^#" | grep -v "^$"  | awk '{printf("%s@NEWLINE@", $0)}' | sed 's/)@NEWLINE@/)\n/g' | sed 's/@NEWLINE@/ /g' | 
		grep -iE "add_test\(\"(TOPP|UTILS)_.*/$id " | egrep -v "_prepare\"|_convert|WRITEINI|WRITECTD|INVALIDVALUE"  | while read -r line
	do
		line=$(echo "$line" | sed 's/add_test("\([^"]\+\)"/\1/; s/)$//; s/\${TOPP_BIN_PATH}\///g;s/\${DATA_DIR_TOPP}\///g; s#THIRDPARTY/##g')
		>&2 echo $line
		test_id=$(echo "$line" | cut -d" " -f 1)
		tool_id=$(echo "$line" | cut -d" " -f 2)
		if [[ $test_id =~ _out_?[0-9]? ]]; then
			>&2 echo "    skip $test_id $line"
			continue
		fi
		if [[ ${id,,} != ${tool_id,,} ]]; then
			>&2 echo "    skip $test_id ($id != $tool_id) $line"
			continue
		fi

		#remove tests with set_tests_properties(....PROPERTIES WILL_FAIL 1)
		if grep -lq "$test_id"'\".* PROPERTIES WILL_FAIL 1' $OPENMSGIT/src/tests/topp/CMakeLists.txt $OPENMSGIT/src/tests/topp/THIRDPARTY/third_party_tests.cmake; then
			>&2 echo "    skip failing "$test_id
			continue
		fi
		tes="  <test>\n"

		line=$(fix_tmp_files "$line")
		line=$(unique_files "$line")
		#if there is an ini file then we use this to generate the test
		#otherwise the ctd file is used
		#other command line parameters are inserted later into this xml
		if grep -lq "\-ini" <<<"$line"; then
			ini=$(echo $line | sed 's/.*-ini \([^ ]\+\).*/\1/')
			ini="test-data/$ini"
		else
			ini="ctd/$tool_id.ctd"
		fi
		cli=$(echo $line |cut -d" " -f3- | sed 's/-ini [^ ]\+//')
		
		ctdtmp=$(mktemp)
		#echo python3 fill_ctd_clargs.py --ctd $ini $cli
		# using eval: otherwise for some reason quoted values are not used properly ('A B' -> ["'A", "B'"])
		>&2 echo "python3 fill_ctd_clargs.py --ctd $ini $cli"
		eval "python3 fill_ctd_clargs.py --ctd $ini $cli" > "$ctdtmp"
		# echo $ctdtmp
 		# >&2 cat $ctdtmp
  		testtmp=$(mktemp)
 		python3 $CTDCONVERTER/convert.py galaxy -i $ctdtmp -o $testtmp -s tools_blacklist.txt -f "$FILETYPES" -m macros.xml -t tool.conf  -p hardcoded_params.json --tool-version $VERSION --test-only --test-unsniffable csv tsv txt dta dta2d edta mrm splib > /dev/null
	   	cat $testtmp | grep -v '<output.*file=""' # | grep -v 'CHEMISTRY/'
		rm $ctdtmp $testtmp

		#> /dev/null

# 		XMLED="xmlstarlet ed -O "
# 		# >&2 echo $line
# 		#split parameter value pairs to lines (assuming there is a
# 		# space befor each parameter and the parameter does not start with a digit)
# 		LOOP=$(echo $line | cut -d" " -f3- | sed 's/^-\([^0-9]\)/\n\1/g; s/ -\([^0-9]\)/\n\1/g; s/"//g' | grep -v "^$")
# 		while read -r param
# 		do
# 			if [[ -z "$param" ]]; then continue; fi
# 			param_name=$(cut -d" " -f1 <<< "$param")
# 			param_value=$(cut -d" " -f 2- <<< "$param")
# 			if [[ $param_value =~ .ini$ ]]; then
# 				continue
# 			fi
# 			# treat flag/boolean parameters (param_name and param_value becomes equal for them)
# 			# (note the search and replace of : -> _ in the value which we don't want to to in
# 			# general for the value)
# 			if [[ "$param_name" == "$param_value" ]]; then
# 				param_value="true"
# 			fi
# 
# 			if grep -lq '<data name="'"$param_name"'"' "./$tool_id.xml"; then
# 				attr="file"
# 			else
# 				attr="value"
# 			fi
# 
# 			# multiple data inputs need to be space separated
# 			if grep -lq '<param name="'"$param_name"'".*type="data".*multiple="true"' "./$tool_id.xml"; then
# 				param_value=${param_value// /,}
# 			fi
# 
# 			xpath=$(echo "-$param_name" | sed 's!\([:-]\)\([^:-]\+$\)!/*[@name="\2"]/@'$attr'!' | sed 's![:-]\([^:/-]\+\)!/section[@name="\1"]!g')	
# # 			>&2 echo $param_name $xpath
# 			XMLED="$XMLED -u '/test/$xpath' -v '$param_value'"
# 		
# 			# set the FLAG generating for optional outputs that are specified on the CLI
# 			if grep -lq '<param.*name="'"$param_name"'_FLAG"' "./$tool_id.xml"; then
# 				xpath=$(echo "-$param_name" | sed 's!\([:-]\)\([^:-]\+$\)!/*[@name="\2_FLAG"]/@value!' | sed 's![:-]\([^:/-]\+\)!/section[@name="\1"]!g')	
# 				XMLED="$XMLED -u '/test/$xpath' -v 'true'"
# 			fi
# 
# 			# if there is a _type parameter in the xml but not in the ctd (i.e. not in the test)
# 			# then add it to the test and set the value according to the file extension
# 			if grep -lq '<param name="'"$param_name"'_type".*"' "./$tool_id.xml"; then
# 				out_type=$(echo $param_value | cut -d" " -f1 | sed 's/[^ ]\+\.\('"$FILETYPES_RE"'\)\(\.tmp\)\?/\1/')
# 				if ! grep -lq '<param name="'"$param_name"'_type"' "$testtmp"; then
# 					xpath=$(echo "-$param_name" | sed 's!\(.*\)[:-][^:-]\+!\1!' | sed 's![:-]!/!g')	
#  					XMLED="$XMLED -s '/test$xpath' -t elem -n paramTMP"
#  					XMLED="$XMLED -i '/test$xpath/paramTMP' -t attr -n name -v '"$param_name"_type'"
#  					XMLED="$XMLED -i '/test$xpath/paramTMP' -t attr -n value -v '$out_type'"
#  					XMLED="$XMLED -r '/test$xpath/paramTMP' -v param"
# 				fi
# 			fi
# # 			# fix data types to Galaxy names
# # 			if [[ "$param_name" == "out_type" ]]; then
# # 				param_value=$(fix_out_type "$param_value" "$FILETYPES")
# # 			fi
# 			# solve problems created by tests using the same file multiple times		
# # 			param_value=$(unique_files $param_value | sed 's/ $//')
# # 			if [[ $param_value =~ .ini$ ]]; then
# # 				ini="test-data/$param_value"
# # 			else
# # 				tes="$tes"$(output_param_xml "$param_name" "$param_value" "$tool_id")
# # 			fi
# 		done <<< "$LOOP"
# 
# 
# 		# edit test xml
# 		# - remove empty outputs
# 	    # - remove all data parameters linking to default files from Openms/share
# 		tmp=$(mktemp)
# 		eval $XMLED $testtmp | grep -v '<output.*file=""' | grep -v 'CHEMISTRY/' > $tmp
# 		>&2 echo $XMLED
# 		mv $tmp $testtmp
# 
# 		# remove empty valued data inputs
# 		grep 'value=""' $testtmp | while read -r line
# 		do
# 				name=$(echo $line | sed 's/.*name="\([^"]\+\)".*/\1/')
# 				if grep -lq '<param.*name="'"$name"'".*type="data".*optional="true"' "./$tool_id.xml"; then
# 					grep -v '<param name="'$name'"' $testtmp > $tmp && mv $tmp $testtmp
# 				fi
# 
# 		done
# 
# 		#TODO set hardcoded values
# # # 	>&2 echo 1 jq -e ".$name | .[]? | .value" hardcoded_params.json 
# # 	#if jq -e ".$name | .[]? | .value" hardcoded_params.json > /dev/null; then
# # 	if jq -e '.'"$name"' | .[]? | select((has("value")) and ((has("tools")|not) or (.tools == []) or (.tools|contains(["'"$tool_id"'"]))) )' > /dev/null hardcoded_params.json; then
# # 		#>&2 echo SKIP $name $value
# # 		return 0
# # 	fi
# # 			# TODO for optional outputs: add bool parameter that triggers it
# # 			if grep -lq '<data.*name="'"$param_name"'".*optional="true"' "./$tool_id.xml"; then
# # 			fi
# 		
# 		
# 		# 		if [[ ! -z "$ini" ]]; then
# # 			tes="$tes"$(ini2test "$ini" "$tes" "$tool_id")
# # 		fi
# 
# # 		# if out_type select is contained in the tool and the command line does not set 
# # 		# then extract it from the extension of the argument to -out
# # 
# # 		while read -r otline; do
# # 			nm=$(sed 's/.*<param name="\([^"]\+\)_type".*/\1/' <<< "$otline")
# # #			>&2 echo $nm
# # 			if ! grep -lq "$nm"'_type' <<<"$tes"; then
# # #				>&2 echo $line
# # 				out_type=$(sed 's/.*-'"$nm"' [^ ]\+\.\('"$FILETYPES_RE"'\)\(\.tmp\)\?\( .*\|$\)/\1/' <<<"$line")
# # #				>&2 echo $out_type
# # 				out_type=$(grep "^$out_type\s" "$FILETYPES" | awk '{print $2}')
# # #				>&2 echo $out_type
# # 				param_line=$(nl "./$tool_id.xml" | grep '<param.*'"$nm"'_type' | cut -f 1)
# # 				adv_line=$(nl "./$tool_id.xml" | grep '<expand macro="adv_opts_macro">' | cut -f 1)
# # 				adv=""
# # 				if [[ $adv_line -lt $param_line ]]; then
# # 					adv="adv_opts_cond|"
# # 				fi
# # 
# # 				if [ ! -z "$out_type" ]; then
# # 					tes="$tes"'    <param name="'"$adv$nm"'_type" value="'"$out_type"'"/>\n'
# # 				fi
# # 			fi	
# # 		done <<< $(grep -E '<param name="out(_[^ "]+)?_type".*optional="false"' "./$tool_id.xml";)
# 
# # 		if grep -q "adv_opts_cond" <<< "$tes"; then
# # 			tes="$tes"'    <param name="adv_opts_cond|adv_opts_selector" value="advanced"/>\n'
# # 		fi
# # 		tes="$tes  </test>"
		#rm $testtmp
	done 
	echo '</xml>'
}

# # parse test definitions from OpenMS sources for a tool with a given id
# function get_tests {
# 	id=$1
# 	>&2 echo "generate tests for $id"
# 	echo '<xml name="autotest_'"$id"'">'
# 
# 	# get the tests from the CMakeLists.txt
#         # 1st remove some tests
# 	# - Filefilter with empty select_palarity value (empty is not in the list of allowed options)
# 	# - MassTraceExtractor with outdated ini file leading to wrong parameters https://github.com/OpenMS/OpenMS/issues/4386
# 	# - OpenSwathMzMLFileCacher with -convert_back argumen https://github.com/OpenMS/OpenMS/issues/4399t
# 	# some input files are originally in a subdir (degenerated cases/), but not in test-data
# 	CMAKE=$(cat OpenMS$VERSION.0-git/src/tests/topp/CMakeLists.txt OpenMS$VERSION.0-git/src/tests/topp/THIRDPARTY/third_party_tests.cmake  |
# 		grep -v 'FileFilter.*-spectra:select_polarity ""' |
# 		grep -v 'MassTraceExtractor_2.ini ' |
# 		grep -v 'OpenSwathMzMLFileCacher .*-convert_back' | 
# 		sed 's@degenerate_cases/@@g')
# 		# 1st part is a dirty hack to join lines containing a single function call, e.g.
# 	# addtest(....
# 	#         ....)
# 	echo "$CMAKE" | sed 's/#.*//; s/^\s*//; s/\s*$//' | grep -v "^#" | grep -v "^$"  | awk '{printf("%s@NEWLINE@", $0)}' | sed 's/)@NEWLINE@/)\n/g' | sed 's/@NEWLINE@/ /g' | 
# 		grep -iE "add_test\(\"(TOPP|UTILS)_.*/$id " | egrep -v "_prepare\"|_convert|WRITEINI|WRITECTD|INVALIDVALUE"  | while read -r line
# 	do
# 		ini=""
# 		line=$(sed 's/add_test("//; s/)$//; s/\${TOPP_BIN_PATH}\///g;s/\${DATA_DIR_TOPP}\///g; s#THIRDPARTY/##g' <<< "$line")
# 		test_id=$(cut -d" " -f 1 <<< "$line")
# 		tool_id=$(cut -d" " -f 2 <<< "$line")
# 		if [[ $test_id =~ _out_?[0-9]? ]]; then
# 			>&2 echo "    skip $test_id $line"
# 			continue
# 		fi
# 		if [[ ${id,,} != ${tool_id,,} ]]; then
# 			>&2 echo "    skip $test_id ($id != $tool_id) $line"
# 			continue
# 		fi
# 
# 		#remove tests with set_tests_properties(....PROPERTIES WILL_FAIL 1)
# 		if grep -lq "$test_id"'.* PROPERTIES WILL_FAIL 1' OpenMS$VERSION.0-git/src/tests/topp/CMakeLists.txt OpenMS$VERSION.0-git/src/tests/topp/THIRDPARTY/third_party_tests.cmake; then
# 			>&2 echo "    skip failing "$test_id
# 			continue
# 		fi
# 		tes="  <test>\n"
# 
# 		line=$(fix_tmp_files "$line")
# 		# >&2 echo $line
# 		#split parameter value pairs to lines (assuming there is a
# 		# space befor each parameter and the parameter does not start with a digit)
# 		LOOP=$(echo $line | cut -d" " -f3- | sed "s/^-\([^0-9]\)/\n\1/g; s/ -\([^0-9]\)/\n\1/g" | grep -v "^$")
# 		while read -r param
# 		do
# 			if [[ -z "$param" ]]; then continue; fi
# 			param_name=$(cut -d" " -f1 <<< "$param" | sed 's/[:-]/_/g')
# 			param_value=$(cut -d" " -f 2- <<< "$param")
# 
# 			# treat flag/boolean parameters (param_name and param_value becomes equal for them)
# 			# (note the search and replace of : -> _ in the value which we don't want to to in
# 			# general for the value)
# 			if [[ "$param_name" == "${param_value//:/_}" ]]; then
# 				param_value="-"$param_value # "true"
# 			fi
# 
# # 			# fix data types to Galaxy names
# # 			if [[ "$param_name" == "out_type" ]]; then
# # 				param_value=$(fix_out_type "$param_value" "$FILETYPES")
# # 			fi
# 			# solve problems created by tests using the same file multiple times		
# 			param_value=$(unique_files $param_value | sed 's/ $//')
# 			if [[ $param_value =~ .ini$ ]]; then
# 				ini="test-data/$param_value"
# 			else
# 				tes="$tes"$(output_param_xml "$param_name" "$param_value" "$tool_id")
# 			fi
# 		done <<< "$LOOP"
# 		if [[ ! -z "$ini" ]]; then
# 			tes="$tes"$(ini2test "$ini" "$tes" "$tool_id")
# 		fi
# 
# 		# if out_type select is contained in the tool and the command line does not set 
# 		# then extract it from the extension of the argument to -out
# 
# 		while read -r otline; do
# 			nm=$(sed 's/.*<param name="\([^"]\+\)_type".*/\1/' <<< "$otline")
# #			>&2 echo $nm
# 			if ! grep -lq "$nm"'_type' <<<"$tes"; then
# #				>&2 echo $line
# 				out_type=$(sed 's/.*-'"$nm"' [^ ]\+\.\('"$FILETYPES_RE"'\)\(\.tmp\)\?\( .*\|$\)/\1/' <<<"$line")
# #				>&2 echo $out_type
# 				out_type=$(grep "^$out_type\s" "$FILETYPES" | awk '{print $2}')
# #				>&2 echo $out_type
# 				param_line=$(nl "./$tool_id.xml" | grep '<param.*'"$nm"'_type' | cut -f 1)
# 				adv_line=$(nl "./$tool_id.xml" | grep '<expand macro="adv_opts_macro">' | cut -f 1)
# 				adv=""
# 				if [[ $adv_line -lt $param_line ]]; then
# 					adv="adv_opts_cond|"
# 				fi
# 
# 				if [ ! -z "$out_type" ]; then
# 					tes="$tes"'    <param name="'"$adv$nm"'_type" value="'"$out_type"'"/>\n'
# 				fi
# 			fi	
# 		done <<< $(grep -E '<param name="out(_[^ "]+)?_type".*optional="false"' "./$tool_id.xml";)
# 
# 		if grep -q "adv_opts_cond" <<< "$tes"; then
# 			tes="$tes"'    <param name="adv_opts_cond|adv_opts_selector" value="advanced"/>\n'
# 		fi
# 		tes="$tes  </test>"
# 
# 		# output final test, but remove all data parameters linking to default files from Openms/share
# 		echo -e "$tes" | grep -v 'CHEMISTRY/'
# 	done 
# 	echo '</xml>'
# }

# function output_param_xml {
# 	name="$1"
# 	value="$2"
# 	tool_id="$3"
# 
# #  	>&2 echo output_param_xml $name $adv $value $tool_id
# 
# # 	if [[ "$value" == "" ]]; then
# # 		return 0
# # 	fi
# # 	>&2 echo 1 jq -e ".$name | .[]? | .value" hardcoded_params.json 
# 	#if jq -e ".$name | .[]? | .value" hardcoded_params.json > /dev/null; then
# 	if jq -e '.'"$name"' | .[]? | select((has("value")) and ((has("tools")|not) or (.tools == []) or (.tools|contains(["'"$tool_id"'"]))) )' > /dev/null hardcoded_params.json; then
# 		#>&2 echo SKIP $name $value
# 		return 0
# 	fi
# 
# 	# check if the parameter is advanced
# 	adv=''	
# 	adv_re="\\\$adv_opts_cond.(out_)?$name"
# 	if grep -Eq ''$adv_re'[:)"'"'"'"]|'$adv_re'$' "./$tool_id.xml"; then
# 		adv='adv_opts_cond|'
# 	fi
# 
# 	if grep -lq '<data name="out_'"$name"'"' "./$tool_id.xml"; then
# 		if [[ "$value" == "" ]]; then
# 			return 0
# 		fi
# 		# for optional outputs: add bool parameter that triggers it
# 		if grep -lq '<param.*name="'"$name"'"' "./$tool_id.xml"; then
# 			echo '    <param name="'"$adv$name"'" value="true"/>'
# 		fi
# 		value=${value//\"/}
# 		# multiple outputs are space separated -> comma separate them
# 		value=${value// /,}
# 		#TODO maybe make compare more specific (using file ... | grep text)
# 		#TODO sim_size should be temporary to detect real tool errors
# 		echo '    <output name="out_'"$name"'" value="'"$value"'" compare="sim_size" delta="100"/>\n'
# 	elif grep -lq '<collection.*name="out_'"$name"'"' "./$tool_id.xml"; then
# 		if [[ "$value" == "" ]]; then
# 			return 0
# 		fi
# 		# for optional outputs: add bool parameter that triggers it
# 		 
# 		if grep -lq '<param.*name="'"$name"'"' "./$tool_id.xml"; then
# 			echo '    <param name="'"$adv$name"'" value="true"/>\n'
# 		fi
# 		value=${value//\"/}
# 		# since I have no idea on how to determine the element names in a generic way
# 		# test just for the correct number of outputs
# 		echo '    <output_collection name="out_'"$name"'" type="list" count="'"$(echo $value | wc -w)"'"/>\n'
# 		#tes="$tes"'    <output_collection name="out_'$name'" type="list">\n'
# 		#while read -r elem
# 		#do
# 		#	tes="$tes"'        <element name="'"$elem"'" file="'"$elem"'" ftype="gff" />\n'
# 		#done <<< ${value// /$'\n'}
# 		#tes="$tes"'    </output_collection>\n'
# 	else
# # TODO not in ini2test: commas are added automatically to selects 
# # 		# make input comma separated (A B "C D" -> A,B,"C D")
# # 		# - for selects with multiple true
# # 		if grep -lq '<param name="'"$adv$name"'".*multiple="true"' "./$tool_id.xml"; then
# # 			value=$(awk 'BEGIN{FPAT = "([^[:space:]]+)|(\"[^\"]+\")"}{for(i=1;i<NF;i++){printf("%s,",$i)} printf("%s", $NF)}' <<<"$value")
# # 		fi
# 		# mandatory selects/data should not be outputed if the value is '' otherwise the test assumes that the option '' (empty string) has been selected which is not what we want and usually not even an option
# 		if grep -Eq '<param name="'"$adv$name"'".*type="data".*optional="true"' "./$tool_id.xml"; then
# 			if [[ "$value" == "" ]]; then
# 				return 0
# 			fi
# 		fi
# 		if grep -Eq '<param name="'"$adv$name"'".*type="select".*optional="true"' "./$tool_id.xml"; then
# 			if [[ "$value" == "" ]]; then
# 				return 0
# 			fi
# 		fi
# 		# - multiple input files are comma separated
# 		# - for unsniffable file extensions we just set the input data type
# 		#   (take it from the test input file or the parameter in the xml file)
# 		if grep -lq '<param name="'"$adv$name"'".*type="data"' "./$tool_id.xml"; then
# 			value=${value// /,}
# 			ext=$(sed -e 's/.*\(tsv\|csv\|txt\|dta2d\|edta\|mrm\)\(\.tmp\)\?$/\1/' <<< "$value")
# 			if [[ "$ext" == "$value" ]]; then
# 
# 				# if the extension cant be extracted from the file name
# 				# try to get it from the xml
# 				param=$(grep '<param name="'"$adv$name"'".*type="data"' "./$tool_id.xml")
# 				ext=$(sed 's/.*format="\(tsv\|csv\|txt\|dta2d\|edta\|mrm\)".*/\1/' <<< $param)
# 				if [[ "$param" == "$ext" ]]; then
# 					tpe=""
# 				else
# 					tpe='ftype="'$(grep "^$ext\s" "$FILETYPES" | awk '{print $2}')'"'
# 				fi
# 			else
# 				tpe='ftype="'$(grep "^$ext\s" "$FILETYPES" | awk '{print $2}')'"'
# 			fi
# 		fi
# 		value=${value//\"/}
# 		echo '    <param name="'"$adv$name"'" value="'"$value"'" '"$tpe"'/>\n'
# 	fi
# # # 	# fix data types to Galaxy names
# # # 	if [[ "$name" == "out_type" ]]; then
# # # 		value=$(fix_out_type "$value" "$FILETYPES")
# # # 	fi
# # 	if [[ "$value" != "" ]]; then
# # 		echo '   <param name="'"$adv$name"'" value="'"$value"'"/>'
# # #  		echo '    <param name="'"$adv$name"'"><value><![CDATA['"$(echo "$value" | recode html..ascii)"']]></value></param>'
# # 	fi
# }


# # ini to test
# # some of the tests specify parameters in an ini file 
# # for the auto generated tests these need to be transformed to galaxy test xml
# # - values might contain html entities (e.g. &lt;) which are converted -> therefore values are in CDATA
# # TODO this might be better to generate w CTDConverter using something similar to --testtest (just that only the test is generated)
# # parameters ini file, test generated so far
# function ini2test {
# 	ini=$1
# 	tes=$2
# 	tool_id=$3
# 	nodecn=0
# 	path=""
# 	LOOP=$(egrep "NODE|ITEM|ITEMLIST|LISTITEM" "$ini" | sed 's/^\s*//; s/\s*$//')
#      	while read -r ini_line; do
# 		type=$(echo "$ini_line" | cut -d" " -f1)
# #  		>&2 echo "$ini_line"
# 		#get the name from ITEM and ITEMLIST
# 		if [[ "$type" =~ \<ITEM|\<ITEMLIST|\<NODE ]]; then
# 			name=$(echo "$path" | sed 's/[:-]/_/g')$(echo "$ini_line" | sed 's/.*name="\([^\"]\+\)".*/\1/' | sed 's/[:-]/_/g; ')
# 		fi
# 		# skip params that are already in the test
# 		if [[ "$type" =~ \<ITEM|\</ITEMLIST ]]; then
# 			if grep -Eq '<.* name="(adv_opts_cond\|)?(out_)?'"$name"'"' <<< "$tes"; then
# 				continue
# 			fi
# 		fi
# 		if [[ "$type" == "<ITEM" ]]; then
# 			value=$(echo "$ini_line" | sed 's/.*value="\([^"]*\)".*/\1/')
# 			echo -n "$(output_param_xml "$name" "$value" "$tool_id")"
# 		elif [[ "$type" == "<ITEMLIST" ]]; then
# 			value=""
# 			if grep -lq '<param name="'"$adv$name"'".*multiple="true"' "./$tool_id.xml"; then
# 				sep=","
# 			else
# 				sep=" "
# 			fi
# 		elif [[ "$type" == "<LISTITEM" ]]; then
# 			if [[ "$value" == "" ]]; then
# 				# just append listitems to the final value (which is used when </ITEMLIST>)
# 				value="$(echo "$ini_line" | sed 's/.*value="\([^"]*\)".*/\1/')"
# 			else
# 				value="$value$sep$(echo "$ini_line" | sed 's/.*value="\([^"]*\)".*/\1/')"
# 			fi
# 		elif [[ "$type" == "</ITEMLIST>" ]]; then
# # 			# do not output anything for itemlist without listitems
# # 			if [[ "$value" == "" ]]; then
# # 				continue
# # 			fi
# 			echo -n "$(output_param_xml "$name" "$value" "$tool_id")"
# 		elif [[ "$type" == "<NODE" ]]; then
# 			# at least one ini file (see https://github.com/OpenMS/OpenMS/issues/4386)
# 			# contained two sets of parameters, since OpenMS seems to ignore the 2nd 
# 			# we do the same
# 			if [[ "$name" == "2" ]]; then
# 				break
# 			fi
# 
# 			name=$(echo "$ini_line" | sed 's/.*name="\([^"]\+\)".*/\1/' | sed 's/:/_/')
# 			let nodecnt=nodecnt+1
# 			if [[ $nodecnt -gt 2 ]]; then
# 				path=$path$name:
# 			fi
# 		elif [[ "$type" == "</NODE>" ]]; then
# 			path=$(echo $path | sed 's/[^:]\+:$//')
# 			let nodecnt=nodecnt-1
# 		fi
# 	done <<< "$LOOP"
# }

#some tests use the same file twice which does not work in planemo tests
#hence we create symlinks for each file used twice
function unique_files {
	line=$@
	for arg in $@
	do
		if [[ ! -f "test-data/$arg" ]]; then
			continue
		fi
		cnt=$(grep -c $arg <<< $(echo "$line" | tr ' ' '\n'))
		while [[ $cnt -gt 1 ]]; do
            new_arg=$(echo $arg | sed "s/\(.*\)\./\1_$cnt./")
			ln -fs $arg test-data/$new_arg
			line=$(echo $line | sed "s/\($arg.*\)$arg/\1$new_arg/")
			cnt=$(grep -c $arg <<< $(echo "$line" | tr ' ' '\n'))
		done
	done

	echo $line
}

# options of out_type selects need to be fixed to Galaxy data types
function fix_out_type {
	grep "^$1" "$2" | awk '{print $2}'
}

#OpenMS tests output to tmp files and compare with FuzzyDiff to the expected file.
#problem: the extension of the tmp files is unusable for test generation.
#unfortunately the extensions used in the DIFF lines are not always usable for the CLI
#(e.g. for prepare_test_data, e.g. CLI expects csv but test file is txt)
#this function replaces the tmp file by the expected file. 
function fix_tmp_files {
#	>&2 echo "FIX $line"
	ret=""
	for a in $@; do
		if [[ ! $a =~ .tmp$ ]]; then
			ret="$ret $a"
			continue
		fi
#		>&2 echo "    a "$a
		g=$(cat $OPENMSGIT/src/tests/topp/CMakeLists.txt $OPENMSGIT/src/tests/topp/THIRDPARTY/third_party_tests.cmake | awk '{printf("%s@NEWLINE@", $0)}' | sed 's/)@NEWLINE@/)\n/g' | sed 's/@NEWLINE@/ /g' | grep '\${DIFF}.*'"$a")
#		>&2 echo "    g "$g
		in1=$(sed 's/.*-in1 \([^ ]\+\).*/\1/' <<<$g)
#		>&2 echo "    in1 "$in1
		if [[  "$a" != "$in1" ]]; then
			ret="$ret $a"
			continue
		fi
		in2=$(sed 's/.*-in2 \([^ ]\+\).*/\1/' <<<$g)
		in2=$(basename $in2 | sed 's/)$//')
#		>&2 echo "    in2 "$in2
		if [[ -f "test-data/$in2" ]]; then
			ln -fs "$in1" "test-data/$in2"
			ret="$ret $in2"
		else
			ret="$ret $a"
		fi
	done
#	>&2 echo "--> $ret"
	echo "$ret"
}

function link_tmp_files {
     # note this also considers commented lines (starting with a #)
	 # because of tests where the diff command is commented and we
	 # still want to use the extension of these files
	 cat $OPENMSGIT/src/tests/topp/CMakeLists.txt $OPENMSGIT/src/tests/topp/THIRDPARTY/third_party_tests.cmake | sed 's/^\s*//; s/\s*$//' | grep -v "^$"  | awk '{printf("%s@NEWLINE@", $0)}' | sed 's/)@NEWLINE@/)\n/g' | sed 's/@NEWLINE@/ /g' | grep "\${DIFF}" | while read -r line
	do
		in1=$(sed 's/.*-in1 \([^ ]\+\).*/\1/' <<<$line)
 		in1=$(basename $in1 | sed 's/)$//')
		in2=$(sed 's/.*-in2 \([^ ]\+\).*/\1/' <<<$line)
 		in2=$(basename $in2 | sed 's/)$//')
		if [[ "$in1" == "$in2" ]]; then
			>&2 echo "not linking equal $in1 $in2"
			continue
		fi
		ln -f -s $in1 test-data/$in2
    done
    for i in test-data/*.tmp
	do
		if [ ! -e test-data/$(basename $i .tmp) ]; then
				ln -s $(basename $i) test-data/$(basename $i .tmp)
				#ln -s $(basename $i) test-data/$(basename $i .tmp)
		else
				ln -fs $(basename $i) test-data/$(basename $i .tmp)
		fi
	done
}



# parse data preparation calls from OpenMS sources for a tool with a given id
function prepare_test_data {
# 	id=$1
# | egrep -i "$id\_.*[0-9]+(_prepare\"|_convert)?"
	cat $OPENMSGIT/src/tests/topp/CMakeLists.txt  $OPENMSGIT/src/tests/topp/THIRDPARTY/third_party_tests.cmake | sed 's/#.*$//'| sed 's/^\s*//; s/\s*$//' | grep -v "^$"  | awk '{printf("%s@NEWLINE@", $0)}' | sed 's/)@NEWLINE@/)\n/g' | sed 's/@NEWLINE@/ /g' | 
		sed 's/degenerate_cases\///' | 
		egrep -v "WRITEINI|WRITECTD|INVALIDVALUE|DIFF" | 
		grep add_test | 
		egrep "TOPP|UTILS" |
		sed 's@${DATA_DIR_SHARE}/@@g;'|
		sed 's@${TMP_RIP_PATH}@dummy2.tmp@g'|
		sed 's@TOFCalibration_ref_masses @TOFCalibration_ref_masses.txt @g; s@TOFCalibration_const @TOFCalibration_const.csv @'| 
	while read line
	do
		test_id=$(echo "$line" | sed 's/add_test(//; s/"//g;  s/)[^)]*$//; s/\${TOPP_BIN_PATH}\///g;s/\${DATA_DIR_TOPP}\///g; s#THIRDPARTY/##g' | cut -d" " -f1)

		if grep -lq "$test_id"'\".* PROPERTIES WILL_FAIL 1' $OPENMSGIT/src/tests/topp/CMakeLists.txt $OPENMSGIT/src/tests/topp/THIRDPARTY/third_party_tests.cmake; then
			>&2 echo "    skip failing "$test_id
			continue
		fi

		line=$(echo "$line" | sed 's/add_test("//; s/)[^)]*$//; s/\${TOPP_BIN_PATH}\///g;s/\${DATA_DIR_TOPP}\///g; s#THIRDPARTY/##g' | cut -d" " -f2-)
		echo "$line > $test_id.stdout 2> $test_id.stderr"
		echo "if [[ \"\$?\" -ne \"0\" ]]; then >&2 echo '$test_id failed'; >&2 echo -e \"stderr:\n\$(cat $test_id.stderr | sed 's/^/    /')\"; echo -e \"stdout:\n\$(cat $test_id.stdout)\";fi"	
		# echo "$(fix_tmp_files $line)"
    done
}
