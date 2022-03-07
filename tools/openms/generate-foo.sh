#!/usr/bin/env bash

# parse test definitions from OpenMS sources for a tool with a given id
function get_tests2 {
    id=$1
    >&2 echo "generate tests for $id"
    echo '<xml name="autotest_'"$id"'">'

    # get the tests from the CMakeLists.txt
    # 1st remove some tests
    # - OpenSwathMzMLFileCacher with -convert_back argumen https://github.com/OpenMS/OpenMS/issues/4399
    # - IDRipper PATH gets empty causing problems. TODO But overall the option needs to be handled differentlt
    # - several tools with duplicated input (leads to conflict when linking)
    # - TOFCalibration inputs we extension (also in prepare_test_data) https://github.com/OpenMS/OpenMS/pull/4525
    # - MaRaCluster with -consensus_out (parameter blacklister: https://github.com/OpenMS/OpenMS/issues/4456)
    # - FileMerger with mixed dta dta2d input (ftype can not be specified in the test, dta can not be sniffed)
    # - some input files are originally in a subdir (degenerated cases/), but not in test-data
    # - SeedListGenerator: https://github.com/OpenMS/OpenMS/issues/4404
    # - OpenSwathAnalyzer 9/10: cachedMzML (not supported yet)
    # - FeatureFinderIdentification name clash of two tests https://github.com/OpenMS/OpenMS/pull/5002
    # - TODO SiriusAdapter https://github.com/OpenMS/OpenMS/pull/5010
    # - OpenMS 2.8 remove test SiriusAdapter_10 https://github.com/OpenMS/OpenMS/issues/5869
    CMAKE=$(cat $OPENMSGIT/src/tests/topp/CMakeLists.txt $OPENMSGIT/src/tests/topp/THIRDPARTY/third_party_tests.cmake  |
        sed 's@${DATA_DIR_SHARE}/@@g' |
        grep -v 'OpenSwathMzMLFileCacher .*-convert_back' |
        sed 's/${TMP_RIP_PATH}/""/' |
        grep -v "MaRaClusterAdapter.*-consensus_out"|
        grep -v "FileMerger_1_input1.dta2d.*FileMerger_1_input2.dta " |
        sed 's@degenerate_cases/@@g' |
        grep -v 'TOPP_SeedListGenerator_3"' | 
        egrep -v 'TOPP_OpenSwathAnalyzer_test_3"|TOPP_OpenSwathAnalyzer_test_4"' |
        egrep -v '"TOPP_FeatureFinderIdentification_4"' | 
        sed 's/\("TOPP_SiriusAdapter_4".*\)-sirius:database all\(.*\)/\1-sirius:database pubchem\2/' |
        grep -v '"TOPP_SiriusAdapter_10"')


#         grep -v 'FileFilter.*-spectra:select_polarity ""' |
#         grep -v 'MassTraceExtractor_2.ini ' |
#         grep -v "FileMerger_6_input2.mzML.*FileMerger_6_input2.mzML" |
#         grep -v "IDMerger_1_input1.idXML.*IDMerger_1_input1.idXML" |
#         grep -v "degenerated_empty.idXML.*degenerated_empty.idXML" |
#         grep -v "FeatureLinkerUnlabeledKD_1_output.consensusXML.*FeatureLinkerUnlabeledKD_1_output.consensusXML" |
#         grep -v "FeatureLinkerUnlabeledQT_1_output.consensusXML.*FeatureLinkerUnlabeledQT_1_output.consensusXML" |

    # 1st part is a dirty hack to join lines containing a single function call, e.g.
    # addtest(....
    #         ....)
    echo "$CMAKE" | sed 's/#.*//; s/^\s*//; s/\s*$//' | grep -v "^#" | grep -v "^$"  | awk '{printf("%s@NEWLINE@", $0)}' | sed 's/)@NEWLINE@/)\n/g' | sed 's/@NEWLINE@/ /g' | 
        grep -iE "add_test\(\"(TOPP|UTILS)_.*/$id " | egrep -v "_prepare\"|_convert|WRITEINI|WRITECTD|INVALIDVALUE"  | while read -r line
    do
        line=$(echo "$line" | sed 's/add_test("\([^"]\+\)"/\1/; s/)$//; s/\${TOPP_BIN_PATH}\///g;s/\${DATA_DIR_TOPP}\///g; s#THIRDPARTY/##g')
        # >&2 echo $line
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
        # >&2 echo LINE $line
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
        # using eval: otherwise for some reason quoted values are not used properly ('A B' -> ["'A", "B'"])
        # >&2 echo "python3 fill_ctd_clargs.py --ini_file $ini --ctd_file ctd/$tool_id.ctd $cli" 
        eval "python3 fill_ctd_clargs.py --ini_file $ini --ctd_file ctd/$tool_id.ctd $cli" > "$ctdtmp"
        # echo $ctdtmp
        # >&2 cat $ctdtmp
        testtmp=$(mktemp)
        # >&2 cat $ctdtmp
        # >&2 echo CTDConverter galaxy -i $ctdtmp -o $testtmp -s tools_blacklist.txt -f "$FILETYPES" -m macros.xml -t tool.conf  -p hardcoded_params.json --tool-version $VERSION --test-only --test-unsniffable csv tsv txt dta dta2d edta mrm splib
        CTDConverter galaxy -i $ctdtmp -o $testtmp -s tools_blacklist.txt -f "$FILETYPES" -m macros.xml -t tool.conf  -p hardcoded_params.json --tool-version $VERSION --test-only --test-unsniffable csv tsv txt dta dta2d edta mrm splib # > /dev/null
        cat $testtmp | grep -v '<output.*file=""' # | grep -v 'CHEMISTRY/'
        rm $ctdtmp $testtmp

        #> /dev/null

        #rm $testtmp
    done 
    echo '</xml>'
}

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
#    >&2 echo "FIX $line"
    ret=""
    for a in $@; do
        if [[ ! $a =~ .tmp$ ]]; then
            ret="$ret $a"
            continue
        fi
    #    >&2 echo "    a "$a
        g=$(cat $OPENMSGIT/src/tests/topp/CMakeLists.txt $OPENMSGIT/src/tests/topp/THIRDPARTY/third_party_tests.cmake | awk '{printf("%s@NEWLINE@", $0)}' | sed 's/)@NEWLINE@/)\n/g' | sed 's/@NEWLINE@/ /g' | grep '\${DIFF}.*'"$a")
    #    >&2 echo "    g "$g
        in1=$(sed 's/.*-in1 \([^ ]\+\).*/\1/' <<<$g)
        # >&2 echo "    in1 "$in1
        if [[  "$a" != "$in1" ]]; then
            ret="$ret $a"
            continue
        fi
        in2=$(sed 's/.*-in2 \([^ ]\+\).*/\1/' <<<$g)
        in2=$(basename $in2 | sed 's/)$//')
        # >&2 echo "    in2 "$in2
        if [[ -f "test-data/$in2" ]]; then
            ln -fs "$in1" "test-data/$in2"
            ret="$ret $in2"
        else
            ret="$ret $a"
        fi
    done
