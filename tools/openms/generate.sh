#!/bin/bash

# VERSION=2.3
# CONDAPKG=https://anaconda.org/bioconda/openms/2.3.0/download/linux-64/openms-2.3.0-py27h932d754_3.tar.bz2
VERSION=2.4
CONDAPKG=https://anaconda.org/bioconda/openms/2.4.0/download/linux-64/openms-2.4.0-py27h574aadf_1.tar.bz2

# ini to test
# some of the tests specify parameters in an ini file 
# for the auto generated tests these need to be transformed to galaxy test xml
function ini2test {
	ini=$1
	
	hcregexp='name="'$(grep -v "^#" hardcoded_params.txt | grep -v "^$" | cut -f1 | tr '\n' '|' | sed 's/|$//')'"'
	egrep "ITEM|ITEMLIST|LISTITEM" $ini | sed 's/^\s*//; s/\s*$//' | while read line
	do
		type=$(echo "$line" | cut -d" " -f1)
		if [[ "$type" == "<ITEM" ]]; then
			name=$(echo "$line" | sed 's/.*name="\([^\"]\+\)".*/\1/' | sed 's/:/_/')
			value=$(echo "$line" | sed 's/.*value="\([^\"]*\)".*/\1/')
			if [[ "$value" != "" ]]; then
				echo '    <param name="'$name'" value="'$value'"/>'
			fi
		elif [[ "$type" == "<ITEMLIST" ]]; then
			name=$(echo "$line" | sed 's/.*name="\([^\"]\+\)".*/\1/'| sed 's/:/_/')
			value=""
		elif [[ "$type" == "<LISTITEM" ]]; then
			if [[ "$value" == "" ]]; then
				value=$(echo "$line" | sed 's/.*value="\([^\"]*\)".*/\1/')
			else	
				value=$value","$(echo "$line" | sed 's/.*value="\([^\"]*\)".*/\1/')
			fi
		elif [[ "$type" == "</ITEMLIST" ]]; then
			if [[ "$value" != "" ]]; then
				echo '    <param name="'$name'" value="'$value'"/>'
			fi
		fi
	done | egrep -v "$hcregexp"

}


# parse test definitions from OpenMS sources for a tool with a given id
function get_tests {
	id=$1
	echo '<xml name="autotest_'$id'">'

	# get the tests from the CMakeLists.txt
        # 1st part is a dirty hack to join lines containing a single function call, e.g.
	# addtest(....
	#         ....)
	cat OpenMS-git/src/tests/topp/CMakeLists.txt | sed 's/^\s*//; s/\s*$//' | grep -v "^#" | grep -v "^$"  | awk '{printf("%s@NEWLINE@", $0)}' | sed 's/)@NEWLINE@/)\n/g' | sed 's/@NEWLINE@/ /g' | 
		egrep -v "_prep|_convert|WRITEINI|WRITECTD|INVALIDVALUE" | grep " $id\_" | grep add_test | egrep "TOPP|UTILS" | while read line
	do
		line=$(echo $line | sed 's/add_test("//; s/)$//; s/"//g; s/\${TOPP_BIN_PATH}\///g;s/\${DATA_DIR_TOPP}\///g; s/-test//; s#THIRDPARTY/##g')
		test_id=$(echo $line | cut -d" " -f 1)
		tool_id=$(echo $line | cut -d" " -f 2)
		if [[ $test_id =~ _out_?[0-9]? ]]; then
			continue
		fi

		if [[ $id != $tool_id ]]; then
			>&2 echo "skip $test_id ($id != $tool_id) "$line
			continue
		fi

		echo "  <test>"

		echo $line | cut -d" " -f3- | sed "s/-/\n/g" | grep -v "^$" | while read param
		do
			param_name=$(echo $param | cut -d" " -f1 | sed 's/:/_/g')
			param_value=$(echo $param | cut -d" " -f 2-)
			
			if grep -lq "^$param_name\s" hardcoded_params.txt; then 
				continue
			fi

			# treat flag/boolean parameters (param_name and param_value becomes equal for them)
			if [[ $param_name == $param_value ]]; then
				param_value="-"$param_value
			fi
			
			if [[ $param_value =~ .ini$ ]]; then
				ini2test test-data/$param_value
			elif grep -lq '<data name="param_out_'$param_name'"' ./$tool_id.xml
			then
				echo '    <output name="param_out_'$param_name'" value="'$param_value'"/>'
			elif grep -lq '<collection .* name="param_out_'$param_name'"' ./$tool_id.xml
			then
				echo '    <output_collection name="param_out_'$param_name'" type="list">'
				echo $param_value | sed 's/ /\n/g' | while read elem
				do
				echo '        <element name="'$elem'" file="'$elem'" ftype="gff" />'
				done
				echo '    </output_collection>'
			else
				echo '    <param name="param_'$param_name'" value="'$param_value'"/>'
			fi
		done
		echo "  </test>"
	done 
	echo '</xml>'
}  

