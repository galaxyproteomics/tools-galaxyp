#!/bin/bash

VERSION=2.3
CONDAPKG=https://anaconda.org/bioconda/openms/2.3.0/download/linux-64/openms-2.3.0-py27h932d754_3.tar.bz2
#https://anaconda.org/bioconda/openms/2.4.0/download/linux-64/openms-2.4.0-py27h574aadf_1.tar.bz2


# parse test definitions from OpenMS sources for a tool with a given id
function get_tests {
	id=$1
	echo '<xml name="tests_'$id'">'
	cat OpenMS/src/tests/topp/CMakeLists.txt | grep -v "^\s*#" | egrep -v "_prep|_convert|WRITEINI|WRITECTD|INVALIDVALUE" | grep " $id\_" | grep add_test | egrep "TOPP|UTILS" | while read line
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
			param_name=$(echo $param | cut -d" " -f1)
			param_value=$(echo $param | cut -d" " -f 2-)
			
			if grep -lq "^$param_name\s" ../hardcoded_params.txt; then 
				continue
			fi

			# treat flag/boolean parameters (param_name and param_value becomes equal for them)
			if [[ $param_name == $param_value ]]; then
				param_value="-"$param_value
			fi

			if grep -lq '<data name="param_'$param_name'"' xml/$tool_id.xml
			then
				echo '    <output name="param_'$param_name'" value="'$param_value'"/>'
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
	cat OpenMS/src/tests/topp/CMakeLists.txt | grep -v "^\s*#" | egrep -v "WRITEINI|WRITECTD|INVALIDVALUE|DIFF" | egrep "$id\_.*[0-9]+(_prep|_convert)?" | grep add_test | egrep "TOPP|UTILS" | while read line
	do
		line=$(echo $line | sed 's/add_test("//; s/)[^)]*$//; s/\${TOPP_BIN_PATH}\///g;s/\${DATA_DIR_TOPP}\///g; s/-test//; s#THIRDPARTY/##g' | cut -d" " -f2-)
		echo $line
	done 
}