#    >&2 echo "--> $ret"
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
    
    find test-data/ -name "*.tmp" -print0 | 
    while IFS= read -r -d '' i; do 
        if [ ! -e test-data/$(basename $i .tmp) ]; then
            ln -s $(basename $i) test-data/$(basename $i .tmp)
        else
            ln -fs $(basename $i) test-data/$(basename $i .tmp)
        fi
    done
}



# parse data preparation calls from OpenMS sources for a tool with a given id
function prepare_test_data {
#     id=$1
# | egrep -i "$id\_.*[0-9]+(_prepare\"|_convert)?"

# TODO SiriusAdapter https://github.com/OpenMS/OpenMS/pull/5010
    cat $OPENMSGIT/src/tests/topp/CMakeLists.txt  $OPENMSGIT/src/tests/topp/THIRDPARTY/third_party_tests.cmake | sed 's/#.*$//'| sed 's/^\s*//; s/\s*$//' | grep -v "^$"  | awk '{printf("%s@NEWLINE@", $0)}' | sed 's/)@NEWLINE@/)\n/g' | sed 's/@NEWLINE@/ /g' | 
        sed 's/degenerate_cases\///' | 
        egrep -v "WRITEINI|WRITECTD|INVALIDVALUE|DIFF" | 
        grep add_test | 
        egrep "TOPP|UTILS" |
        sed 's@${DATA_DIR_SHARE}/@@g;'|
        sed 's@${TMP_RIP_PATH}@./@g'|
        sed 's@TOFCalibration_ref_masses @TOFCalibration_ref_masses.txt @g; s@TOFCalibration_const @TOFCalibration_const.csv @'| 
	sed 's/\("TOPP_SiriusAdapter_4".*\)-sirius:database all\(.*\)/\1-sirius:database pubchem\2/' |
    while read line
    do
        test_id=$(echo "$line" | sed 's/add_test(//; s/"//g;  s/)[^)]*$//; s/\${TOPP_BIN_PATH}\///g;s/\${DATA_DIR_TOPP}\///g; s#THIRDPARTY/##g' | cut -d" " -f1)

        if grep -lq "$test_id"'\".* PROPERTIES WILL_FAIL 1' $OPENMSGIT/src/tests/topp/CMakeLists.txt $OPENMSGIT/src/tests/topp/THIRDPARTY/third_party_tests.cmake; then
            >&2 echo "    skip failing "$test_id
            continue
        fi

        line=$(echo "$line" | sed 's/add_test("//; s/)[^)]*$//; s/\${TOPP_BIN_PATH}\///g;s/\${DATA_DIR_TOPP}\///g; s#THIRDPARTY/##g' | cut -d" " -f2-)
        # line="$(fix_tmp_files $line)"
        echo 'echo executing "'$test_id'"'
	echo "$line > $test_id.stdout 2> $test_id.stderr"
        echo "if [[ \"\$?\" -ne \"0\" ]]; then >&2 echo '$test_id failed'; >&2 echo -e \"stderr:\n\$(cat $test_id.stderr | sed 's/^/    /')\"; echo -e \"stdout:\n\$(cat $test_id.stdout)\";fi"    
    done
}
