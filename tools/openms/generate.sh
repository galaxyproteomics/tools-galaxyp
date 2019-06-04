# wget https://anaconda.org/bioconda/openms/2.3.0/download/linux-64/openms-2.3.0-py27h932d754_3.tar.bz2
# tar -xf openms-2.3.0-py27h932d754_3.tar.bz2

https://anaconda.org/bioconda/openms/2.4.0/download/linux-64/openms-2.4.0-py27h574aadf_1.tar.bz2
 
# /home/berntm/miniconda3/bin/conda create -y --quiet --override-channels --channel iuc --channel conda-forge --channel bioconda --channel defaults --name __openms@2.3 openms=2.3 
# 
# conda activate __openms@2.3
# 
# mkdir ctd
# for i in bin/*
# do
# 	echo $i
# 	$(basename $i) -write_ctd ctd/
# done
# 
# sed -i -e 's/²/^2/' ctd/MetaProSIP.ctd
# 
# git clone https://github.com/genericworkflownodes/CTDopts
# export PYTHONPATH=/home/berntm/projects/tools-galaxyp/tools/openms/gen-test/CTDopts
# git clone https://github.com/WorkflowConversion/CTDConverter.git

python CTDConverter/convert.py galaxy -i ctd/*ctd -o xml/ -s ../tools_blacklist.txt -f ../filetypes.txt -m ../macros.xml -t ../tool.conf  -p ../hardcoded_params.txt -b version log debug test java_memory java_permgen
#-b version log debug test in_type executable pepnovo_executable param_model_directory rt_concat_trafo_out param_id_pool

# mods for all xml files
# - add aggressive error checks
# - make command and help CDATA
# - remove trailing # chars that are introduced via CTDConverter for hard coded boolean parameters
# - add requirements for tools with -...executable parameter
# - fix in_type (using link with the proper extension)
for i in xml/*xml
do
	echo postprocessing $i
	sed -i -e 's#<command>#<command detect_errors="aggressive"><![CDATA[#g' $i
	sed -i -e 's#</command>#]]></command>#g' $i
	sed -i -e 's#<help>#<help><![CDATA[#g' $i
	sed -i -e 's#</help>#]]></help>#g' $i
	sed -i -e 's/#$//' $i
	sed -i -e 's#<expand macro="requirements"/>#<expand macro="requirements"/>\n  </expand>#' $i
	if grep -lq '\-r.*_executable' $i
	then
		sed -i -e 's#<expand macro="requirements"/>#<expand macro="requirements"/>\n    <requirement type="package" version="3.3.1">r-base</requirement>#' $i
	fi

	if grep -lq "percolator_executable" $i
	then
		sed -i -e 's#<expand macro="requirements"/>#<expand macro="requirements"/>\n    <requirement type="package" version="3.2.1">percolator</requirement>\n  </expand>#' $i
	fi
	if grep -lq "comet_executable" $i
	then
		sed -i -e 's#<expand macro="requirements"/>#<expand macro="requirements"/>\n    <requirement type="package" version="2018014">comet-ms</requirement>\n  </expand>#' $i
	fi
	if grep -lq "fido_executable" $i
	then
		sed -i -e 's#<expand macro="requirements"/>#<expand macro="requirements"/>\n    <requirement type="package" version="1.0">fido</requirement>\n  </expand>#' $i
	fi
	if grep -lq "xtandem_executable" $i
	then
		sed -i -e 's#<expand macro="requirements"/>#<expand macro="requirements"/>\n    <requirement type="package" version="15.12.15.2">xtandem</requirement>\n  </expand>#' $i
	fi
	#TODO requirements for ommsa, myrimatch, 
	#TODO pepnovo (add models to recipe? also fix version currently mismatch between download and version)
	#TODO requirements for java?

	if grep -lq "in_type" $i
	then
		sed -i -e '/in_type/d' $i
		sed -i -e "s#\(<!\[CDATA\[\)#\1\nln -s $param_in 'param_in.\${param_in.ext}' \&\&\n#" $i
		sed -i -e "s#-in TODO#-in 'param_in.\${param_in.ext}'\n#" $i
	fi

	if grep -lq "out_type" $i
	then
		sed -i -e 's#<data name="param_out" format="mzid"/>##'
	fi

	# TODO remove empty advanced options section

done