reset old data
rm xml/*xml
echo "<macros>" > xml/macros_test.xml
echo "" > prepare_test_data.sh

# wget $CONDAPKG 
# tar -xf $(basename $CONDAPKG)

# git clone -b release/2.3.0 https://github.com/OpenMS/OpenMS.git

# /home/berntm/miniconda3/bin/conda create -y --quiet --override-channels --channel iuc --channel conda-forge --channel bioconda --channel defaults --name __openms@$VERSION openms=$VERSION
# 
# conda activate __openms@2.3
# 
# mkdir ctd
# for i in bin/*
# do
# 	b=$(basename $i)
# 	$b -write_ctd ctd/
# 	sed -i -e 's/²/^2/' ctd/$b.ctd
# done
# 
# git clone https://github.com/genericworkflownodes/CTDopts
# export PYTHONPATH=/home/berntm/projects/tools-galaxyp/tools/openms/gen-test/CTDopts
# git clone https://github.com/WorkflowConversion/CTDConverter.git

python CTDConverter/convert.py galaxy -i ctd/*ctd -o xml/ -s ../tools_blacklist.txt -f ../filetypes.txt -m ../macros.xml -t ../tool.conf  -p ../hardcoded_params.txt -b version log debug test java_memory java_permgen
#-b version log debug test in_type executable pepnovo_executable param_model_directory rt_concat_trafo_out param_id_pool
# 
# mods for all xml files
# - add aggressive error checks
# - make command and help CDATA
# - remove trailing # chars that are introduced via CTDConverter for hard coded boolean parameters
# - add requirements for tools with -...executable parameter
# - fix in_type (using link with the proper extension)
for i in xml/*xml
do

	id=$(basename $i .xml)

	#if [[ $id != "IDFileConverter" ]]; then
	#	continue
	#fi
	echo postprocessing $id

	sed -i -e '/.*<expand macro="references"/d' $i
	sed -i -e 's#<help>#<help><![CDATA[#g' $i
	sed -i -e 's#</help>#]]></help>\n<expand macro="references"/>#g' $i
	sed -i -e 's/#$//' $i
	sed -i -e 's#<expand macro="requirements"/>#<expand macro="requirements">\n  </expand>#' $i
	if grep -lq '\-r.*_executable' $i
	then
		sed -i -e 's#<expand macro="requirements">#<expand macro="requirements"/>\n    <requirement type="package" version="3.3.1">r-base</requirement>#' $i
	fi

	if grep -lq "percolator_executable" $i
	then
		sed -i -e 's#<expand macro="requirements">#<expand macro="requirements"/>\n    <requirement type="package" version="3.2.1">percolator</requirement>\n  </expand>#' $i
	fi
	if grep -lq "comet_executable" $i
	then
		sed -i -e 's#<expand macro="requirements">#<expand macro="requirements"/>\n    <requirement type="package" version="2018014">comet-ms</requirement>\n  </expand>#' $i
	fi
	if grep -lq "fido_executable" $i
	then
		sed -i -e 's#<expand macro="requirements">#<expand macro="requirements"/>\n    <requirement type="package" version="1.0">fido</requirement>\n  </expand>#' $i
	fi
	if grep -lq "xtandem_executable" $i
	then
		sed -i -e 's#<expand macro="requirements">#<expand macro="requirements"/>\n    <requirement type="package" version="15.12.15.2">xtandem</requirement>\n  </expand>#' $i
	fi
	#TODO requirements for ommsa, myrimatch, luciphor (also -executable)
	#TODO requirements for java?

	if grep -lq "in_type" $i
	then
		sed -i -e '/in_type/d' $i
	fi
	
	for x in $(grep 'type="data"' $i | sed 's/.*name="\([^"]\+\)".*/\1/' | uniq)
	do
		X=$(echo $x | sed 's/param_//')
		sed -i -e "s@\(<command>\)@\1#if str(\$$x)!=\"None:\"\nln -s \$$x '$x.\${$x.ext}' \&\&\n#end if\n@" $i
		sed -i -e "s#-$X .*#-$X '$x.\${$x.ext}'\n#" $i
	done

	if grep -lq "out_type" $i
	then
		sed -i -e 's#<data name="param_out" .*"/>#<data name="param_out" metadata_source="param_in" auto_format="true"/>#' $i
	fi

	# TODO remove empty advanced options section

	# add tests
	sed -i -e "s#\(</outputs>\)#\1\n  <tests>\n    <expand macro=\"tests_$id\"/>\n  </tests>#" $i
	sed -i -e "s#\(</macros>\)#    <import>macros_test.xml</import>\n  \1#" $i
	get_tests $id >> xml/macros_test.xml
	prepare_test_data $id >> prepare_test_data.sh

	# add CDATA to command and add aggressive error checks 
	sed -i -e 's#<command>#<command detect_errors="aggressive"><![CDATA[\n#g' $i
	sed -i -e 's#</command>#]]></command>#g' $i
done

## tool specific changes 
# AccurateMassSearch db_mapping|db_struct|positive_adducts|negative_adducts are documented as mandatory, but they are optional 
for i in db_mapping db_struct positive_adducts negative_adducts
do
	sed -i -e 's/\(<param name="param_'$i'".*\)optional="False"/\1optional="True"/' xml/AccurateMassSearch.xml
        sed -i -e 's/\(<param name="param_'$i'".*\)value="[^"]\+"/\1/' xml/AccurateMassSearch.xml
done



echo "</macros>" >> xml/macros_test.xml

##copy test data from OpenMS sources
mkdir -p xml/test-data

( cat xml/macros_test.xml | grep "<param" | sed 's/.*value="\([^"]\+\)".*/\1/' && cat prepare_test_data.sh) | sed 's/ /\n/g' | grep "\." | grep -v "^-" | grep -v "^[:-]\?[0-9]\+\.[0-9]\+" | sort -u | while read line
do
	b=$(basename $line)
	f=$(find OpenMS/ -name "$b" | head -n 1)
	if [[ ! -z $f ]]; then
		cp $f xml/test-data/
	fi	
done


# chmod u+x prepare_test_data.sh
# cd xml/test-data
# ../../prepare_test_data.sh
# cd ../..
# 
# conda deactivate