# parse data preparation calls from OpenMS sources for a tool with a given id
function prepare_test_data {
	id=$1

	cat OpenMS-git/src/tests/topp/CMakeLists.txt | sed 's/#.*$//'| sed 's/^\s*//; s/\s*$//' | grep -v "^$"  | awk '{printf("%s@NEWLINE@", $0)}' | sed 's/)@NEWLINE@/)\n/g' | sed 's/@NEWLINE@/ /g' | 
		egrep -v "WRITEINI|WRITECTD|INVALIDVALUE|DIFF" | egrep "$id\_.*[0-9]+(_prep|_convert)?" | grep add_test | egrep "TOPP|UTILS" | while read line
	do
		line=$(echo $line | sed 's/add_test("//; s/)[^)]*$//; s/\${TOPP_BIN_PATH}\///g;s/\${DATA_DIR_TOPP}\///g; s/-test//; s#THIRDPARTY/##g' | cut -d" " -f2-)
		echo $line
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
# python2 CTDConverter/convert.py galaxy -i ctd/*ctd -o ./ -s tools_blacklist.txt -f filetypes.txt -m macros.xml -t tool.conf  -p hardcoded_params.txt -b version log debug test java_memory java_permgen in_type --test-macros macros_autotest.xml --test-macros-prefix autotest_ --tool-version $VERSION
#-b version log debug test in_type executable pepnovo_executable param_model_directory rt_concat_trafo_out param_id_pool

# echo "" > prepare_test_data.sh
# for i in OpenMS$VERSION-pkg/bin/*
# do
# 	b=$(basename "$i")
# 	echo "echo '$b'" >> prepare_test_data.sh
# 	prepare_test_data "$b" >> prepare_test_data.sh
# done
# ##copy test data from OpenMS sources
# rm -rf test-data
# mkdir test-data
# ##( ( grep "<param" ./macros_autotest.xml | sed 's/.*value="\([^"]\+\)".*/\1/')  &&  (sed 's/ /\n/g' prepare_test_data.sh )) | grep "\." | grep -v "^-" | grep -v "^[:-]\?[0-9]\+\.[0-9]\+" | sort -u | while read line
# sed 's/ /\n/g' prepare_test_data.sh | grep "\." | grep -v "^-" | grep -v "^[:-]\?[0-9]\+\.[0-9]\+" | sort -u | while read line
# do
# 	b=$(basename "$line")
# 	f=$(find OpenMS-git/ -name "$b" | head -n 1)
# 	if [[ ! -z $f ]]; then
# 		cp "$f" test-data/
# 	fi	
# done

# conda activate ./OpenMS$VERSION-env
# chmod u+x prepare_test_data.sh
# cd ./test-data || exit
# ../prepare_test_data.sh
# cd - || exit
# conda deactivate


echo "<macros>" > ./macros_autotest.xml
for i in OpenMS$VERSION-pkg/bin/*
do
	b=$(basename "$i")
	get_tests "$b" >> ./macros_autotest.xml
done
echo "</macros>" >> ./macros_autotest.xml


# 
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
