export COMET_BINARY="comet"
export CRUX_BINARY="crux"
export FIDOCHOOSEPARAMS_BINARY="FidoChooseParameters"
export FIDO_BINARY="Fido"
export LUCIPHOR_BINARY="$(dirname $(realpath $(which luciphor2)))/luciphor2.jar"
export MARACLUSTER_BINARY="/tmp/openms-stuff//OpenMS2.8.0-git/THIRDPARTY/Linux/64bit/MaRaCluster/maracluster"
export MSFRAGGER_BINARY="/home/berntm/Downloads/MSFragger-20171106/MSFragger-20171106.jar"
export MSGFPLUS_BINARY="$(msgf_plus -get_jar_path)"
export MYRIMATCH_BINARY="myrimatch"
export NOVOR_BINARY="/home/berntm/Downloads/novor/lib/novor.jar"
export OMSSA_BINARY="$(dirname $(realpath $(which omssacl)))/omssacl"
export PERCOLATOR_BINARY="percolator"
export SIRIUS_BINARY="$(which sirius)"
export SPECTRAST_BINARY="/tmp/openms-stuff//OpenMS2.8.0-git/THIRDPARTY/Linux/64bit/SpectraST/spectrast"
export XTANDEM_BINARY="xtandem"
export THERMORAWFILEPARSER_BINARY="ThermoRawFileParser.exe"
echo executing "UTILS_FuzzyDiff_3"
FuzzyDiff -test -ini FuzzyDiff.ini -in1 FuzzyDiff_3_in1.featureXML -in2 FuzzyDiff_3_in2.featureXML > UTILS_FuzzyDiff_3.stdout 2> UTILS_FuzzyDiff_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_FuzzyDiff_3 failed'; >&2 echo -e "stderr:\n$(cat UTILS_FuzzyDiff_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_FuzzyDiff_3.stdout)";fi
echo executing "TOPP_IDMerger_1"
IDMerger -test -in IDMerger_1_input1.idXML IDMerger_1_input2.idXML -out IDMerger_1_output.tmp > TOPP_IDMerger_1.stdout 2> TOPP_IDMerger_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDMerger_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDMerger_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDMerger_1.stdout)";fi
echo executing "TOPP_IDMerger_2"
IDMerger -test -pepxml_protxml -in IDMerger_2_input1.idXML IDMerger_2_input2.idXML -out IDMerger_2_output.tmp -annotate_file_origin "false" > TOPP_IDMerger_2.stdout 2> TOPP_IDMerger_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDMerger_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDMerger_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDMerger_2.stdout)";fi
echo executing "TOPP_IDMerger_3"
IDMerger -test -in IDMerger_1_input1.idXML IDMerger_1_input1.idXML -out IDMerger_3_output.tmp -annotate_file_origin "false" > TOPP_IDMerger_3.stdout 2> TOPP_IDMerger_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDMerger_3 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDMerger_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDMerger_3.stdout)";fi
echo executing "TOPP_IDMerger_4"
IDMerger -test -in degenerated_empty.idXML degenerated_empty.idXML -out IDMerger_4_output.tmp -annotate_file_origin "false" > TOPP_IDMerger_4.stdout 2> TOPP_IDMerger_4.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDMerger_4 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDMerger_4.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDMerger_4.stdout)";fi
echo executing "TOPP_IDMerger_5"
IDMerger -test -in IDMerger_2_input1.idXML -add_to IDMerger_5_input1.idXML -out IDMerger_5_output.tmp -annotate_file_origin "false" > TOPP_IDMerger_5.stdout 2> TOPP_IDMerger_5.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDMerger_5 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDMerger_5.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDMerger_5.stdout)";fi
echo executing "TOPP_IDMerger_6"
IDMerger -test -in IDMerger_6_input1.oms IDMerger_6_input2.oms -out IDMerger_6_output1.oms > TOPP_IDMerger_6.stdout 2> TOPP_IDMerger_6.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDMerger_6 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDMerger_6.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDMerger_6.stdout)";fi
echo executing "TOPP_IDMerger_6_out1"
IDFileConverter -in IDMerger_6_output1.oms -out IDMerger_6_output2.tmp -out_type idXML > TOPP_IDMerger_6_out1.stdout 2> TOPP_IDMerger_6_out1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDMerger_6_out1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDMerger_6_out1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDMerger_6_out1.stdout)";fi
echo executing "TOPP_BaselineFilter_1"
BaselineFilter -test -in BaselineFilter_input.mzML -out BaselineFilter.tmp -struc_elem_length 1.5 > TOPP_BaselineFilter_1.stdout 2> TOPP_BaselineFilter_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_BaselineFilter_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_BaselineFilter_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_BaselineFilter_1.stdout)";fi
echo executing "TOPP_ConsensusMapNormalizer_1"
ConsensusMapNormalizer -test -in ConsensusMapNormalizer_input.consensusXML -out ConsensusMapNormalizer.tmp > TOPP_ConsensusMapNormalizer_1.stdout 2> TOPP_ConsensusMapNormalizer_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_ConsensusMapNormalizer_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_ConsensusMapNormalizer_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_ConsensusMapNormalizer_1.stdout)";fi
echo executing "TOPP_MapNormalizer_1"
MapNormalizer -test -in MapNormalizer_input.mzML -out MapNormalizer.tmp > TOPP_MapNormalizer_1.stdout 2> TOPP_MapNormalizer_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_MapNormalizer_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_MapNormalizer_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_MapNormalizer_1.stdout)";fi
echo executing "TOPP_DatabaseSuitability_1"
DatabaseSuitability -test -in_id DatabaseSuitability_in_id.idXML -in_spec DatabaseSuitability_in_spec.mzML -in_novo DatabaseSuitability_in_novo.idXML -database DatabaseSuitability_database.fasta -novo_database DatabaseSuitability_novo_database.FASTA -out DatabaseSuitability_1.tmp > TOPP_DatabaseSuitability_1.stdout 2> TOPP_DatabaseSuitability_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_DatabaseSuitability_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_DatabaseSuitability_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_DatabaseSuitability_1.stdout)";fi
echo executing "TOPP_DatabaseSuitability_2"
DatabaseSuitability -test -in_id DatabaseSuitability_in_id.idXML -in_spec DatabaseSuitability_in_spec.mzML -in_novo DatabaseSuitability_in_novo.idXML -database DatabaseSuitability_database.fasta -novo_database DatabaseSuitability_novo_database.FASTA -algorithm:FDR 0.05 -out DatabaseSuitability_2.tmp > TOPP_DatabaseSuitability_2.stdout 2> TOPP_DatabaseSuitability_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_DatabaseSuitability_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_DatabaseSuitability_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_DatabaseSuitability_2.stdout)";fi
echo executing "TOPP_DatabaseSuitability_3"
DatabaseSuitability -test -in_id DatabaseSuitability_in_id.idXML -in_spec DatabaseSuitability_in_spec.mzML -in_novo DatabaseSuitability_in_novo.idXML -database DatabaseSuitability_database.fasta -novo_database DatabaseSuitability_novo_database.FASTA -algorithm:FDR 0.5 -algorithm:reranking_cutoff_percentile 0.5 -out DatabaseSuitability_3.tmp > TOPP_DatabaseSuitability_3.stdout 2> TOPP_DatabaseSuitability_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_DatabaseSuitability_3 failed'; >&2 echo -e "stderr:\n$(cat TOPP_DatabaseSuitability_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_DatabaseSuitability_3.stdout)";fi
echo executing "TOPP_Decharger_1"
Decharger -test -in Decharger_input.featureXML -ini Decharger_input.ini -out_fm Decharger_output_fm.tmp -out_cm Decharger_output.tmp -outpairs Decharger_p_output.tmp > TOPP_Decharger_1.stdout 2> TOPP_Decharger_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_Decharger_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_Decharger_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_Decharger_1.stdout)";fi
echo executing "TOPP_DTAExtractor_1"
DTAExtractor -test -in DTAExtractor_1_input.mzML -out DTAExtractor -rt :61 > TOPP_DTAExtractor_1.stdout 2> TOPP_DTAExtractor_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_DTAExtractor_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_DTAExtractor_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_DTAExtractor_1.stdout)";fi
echo executing "TOPP_DTAExtractor_2"
DTAExtractor -test -in DTAExtractor_1_input.mzML -out DTAExtractor -level 1 > TOPP_DTAExtractor_2.stdout 2> TOPP_DTAExtractor_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_DTAExtractor_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_DTAExtractor_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_DTAExtractor_2.stdout)";fi
echo executing "TOPP_DTAExtractor_3"
DTAExtractor -test -in DTAExtractor_1_input.mzML -out DTAExtractor -level 2 -mz :1000 > TOPP_DTAExtractor_3.stdout 2> TOPP_DTAExtractor_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_DTAExtractor_3 failed'; >&2 echo -e "stderr:\n$(cat TOPP_DTAExtractor_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_DTAExtractor_3.stdout)";fi
echo executing "TOPP_MassTraceExtractor_1"
MassTraceExtractor -test -ini MassTraceExtractor.ini -in MassTraceExtractor_1_input.mzML -out MassTraceExtractor_1.tmp > TOPP_MassTraceExtractor_1.stdout 2> TOPP_MassTraceExtractor_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_MassTraceExtractor_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_MassTraceExtractor_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_MassTraceExtractor_1.stdout)";fi
echo executing "TOPP_MassTraceExtractor_2"
MassTraceExtractor -test -ini MassTraceExtractor_2.ini -in MassTraceExtractor_1_input.mzML -out MassTraceExtractor_2.tmp > TOPP_MassTraceExtractor_2.stdout 2> TOPP_MassTraceExtractor_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_MassTraceExtractor_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_MassTraceExtractor_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_MassTraceExtractor_2.stdout)";fi
echo executing "TOPP_FeatureFinderMetabo_1"
FeatureFinderMetabo -test -ini FeatureFinderMetabo.ini -in FeatureFinderMetabo_1_input.mzML -out FeatureFinderMetabo_1.tmp > TOPP_FeatureFinderMetabo_1.stdout 2> TOPP_FeatureFinderMetabo_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FeatureFinderMetabo_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FeatureFinderMetabo_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FeatureFinderMetabo_1.stdout)";fi
echo executing "TOPP_FeatureFinderMetabo_2"
FeatureFinderMetabo -test -ini FeatureFinderMetabo_2_noEPD.ini -in FeatureFinderMetabo_2_input.mzML -out FeatureFinderMetabo_2.tmp > TOPP_FeatureFinderMetabo_2.stdout 2> TOPP_FeatureFinderMetabo_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FeatureFinderMetabo_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FeatureFinderMetabo_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FeatureFinderMetabo_2.stdout)";fi
echo executing "TOPP_FeatureFinderMetabo_3"
FeatureFinderMetabo -test -ini FeatureFinderMetabo_3.ini -in FeatureFinderMetabo_3_input.mzML -out FeatureFinderMetabo_3.tmp -out_chrom FeatureFinderMetabo_3_chrom.tmp > TOPP_FeatureFinderMetabo_3.stdout 2> TOPP_FeatureFinderMetabo_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FeatureFinderMetabo_3 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FeatureFinderMetabo_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FeatureFinderMetabo_3.stdout)";fi
echo executing "TOPP_FeatureFinderMetabo_4"
FeatureFinderMetabo -test -ini FeatureFinderMetabo_4.ini -in FeatureFinderMetabo_3_input.mzML -out FeatureFinderMetabo_4.tmp -out_chrom FeatureFinderMetabo_4_chrom.tmp > TOPP_FeatureFinderMetabo_4.stdout 2> TOPP_FeatureFinderMetabo_4.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FeatureFinderMetabo_4 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FeatureFinderMetabo_4.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FeatureFinderMetabo_4.stdout)";fi
echo executing "TOPP_FeatureFinderMetabo_5"
FeatureFinderMetabo -test -ini FeatureFinderMetabo.ini -in FeatureFinderMetabo_1_input.mzML -out FeatureFinderMetabo_5.tmp -algorithm:mtd:quant_method max_height > TOPP_FeatureFinderMetabo_5.stdout 2> TOPP_FeatureFinderMetabo_5.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FeatureFinderMetabo_5 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FeatureFinderMetabo_5.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FeatureFinderMetabo_5.stdout)";fi
echo executing "TOPP_FeatureFinderCentroided_1"
FeatureFinderCentroided -test -ini FeatureFinderCentroided_1_parameters.ini -in FeatureFinderCentroided_1_input.mzML -out FeatureFinderCentroided_1.tmp > TOPP_FeatureFinderCentroided_1.stdout 2> TOPP_FeatureFinderCentroided_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FeatureFinderCentroided_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FeatureFinderCentroided_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FeatureFinderCentroided_1.stdout)";fi
echo executing "TOPP_FeatureFinderIdentification_1"
FeatureFinderIdentification -test -in FeatureFinderIdentification_1_input.mzML -id FeatureFinderIdentification_1_input.idXML -out FeatureFinderIdentification_1.tmp.featureXML -extract:mz_window 0.1 -detect:peak_width 60 -model:type none > TOPP_FeatureFinderIdentification_1.stdout 2> TOPP_FeatureFinderIdentification_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FeatureFinderIdentification_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FeatureFinderIdentification_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FeatureFinderIdentification_1.stdout)";fi
echo executing "TOPP_FeatureFinderIdentification_3"
FeatureFinderIdentification -test -in FeatureFinderIdentification_1_input.mzML -id FeatureFinderIdentification_1_input.idXML -out FeatureFinderIdentification_3.tmp.featureXML -extract:mz_window 0.1 -detect:peak_width 60 -model:type symmetric > TOPP_FeatureFinderIdentification_3.stdout 2> TOPP_FeatureFinderIdentification_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FeatureFinderIdentification_3 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FeatureFinderIdentification_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FeatureFinderIdentification_3.stdout)";fi
echo executing "TOPP_FeatureFinderIdentification_5"
FeatureFinderIdentification -test -in FeatureFinderIdentification_1_input.mzML -id FeatureFinderIdentification_1_input.idXML -out FeatureFinderIdentification_5.tmp.featureXML -candidates_out FeatureFinderIdentification_5_candidates.tmp -extract:mz_window 0.1 -extract:batch_size 10 -detect:peak_width 60 -model:type none > TOPP_FeatureFinderIdentification_5.stdout 2> TOPP_FeatureFinderIdentification_5.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FeatureFinderIdentification_5 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FeatureFinderIdentification_5.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FeatureFinderIdentification_5.stdout)";fi
echo executing "TOPP_FeatureFinderMRM_1"
FeatureFinderMRM -test -in FeatureFinderMRM_1_input.mzML -ini FeatureFinderMRM_1_parameters.ini -out FeatureFinderMRM_1.tmp > TOPP_FeatureFinderMRM_1.stdout 2> TOPP_FeatureFinderMRM_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FeatureFinderMRM_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FeatureFinderMRM_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FeatureFinderMRM_1.stdout)";fi
echo executing "TOPP_FeatureFinderMultiplex_1"
FeatureFinderMultiplex -test -in FeatureFinderMultiplex_1_input.mzML -ini FeatureFinderMultiplex_1_parameters.ini -out FeatureFinderMultiplex_1.tmp -out_multiplets FeatureFinderMultiplex_2.tmp > TOPP_FeatureFinderMultiplex_1.stdout 2> TOPP_FeatureFinderMultiplex_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FeatureFinderMultiplex_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FeatureFinderMultiplex_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FeatureFinderMultiplex_1.stdout)";fi
echo executing "TOPP_FeatureFinderMultiplex_2"
FeatureFinderMultiplex -test -in FeatureFinderMultiplex_2_input.mzML -ini FeatureFinderMultiplex_2_parameters.ini -out FeatureFinderMultiplex_3.tmp -out_multiplets FeatureFinderMultiplex_4.tmp > TOPP_FeatureFinderMultiplex_2.stdout 2> TOPP_FeatureFinderMultiplex_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FeatureFinderMultiplex_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FeatureFinderMultiplex_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FeatureFinderMultiplex_2.stdout)";fi
echo executing "TOPP_FeatureFinderMultiplex_3"
FeatureFinderMultiplex -test -in FeatureFinderMultiplex_3_input.mzML -ini FeatureFinderMultiplex_3_parameters.ini -out FeatureFinderMultiplex_5.tmp -out_multiplets FeatureFinderMultiplex_6.tmp > TOPP_FeatureFinderMultiplex_3.stdout 2> TOPP_FeatureFinderMultiplex_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FeatureFinderMultiplex_3 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FeatureFinderMultiplex_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FeatureFinderMultiplex_3.stdout)";fi
echo executing "TOPP_FeatureFinderMultiplex_4"
FeatureFinderMultiplex -test -in FeatureFinderMultiplex_4_input.mzML -ini FeatureFinderMultiplex_4_parameters.ini -out FeatureFinderMultiplex_7.tmp -out_multiplets FeatureFinderMultiplex_8.tmp > TOPP_FeatureFinderMultiplex_4.stdout 2> TOPP_FeatureFinderMultiplex_4.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FeatureFinderMultiplex_4 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FeatureFinderMultiplex_4.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FeatureFinderMultiplex_4.stdout)";fi
echo executing "TOPP_FeatureFinderMultiplex_5"
FeatureFinderMultiplex -test -in FeatureFinderMultiplex_5_input.mzML -ini FeatureFinderMultiplex_5_parameters.ini -out FeatureFinderMultiplex_9.tmp -out_multiplets FeatureFinderMultiplex_10.tmp > TOPP_FeatureFinderMultiplex_5.stdout 2> TOPP_FeatureFinderMultiplex_5.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FeatureFinderMultiplex_5 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FeatureFinderMultiplex_5.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FeatureFinderMultiplex_5.stdout)";fi
echo executing "TOPP_FeatureFinderMultiplex_6"
FeatureFinderMultiplex -test -in FeatureFinderMultiplex_6_input.mzML -ini FeatureFinderMultiplex_6_parameters.ini -out FeatureFinderMultiplex_11.tmp -out_multiplets FeatureFinderMultiplex_12.tmp > TOPP_FeatureFinderMultiplex_6.stdout 2> TOPP_FeatureFinderMultiplex_6.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FeatureFinderMultiplex_6 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FeatureFinderMultiplex_6.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FeatureFinderMultiplex_6.stdout)";fi
echo executing "TOPP_FeatureFinderMultiplex_7"
FeatureFinderMultiplex -test -in FeatureFinderMultiplex_7_input.mzML -ini FeatureFinderMultiplex_7_parameters.ini -out FeatureFinderMultiplex_13.tmp -out_multiplets FeatureFinderMultiplex_14.tmp > TOPP_FeatureFinderMultiplex_7.stdout 2> TOPP_FeatureFinderMultiplex_7.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FeatureFinderMultiplex_7 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FeatureFinderMultiplex_7.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FeatureFinderMultiplex_7.stdout)";fi
echo executing "TOPP_FeatureFinderMultiplex_8"
FeatureFinderMultiplex -test -in FeatureFinderMultiplex_8_input.mzML -ini FeatureFinderMultiplex_8_parameters.ini -out FeatureFinderMultiplex_15.tmp -out_multiplets FeatureFinderMultiplex_16.tmp > TOPP_FeatureFinderMultiplex_8.stdout 2> TOPP_FeatureFinderMultiplex_8.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FeatureFinderMultiplex_8 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FeatureFinderMultiplex_8.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FeatureFinderMultiplex_8.stdout)";fi
echo executing "TOPP_FeatureFinderMultiplex_9"
FeatureFinderMultiplex -test -in FeatureFinderMultiplex_9_input.mzML -ini FeatureFinderMultiplex_9_parameters.ini -out FeatureFinderMultiplex_17.tmp -out_multiplets FeatureFinderMultiplex_18.tmp > TOPP_FeatureFinderMultiplex_9.stdout 2> TOPP_FeatureFinderMultiplex_9.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FeatureFinderMultiplex_9 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FeatureFinderMultiplex_9.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FeatureFinderMultiplex_9.stdout)";fi
echo executing "TOPP_FeatureFinderMultiplex_10"
FeatureFinderMultiplex -test -in FeatureFinderMultiplex_10_input.mzML -ini FeatureFinderMultiplex_10_parameters.ini -out FeatureFinderMultiplex_19.tmp -out_multiplets FeatureFinderMultiplex_20.tmp > TOPP_FeatureFinderMultiplex_10.stdout 2> TOPP_FeatureFinderMultiplex_10.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FeatureFinderMultiplex_10 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FeatureFinderMultiplex_10.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FeatureFinderMultiplex_10.stdout)";fi
echo executing "TOPP_FeatureFinderMultiplex_11"
FeatureFinderMultiplex -test -in FeatureFinderMultiplex_11_input.mzML -ini FeatureFinderMultiplex_11_parameters.ini -out FeatureFinderMultiplex_21.tmp > TOPP_FeatureFinderMultiplex_11.stdout 2> TOPP_FeatureFinderMultiplex_11.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FeatureFinderMultiplex_11 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FeatureFinderMultiplex_11.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FeatureFinderMultiplex_11.stdout)";fi
echo executing "TOPP_FileConverter_1"
FileConverter -test -in FileConverter_1_input.mzData -out FileConverter_1.tmp -out_type mzML > TOPP_FileConverter_1.stdout 2> TOPP_FileConverter_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileConverter_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileConverter_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileConverter_1.stdout)";fi
echo executing "TOPP_FileConverter_2"
FileConverter -test  -in FileConverter_2_input.someInputDTA2D -in_type dta2d -out FileConverter_2.tmp -out_type mzML > TOPP_FileConverter_2.stdout 2> TOPP_FileConverter_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileConverter_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileConverter_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileConverter_2.stdout)";fi
echo executing "TOPP_FileConverter_3"
FileConverter -test  -in FileConverter_3_input.featureXML -out FileConverter_3.tmp -out_type mzML > TOPP_FileConverter_3.stdout 2> TOPP_FileConverter_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileConverter_3 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileConverter_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileConverter_3.stdout)";fi
echo executing "TOPP_FileConverter_4"
FileConverter -test  -in FileConverter_4_input.mzXML -out FileConverter_4.tmp -out_type mzML > TOPP_FileConverter_4.stdout 2> TOPP_FileConverter_4.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileConverter_4 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileConverter_4.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileConverter_4.stdout)";fi
echo executing "TOPP_FileConverter_5"
FileConverter -test -in FileConverter_5_input.mzML -out FileConverter_5.tmp -out_type mzXML > TOPP_FileConverter_5.stdout 2> TOPP_FileConverter_5.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileConverter_5 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileConverter_5.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileConverter_5.stdout)";fi
echo executing "TOPP_FileConverter_6"
FileConverter -test -in FileConverter_6_input.mzML -out FileConverter_6.tmp -out_type mzXML > TOPP_FileConverter_6.stdout 2> TOPP_FileConverter_6.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileConverter_6 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileConverter_6.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileConverter_6.stdout)";fi
echo executing "TOPP_FileConverter_7"
FileConverter -test -in FileConverter_7_input.consensusXML -out FileConverter_7.tmp -out_type featureXML > TOPP_FileConverter_7.stdout 2> TOPP_FileConverter_7.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileConverter_7 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileConverter_7.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileConverter_7.stdout)";fi
echo executing "TOPP_FileConverter_8"
FileConverter -test -in FileConverter_8_input.mzML -out FileConverter_8.tmp -out_type mzData > TOPP_FileConverter_8.stdout 2> TOPP_FileConverter_8.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileConverter_8 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileConverter_8.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileConverter_8.stdout)";fi
echo executing "TOPP_FileConverter_9"
FileConverter -test -in FileConverter_9_input.consensusXML -out FileConverter_9.tmp -out_type featureXML > TOPP_FileConverter_9.stdout 2> TOPP_FileConverter_9.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileConverter_9 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileConverter_9.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileConverter_9.stdout)";fi
echo executing "TOPP_FileConverter_10"
FileConverter -test -in FileConverter_10_input.edta -no_progress -out FileConverter_10.tmp -out_type featureXML > TOPP_FileConverter_10.stdout 2> TOPP_FileConverter_10.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileConverter_10 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileConverter_10.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileConverter_10.stdout)";fi
echo executing "TOPP_FileConverter_11"
FileConverter -test -in FileConverter_11_input.peplist -no_progress -out FileConverter_11.tmp -out_type featureXML > TOPP_FileConverter_11.stdout 2> TOPP_FileConverter_11.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileConverter_11 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileConverter_11.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileConverter_11.stdout)";fi
echo executing "TOPP_FileConverter_12"
FileConverter -test -in FileConverter_12_input.peptides.tsv -no_progress -out FileConverter_12.tmp -out_type featureXML > TOPP_FileConverter_12.stdout 2> TOPP_FileConverter_12.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileConverter_12 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileConverter_12.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileConverter_12.stdout)";fi
echo executing "TOPP_FileConverter_13"
FileConverter -test -in FileConverter_13_input.peptides.kroenik -no_progress -out FileConverter_13.tmp -out_type featureXML > TOPP_FileConverter_13.stdout 2> TOPP_FileConverter_13.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileConverter_13 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileConverter_13.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileConverter_13.stdout)";fi
echo executing "TOPP_FileConverter_14"
FileConverter -test -in FileConverter_9_output.featureXML -no_progress -out FileConverter_14.tmp -out_type consensusXML > TOPP_FileConverter_14.stdout 2> TOPP_FileConverter_14.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileConverter_14 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileConverter_14.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileConverter_14.stdout)";fi
echo executing "TOPP_FileConverter_15"
FileConverter -test -in FileConverter_10_input.edta -no_progress -out FileConverter_15.tmp -out_type consensusXML > TOPP_FileConverter_15.stdout 2> TOPP_FileConverter_15.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileConverter_15 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileConverter_15.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileConverter_15.stdout)";fi
echo executing "TOPP_FileConverter_16"
FileConverter -test -in FileConverter_16_input.edta -no_progress -out FileConverter_16.tmp -out_type consensusXML > TOPP_FileConverter_16.stdout 2> TOPP_FileConverter_16.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileConverter_16 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileConverter_16.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileConverter_16.stdout)";fi
echo executing "TOPP_FileConverter_17"
FileConverter -test -in FileConverter_17_input.consensusXML -no_progress -out FileConverter_17.csv > TOPP_FileConverter_17.stdout 2> TOPP_FileConverter_17.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileConverter_17 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileConverter_17.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileConverter_17.stdout)";fi
echo executing "TOPP_FileConverter_18"
FileConverter -test -in FileConverter_17_input.consensusXML -no_progress -out FileConverter_18.tmp -out_type csv > TOPP_FileConverter_18.stdout 2> TOPP_FileConverter_18.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileConverter_18 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileConverter_18.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileConverter_18.stdout)";fi
echo executing "TOPP_FileConverter_19"
FileConverter -test -in FileFilter_1_input.mzML -out FileConverter_19.tmp -process_lowmemory -in_type mzML -out_type mzML > TOPP_FileConverter_19.stdout 2> TOPP_FileConverter_19.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileConverter_19 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileConverter_19.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileConverter_19.stdout)";fi
echo executing "TOPP_FileConverter_20"
FileConverter -test -in FileConverter_20_input.featureXML -out FileConverter_20.tmp -in_type featureXML -out_type featureXML > TOPP_FileConverter_20.stdout 2> TOPP_FileConverter_20.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileConverter_20 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileConverter_20.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileConverter_20.stdout)";fi
echo executing "TOPP_FileConverter_21"
FileConverter -test -in FileConverter_4_input.mzXML -out FileConverter_21.tmp -out_type mzML -process_lowmemory > TOPP_FileConverter_21.stdout 2> TOPP_FileConverter_21.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileConverter_21 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileConverter_21.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileConverter_21.stdout)";fi
echo executing "TOPP_FileConverter_23"
FileConverter -test -in FileConverter_23_input.mzML -out FileConverter_23.tmp -out_type mzML > TOPP_FileConverter_23.stdout 2> TOPP_FileConverter_23.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileConverter_23 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileConverter_23.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileConverter_23.stdout)";fi
echo executing "TOPP_FileConverter_24"
FileConverter -test -in FileFilter_1_input.mzML -out FileConverter_24.tmp -process_lowmemory -in_type mzML -out_type mzML -lossy_compression -lossy_mass_accuracy 0.0001 > TOPP_FileConverter_24.stdout 2> TOPP_FileConverter_24.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileConverter_24 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileConverter_24.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileConverter_24.stdout)";fi
echo executing "TOPP_FileConverter_25"
FileConverter -test -in FileFilter_1_input.mzML -out FileConverter_25.tmp -process_lowmemory -in_type mzML -out_type mzML -lossy_compression > TOPP_FileConverter_25.stdout 2> TOPP_FileConverter_25.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileConverter_25 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileConverter_25.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileConverter_25.stdout)";fi
echo executing "TOPP_FileConverter_26"
FileConverter -test -in FileFilter_1_input.mzML -out FileConverter_26.tmp -force_MaxQuant_compatibility -out_type mzXML > TOPP_FileConverter_26.stdout 2> TOPP_FileConverter_26.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileConverter_26 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileConverter_26.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileConverter_26.stdout)";fi
echo executing "TOPP_FileConverter_26-2"
FileConverter -test -in FileConverter_26_output.mzXML -out FileConverter_26-2.tmp -force_MaxQuant_compatibility -out_type mzXML > TOPP_FileConverter_26-2.stdout 2> TOPP_FileConverter_26-2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileConverter_26-2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileConverter_26-2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileConverter_26-2.stdout)";fi
echo executing "TOPP_FileConverter_27"
FileConverter -test -in FileConverter_27_input.mzML -out FileConverter_27.tmp -out_type mzML  -convert_to_chromatograms > TOPP_FileConverter_27.stdout 2> TOPP_FileConverter_27.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileConverter_27 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileConverter_27.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileConverter_27.stdout)";fi
echo executing "TOPP_FileConverter_28"
FileConverter -test -in FileConverter_28_input.mzML -out FileConverter_28.tmp -out_type mzML  -convert_to_chromatograms > TOPP_FileConverter_28.stdout 2> TOPP_FileConverter_28.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileConverter_28 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileConverter_28.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileConverter_28.stdout)";fi
echo executing "TOPP_FileConverter_29"
FileConverter -test -in OpenSwathWorkflow_17_input.mzML -out FileConverter_29.tmp -out_type mzML -lossy_compression -lossy_mass_accuracy 1e-5 -process_lowmemory > TOPP_FileConverter_29.stdout 2> TOPP_FileConverter_29.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileConverter_29 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileConverter_29.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileConverter_29.stdout)";fi
echo executing "TOPP_FileConverter_29_back"
FileConverter -test -in FileConverter_29.tmp -in_type mzML -out FileConverter_29.back.tmp -out_type mzML > TOPP_FileConverter_29_back.stdout 2> TOPP_FileConverter_29_back.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileConverter_29_back failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileConverter_29_back.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileConverter_29_back.stdout)";fi
echo executing "TOPP_FileConverter_30"
FileConverter -test -in FileConverter_30_input.mzML -change_im_format multiple_spectra -out_type mzML -out FileConverter_30.tmp > TOPP_FileConverter_30.stdout 2> TOPP_FileConverter_30.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileConverter_30 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileConverter_30.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileConverter_30.stdout)";fi
echo executing "TOPP_FileConverter_31"
FileConverter -test -in FileConverter_30_output.mzML -change_im_format concatenated -out_type mzML -out FileConverter_31.tmp > TOPP_FileConverter_31.stdout 2> TOPP_FileConverter_31.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileConverter_31 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileConverter_31.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileConverter_31.stdout)";fi
echo executing "TOPP_FileConverter_32"
FileConverter -test -in FileConverter_32_input.mzML -out_type mzML -out FileConverter_32.tmp > TOPP_FileConverter_32.stdout 2> TOPP_FileConverter_32.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileConverter_32 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileConverter_32.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileConverter_32.stdout)";fi
echo executing "TOPP_FileFilter_1"
FileFilter -test -in FileFilter_1_input.mzML -out FileFilter_1.tmp -rt :30 -mz :1000 -int :20000 -in_type mzML -out_type mzML > TOPP_FileFilter_1.stdout 2> TOPP_FileFilter_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileFilter_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileFilter_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileFilter_1.stdout)";fi
echo executing "TOPP_FileFilter_2"
FileFilter -test -in FileFilter_1_input.mzML -out FileFilter_2.tmp -rt 30: -mz 1000: -int 100: -in_type mzML -out_type mzML > TOPP_FileFilter_2.stdout 2> TOPP_FileFilter_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileFilter_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileFilter_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileFilter_2.stdout)";fi
echo executing "TOPP_FileFilter_3"
FileFilter -test -in FileFilter_1_input.mzML -out FileFilter_3.tmp -peak_options:level 2 -in_type mzML -out_type mzML > TOPP_FileFilter_3.stdout 2> TOPP_FileFilter_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileFilter_3 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileFilter_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileFilter_3.stdout)";fi
echo executing "TOPP_FileFilter_4"
FileFilter -test -in FileFilter_4_input.mzML -out FileFilter_4.tmp -spectra:remove_zoom -in_type mzML -out_type mzML > TOPP_FileFilter_4.stdout 2> TOPP_FileFilter_4.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileFilter_4 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileFilter_4.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileFilter_4.stdout)";fi
echo executing "TOPP_FileFilter_5"
FileFilter -test -in FileFilter_5_input.featureXML -out FileFilter_5.tmp -rt :1000 -mz :480 -int :79000 -f_and_c:charge :3 -feature:q :0.6 -in_type featureXML -out_type featureXML > TOPP_FileFilter_5.stdout 2> TOPP_FileFilter_5.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileFilter_5 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileFilter_5.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileFilter_5.stdout)";fi
echo executing "TOPP_FileFilter_6"
FileFilter -test -in FileFilter_5_input.featureXML -out FileFilter_6.tmp -rt 1000: -mz 440: -int 70000: -f_and_c:charge 3: -feature:q 0.51: -in_type featureXML -out_type featureXML > TOPP_FileFilter_6.stdout 2> TOPP_FileFilter_6.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileFilter_6 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileFilter_6.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileFilter_6.stdout)";fi
echo executing "TOPP_FileFilter_7"
FileFilter -test -in FileFilter_7_input.mzML -out FileFilter_7.tmp -int 7000: -peak_options:level 1 2 3 -in_type mzML -out_type mzML > TOPP_FileFilter_7.stdout 2> TOPP_FileFilter_7.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileFilter_7 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileFilter_7.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileFilter_7.stdout)";fi
echo executing "TOPP_FileFilter_8"
FileFilter -test -in FileFilter_8_input.consensusXML -out FileFilter_8.tmp -rt 600:1400 -mz 700:2300 -int 1100:6000 -in_type consensusXML -out_type consensusXML > TOPP_FileFilter_8.stdout 2> TOPP_FileFilter_8.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileFilter_8 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileFilter_8.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileFilter_8.stdout)";fi
echo executing "TOPP_FileFilter_9"
FileFilter -test -in FileFilter_9_input.mzML -out FileFilter_9.tmp -spectra:remove_mode SelectedIonMonitoring -in_type mzML -out_type mzML > TOPP_FileFilter_9.stdout 2> TOPP_FileFilter_9.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileFilter_9 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileFilter_9.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileFilter_9.stdout)";fi
echo executing "TOPP_FileFilter_10"
FileFilter -test -in FileFilter_10_input.mzML -out FileFilter_10.tmp -spectra:remove_activation "Collision-induced dissociation" -in_type mzML -out_type mzML > TOPP_FileFilter_10.stdout 2> TOPP_FileFilter_10.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileFilter_10 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileFilter_10.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileFilter_10.stdout)";fi
echo executing "TOPP_FileFilter_11"
FileFilter -test -in FileFilter_11_input.mzML -out FileFilter_11.tmp -spectra:remove_activation "Plasma desorption" -in_type mzML -out_type mzML > TOPP_FileFilter_11.stdout 2> TOPP_FileFilter_11.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileFilter_11 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileFilter_11.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileFilter_11.stdout)";fi
echo executing "TOPP_FileFilter_12"
FileFilter -test -in FileFilter_12_input.mzML -out FileFilter_12.tmp -peak_options:remove_chromatograms -in_type mzML -out_type mzML > TOPP_FileFilter_12.stdout 2> TOPP_FileFilter_12.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileFilter_12 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileFilter_12.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileFilter_12.stdout)";fi
echo executing "TOPP_FileFilter_13"
FileFilter -test -in FileFilter_13_input.consensusXML -out FileFilter_13.tmp -in_type consensusXML -out_type featureXML -consensus:map 2 > TOPP_FileFilter_13.stdout 2> TOPP_FileFilter_13.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileFilter_13 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileFilter_13.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileFilter_13.stdout)";fi
echo executing "TOPP_FileFilter_14"
FileFilter -test -in FileFilter_14_input.consensusXML -out FileFilter_14.tmp -in_type consensusXML -out_type consensusXML -consensus:map 0 2 > TOPP_FileFilter_14.stdout 2> TOPP_FileFilter_14.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileFilter_14 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileFilter_14.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileFilter_14.stdout)";fi
echo executing "TOPP_FileFilter_15"
FileFilter -test -in FileFilter_15_input.featureXML -out FileFilter_15.tmp -id:sequences_whitelist Oxidation -id:remove_unassigned_ids > TOPP_FileFilter_15.stdout 2> TOPP_FileFilter_15.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileFilter_15 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileFilter_15.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileFilter_15.stdout)";fi
echo executing "TOPP_FileFilter_16"
FileFilter -test -in FileFilter_15_input.featureXML -out FileFilter_16.tmp -id:sequences_whitelist Oxidation -id:remove_unassigned_ids -mz 400:600 -rt 3000:4000 > TOPP_FileFilter_16.stdout 2> TOPP_FileFilter_16.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileFilter_16 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileFilter_16.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileFilter_16.stdout)";fi
echo executing "TOPP_FileFilter_17"
FileFilter -test -in FileFilter_15_input.featureXML -out FileFilter_17.tmp -id:remove_annotated_features -mz 400:600 -rt 3000:4000 > TOPP_FileFilter_17.stdout 2> TOPP_FileFilter_17.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileFilter_17 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileFilter_17.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileFilter_17.stdout)";fi
echo executing "TOPP_FileFilter_18"
FileFilter -test -in FileFilter_18_input.consensusXML -out FileFilter_18.tmp -id:sequences_whitelist Oxidation -id:remove_unassigned_ids > TOPP_FileFilter_18.stdout 2> TOPP_FileFilter_18.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileFilter_18 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileFilter_18.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileFilter_18.stdout)";fi
echo executing "TOPP_FileFilter_19"
FileFilter -test -in FileFilter_18_input.consensusXML -out FileFilter_19.tmp -id:remove_unannotated_features -mz 400:600 -rt 3000:4000 > TOPP_FileFilter_19.stdout 2> TOPP_FileFilter_19.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileFilter_19 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileFilter_19.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileFilter_19.stdout)";fi
echo executing "TOPP_FileFilter_20"
FileFilter -test -in FileFilter_15_input.featureXML -out FileFilter_20.tmp -id:accessions_whitelist YDL217C -id:remove_unassigned_ids > TOPP_FileFilter_20.stdout 2> TOPP_FileFilter_20.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileFilter_20 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileFilter_20.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileFilter_20.stdout)";fi
echo executing "TOPP_FileFilter_21"
FileFilter -test -in FileFilter_15_input.featureXML -out FileFilter_21.tmp -id:remove_unassigned_ids -id:remove_unannotated_features -id:keep_best_score_id > TOPP_FileFilter_21.stdout 2> TOPP_FileFilter_21.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileFilter_21 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileFilter_21.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileFilter_21.stdout)";fi
echo executing "TOPP_FileFilter_22"
FileFilter -test -in FileFilter_22_input.consensusXML -out FileFilter_22.tmp -f_and_c:remove_meta distinct_charges gt "1,2" > TOPP_FileFilter_22.stdout 2> TOPP_FileFilter_22.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileFilter_22 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileFilter_22.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileFilter_22.stdout)";fi
echo executing "TOPP_FileFilter_23"
FileFilter -test -in FileFilter_22_input.consensusXML -out FileFilter_23.tmp -f_and_c:remove_meta distinct_charges_size gt 2 > TOPP_FileFilter_23.stdout 2> TOPP_FileFilter_23.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileFilter_23 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileFilter_23.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileFilter_23.stdout)";fi
echo executing "TOPP_FileFilter_24"
FileFilter -test -in FileFilter_22_input.consensusXML -out FileFilter_24.tmp -f_and_c:remove_meta DOESNOTEXIST lt "whatever" > TOPP_FileFilter_24.stdout 2> TOPP_FileFilter_24.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileFilter_24 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileFilter_24.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileFilter_24.stdout)";fi
echo executing "TOPP_FileFilter_25"
FileFilter -test -in FileFilter_25_input.mzML.gz -id:blacklist FileFilter_25_input.idXML -out FileFilter_25.tmp -id:mz 0.05 -id:rt 1 -id:blacklist_imperfect > TOPP_FileFilter_25.stdout 2> TOPP_FileFilter_25.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileFilter_25 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileFilter_25.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileFilter_25.stdout)";fi
echo executing "TOPP_FileFilter_26"
FileFilter -test -in FileFilter_25_input.mzML.gz -id:blacklist FileFilter_25_input.idXML -out FileFilter_26.tmp -id:blacklist_imperfect > TOPP_FileFilter_26.stdout 2> TOPP_FileFilter_26.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileFilter_26 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileFilter_26.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileFilter_26.stdout)";fi
echo executing "TOPP_FileFilter_28"
FileFilter -test -in FileFilter_28_input.mzML.gz -peak_options:pc_mz_range 832:836 -out FileFilter_28.tmp -peak_options:level 2 > TOPP_FileFilter_28.stdout 2> TOPP_FileFilter_28.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileFilter_28 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileFilter_28.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileFilter_28.stdout)";fi
echo executing "TOPP_FileFilter_29"
FileFilter -test -in FileFilter_28_input.mzML.gz -peak_options:pc_mz_range 832:836 -out FileFilter_29.tmp -peak_options:level 1 2 > TOPP_FileFilter_29.stdout 2> TOPP_FileFilter_29.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileFilter_29 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileFilter_29.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileFilter_29.stdout)";fi
echo executing "TOPP_FileFilter_30"
FileFilter -test -in FileFilter_28_input.mzML.gz -peak_options:pc_mz_range 832:836 -out FileFilter_30.tmp -peak_options:level 1 2 > TOPP_FileFilter_30.stdout 2> TOPP_FileFilter_30.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileFilter_30 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileFilter_30.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileFilter_30.stdout)";fi
echo executing "TOPP_FileFilter_31"
FileFilter -test -in FileFilter_31_34_input.mzML -spectra:remove_isolation_window_width :2 -out FileFilter_31.tmp  > TOPP_FileFilter_31.stdout 2> TOPP_FileFilter_31.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileFilter_31 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileFilter_31.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileFilter_31.stdout)";fi
echo executing "TOPP_FileFilter_32"
FileFilter -test -in FileFilter_31_34_input.mzML -spectra:select_isolation_window_width :2 -out FileFilter_32.tmp  > TOPP_FileFilter_32.stdout 2> TOPP_FileFilter_32.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileFilter_32 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileFilter_32.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileFilter_32.stdout)";fi
echo executing "TOPP_FileFilter_33"
FileFilter -test -in FileFilter_31_34_input.mzML -spectra:remove_collision_energy :35 -out FileFilter_33.tmp  > TOPP_FileFilter_33.stdout 2> TOPP_FileFilter_33.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileFilter_33 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileFilter_33.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileFilter_33.stdout)";fi
echo executing "TOPP_FileFilter_34"
FileFilter -test -in FileFilter_31_34_input.mzML -spectra:select_collision_energy :35 -out FileFilter_34.tmp  > TOPP_FileFilter_34.stdout 2> TOPP_FileFilter_34.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileFilter_34 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileFilter_34.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileFilter_34.stdout)";fi
echo executing "TOPP_FileFilter_35"
FileFilter -test -in FileFilter_1_input.mzML -out FileFilter_35.tmp -peak_options:indexed_file true -in_type mzML -out_type mzML > TOPP_FileFilter_35.stdout 2> TOPP_FileFilter_35.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileFilter_35 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileFilter_35.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileFilter_35.stdout)";fi
echo executing "TOPP_FileFilter_36"
FileFilter -test -in FileFilter_1_input.mzML -out FileFilter_36.tmp -peak_options:indexed_file false -in_type mzML -out_type mzML > TOPP_FileFilter_36.stdout 2> TOPP_FileFilter_36.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileFilter_36 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileFilter_36.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileFilter_36.stdout)";fi
echo executing "TOPP_FileFilter_37"
FileFilter -test -in FileFilter_1_input.mzML -out FileFilter_37.tmp -test -peak_options:numpress:intensity slof -peak_options:numpress:masstime linear -in_type mzML -peak_options:numpress:lossy_mass_accuracy 1e-4 -out_type mzML > TOPP_FileFilter_37.stdout 2> TOPP_FileFilter_37.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileFilter_37 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileFilter_37.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileFilter_37.stdout)";fi
echo executing "TOPP_FileFilter_38"
FileFilter -test -in FileFilter_1_input.mzML -out FileFilter_38.tmp -test -peak_options:numpress:intensity pic -peak_options:numpress:masstime linear -in_type mzML -peak_options:numpress:lossy_mass_accuracy 1e-4 -out_type mzML > TOPP_FileFilter_38.stdout 2> TOPP_FileFilter_38.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileFilter_38 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileFilter_38.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileFilter_38.stdout)";fi
echo executing "TOPP_FileFilter_40"
FileFilter -test -in FileFilter_40_input.mzML -out FileFilter_40.tmp -spectra:select_polarity positive -in_type mzML -out_type mzML > TOPP_FileFilter_40.stdout 2> TOPP_FileFilter_40.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileFilter_40 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileFilter_40.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileFilter_40.stdout)";fi
echo executing "TOPP_FileFilter_41"
FileFilter -test -in FileFilter_40_input.mzML -out FileFilter_41.tmp -spectra:select_polarity negative -in_type mzML -out_type mzML > TOPP_FileFilter_41.stdout 2> TOPP_FileFilter_41.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileFilter_41 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileFilter_41.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileFilter_41.stdout)";fi
echo executing "TOPP_FileFilter_42"
FileFilter -test -in FileFilter_40_input.mzML -out FileFilter_42.tmp -spectra:select_polarity "" -in_type mzML -out_type mzML > TOPP_FileFilter_42.stdout 2> TOPP_FileFilter_42.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileFilter_42 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileFilter_42.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileFilter_42.stdout)";fi
echo executing "TOPP_FileFilter_43"
FileFilter -test -in FileFilter_43_input.mzML -out FileFilter_43.tmp.mzML -in_type mzML -out_type mzML > TOPP_FileFilter_43.stdout 2> TOPP_FileFilter_43.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileFilter_43 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileFilter_43.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileFilter_43.stdout)";fi
echo executing "TOPP_FileFilter_43_read_again"
FileFilter -test -in FileFilter_43.tmp.mzML -out FileFilter_43.dummy.tmp  -in_type mzML -out_type mzML > TOPP_FileFilter_43_read_again.stdout 2> TOPP_FileFilter_43_read_again.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileFilter_43_read_again failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileFilter_43_read_again.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileFilter_43_read_again.stdout)";fi
echo executing "TOPP_FileFilter_44"
FileFilter -test -in FileFilter_44_input.mzML -out FileFilter_44.tmp -test -in_type mzML -out_type mzML > TOPP_FileFilter_44.stdout 2> TOPP_FileFilter_44.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileFilter_44 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileFilter_44.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileFilter_44.stdout)";fi
echo executing "TOPP_FileFilter_45"
FileFilter -test -in FileFilter_45_input.featureXML -id:sequences_whitelist "YSFS" "STLIPPPSK(Label:13C(6)15N(2))" -out FileFilter_45.tmp > TOPP_FileFilter_45.stdout 2> TOPP_FileFilter_45.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileFilter_45 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileFilter_45.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileFilter_45.stdout)";fi
echo executing "TOPP_FileFilter_46"
FileFilter -test -in FileFilter_46_input.featureXML -id:sequences_whitelist "YSFS" "STLIPPPSK(Label:13C(6)15N(2))" -id:sequence_comparison_method "exact" -out FileFilter_46.tmp > TOPP_FileFilter_46.stdout 2> TOPP_FileFilter_46.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileFilter_46 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileFilter_46.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileFilter_46.stdout)";fi
echo executing "TOPP_FileFilter_47"
FileFilter -test -in FileFilter_47_input.mzML -spectra:blackorwhitelist:file FileFilter_47_input_select.mzML -spectra:blackorwhitelist:similarity_threshold 0.9 -out FileFilter_47_1.tmp > TOPP_FileFilter_47.stdout 2> TOPP_FileFilter_47.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileFilter_47 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileFilter_47.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileFilter_47.stdout)";fi
echo executing "TOPP_FileFilter_48"
FileFilter -test -in FileFilter_47_input.mzML -spectra:blackorwhitelist:file FileFilter_47_input_select.mzML -spectra:blackorwhitelist:similarity_threshold 0.9 -spectra:blackorwhitelist:blacklist false -out FileFilter_48_1.tmp > TOPP_FileFilter_48.stdout 2> TOPP_FileFilter_48.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileFilter_48 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileFilter_48.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileFilter_48.stdout)";fi
echo executing "TOPP_FileFilter_49"
FileFilter -test -in FileFilter_49_input.mzML -peak_options:numpress:intensity pic -peak_options:numpress:masstime linear -peak_options:numpress:float_da slof -peak_options:zlib_compression true -out FileFilter_49_1.tmp > TOPP_FileFilter_49.stdout 2> TOPP_FileFilter_49.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileFilter_49 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileFilter_49.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileFilter_49.stdout)";fi
echo executing "TOPP_FileInfo_1"
FileInfo -test -in FileInfo_1_input.dta -in_type dta -no_progress -out FileInfo_1.tmp > TOPP_FileInfo_1.stdout 2> TOPP_FileInfo_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileInfo_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileInfo_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileInfo_1.stdout)";fi
echo executing "TOPP_FileInfo_2"
FileInfo -test -in FileInfo_2_input.dta2d -no_progress -out FileInfo_2.tmp > TOPP_FileInfo_2.stdout 2> TOPP_FileInfo_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileInfo_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileInfo_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileInfo_2.stdout)";fi
echo executing "TOPP_FileInfo_3"
FileInfo -test -in FileInfo_3_input.featureXML -m -s -p -no_progress -out FileInfo_3.tmp > TOPP_FileInfo_3.stdout 2> TOPP_FileInfo_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileInfo_3 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileInfo_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileInfo_3.stdout)";fi
echo executing "TOPP_FileInfo_4"
FileInfo -test -in FileInfo_4_input.mzXML -m -no_progress -out FileInfo_4.tmp > TOPP_FileInfo_4.stdout 2> TOPP_FileInfo_4.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileInfo_4 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileInfo_4.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileInfo_4.stdout)";fi
echo executing "TOPP_FileInfo_5"
FileInfo -test -in FileInfo_5_input.mzDat -in_type mzData -m -s -no_progress -out FileInfo_5.tmp > TOPP_FileInfo_5.stdout 2> TOPP_FileInfo_5.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileInfo_5 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileInfo_5.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileInfo_5.stdout)";fi
echo executing "TOPP_FileInfo_6"
FileInfo -test -in FileInfo_6_input.mzData -d -s -no_progress -out FileInfo_6.tmp > TOPP_FileInfo_6.stdout 2> TOPP_FileInfo_6.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileInfo_6 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileInfo_6.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileInfo_6.stdout)";fi
echo executing "TOPP_FileInfo_7"
FileInfo -test -in FileInfo_7_input.consensusXML -s -m -p -no_progress -out FileInfo_7.tmp > TOPP_FileInfo_7.stdout 2> TOPP_FileInfo_7.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileInfo_7 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileInfo_7.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileInfo_7.stdout)";fi
echo executing "TOPP_FileInfo_9"
FileInfo -test -in FileInfo_9_input.mzML -m -p -s -no_progress -out FileInfo_9.tmp > TOPP_FileInfo_9.stdout 2> TOPP_FileInfo_9.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileInfo_9 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileInfo_9.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileInfo_9.stdout)";fi
echo executing "TOPP_FileInfo_10"
FileInfo -test -in FileInfo_10_input.idXML -no_progress -out FileInfo_10.tmp > TOPP_FileInfo_10.stdout 2> TOPP_FileInfo_10.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileInfo_10 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileInfo_10.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileInfo_10.stdout)";fi
echo executing "TOPP_FileInfo_12"
FileInfo -test -in FileInfo_12_input.mzML -i  -no_progress > TOPP_FileInfo_12.stdout 2> TOPP_FileInfo_12.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileInfo_12 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileInfo_12.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileInfo_12.stdout)";fi
echo executing "TOPP_FileInfo_13"
FileInfo -test -in FileInfo_13_input.consensusXML -no_progress > TOPP_FileInfo_13.stdout 2> TOPP_FileInfo_13.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileInfo_13 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileInfo_13.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileInfo_13.stdout)";fi
echo executing "TOPP_FileInfo_14"
FileInfo -test -in FileInfo_14_input.mzid -v -no_progress -out FileInfo_14.tmp > TOPP_FileInfo_14.stdout 2> TOPP_FileInfo_14.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileInfo_14 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileInfo_14.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileInfo_14.stdout)";fi
echo executing "TOPP_FileInfo_15"
FileInfo -test -in FileInfo_15_input.mzid -v -no_progress -out FileInfo_15.tmp > TOPP_FileInfo_15.stdout 2> TOPP_FileInfo_15.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileInfo_15 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileInfo_15.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileInfo_15.stdout)";fi
echo executing "TOPP_FileInfo_16"
FileInfo -test -in FileInfo_16_input.trafoXML -out FileInfo_16_output.tmp > TOPP_FileInfo_16.stdout 2> TOPP_FileInfo_16.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileInfo_16 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileInfo_16.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileInfo_16.stdout)";fi
echo executing "TOPP_FileInfo_17"
FileInfo -test -in FileInfo_17_input.fasta -out FileInfo_17_output.tmp > TOPP_FileInfo_17.stdout 2> TOPP_FileInfo_17.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileInfo_17 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileInfo_17.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileInfo_17.stdout)";fi
echo executing "TOPP_FileInfo_18"
FileInfo -test -in FileInfo_18_input.fasta -out FileInfo_18_output.tmp > TOPP_FileInfo_18.stdout 2> TOPP_FileInfo_18.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileInfo_18 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileInfo_18.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileInfo_18.stdout)";fi
echo executing "TOPP_FileMerger_1"
FileMerger -test -in FileMerger_1_input1.dta2d FileMerger_1_input2.dta FileMerger_1_input3.dta2d -out FileMerger_1.tmp -raw:rt_custom 1 2 3 > TOPP_FileMerger_1.stdout 2> TOPP_FileMerger_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileMerger_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileMerger_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileMerger_1.stdout)";fi
echo executing "TOPP_FileMerger_2"
FileMerger -test -in FileMerger_2_input1.dta FileMerger_2_input2.dta -in_type dta -out FileMerger_2.tmp -raw:rt_custom 5 10 > TOPP_FileMerger_2.stdout 2> TOPP_FileMerger_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileMerger_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileMerger_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileMerger_2.stdout)";fi
echo executing "TOPP_FileMerger_3"
FileMerger -test -in FileMerger_3_input1.dta FileMerger_3_input2.dta -out FileMerger_3.tmp -raw:rt_auto > TOPP_FileMerger_3.stdout 2> TOPP_FileMerger_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileMerger_3 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileMerger_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileMerger_3.stdout)";fi
echo executing "TOPP_FileMerger_4"
FileMerger -test -in FileMerger_4_input1.dta2d FileMerger_4_input2.dta2d -out FileMerger_4.tmp > TOPP_FileMerger_4.stdout 2> TOPP_FileMerger_4.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileMerger_4 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileMerger_4.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileMerger_4.stdout)";fi
echo executing "TOPP_FileMerger_5"
FileMerger -test -in FileMerger_5_input_rt1023.331.dta FileMerger_5_input_rt2044.334.dta FileMerger_5_input_rt889.32.dta -raw:rt_filename -raw:ms_level 2 -out FileMerger_5.tmp > TOPP_FileMerger_5.stdout 2> TOPP_FileMerger_5.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileMerger_5 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileMerger_5.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileMerger_5.stdout)";fi
echo executing "TOPP_FileMerger_6"
FileMerger -test -in FileMerger_6_input1.mzML FileMerger_6_input2.mzML -out FileMerger_6.tmp > TOPP_FileMerger_6.stdout 2> TOPP_FileMerger_6.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileMerger_6 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileMerger_6.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileMerger_6.stdout)";fi
echo executing "TOPP_FileMerger_7"
FileMerger -test -in FileMerger_7_input1.featureXML FileMerger_7_input2.featureXML -out FileMerger_7.tmp > TOPP_FileMerger_7.stdout 2> TOPP_FileMerger_7.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileMerger_7 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileMerger_7.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileMerger_7.stdout)";fi
echo executing "TOPP_FileMerger_8"
FileMerger -test -in FileMerger_8_input1.consensusXML FileMerger_8_input2.consensusXML -out FileMerger_8.tmp > TOPP_FileMerger_8.stdout 2> TOPP_FileMerger_8.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileMerger_8 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileMerger_8.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileMerger_8.stdout)";fi
echo executing "TOPP_FileMerger_9"
FileMerger -test -in FileMerger_9_input1.traML FileMerger_9_input2.traML -out FileMerger_9.tmp > TOPP_FileMerger_9.stdout 2> TOPP_FileMerger_9.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileMerger_9 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileMerger_9.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileMerger_9.stdout)";fi
echo executing "TOPP_FileMerger_10"
FileMerger -test -in FileMerger_6_input2.mzML FileMerger_6_input2.mzML -out FileMerger_10_output.tmp -rt_concat:gap 10.0 -rt_concat:trafo_out FileMerger_10_trafo1.tmp FileMerger_10_trafo2.tmp > TOPP_FileMerger_10.stdout 2> TOPP_FileMerger_10.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileMerger_10 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileMerger_10.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileMerger_10.stdout)";fi
echo executing "TOPP_FileMerger_11"
FileMerger -test -in FileMerger_8_input1.consensusXML FileMerger_8_input2.consensusXML -append_method append_cols -out FileMerger_11.tmp > TOPP_FileMerger_11.stdout 2> TOPP_FileMerger_11.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FileMerger_11 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FileMerger_11.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FileMerger_11.stdout)";fi
echo executing "TOPP_GNPSExport_1"
GNPSExport -test -ini GNPSExport_1_mostint.ini -in_cm GNPSExport_cons1.consensusXML -in_mzml GNPSExport_mzml1.mzML GNPSExport_mzml2.mzML -out GNPSExport_1_out.tmp > TOPP_GNPSExport_1.stdout 2> TOPP_GNPSExport_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_GNPSExport_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_GNPSExport_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_GNPSExport_1.stdout)";fi
echo executing "TOPP_GNPSExport_2"
GNPSExport -test -ini GNPSExport_2_merged.ini -in_cm GNPSExport_cons1.consensusXML -in_mzml GNPSExport_mzml1.mzML GNPSExport_mzml2.mzML -out GNPSExport_2_out.tmp > TOPP_GNPSExport_2.stdout 2> TOPP_GNPSExport_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_GNPSExport_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_GNPSExport_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_GNPSExport_2.stdout)";fi
echo executing "TOPP_GNPSExport_3"
GNPSExport -test -ini GNPSExport_3_binsize.ini -in_cm GNPSExport_cons1.consensusXML -in_mzml GNPSExport_mzml1.mzML GNPSExport_mzml2.mzML -out GNPSExport_3_out.tmp > TOPP_GNPSExport_3.stdout 2> TOPP_GNPSExport_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_GNPSExport_3 failed'; >&2 echo -e "stderr:\n$(cat TOPP_GNPSExport_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_GNPSExport_3.stdout)";fi
echo executing "TOPP_HighResPrecursorMassCorrector_1"
HighResPrecursorMassCorrector -test -in HighResPrecursorMassCorrector_2860_1103_3.mzML -feature:in HighResPrecursorMassCorrector_2860_1103_3.featureXML -out HighResPrecursorMassCorrector_2860_1103_3_out.tmp > TOPP_HighResPrecursorMassCorrector_1.stdout 2> TOPP_HighResPrecursorMassCorrector_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_HighResPrecursorMassCorrector_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_HighResPrecursorMassCorrector_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_HighResPrecursorMassCorrector_1.stdout)";fi
echo executing "TOPP_HighResPrecursorMassCorrector_2"
HighResPrecursorMassCorrector -test -in HighResPrecursorMassCorrector_1035_1178_4.mzML -feature:in HighResPrecursorMassCorrector_1035_1178_4.featureXML -feature:max_trace 4 -feature:mz_tolerance 10 -out HighResPrecursorMassCorrector_1035_1178_4_out.tmp > TOPP_HighResPrecursorMassCorrector_2.stdout 2> TOPP_HighResPrecursorMassCorrector_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_HighResPrecursorMassCorrector_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_HighResPrecursorMassCorrector_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_HighResPrecursorMassCorrector_2.stdout)";fi
echo executing "TOPP_HighResPrecursorMassCorrector_3"
HighResPrecursorMassCorrector -test -in HighResPrecursorMassCorrector_2538_1091_2.mzML -feature:in HighResPrecursorMassCorrector_2538_1091_2.featureXML -out HighResPrecursorMassCorrector_2538_1091_2_out.tmp > TOPP_HighResPrecursorMassCorrector_3.stdout 2> TOPP_HighResPrecursorMassCorrector_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_HighResPrecursorMassCorrector_3 failed'; >&2 echo -e "stderr:\n$(cat TOPP_HighResPrecursorMassCorrector_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_HighResPrecursorMassCorrector_3.stdout)";fi
echo executing "TOPP_HighResPrecursorMassCorrector_4"
HighResPrecursorMassCorrector -test -in HighResPrecursorMassCorrector_2810_1091_3.mzML -feature:in HighResPrecursorMassCorrector_2810_1091_3.featureXML -out HighResPrecursorMassCorrector_2810_1091_3_out.tmp > TOPP_HighResPrecursorMassCorrector_4.stdout 2> TOPP_HighResPrecursorMassCorrector_4.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_HighResPrecursorMassCorrector_4 failed'; >&2 echo -e "stderr:\n$(cat TOPP_HighResPrecursorMassCorrector_4.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_HighResPrecursorMassCorrector_4.stdout)";fi
echo executing "TOPP_HighResPrecursorMassCorrector_5"
HighResPrecursorMassCorrector -test -in HighResPrecursorMassCorrector_3070_1191_3.mzML -feature:in HighResPrecursorMassCorrector_3070_1191_3.featureXML -out HighResPrecursorMassCorrector_3070_1191_3_out.tmp > TOPP_HighResPrecursorMassCorrector_5.stdout 2> TOPP_HighResPrecursorMassCorrector_5.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_HighResPrecursorMassCorrector_5 failed'; >&2 echo -e "stderr:\n$(cat TOPP_HighResPrecursorMassCorrector_5.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_HighResPrecursorMassCorrector_5.stdout)";fi
echo executing "TOPP_HighResPrecursorMassCorrector_6"
HighResPrecursorMassCorrector -test -in HighResPrecursorMassCorrector_6.mzML -highest_intensity_peak:mz_tolerance 0.2 -out HighResPrecursorMassCorrector_6_out.tmp > TOPP_HighResPrecursorMassCorrector_6.stdout 2> TOPP_HighResPrecursorMassCorrector_6.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_HighResPrecursorMassCorrector_6 failed'; >&2 echo -e "stderr:\n$(cat TOPP_HighResPrecursorMassCorrector_6.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_HighResPrecursorMassCorrector_6.stdout)";fi
echo executing "TOPP_IDRTCalibration_1"
IDRTCalibration -test -in IDRTCalibration_1_input.idXML -out IDRTCalibration_1_output.tmp -calibrant_1_input 10 -calibrant_2_input 90 > TOPP_IDRTCalibration_1.stdout 2> TOPP_IDRTCalibration_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDRTCalibration_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDRTCalibration_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDRTCalibration_1.stdout)";fi
echo executing "TOPP_IDRTCalibration_2"
IDRTCalibration -test -in degenerated_empty.idXML -out IDRTCalibration_2_output.tmp -calibrant_1_input 10 -calibrant_2_input 90 > TOPP_IDRTCalibration_2.stdout 2> TOPP_IDRTCalibration_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDRTCalibration_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDRTCalibration_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDRTCalibration_2.stdout)";fi
echo executing "TOPP_IDMassAccuracy_1"
IDMassAccuracy -test -in spectra.mzML -id_in MSGFPlusAdapter_1_out.idXML -number_of_bins 10 -out_fragment IDMassAccuracy_1_out_fragment.tsv -out_fragment_fit IDMassAccuracy_1_out_fragment_fit.tsv -out_precursor IDMassAccuracy_1_out_precursor.tsv -out_precursor_fit IDMassAccuracy_1_out_precursor_fit.tsv > TOPP_IDMassAccuracy_1.stdout 2> TOPP_IDMassAccuracy_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDMassAccuracy_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDMassAccuracy_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDMassAccuracy_1.stdout)";fi
echo executing "TOPP_IsobaricAnalyzer_1"
IsobaricAnalyzer -test -in IsobaricAnalyzer_input_1.mzML -ini IsobaricAnalyzer.ini -out IsobaricAnalyzer_output_1.tmp > TOPP_IsobaricAnalyzer_1.stdout 2> TOPP_IsobaricAnalyzer_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IsobaricAnalyzer_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IsobaricAnalyzer_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IsobaricAnalyzer_1.stdout)";fi
echo executing "TOPP_IsobaricAnalyzer_TMTTenPlexMethod_1"
IsobaricAnalyzer -test -in TMTTenPlexMethod_test.mzML -ini TMTTenPlexMethod_test.ini -out TMTTenPlexMethod_output.tmp > TOPP_IsobaricAnalyzer_TMTTenPlexMethod_1.stdout 2> TOPP_IsobaricAnalyzer_TMTTenPlexMethod_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IsobaricAnalyzer_TMTTenPlexMethod_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IsobaricAnalyzer_TMTTenPlexMethod_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IsobaricAnalyzer_TMTTenPlexMethod_1.stdout)";fi
echo executing "TOPP_IsobaricAnalyzer_TMTElevenPlexMethod_1"
IsobaricAnalyzer -test -in TMTTenPlexMethod_test.mzML -ini TMTElevenPlexMethod_test.ini -out TMTElevenPlexMethod_output.tmp > TOPP_IsobaricAnalyzer_TMTElevenPlexMethod_1.stdout 2> TOPP_IsobaricAnalyzer_TMTElevenPlexMethod_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IsobaricAnalyzer_TMTElevenPlexMethod_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IsobaricAnalyzer_TMTElevenPlexMethod_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IsobaricAnalyzer_TMTElevenPlexMethod_1.stdout)";fi
echo executing "TOPP_IsobaricAnalyzer_MS3TMT10Plex_1"
IsobaricAnalyzer -test -in MS3_nonHierarchical.mzML -extraction:select_activation "Collision-induced dissociation" -type tmt10plex -out MS3TMT10Plex_output.tmp > TOPP_IsobaricAnalyzer_MS3TMT10Plex_1.stdout 2> TOPP_IsobaricAnalyzer_MS3TMT10Plex_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IsobaricAnalyzer_MS3TMT10Plex_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IsobaricAnalyzer_MS3TMT10Plex_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IsobaricAnalyzer_MS3TMT10Plex_1.stdout)";fi
echo executing "TOPP_IDConflictResolver_1"
IDConflictResolver -test -in IDConflictResolver_1_input.featureXML -out IDConflictResolver_1_output.tmp > TOPP_IDConflictResolver_1.stdout 2> TOPP_IDConflictResolver_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDConflictResolver_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDConflictResolver_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDConflictResolver_1.stdout)";fi
echo executing "TOPP_IDConflictResolver_2"
IDConflictResolver -test -in IDConflictResolver_2_input.consensusXML -out IDConflictResolver_2_output.tmp > TOPP_IDConflictResolver_2.stdout 2> TOPP_IDConflictResolver_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDConflictResolver_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDConflictResolver_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDConflictResolver_2.stdout)";fi
echo executing "TOPP_IDConflictResolver_3"
IDConflictResolver -test -in IDConflictResolver_3_input.consensusXML -out IDConflictResolver_3_output.tmp > TOPP_IDConflictResolver_3.stdout 2> TOPP_IDConflictResolver_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDConflictResolver_3 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDConflictResolver_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDConflictResolver_3.stdout)";fi
echo executing "TOPP_IDConflictResolver_4"
IDConflictResolver -test -in IDConflictResolver_4_input.featureXML -resolve_between_features highest_intensity -out IDConflictResolver_4.tmp > TOPP_IDConflictResolver_4.stdout 2> TOPP_IDConflictResolver_4.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDConflictResolver_4 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDConflictResolver_4.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDConflictResolver_4.stdout)";fi
echo executing "TOPP_IDFileConverter_1"
IDFileConverter -test -in IDFileConverter_1_input1.mascotXML -mz_file IDFileConverter_1_input2.mzML -out IDFileConverter_1_output.tmp -out_type idXML > TOPP_IDFileConverter_1.stdout 2> TOPP_IDFileConverter_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDFileConverter_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDFileConverter_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDFileConverter_1.stdout)";fi
echo executing "TOPP_IDFileConverter_2"
IDFileConverter -test -in PepXMLFile_test.pepxml -mz_file PepXMLFile_test.mzML -mz_name PepXMLFile_test -out IDFileConverter_2_output.tmp -out_type idXML > TOPP_IDFileConverter_2.stdout 2> TOPP_IDFileConverter_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDFileConverter_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDFileConverter_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDFileConverter_2.stdout)";fi
echo executing "TOPP_IDFileConverter_3"
IDFileConverter -test -in IDFileConverter_3_input.protXML -out IDFileConverter_3_output.tmp -out_type idXML > TOPP_IDFileConverter_3.stdout 2> TOPP_IDFileConverter_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDFileConverter_3 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDFileConverter_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDFileConverter_3.stdout)";fi
echo executing "TOPP_IDFileConverter_5"
IDFileConverter -test -in IDFileConverter_1_input1.mascotXML -mz_file IDFileConverter_1_input2.mzML -out IDFileConverter_5_output.tmp -ini IDFileConverter_5_parameters.ini > TOPP_IDFileConverter_5.stdout 2> TOPP_IDFileConverter_5.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDFileConverter_5 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDFileConverter_5.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDFileConverter_5.stdout)";fi
echo executing "TOPP_IDFileConverter_6"
IDFileConverter -test -in IDFileConverter_6_input1.pepXML -mz_file IDFileConverter_1_input2.mzML -mz_name F025589.dat.mzML -out IDFileConverter_6_output.tmp -out_type idXML > TOPP_IDFileConverter_6.stdout 2> TOPP_IDFileConverter_6.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDFileConverter_6 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDFileConverter_6.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDFileConverter_6.stdout)";fi
echo executing "TOPP_IDFileConverter_7"
IDFileConverter -test -in IDFileConverter_7_input1.xml -out IDFileConverter_7_output.tmp -out_type idXML > TOPP_IDFileConverter_7.stdout 2> TOPP_IDFileConverter_7.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDFileConverter_7 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDFileConverter_7.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDFileConverter_7.stdout)";fi
echo executing "TOPP_IDFileConverter_8"
IDFileConverter -test -in IDFileConverter_8_input.mzid -out IDFileConverter_8_output.tmp -out_type idXML > TOPP_IDFileConverter_8.stdout 2> TOPP_IDFileConverter_8.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDFileConverter_8 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDFileConverter_8.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDFileConverter_8.stdout)";fi
echo executing "TOPP_IDFileConverter_9"
IDFileConverter -test -in IDFileConverter_9_input.idXML -out IDFileConverter_9_output.tmp -out_type mzid > TOPP_IDFileConverter_9.stdout 2> TOPP_IDFileConverter_9.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDFileConverter_9 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDFileConverter_9.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDFileConverter_9.stdout)";fi
echo executing "TOPP_IDFileConverter_10"
IDFileConverter -test -in IDFileConverter_10_input.pepXML -out IDFileConverter_10_output.tmp -out_type idXML > TOPP_IDFileConverter_10.stdout 2> TOPP_IDFileConverter_10.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDFileConverter_10 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDFileConverter_10.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDFileConverter_10.stdout)";fi
echo executing "TOPP_IDFileConverter_11"
IDFileConverter -test -in IDFileConverter_11_input.tsv -out IDFileConverter_11_output.tmp -out_type idXML > TOPP_IDFileConverter_11.stdout 2> TOPP_IDFileConverter_11.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDFileConverter_11 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDFileConverter_11.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDFileConverter_11.stdout)";fi
echo executing "TOPP_IDFileConverter_12"
IDFileConverter -test -in IDFileConverter_12_input.psms -out IDFileConverter_12_output.tmp -out_type idXML -score_type qvalue > TOPP_IDFileConverter_12.stdout 2> TOPP_IDFileConverter_12.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDFileConverter_12 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDFileConverter_12.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDFileConverter_12.stdout)";fi
echo executing "TOPP_IDFileConverter_13"
IDFileConverter -test -in IDFileConverter_12_input.psms -out IDFileConverter_13_output.tmp -out_type idXML -score_type PEP > TOPP_IDFileConverter_13.stdout 2> TOPP_IDFileConverter_13.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDFileConverter_13 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDFileConverter_13.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDFileConverter_13.stdout)";fi
echo executing "TOPP_IDFileConverter_14"
IDFileConverter -test -in IDFileConverter_12_input.psms -out IDFileConverter_14_output.tmp -out_type idXML -score_type score > TOPP_IDFileConverter_14.stdout 2> TOPP_IDFileConverter_14.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDFileConverter_14 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDFileConverter_14.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDFileConverter_14.stdout)";fi
echo executing "TOPP_IDFileConverter_15"
IDFileConverter -test -in MSGFPlusAdapter_1_out.mzid -out IDFileConverter_15_output.tmp -out_type idXML -mz_file spectra.mzML > TOPP_IDFileConverter_15.stdout 2> TOPP_IDFileConverter_15.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDFileConverter_15 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDFileConverter_15.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDFileConverter_15.stdout)";fi
echo executing "TOPP_IDFileConverter_16"
IDFileConverter -test -in IDFileConverter_16_input.pepXML -out IDFileConverter_16_output.tmp -out_type idXML > TOPP_IDFileConverter_16.stdout 2> TOPP_IDFileConverter_16.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDFileConverter_16 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDFileConverter_16.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDFileConverter_16.stdout)";fi
echo executing "TOPP_IDFileConverter_17"
IDFileConverter -test -in IDFileConverter_17_input.idXML -out IDFileConverter_17_output.tmp -out_type pepXML > TOPP_IDFileConverter_17.stdout 2> TOPP_IDFileConverter_17.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDFileConverter_17 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDFileConverter_17.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDFileConverter_17.stdout)";fi
echo executing "TOPP_IDFileConverter_18"
IDFileConverter -test -in IDFileConverter_18_input.idXML -out IDFileConverter_18_output.tmp -out_type pepXML > TOPP_IDFileConverter_18.stdout 2> TOPP_IDFileConverter_18.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDFileConverter_18 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDFileConverter_18.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDFileConverter_18.stdout)";fi
echo executing "TOPP_IDFileConverter_19"
IDFileConverter -test -in IDFileConverter_19_input.idXML -out IDFileConverter_19_output.tmp -out_type pepXML > TOPP_IDFileConverter_19.stdout 2> TOPP_IDFileConverter_19.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDFileConverter_19 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDFileConverter_19.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDFileConverter_19.stdout)";fi
echo executing "TOPP_IDFileConverter_20"
IDFileConverter -test -in IDFileConverter_20_input.idXML -out IDFileConverter_20_output.tmp -out_type pepXML > TOPP_IDFileConverter_20.stdout 2> TOPP_IDFileConverter_20.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDFileConverter_20 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDFileConverter_20.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDFileConverter_20.stdout)";fi
echo executing "TOPP_IDFileConverter_21"
IDFileConverter -test -in IDFileConverter_21_input.idXML -out_type idXML -out IDFileConverter_21_output.tmp -mz_file IDMapper_4_input.mzML > TOPP_IDFileConverter_21.stdout 2> TOPP_IDFileConverter_21.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDFileConverter_21 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDFileConverter_21.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDFileConverter_21.stdout)";fi
echo executing "TOPP_IDFileConverter_22"
IDFileConverter -test -in MSGFPlusAdapter_1_out.mzid -out IDFileConverter_22_output.tmp -out_type idXML -mz_file spectra.mzML -add_ionmatch_annotation 0.01 > TOPP_IDFileConverter_22.stdout 2> TOPP_IDFileConverter_22.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDFileConverter_22 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDFileConverter_22.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDFileConverter_22.stdout)";fi
echo executing "TOPP_IDFileConverter_23"
IDFileConverter -test -in IDFileConverter_23_input.mzid -out IDFileConverter_23_output.tmp -out_type idXML > TOPP_IDFileConverter_23.stdout 2> TOPP_IDFileConverter_23.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDFileConverter_23 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDFileConverter_23.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDFileConverter_23.stdout)";fi
echo executing "TOPP_IDFileConverter_24"
IDFileConverter -test -in IDFileConverter_24_input.pep.xml -out IDFileConverter_24_output.tmp -out_type idXML > TOPP_IDFileConverter_24.stdout 2> TOPP_IDFileConverter_24.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDFileConverter_24 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDFileConverter_24.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDFileConverter_24.stdout)";fi
echo executing "TOPP_IDFileConverter_25"
IDFileConverter -test -in IDFileConverter_25_input.idXML -out IDFileConverter_25_output.tmp -out_type pepXML > TOPP_IDFileConverter_25.stdout 2> TOPP_IDFileConverter_25.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDFileConverter_25 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDFileConverter_25.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDFileConverter_25.stdout)";fi
echo executing "TOPP_IDFileConverter_26"
IDFileConverter -test -in IDFileConverter_26_input.mzid -out IDFileConverter_26_output.tmp -out_type idXML > TOPP_IDFileConverter_26.stdout 2> TOPP_IDFileConverter_26.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDFileConverter_26 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDFileConverter_26.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDFileConverter_26.stdout)";fi
echo executing "TOPP_IDFileConverter_27"
IDFileConverter -test -in IDFileConverter_27_input.idXML -out IDFileConverter_27_output.tmp -out_type fasta > TOPP_IDFileConverter_27.stdout 2> TOPP_IDFileConverter_27.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDFileConverter_27 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDFileConverter_27.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDFileConverter_27.stdout)";fi
echo executing "TOPP_IDFileConverter_28"
IDFileConverter -test -in IDFileConverter_27_input.idXML -out IDFileConverter_28_output.tmp -out_type fasta -number_of_hits -1 > TOPP_IDFileConverter_28.stdout 2> TOPP_IDFileConverter_28.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDFileConverter_28 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDFileConverter_28.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDFileConverter_28.stdout)";fi
echo executing "TOPP_IDFileConverter_29"
IDFileConverter -test -in IDFileConverter_27_input.idXML -out IDFileConverter_29_output.tmp -out_type fasta -concatenate_peptides > TOPP_IDFileConverter_29.stdout 2> TOPP_IDFileConverter_29.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDFileConverter_29 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDFileConverter_29.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDFileConverter_29.stdout)";fi
echo executing "TOPP_IDFileConverter_30"
IDFileConverter -test -in IDFileConverter_27_input.idXML -out IDFileConverter_30_output.tmp -out_type fasta -concatenate_peptides -number_of_hits 2 > TOPP_IDFileConverter_30.stdout 2> TOPP_IDFileConverter_30.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDFileConverter_30 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDFileConverter_30.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDFileConverter_30.stdout)";fi
echo executing "TOPP_IDFileConverter_31"
IDFileConverter -test -in IDFileConverter_31_input.mzid -out IDFileConverter_31_output.tmp -out_type idXML > TOPP_IDFileConverter_31.stdout 2> TOPP_IDFileConverter_31.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDFileConverter_31 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDFileConverter_31.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDFileConverter_31.stdout)";fi
echo executing "TOPP_IDFileConverter_32"
IDFileConverter -test -in IDFileConverter_32_input.FASTA -out IDFileConverter_32_output.tmp -out_type mzML > TOPP_IDFileConverter_32.stdout 2> TOPP_IDFileConverter_32.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDFileConverter_32 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDFileConverter_32.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDFileConverter_32.stdout)";fi
echo executing "TOPP_IDFileConverter_32_File_Conversion"
FileConverter -test -in IDFileConverter_32_output.tmp -out IDFileConverter_32_output_mgf.tmp -out_type mgf > TOPP_IDFileConverter_32_File_Conversion.stdout 2> TOPP_IDFileConverter_32_File_Conversion.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDFileConverter_32_File_Conversion failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDFileConverter_32_File_Conversion.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDFileConverter_32_File_Conversion.stdout)";fi
echo executing "TOPP_IDFileConverter_33"
IDFileConverter -test -in IDFileConverter_32_input.FASTA -out IDFileConverter_33_output.tmp -out_type mzML -fasta_to_mzml:missed_cleavages 1 -fasta_to_mzml:precursor_charge 3 > TOPP_IDFileConverter_33.stdout 2> TOPP_IDFileConverter_33.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDFileConverter_33 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDFileConverter_33.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDFileConverter_33.stdout)";fi
echo executing "TOPP_IDFileConverter_33_File_Conversion"
FileConverter -test -in IDFileConverter_33_output.tmp -out IDFileConverter_33_output_mgf.tmp -out_type mgf > TOPP_IDFileConverter_33_File_Conversion.stdout 2> TOPP_IDFileConverter_33_File_Conversion.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDFileConverter_33_File_Conversion failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDFileConverter_33_File_Conversion.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDFileConverter_33_File_Conversion.stdout)";fi
echo executing "TOPP_IDFileConverter_34_1"
IDFileConverter -test -in IDFileConverter_34_input.idXML -out IDFileConverter_34_output1.oms > TOPP_IDFileConverter_34_1.stdout 2> TOPP_IDFileConverter_34_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDFileConverter_34_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDFileConverter_34_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDFileConverter_34_1.stdout)";fi
echo executing "TOPP_IDFileConverter_34_2"
IDFileConverter -test -in IDFileConverter_34_output1.oms -out IDFileConverter_34_output2.tmp -out_type idXML > TOPP_IDFileConverter_34_2.stdout 2> TOPP_IDFileConverter_34_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDFileConverter_34_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDFileConverter_34_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDFileConverter_34_2.stdout)";fi
echo executing "TOPP_IDFilter_1"
IDFilter -test -in IDFilter_1_input.idXML -out IDFilter_1_output.tmp -whitelist:proteins IDFilter_1_input.fas > TOPP_IDFilter_1.stdout 2> TOPP_IDFilter_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDFilter_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDFilter_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDFilter_1.stdout)";fi
echo executing "TOPP_IDFilter_3"
IDFilter -test -in IDFilter_3_input.idXML -out IDFilter_3_output.tmp -blacklist:peptides IDFilter_3_2_input.idXML > TOPP_IDFilter_3.stdout 2> TOPP_IDFilter_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDFilter_3 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDFilter_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDFilter_3.stdout)";fi
echo executing "TOPP_IDFilter_4"
IDFilter -test -in IDFilter_4_input.idXML -out IDFilter_4_output.tmp -rt:p_value 0.08 > TOPP_IDFilter_4.stdout 2> TOPP_IDFilter_4.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDFilter_4 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDFilter_4.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDFilter_4.stdout)";fi
echo executing "TOPP_IDFilter_5"
IDFilter -test -in IDFilter_5_input.idXML -out IDFilter_5_output.tmp -score:pep 32 -score:prot 25 > TOPP_IDFilter_5.stdout 2> TOPP_IDFilter_5.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDFilter_5 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDFilter_5.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDFilter_5.stdout)";fi
echo executing "TOPP_IDFilter_5a"
IDFilter -test -in IDFilter_5_input.idXML -out IDFilter_5a_output.tmp -score:pep 32  > TOPP_IDFilter_5a.stdout 2> TOPP_IDFilter_5a.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDFilter_5a failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDFilter_5a.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDFilter_5a.stdout)";fi
echo executing "TOPP_IDFilter_5b"
IDFilter -test -in IDFilter_5_input.idXML -out IDFilter_5b_output.tmp -score:prot 25 > TOPP_IDFilter_5b.stdout 2> TOPP_IDFilter_5b.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDFilter_5b failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDFilter_5b.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDFilter_5b.stdout)";fi
echo executing "TOPP_IDFilter_5c"
IDFilter -test -in IDFilter_5_input.idXML -out IDFilter_5c_output.tmp -score:prot 25 -delete_unreferenced_peptide_hits > TOPP_IDFilter_5c.stdout 2> TOPP_IDFilter_5c.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDFilter_5c failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDFilter_5c.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDFilter_5c.stdout)";fi
echo executing "TOPP_IDFilter_6"
IDFilter -test -in IDFilter_6_input.idXML -out IDFilter_6_output.tmp -best:n_peptide_hits 2 -best:n_protein_hits 10 > TOPP_IDFilter_6.stdout 2> TOPP_IDFilter_6.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDFilter_6 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDFilter_6.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDFilter_6.stdout)";fi
echo executing "TOPP_IDFilter_7"
IDFilter -test -in IDFilter_7_input.idXML -out IDFilter_7_output.tmp -remove_duplicate_psm > TOPP_IDFilter_7.stdout 2> TOPP_IDFilter_7.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDFilter_7 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDFilter_7.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDFilter_7.stdout)";fi
echo executing "TOPP_IDFilter_8"
IDFilter -test -in IDFilter_8_input.idXML -out IDFilter_8_output.tmp -precursor:rt 200:350 -precursor:mz 999:1000 > TOPP_IDFilter_8.stdout 2> TOPP_IDFilter_8.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDFilter_8 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDFilter_8.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDFilter_8.stdout)";fi
echo executing "TOPP_IDFilter_9"
IDFilter -test -in IDFilter_9_input.idXML -out IDFilter_9_output.tmp -score:pep 0.05 > TOPP_IDFilter_9.stdout 2> TOPP_IDFilter_9.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDFilter_9 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDFilter_9.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDFilter_9.stdout)";fi
echo executing "TOPP_IDFilter_10"
IDFilter -test -in IDFilter_10_input.idXML -out IDFilter_10_output.tmp -score:prot 0.3 -delete_unreferenced_peptide_hits > TOPP_IDFilter_10.stdout 2> TOPP_IDFilter_10.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDFilter_10 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDFilter_10.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDFilter_10.stdout)";fi
echo executing "TOPP_IDFilter_11"
IDFilter -test -in IDFilter_11_input.idXML -out IDFilter_11_output.tmp -remove_decoys -delete_unreferenced_peptide_hits > TOPP_IDFilter_11.stdout 2> TOPP_IDFilter_11.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDFilter_11 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDFilter_11.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDFilter_11.stdout)";fi
echo executing "TOPP_IDFilter_12"
IDFilter -test -in IDFilter_12_input.idXML -out IDFilter_12_output.tmp -in_silico_digestion:fasta IDFilter_12_input.fasta > TOPP_IDFilter_12.stdout 2> TOPP_IDFilter_12.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDFilter_12 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDFilter_12.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDFilter_12.stdout)";fi
echo executing "TOPP_IDFilter_13"
IDFilter -test -in IDFilter_13_input.idXML -out IDFilter_13_output.tmp -in_silico_digestion:fasta IDFilter_13_input.fasta -in_silico_digestion:missed_cleavages 1 > TOPP_IDFilter_13.stdout 2> TOPP_IDFilter_13.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDFilter_13 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDFilter_13.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDFilter_13.stdout)";fi
echo executing "TOPP_IDFilter_14"
IDFilter -test -in IDFilter_14_input.idXML -out IDFilter_14_output.tmp -in_silico_digestion:fasta IDFilter_14_input.fasta -in_silico_digestion:enzyme Trypsin/P -in_silico_digestion:missed_cleavages 1 > TOPP_IDFilter_14.stdout 2> TOPP_IDFilter_14.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDFilter_14 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDFilter_14.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDFilter_14.stdout)";fi
echo executing "TOPP_IDFilter_15"
IDFilter -test -in IDFilter_15_input.idXML -out IDFilter_15_output.tmp -in_silico_digestion:fasta IDFilter_15_input.fasta -in_silico_digestion:enzyme Trypsin/P -in_silico_digestion:missed_cleavages 1 -in_silico_digestion:specificity semi > TOPP_IDFilter_15.stdout 2> TOPP_IDFilter_15.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDFilter_15 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDFilter_15.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDFilter_15.stdout)";fi
echo executing "TOPP_IDFilter_16"
IDFilter -test -in IDFilter_16_input.idXML -out IDFilter_16_output.tmp -in_silico_digestion:fasta IDFilter_16_input.fasta -in_silico_digestion:enzyme Trypsin/P -in_silico_digestion:missed_cleavages 1 -in_silico_digestion:methionine_cleavage > TOPP_IDFilter_16.stdout 2> TOPP_IDFilter_16.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDFilter_16 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDFilter_16.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDFilter_16.stdout)";fi
echo executing "TOPP_IDFilter_17"
IDFilter -test -in IDFilter_missed_cleavages_input.idXML -out IDFilter_17_output.tmp -missed_cleavages:enzyme Lys-N -missed_cleavages:number_of_missed_cleavages :2 > TOPP_IDFilter_17.stdout 2> TOPP_IDFilter_17.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDFilter_17 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDFilter_17.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDFilter_17.stdout)";fi
echo executing "TOPP_IDFilter_18"
IDFilter -test -in IDFilter_missed_cleavages_input.idXML -out IDFilter_18_output.tmp -missed_cleavages:enzyme Lys-N -missed_cleavages:number_of_missed_cleavages 2: > TOPP_IDFilter_18.stdout 2> TOPP_IDFilter_18.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDFilter_18 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDFilter_18.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDFilter_18.stdout)";fi
echo executing "TOPP_IDFilter_19"
IDFilter -test -in IDFilter_missed_cleavages_input.idXML -out IDFilter_19_output.tmp -missed_cleavages:enzyme Lys-N -missed_cleavages:number_of_missed_cleavages 1:3 > TOPP_IDFilter_19.stdout 2> TOPP_IDFilter_19.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDFilter_19 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDFilter_19.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDFilter_19.stdout)";fi
echo executing "TOPP_IDFilter_20"
IDFilter -test -in IDFilter_missed_cleavages_input.idXML -out IDFilter_20_output.tmp -missed_cleavages:number_of_missed_cleavages 1:0 > TOPP_IDFilter_20.stdout 2> TOPP_IDFilter_20.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDFilter_20 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDFilter_20.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDFilter_20.stdout)";fi
echo executing "TOPP_IDFilter_21"
IDFilter -test -in IDFilter_16_input.idXML -out IDFilter_21_output.tmp -remove_peptide_hits_by_metavalue "calcMZ" "gt" "750.0" > TOPP_IDFilter_21.stdout 2> TOPP_IDFilter_21.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDFilter_21 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDFilter_21.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDFilter_21.stdout)";fi
echo executing "TOPP_IDFilter_22"
IDFilter -test -in IDFilter_16_input.idXML -out IDFilter_22_output.tmp -remove_peptide_hits_by_metavalue "end" "ne" "23" > TOPP_IDFilter_22.stdout 2> TOPP_IDFilter_22.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDFilter_22 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDFilter_22.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDFilter_22.stdout)";fi
echo executing "TOPP_IDFilter_23"
IDFilter -test -in IDMapper_2_output.consensusXML -out IDFilter_23_output.tmp -whitelist:protein_accessions "Q9HP81" > TOPP_IDFilter_23.stdout 2> TOPP_IDFilter_23.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDFilter_23 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDFilter_23.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDFilter_23.stdout)";fi
echo executing "TOPP_IDFilter_24"
IDFilter -test -in Epifany_3_out.consensusXML -out IDFilter_24_output.tmp -score:protgroup 0.99 > TOPP_IDFilter_24.stdout 2> TOPP_IDFilter_24.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDFilter_24 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDFilter_24.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDFilter_24.stdout)";fi
echo executing "TOPP_MapAlignerPoseClustering_1"
MapAlignerPoseClustering -test -ini MapAlignerPoseClustering_1_parameters.ini -in MapAlignerPoseClustering_1_input1.featureXML MapAlignerPoseClustering_1_input2.featureXML MapAlignerPoseClustering_1_input3.featureXML -out MapAlignerPoseClustering_1_output1.tmp MapAlignerPoseClustering_1_output2.tmp MapAlignerPoseClustering_1_output3.tmp -trafo_out MapAlignerPoseClustering_1_trafo1.tmp MapAlignerPoseClustering_1_trafo2.tmp MapAlignerPoseClustering_1_trafo3.tmp > TOPP_MapAlignerPoseClustering_1.stdout 2> TOPP_MapAlignerPoseClustering_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_MapAlignerPoseClustering_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_MapAlignerPoseClustering_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_MapAlignerPoseClustering_1.stdout)";fi
echo executing "TOPP_MapAlignerPoseClustering_2"
MapAlignerPoseClustering -test -ini MapAlignerPoseClustering_2_parameters.ini -in MapAlignerPoseClustering_2_input1.mzML MapAlignerPoseClustering_2_input2.mzML MapAlignerPoseClustering_2_input3.mzML -out MapAlignerPoseClustering_2_output1.tmp MapAlignerPoseClustering_2_output2.tmp MapAlignerPoseClustering_2_output3.tmp > TOPP_MapAlignerPoseClustering_2.stdout 2> TOPP_MapAlignerPoseClustering_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_MapAlignerPoseClustering_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_MapAlignerPoseClustering_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_MapAlignerPoseClustering_2.stdout)";fi
echo executing "TOPP_MapAlignerPoseClustering_3"
MapAlignerPoseClustering -test -ini MapAlignerPoseClustering_1_parameters.ini -in MapAlignerPoseClustering_1_input2.featureXML MapAlignerPoseClustering_1_input3.featureXML -out MapAlignerPoseClustering_3_output1.tmp MapAlignerPoseClustering_3_output2.tmp -reference:file MapAlignerPoseClustering_1_input1.featureXML > TOPP_MapAlignerPoseClustering_3.stdout 2> TOPP_MapAlignerPoseClustering_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_MapAlignerPoseClustering_3 failed'; >&2 echo -e "stderr:\n$(cat TOPP_MapAlignerPoseClustering_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_MapAlignerPoseClustering_3.stdout)";fi
echo executing "TOPP_MapAlignerPoseClustering_4"
MapAlignerPoseClustering -test -ini MapAlignerPoseClustering_1_parameters.ini -in MapAlignerPoseClustering_1_input1.featureXML MapAlignerPoseClustering_1_input2.featureXML -trafo_out MapAlignerPoseClustering_4_trafo1.tmp MapAlignerPoseClustering_4_trafo2.tmp -reference:index 2 > TOPP_MapAlignerPoseClustering_4.stdout 2> TOPP_MapAlignerPoseClustering_4.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_MapAlignerPoseClustering_4 failed'; >&2 echo -e "stderr:\n$(cat TOPP_MapAlignerPoseClustering_4.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_MapAlignerPoseClustering_4.stdout)";fi
echo executing "TOPP_MapAlignerIdentification_1"
MapAlignerIdentification -test -ini MapAlignerIdentification_parameters.ini -in MapAlignerIdentification_1_input1.featureXML MapAlignerIdentification_1_input2.featureXML -out MapAlignerIdentification_1_output1.tmp MapAlignerIdentification_1_output2.tmp > TOPP_MapAlignerIdentification_1.stdout 2> TOPP_MapAlignerIdentification_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_MapAlignerIdentification_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_MapAlignerIdentification_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_MapAlignerIdentification_1.stdout)";fi
echo executing "TOPP_MapAlignerIdentification_2"
MapAlignerIdentification -test -ini MapAlignerIdentification_parameters.ini -in MapAlignerIdentification_1_input1.featureXML -out MapAlignerIdentification_2_output1.tmp -reference:file MapAlignerIdentification_1_input2.featureXML > TOPP_MapAlignerIdentification_2.stdout 2> TOPP_MapAlignerIdentification_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_MapAlignerIdentification_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_MapAlignerIdentification_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_MapAlignerIdentification_2.stdout)";fi
echo executing "TOPP_MapAlignerIdentification_3"
MapAlignerIdentification -test -ini MapAlignerIdentification_parameters.ini -in MapAlignerIdentification_1_input2.featureXML MapAlignerIdentification_1_input1.featureXML -out MapAlignerIdentification_3_output1.tmp MapAlignerIdentification_3_output2.tmp -reference:index 1 > TOPP_MapAlignerIdentification_3.stdout 2> TOPP_MapAlignerIdentification_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_MapAlignerIdentification_3 failed'; >&2 echo -e "stderr:\n$(cat TOPP_MapAlignerIdentification_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_MapAlignerIdentification_3.stdout)";fi
echo executing "TOPP_MapAlignerIdentification_4"
MapAlignerIdentification -test -ini MapAlignerIdentification_parameters.ini -in  MapAlignerIdentification_1_input1.featureXML MapAlignerIdentification_1_input2.featureXML -out MapAlignerIdentification_4_output1.tmp MapAlignerIdentification_4_output2.tmp -reference:index 2 > TOPP_MapAlignerIdentification_4.stdout 2> TOPP_MapAlignerIdentification_4.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_MapAlignerIdentification_4 failed'; >&2 echo -e "stderr:\n$(cat TOPP_MapAlignerIdentification_4.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_MapAlignerIdentification_4.stdout)";fi
echo executing "TOPP_MapAlignerIdentification_5"
MapAlignerIdentification -test -ini MapAlignerIdentification_parameters.ini -in MapAlignerIdentification_5_input1.consensusXML MapAlignerIdentification_5_input2.consensusXML -out MapAlignerIdentification_5_output1.tmp MapAlignerIdentification_5_output2.tmp > TOPP_MapAlignerIdentification_5.stdout 2> TOPP_MapAlignerIdentification_5.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_MapAlignerIdentification_5 failed'; >&2 echo -e "stderr:\n$(cat TOPP_MapAlignerIdentification_5.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_MapAlignerIdentification_5.stdout)";fi
echo executing "TOPP_MapAlignerIdentification_6"
MapAlignerIdentification -test -ini MapAlignerIdentification_parameters.ini -in MapAlignerIdentification_1_input1.featureXML -trafo_out MapAlignerIdentification_6_output1.tmp -reference:file MapAlignerIdentification_1_input2.featureXML > TOPP_MapAlignerIdentification_6.stdout 2> TOPP_MapAlignerIdentification_6.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_MapAlignerIdentification_6 failed'; >&2 echo -e "stderr:\n$(cat TOPP_MapAlignerIdentification_6.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_MapAlignerIdentification_6.stdout)";fi
echo executing "TOPP_MapAlignerIdentification_7"
MapAlignerIdentification -test -in MapAlignerIdentification_7_input1.idXML -out MapAlignerIdentification_7_output1.tmp -trafo_out MapAlignerIdentification_7_output2.tmp -reference:file MapAlignerIdentification_7_input2.idXML -force > TOPP_MapAlignerIdentification_7.stdout 2> TOPP_MapAlignerIdentification_7.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_MapAlignerIdentification_7 failed'; >&2 echo -e "stderr:\n$(cat TOPP_MapAlignerIdentification_7.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_MapAlignerIdentification_7.stdout)";fi
echo executing "TOPP_MapAlignerIdentification_8"
MapAlignerIdentification -test -in MapAlignerIdentification_8_input1.oms -trafo_out MapAlignerIdentification_8_output1.tmp -out MapAlignerIdentification_8_output2.tmp -reference:file MapAlignerIdentification_8_input2.oms -store_original_rt > TOPP_MapAlignerIdentification_8.stdout 2> TOPP_MapAlignerIdentification_8.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_MapAlignerIdentification_8 failed'; >&2 echo -e "stderr:\n$(cat TOPP_MapAlignerIdentification_8.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_MapAlignerIdentification_8.stdout)";fi
echo executing "TOPP_MapAlignerSpectrum_1"
MapAlignerSpectrum -test -ini MapAlignerSpectrum_parameters.ini -in MapAlignerSpectrum_1_input1.mzML MapAlignerSpectrum_1_input2.mzML MapAlignerSpectrum_1_input3.mzML -out MapAlignerSpectrum_1_output1.tmp MapAlignerSpectrum_1_output2.tmp MapAlignerSpectrum_1_output3.tmp > TOPP_MapAlignerSpectrum_1.stdout 2> TOPP_MapAlignerSpectrum_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_MapAlignerSpectrum_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_MapAlignerSpectrum_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_MapAlignerSpectrum_1.stdout)";fi
echo executing "TOPP_MapAlignerTreeGuided_1"
MapAlignerTreeGuided -test -ini MapAlignerTreeGuided_parameters.ini -in MapAlignerTreeGuided_1_input1.featureXML MapAlignerTreeGuided_1_input2.featureXML MapAlignerTreeGuided_1_input3.featureXML -out MapAlignerTreeGuided_1_output1.tmp MapAlignerTreeGuided_1_output2.tmp MapAlignerTreeGuided_1_output3.tmp > TOPP_MapAlignerTreeGuided_1.stdout 2> TOPP_MapAlignerTreeGuided_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_MapAlignerTreeGuided_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_MapAlignerTreeGuided_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_MapAlignerTreeGuided_1.stdout)";fi
echo executing "TOPP_MapAlignerTreeGuided_2"
MapAlignerTreeGuided -test -ini MapAlignerTreeGuided_parameters.ini -in MapAlignerTreeGuided_1_input1.featureXML MapAlignerTreeGuided_1_input2.featureXML MapAlignerTreeGuided_1_input3.featureXML -trafo_out MapAlignerTreeGuided_2_output1.tmp MapAlignerTreeGuided_2_output2.tmp MapAlignerTreeGuided_2_output3.tmp > TOPP_MapAlignerTreeGuided_2.stdout 2> TOPP_MapAlignerTreeGuided_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_MapAlignerTreeGuided_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_MapAlignerTreeGuided_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_MapAlignerTreeGuided_2.stdout)";fi
echo executing "TOPP_MapAlignerTreeGuided_3"
MapAlignerTreeGuided -test -ini MapAlignerTreeGuided_parameters2.ini -in MapAlignerTreeGuided_1_input1.featureXML MapAlignerTreeGuided_1_input2.featureXML MapAlignerTreeGuided_1_input3.featureXML -out MapAlignerTreeGuided_3_output1.tmp MapAlignerTreeGuided_3_output2.tmp MapAlignerTreeGuided_3_output3.tmp > TOPP_MapAlignerTreeGuided_3.stdout 2> TOPP_MapAlignerTreeGuided_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_MapAlignerTreeGuided_3 failed'; >&2 echo -e "stderr:\n$(cat TOPP_MapAlignerTreeGuided_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_MapAlignerTreeGuided_3.stdout)";fi
echo executing "TOPP_MapRTTransformer_1"
MapRTTransformer -test -in MapRTTransformer_1_input.featureXML -trafo_in MapRTTransformer_trafo_linear.trafoXML -out MapRTTransformer_1_output.tmp > TOPP_MapRTTransformer_1.stdout 2> TOPP_MapRTTransformer_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_MapRTTransformer_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_MapRTTransformer_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_MapRTTransformer_1.stdout)";fi
echo executing "TOPP_MapRTTransformer_2"
MapRTTransformer -test -in MapRTTransformer_2_input.mzML -trafo_in MapRTTransformer_trafo_linear.trafoXML -out MapRTTransformer_2_output.tmp > TOPP_MapRTTransformer_2.stdout 2> TOPP_MapRTTransformer_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_MapRTTransformer_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_MapRTTransformer_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_MapRTTransformer_2.stdout)";fi
echo executing "TOPP_MapRTTransformer_3"
MapRTTransformer -test -invert -trafo_in MapAlignerPoseClustering_1_trafo2.trafoXML -trafo_out MapRTTransformer_3_output.tmp > TOPP_MapRTTransformer_3.stdout 2> TOPP_MapRTTransformer_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_MapRTTransformer_3 failed'; >&2 echo -e "stderr:\n$(cat TOPP_MapRTTransformer_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_MapRTTransformer_3.stdout)";fi
echo executing "TOPP_MapRTTransformer_4"
MapRTTransformer -test -in MapRTTransformer_4_input.chrom.mzML -trafo_in MapRTTransformer_trafo_linear.trafoXML -out MapRTTransformer_4_output.tmp > TOPP_MapRTTransformer_4.stdout 2> TOPP_MapRTTransformer_4.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_MapRTTransformer_4 failed'; >&2 echo -e "stderr:\n$(cat TOPP_MapRTTransformer_4.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_MapRTTransformer_4.stdout)";fi
echo executing "TOPP_MapRTTransformer_5"
MapRTTransformer -test -in MapRTTransformer_1_input.featureXML -trafo_in MapRTTransformer_trafo_none.trafoXML -out MapRTTransformer_5_output.tmp > TOPP_MapRTTransformer_5.stdout 2> TOPP_MapRTTransformer_5.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_MapRTTransformer_5 failed'; >&2 echo -e "stderr:\n$(cat TOPP_MapRTTransformer_5.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_MapRTTransformer_5.stdout)";fi
echo executing "TOPP_MapRTTransformer_6"
MapRTTransformer -test -in MapRTTransformer_1_input.featureXML -trafo_in MapRTTransformer_trafo_linear.trafoXML -out MapRTTransformer_6_output.tmp -store_original_rt > TOPP_MapRTTransformer_6.stdout 2> TOPP_MapRTTransformer_6.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_MapRTTransformer_6 failed'; >&2 echo -e "stderr:\n$(cat TOPP_MapRTTransformer_6.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_MapRTTransformer_6.stdout)";fi
echo executing "TOPP_MetaProSIP_1"
MetaProSIP -test -in_mzML MetaProSIP_1_input.mzML -in_fasta MetaProSIP_1_input.fasta -in_featureXML MetaProSIP_1_input.featureXML -out_csv MetaProSIP_1_output_1.tmp -out_peptide_centric_csv MetaProSIP_1_output_2.tmp > TOPP_MetaProSIP_1.stdout 2> TOPP_MetaProSIP_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_MetaProSIP_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_MetaProSIP_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_MetaProSIP_1.stdout)";fi
echo executing "TOPP_MascotAdapter_1"
MascotAdapter -test -ini MascotAdapter_1_parameters.ini -in MascotAdapter_1_input.mzData -out MascotAdapter_1_output.tmp -out_type mgf > TOPP_MascotAdapter_1.stdout 2> TOPP_MascotAdapter_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_MascotAdapter_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_MascotAdapter_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_MascotAdapter_1.stdout)";fi
echo executing "TOPP_MascotAdapter_2"
MascotAdapter -test -in MascotAdapter_2_input.mascotXML -out MascotAdapter_2_output.tmp -out_type idXML > TOPP_MascotAdapter_2.stdout 2> TOPP_MascotAdapter_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_MascotAdapter_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_MascotAdapter_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_MascotAdapter_2.stdout)";fi
echo executing "TOPP_MetaboliteAdductDecharger_1"
MetaboliteAdductDecharger -test -in MetaboliteAdductDecharger_input.featureXML -out_fm MetaboliteAdductDecharger_1_output.tmp > TOPP_MetaboliteAdductDecharger_1.stdout 2> TOPP_MetaboliteAdductDecharger_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_MetaboliteAdductDecharger_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_MetaboliteAdductDecharger_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_MetaboliteAdductDecharger_1.stdout)";fi
echo executing "TOPP_MetaboliteAdductDecharger_2"
MetaboliteAdductDecharger -test -in MetaboliteAdductDecharger_input.featureXML -out_cm MetaboliteAdductDecharger_2_output_1.tmp -outpairs MetaboliteAdductDecharger_2_output_2.tmp > TOPP_MetaboliteAdductDecharger_2.stdout 2> TOPP_MetaboliteAdductDecharger_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_MetaboliteAdductDecharger_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_MetaboliteAdductDecharger_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_MetaboliteAdductDecharger_2.stdout)";fi
echo executing "TOPP_MSstatsConverter_1"
MSstatsConverter -test -in MSstatsConverter_1_in.consensusXML -retention_time_summarization_method max -in_design MSstatsConverter_1_design.tsv -out MSstatsConverter_1_out.tmp > TOPP_MSstatsConverter_1.stdout 2> TOPP_MSstatsConverter_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_MSstatsConverter_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_MSstatsConverter_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_MSstatsConverter_1.stdout)";fi
echo executing "TOPP_MSstatsConverter_2"
MSstatsConverter -test -in MSstatsConverter_2_in.consensusXML -method "ISO" -retention_time_summarization_method manual -in_design MSstatsConverter_2_design.tsv -out MSstatsConverter_2_out.tmp -msstats_bioreplicate MSstats_BioReplicate -msstats_condition MSstats_Condition -msstats_mixture MSstats_Mixture > TOPP_MSstatsConverter_2.stdout 2> TOPP_MSstatsConverter_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_MSstatsConverter_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_MSstatsConverter_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_MSstatsConverter_2.stdout)";fi
echo executing "TOPP_MSstatsConverter_3"
MSstatsConverter -test -in MSstatsConverter_3_in.consensusXML -method "ISO" -retention_time_summarization_method manual -in_design MSstatsConverter_3_design.tsv -out MSstatsConverter_3_out.tmp -msstats_bioreplicate MSstats_BioReplicate -msstats_condition MSstats_Condition -msstats_mixture MSstats_Mixture > TOPP_MSstatsConverter_3.stdout 2> TOPP_MSstatsConverter_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_MSstatsConverter_3 failed'; >&2 echo -e "stderr:\n$(cat TOPP_MSstatsConverter_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_MSstatsConverter_3.stdout)";fi
echo executing "TOPP_SpecLibSearcher_1"
SpecLibSearcher -test -ini SpecLibSearcher_1_parameters.ini -in SpecLibSearcher_1.mzML -lib SpecLibSearcher_1.MSP -out SpecLibSearcher_1.tmp > TOPP_SpecLibSearcher_1.stdout 2> TOPP_SpecLibSearcher_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_SpecLibSearcher_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_SpecLibSearcher_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_SpecLibSearcher_1.stdout)";fi
echo executing "TOPP_OpenSwathAssayGenerator_test_1"
OpenSwathAssayGenerator -test -in OpenSwathAssayGenerator_input.TraML -out OpenSwathAssayGenerator_output.TraML.tmp -out_type TraML -min_transitions 6 -max_transitions 6 -allowed_fragment_types b,y -allowed_fragment_charges 2,3 -enable_detection_specific_losses > TOPP_OpenSwathAssayGenerator_test_1.stdout 2> TOPP_OpenSwathAssayGenerator_test_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathAssayGenerator_test_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathAssayGenerator_test_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathAssayGenerator_test_1.stdout)";fi
echo executing "TOPP_OpenSwathAssayGenerator_test_2"
OpenSwathAssayGenerator -test -in OpenSwathAssayGenerator_input_2.TraML -out OpenSwathAssayGenerator_output_2.TraML.tmp -out_type TraML -allowed_fragment_charges 1,2,3,4 -enable_ipf -unimod_file OpenSwathAssayGenerator_input_2_unimod.xml > TOPP_OpenSwathAssayGenerator_test_2.stdout 2> TOPP_OpenSwathAssayGenerator_test_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathAssayGenerator_test_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathAssayGenerator_test_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathAssayGenerator_test_2.stdout)";fi
echo executing "TOPP_OpenSwathAssayGenerator_test_3"
OpenSwathAssayGenerator -test -in OpenSwathAssayGenerator_input_2.TraML -out OpenSwathAssayGenerator_output_3.TraML.tmp -out_type TraML -allowed_fragment_charges 1,2,3,4 -enable_ipf -unimod_file OpenSwathAssayGenerator_input_3_unimod.xml > TOPP_OpenSwathAssayGenerator_test_3.stdout 2> TOPP_OpenSwathAssayGenerator_test_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathAssayGenerator_test_3 failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathAssayGenerator_test_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathAssayGenerator_test_3.stdout)";fi
echo executing "TOPP_OpenSwathDecoyGenerator_test_1"
OpenSwathDecoyGenerator -test -in OpenSwathDecoyGenerator_input.TraML -out OpenSwathDecoyGenerator.TraML.tmp -out_type TraML -method pseudo-reverse -separate -switchKR false > TOPP_OpenSwathDecoyGenerator_test_1.stdout 2> TOPP_OpenSwathDecoyGenerator_test_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathDecoyGenerator_test_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathDecoyGenerator_test_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathDecoyGenerator_test_1.stdout)";fi
echo executing "TOPP_OpenSwathDecoyGenerator_test_2"
OpenSwathDecoyGenerator -test -in OpenSwathDecoyGenerator_input_2.TraML -out OpenSwathDecoyGenerator_2.TraML.tmp -out_type TraML -method pseudo-reverse -product_mz_threshold 0.8 -switchKR false > TOPP_OpenSwathDecoyGenerator_test_2.stdout 2> TOPP_OpenSwathDecoyGenerator_test_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathDecoyGenerator_test_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathDecoyGenerator_test_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathDecoyGenerator_test_2.stdout)";fi
echo executing "TOPP_OpenSwathDecoyGenerator_test_3"
OpenSwathDecoyGenerator -test -in OpenSwathDecoyGenerator_input_3.TraML -out OpenSwathDecoyGenerator_3.TraML.tmp -out_type TraML -method pseudo-reverse -separate -switchKR false > TOPP_OpenSwathDecoyGenerator_test_3.stdout 2> TOPP_OpenSwathDecoyGenerator_test_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathDecoyGenerator_test_3 failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathDecoyGenerator_test_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathDecoyGenerator_test_3.stdout)";fi
echo executing "TOPP_OpenSwathDecoyGenerator_test_4"
OpenSwathDecoyGenerator -test -in OpenSwathDecoyGenerator_input_4.tsv -out OpenSwathDecoyGenerator_4.TraML.tmp -out_type TraML -method pseudo-reverse -separate -switchKR true -enable_detection_unspecific_losses  -enable_detection_specific_losses -min_decoy_fraction 0.4 > TOPP_OpenSwathDecoyGenerator_test_4.stdout 2> TOPP_OpenSwathDecoyGenerator_test_4.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathDecoyGenerator_test_4 failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathDecoyGenerator_test_4.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathDecoyGenerator_test_4.stdout)";fi
echo executing "TOPP_ConvertTSVToTraML_test_1"
TargetedFileConverter -test -in ConvertTSVToTraML_1_input.tsv -out ConvertTSVToTraML_output.TraML.tmp -out_type TraML > TOPP_ConvertTSVToTraML_test_1.stdout 2> TOPP_ConvertTSVToTraML_test_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_ConvertTSVToTraML_test_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_ConvertTSVToTraML_test_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_ConvertTSVToTraML_test_1.stdout)";fi
echo executing "TOPP_ConvertTSVToTraML_test_2"
TargetedFileConverter -test -in ConvertTSVToTraML_2_input.tsv -out ConvertTSVToTraML_2_output.TraML.tmp -algorithm:retentionTimeInterpretation minutes -out_type TraML > TOPP_ConvertTSVToTraML_test_2.stdout 2> TOPP_ConvertTSVToTraML_test_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_ConvertTSVToTraML_test_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_ConvertTSVToTraML_test_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_ConvertTSVToTraML_test_2.stdout)";fi
echo executing "TOPP_ConvertTSVToTraML_test_3"
TargetedFileConverter -test -in ConvertTSVToTraML_2_input.tsv -out ConvertTSVToTraML_3_output.TraML.tmp -algorithm:retentionTimeInterpretation seconds -out_type TraML > TOPP_ConvertTSVToTraML_test_3.stdout 2> TOPP_ConvertTSVToTraML_test_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_ConvertTSVToTraML_test_3 failed'; >&2 echo -e "stderr:\n$(cat TOPP_ConvertTSVToTraML_test_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_ConvertTSVToTraML_test_3.stdout)";fi
echo executing "TOPP_ConvertTSVToTraML_test_4"
TargetedFileConverter -test -in ConvertTSVToTraML_4_input.mrm -out ConvertTSVToTraML_4_output.TraML.tmp -out_type TraML > TOPP_ConvertTSVToTraML_test_4.stdout 2> TOPP_ConvertTSVToTraML_test_4.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_ConvertTSVToTraML_test_4 failed'; >&2 echo -e "stderr:\n$(cat TOPP_ConvertTSVToTraML_test_4.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_ConvertTSVToTraML_test_4.stdout)";fi
echo executing "TOPP_ConvertTSVToTraML_test_5"
TargetedFileConverter -test -in ConvertTSVToTraML_5_input.tsv -out ConvertTSVToTraML_5_output.TraML.tmp -out_type TraML > TOPP_ConvertTSVToTraML_test_5.stdout 2> TOPP_ConvertTSVToTraML_test_5.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_ConvertTSVToTraML_test_5 failed'; >&2 echo -e "stderr:\n$(cat TOPP_ConvertTSVToTraML_test_5.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_ConvertTSVToTraML_test_5.stdout)";fi
echo executing "TOPP_ConvertTSVToTraML_test_6"
TargetedFileConverter -test -in ConvertTSVToTraML_6_input.tsv -out ConvertTSVToTraML_6_output.TraML.tmp -out_type TraML > TOPP_ConvertTSVToTraML_test_6.stdout 2> TOPP_ConvertTSVToTraML_test_6.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_ConvertTSVToTraML_test_6 failed'; >&2 echo -e "stderr:\n$(cat TOPP_ConvertTSVToTraML_test_6.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_ConvertTSVToTraML_test_6.stdout)";fi
echo executing "TOPP_ConvertTSVToTraML_test_7"
TargetedFileConverter -test -in ConvertTSVToTraML_7_input_Skyline.tsv -out ConvertTSVToTraML_7_output.TraML.tmp -out_type TraML > TOPP_ConvertTSVToTraML_test_7.stdout 2> TOPP_ConvertTSVToTraML_test_7.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_ConvertTSVToTraML_test_7 failed'; >&2 echo -e "stderr:\n$(cat TOPP_ConvertTSVToTraML_test_7.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_ConvertTSVToTraML_test_7.stdout)";fi
echo executing "TOPP_TargetedFileConverter_test_1_prepare"
TargetedFileConverter -test -in TargetedFileConverter_1_input.TraML -out TargetedFileConverter_1_output.pqp.tmp -out_type pqp > TOPP_TargetedFileConverter_test_1_prepare.stdout 2> TOPP_TargetedFileConverter_test_1_prepare.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_TargetedFileConverter_test_1_prepare failed'; >&2 echo -e "stderr:\n$(cat TOPP_TargetedFileConverter_test_1_prepare.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_TargetedFileConverter_test_1_prepare.stdout)";fi
echo executing "TOPP_TargetedFileConverter_test_1"
TargetedFileConverter -test -in TargetedFileConverter_1_output.pqp.tmp -in_type pqp -out TargetedFileConverter_1_output.TraML.tmp -out_type TraML > TOPP_TargetedFileConverter_test_1.stdout 2> TOPP_TargetedFileConverter_test_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_TargetedFileConverter_test_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_TargetedFileConverter_test_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_TargetedFileConverter_test_1.stdout)";fi
echo executing "TOPP_TargetedFileConverter_test_2"
TargetedFileConverter -test -in TargetedFileConverter_1_output.pqp.tmp -in_type pqp -out TargetedFileConverter_2_output.TraML.tmp -out_type TraML -legacy_traml_id > TOPP_TargetedFileConverter_test_2.stdout 2> TOPP_TargetedFileConverter_test_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_TargetedFileConverter_test_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_TargetedFileConverter_test_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_TargetedFileConverter_test_2.stdout)";fi
echo executing "TOPP_TargetedFileConverter_test_3_prepare"
TargetedFileConverter -test -in TargetedFileConverter_3_input.TraML -out TargetedFileConverter_3_output.pqp.tmp -out_type pqp > TOPP_TargetedFileConverter_test_3_prepare.stdout 2> TOPP_TargetedFileConverter_test_3_prepare.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_TargetedFileConverter_test_3_prepare failed'; >&2 echo -e "stderr:\n$(cat TOPP_TargetedFileConverter_test_3_prepare.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_TargetedFileConverter_test_3_prepare.stdout)";fi
echo executing "TOPP_TargetedFileConverter_test_3"
TargetedFileConverter -test -in TargetedFileConverter_3_output.pqp.tmp -in_type pqp -out TargetedFileConverter_3_output.TraML.tmp -out_type TraML > TOPP_TargetedFileConverter_test_3.stdout 2> TOPP_TargetedFileConverter_test_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_TargetedFileConverter_test_3 failed'; >&2 echo -e "stderr:\n$(cat TOPP_TargetedFileConverter_test_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_TargetedFileConverter_test_3.stdout)";fi
echo executing "TOPP_TargetedFileConverter_test_4"
TargetedFileConverter -test -in TargetedFileConverter_3_output.pqp.tmp -in_type pqp -out TargetedFileConverter_4_output.TraML.tmp -out_type TraML -legacy_traml_id > TOPP_TargetedFileConverter_test_4.stdout 2> TOPP_TargetedFileConverter_test_4.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_TargetedFileConverter_test_4 failed'; >&2 echo -e "stderr:\n$(cat TOPP_TargetedFileConverter_test_4.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_TargetedFileConverter_test_4.stdout)";fi
echo executing "TOPP_TargetedFileConverter_test_10_prepare"
TargetedFileConverter -test -in TargetedFileConverter_10_input.pqp  -out TargetedFileConverter_10_output.TraML.tmp -out_type TraML -legacy_traml_id > TOPP_TargetedFileConverter_test_10_prepare.stdout 2> TOPP_TargetedFileConverter_test_10_prepare.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_TargetedFileConverter_test_10_prepare failed'; >&2 echo -e "stderr:\n$(cat TOPP_TargetedFileConverter_test_10_prepare.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_TargetedFileConverter_test_10_prepare.stdout)";fi
echo executing "TOPP_TargetedFileConverter_test_10"
TargetedFileConverter -test -in TargetedFileConverter_10_output.TraML.tmp -in_type TraML -out TargetedFileConverter_10_output.tsv.tmp -out_type tsv > TOPP_TargetedFileConverter_test_10.stdout 2> TOPP_TargetedFileConverter_test_10.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_TargetedFileConverter_test_10 failed'; >&2 echo -e "stderr:\n$(cat TOPP_TargetedFileConverter_test_10.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_TargetedFileConverter_test_10.stdout)";fi
echo executing "TOPP_TargetedFileConverter_test_11_prepare"
TargetedFileConverter -test -in TargetedFileConverter_11_input.TraML -out TargetedFileConverter_11_output.pqp.tmp -out_type pqp > TOPP_TargetedFileConverter_test_11_prepare.stdout 2> TOPP_TargetedFileConverter_test_11_prepare.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_TargetedFileConverter_test_11_prepare failed'; >&2 echo -e "stderr:\n$(cat TOPP_TargetedFileConverter_test_11_prepare.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_TargetedFileConverter_test_11_prepare.stdout)";fi
echo executing "TOPP_TargetedFileConverter_test_11"
TargetedFileConverter -test -in TargetedFileConverter_11_output.pqp.tmp -in_type pqp -out TargetedFileConverter_11_output.TraML.tmp -out_type TraML > TOPP_TargetedFileConverter_test_11.stdout 2> TOPP_TargetedFileConverter_test_11.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_TargetedFileConverter_test_11 failed'; >&2 echo -e "stderr:\n$(cat TOPP_TargetedFileConverter_test_11.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_TargetedFileConverter_test_11.stdout)";fi
echo executing "TOPP_TargetedFileConverter_test_8_prepare"
TargetedFileConverter -algorithm:override_group_label_check -test -in TargetedFileConverter_8_input.tsv -out TargetedFileConverter_8_output.TraML.tmp -out_type TraML > TOPP_TargetedFileConverter_test_8_prepare.stdout 2> TOPP_TargetedFileConverter_test_8_prepare.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_TargetedFileConverter_test_8_prepare failed'; >&2 echo -e "stderr:\n$(cat TOPP_TargetedFileConverter_test_8_prepare.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_TargetedFileConverter_test_8_prepare.stdout)";fi
echo executing "TOPP_TargetedFileConverter_test_8"
TargetedFileConverter -algorithm:override_group_label_check -test -in TargetedFileConverter_8_output.TraML.tmp -in_type TraML -out TargetedFileConverter_8_output.tsv.tmp -out_type tsv > TOPP_TargetedFileConverter_test_8.stdout 2> TOPP_TargetedFileConverter_test_8.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_TargetedFileConverter_test_8 failed'; >&2 echo -e "stderr:\n$(cat TOPP_TargetedFileConverter_test_8.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_TargetedFileConverter_test_8.stdout)";fi
echo executing "TOPP_TargetedFileConverter_test_9_prepare"
TargetedFileConverter -algorithm:override_group_label_check -test -in TargetedFileConverter_9_input.TraML -out TargetedFileConverter_9_output.pqp.tmp -out_type pqp > TOPP_TargetedFileConverter_test_9_prepare.stdout 2> TOPP_TargetedFileConverter_test_9_prepare.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_TargetedFileConverter_test_9_prepare failed'; >&2 echo -e "stderr:\n$(cat TOPP_TargetedFileConverter_test_9_prepare.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_TargetedFileConverter_test_9_prepare.stdout)";fi
echo executing "TOPP_TargetedFileConverter_test_9"
TargetedFileConverter -algorithm:override_group_label_check -test -in TargetedFileConverter_9_output.pqp.tmp -in_type pqp -out TargetedFileConverter_9_output.TraML.tmp -out_type TraML > TOPP_TargetedFileConverter_test_9.stdout 2> TOPP_TargetedFileConverter_test_9.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_TargetedFileConverter_test_9 failed'; >&2 echo -e "stderr:\n$(cat TOPP_TargetedFileConverter_test_9.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_TargetedFileConverter_test_9.stdout)";fi
echo executing "TOPP_TargetedFileConverter_test_5"
TargetedFileConverter -test -in ConvertTSVToTraML_output.TraML -out ConvertTraMLToTSV_output.tmp.tsv -out_type tsv > TOPP_TargetedFileConverter_test_5.stdout 2> TOPP_TargetedFileConverter_test_5.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_TargetedFileConverter_test_5 failed'; >&2 echo -e "stderr:\n$(cat TOPP_TargetedFileConverter_test_5.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_TargetedFileConverter_test_5.stdout)";fi
echo executing "TOPP_TargetedFileConverter_test_12_prepare"
TargetedFileConverter -algorithm:override_group_label_check -test -in TargetedFileConverter_12_input.TraML -out TargetedFileConverter_12_output.pqp.tmp -out_type pqp > TOPP_TargetedFileConverter_test_12_prepare.stdout 2> TOPP_TargetedFileConverter_test_12_prepare.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_TargetedFileConverter_test_12_prepare failed'; >&2 echo -e "stderr:\n$(cat TOPP_TargetedFileConverter_test_12_prepare.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_TargetedFileConverter_test_12_prepare.stdout)";fi
echo executing "TOPP_TargetedFileConverter_test_12"
TargetedFileConverter -algorithm:override_group_label_check -test -in TargetedFileConverter_12_output.pqp.tmp -in_type pqp -out TargetedFileConverter_12_output.TraML.tmp -out_type TraML > TOPP_TargetedFileConverter_test_12.stdout 2> TOPP_TargetedFileConverter_test_12.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_TargetedFileConverter_test_12 failed'; >&2 echo -e "stderr:\n$(cat TOPP_TargetedFileConverter_test_12.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_TargetedFileConverter_test_12.stdout)";fi
echo executing "TOPP_TargetedFileConverter_test_13"
TargetedFileConverter -test -in TargetedFileConverter_12_input.tsv -out TargetedFileConverter_13_output.TraML.tmp -out_type TraML > TOPP_TargetedFileConverter_test_13.stdout 2> TOPP_TargetedFileConverter_test_13.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_TargetedFileConverter_test_13 failed'; >&2 echo -e "stderr:\n$(cat TOPP_TargetedFileConverter_test_13.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_TargetedFileConverter_test_13.stdout)";fi
echo executing "TOPP_TargetedFileConverter_test_6"
TargetedFileConverter -test -in ConvertTSVToTraML_5_output.TraML -out ConvertTraMLToTSV_output_2.tmp.tsv -out_type tsv > TOPP_TargetedFileConverter_test_6.stdout 2> TOPP_TargetedFileConverter_test_6.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_TargetedFileConverter_test_6 failed'; >&2 echo -e "stderr:\n$(cat TOPP_TargetedFileConverter_test_6.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_TargetedFileConverter_test_6.stdout)";fi
echo executing "TOPP_TargetedFileConverter_test_6_convert_back"
TargetedFileConverter -test -in ConvertTraMLToTSV_output_2.tmp.tsv -in_type tsv -out ConvertTraMLToTSV_output_2.tsv.back.tmp -out_type TraML > TOPP_TargetedFileConverter_test_6_convert_back.stdout 2> TOPP_TargetedFileConverter_test_6_convert_back.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_TargetedFileConverter_test_6_convert_back failed'; >&2 echo -e "stderr:\n$(cat TOPP_TargetedFileConverter_test_6_convert_back.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_TargetedFileConverter_test_6_convert_back.stdout)";fi
echo executing "TOPP_MRMMapper_test_1"
MRMMapper -in MRMMapping_input.chrom.mzML -tr MRMMapping_input.TraML -out MRMMapping_output_1.chrom.mzML.tmp -test -algorithm:precursor_tolerance 0.3 -algorithm:product_tolerance 0.3 > TOPP_MRMMapper_test_1.stdout 2> TOPP_MRMMapper_test_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_MRMMapper_test_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_MRMMapper_test_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_MRMMapper_test_1.stdout)";fi
echo executing "TOPP_MRMMapper_test_2"
MRMMapper -in MRMMapping_input.chrom.mzML -tr MRMMapping_input_2.TraML -out MRMMapping_output_2.chrom.mzML.tmp -test -algorithm:precursor_tolerance 0.01 -algorithm:product_tolerance 0.01 > TOPP_MRMMapper_test_2.stdout 2> TOPP_MRMMapper_test_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_MRMMapper_test_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_MRMMapper_test_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_MRMMapper_test_2.stdout)";fi
echo executing "TOPP_OpenSwathFeatureXMLToTSV_test_1"
OpenSwathFeatureXMLToTSV -in OpenSwathFeatureXMLToTSV_input.featureXML -tr OpenSwathFeatureXMLToTSV_input.TraML -out OpenSwathFeatureXMLToTSV_output.short.csv.tmp -short_format -test > TOPP_OpenSwathFeatureXMLToTSV_test_1.stdout 2> TOPP_OpenSwathFeatureXMLToTSV_test_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathFeatureXMLToTSV_test_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathFeatureXMLToTSV_test_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathFeatureXMLToTSV_test_1.stdout)";fi
echo executing "TOPP_OpenSwathFeatureXMLToTSV_test_2"
OpenSwathFeatureXMLToTSV -in OpenSwathFeatureXMLToTSV_input.featureXML -tr OpenSwathFeatureXMLToTSV_input.TraML -out OpenSwathFeatureXMLToTSV_output.long.csv.tmp -test > TOPP_OpenSwathFeatureXMLToTSV_test_2.stdout 2> TOPP_OpenSwathFeatureXMLToTSV_test_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathFeatureXMLToTSV_test_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathFeatureXMLToTSV_test_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathFeatureXMLToTSV_test_2.stdout)";fi
echo executing "TOPP_OpenSwathFeatureXMLToTSV_test_3"
OpenSwathFeatureXMLToTSV -in OpenSwathFeatureXMLToTSV_input.featureXML -tr OpenSwathFeatureXMLToTSV_input.TraML -out OpenSwathFeatureXMLToTSV_3_output.short.csv.tmp -short_format -best_scoring_peptide main_var_xx_lda_prelim_score -test > TOPP_OpenSwathFeatureXMLToTSV_test_3.stdout 2> TOPP_OpenSwathFeatureXMLToTSV_test_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathFeatureXMLToTSV_test_3 failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathFeatureXMLToTSV_test_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathFeatureXMLToTSV_test_3.stdout)";fi
echo executing "TOPP_OpenSwathChromatogramExtractor_test_1"
OpenSwathChromatogramExtractor -in OpenSwathChromatogramExtractor_input.mzML -tr OpenSwathChromatogramExtractor_input.TraML -out OpenSwathChromatogramExtractor_output.mzML.tmp -test > TOPP_OpenSwathChromatogramExtractor_test_1.stdout 2> TOPP_OpenSwathChromatogramExtractor_test_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathChromatogramExtractor_test_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathChromatogramExtractor_test_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathChromatogramExtractor_test_1.stdout)";fi
echo executing "TOPP_OpenSwathChromatogramExtractor_test_2"
OpenSwathChromatogramExtractor -in OpenSwathChromatogramExtractor_input.mzML -tr OpenSwathChromatogramExtractor_input.TraML -rt_norm OpenSwathChromatogramExtractor_input.trafoXML -out OpenSwathChromatogramExtractor_output_2.mzML.tmp -test -rt_window 50 > TOPP_OpenSwathChromatogramExtractor_test_2.stdout 2> TOPP_OpenSwathChromatogramExtractor_test_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathChromatogramExtractor_test_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathChromatogramExtractor_test_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathChromatogramExtractor_test_2.stdout)";fi
echo executing "TOPP_OpenSwathChromatogramExtractor_test_3"
OpenSwathChromatogramExtractor -in OpenSwathChromatogramExtractor_input.mzML -tr OpenSwathChromatogramExtractor_input.TraML -out OpenSwathChromatogramExtractor_output_3.mzML.tmp -test -extract_MS1 > TOPP_OpenSwathChromatogramExtractor_test_3.stdout 2> TOPP_OpenSwathChromatogramExtractor_test_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathChromatogramExtractor_test_3 failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathChromatogramExtractor_test_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathChromatogramExtractor_test_3.stdout)";fi
echo executing "TOPP_OpenSwathChromatogramExtractor_test_4"
OpenSwathChromatogramExtractor -in OpenSwathChromatogramExtractor_4_input.mzML -tr OpenSwathChromatogramExtractor_4_input.TraML -out OpenSwathChromatogramExtractor_output_4.mzML.tmp -ion_mobility_window 0.05 -is_swath -test > TOPP_OpenSwathChromatogramExtractor_test_4.stdout 2> TOPP_OpenSwathChromatogramExtractor_test_4.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathChromatogramExtractor_test_4 failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathChromatogramExtractor_test_4.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathChromatogramExtractor_test_4.stdout)";fi
echo executing "TOPP_OpenSwathChromatogramExtractor_test_5"
OpenSwathChromatogramExtractor -in OpenSwathChromatogramExtractor_input.mzML -tr OpenSwathChromatogramExtractor_5_input.TraML -out OpenSwathChromatogramExtractor_5_output.mzML.tmp -test -extract_MS1 > TOPP_OpenSwathChromatogramExtractor_test_5.stdout 2> TOPP_OpenSwathChromatogramExtractor_test_5.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathChromatogramExtractor_test_5 failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathChromatogramExtractor_test_5.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathChromatogramExtractor_test_5.stdout)";fi
echo executing "TOPP_OpenSwathAnalyzer_test_1"
OpenSwathAnalyzer -in OpenSwathAnalyzer_1_input_chrom.mzML -tr OpenSwathAnalyzer_1_input.TraML -out OpenSwathAnalyzer_1_output.featureXML.tmp -rt_norm OpenSwathAnalyzer_input.trafoXML -algorithm:TransitionGroupPicker:PeakPickerMRM:peak_width 40.0 -algorithm:TransitionGroupPicker:PeakPickerMRM:method legacy -test > TOPP_OpenSwathAnalyzer_test_1.stdout 2> TOPP_OpenSwathAnalyzer_test_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathAnalyzer_test_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathAnalyzer_test_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathAnalyzer_test_1.stdout)";fi
echo executing "TOPP_OpenSwathAnalyzer_test_2"
OpenSwathAnalyzer -in OpenSwathAnalyzer_1_input_chrom.mzML -tr OpenSwathAnalyzer_1_input.TraML -out OpenSwathAnalyzer_2_output.featureXML.tmp -swath_files OpenSwathAnalyzer_2_swathfile.mzML -algorithm:TransitionGroupPicker:PeakPickerMRM:peak_width 40.0 -algorithm:TransitionGroupPicker:PeakPickerMRM:method legacy -test > TOPP_OpenSwathAnalyzer_test_2.stdout 2> TOPP_OpenSwathAnalyzer_test_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathAnalyzer_test_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathAnalyzer_test_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathAnalyzer_test_2.stdout)";fi
echo executing "TOPP_OpenSwathAnalyzer_test_5_mod"
OpenSwathAnalyzer -in OpenSwathAnalyzer_1_input_chrom.mzML -tr OpenSwathAnalyzer_mod_input.TraML -out OpenSwathAnalyzer_5_output.featureXML.tmp -swath_files OpenSwathAnalyzer_2_swathfile.mzML -ini OpenSwathAnalyzer_5.ini -test > TOPP_OpenSwathAnalyzer_test_5_mod.stdout 2> TOPP_OpenSwathAnalyzer_test_5_mod.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathAnalyzer_test_5_mod failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathAnalyzer_test_5_mod.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathAnalyzer_test_5_mod.stdout)";fi
echo executing "TOPP_OpenSwathAnalyzer_test_6_nomod"
OpenSwathAnalyzer -in OpenSwathAnalyzer_1_input_chrom.mzML -tr OpenSwathAnalyzer_1_input.TraML -out OpenSwathAnalyzer_6_output.featureXML.tmp -swath_files OpenSwathAnalyzer_2_swathfile.mzML -ini OpenSwathAnalyzer_5.ini -test > TOPP_OpenSwathAnalyzer_test_6_nomod.stdout 2> TOPP_OpenSwathAnalyzer_test_6_nomod.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathAnalyzer_test_6_nomod failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathAnalyzer_test_6_nomod.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathAnalyzer_test_6_nomod.stdout)";fi
echo executing "TOPP_OpenSwathAnalyzer_test_7_backgroundSubtraction"
OpenSwathAnalyzer -in OpenSwathAnalyzer_1_input_chrom.mzML -tr OpenSwathAnalyzer_1_input.TraML -out OpenSwathAnalyzer_7_output.featureXML.tmp -ini OpenSwathAnalyzer_7_backgroundSubtraction.ini -test > TOPP_OpenSwathAnalyzer_test_7_backgroundSubtraction.stdout 2> TOPP_OpenSwathAnalyzer_test_7_backgroundSubtraction.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathAnalyzer_test_7_backgroundSubtraction failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathAnalyzer_test_7_backgroundSubtraction.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathAnalyzer_test_7_backgroundSubtraction.stdout)";fi
echo executing "TOPP_OpenSwathAnalyzer_test_8"
OpenSwathAnalyzer -in OpenSwathAnalyzer_1_input_chrom.mzML -tr OpenSwathAnalyzer_1_input.TraML -out OpenSwathAnalyzer_8_output.featureXML.tmp -rt_norm OpenSwathAnalyzer_input.trafoXML -algorithm:TransitionGroupPicker:PeakPickerMRM:peak_width 40.0 -algorithm:TransitionGroupPicker:PeakPickerMRM:method legacy -algorithm:Scores:use_ms1_mi -algorithm:Scores:use_mi_score -algorithm:Scores:use_total_mi_score -test > TOPP_OpenSwathAnalyzer_test_8.stdout 2> TOPP_OpenSwathAnalyzer_test_8.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathAnalyzer_test_8 failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathAnalyzer_test_8.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathAnalyzer_test_8.stdout)";fi
echo executing "TOPP_OpenSwathAnalyzer_test_9"
OpenSwathAnalyzer -in OpenSwathAnalyzer_1_input_chrom.mzML -tr OpenSwathAnalyzer_1_input.TraML -out OpenSwathAnalyzer_9_output.featureXML.tmp -rt_norm OpenSwathAnalyzer_input.trafoXML -algorithm:TransitionGroupPicker:PeakPickerMRM:peak_width 40.0 -algorithm:TransitionGroupPicker:PeakPickerMRM:method legacy -algorithm:Scores:use_mi_score -test > TOPP_OpenSwathAnalyzer_test_9.stdout 2> TOPP_OpenSwathAnalyzer_test_9.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathAnalyzer_test_9 failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathAnalyzer_test_9.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathAnalyzer_test_9.stdout)";fi
echo executing "TOPP_OpenSwathAnalyzer_test_10"
OpenSwathAnalyzer -in OpenSwathAnalyzer_1_input_chrom.mzML -tr OpenSwathAnalyzer_1_input.TraML -out OpenSwathAnalyzer_10_output.featureXML.tmp -rt_norm OpenSwathAnalyzer_input.trafoXML -algorithm:TransitionGroupPicker:PeakPickerMRM:peak_width 40.0 -algorithm:TransitionGroupPicker:PeakPickerMRM:method legacy -algorithm:Scores:use_mi_score -algorithm:Scores:use_total_mi_score -test > TOPP_OpenSwathAnalyzer_test_10.stdout 2> TOPP_OpenSwathAnalyzer_test_10.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathAnalyzer_test_10 failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathAnalyzer_test_10.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathAnalyzer_test_10.stdout)";fi
echo executing "TOPP_OpenSwathAnalyzer_test_11"
OpenSwathAnalyzer -in OpenSwathAnalyzer_1_input_chrom.mzML -tr OpenSwathAnalyzer_1_input.TraML -out OpenSwathAnalyzer_11_output.featureXML.tmp -rt_norm OpenSwathAnalyzer_input.trafoXML -algorithm:TransitionGroupPicker:PeakPickerMRM:peak_width 40.0 -algorithm:TransitionGroupPicker:PeakPickerMRM:method legacy -algorithm:Scores:use_total_mi_score -test > TOPP_OpenSwathAnalyzer_test_11.stdout 2> TOPP_OpenSwathAnalyzer_test_11.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathAnalyzer_test_11 failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathAnalyzer_test_11.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathAnalyzer_test_11.stdout)";fi
echo executing "TOPP_OpenSwathRTNormalizer_test_1"
OpenSwathRTNormalizer -in OpenSwathRTNormalizer_1_input.mzML -tr OpenSwathRTNormalizer_1_input.TraML -out OpenSwathRTNormalizer_1_output.trafoXML.tmp -test > TOPP_OpenSwathRTNormalizer_test_1.stdout 2> TOPP_OpenSwathRTNormalizer_test_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathRTNormalizer_test_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathRTNormalizer_test_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathRTNormalizer_test_1.stdout)";fi
echo executing "TOPP_OpenSwathRTNormalizer_test_3"
OpenSwathRTNormalizer -in OpenSwathRTNormalizer_1_input.mzML -tr OpenSwathRTNormalizer_1_input.TraML -out OpenSwathRTNormalizer_3_output.trafoXML.tmp -test -estimateBestPeptides -peptideEstimation:NrRTBins 3 -peptideEstimation:MinBinsFilled 3 > TOPP_OpenSwathRTNormalizer_test_3.stdout 2> TOPP_OpenSwathRTNormalizer_test_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathRTNormalizer_test_3 failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathRTNormalizer_test_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathRTNormalizer_test_3.stdout)";fi
echo executing "TOPP_OpenSwathRTNormalizer_test_4"
OpenSwathRTNormalizer -in OpenSwathRTNormalizer_1_input.mzML -tr OpenSwathRTNormalizer_1_input.TraML -out OpenSwathRTNormalizer_4_output.trafoXML.tmp -test -RTNormalization:outlierMethod iter_residual > TOPP_OpenSwathRTNormalizer_test_4.stdout 2> TOPP_OpenSwathRTNormalizer_test_4.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathRTNormalizer_test_4 failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathRTNormalizer_test_4.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathRTNormalizer_test_4.stdout)";fi
echo executing "TOPP_OpenSwathConfidenceScoring_1"
OpenSwathConfidenceScoring -test -in OpenSwathFeatureXMLToTSV_input.featureXML -lib OpenSwathFeatureXMLToTSV_input.TraML -trafo OpenSwathConfidenceScoring_1_input.trafoXML -transitions 2 -decoys 1 -out OpenSwathConfidenceScoring_1_output.tmp > TOPP_OpenSwathConfidenceScoring_1.stdout 2> TOPP_OpenSwathConfidenceScoring_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathConfidenceScoring_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathConfidenceScoring_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathConfidenceScoring_1.stdout)";fi
echo executing "TOPP_OpenSwathMzMLFileCacher_test_1_step1"
OpenSwathMzMLFileCacher -in OpenSwathMzMLFileCacher_1_input.mzML -out OpenSwathMzMLFileCacher_1_input.cached.tmp.mzML -test > TOPP_OpenSwathMzMLFileCacher_test_1_step1.stdout 2> TOPP_OpenSwathMzMLFileCacher_test_1_step1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathMzMLFileCacher_test_1_step1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathMzMLFileCacher_test_1_step1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathMzMLFileCacher_test_1_step1.stdout)";fi
echo executing "TOPP_OpenSwathMzMLFileCacher_test_1_step2"
OpenSwathMzMLFileCacher -in OpenSwathMzMLFileCacher_1_input.cached.tmp.mzML -out OpenSwathMzMLFileCacher_1_output.tmp.mzML -convert_back -test > TOPP_OpenSwathMzMLFileCacher_test_1_step2.stdout 2> TOPP_OpenSwathMzMLFileCacher_test_1_step2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathMzMLFileCacher_test_1_step2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathMzMLFileCacher_test_1_step2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathMzMLFileCacher_test_1_step2.stdout)";fi
echo executing "TOPP_OpenSwathMzMLFileCacher_test_2_step1"
OpenSwathMzMLFileCacher -in OpenSwathMzMLFileCacher_2_input.chrom.mzML -out OpenSwathMzMLFileCacher_2_input.chrom.cached.tmp.mzML -test > TOPP_OpenSwathMzMLFileCacher_test_2_step1.stdout 2> TOPP_OpenSwathMzMLFileCacher_test_2_step1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathMzMLFileCacher_test_2_step1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathMzMLFileCacher_test_2_step1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathMzMLFileCacher_test_2_step1.stdout)";fi
echo executing "TOPP_OpenSwathMzMLFileCacher_test_2_step2"
OpenSwathMzMLFileCacher -in OpenSwathMzMLFileCacher_2_input.chrom.cached.tmp.mzML -out OpenSwathMzMLFileCacher_2_output.chrom.tmp.mzML -convert_back -test > TOPP_OpenSwathMzMLFileCacher_test_2_step2.stdout 2> TOPP_OpenSwathMzMLFileCacher_test_2_step2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathMzMLFileCacher_test_2_step2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathMzMLFileCacher_test_2_step2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathMzMLFileCacher_test_2_step2.stdout)";fi
echo executing "TOPP_OpenSwathMzMLFileCacher_test_3_step1"
OpenSwathMzMLFileCacher -in OpenSwathMzMLFileCacher_1_input.mzML -out OpenSwathMzMLFileCacher_3_input.tmp.sqMass -test -lossy_compression true -lossy_mass_accuracy 1e-4 > TOPP_OpenSwathMzMLFileCacher_test_3_step1.stdout 2> TOPP_OpenSwathMzMLFileCacher_test_3_step1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathMzMLFileCacher_test_3_step1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathMzMLFileCacher_test_3_step1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathMzMLFileCacher_test_3_step1.stdout)";fi
echo executing "TOPP_OpenSwathMzMLFileCacher_test_3_step2"
OpenSwathMzMLFileCacher -in OpenSwathMzMLFileCacher_3_input.tmp.sqMass -out OpenSwathMzMLFileCacher_3_output.tmp.mzML -test > TOPP_OpenSwathMzMLFileCacher_test_3_step2.stdout 2> TOPP_OpenSwathMzMLFileCacher_test_3_step2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathMzMLFileCacher_test_3_step2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathMzMLFileCacher_test_3_step2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathMzMLFileCacher_test_3_step2.stdout)";fi
echo executing "TOPP_OpenSwathMzMLFileCacher_test_4_step1"
OpenSwathMzMLFileCacher -in OpenSwathMzMLFileCacher_2_input.chrom.mzML -out OpenSwathMzMLFileCacher_4_input.tmp.sqMass -test > TOPP_OpenSwathMzMLFileCacher_test_4_step1.stdout 2> TOPP_OpenSwathMzMLFileCacher_test_4_step1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathMzMLFileCacher_test_4_step1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathMzMLFileCacher_test_4_step1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathMzMLFileCacher_test_4_step1.stdout)";fi
echo executing "TOPP_OpenSwathMzMLFileCacher_test_4_step2"
OpenSwathMzMLFileCacher -in OpenSwathMzMLFileCacher_4_input.tmp.sqMass -out OpenSwathMzMLFileCacher_4_output.tmp.mzML -test > TOPP_OpenSwathMzMLFileCacher_test_4_step2.stdout 2> TOPP_OpenSwathMzMLFileCacher_test_4_step2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathMzMLFileCacher_test_4_step2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathMzMLFileCacher_test_4_step2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathMzMLFileCacher_test_4_step2.stdout)";fi
echo executing "TOPP_OpenSwathMzMLFileCacher_test_5_step1"
OpenSwathMzMLFileCacher -in OpenSwathMzMLFileCacher_1_input.mzML -out OpenSwathMzMLFileCacher_1_input.cached.tmp.mzML -test -process_lowmemory > TOPP_OpenSwathMzMLFileCacher_test_5_step1.stdout 2> TOPP_OpenSwathMzMLFileCacher_test_5_step1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathMzMLFileCacher_test_5_step1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathMzMLFileCacher_test_5_step1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathMzMLFileCacher_test_5_step1.stdout)";fi
echo executing "TOPP_OpenSwathMzMLFileCacher_test_5_step2"
OpenSwathMzMLFileCacher -in OpenSwathMzMLFileCacher_1_input.cached.tmp.mzML -out OpenSwathMzMLFileCacher_1_output.tmp.mzML -convert_back -test > TOPP_OpenSwathMzMLFileCacher_test_5_step2.stdout 2> TOPP_OpenSwathMzMLFileCacher_test_5_step2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathMzMLFileCacher_test_5_step2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathMzMLFileCacher_test_5_step2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathMzMLFileCacher_test_5_step2.stdout)";fi
echo executing "TOPP_OpenSwathAnalyzer_test_3_prepare"
OpenSwathMzMLFileCacher -in OpenSwathAnalyzer_2_swathfile.mzML -out OpenSwathAnalyzer_3_swathfile.mzML.cached.tmp -out_type mzML -test > TOPP_OpenSwathAnalyzer_test_3_prepare.stdout 2> TOPP_OpenSwathAnalyzer_test_3_prepare.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathAnalyzer_test_3_prepare failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathAnalyzer_test_3_prepare.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathAnalyzer_test_3_prepare.stdout)";fi
echo executing "TOPP_OpenSwathAnalyzer_test_3"
OpenSwathAnalyzer -in OpenSwathAnalyzer_1_input_chrom.mzML -tr OpenSwathAnalyzer_1_input.TraML -out MRMFeatureFinderScore_output_3.featureXML.tmp -swath_files OpenSwathAnalyzer_3_swathfile.mzML.cached.tmp -algorithm:TransitionGroupPicker:PeakPickerMRM:peak_width 40.0 -algorithm:TransitionGroupPicker:PeakPickerMRM:method legacy -test > TOPP_OpenSwathAnalyzer_test_3.stdout 2> TOPP_OpenSwathAnalyzer_test_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathAnalyzer_test_3 failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathAnalyzer_test_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathAnalyzer_test_3.stdout)";fi
echo executing "TOPP_OpenSwathAnalyzer_test_4_prepare1"
OpenSwathMzMLFileCacher -in OpenSwathAnalyzer_2_swathfile.mzML -out OpenSwathAnalyzer_4_swathfile.mzML.cached.tmp -out_type mzML -test > TOPP_OpenSwathAnalyzer_test_4_prepare1.stdout 2> TOPP_OpenSwathAnalyzer_test_4_prepare1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathAnalyzer_test_4_prepare1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathAnalyzer_test_4_prepare1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathAnalyzer_test_4_prepare1.stdout)";fi
echo executing "TOPP_OpenSwathAnalyzer_test_4_prepare2"
OpenSwathMzMLFileCacher -in OpenSwathAnalyzer_1_input_chrom.mzML -out OpenSwathAnalyzer_4_input_chrom.mzML.cached.tmp -out_type mzML -test > TOPP_OpenSwathAnalyzer_test_4_prepare2.stdout 2> TOPP_OpenSwathAnalyzer_test_4_prepare2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathAnalyzer_test_4_prepare2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathAnalyzer_test_4_prepare2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathAnalyzer_test_4_prepare2.stdout)";fi
echo executing "TOPP_OpenSwathAnalyzer_test_4"
OpenSwathAnalyzer -in OpenSwathAnalyzer_4_input_chrom.mzML.cached.tmp -tr OpenSwathAnalyzer_1_input.TraML -out MRMFeatureFinderScore_output_4.featureXML.tmp -swath_files OpenSwathAnalyzer_4_swathfile.mzML.cached.tmp -algorithm:TransitionGroupPicker:PeakPickerMRM:peak_width 40.0 -algorithm:TransitionGroupPicker:PeakPickerMRM:method legacy -test > TOPP_OpenSwathAnalyzer_test_4.stdout 2> TOPP_OpenSwathAnalyzer_test_4.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathAnalyzer_test_4 failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathAnalyzer_test_4.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathAnalyzer_test_4.stdout)";fi
echo executing "UTILS_MRMTransitionGroupPicker_test_1"
MRMTransitionGroupPicker -in MRMTransitionGroupPicker_1_input.mzML -tr MRMTransitionGroupPicker_1_input.TraML -out MRMTransitionGroupPicker_test_1.featureXML.tmp -test -algorithm:PeakPickerMRM:remove_overlapping_peaks true -algorithm:PeakPickerMRM:method legacy -algorithm:PeakPickerMRM:peak_width 40.0 > UTILS_MRMTransitionGroupPicker_test_1.stdout 2> UTILS_MRMTransitionGroupPicker_test_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_MRMTransitionGroupPicker_test_1 failed'; >&2 echo -e "stderr:\n$(cat UTILS_MRMTransitionGroupPicker_test_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_MRMTransitionGroupPicker_test_1.stdout)";fi
echo executing "UTILS_MRMTransitionGroupPicker_test_2"
MRMTransitionGroupPicker -in MRMTransitionGroupPicker_1_input.mzML -tr MRMTransitionGroupPicker_1_input.TraML -out MRMTransitionGroupPicker_test_2.featureXML.tmp -test -algorithm:PeakPickerMRM:remove_overlapping_peaks true -algorithm:PeakPickerMRM:method legacy -algorithm:PeakPickerMRM:peak_width 40.0 -algorithm:compute_total_mi > UTILS_MRMTransitionGroupPicker_test_2.stdout 2> UTILS_MRMTransitionGroupPicker_test_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_MRMTransitionGroupPicker_test_2 failed'; >&2 echo -e "stderr:\n$(cat UTILS_MRMTransitionGroupPicker_test_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_MRMTransitionGroupPicker_test_2.stdout)";fi
echo executing "TOPP_OpenSwathWorkflow_1"
OpenSwathWorkflow -in OpenSwathWorkflow_1_input.mzML -tr OpenSwathWorkflow_1_input.TraML -rt_norm OpenSwathWorkflow_1_input.trafoXML -out_chrom OpenSwathWorkflow_1.chrom.mzML.tmp -out_features OpenSwathWorkflow_1.featureXML.tmp -out_qc OpenSwathWorkflow_1.json.tmp -enable_ms1 "false" ${OLD_OSW_PARAM}  > TOPP_OpenSwathWorkflow_1.stdout 2> TOPP_OpenSwathWorkflow_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathWorkflow_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathWorkflow_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathWorkflow_1.stdout)";fi
echo executing "TOPP_OpenSwathWorkflow_2"
OpenSwathWorkflow -in OpenSwathWorkflow_2_input.mzXML -tr OpenSwathWorkflow_2_input.TraML -rt_norm OpenSwathWorkflow_2_input.trafoXML -out_chrom OpenSwathWorkflow_2.chrom.mzML.tmp -out_features OpenSwathWorkflow_2.featureXML.tmp -enable_ms1 "false" ${OLD_OSW_PARAM}  > TOPP_OpenSwathWorkflow_2.stdout 2> TOPP_OpenSwathWorkflow_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathWorkflow_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathWorkflow_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathWorkflow_2.stdout)";fi
echo executing "TOPP_OpenSwathWorkflow_3"
OpenSwathWorkflow -in OpenSwathWorkflow_1_input.mzML -tr OpenSwathWorkflow_1_input.TraML -rt_norm OpenSwathWorkflow_1_input.trafoXML -out_chrom OpenSwathWorkflow_3.chrom.mzML.tmp -out_features OpenSwathWorkflow_3.featureXML.tmp ${OLD_OSW_PARAM} > TOPP_OpenSwathWorkflow_3.stdout 2> TOPP_OpenSwathWorkflow_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathWorkflow_3 failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathWorkflow_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathWorkflow_3.stdout)";fi
echo executing "TOPP_OpenSwathWorkflow_4"
OpenSwathWorkflow -in OpenSwathWorkflow_1_input.mzML -tr OpenSwathWorkflow_1_input.TraML -rt_norm OpenSwathWorkflow_1_input.trafoXML -out_chrom OpenSwathWorkflow_4.chrom.mzML.tmp -out_tsv OpenSwathWorkflow_4.tsv.tmp ${OLD_OSW_PARAM} > TOPP_OpenSwathWorkflow_4.stdout 2> TOPP_OpenSwathWorkflow_4.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathWorkflow_4 failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathWorkflow_4.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathWorkflow_4.stdout)";fi
echo executing "TOPP_OpenSwathWorkflow_5"
OpenSwathWorkflow -in OpenSwathWorkflow_1_input.mzML -tr OpenSwathWorkflow_1_input.TraML -rt_norm OpenSwathWorkflow_1_input.trafoXML -out_chrom OpenSwathWorkflow_5.chrom.mzML.tmp -out_features OpenSwathWorkflow_5.featureXML.tmp -readOptions cache -tempDirectory "." ${OLD_OSW_PARAM} > TOPP_OpenSwathWorkflow_5.stdout 2> TOPP_OpenSwathWorkflow_5.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathWorkflow_5 failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathWorkflow_5.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathWorkflow_5.stdout)";fi
echo executing "TOPP_OpenSwathWorkflow_6"
OpenSwathWorkflow -in OpenSwathWorkflow_1_input.mzML -tr OpenSwathWorkflow_1_input.TraML -rt_norm OpenSwathWorkflow_1_input.trafoXML -out_chrom OpenSwathWorkflow_6.chrom.mzML.tmp -out_features OpenSwathWorkflow_6.featureXML.tmp -readOptions cacheWorkingInMemory -tempDirectory "." ${OLD_OSW_PARAM}  > TOPP_OpenSwathWorkflow_6.stdout 2> TOPP_OpenSwathWorkflow_6.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathWorkflow_6 failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathWorkflow_6.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathWorkflow_6.stdout)";fi
echo executing "TOPP_OpenSwathWorkflow_7"
OpenSwathWorkflow -in OpenSwathWorkflow_1_input.mzML -tr OpenSwathWorkflow_1_input.TraML -rt_norm OpenSwathWorkflow_1_input.trafoXML -out_chrom OpenSwathWorkflow_7.chrom.mzML.tmp -out_features OpenSwathWorkflow_7.featureXML.tmp -swath_windows_file swath_windows.txt ${OLD_OSW_PARAM}  > TOPP_OpenSwathWorkflow_7.stdout 2> TOPP_OpenSwathWorkflow_7.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathWorkflow_7 failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathWorkflow_7.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathWorkflow_7.stdout)";fi
echo executing "TOPP_OpenSwathWorkflow_10"
OpenSwathWorkflow -in OpenSwathWorkflow_1_input.mzML -tr OpenSwathWorkflow_1_input.TraML -rt_norm OpenSwathWorkflow_1_input.trafoXML -out_chrom OpenSwathWorkflow_10.chrom.mzML.tmp -out_features OpenSwathWorkflow_10.featureXML.tmp -swath_windows_file swath_windows_overlap.txt -force ${OLD_OSW_PARAM}  > TOPP_OpenSwathWorkflow_10.stdout 2> TOPP_OpenSwathWorkflow_10.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathWorkflow_10 failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathWorkflow_10.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathWorkflow_10.stdout)";fi
echo executing "TOPP_OpenSwathWorkflow_11"
OpenSwathWorkflow -in OpenSwathWorkflow_11_input.mzML -tr_irt OpenSwathWorkflow_11_input.TraML -tr OpenSwathWorkflow_11_input.TraML -out_chrom OpenSwathWorkflow_11.chrom.mzML.tmp -out_features OpenSwathWorkflow_11.featureXML.tmp -mz_extraction_window 0.2 -rt_extraction_window -1 -Scoring:Scores:use_sonar_scores -sonar -RTNormalization:outlierMethod none -mz_correction_function quadratic_regression_delta_ppm -irt_mz_extraction_window 550 -irt_mz_extraction_window_unit ppm -enable_ms1 "false" ${OLD_OSW_PARAM}  > TOPP_OpenSwathWorkflow_11.stdout 2> TOPP_OpenSwathWorkflow_11.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathWorkflow_11 failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathWorkflow_11.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathWorkflow_11.stdout)";fi
echo executing "TOPP_OpenSwathWorkflow_13_prepare"
TargetedFileConverter -test -in OpenSwathWorkflow_1_input.TraML -out OpenSwathWorkflow_13_input.pqp.tmp -out_type pqp > TOPP_OpenSwathWorkflow_13_prepare.stdout 2> TOPP_OpenSwathWorkflow_13_prepare.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathWorkflow_13_prepare failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathWorkflow_13_prepare.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathWorkflow_13_prepare.stdout)";fi
echo executing "TOPP_OpenSwathWorkflow_13"
OpenSwathWorkflow -in OpenSwathWorkflow_1_input.mzML -tr OpenSwathWorkflow_13_input.pqp.tmp -tr_type pqp -rt_norm OpenSwathWorkflow_1_input.trafoXML -out_chrom OpenSwathWorkflow_13.chrom.mzML.tmp -out_osw OpenSwathWorkflow_13.osw ${OLD_OSW_PARAM}  > TOPP_OpenSwathWorkflow_13.stdout 2> TOPP_OpenSwathWorkflow_13.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathWorkflow_13 failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathWorkflow_13.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathWorkflow_13.stdout)";fi
echo executing "TOPP_OpenSwathWorkflow_14_prepare"
TargetedFileConverter -test -in OpenSwathWorkflow_1_input.TraML -out OpenSwathWorkflow_14_input.pqp.tmp -out_type pqp > TOPP_OpenSwathWorkflow_14_prepare.stdout 2> TOPP_OpenSwathWorkflow_14_prepare.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathWorkflow_14_prepare failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathWorkflow_14_prepare.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathWorkflow_14_prepare.stdout)";fi
echo executing "TOPP_OpenSwathWorkflow_14"
OpenSwathWorkflow -in OpenSwathWorkflow_1_input.mzML -tr OpenSwathWorkflow_14_input.pqp.tmp -tr_type pqp -rt_norm OpenSwathWorkflow_1_input.trafoXML -out_chrom OpenSwathWorkflow_14.chrom.tmp.sqMass -out_osw OpenSwathWorkflow_14.osw ${OLD_OSW_PARAM}  > TOPP_OpenSwathWorkflow_14.stdout 2> TOPP_OpenSwathWorkflow_14.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathWorkflow_14 failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathWorkflow_14.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathWorkflow_14.stdout)";fi
echo executing "TOPP_OpenSwathWorkflow_14_step2"
OpenSwathMzMLFileCacher -in OpenSwathWorkflow_14.chrom.tmp.sqMass -out OpenSwathWorkflow_14.chrom.tmp.mzML -test -lossy_compression false -lossy_mass_accuracy 1e-4 -full_meta false > TOPP_OpenSwathWorkflow_14_step2.stdout 2> TOPP_OpenSwathWorkflow_14_step2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathWorkflow_14_step2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathWorkflow_14_step2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathWorkflow_14_step2.stdout)";fi
echo executing "TOPP_OpenSwathWorkflow_15"
OpenSwathWorkflow -in OpenSwathWorkflow_15_input.mzML -tr OpenSwathWorkflow_1_input.TraML -rt_norm OpenSwathWorkflow_1_input.trafoXML -out_chrom OpenSwathWorkflow_15.chrom.mzML.tmp -out_features OpenSwathWorkflow_15.featureXML.tmp -Scoring:TransitionGroupPicker:use_precursors -ms1_isotopes 2 "-test" "-mz_extraction_window" "0.05" "-mz_extraction_window_unit" "Th" "-Scoring:Scores:use_ms1_mi" "false" "-Scoring:Scores:use_mi_score" "false" > TOPP_OpenSwathWorkflow_15.stdout 2> TOPP_OpenSwathWorkflow_15.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathWorkflow_15 failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathWorkflow_15.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathWorkflow_15.stdout)";fi
echo executing "TOPP_OpenSwathWorkflow_16_prepare"
OpenSwathMzMLFileCacher -in OpenSwathWorkflow_1_input.mzML -out OpenSwathWorkflow_16_input.sqMass -test -lossy_compression true -lossy_mass_accuracy 1e-4 -full_meta true > TOPP_OpenSwathWorkflow_16_prepare.stdout 2> TOPP_OpenSwathWorkflow_16_prepare.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathWorkflow_16_prepare failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathWorkflow_16_prepare.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathWorkflow_16_prepare.stdout)";fi
echo executing "TOPP_OpenSwathWorkflow_16"
OpenSwathWorkflow -in OpenSwathWorkflow_16_input.sqMass -tr OpenSwathWorkflow_1_input.TraML -rt_norm OpenSwathWorkflow_1_input.trafoXML -out_chrom OpenSwathWorkflow_16.chrom.mzML.tmp -out_features OpenSwathWorkflow_16.featureXML.tmp -readOptions workingInMemory -ms1_isotopes 2 ${OLD_OSW_PARAM}  > TOPP_OpenSwathWorkflow_16.stdout 2> TOPP_OpenSwathWorkflow_16.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathWorkflow_16 failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathWorkflow_16.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathWorkflow_16.stdout)";fi
echo executing "TOPP_OpenSwathWorkflow_17"
OpenSwathWorkflow -in OpenSwathWorkflow_17_input.mzML -tr OpenSwathWorkflow_17_input.tsv -out_chrom OpenSwathWorkflow_17.chrom.mzML.tmp -out_features OpenSwathWorkflow_17.featureXML.tmp -readOptions workingInMemory -ion_mobility_window 0.05 -use_ms1_ion_mobility "false" -Scoring:Scores:use_ion_mobility_scores ${OLD_OSW_PARAM}  > TOPP_OpenSwathWorkflow_17.stdout 2> TOPP_OpenSwathWorkflow_17.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathWorkflow_17 failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathWorkflow_17.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathWorkflow_17.stdout)";fi
echo executing "TOPP_OpenSwathWorkflow_17_cache"
OpenSwathWorkflow -in OpenSwathWorkflow_17_input.mzML -tr OpenSwathWorkflow_17_input.tsv -out_chrom OpenSwathWorkflow_17.chrom.mzML.tmp -out_features OpenSwathWorkflow_17.featureXML.tmp -readOptions cache -ion_mobility_window 0.05 -use_ms1_ion_mobility "false" -Scoring:Scores:use_ion_mobility_scores ${OLD_OSW_PARAM}  > TOPP_OpenSwathWorkflow_17_cache.stdout 2> TOPP_OpenSwathWorkflow_17_cache.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathWorkflow_17_cache failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathWorkflow_17_cache.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathWorkflow_17_cache.stdout)";fi
echo executing "TOPP_OpenSwathWorkflow_17_b_prepare"
TargetedFileConverter -test -in OpenSwathWorkflow_17_input.tsv -out OpenSwathWorkflow_17_input.pqp.tmp -out_type pqp > TOPP_OpenSwathWorkflow_17_b_prepare.stdout 2> TOPP_OpenSwathWorkflow_17_b_prepare.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathWorkflow_17_b_prepare failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathWorkflow_17_b_prepare.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathWorkflow_17_b_prepare.stdout)";fi
echo executing "TOPP_OpenSwathWorkflow_17_b"
OpenSwathWorkflow -in OpenSwathWorkflow_17_input.mzML -tr_type pqp -tr OpenSwathWorkflow_17_input.pqp.tmp -out_chrom OpenSwathWorkflow_17_b.chrom.mzML.tmp -out_features OpenSwathWorkflow_17_b.featureXML.tmp -readOptions workingInMemory -ion_mobility_window 0.05 -use_ms1_ion_mobility "false" ${OLD_OSW_PARAM}  > TOPP_OpenSwathWorkflow_17_b.stdout 2> TOPP_OpenSwathWorkflow_17_b.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathWorkflow_17_b failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathWorkflow_17_b.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathWorkflow_17_b.stdout)";fi
echo executing "TOPP_OpenSwathFileSplitter_1"
OpenSwathFileSplitter -in OpenSwathWorkflow_1_input.mzML -outputDirectory ""  -out_qc OpenSwathFileSplitter_1.json.tmp -test > TOPP_OpenSwathFileSplitter_1.stdout 2> TOPP_OpenSwathFileSplitter_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathFileSplitter_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathFileSplitter_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathFileSplitter_1.stdout)";fi
echo executing "TOPP_OpenSwathWorkflow_18"
OpenSwathWorkflow -in OpenSwathWorkflow_1_input.mzML -tr OpenSwathWorkflow_1_input.TraML -rt_norm OpenSwathWorkflow_1_input.trafoXML -out_features OpenSwathWorkflow_18.featureXML.tmp "-test" "-mz_extraction_window" "0.05" "-mz_extraction_window_unit" "Th" "-ms1_isotopes" "0" "-Scoring:TransitionGroupPicker:compute_peak_quality" "-Scoring:Scores:use_mi_score" "false" > TOPP_OpenSwathWorkflow_18.stdout 2> TOPP_OpenSwathWorkflow_18.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathWorkflow_18 failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathWorkflow_18.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathWorkflow_18.stdout)";fi
echo executing "TOPP_OpenSwathWorkflow_19"
OpenSwathWorkflow -in OpenSwathWorkflow_1_input.mzML -tr OpenSwathWorkflow_1_input.TraML -rt_norm OpenSwathWorkflow_1_input.trafoXML -out_features OpenSwathWorkflow_19.featureXML.tmp "-test" "-mz_extraction_window" "0.05" "-mz_extraction_window_unit" "Th" "-ms1_isotopes" "0" "-Scoring:TransitionGroupPicker:compute_peak_quality" "-Scoring:Scores:use_ms1_mi" "false" > TOPP_OpenSwathWorkflow_19.stdout 2> TOPP_OpenSwathWorkflow_19.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathWorkflow_19 failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathWorkflow_19.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathWorkflow_19.stdout)";fi
echo executing "TOPP_OpenSwathWorkflow_20"
OpenSwathWorkflow -in OpenSwathWorkflow_1_input.mzML -tr OpenSwathWorkflow_1_input.TraML -rt_norm OpenSwathWorkflow_1_input.trafoXML -out_features OpenSwathWorkflow_20.featureXML.tmp "-test" "-mz_extraction_window" "0.05" "-mz_extraction_window_unit" "Th" "-ms1_isotopes" "0" "-Scoring:TransitionGroupPicker:compute_peak_quality" "-Scoring:Scores:use_total_mi_score" "-Scoring:Scores:use_ms1_mi" "false"  > TOPP_OpenSwathWorkflow_20.stdout 2> TOPP_OpenSwathWorkflow_20.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathWorkflow_20 failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathWorkflow_20.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathWorkflow_20.stdout)";fi
echo executing "TOPP_OpenSwathWorkflow_21"
OpenSwathWorkflow -in OpenSwathWorkflow_21_input.mzML -tr OpenSwathWorkflow_21_input.tsv -tr_irt OpenSwathWorkflow_21_input.irt.TraML -out_features OpenSwathWorkflow_21.featureXML.tmp -Debugging:irt_trafo OpenSwathWorkflow_21.trafoXML.tmp -out_chrom OpenSwathWorkflow_21.mzML.tmp -RTNormalization:lowess:span 0.666666666666666666666666666 "-test" "-mz_extraction_window" "0.05" "-mz_extraction_window_unit" "Th" "-ms1_isotopes" "0" "-Scoring:Scores:use_total_mi_score" "-Scoring:Scores:use_ms1_mi" "false" "-Scoring:TransitionGroupPicker:compute_peak_quality" > TOPP_OpenSwathWorkflow_21.stdout 2> TOPP_OpenSwathWorkflow_21.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathWorkflow_21 failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathWorkflow_21.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathWorkflow_21.stdout)";fi
echo executing "TOPP_OpenSwathWorkflow_22"
OpenSwathWorkflow -in OpenSwathWorkflow_22_input.mzML -tr OpenSwathWorkflow_22_input.tsv -out_chrom OpenSwathWorkflow_22.chrom.mzML.tmp -out_features OpenSwathWorkflow_22.featureXML.tmp -readOptions workingInMemory -matching_window_only "true" -ms1_isotopes 3 ${OLD_OSW_PARAM}  > TOPP_OpenSwathWorkflow_22.stdout 2> TOPP_OpenSwathWorkflow_22.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenSwathWorkflow_22 failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenSwathWorkflow_22.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenSwathWorkflow_22.stdout)";fi
echo executing "TOPP_NoiseFilterGaussian_1"
NoiseFilterGaussian -test -ini NoiseFilterGaussian_1_parameters.ini -in NoiseFilterGaussian_1_input.mzML -out NoiseFilterGaussian_1.tmp > TOPP_NoiseFilterGaussian_1.stdout 2> TOPP_NoiseFilterGaussian_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_NoiseFilterGaussian_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_NoiseFilterGaussian_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_NoiseFilterGaussian_1.stdout)";fi
echo executing "TOPP_NoiseFilterGaussian_2"
NoiseFilterGaussian -test -ini NoiseFilterGaussian_2_parameters.ini -in NoiseFilterGaussian_2_input.chrom.mzML -out NoiseFilterGaussian_2.tmp > TOPP_NoiseFilterGaussian_2.stdout 2> TOPP_NoiseFilterGaussian_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_NoiseFilterGaussian_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_NoiseFilterGaussian_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_NoiseFilterGaussian_2.stdout)";fi
echo executing "TOPP_NoiseFilterGaussian_3"
NoiseFilterGaussian -test -ini NoiseFilterGaussian_1_parameters.ini -in NoiseFilterGaussian_1_input.mzML -out NoiseFilterGaussian_3.tmp -processOption lowmemory > TOPP_NoiseFilterGaussian_3.stdout 2> TOPP_NoiseFilterGaussian_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_NoiseFilterGaussian_3 failed'; >&2 echo -e "stderr:\n$(cat TOPP_NoiseFilterGaussian_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_NoiseFilterGaussian_3.stdout)";fi
echo executing "TOPP_NoiseFilterGaussian_4"
NoiseFilterGaussian -test -ini NoiseFilterGaussian_2_parameters.ini -in NoiseFilterGaussian_2_input.chrom.mzML -out NoiseFilterGaussian_4.tmp -processOption lowmemory > TOPP_NoiseFilterGaussian_4.stdout 2> TOPP_NoiseFilterGaussian_4.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_NoiseFilterGaussian_4 failed'; >&2 echo -e "stderr:\n$(cat TOPP_NoiseFilterGaussian_4.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_NoiseFilterGaussian_4.stdout)";fi
echo executing "TOPP_NoiseFilterSGolay_1"
NoiseFilterSGolay -test -ini NoiseFilterSGolay_1_parameters.ini -in NoiseFilterSGolay_1_input.mzML -out NoiseFilterSGolay_1.tmp > TOPP_NoiseFilterSGolay_1.stdout 2> TOPP_NoiseFilterSGolay_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_NoiseFilterSGolay_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_NoiseFilterSGolay_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_NoiseFilterSGolay_1.stdout)";fi
echo executing "TOPP_NoiseFilterSGolay_2"
NoiseFilterSGolay -test -ini NoiseFilterSGolay_2_parameters.ini -in NoiseFilterSGolay_2_input.chrom.mzML -out NoiseFilterSGolay_2.tmp > TOPP_NoiseFilterSGolay_2.stdout 2> TOPP_NoiseFilterSGolay_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_NoiseFilterSGolay_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_NoiseFilterSGolay_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_NoiseFilterSGolay_2.stdout)";fi
echo executing "TOPP_NoiseFilterSGolay_3"
NoiseFilterSGolay -test -ini NoiseFilterSGolay_1_parameters.ini -in NoiseFilterSGolay_1_input.mzML -out NoiseFilterSGolay_3.tmp -processOption lowmemory > TOPP_NoiseFilterSGolay_3.stdout 2> TOPP_NoiseFilterSGolay_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_NoiseFilterSGolay_3 failed'; >&2 echo -e "stderr:\n$(cat TOPP_NoiseFilterSGolay_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_NoiseFilterSGolay_3.stdout)";fi
echo executing "TOPP_NoiseFilterSGolay_4"
NoiseFilterSGolay -test -ini NoiseFilterSGolay_2_parameters.ini -in NoiseFilterSGolay_2_input.chrom.mzML -out NoiseFilterSGolay_4.tmp -processOption lowmemory > TOPP_NoiseFilterSGolay_4.stdout 2> TOPP_NoiseFilterSGolay_4.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_NoiseFilterSGolay_4 failed'; >&2 echo -e "stderr:\n$(cat TOPP_NoiseFilterSGolay_4.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_NoiseFilterSGolay_4.stdout)";fi
echo executing "TOPP_PeakPickerWavelet_1"
PeakPickerWavelet  -test -ini PeakPickerWavelet_parameters.ini -in PeakPickerWavelet_input.mzML -out PeakPickerWavelet_1.tmp > TOPP_PeakPickerWavelet_1.stdout 2> TOPP_PeakPickerWavelet_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_PeakPickerWavelet_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_PeakPickerWavelet_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_PeakPickerWavelet_1.stdout)";fi
echo executing "TOPP_PeakPickerWavelet_2"
PeakPickerWavelet  -test -ini PeakPickerWavelet_deconv_parameters.ini -in PeakPickerWavelet_deconv_input.mzML -out PeakPickerWavelet_2.tmp > TOPP_PeakPickerWavelet_2.stdout 2> TOPP_PeakPickerWavelet_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_PeakPickerWavelet_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_PeakPickerWavelet_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_PeakPickerWavelet_2.stdout)";fi
echo executing "TOPP_PeakPickerWavelet_4"
PeakPickerWavelet  -test -ini PeakPickerWavelet_parameters.ini -in PeakPickerWavelet_input.mzML -out PeakPickerWavelet_4.tmp -threads 2 > TOPP_PeakPickerWavelet_4.stdout 2> TOPP_PeakPickerWavelet_4.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_PeakPickerWavelet_4 failed'; >&2 echo -e "stderr:\n$(cat TOPP_PeakPickerWavelet_4.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_PeakPickerWavelet_4.stdout)";fi
echo executing "TOPP_PeakPickerWavelet_5"
PeakPickerWavelet  -test -ini PeakPickerWavelet_parameters_noMetaData.ini -in PeakPickerWavelet_input.mzML -out PeakPickerWavelet_5.tmp -threads 2 > TOPP_PeakPickerWavelet_5.stdout 2> TOPP_PeakPickerWavelet_5.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_PeakPickerWavelet_5 failed'; >&2 echo -e "stderr:\n$(cat TOPP_PeakPickerWavelet_5.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_PeakPickerWavelet_5.stdout)";fi
echo executing "TOPP_PeakPickerHiRes_1"
PeakPickerHiRes -test -ini PeakPickerHiRes_parameters.ini -in PeakPickerHiRes_input.mzML -out PeakPickerHiRes_1.tmp > TOPP_PeakPickerHiRes_1.stdout 2> TOPP_PeakPickerHiRes_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_PeakPickerHiRes_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_PeakPickerHiRes_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_PeakPickerHiRes_1.stdout)";fi
echo executing "TOPP_PeakPickerHiRes_2"
PeakPickerHiRes -test -ini PeakPickerHiRes_parameters.ini -in PeakPickerHiRes_2_input.mzML -out PeakPickerHiRes_2.tmp > TOPP_PeakPickerHiRes_2.stdout 2> TOPP_PeakPickerHiRes_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_PeakPickerHiRes_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_PeakPickerHiRes_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_PeakPickerHiRes_2.stdout)";fi
echo executing "TOPP_PeakPickerHiRes_3"
PeakPickerHiRes -test -ini PeakPickerHiRes_parameters.ini -in PeakPickerHiRes_input.mzML -out PeakPickerHiRes_3.tmp -processOption lowmemory > TOPP_PeakPickerHiRes_3.stdout 2> TOPP_PeakPickerHiRes_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_PeakPickerHiRes_3 failed'; >&2 echo -e "stderr:\n$(cat TOPP_PeakPickerHiRes_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_PeakPickerHiRes_3.stdout)";fi
echo executing "TOPP_PeakPickerHiRes_4"
PeakPickerHiRes -test -ini PeakPickerHiRes_parameters.ini -in PeakPickerHiRes_2_input.mzML -out PeakPickerHiRes_4.tmp -processOption lowmemory > TOPP_PeakPickerHiRes_4.stdout 2> TOPP_PeakPickerHiRes_4.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_PeakPickerHiRes_4 failed'; >&2 echo -e "stderr:\n$(cat TOPP_PeakPickerHiRes_4.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_PeakPickerHiRes_4.stdout)";fi
echo executing "TOPP_PeakPickerHiRes_5"
PeakPickerHiRes -test -in PeakPickerHiRes_5_input.mzML -out PeakPickerHiRes_5.tmp > TOPP_PeakPickerHiRes_5.stdout 2> TOPP_PeakPickerHiRes_5.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_PeakPickerHiRes_5 failed'; >&2 echo -e "stderr:\n$(cat TOPP_PeakPickerHiRes_5.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_PeakPickerHiRes_5.stdout)";fi
echo executing "UTILS_PeakPickerIterative_1"
PeakPickerIterative -in PeakPickerIterative_1_input.mzML -ini PeakPickerIterative_1.ini -out PeakPickerIterative.mzML.tmp -test > UTILS_PeakPickerIterative_1.stdout 2> UTILS_PeakPickerIterative_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_PeakPickerIterative_1 failed'; >&2 echo -e "stderr:\n$(cat UTILS_PeakPickerIterative_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_PeakPickerIterative_1.stdout)";fi
echo executing "UTILS_PeakPickerIterative_2"
PeakPickerIterative -in PeakPickerIterative_2_input.mzML -ini PeakPickerIterative_2.ini -out PeakPickerIterative_2.mzML.tmp -test > UTILS_PeakPickerIterative_2.stdout 2> UTILS_PeakPickerIterative_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_PeakPickerIterative_2 failed'; >&2 echo -e "stderr:\n$(cat UTILS_PeakPickerIterative_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_PeakPickerIterative_2.stdout)";fi
echo executing "TOPP_ProteinInference_1"
ProteinInference -test -in ProteinInference_1_input.idXML -out ProteinInference_1_output.tmp -Algorithm:use_shared_peptides false -merge_runs all -Merging:annotate_origin false > TOPP_ProteinInference_1.stdout 2> TOPP_ProteinInference_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_ProteinInference_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_ProteinInference_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_ProteinInference_1.stdout)";fi
echo executing "TOPP_ProteinInference_2"
ProteinInference -test -in Epifany_2_input.consensusXML -out ProteinInference_2_output.tmp -Algorithm:use_shared_peptides false -out_type consensusXML > TOPP_ProteinInference_2.stdout 2> TOPP_ProteinInference_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_ProteinInference_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_ProteinInference_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_ProteinInference_2.stdout)";fi
echo executing "TOPP_ProteinInference_3"
ProteinInference -test -in MSstatsConverter_3_in.consensusXML -out ProteinInference_3_output.tmp -Algorithm:use_shared_peptides true -picked_decoy_string "_rev" -picked_decoy_prefix "suffix" -protein_fdr true -out_type consensusXML > TOPP_ProteinInference_3.stdout 2> TOPP_ProteinInference_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_ProteinInference_3 failed'; >&2 echo -e "stderr:\n$(cat TOPP_ProteinInference_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_ProteinInference_3.stdout)";fi
echo executing "TOPP_Resampler_1"
Resampler -test -in Resampler_1_input.mzML -out Resampler.mzML -sampling_rate 0.3 > TOPP_Resampler_1.stdout 2> TOPP_Resampler_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_Resampler_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_Resampler_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_Resampler_1.stdout)";fi
echo executing "TOPP_RNPxlSearch_1"
RNPxlSearch -test -in RNPxlSearch_1_input.mzML -database RNPxlSearch_1_input.fasta -out RNPxlSearch_1_output.tmp -ini RNPxlSearch_1_parameters.ini > TOPP_RNPxlSearch_1.stdout 2> TOPP_RNPxlSearch_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_RNPxlSearch_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_RNPxlSearch_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_RNPxlSearch_1.stdout)";fi
echo executing "TOPP_RNPxlSearch_2"
RNPxlSearch -test -in RNPxlSearch_1_input.mzML -database RNPxlSearch_1_input.fasta -out RNPxlSearch_2_output.tmp -RNPxl:decoys -ini RNPxlSearch_1_parameters.ini > TOPP_RNPxlSearch_2.stdout 2> TOPP_RNPxlSearch_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_RNPxlSearch_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_RNPxlSearch_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_RNPxlSearch_2.stdout)";fi
echo executing "TOPP_RNPxlSearch_3"
RNPxlSearch -test -in RNPxlSearch_1_input.mzML -database RNPxlSearch_1_input.fasta -out RNPxlSearch_3_output.tmp -report:top_hits 3 -out_tsv RNPxlSearch_3_output2.tmp -precursor:mass_tolerance 10 -RNPxl:scoring fast > TOPP_RNPxlSearch_3.stdout 2> TOPP_RNPxlSearch_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_RNPxlSearch_3 failed'; >&2 echo -e "stderr:\n$(cat TOPP_RNPxlSearch_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_RNPxlSearch_3.stdout)";fi
echo executing "TOPP_RNPxlSearch_4"
RNPxlSearch -test -in RNPxlSearch_1_input.mzML -RNPxl:decoys -database RNPxlSearch_1_input.fasta -out RNPxlSearch_4_output.tmp -report:top_hits 2 -out_tsv RNPxlSearch_4_output2.tmp -precursor:mass_tolerance 10 -RNPxl:scoring fast > TOPP_RNPxlSearch_4.stdout 2> TOPP_RNPxlSearch_4.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_RNPxlSearch_4 failed'; >&2 echo -e "stderr:\n$(cat TOPP_RNPxlSearch_4.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_RNPxlSearch_4.stdout)";fi
echo executing "TOPP_RTModel_1"
RTModel -test -in RTModel_1_input.idXML -out RTModel_1_output.tmp -ini RTModel_1_parameters.ini > TOPP_RTModel_1.stdout 2> TOPP_RTModel_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_RTModel_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_RTModel_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_RTModel_1.stdout)";fi
echo executing "TOPP_RTModel_2"
RTModel -test -in_positive RTModel_2_input_positive.idXML -in_negative RTModel_2_input_negative.idXML -out RTModel_2_output.tmp -ini RTModel_2_parameters.ini > TOPP_RTModel_2.stdout 2> TOPP_RTModel_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_RTModel_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_RTModel_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_RTModel_2.stdout)";fi
echo executing "TOPP_RTModel_3"
RTModel -test -in RTModel_3_input.idXML -out RTModel_3_output.tmp -ini RTModel_3_parameters.ini > TOPP_RTModel_3.stdout 2> TOPP_RTModel_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_RTModel_3 failed'; >&2 echo -e "stderr:\n$(cat TOPP_RTModel_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_RTModel_3.stdout)";fi
echo executing "TOPP_RTModel_4"
RTModel -test -in RTModel_4_input.txt -out RTModel_4_output.tmp -ini RTModel_4_parameters.ini > TOPP_RTModel_4.stdout 2> TOPP_RTModel_4.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_RTModel_4 failed'; >&2 echo -e "stderr:\n$(cat TOPP_RTModel_4.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_RTModel_4.stdout)";fi
echo executing "TOPP_PTModel_1"
PTModel -test -in_positive PTModel_1_input_positive.idXML -in_negative PTModel_1_input_negative.idXML -out PTModel_1_output.tmp -ini PTModel_1_parameters.ini > TOPP_PTModel_1.stdout 2> TOPP_PTModel_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_PTModel_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_PTModel_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_PTModel_1.stdout)";fi
echo executing "TOPP_PTPredict_1"
PTPredict -test -in PTPredict_1_input.idXML -out PTPredict_1_output.tmp -svm_model PTPredict_1_input.model > TOPP_PTPredict_1.stdout 2> TOPP_PTPredict_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_PTPredict_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_PTPredict_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_PTPredict_1.stdout)";fi
echo executing "TOPP_RTPredict_1"
RTPredict -test -in_id RTPredict_1_input.idXML -out_id:file RTPredict_1_output.tmp -total_gradient_time 3000 -svm_model RTPredict_1_input.model > TOPP_RTPredict_1.stdout 2> TOPP_RTPredict_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_RTPredict_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_RTPredict_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_RTPredict_1.stdout)";fi
echo executing "TOPP_RTPredict_2"
RTPredict -test -in_id RTPredict_2_input.idXML -out_id:positive RTPredict_2_output_positive.tmp -out_id:negative RTPredict_2_output_negative.tmp -svm_model RTPredict_2_input.model -in_oligo_params RTPredict_2_input.model_additional_parameters.paramXML -in_oligo_trainset RTPredict_2_input.model_samples > TOPP_RTPredict_2.stdout 2> TOPP_RTPredict_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_RTPredict_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_RTPredict_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_RTPredict_2.stdout)";fi
echo executing "TOPP_RTPredict_3"
RTPredict -test -in_id RTPredict_3_input.idXML -out_id:file RTPredict_3_output.tmp -total_gradient_time 1 -svm_model RTPredict_3_input.model -in_oligo_params RTPredict_3_input.model_additional_parameters.paramXML -in_oligo_trainset RTPredict_3_input.model_samples > TOPP_RTPredict_3.stdout 2> TOPP_RTPredict_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_RTPredict_3 failed'; >&2 echo -e "stderr:\n$(cat TOPP_RTPredict_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_RTPredict_3.stdout)";fi
echo executing "TOPP_RTPredict_4"
RTPredict -test -in_text RTPredict_4_input.txt -out_text:file RTPredict_4_output.tmp -total_gradient_time 1 -svm_model RTPredict_4_input.model -in_oligo_params RTPredict_4_input.model_additional_parameters.paramXML -in_oligo_trainset RTPredict_4_input.model_samples > TOPP_RTPredict_4.stdout 2> TOPP_RTPredict_4.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_RTPredict_4 failed'; >&2 echo -e "stderr:\n$(cat TOPP_RTPredict_4.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_RTPredict_4.stdout)";fi
echo executing "TOPP_RTPredict_5"
RTPredict -test -in_id RTPredict_5_input.idXML -out_text:file RTPredict_5_output.tmp -total_gradient_time 1 -svm_model RTPredict_5_input.model -in_oligo_params RTPredict_5_input.model_additional_parameters.paramXML -in_oligo_trainset RTPredict_5_input.model_samples > TOPP_RTPredict_5.stdout 2> TOPP_RTPredict_5.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_RTPredict_5 failed'; >&2 echo -e "stderr:\n$(cat TOPP_RTPredict_5.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_RTPredict_5.stdout)";fi
echo executing "TOPP_SeedListGenerator_1"
SeedListGenerator -test -in PepXMLFile_test.mzML -out_prefix SeedListGenerator_1_output_tmp > TOPP_SeedListGenerator_1.stdout 2> TOPP_SeedListGenerator_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_SeedListGenerator_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_SeedListGenerator_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_SeedListGenerator_1.stdout)";fi
echo executing "TOPP_SeedListGenerator_2"
SeedListGenerator -test -in IDMapper_1_output.featureXML -out_prefix SeedListGenerator_2_output_tmp > TOPP_SeedListGenerator_2.stdout 2> TOPP_SeedListGenerator_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_SeedListGenerator_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_SeedListGenerator_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_SeedListGenerator_2.stdout)";fi
echo executing "TOPP_SeedListGenerator_3"
SeedListGenerator -test -in ConsensusXMLFile_1.consensusXML -out_prefix SeedListGenerator_3_output_tmp > TOPP_SeedListGenerator_3.stdout 2> TOPP_SeedListGenerator_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_SeedListGenerator_3 failed'; >&2 echo -e "stderr:\n$(cat TOPP_SeedListGenerator_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_SeedListGenerator_3.stdout)";fi
echo executing "TOPP_SpectraFilterSqrtMower_1"
SpectraFilterSqrtMower -test -in SpectraFilterSqrtMower_1_input.mzML -out SpectraFilterSqrtMower.tmp > TOPP_SpectraFilterSqrtMower_1.stdout 2> TOPP_SpectraFilterSqrtMower_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_SpectraFilterSqrtMower_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_SpectraFilterSqrtMower_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_SpectraFilterSqrtMower_1.stdout)";fi
echo executing "TOPP_SpectraFilterWindowMower_1"
SpectraFilterWindowMower -test -in SpectraFilterWindowMower_1_input.mzML -out SpectraFilterWindowMower_1.tmp > TOPP_SpectraFilterWindowMower_1.stdout 2> TOPP_SpectraFilterWindowMower_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_SpectraFilterWindowMower_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_SpectraFilterWindowMower_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_SpectraFilterWindowMower_1.stdout)";fi
echo executing "TOPP_SpectraFilterWindowMower_2"
SpectraFilterWindowMower -test -in SpectraFilterWindowMower_2_input.mzML -out SpectraFilterWindowMower_2.tmp -ini SpectraFilterWindowMower_2_parameters.ini > TOPP_SpectraFilterWindowMower_2.stdout 2> TOPP_SpectraFilterWindowMower_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_SpectraFilterWindowMower_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_SpectraFilterWindowMower_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_SpectraFilterWindowMower_2.stdout)";fi
echo executing "TOPP_InternalCalibration_1"
InternalCalibration -test -in InternalCalibration_1_BSA1.mzML -cal:id_in InternalCalibration_1_BSA1_OMSSA.idXML -out InternalCalibration_1_BSA1_out.mzML.tmp -cal:model_type linear -RANSAC:enabled -RANSAC:iter 500 -RANSAC:threshold 1 -RT_chunking -1 -quality_control:models InternalCalibration_1_models.csv.tmp -quality_control:residuals InternalCalibration_1_residuals.csv.tmp -ms_level 1 > TOPP_InternalCalibration_1.stdout 2> TOPP_InternalCalibration_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_InternalCalibration_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_InternalCalibration_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_InternalCalibration_1.stdout)";fi
echo executing "TOPP_InternalCalibration_2"
InternalCalibration -test -in InternalCalibration_2_lockmass.mzML.gz -cal:lock_in InternalCalibration_2_lock.csv -out InternalCalibration_2_lockmass.mzML.tmp -cal:lock_require_mono -cal:model_type linear -RT_chunking 60 -quality_control:models InternalCalibration_2_models.csv.tmp -quality_control:residuals InternalCalibration_2_residuals.csv.tmp > TOPP_InternalCalibration_2.stdout 2> TOPP_InternalCalibration_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_InternalCalibration_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_InternalCalibration_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_InternalCalibration_2.stdout)";fi
echo executing "TOPP_InternalCalibration_2_convert"
FileConverter -test -in InternalCalibration_2_lockmass.mzML.tmp -no_progress -out InternalCalibration_2_out_lockmass.dta2d.tmp -out_type dta2d > TOPP_InternalCalibration_2_convert.stdout 2> TOPP_InternalCalibration_2_convert.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_InternalCalibration_2_convert failed'; >&2 echo -e "stderr:\n$(cat TOPP_InternalCalibration_2_convert.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_InternalCalibration_2_convert.stdout)";fi
echo executing "TOPP_ExternalCalibration_1_MS1"
ExternalCalibration -test -in ExternalCalibration_1_input.mzML -out ExternalCalibration_1_MS1_out.mzML.tmp -offset -5.5 -slope 0.0001 -ms_level 1 > TOPP_ExternalCalibration_1_MS1.stdout 2> TOPP_ExternalCalibration_1_MS1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_ExternalCalibration_1_MS1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_ExternalCalibration_1_MS1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_ExternalCalibration_1_MS1.stdout)";fi
echo executing "TOPP_ExternalCalibration_2_MS2"
ExternalCalibration -test -in ExternalCalibration_1_input.mzML -out ExternalCalibration_2_MS2_out.mzML.tmp -offset -5.5 -slope 0.0001 -ms_level 2 > TOPP_ExternalCalibration_2_MS2.stdout 2> TOPP_ExternalCalibration_2_MS2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_ExternalCalibration_2_MS2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_ExternalCalibration_2_MS2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_ExternalCalibration_2_MS2.stdout)";fi
echo executing "TOPP_TOFCalibration_1"
TOFCalibration -test -in TOFCalibration_1_input.mzML -out TOFCalibration.tmp -ref_masses TOFCalibration_ref_masses.tsv -ini TOFCalibration_parameters.ini -tof_const TOFCalibration_const.tsv -ext_calibrants TOFCalibration_1_calibrants.mzML > TOPP_TOFCalibration_1.stdout 2> TOPP_TOFCalibration_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_TOFCalibration_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_TOFCalibration_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_TOFCalibration_1.stdout)";fi
echo executing "TOPP_TOFCalibration_2"
TOFCalibration -test -in TOFCalibration_2_input.mzML -out TOFCalibration_2.tmp -ref_masses TOFCalibration_ref_masses.tsv -ini TOFCalibration_parameters.ini -tof_const TOFCalibration_const.tsv -ext_calibrants TOFCalibration_2_calibrants.mzML -peak_data > TOPP_TOFCalibration_2.stdout 2> TOPP_TOFCalibration_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_TOFCalibration_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_TOFCalibration_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_TOFCalibration_2.stdout)";fi
echo executing "TOPP_TextExporter_1"
TextExporter -test -in TextExporter_1_input.featureXML -no_progress -out TextExporter_1_output.tmp > TOPP_TextExporter_1.stdout 2> TOPP_TextExporter_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_TextExporter_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_TextExporter_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_TextExporter_1.stdout)";fi
echo executing "TOPP_TextExporter_2"
TextExporter -test -in TextExporter_2_input.consensusXML -ini TextExporter_2_parameters.ini > TOPP_TextExporter_2.stdout 2> TOPP_TextExporter_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_TextExporter_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_TextExporter_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_TextExporter_2.stdout)";fi
echo executing "TOPP_TextExporter_3"
TextExporter -test -in TextExporter_3_input.idXML -no_progress -out TextExporter_3_output.tmp > TOPP_TextExporter_3.stdout 2> TOPP_TextExporter_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_TextExporter_3 failed'; >&2 echo -e "stderr:\n$(cat TOPP_TextExporter_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_TextExporter_3.stdout)";fi
echo executing "TOPP_TextExporter_4"
TextExporter -test -in TextExporter_3_input.idXML -no_progress -out TextExporter_4_output.tmp -id:proteins_only > TOPP_TextExporter_4.stdout 2> TOPP_TextExporter_4.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_TextExporter_4 failed'; >&2 echo -e "stderr:\n$(cat TOPP_TextExporter_4.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_TextExporter_4.stdout)";fi
echo executing "TOPP_TextExporter_5"
TextExporter -test -in TextExporter_5_input.idXML -no_progress -out TextExporter_5_output.tmp -id:peptides_only -id:first_dim_rt > TOPP_TextExporter_5.stdout 2> TOPP_TextExporter_5.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_TextExporter_5 failed'; >&2 echo -e "stderr:\n$(cat TOPP_TextExporter_5.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_TextExporter_5.stdout)";fi
echo executing "TOPP_TextExporter_6"
TextExporter -test -in TextExporter_6_input.featureXML -no_progress -out TextExporter_6_output.tmp -no_ids > TOPP_TextExporter_6.stdout 2> TOPP_TextExporter_6.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_TextExporter_6 failed'; >&2 echo -e "stderr:\n$(cat TOPP_TextExporter_6.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_TextExporter_6.stdout)";fi
echo executing "TOPP_TextExporter_7"
TextExporter -test -in TextExporter_7_input.consensusXML -ini TextExporter_7_parameters.ini > TOPP_TextExporter_7.stdout 2> TOPP_TextExporter_7.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_TextExporter_7 failed'; >&2 echo -e "stderr:\n$(cat TOPP_TextExporter_7.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_TextExporter_7.stdout)";fi
echo executing "TOPP_TextExporter_8"
TextExporter -test -in TextExporter_1_input.featureXML -no_ids -no_progress -out TextExporter_8_output.tmp > TOPP_TextExporter_8.stdout 2> TOPP_TextExporter_8.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_TextExporter_8 failed'; >&2 echo -e "stderr:\n$(cat TOPP_TextExporter_8.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_TextExporter_8.stdout)";fi
echo executing "TOPP_TextExporter_9"
TextExporter -test -in TextExporter_9_input.idXML -no_progress -out TextExporter_9_output.tmp -id:add_metavalues 0 -id:add_hit_metavalues 0 > TOPP_TextExporter_9.stdout 2> TOPP_TextExporter_9.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_TextExporter_9 failed'; >&2 echo -e "stderr:\n$(cat TOPP_TextExporter_9.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_TextExporter_9.stdout)";fi
echo executing "TOPP_FeatureLinkerLabeled_1"
FeatureLinkerLabeled -test -ini FeatureLinkerLabeled_1_parameters.ini -in FeatureLinkerLabeled_1_input.featureXML -out FeatureLinkerLabeled_1_output.tmp > TOPP_FeatureLinkerLabeled_1.stdout 2> TOPP_FeatureLinkerLabeled_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FeatureLinkerLabeled_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FeatureLinkerLabeled_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FeatureLinkerLabeled_1.stdout)";fi
echo executing "TOPP_FeatureLinkerLabeled_2"
FeatureLinkerLabeled -test -ini FeatureLinkerLabeled_2_parameters.ini -in FeatureLinkerLabeled_2_input.featureXML -out FeatureLinkerLabeled_2_output.tmp > TOPP_FeatureLinkerLabeled_2.stdout 2> TOPP_FeatureLinkerLabeled_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FeatureLinkerLabeled_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FeatureLinkerLabeled_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FeatureLinkerLabeled_2.stdout)";fi
echo executing "TOPP_FeatureLinkerUnlabeled_1"
FeatureLinkerUnlabeled -test -ini FeatureLinkerUnlabeled_1_parameters.ini -in FeatureLinkerUnlabeled_1_input1.featureXML FeatureLinkerUnlabeled_1_input2.featureXML FeatureLinkerUnlabeled_1_input3.featureXML -out FeatureLinkerUnlabeled_1_output.tmp > TOPP_FeatureLinkerUnlabeled_1.stdout 2> TOPP_FeatureLinkerUnlabeled_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FeatureLinkerUnlabeled_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FeatureLinkerUnlabeled_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FeatureLinkerUnlabeled_1.stdout)";fi
echo executing "TOPP_FeatureLinkerUnlabeled_2"
FeatureLinkerUnlabeled -test -ini FeatureLinkerUnlabeled_2_parameters.ini -in FeatureLinkerUnlabeled_2_input1.featureXML FeatureLinkerUnlabeled_2_input2.featureXML FeatureLinkerUnlabeled_2_input3.featureXML -out FeatureLinkerUnlabeled_2_output.tmp > TOPP_FeatureLinkerUnlabeled_2.stdout 2> TOPP_FeatureLinkerUnlabeled_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FeatureLinkerUnlabeled_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FeatureLinkerUnlabeled_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FeatureLinkerUnlabeled_2.stdout)";fi
echo executing "TOPP_FeatureLinkerUnlabeled_3"
FeatureLinkerUnlabeled -test -ini FeatureLinkerUnlabeled_3_parameters.ini -in FeatureLinkerUnlabeled_3_input1.featureXML FeatureLinkerUnlabeled_3_input2.featureXML -out FeatureLinkerUnlabeled_3_output.tmp > TOPP_FeatureLinkerUnlabeled_3.stdout 2> TOPP_FeatureLinkerUnlabeled_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FeatureLinkerUnlabeled_3 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FeatureLinkerUnlabeled_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FeatureLinkerUnlabeled_3.stdout)";fi
echo executing "TOPP_FeatureLinkerUnlabeled_4"
FeatureLinkerUnlabeled -test -ini FeatureLinkerUnlabeled_4_parameters.ini -in FeatureLinkerUnlabeled_1_input1.featureXML FeatureLinkerUnlabeled_1_input2.featureXML FeatureLinkerUnlabeled_1_input3.featureXML -out FeatureLinkerUnlabeled_4_output.tmp > TOPP_FeatureLinkerUnlabeled_4.stdout 2> TOPP_FeatureLinkerUnlabeled_4.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FeatureLinkerUnlabeled_4 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FeatureLinkerUnlabeled_4.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FeatureLinkerUnlabeled_4.stdout)";fi
echo executing "TOPP_FeatureLinkerUnlabeledQT_1"
FeatureLinkerUnlabeledQT -test -ini FeatureLinkerUnlabeledQT_1_parameters.ini -in FeatureLinkerUnlabeled_1_input1.featureXML FeatureLinkerUnlabeled_1_input2.featureXML FeatureLinkerUnlabeled_1_input3.featureXML -out FeatureLinkerUnlabeledQT_1_output.tmp > TOPP_FeatureLinkerUnlabeledQT_1.stdout 2> TOPP_FeatureLinkerUnlabeledQT_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FeatureLinkerUnlabeledQT_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FeatureLinkerUnlabeledQT_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FeatureLinkerUnlabeledQT_1.stdout)";fi
echo executing "TOPP_FeatureLinkerUnlabeledQT_2"
FeatureLinkerUnlabeledQT -test -ini FeatureLinkerUnlabeledQT_2_parameters.ini -in FeatureLinkerUnlabeledQT_1_output.consensusXML FeatureLinkerUnlabeledQT_1_output.consensusXML -out FeatureLinkerUnlabeledQT_2_output.tmp > TOPP_FeatureLinkerUnlabeledQT_2.stdout 2> TOPP_FeatureLinkerUnlabeledQT_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FeatureLinkerUnlabeledQT_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FeatureLinkerUnlabeledQT_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FeatureLinkerUnlabeledQT_2.stdout)";fi
echo executing "TOPP_FeatureLinkerUnlabeledQT_3"
FeatureLinkerUnlabeledQT -test -ini FeatureLinkerUnlabeledQT_3_parameters.ini -in FeatureLinkerUnlabeledQT_3_input1.featureXML FeatureLinkerUnlabeledQT_3_input2.featureXML -out FeatureLinkerUnlabeledQT_3_output.tmp > TOPP_FeatureLinkerUnlabeledQT_3.stdout 2> TOPP_FeatureLinkerUnlabeledQT_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FeatureLinkerUnlabeledQT_3 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FeatureLinkerUnlabeledQT_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FeatureLinkerUnlabeledQT_3.stdout)";fi
echo executing "TOPP_FeatureLinkerUnlabeledQT_4"
FeatureLinkerUnlabeledQT -test -ini FeatureLinkerUnlabeledQT_1_parameters.ini -in FeatureLinkerUnlabeled_1_input1.featureXML FeatureLinkerUnlabeled_1_input2.featureXML FeatureLinkerUnlabeled_1_input3.featureXML -out FeatureLinkerUnlabeledQT_4_output.tmp -algorithm:use_identifications > TOPP_FeatureLinkerUnlabeledQT_4.stdout 2> TOPP_FeatureLinkerUnlabeledQT_4.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FeatureLinkerUnlabeledQT_4 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FeatureLinkerUnlabeledQT_4.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FeatureLinkerUnlabeledQT_4.stdout)";fi
echo executing "TOPP_FeatureLinkerUnlabeledQT_5"
FeatureLinkerUnlabeledQT -test -ini FeatureLinkerUnlabeledQT_1_parameters.ini -in FeatureLinkerUnlabeledQT_5_input1.featureXML FeatureLinkerUnlabeledQT_5_input2.featureXML FeatureLinkerUnlabeledQT_5_input3.featureXML -out FeatureLinkerUnlabeledQT_5_output.tmp -algorithm:distance_RT:max_difference 200 > TOPP_FeatureLinkerUnlabeledQT_5.stdout 2> TOPP_FeatureLinkerUnlabeledQT_5.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FeatureLinkerUnlabeledQT_5 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FeatureLinkerUnlabeledQT_5.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FeatureLinkerUnlabeledQT_5.stdout)";fi
echo executing "TOPP_FeatureLinkerUnlabeledQT_6"
FeatureLinkerUnlabeledQT -test -in FeatureLinkerUnlabeledQT_5_input1.featureXML FeatureLinkerUnlabeledQT_5_input2.featureXML FeatureLinkerUnlabeledQT_5_input3.featureXML -out FeatureLinkerUnlabeledQT_6_output.tmp -algorithm:use_identifications -algorithm:distance_RT:max_difference 200 > TOPP_FeatureLinkerUnlabeledQT_6.stdout 2> TOPP_FeatureLinkerUnlabeledQT_6.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FeatureLinkerUnlabeledQT_6 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FeatureLinkerUnlabeledQT_6.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FeatureLinkerUnlabeledQT_6.stdout)";fi
echo executing "TOPP_FeatureLinkerUnlabeledKD_1"
FeatureLinkerUnlabeledKD -test -ini FeatureLinkerUnlabeledKD_1_parameters.ini -in FeatureLinkerUnlabeled_1_input1.featureXML FeatureLinkerUnlabeled_1_input2.featureXML FeatureLinkerUnlabeled_1_input3.featureXML -out FeatureLinkerUnlabeledKD_1_output.tmp > TOPP_FeatureLinkerUnlabeledKD_1.stdout 2> TOPP_FeatureLinkerUnlabeledKD_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FeatureLinkerUnlabeledKD_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FeatureLinkerUnlabeledKD_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FeatureLinkerUnlabeledKD_1.stdout)";fi
echo executing "TOPP_FeatureLinkerUnlabeledKD_2"
FeatureLinkerUnlabeledKD -test -ini FeatureLinkerUnlabeledKD_2_parameters.ini -in FeatureLinkerUnlabeledKD_1_output.consensusXML FeatureLinkerUnlabeledKD_1_output.consensusXML -out FeatureLinkerUnlabeledKD_2_output.tmp > TOPP_FeatureLinkerUnlabeledKD_2.stdout 2> TOPP_FeatureLinkerUnlabeledKD_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FeatureLinkerUnlabeledKD_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FeatureLinkerUnlabeledKD_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FeatureLinkerUnlabeledKD_2.stdout)";fi
echo executing "TOPP_FeatureLinkerUnlabeledKD_3"
FeatureLinkerUnlabeledKD -test -ini FeatureLinkerUnlabeledKD_3_parameters.ini -in FeatureLinkerUnlabeledQT_3_input1.featureXML FeatureLinkerUnlabeledQT_3_input2.featureXML -out FeatureLinkerUnlabeledKD_3_output.tmp > TOPP_FeatureLinkerUnlabeledKD_3.stdout 2> TOPP_FeatureLinkerUnlabeledKD_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FeatureLinkerUnlabeledKD_3 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FeatureLinkerUnlabeledKD_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FeatureLinkerUnlabeledKD_3.stdout)";fi
echo executing "TOPP_FeatureLinkerUnlabeledKD_4"
FeatureLinkerUnlabeledKD -test -ini FeatureLinkerUnlabeledKD_4_parameters.ini -in FeatureLinkerUnlabeledKD_dc_input1.featureXML FeatureLinkerUnlabeledKD_dc_input2.featureXML FeatureLinkerUnlabeledKD_dc_input3.featureXML FeatureLinkerUnlabeledKD_dc_input1.featureXML FeatureLinkerUnlabeledKD_dc_input2.featureXML -out FeatureLinkerUnlabeledKD_4_output.tmp -algorithm:link:charge_merging Identical -algorithm:link:adduct_merging Any > TOPP_FeatureLinkerUnlabeledKD_4.stdout 2> TOPP_FeatureLinkerUnlabeledKD_4.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FeatureLinkerUnlabeledKD_4 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FeatureLinkerUnlabeledKD_4.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FeatureLinkerUnlabeledKD_4.stdout)";fi
echo executing "TOPP_FeatureLinkerUnlabeledKD_5"
FeatureLinkerUnlabeledKD -test -ini FeatureLinkerUnlabeledKD_4_parameters.ini -in FeatureLinkerUnlabeledKD_dc_input1.featureXML FeatureLinkerUnlabeledKD_dc_input2.featureXML FeatureLinkerUnlabeledKD_dc_input3.featureXML FeatureLinkerUnlabeledKD_dc_input1.featureXML FeatureLinkerUnlabeledKD_dc_input2.featureXML -out FeatureLinkerUnlabeledKD_5_output.tmp -algorithm:link:charge_merging With_charge_zero -algorithm:link:adduct_merging Any > TOPP_FeatureLinkerUnlabeledKD_5.stdout 2> TOPP_FeatureLinkerUnlabeledKD_5.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FeatureLinkerUnlabeledKD_5 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FeatureLinkerUnlabeledKD_5.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FeatureLinkerUnlabeledKD_5.stdout)";fi
echo executing "TOPP_FeatureLinkerUnlabeledKD_6"
FeatureLinkerUnlabeledKD -test -ini FeatureLinkerUnlabeledKD_4_parameters.ini -in FeatureLinkerUnlabeledKD_dc_input1.featureXML FeatureLinkerUnlabeledKD_dc_input2.featureXML FeatureLinkerUnlabeledKD_dc_input3.featureXML FeatureLinkerUnlabeledKD_dc_input1.featureXML FeatureLinkerUnlabeledKD_dc_input2.featureXML -out FeatureLinkerUnlabeledKD_6_output.tmp -algorithm:link:charge_merging Any -algorithm:link:adduct_merging With_unknown_adducts > TOPP_FeatureLinkerUnlabeledKD_6.stdout 2> TOPP_FeatureLinkerUnlabeledKD_6.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FeatureLinkerUnlabeledKD_6 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FeatureLinkerUnlabeledKD_6.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FeatureLinkerUnlabeledKD_6.stdout)";fi
echo executing "TOPP_FeatureLinkerUnlabeledKD_7"
FeatureLinkerUnlabeledKD -test -ini FeatureLinkerUnlabeledKD_4_parameters.ini -in FeatureLinkerUnlabeledKD_dc_input1.featureXML FeatureLinkerUnlabeledKD_dc_input2.featureXML FeatureLinkerUnlabeledKD_dc_input3.featureXML FeatureLinkerUnlabeledKD_dc_input1.featureXML FeatureLinkerUnlabeledKD_dc_input2.featureXML -out FeatureLinkerUnlabeledKD_7_output.tmp -algorithm:link:charge_merging Any -algorithm:link:adduct_merging Identical > TOPP_FeatureLinkerUnlabeledKD_7.stdout 2> TOPP_FeatureLinkerUnlabeledKD_7.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FeatureLinkerUnlabeledKD_7 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FeatureLinkerUnlabeledKD_7.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FeatureLinkerUnlabeledKD_7.stdout)";fi
echo executing "TOPP_IDMapper_1"
IDMapper -test -in IDMapper_1_input.featureXML -out IDMapper_1_output.tmp -id IDMapper_1_input.idXML -mz_measure Da -mz_tolerance 1 -ignore_charge -mz_reference precursor -feature:use_centroid_mz false > TOPP_IDMapper_1.stdout 2> TOPP_IDMapper_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDMapper_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDMapper_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDMapper_1.stdout)";fi
echo executing "TOPP_IDMapper_2"
IDMapper -test -in IDMapper_2_input.consensusXML -out IDMapper_2_output.tmp -id IDMapper_2_input.idXML  -mz_measure Da -mz_tolerance 1 -mz_reference precursor > TOPP_IDMapper_2.stdout 2> TOPP_IDMapper_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDMapper_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDMapper_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDMapper_2.stdout)";fi
echo executing "TOPP_IDMapper_3"
IDMapper -test -in IDMapper_3_input.featureXML -out IDMapper_3_output.tmp -id IDMapper_3_input.idXML  -mz_measure ppm -mz_tolerance 3 -rt_tolerance 4 -ignore_charge -mz_reference precursor > TOPP_IDMapper_3.stdout 2> TOPP_IDMapper_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDMapper_3 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDMapper_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDMapper_3.stdout)";fi
echo executing "TOPP_IDMapper_4"
IDMapper -test -in IDMapper_4_input.featureXML -out IDMapper_4_output.tmp -id IDMapper_4_input.idXML -spectra:in IDMapper_4_input.mzML -mz_measure ppm -mz_tolerance 20 -rt_tolerance 10 > TOPP_IDMapper_4.stdout 2> TOPP_IDMapper_4.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDMapper_4 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDMapper_4.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDMapper_4.stdout)";fi
echo executing "TOPP_IDMapper_5"
IDMapper -test -in IDMapper_5_input.featureXML -out IDMapper_5_output.tmp -id IDMapper_5_input.idXML -spectra:in IDMapper_5_input.mzML -mz_measure ppm -mz_tolerance 10 -rt_tolerance 20 -feature:use_centroid_mz false > TOPP_IDMapper_5.stdout 2> TOPP_IDMapper_5.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDMapper_5 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDMapper_5.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDMapper_5.stdout)";fi
echo executing "TOPP_IDRipper_1"
IDRipper -test -in IDRipper_1_input.idXML -out ./  > TOPP_IDRipper_1.stdout 2> TOPP_IDRipper_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDRipper_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDRipper_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDRipper_1.stdout)";fi
echo executing "TOPP_IDRipper_2"
IDRipper -test -in IDRipper_2_input.idXML -out ./ -numeric_filenames -split_ident_runs  > TOPP_IDRipper_2.stdout 2> TOPP_IDRipper_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDRipper_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDRipper_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDRipper_2.stdout)";fi
echo executing "TOPP_IDRipper_2a"
IDRipper -test -in IDRipper_2_input.idXML -out ./ -numeric_filenames  > TOPP_IDRipper_2a.stdout 2> TOPP_IDRipper_2a.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDRipper_2a failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDRipper_2a.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDRipper_2a.stdout)";fi
echo executing "TOPP_IDRipper_3_prep"
IDMerger -test -in IDRipper_3_input1.idXML IDRipper_3_input2.idXML -out IDRipper_3_output.tmp > TOPP_IDRipper_3_prep.stdout 2> TOPP_IDRipper_3_prep.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDRipper_3_prep failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDRipper_3_prep.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDRipper_3_prep.stdout)";fi
echo executing "TOPP_IDRipper_3"
IDRipper -test -in IDRipper_3_output.idXML -out ./ > TOPP_IDRipper_3.stdout 2> TOPP_IDRipper_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDRipper_3 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDRipper_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDRipper_3.stdout)";fi
echo executing "TOPP_ConsensusID_1"
ConsensusID -test -in ConsensusID_1_input.idXML -out ConsensusID_1_output.tmp -algorithm PEPMatrix -PEPMatrix:matrix PAM30MS > TOPP_ConsensusID_1.stdout 2> TOPP_ConsensusID_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_ConsensusID_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_ConsensusID_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_ConsensusID_1.stdout)";fi
echo executing "TOPP_ConsensusID_2"
ConsensusID -test -in ConsensusID_2_input.featureXML -out ConsensusID_2_output.tmp -algorithm average > TOPP_ConsensusID_2.stdout 2> TOPP_ConsensusID_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_ConsensusID_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_ConsensusID_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_ConsensusID_2.stdout)";fi
echo executing "TOPP_ConsensusID_3"
ConsensusID -test -in ConsensusID_3_input.consensusXML -out ConsensusID_3_output.tmp -algorithm best > TOPP_ConsensusID_3.stdout 2> TOPP_ConsensusID_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_ConsensusID_3 failed'; >&2 echo -e "stderr:\n$(cat TOPP_ConsensusID_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_ConsensusID_3.stdout)";fi
echo executing "TOPP_ConsensusID_4"
ConsensusID -test -in ConsensusID_1_input.idXML -out ConsensusID_4_output.tmp -algorithm PEPMatrix -PEPMatrix:matrix identity -filter:considered_hits 6 > TOPP_ConsensusID_4.stdout 2> TOPP_ConsensusID_4.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_ConsensusID_4 failed'; >&2 echo -e "stderr:\n$(cat TOPP_ConsensusID_4.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_ConsensusID_4.stdout)";fi
echo executing "TOPP_ConsensusID_5"
ConsensusID -test -in ConsensusID_1_input.idXML -out ConsensusID_5_output.tmp -algorithm PEPIons > TOPP_ConsensusID_5.stdout 2> TOPP_ConsensusID_5.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_ConsensusID_5 failed'; >&2 echo -e "stderr:\n$(cat TOPP_ConsensusID_5.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_ConsensusID_5.stdout)";fi
echo executing "TOPP_ConsensusID_6"
ConsensusID -test -in ConsensusID_1_input.idXML -out ConsensusID_6_output.tmp -algorithm best -filter:min_support 0.5 > TOPP_ConsensusID_6.stdout 2> TOPP_ConsensusID_6.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_ConsensusID_6 failed'; >&2 echo -e "stderr:\n$(cat TOPP_ConsensusID_6.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_ConsensusID_6.stdout)";fi
echo executing "TOPP_ConsensusID_7"
ConsensusID -test -in ConsensusID_6_input.idXML -out ConsensusID_7_output.tmp -algorithm best -per_spectrum -filter:keep_old_scores > TOPP_ConsensusID_7.stdout 2> TOPP_ConsensusID_7.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_ConsensusID_7 failed'; >&2 echo -e "stderr:\n$(cat TOPP_ConsensusID_7.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_ConsensusID_7.stdout)";fi
echo executing "TOPP_ConsensusID_8"
ConsensusID -test -in ConsensusID_8_input.idXML -out ConsensusID_8_output.tmp -algorithm best -per_spectrum -filter:keep_old_scores > TOPP_ConsensusID_8.stdout 2> TOPP_ConsensusID_8.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_ConsensusID_8 failed'; >&2 echo -e "stderr:\n$(cat TOPP_ConsensusID_8.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_ConsensusID_8.stdout)";fi
echo executing "TOPP_PrecursorIonSelector_1"
PrecursorIonSelector -test -in PrecursorIonSelector_features.featureXML -sim_results PrecursorIonSelector_1_output.tmp -ini PrecursorIonSelector_1_parameters.ini -db_path PrecursorIonSelector_db.fasta -ids PrecursorIonSelector_ids.idXML > TOPP_PrecursorIonSelector_1.stdout 2> TOPP_PrecursorIonSelector_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_PrecursorIonSelector_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_PrecursorIonSelector_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_PrecursorIonSelector_1.stdout)";fi
echo executing "TOPP_PrecursorIonSelector_2"
PrecursorIonSelector -test -in PrecursorIonSelector_features.featureXML -out PrecursorIonSelector_2_output.tmp -ini PrecursorIonSelector_2_parameters.ini -db_path PrecursorIonSelector_db.fasta -ids PrecursorIonSelector_ids.idXML > TOPP_PrecursorIonSelector_2.stdout 2> TOPP_PrecursorIonSelector_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_PrecursorIonSelector_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_PrecursorIonSelector_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_PrecursorIonSelector_2.stdout)";fi
echo executing "TOPP_CompNovo_1"
CompNovo -test -in CompNovo_1_input.mzML -ini CompNovo_1.ini -out CompNovo_1_output.tmp > TOPP_CompNovo_1.stdout 2> TOPP_CompNovo_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_CompNovo_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_CompNovo_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_CompNovo_1.stdout)";fi
echo executing "TOPP_CompNovoCID_1"
CompNovoCID -test -in CompNovoCID_1_input.mzML -ini CompNovoCID_1.ini -out CompNovoCID_1_output.tmp > TOPP_CompNovoCID_1.stdout 2> TOPP_CompNovoCID_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_CompNovoCID_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_CompNovoCID_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_CompNovoCID_1.stdout)";fi
echo executing "TOPP_PrecursorMassCorrector_1"
PrecursorMassCorrector -test -in PrecursorMassCorrector_1_input.mzML -ini PrecursorMassCorrector_1.ini -out PrecursorMassCorrector_1_output.tmp > TOPP_PrecursorMassCorrector_1.stdout 2> TOPP_PrecursorMassCorrector_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_PrecursorMassCorrector_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_PrecursorMassCorrector_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_PrecursorMassCorrector_1.stdout)";fi
echo executing "TOPP_FalseDiscoveryRate_1"
FalseDiscoveryRate -test -in FalseDiscoveryRate_OMSSA.idXML -out FalseDiscoveryRate_output_1.tmp -PSM true -protein false > TOPP_FalseDiscoveryRate_1.stdout 2> TOPP_FalseDiscoveryRate_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FalseDiscoveryRate_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FalseDiscoveryRate_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FalseDiscoveryRate_1.stdout)";fi
echo executing "TOPP_FalseDiscoveryRate_2"
FalseDiscoveryRate -test -in FalseDiscoveryRate_OMSSA.idXML -out FalseDiscoveryRate_output_2.tmp -algorithm:treat_runs_separately -PSM true -protein false > TOPP_FalseDiscoveryRate_2.stdout 2> TOPP_FalseDiscoveryRate_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FalseDiscoveryRate_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FalseDiscoveryRate_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FalseDiscoveryRate_2.stdout)";fi
echo executing "TOPP_FalseDiscoveryRate_3"
FalseDiscoveryRate -test -in FalseDiscoveryRate_OMSSA.idXML -out FalseDiscoveryRate_output_3.tmp -algorithm:split_charge_variants -PSM true -protein false > TOPP_FalseDiscoveryRate_3.stdout 2> TOPP_FalseDiscoveryRate_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FalseDiscoveryRate_3 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FalseDiscoveryRate_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FalseDiscoveryRate_3.stdout)";fi
echo executing "TOPP_FalseDiscoveryRate_4"
FalseDiscoveryRate -test -in FalseDiscoveryRate_OMSSA_4.idXML -out FalseDiscoveryRate_output_4.tmp -algorithm:split_charge_variants -PSM true -protein false > TOPP_FalseDiscoveryRate_4.stdout 2> TOPP_FalseDiscoveryRate_4.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FalseDiscoveryRate_4 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FalseDiscoveryRate_4.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FalseDiscoveryRate_4.stdout)";fi
echo executing "TOPP_FalseDiscoveryRate_5"
FalseDiscoveryRate -test -in FalseDiscoveryRate_5_input.idXML -out FalseDiscoveryRate_5_output.tmp -PSM false -protein true -algorithm:add_decoy_proteins -force > TOPP_FalseDiscoveryRate_5.stdout 2> TOPP_FalseDiscoveryRate_5.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FalseDiscoveryRate_5 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FalseDiscoveryRate_5.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FalseDiscoveryRate_5.stdout)";fi
echo executing "TOPP_FalseDiscoveryRate_6"
FalseDiscoveryRate -test -in FalseDiscoveryRate_6_input.idXML -out FalseDiscoveryRate_6_output.tmp -PSM true -protein false -FDR:PSM 0.05 > TOPP_FalseDiscoveryRate_6.stdout 2> TOPP_FalseDiscoveryRate_6.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FalseDiscoveryRate_6 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FalseDiscoveryRate_6.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FalseDiscoveryRate_6.stdout)";fi
echo executing "TOPP_FalseDiscoveryRate_7"
FalseDiscoveryRate -test -in FalseDiscoveryRate_7_input.idXML -out FalseDiscoveryRate_7_output.tmp -PSM false -protein true -FDR:protein 0.30 -force > TOPP_FalseDiscoveryRate_7.stdout 2> TOPP_FalseDiscoveryRate_7.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FalseDiscoveryRate_7 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FalseDiscoveryRate_7.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FalseDiscoveryRate_7.stdout)";fi
echo executing "TOPP_IDPosteriorErrorProbability_1"
IDPosteriorErrorProbability -test -in IDPosteriorErrorProbability_Mascot_input.idXML -out 	IDPosteriorErrorProbability_output_1.tmp > TOPP_IDPosteriorErrorProbability_1.stdout 2> TOPP_IDPosteriorErrorProbability_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDPosteriorErrorProbability_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDPosteriorErrorProbability_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDPosteriorErrorProbability_1.stdout)";fi
echo executing "TOPP_IDPosteriorErrorProbability_2"
IDPosteriorErrorProbability -test -in IDPosteriorErrorProbability_XTandem_input.idXML -out IDPosteriorErrorProbability_output_2.tmp > TOPP_IDPosteriorErrorProbability_2.stdout 2> TOPP_IDPosteriorErrorProbability_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDPosteriorErrorProbability_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDPosteriorErrorProbability_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDPosteriorErrorProbability_2.stdout)";fi
echo executing "TOPP_IDPosteriorErrorProbability_3"
IDPosteriorErrorProbability -test -in IDPosteriorErrorProbability_OMSSA_input.idXML -out IDPosteriorErrorProbability_output_3.tmp > TOPP_IDPosteriorErrorProbability_3.stdout 2> TOPP_IDPosteriorErrorProbability_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDPosteriorErrorProbability_3 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDPosteriorErrorProbability_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDPosteriorErrorProbability_3.stdout)";fi
echo executing "TOPP_IDPosteriorErrorProbability_4"
IDPosteriorErrorProbability -test -in IDPosteriorErrorProbability_OMSSA_input2.idXML -out IDPosteriorErrorProbability_output_4.tmp -split_charge > TOPP_IDPosteriorErrorProbability_4.stdout 2> TOPP_IDPosteriorErrorProbability_4.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDPosteriorErrorProbability_4 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDPosteriorErrorProbability_4.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDPosteriorErrorProbability_4.stdout)";fi
echo executing "TOPP_IDPosteriorErrorProbability_5"
IDPosteriorErrorProbability -test -in IDPosteriorErrorProbability_XTandem_input2.idXML -out IDPosteriorErrorProbability_output_5.tmp -split_charge > TOPP_IDPosteriorErrorProbability_5.stdout 2> TOPP_IDPosteriorErrorProbability_5.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDPosteriorErrorProbability_5 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDPosteriorErrorProbability_5.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDPosteriorErrorProbability_5.stdout)";fi
echo executing "TOPP_IDPosteriorErrorProbability_6"
IDPosteriorErrorProbability -test -in IDPosteriorErrorProbability_Mascot_input2.idXML -out IDPosteriorErrorProbability_output_6.tmp -split_charge > TOPP_IDPosteriorErrorProbability_6.stdout 2> TOPP_IDPosteriorErrorProbability_6.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDPosteriorErrorProbability_6 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDPosteriorErrorProbability_6.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDPosteriorErrorProbability_6.stdout)";fi
echo executing "TOPP_IDPosteriorErrorProbability_7"
IDPosteriorErrorProbability -test -in IDPosteriorErrorProbability_bad_data.idXML -out IDPosteriorErrorProbability_bad_data_output.tmp -ignore_bad_data > TOPP_IDPosteriorErrorProbability_7.stdout 2> TOPP_IDPosteriorErrorProbability_7.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDPosteriorErrorProbability_7 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDPosteriorErrorProbability_7.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDPosteriorErrorProbability_7.stdout)";fi
echo executing "TOPP_IDPosteriorErrorProbability_8"
IDPosteriorErrorProbability -test -in IDPosteriorErrorProbability_OMSSA_input.idXML -out IDPosteriorErrorProbability_output_8.tmp -prob_correct > TOPP_IDPosteriorErrorProbability_8.stdout 2> TOPP_IDPosteriorErrorProbability_8.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_IDPosteriorErrorProbability_8 failed'; >&2 echo -e "stderr:\n$(cat TOPP_IDPosteriorErrorProbability_8.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_IDPosteriorErrorProbability_8.stdout)";fi
echo executing "TOPP_ProteinResolver_1"
ProteinResolver -test -in ProteinResolver_1_input.consensusXML -fasta ProteinResolver_1_input.fasta -protein_groups ProteinResolver_1_output1.tmp -peptide_table ProteinResolver_1_output2.tmp -protein_table ProteinResolver_1_output3.tmp > TOPP_ProteinResolver_1.stdout 2> TOPP_ProteinResolver_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_ProteinResolver_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_ProteinResolver_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_ProteinResolver_1.stdout)";fi
echo executing "TOPP_ProteinQuantifier_1"
ProteinQuantifier -test -in ProteinQuantifier_input.featureXML -out ProteinQuantifier_1_output1.tmp -peptide_out ProteinQuantifier_1_output2.tmp > TOPP_ProteinQuantifier_1.stdout 2> TOPP_ProteinQuantifier_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_ProteinQuantifier_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_ProteinQuantifier_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_ProteinQuantifier_1.stdout)";fi
echo executing "TOPP_ProteinQuantifier_2"
ProteinQuantifier -test -in ProteinQuantifier_input.featureXML -out ProteinQuantifier_2_output1.tmp -peptide_out ProteinQuantifier_2_output2.tmp -top 2 -include_all -best_charge_and_fraction -average sum > TOPP_ProteinQuantifier_2.stdout 2> TOPP_ProteinQuantifier_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_ProteinQuantifier_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_ProteinQuantifier_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_ProteinQuantifier_2.stdout)";fi
echo executing "TOPP_ProteinQuantifier_3"
ProteinQuantifier -test -in ProteinQuantifier_3_input.featureXML -out ProteinQuantifier_3_output1.tmp -peptide_out ProteinQuantifier_3_output2.tmp -top 2 -include_all -average mean > TOPP_ProteinQuantifier_3.stdout 2> TOPP_ProteinQuantifier_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_ProteinQuantifier_3 failed'; >&2 echo -e "stderr:\n$(cat TOPP_ProteinQuantifier_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_ProteinQuantifier_3.stdout)";fi
echo executing "TOPP_ProteinQuantifier_4"
ProteinQuantifier -test -in ProteinQuantifier_input.consensusXML -out ProteinQuantifier_4_output.tmp -top 0 -average sum > TOPP_ProteinQuantifier_4.stdout 2> TOPP_ProteinQuantifier_4.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_ProteinQuantifier_4 failed'; >&2 echo -e "stderr:\n$(cat TOPP_ProteinQuantifier_4.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_ProteinQuantifier_4.stdout)";fi
echo executing "TOPP_ProteinQuantifier_5"
ProteinQuantifier -test -in ProteinQuantifier_input.consensusXML -out ProteinQuantifier_5_output.tmp -top 3 -average sum > TOPP_ProteinQuantifier_5.stdout 2> TOPP_ProteinQuantifier_5.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_ProteinQuantifier_5 failed'; >&2 echo -e "stderr:\n$(cat TOPP_ProteinQuantifier_5.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_ProteinQuantifier_5.stdout)";fi
echo executing "TOPP_ProteinQuantifier_6"
ProteinQuantifier -test -in ProteinQuantifier_input.consensusXML -out ProteinQuantifier_6_output.tmp -top 3 -include_all -average sum > TOPP_ProteinQuantifier_6.stdout 2> TOPP_ProteinQuantifier_6.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_ProteinQuantifier_6 failed'; >&2 echo -e "stderr:\n$(cat TOPP_ProteinQuantifier_6.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_ProteinQuantifier_6.stdout)";fi
echo executing "TOPP_ProteinQuantifier_7"
ProteinQuantifier -test -in ProteinQuantifier_input.consensusXML -out ProteinQuantifier_7_output.tmp -top 0 -consensus:fix_peptides -average sum > TOPP_ProteinQuantifier_7.stdout 2> TOPP_ProteinQuantifier_7.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_ProteinQuantifier_7 failed'; >&2 echo -e "stderr:\n$(cat TOPP_ProteinQuantifier_7.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_ProteinQuantifier_7.stdout)";fi
echo executing "TOPP_ProteinQuantifier_8"
ProteinQuantifier -test -in ProteinQuantifier_input.consensusXML -out ProteinQuantifier_8_output.tmp -top 3 -consensus:fix_peptides -average sum > TOPP_ProteinQuantifier_8.stdout 2> TOPP_ProteinQuantifier_8.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_ProteinQuantifier_8 failed'; >&2 echo -e "stderr:\n$(cat TOPP_ProteinQuantifier_8.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_ProteinQuantifier_8.stdout)";fi
echo executing "TOPP_ProteinQuantifier_9"
ProteinQuantifier -test -in ProteinQuantifier_input.consensusXML -out ProteinQuantifier_9_output.tmp -mztab ProteinQuantifier_9_output_mztab.tmp -top 3 -include_all -consensus:fix_peptides -average sum > TOPP_ProteinQuantifier_9.stdout 2> TOPP_ProteinQuantifier_9.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_ProteinQuantifier_9 failed'; >&2 echo -e "stderr:\n$(cat TOPP_ProteinQuantifier_9.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_ProteinQuantifier_9.stdout)";fi
echo executing "TOPP_ProteinQuantifier_12"
ProteinQuantifier -test -in ProteinQuantifier_input.consensusXML -out ProteinQuantifier_12_output.tmp -top 3 -include_all -consensus:fix_peptides -average sum -ratios > TOPP_ProteinQuantifier_12.stdout 2> TOPP_ProteinQuantifier_12.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_ProteinQuantifier_12 failed'; >&2 echo -e "stderr:\n$(cat TOPP_ProteinQuantifier_12.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_ProteinQuantifier_12.stdout)";fi
echo executing "TOPP_ProteinQuantifier_13"
ProteinQuantifier -test -in ProteinQuantifier_input.consensusXML -out ProteinQuantifier_13_output.tmp -top 3 -include_all -consensus:fix_peptides -average sum -ratiosSILAC > TOPP_ProteinQuantifier_13.stdout 2> TOPP_ProteinQuantifier_13.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_ProteinQuantifier_13 failed'; >&2 echo -e "stderr:\n$(cat TOPP_ProteinQuantifier_13.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_ProteinQuantifier_13.stdout)";fi
echo executing "TOPP_ProteinQuantifier_14"
ProteinQuantifier -test -in ProteinQuantifier_input.idXML -out ProteinQuantifier_14_output1.tmp -peptide_out ProteinQuantifier_14_output2.tmp -top 0 -average sum > TOPP_ProteinQuantifier_14.stdout 2> TOPP_ProteinQuantifier_14.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_ProteinQuantifier_14 failed'; >&2 echo -e "stderr:\n$(cat TOPP_ProteinQuantifier_14.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_ProteinQuantifier_14.stdout)";fi
echo executing "TOPP_InclusionExclusionListCreator_1"
InclusionExclusionListCreator -test -include InclusionExclusionListCreator.featureXML -out InclusionExclusionListCreator_1_output.tmp > TOPP_InclusionExclusionListCreator_1.stdout 2> TOPP_InclusionExclusionListCreator_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_InclusionExclusionListCreator_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_InclusionExclusionListCreator_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_InclusionExclusionListCreator_1.stdout)";fi
echo executing "TOPP_InclusionExclusionListCreator_2"
InclusionExclusionListCreator -test -exclude InclusionExclusionListCreator.featureXML -out InclusionExclusionListCreator_2_output.tmp -ini InclusionExclusionListCreator_2.ini > TOPP_InclusionExclusionListCreator_2.stdout 2> TOPP_InclusionExclusionListCreator_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_InclusionExclusionListCreator_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_InclusionExclusionListCreator_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_InclusionExclusionListCreator_2.stdout)";fi
echo executing "TOPP_InclusionExclusionListCreator_3"
InclusionExclusionListCreator -test -include InclusionExclusionListCreator.fasta -out InclusionExclusionListCreator_3_output.tmp -inclusion_charges 1 2 -rt_model InclusionExclusionListCreator_rt.model > TOPP_InclusionExclusionListCreator_3.stdout 2> TOPP_InclusionExclusionListCreator_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_InclusionExclusionListCreator_3 failed'; >&2 echo -e "stderr:\n$(cat TOPP_InclusionExclusionListCreator_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_InclusionExclusionListCreator_3.stdout)";fi
echo executing "TOPP_InclusionExclusionListCreator_4"
InclusionExclusionListCreator -test -exclude InclusionExclusionListCreator.fasta -out InclusionExclusionListCreator_4_output.tmp -exclusion_charges 1 2 -rt_model InclusionExclusionListCreator_rt.model  -ini InclusionExclusionListCreator_4.ini > TOPP_InclusionExclusionListCreator_4.stdout 2> TOPP_InclusionExclusionListCreator_4.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_InclusionExclusionListCreator_4 failed'; >&2 echo -e "stderr:\n$(cat TOPP_InclusionExclusionListCreator_4.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_InclusionExclusionListCreator_4.stdout)";fi
echo executing "TOPP_InclusionExclusionListCreator_5"
InclusionExclusionListCreator -test -exclude InclusionExclusionListCreator.idXML -out InclusionExclusionListCreator_5_output.tmp -exclusion_charges 1 2 -rt_model InclusionExclusionListCreator_rt.model > TOPP_InclusionExclusionListCreator_5.stdout 2> TOPP_InclusionExclusionListCreator_5.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_InclusionExclusionListCreator_5 failed'; >&2 echo -e "stderr:\n$(cat TOPP_InclusionExclusionListCreator_5.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_InclusionExclusionListCreator_5.stdout)";fi
echo executing "TOPP_InclusionExclusionListCreator_6"
InclusionExclusionListCreator -test -exclude InclusionExclusionListCreator.idXML -out InclusionExclusionListCreator_6_output.tmp -exclusion_charges 1 2 -rt_model InclusionExclusionListCreator_rt.model  -ini InclusionExclusionListCreator_6.ini > TOPP_InclusionExclusionListCreator_6.stdout 2> TOPP_InclusionExclusionListCreator_6.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_InclusionExclusionListCreator_6 failed'; >&2 echo -e "stderr:\n$(cat TOPP_InclusionExclusionListCreator_6.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_InclusionExclusionListCreator_6.stdout)";fi
echo executing "TOPP_PeptideIndexer_1"
PeptideIndexer -test -fasta PeptideIndexer_1.fasta -in PeptideIndexer_1.idXML -out PeptideIndexer_1_out.tmp.idXML -unmatched_action warn -enzyme:specificity none -aaa_max 4 > TOPP_PeptideIndexer_1.stdout 2> TOPP_PeptideIndexer_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_PeptideIndexer_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_PeptideIndexer_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_PeptideIndexer_1.stdout)";fi
echo executing "TOPP_PeptideIndexer_2"
PeptideIndexer -test -fasta PeptideIndexer_1.fasta -in PeptideIndexer_1.idXML -out PeptideIndexer_2_out.tmp.idXML -unmatched_action warn -write_protein_sequence -enzyme:specificity none -aaa_max 4 > TOPP_PeptideIndexer_2.stdout 2> TOPP_PeptideIndexer_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_PeptideIndexer_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_PeptideIndexer_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_PeptideIndexer_2.stdout)";fi
echo executing "TOPP_PeptideIndexer_3"
PeptideIndexer -test -fasta PeptideIndexer_1.fasta -in PeptideIndexer_1.idXML -out PeptideIndexer_3_out.tmp.idXML -unmatched_action warn -keep_unreferenced_proteins -enzyme:specificity none -aaa_max 4 > TOPP_PeptideIndexer_3.stdout 2> TOPP_PeptideIndexer_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_PeptideIndexer_3 failed'; >&2 echo -e "stderr:\n$(cat TOPP_PeptideIndexer_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_PeptideIndexer_3.stdout)";fi
echo executing "TOPP_PeptideIndexer_4"
PeptideIndexer -test -fasta PeptideIndexer_1.fasta -in PeptideIndexer_1.idXML -out PeptideIndexer_4_out.tmp.idXML -unmatched_action warn -aaa_max 0 -write_protein_sequence -enzyme:specificity none -aaa_max 4 > TOPP_PeptideIndexer_4.stdout 2> TOPP_PeptideIndexer_4.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_PeptideIndexer_4 failed'; >&2 echo -e "stderr:\n$(cat TOPP_PeptideIndexer_4.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_PeptideIndexer_4.stdout)";fi
echo executing "TOPP_PeptideIndexer_5"
PeptideIndexer -test -fasta PeptideIndexer_1.fasta -in PeptideIndexer_1.idXML -out PeptideIndexer_5_out.tmp.idXML -unmatched_action warn -enzyme:specificity none -aaa_max 4 > TOPP_PeptideIndexer_5.stdout 2> TOPP_PeptideIndexer_5.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_PeptideIndexer_5 failed'; >&2 echo -e "stderr:\n$(cat TOPP_PeptideIndexer_5.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_PeptideIndexer_5.stdout)";fi
echo executing "TOPP_PeptideIndexer_6"
PeptideIndexer -test -fasta PeptideIndexer_1.fasta -in PeptideIndexer_2.idXML -out PeptideIndexer_6_out.tmp.idXML -unmatched_action warn -enzyme:specificity none -aaa_max 3 > TOPP_PeptideIndexer_6.stdout 2> TOPP_PeptideIndexer_6.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_PeptideIndexer_6 failed'; >&2 echo -e "stderr:\n$(cat TOPP_PeptideIndexer_6.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_PeptideIndexer_6.stdout)";fi
echo executing "TOPP_PeptideIndexer_7"
PeptideIndexer -test -fasta PeptideIndexer_1.fasta -in PeptideIndexer_3.idXML -out PeptideIndexer_7_out.tmp.idXML -unmatched_action warn -aaa_max 4 -enzyme:specificity full -decoy_string DECOY_ > TOPP_PeptideIndexer_7.stdout 2> TOPP_PeptideIndexer_7.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_PeptideIndexer_7 failed'; >&2 echo -e "stderr:\n$(cat TOPP_PeptideIndexer_7.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_PeptideIndexer_7.stdout)";fi
echo executing "TOPP_PeptideIndexer_8"
PeptideIndexer -test -fasta PeptideIndexer_1.fasta -in PeptideIndexer_3.idXML -out PeptideIndexer_8_out.tmp.idXML -unmatched_action warn -enzyme:specificity semi -aaa_max 4 > TOPP_PeptideIndexer_8.stdout 2> TOPP_PeptideIndexer_8.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_PeptideIndexer_8 failed'; >&2 echo -e "stderr:\n$(cat TOPP_PeptideIndexer_8.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_PeptideIndexer_8.stdout)";fi
echo executing "TOPP_PeptideIndexer_9"
PeptideIndexer -test -fasta PeptideIndexer_1.fasta -in PeptideIndexer_3.idXML -out PeptideIndexer_9_out.tmp.idXML -unmatched_action remove -enzyme:specificity none -aaa_max 4 > TOPP_PeptideIndexer_9.stdout 2> TOPP_PeptideIndexer_9.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_PeptideIndexer_9 failed'; >&2 echo -e "stderr:\n$(cat TOPP_PeptideIndexer_9.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_PeptideIndexer_9.stdout)";fi
echo executing "TOPP_PeptideIndexer_10"
PeptideIndexer -test -fasta PeptideIndexer_10_input.fasta -in PeptideIndexer_10_input.idXML -out PeptideIndexer_10_output.tmp.idXML -IL_equivalent -aaa_max 3 -write_protein_sequence > TOPP_PeptideIndexer_10.stdout 2> TOPP_PeptideIndexer_10.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_PeptideIndexer_10 failed'; >&2 echo -e "stderr:\n$(cat TOPP_PeptideIndexer_10.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_PeptideIndexer_10.stdout)";fi
echo executing "TOPP_PeptideIndexer_12"
PeptideIndexer -test -fasta PeptideIndexer_1.fasta -in PeptideIndexer_1.idXML -out PeptideIndexer_12_out.tmp.idXML -unmatched_action warn -enzyme:specificity none -aaa_max 4 > TOPP_PeptideIndexer_12.stdout 2> TOPP_PeptideIndexer_12.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_PeptideIndexer_12 failed'; >&2 echo -e "stderr:\n$(cat TOPP_PeptideIndexer_12.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_PeptideIndexer_12.stdout)";fi
echo executing "TOPP_PeptideIndexer_13"
PeptideIndexer -test -fasta PeptideIndexer_1.fasta -in empty.idXML -out PeptideIndexer_13_out.tmp.idXML -aaa_max 4 > TOPP_PeptideIndexer_13.stdout 2> TOPP_PeptideIndexer_13.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_PeptideIndexer_13 failed'; >&2 echo -e "stderr:\n$(cat TOPP_PeptideIndexer_13.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_PeptideIndexer_13.stdout)";fi
echo executing "TOPP_PeptideIndexer_14"
PeptideIndexer -test -fasta PeptideIndexer_2.fasta -in PeptideIndexer_14.idXML -out PeptideIndexer_14_out.tmp.idXML -enzyme:specificity none -aaa_max 4 -write_protein_sequence > TOPP_PeptideIndexer_14.stdout 2> TOPP_PeptideIndexer_14.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_PeptideIndexer_14 failed'; >&2 echo -e "stderr:\n$(cat TOPP_PeptideIndexer_14.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_PeptideIndexer_14.stdout)";fi
echo executing "TOPP_MzTabExporter_1"
MzTabExporter -test -in MzTabExporter_1_input.consensusXML -out MzTabExporter_1_output.tmp > TOPP_MzTabExporter_1.stdout 2> TOPP_MzTabExporter_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_MzTabExporter_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_MzTabExporter_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_MzTabExporter_1.stdout)";fi
echo executing "TOPP_MzTabExporter_2"
MzTabExporter -test -in MzTabExporter_2_input.idXML -out MzTabExporter_2_output.tmp > TOPP_MzTabExporter_2.stdout 2> TOPP_MzTabExporter_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_MzTabExporter_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_MzTabExporter_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_MzTabExporter_2.stdout)";fi
echo executing "TOPP_MzTabExporter_3"
MzTabExporter -test -in MzTabExporter_3_input.featureXML -out MzTabExporter_3_output.tmp > TOPP_MzTabExporter_3.stdout 2> TOPP_MzTabExporter_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_MzTabExporter_3 failed'; >&2 echo -e "stderr:\n$(cat TOPP_MzTabExporter_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_MzTabExporter_3.stdout)";fi
echo executing "TOPP_MzTabExporter_4"
MzTabExporter -test -in Epifany_2_out.consensusXML -out MzTabExporter_4_output.tmp > TOPP_MzTabExporter_4.stdout 2> TOPP_MzTabExporter_4.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_MzTabExporter_4 failed'; >&2 echo -e "stderr:\n$(cat TOPP_MzTabExporter_4.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_MzTabExporter_4.stdout)";fi
echo executing "TOPP_MzTabExporter_5"
MzTabExporter -test -in MzTabExporter_5_in.consensusXML -out MzTabExporter_5_output.tmp -first_run_inference_only > TOPP_MzTabExporter_5.stdout 2> TOPP_MzTabExporter_5.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_MzTabExporter_5 failed'; >&2 echo -e "stderr:\n$(cat TOPP_MzTabExporter_5.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_MzTabExporter_5.stdout)";fi
echo executing "TOPP_MzTabExporter_6"
MzTabExporter -test -in MzTabExporter_6_input.idXML -out MzTabExporter_6_output.tmp > TOPP_MzTabExporter_6.stdout 2> TOPP_MzTabExporter_6.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_MzTabExporter_6 failed'; >&2 echo -e "stderr:\n$(cat TOPP_MzTabExporter_6.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_MzTabExporter_6.stdout)";fi
echo executing "TOPP_MzTabExporter_7"
MzTabExporter -test -in MzTabExporter_7_input.consensusXML -out MzTabExporter_7_output.tmp > TOPP_MzTabExporter_7.stdout 2> TOPP_MzTabExporter_7.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_MzTabExporter_7 failed'; >&2 echo -e "stderr:\n$(cat TOPP_MzTabExporter_7.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_MzTabExporter_7.stdout)";fi
echo executing "TOPP_MzTabExporter_8"
MzTabExporter -test -in MzTabExporter_6_input.idXML -export_all_psms -out MzTabExporter_8_output.tmp > TOPP_MzTabExporter_8.stdout 2> TOPP_MzTabExporter_8.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_MzTabExporter_8 failed'; >&2 echo -e "stderr:\n$(cat TOPP_MzTabExporter_8.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_MzTabExporter_8.stdout)";fi
echo executing "TOPP_OpenPepXL_1"
OpenPepXL -test -ini OpenPepXL_input.ini -in OpenPepXL_input.mzML -consensus OpenPepXL_input.consensusXML -database OpenPepXL_input.fasta -out_xquestxml OpenPepXL_output.xquest.xml.tmp -out_xquest_specxml OpenPepXL_output.spec.xml.tmp -out_mzIdentML OpenPepXL_output.mzid.tmp -out_idXML OpenPepXL_output.idXML.tmp > TOPP_OpenPepXL_1.stdout 2> TOPP_OpenPepXL_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenPepXL_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenPepXL_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenPepXL_1.stdout)";fi
echo executing "TOPP_OpenPepXLLF_1"
OpenPepXLLF -test -decoy_string "decoy" -in OpenPepXLLF_input.mzML -database OpenPepXLLF_input.fasta -out_xquestxml OpenPepXLLF_output.xquest.xml.tmp -out_xquest_specxml OpenPepXLLF_output.spec.xml.tmp -out_mzIdentML OpenPepXLLF_output.mzid.tmp -out_idXML OpenPepXLLF_output.idXML.tmp > TOPP_OpenPepXLLF_1.stdout 2> TOPP_OpenPepXLLF_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenPepXLLF_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenPepXLLF_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenPepXLLF_1.stdout)";fi
echo executing "TOPP_OpenPepXLLF_2"
OpenPepXLLF -test -ini OpenPepXLLF_input2.ini -in OpenPepXLLF_input2.mzML -database OpenPepXLLF_input2.fasta -out_idXML OpenPepXLLF_output2.idXML.tmp > TOPP_OpenPepXLLF_2.stdout 2> TOPP_OpenPepXLLF_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OpenPepXLLF_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_OpenPepXLLF_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OpenPepXLLF_2.stdout)";fi
echo executing "TOPP_XFDR_1"
XFDR -test -binsize 0.1 -in XFDR_test_in1.idXML -out_idXML XFDR_test_out1_temp.idXML -out_mzIdentML XFDR_test_out1_temp.mzid -out_xquest XFDR_test_out1_temp.xquest.xml > TOPP_XFDR_1.stdout 2> TOPP_XFDR_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_XFDR_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_XFDR_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_XFDR_1.stdout)";fi
echo executing "TOPP_XFDR_2"
XFDR -test -binsize 0.1 -in XFDR_test_in1.idXML -uniquexl -no_qvalues -out_idXML XFDR_test_out2_temp.idXML -out_mzIdentML XFDR_test_out2_temp.mzid -out_xquest XFDR_test_out2_temp.xquest.xml > TOPP_XFDR_2.stdout 2> TOPP_XFDR_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_XFDR_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_XFDR_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_XFDR_2.stdout)";fi
echo executing "TOPP_XFDR_3"
XFDR -test -binsize 0.1 -minscore 0.0 -in XFDR_test_in2.xquest.xml -out_idXML XFDR_test_out3_temp.idXML -out_mzIdentML XFDR_test_out3_temp.mzid -out_xquest XFDR_test_out3_temp.xquest.xml > TOPP_XFDR_3.stdout 2> TOPP_XFDR_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_XFDR_3 failed'; >&2 echo -e "stderr:\n$(cat TOPP_XFDR_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_XFDR_3.stdout)";fi
echo executing "TOPP_XFDR_4"
XFDR -test -binsize 0.1 -minborder -3 -maxborder 3 -in XFDR_test_in2.xquest.xml -out_idXML XFDR_test_out4_temp.idXML -out_mzIdentML XFDR_test_out4_temp.mzid -out_xquest XFDR_test_out4_temp.xquest.xml > TOPP_XFDR_4.stdout 2> TOPP_XFDR_4.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_XFDR_4 failed'; >&2 echo -e "stderr:\n$(cat TOPP_XFDR_4.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_XFDR_4.stdout)";fi
echo executing "TOPP_XFDR_5"
XFDR -test -binsize 0.1 -minborder -3 -maxborder 3 -in XFDR_test_in3.xquest.xml -out_idXML XFDR_test_out5_temp.idXML -out_mzIdentML XFDR_test_out5_temp.mzid -out_xquest XFDR_test_out5_temp.xquest.xml > TOPP_XFDR_5.stdout 2> TOPP_XFDR_5.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_XFDR_5 failed'; >&2 echo -e "stderr:\n$(cat TOPP_XFDR_5.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_XFDR_5.stdout)";fi
echo executing "TOPP_XFDR_6"
XFDR -test -binsize 0.1 -in XFDR_test_in4.idXML -out_idXML XFDR_test_out6_temp.idXML > TOPP_XFDR_6.stdout 2> TOPP_XFDR_6.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_XFDR_6 failed'; >&2 echo -e "stderr:\n$(cat TOPP_XFDR_6.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_XFDR_6.stdout)";fi
echo executing "TOPP_XFDR_7"
XFDR -test -uniquexl -binsize 0.1 -minscore 0.0 -in XFDR_test_in2.xquest.xml -out_idXML XFDR_test_out7_temp.idXML -out_mzIdentML XFDR_test_out7_temp.mzid -out_xquest XFDR_test_out7_temp.xquest.xml > TOPP_XFDR_7.stdout 2> TOPP_XFDR_7.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_XFDR_7 failed'; >&2 echo -e "stderr:\n$(cat TOPP_XFDR_7.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_XFDR_7.stdout)";fi
echo executing "TOPP_QualityControl_1"
QualityControl -test -in_raw QualityControl_1_in1.mzML.gz QualityControl_1_in2.mzML.gz QualityControl_1_in3.mzML.gz -in_postFDR QualityControl_1_in1.featureXML QualityControl_1_in2.featureXML QualityControl_1_in3.featureXML -in_trafo QualityControl_1_in1.trafoXML QualityControl_1_in2.trafoXML QualityControl_1_in3.trafoXML  -in_contaminants QualityControl_1.fasta -in_cm QualityControl_1_in.consensusXML -out_cm QualityControl_1_out.consensusXML.tmp -out QualityControl_1_out.mzTab.tmp > TOPP_QualityControl_1.stdout 2> TOPP_QualityControl_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_QualityControl_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_QualityControl_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_QualityControl_1.stdout)";fi
echo executing "UTILS_AccurateMassSearch_1"
AccurateMassSearch -test -in ConsensusMapNormalizer_input.consensusXML -out AccurateMassSearch_1_output.tmp.mzTab > UTILS_AccurateMassSearch_1.stdout 2> UTILS_AccurateMassSearch_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_AccurateMassSearch_1 failed'; >&2 echo -e "stderr:\n$(cat UTILS_AccurateMassSearch_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_AccurateMassSearch_1.stdout)";fi
echo executing "UTILS_AccurateMassSearch_2"
AccurateMassSearch -test -in AccurateMassSearch_2_input.featureXML -out AccurateMassSearch_2_output.tmp.mzTab -out_annotation AccurateMassSearch_2_output.tmp.featureXML -db:mapping AMS_test_Mapping.tsv -db:struct AMS_test_Struct.tsv -positive_adducts AMS_PositiveAdducts.tsv -negative_adducts AMS_NegativeAdducts.tsv -algorithm:mzTab:exportIsotopeIntensities true -algorithm:keep_unidentified_masses false > UTILS_AccurateMassSearch_2.stdout 2> UTILS_AccurateMassSearch_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_AccurateMassSearch_2 failed'; >&2 echo -e "stderr:\n$(cat UTILS_AccurateMassSearch_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_AccurateMassSearch_2.stdout)";fi
echo executing "UTILS_AccurateMassSearch_3"
AccurateMassSearch -test -in AccurateMassSearch_2_input.featureXML -out AccurateMassSearch_3_output.tmp.mzTab -out_annotation AccurateMassSearch_2_output.tmp.featureXML -db:mapping AMS_test_Mapping.tsv -db:struct AMS_test_Struct.tsv -positive_adducts AMS_PositiveAdducts.tsv -negative_adducts AMS_NegativeAdducts.tsv > UTILS_AccurateMassSearch_3.stdout 2> UTILS_AccurateMassSearch_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_AccurateMassSearch_3 failed'; >&2 echo -e "stderr:\n$(cat UTILS_AccurateMassSearch_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_AccurateMassSearch_3.stdout)";fi
echo executing "UTILS_AccurateMassSearch_5"
AccurateMassSearch -test -in AccurateMassSearch_2_input.featureXML -out AccurateMassSearch_5_output.tmp.mzTab -out_annotation AccurateMassSearch_5_output.tmp.oms -db:mapping AMS_test_Mapping.tsv -db:struct AMS_test_Struct.tsv -positive_adducts AMS_PositiveAdducts.tsv -negative_adducts AMS_NegativeAdducts.tsv -algorithm:id_format ID > UTILS_AccurateMassSearch_5.stdout 2> UTILS_AccurateMassSearch_5.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_AccurateMassSearch_5 failed'; >&2 echo -e "stderr:\n$(cat UTILS_AccurateMassSearch_5.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_AccurateMassSearch_5.stdout)";fi
echo executing "UTILS_AccurateMassSearch_6"
AccurateMassSearch -test -in AccurateMassSearch_2_input.featureXML -out AccurateMassSearch_6_output.tmp.mzTab -out_annotation AccurateMassSearch_6_output.tmp.featureXML -db:mapping AMS_test_Mapping.tsv -db:struct AMS_test_Struct.tsv -positive_adducts AMS_PositiveAdducts.tsv -negative_adducts AMS_NegativeAdducts.tsv -algorithm:id_format ID > UTILS_AccurateMassSearch_6.stdout 2> UTILS_AccurateMassSearch_6.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_AccurateMassSearch_6 failed'; >&2 echo -e "stderr:\n$(cat UTILS_AccurateMassSearch_6.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_AccurateMassSearch_6.stdout)";fi
echo executing "UTILS_AssayGeneratorMetabo_1"
AssayGeneratorMetabo -test -in AssayGeneratorMetabo_input.mzML -in_id AssayGeneratorMetabo_ffm_input.featureXML -out AssayGeneratorMetabo_ffm_output.tmp.tsv -fragment_annotation none -min_transitions 1 -max_transitions 3 > UTILS_AssayGeneratorMetabo_1.stdout 2> UTILS_AssayGeneratorMetabo_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_AssayGeneratorMetabo_1 failed'; >&2 echo -e "stderr:\n$(cat UTILS_AssayGeneratorMetabo_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_AssayGeneratorMetabo_1.stdout)";fi
echo executing "UTILS_AssayGeneratorMetabo_2"
AssayGeneratorMetabo -test -in AssayGeneratorMetabo_input.mzML -in_id AssayGeneratorMetabo_ams_input.featureXML -out AssayGeneratorMetabo_ams_output.tmp.tsv -fragment_annotation none -min_transitions 1 -max_transitions 3 > UTILS_AssayGeneratorMetabo_2.stdout 2> UTILS_AssayGeneratorMetabo_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_AssayGeneratorMetabo_2 failed'; >&2 echo -e "stderr:\n$(cat UTILS_AssayGeneratorMetabo_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_AssayGeneratorMetabo_2.stdout)";fi
echo executing "UTILS_AssayGeneratorMetabo_3"
AssayGeneratorMetabo -test -in AssayGeneratorMetabo_input.mzML -in_id AssayGeneratorMetabo_ffm_input.featureXML -out AssayGeneratorMetabo_ffm_output_consensus.tmp.tsv -fragment_annotation none -method consensus_spectrum -min_transitions 1 -max_transitions 3 > UTILS_AssayGeneratorMetabo_3.stdout 2> UTILS_AssayGeneratorMetabo_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_AssayGeneratorMetabo_3 failed'; >&2 echo -e "stderr:\n$(cat UTILS_AssayGeneratorMetabo_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_AssayGeneratorMetabo_3.stdout)";fi
echo executing "UTILS_AssayGeneratorMetabo_4"
AssayGeneratorMetabo -test -in AssayGeneratorMetabo_input.mzML -in_id AssayGeneratorMetabo_ams_input.featureXML -out AssayGeneratorMetabo_ams_output_consensus.tmp.tsv -fragment_annotation none -method consensus_spectrum -min_transitions 1 -max_transitions 3 > UTILS_AssayGeneratorMetabo_4.stdout 2> UTILS_AssayGeneratorMetabo_4.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_AssayGeneratorMetabo_4 failed'; >&2 echo -e "stderr:\n$(cat UTILS_AssayGeneratorMetabo_4.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_AssayGeneratorMetabo_4.stdout)";fi
echo executing "UTILS_AssayGeneratorMetabo_5"
AssayGeneratorMetabo -test -in AssayGeneratorMetabo_input.mzML -in_id AssayGeneratorMetabo_ams_input.featureXML -out AssayGeneratorMetabo_ams_uku_output_consensus.tmp.tsv -fragment_annotation none -method consensus_spectrum -use_known_unknowns -min_transitions 1 -max_transitions 3 > UTILS_AssayGeneratorMetabo_5.stdout 2> UTILS_AssayGeneratorMetabo_5.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_AssayGeneratorMetabo_5 failed'; >&2 echo -e "stderr:\n$(cat UTILS_AssayGeneratorMetabo_5.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_AssayGeneratorMetabo_5.stdout)";fi
echo executing "UTILS_AssayGeneratorMetabo_6"
TargetedFileConverter -test -in AssayGeneratorMetabo_ams_uku_output_consensus.tsv  -out AssayGeneratorMetabo_ams_uku_output_consensus_traml.tmp.TraML > UTILS_AssayGeneratorMetabo_6.stdout 2> UTILS_AssayGeneratorMetabo_6.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_AssayGeneratorMetabo_6 failed'; >&2 echo -e "stderr:\n$(cat UTILS_AssayGeneratorMetabo_6.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_AssayGeneratorMetabo_6.stdout)";fi
echo executing "UTILS_ImageCreator_1"
ImageCreator -test -in ImageCreator_1_input.mzML -out ImageCreator1.bmp -width 20 -height 15 > UTILS_ImageCreator_1.stdout 2> UTILS_ImageCreator_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_ImageCreator_1 failed'; >&2 echo -e "stderr:\n$(cat UTILS_ImageCreator_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_ImageCreator_1.stdout)";fi
echo executing "UTILS_ImageCreator_2"
ImageCreator -test -in ImageCreator_2_input.mzML -out ImageCreator2.png -out_type bmp -width 20 -height 15 -precursors -precursor_size 3 -precursor_color green -log_intensity > UTILS_ImageCreator_2.stdout 2> UTILS_ImageCreator_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_ImageCreator_2 failed'; >&2 echo -e "stderr:\n$(cat UTILS_ImageCreator_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_ImageCreator_2.stdout)";fi
echo executing "UTILS_IDScoreSwitcher_1"
IDScoreSwitcher -test -in IDFileConverter_12_output.idXML -out IDScoreSwitcher_1_output.tmp -new_score Percolator_PEP -new_score_type "Posterior Error Probability" -new_score_orientation lower_better -old_score Percolator_qvalue > UTILS_IDScoreSwitcher_1.stdout 2> UTILS_IDScoreSwitcher_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_IDScoreSwitcher_1 failed'; >&2 echo -e "stderr:\n$(cat UTILS_IDScoreSwitcher_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_IDScoreSwitcher_1.stdout)";fi
echo executing "UTILS_IDScoreSwitcher_2"
IDScoreSwitcher -test -in IDScoreSwitcher_2_input.idXML -out IDScoreSwitcher_2_output.tmp -new_score "Posterior Probability_score" -new_score_type "Posterior Probability" -new_score_orientation higher_better -proteins > UTILS_IDScoreSwitcher_2.stdout 2> UTILS_IDScoreSwitcher_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_IDScoreSwitcher_2 failed'; >&2 echo -e "stderr:\n$(cat UTILS_IDScoreSwitcher_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_IDScoreSwitcher_2.stdout)";fi
echo executing "UTILS_IDSplitter_1"
IDSplitter -test -in IDMapper_1_output.featureXML -out IDSplitter_1_output1.tmp -id_out IDSplitter_1_output2.tmp > UTILS_IDSplitter_1.stdout 2> UTILS_IDSplitter_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_IDSplitter_1 failed'; >&2 echo -e "stderr:\n$(cat UTILS_IDSplitter_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_IDSplitter_1.stdout)";fi
echo executing "UTILS_MassCalculator_1"
MassCalculator -test -in MassCalculator_1_input.tsv -out MassCalculator_1_output.tmp -charge 0 1 -format table -separator , > UTILS_MassCalculator_1.stdout 2> UTILS_MassCalculator_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_MassCalculator_1 failed'; >&2 echo -e "stderr:\n$(cat UTILS_MassCalculator_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_MassCalculator_1.stdout)";fi
echo executing "UTILS_MassCalculator_2"
MassCalculator -test -in_seq "LDQWLC(Carbamidomethyl)EKL" "(Glu->pyro-Glu)EAM(Oxidation)APKHK" "RANVM(Oxidation)DYR" "FGVEQDVDMVFASFIR" -out MassCalculator_2_output.tmp -charge 1 2 3 > UTILS_MassCalculator_2.stdout 2> UTILS_MassCalculator_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_MassCalculator_2 failed'; >&2 echo -e "stderr:\n$(cat UTILS_MassCalculator_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_MassCalculator_2.stdout)";fi
echo executing "UTILS_MultiplexResolver_1"
MultiplexResolver -test -in MultiplexResolver_1_input.consensusXML -ini MultiplexResolver_1_parameters.ini -out MultiplexResolver_1.tmp -out_conflicts MultiplexResolver_1_conflicts.tmp > UTILS_MultiplexResolver_1.stdout 2> UTILS_MultiplexResolver_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_MultiplexResolver_1 failed'; >&2 echo -e "stderr:\n$(cat UTILS_MultiplexResolver_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_MultiplexResolver_1.stdout)";fi
echo executing "UTILS_MultiplexResolver_2"
MultiplexResolver -test -in MultiplexResolver_2_input.consensusXML -ini MultiplexResolver_2_parameters.ini -out MultiplexResolver_2.tmp -out_conflicts MultiplexResolver_2_conflicts.tmp > UTILS_MultiplexResolver_2.stdout 2> UTILS_MultiplexResolver_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_MultiplexResolver_2 failed'; >&2 echo -e "stderr:\n$(cat UTILS_MultiplexResolver_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_MultiplexResolver_2.stdout)";fi
echo executing "UTILS_MultiplexResolver_3"
MultiplexResolver -test -in MultiplexResolver_3_input.consensusXML -ini MultiplexResolver_3_parameters.ini -out MultiplexResolver_3.tmp -out_conflicts MultiplexResolver_3_conflicts.tmp > UTILS_MultiplexResolver_3.stdout 2> UTILS_MultiplexResolver_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_MultiplexResolver_3 failed'; >&2 echo -e "stderr:\n$(cat UTILS_MultiplexResolver_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_MultiplexResolver_3.stdout)";fi
echo executing "UTILS_MultiplexResolver_4"
MultiplexResolver -test -in MultiplexResolver_4_input.consensusXML -in_blacklist MultiplexResolver_4_input.mzML -ini MultiplexResolver_4_parameters.ini -out MultiplexResolver_4.tmp -out_conflicts MultiplexResolver_4_conflicts.tmp > UTILS_MultiplexResolver_4.stdout 2> UTILS_MultiplexResolver_4.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_MultiplexResolver_4 failed'; >&2 echo -e "stderr:\n$(cat UTILS_MultiplexResolver_4.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_MultiplexResolver_4.stdout)";fi
echo executing "UTILS_INIUpdater_1"
INIUpdater -test -in INIUpdater_1_noupdate.toppas -out INIUpdater_1_noupdate.toppas.tmp > UTILS_INIUpdater_1.stdout 2> UTILS_INIUpdater_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_INIUpdater_1 failed'; >&2 echo -e "stderr:\n$(cat UTILS_INIUpdater_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_INIUpdater_1.stdout)";fi
echo executing "UTILS_INIUpdater_3"
INIUpdater -test -in INIUpdater_3_old.toppas -out INIUpdater_3_old.toppas.tmp > UTILS_INIUpdater_3.stdout 2> UTILS_INIUpdater_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_INIUpdater_3 failed'; >&2 echo -e "stderr:\n$(cat UTILS_INIUpdater_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_INIUpdater_3.stdout)";fi
echo executing "UTILS_DatabaseFilter_1"
DatabaseFilter -test -in DatabaseFilter_1.fasta -id DatabaseFilter_1.idXML -out DatabaseFilter_1_out.fasta.tmp > UTILS_DatabaseFilter_1.stdout 2> UTILS_DatabaseFilter_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_DatabaseFilter_1 failed'; >&2 echo -e "stderr:\n$(cat UTILS_DatabaseFilter_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_DatabaseFilter_1.stdout)";fi
echo executing "UTILS_DatabaseFilter_2"
DatabaseFilter -test -in DatabaseFilter_1.fasta -id DatabaseFilter_1.idXML -out DatabaseFilter_2_out.fasta.tmp -method blacklist > UTILS_DatabaseFilter_2.stdout 2> UTILS_DatabaseFilter_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_DatabaseFilter_2 failed'; >&2 echo -e "stderr:\n$(cat UTILS_DatabaseFilter_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_DatabaseFilter_2.stdout)";fi
echo executing "UTILS_DatabaseFilter_3"
DatabaseFilter -test -in DatabaseFilter_3.fasta -id DatabaseFilter_3.mzid -out DatabaseFilter_3_out.fasta.tmp > UTILS_DatabaseFilter_3.stdout 2> UTILS_DatabaseFilter_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_DatabaseFilter_3 failed'; >&2 echo -e "stderr:\n$(cat UTILS_DatabaseFilter_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_DatabaseFilter_3.stdout)";fi
echo executing "UTILS_DatabaseFilter_4"
DatabaseFilter -test -in DatabaseFilter_3.fasta -id DatabaseFilter_3.mzid -out DatabaseFilter_4_out.fasta.tmp -method blacklist > UTILS_DatabaseFilter_4.stdout 2> UTILS_DatabaseFilter_4.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_DatabaseFilter_4 failed'; >&2 echo -e "stderr:\n$(cat UTILS_DatabaseFilter_4.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_DatabaseFilter_4.stdout)";fi
echo executing "UTILS_DecoyDatabase_1"
DecoyDatabase -test -in DecoyDatabase_1.fasta -out DecoyDatabase_1.fasta.tmp -only_decoy > UTILS_DecoyDatabase_1.stdout 2> UTILS_DecoyDatabase_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_DecoyDatabase_1 failed'; >&2 echo -e "stderr:\n$(cat UTILS_DecoyDatabase_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_DecoyDatabase_1.stdout)";fi
echo executing "UTILS_DecoyDatabase_2"
DecoyDatabase -test -in DecoyDatabase_1.fasta -out DecoyDatabase_2.fasta.tmp -decoy_string "blabla" -decoy_string_position "prefix" -method shuffle -Decoy:non_shuffle_pattern "KRP" -seed 42 > UTILS_DecoyDatabase_2.stdout 2> UTILS_DecoyDatabase_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_DecoyDatabase_2 failed'; >&2 echo -e "stderr:\n$(cat UTILS_DecoyDatabase_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_DecoyDatabase_2.stdout)";fi
echo executing "UTILS_DecoyDatabase_3"
DecoyDatabase -test -in DecoyDatabase_1.fasta -out DecoyDatabase_3.fasta.tmp -decoy_string "blabla" -decoy_string_position "prefix" -method shuffle -Decoy:non_shuffle_pattern "KR" -seed 42 -enzyme "Chymotrypsin" > UTILS_DecoyDatabase_3.stdout 2> UTILS_DecoyDatabase_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_DecoyDatabase_3 failed'; >&2 echo -e "stderr:\n$(cat UTILS_DecoyDatabase_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_DecoyDatabase_3.stdout)";fi
echo executing "UTILS_DecoyDatabase_4"
DecoyDatabase -test -type RNA -in DecoyDatabase_4.fasta -out DecoyDatabase_4.fasta.tmp -decoy_string "blabla" -decoy_string_position "prefix" -method reverse -seed 42  > UTILS_DecoyDatabase_4.stdout 2> UTILS_DecoyDatabase_4.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_DecoyDatabase_4 failed'; >&2 echo -e "stderr:\n$(cat UTILS_DecoyDatabase_4.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_DecoyDatabase_4.stdout)";fi
echo executing "UTILS_SimpleSearchEngine_1"
SimpleSearchEngine -test -ini SimpleSearchEngine_1.ini -in SimpleSearchEngine_1.mzML -out SimpleSearchEngine_1_out.tmp -database SimpleSearchEngine_1.fasta > UTILS_SimpleSearchEngine_1.stdout 2> UTILS_SimpleSearchEngine_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_SimpleSearchEngine_1 failed'; >&2 echo -e "stderr:\n$(cat UTILS_SimpleSearchEngine_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_SimpleSearchEngine_1.stdout)";fi
echo executing "UTILS_SimpleSearchEngine_2"
SimpleSearchEngine -test -ini SimpleSearchEngine_2.ini -in SimpleSearchEngine_1.mzML -out SimpleSearchEngine_2_out.tmp -database SimpleSearchEngine_1.fasta > UTILS_SimpleSearchEngine_2.stdout 2> UTILS_SimpleSearchEngine_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_SimpleSearchEngine_2 failed'; >&2 echo -e "stderr:\n$(cat UTILS_SimpleSearchEngine_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_SimpleSearchEngine_2.stdout)";fi
echo executing "UTILS_FeatureFinderMetaboIdent_1"
FeatureFinderMetaboIdent -test -in FeatureFinderMetaboIdent_1_input.mzML -id FeatureFinderMetaboIdent_1_input.tsv -out FeatureFinderMetaboIdent_1_output.tmp -extract:mz_window 5 -extract:rt_window 20 -detect:peak_width 3 > UTILS_FeatureFinderMetaboIdent_1.stdout 2> UTILS_FeatureFinderMetaboIdent_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_FeatureFinderMetaboIdent_1 failed'; >&2 echo -e "stderr:\n$(cat UTILS_FeatureFinderMetaboIdent_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_FeatureFinderMetaboIdent_1.stdout)";fi
echo executing "UTILS_MzMLSplitter_1"
MzMLSplitter -test -in FileFilter_1_input.mzML -out MzMLSplitter_1_output -parts 2 > UTILS_MzMLSplitter_1.stdout 2> UTILS_MzMLSplitter_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_MzMLSplitter_1 failed'; >&2 echo -e "stderr:\n$(cat UTILS_MzMLSplitter_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_MzMLSplitter_1.stdout)";fi
echo executing "UTILS_MzMLSplitter_2"
MzMLSplitter -test -in FileFilter_1_input.mzML -out MzMLSplitter_2_output -size 40 -unit KB > UTILS_MzMLSplitter_2.stdout 2> UTILS_MzMLSplitter_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_MzMLSplitter_2 failed'; >&2 echo -e "stderr:\n$(cat UTILS_MzMLSplitter_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_MzMLSplitter_2.stdout)";fi
echo executing "UTILS_TICCalculator_1"
TICCalculator -test -in MapNormalizer_output.mzML -read_method regular > UTILS_TICCalculator_1.stdout 2> UTILS_TICCalculator_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_TICCalculator_1 failed'; >&2 echo -e "stderr:\n$(cat UTILS_TICCalculator_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_TICCalculator_1.stdout)";fi
echo executing "UTILS_TICCalculator_2"
TICCalculator -test -in MapNormalizer_output.mzML -read_method streaming -loadData true > UTILS_TICCalculator_2.stdout 2> UTILS_TICCalculator_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_TICCalculator_2 failed'; >&2 echo -e "stderr:\n$(cat UTILS_TICCalculator_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_TICCalculator_2.stdout)";fi
echo executing "UTILS_TICCalculator_3"
TICCalculator -test -in MapNormalizer_output.mzML -read_method streaming -loadData false > UTILS_TICCalculator_3.stdout 2> UTILS_TICCalculator_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_TICCalculator_3 failed'; >&2 echo -e "stderr:\n$(cat UTILS_TICCalculator_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_TICCalculator_3.stdout)";fi
echo executing "UTILS_TICCalculator_4"
TICCalculator -test -in MapNormalizer_output.mzML -read_method indexed > UTILS_TICCalculator_4.stdout 2> UTILS_TICCalculator_4.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_TICCalculator_4 failed'; >&2 echo -e "stderr:\n$(cat UTILS_TICCalculator_4.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_TICCalculator_4.stdout)";fi
echo executing "UTILS_TICCalculator_5"
TICCalculator -test -in MapNormalizer_output.mzML -read_method indexed_parallel > UTILS_TICCalculator_5.stdout 2> UTILS_TICCalculator_5.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_TICCalculator_5 failed'; >&2 echo -e "stderr:\n$(cat UTILS_TICCalculator_5.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_TICCalculator_5.stdout)";fi
echo executing "UTILS_ProteomicsLFQ_1"
ProteomicsLFQ -in examples/FRACTIONS/BSA1_F1.mzML examples/FRACTIONS/BSA1_F2.mzML examples/FRACTIONS/BSA2_F1.mzML examples/FRACTIONS/BSA2_F2.mzML examples/FRACTIONS/BSA3_F1.mzML examples/FRACTIONS/BSA3_F2.mzML -ids examples/FRACTIONS/BSA1_F1.idXML examples/FRACTIONS/BSA1_F2.idXML examples/FRACTIONS/BSA2_F1.idXML examples/FRACTIONS/BSA2_F2.idXML examples/FRACTIONS/BSA3_F1.idXML examples/FRACTIONS/BSA3_F2.idXML -design examples/FRACTIONS/BSA_design.tsv -Alignment:align_algorithm:max_rt_shift 0 -fasta examples/TOPPAS/data/BSA_Identification/18Protein_SoCe_Tr_detergents_trace_target_decoy.fasta -targeted_only true -transfer_ids false -mass_recalibration false -out_cxml BSA.consensusXML.tmp -out_msstats BSA.csv.tmp -out BSA.mzTab.tmp -out_triqler BSA.tsv.tmp -threads 1 -proteinFDR 0.3 -test  > UTILS_ProteomicsLFQ_1.stdout 2> UTILS_ProteomicsLFQ_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_ProteomicsLFQ_1 failed'; >&2 echo -e "stderr:\n$(cat UTILS_ProteomicsLFQ_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_ProteomicsLFQ_1.stdout)";fi
echo executing "UTILS_ProteomicsLFQ_2"
ProteomicsLFQ -in examples/FRACTIONS/BSA1_F1.mzML examples/FRACTIONS/BSA1_F2.mzML examples/FRACTIONS/BSA2_F1.mzML examples/FRACTIONS/BSA2_F2.mzML examples/FRACTIONS/BSA3_F1.mzML examples/FRACTIONS/BSA3_F2.mzML -ids examples/FRACTIONS/BSA1_F1_decoys.idXML examples/FRACTIONS/BSA1_F2.idXML examples/FRACTIONS/BSA2_F1.idXML examples/FRACTIONS/BSA2_F2.idXML examples/FRACTIONS/BSA3_F1.idXML examples/FRACTIONS/BSA3_F2.idXML -design examples/FRACTIONS/BSA_design.tsv -Alignment:align_algorithm:max_rt_shift 0 -fasta examples/TOPPAS/data/BSA_Identification/18Protein_SoCe_Tr_detergents_trace_target_decoy.fasta -targeted_only true -transfer_ids mean -mass_recalibration false -out_cxml BSA_plusTransfer.consensusXML.tmp -out_msstats BSA_plusTransfer.csv.tmp -out BSA_plusTransfer.mzTab.tmp -out_triqler BSA_plusTransfer.tsv.tmp -threads 1 -proteinFDR 0.3 -test  > UTILS_ProteomicsLFQ_2.stdout 2> UTILS_ProteomicsLFQ_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_ProteomicsLFQ_2 failed'; >&2 echo -e "stderr:\n$(cat UTILS_ProteomicsLFQ_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_ProteomicsLFQ_2.stdout)";fi
echo executing "UTILS_ProteomicsLFQ_3"
ProteomicsLFQ -in examples/FRACTIONS/BSA1_F1.mzML examples/FRACTIONS/BSA1_F2.mzML examples/FRACTIONS/BSA2_F1.mzML examples/FRACTIONS/BSA2_F2.mzML examples/FRACTIONS/BSA3_F1.mzML examples/FRACTIONS/BSA3_F2.mzML -ids examples/FRACTIONS/BSA1_F1.idXML examples/FRACTIONS/BSA1_F2.idXML examples/FRACTIONS/BSA2_F1.idXML examples/FRACTIONS/BSA2_F2.idXML examples/FRACTIONS/BSA3_F1.idXML examples/FRACTIONS/BSA3_F2.idXML -design examples/FRACTIONS/BSA_design.tsv -Alignment:align_algorithm:max_rt_shift 0 -Linking:min_nr_diffs_per_bin 10 -fasta examples/TOPPAS/data/BSA_Identification/18Protein_SoCe_Tr_detergents_trace_target_decoy.fasta -targeted_only false -transfer_ids mean -mass_recalibration false -out_cxml BSA_plusSeeds_plusTransfer.consensusXML.tmp -out_msstats BSA_plusSeeds_plusTransfer.csv.tmp -out BSA_plusSeeds_plusTransfer.mzTab.tmp -out_triqler BSA_plusSeeds_plusTransfer.tsv.tmp -threads 1 -proteinFDR 0.3 -test -debug 0  > UTILS_ProteomicsLFQ_3.stdout 2> UTILS_ProteomicsLFQ_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_ProteomicsLFQ_3 failed'; >&2 echo -e "stderr:\n$(cat UTILS_ProteomicsLFQ_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_ProteomicsLFQ_3.stdout)";fi
echo executing "UTILS_ProteomicsLFQ_4"
ProteomicsLFQ -in examples/FRACTIONS/BSA1_F1.mzML examples/FRACTIONS/BSA1_F2.mzML examples/FRACTIONS/BSA2_F1.mzML examples/FRACTIONS/BSA2_F2.mzML examples/FRACTIONS/BSA3_F1.mzML examples/FRACTIONS/BSA3_F2.mzML -ids examples/FRACTIONS/BSA1_F1.idXML examples/FRACTIONS/BSA1_F2.idXML examples/FRACTIONS/BSA2_F1.idXML examples/FRACTIONS/BSA2_F2.idXML examples/FRACTIONS/BSA3_F1.idXML examples/FRACTIONS/BSA3_F2.idXML -design examples/FRACTIONS/BSA_design.tsv -fasta examples/TOPPAS/data/BSA_Identification/18Protein_SoCe_Tr_detergents_trace_target_decoy.fasta -quantification_method spectral_counting -out_cxml BSA_sc.consensusXML.tmp -out BSA_sc.mzTab.tmp -threads 1 -proteinFDR 0.3 -test  > UTILS_ProteomicsLFQ_4.stdout 2> UTILS_ProteomicsLFQ_4.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_ProteomicsLFQ_4 failed'; >&2 echo -e "stderr:\n$(cat UTILS_ProteomicsLFQ_4.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_ProteomicsLFQ_4.stdout)";fi
echo executing "UTILS_ProteomicsLFQ_5"
ProteomicsLFQ -in examples/FRACTIONS/BSA1_F1.mzML examples/FRACTIONS/BSA1_F2.mzML examples/FRACTIONS/BSA2_F1.mzML examples/FRACTIONS/BSA2_F2.mzML examples/FRACTIONS/BSA3_F1.mzML examples/FRACTIONS/BSA3_F2.mzML -ids examples/FRACTIONS/BSA1_F1_decoys.idXML examples/FRACTIONS/BSA1_F2.idXML examples/FRACTIONS/BSA2_F1.idXML examples/FRACTIONS/BSA2_F2.idXML examples/FRACTIONS/BSA3_F1.idXML examples/FRACTIONS/BSA3_F2.idXML -design examples/FRACTIONS/BSA_design.tsv -Alignment:align_algorithm:max_rt_shift 0 -fasta examples/TOPPAS/data/BSA_Identification/18Protein_SoCe_Tr_detergents_trace_target_decoy.fasta -PeptideQuantification:quantify_decoys -targeted_only true -transfer_ids false -mass_recalibration false -out_cxml BSA_decoys.consensusXML.tmp -out_msstats BSA_decoys.csv.tmp -out BSA_decoys.mzTab.tmp -out_triqler BSA_decoys.tsv.tmp -threads 1 -proteinFDR 0.3 -test  > UTILS_ProteomicsLFQ_5.stdout 2> UTILS_ProteomicsLFQ_5.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_ProteomicsLFQ_5 failed'; >&2 echo -e "stderr:\n$(cat UTILS_ProteomicsLFQ_5.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_ProteomicsLFQ_5.stdout)";fi
echo executing "UTILS_ProteomicsLFQ_6"
ProteomicsLFQ -in examples/FRACTIONS/BSA1_F1.mzML examples/FRACTIONS/BSA1_F2.mzML examples/FRACTIONS/BSA2_F1.mzML examples/FRACTIONS/BSA2_F2.mzML examples/FRACTIONS/BSA3_F1.mzML examples/FRACTIONS/BSA3_F2.mzML -ids examples/FRACTIONS/BSA1_F1_msgf_idx_fdr_idpep_switched_filter.idXML examples/FRACTIONS/BSA1_F2_msgf_idx_fdr_idpep_switched_filter.idXML examples/FRACTIONS/BSA2_F1_msgf_idx_fdr_idpep_switched_filter.idXML examples/FRACTIONS/BSA2_F2_msgf_idx_fdr_idpep_switched_filter.idXML examples/FRACTIONS/BSA3_F1_msgf_idx_fdr_idpep_switched_filter.idXML examples/FRACTIONS/BSA3_F2_msgf_idx_fdr_idpep_switched_filter.idXML -design examples/FRACTIONS/BSA_design.tsv -fasta examples/TOPPAS/data/BSA_Identification/18Protein_SoCe_Tr_detergents_trace_target_decoy.fasta -quantification_method spectral_counting -out_cxml BSA_sc_decoys.consensusXML.tmp -out BSA_sc_decoys.mzTab.tmp -threads 1 -proteinFDR 1.0 -test  > UTILS_ProteomicsLFQ_6.stdout 2> UTILS_ProteomicsLFQ_6.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_ProteomicsLFQ_6 failed'; >&2 echo -e "stderr:\n$(cat UTILS_ProteomicsLFQ_6.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_ProteomicsLFQ_6.stdout)";fi
echo executing "UTILS_ProteomicsLFQ_7"
ProteomicsLFQ -in examples/FRACTIONS/BSA1_F2.mzML examples/FRACTIONS/BSA2_F2.mzML -ids examples/FRACTIONS/BSA1_F2.idXML examples/FRACTIONS/BSA2_F2.idXML -design examples/FRACTIONS/BSA_design.tsv -Alignment:align_algorithm:max_rt_shift 0 -fasta examples/TOPPAS/data/BSA_Identification/18Protein_SoCe_Tr_detergents_trace_target_decoy.fasta -targeted_only true -transfer_ids false -mass_recalibration false -out_cxml BSA_sub.consensusXML.tmp -out_msstats BSA_sub.csv.tmp -out BSA_sub.mzTab.tmp -out_triqler BSA_sub.tsv.tmp -threads 1 -proteinFDR 0.8 -test  > UTILS_ProteomicsLFQ_7.stdout 2> UTILS_ProteomicsLFQ_7.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_ProteomicsLFQ_7 failed'; >&2 echo -e "stderr:\n$(cat UTILS_ProteomicsLFQ_7.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_ProteomicsLFQ_7.stdout)";fi
echo executing "UTILS_NucleicAcidSearchEngine_1"
NucleicAcidSearchEngine -test -ini NucleicAcidSearchEngine_1.ini -in NucleicAcidSearchEngine_1.mzML -id_out NucleicAcidSearchEngine_11_out.tmp -out NucleicAcidSearchEngine_12_out.tmp -db_out NucleicAcidSearchEngine_13_out.tmp -digest_out NucleicAcidSearchEngine_1_digest.oms -database NucleicAcidSearchEngine_1.fasta > UTILS_NucleicAcidSearchEngine_1.stdout 2> UTILS_NucleicAcidSearchEngine_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_NucleicAcidSearchEngine_1 failed'; >&2 echo -e "stderr:\n$(cat UTILS_NucleicAcidSearchEngine_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_NucleicAcidSearchEngine_1.stdout)";fi
echo executing "UTILS_NucleicAcidSearchEngine_2"
NucleicAcidSearchEngine -test -ini NucleicAcidSearchEngine_1.ini -in NucleicAcidSearchEngine_1.mzML -id_out NucleicAcidSearchEngine_21_out.tmp -out NucleicAcidSearchEngine_22_out.tmp -db_out NucleicAcidSearchEngine_23_out.tmp -digest NucleicAcidSearchEngine_1_digest.oms > UTILS_NucleicAcidSearchEngine_2.stdout 2> UTILS_NucleicAcidSearchEngine_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_NucleicAcidSearchEngine_2 failed'; >&2 echo -e "stderr:\n$(cat UTILS_NucleicAcidSearchEngine_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_NucleicAcidSearchEngine_2.stdout)";fi
echo executing "UTILS_RNAMassCalculator_1"
RNAMassCalculator -test -in_seq "AUCGGC" -charge -1 -2 -out RNAMassCalculator.tmp > UTILS_RNAMassCalculator_1.stdout 2> UTILS_RNAMassCalculator_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_RNAMassCalculator_1 failed'; >&2 echo -e "stderr:\n$(cat UTILS_RNAMassCalculator_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_RNAMassCalculator_1.stdout)";fi
echo executing "UTILS_Epifany_1"
Epifany -test -in FidoAdapter_1_input.idXML -algorithm:model_parameters:prot_prior 0.7 -algorithm:model_parameters:pep_spurious_emission 0.001 -algorithm:model_parameters:pep_emission 0.1 -out Epifany_1_out.tmp > UTILS_Epifany_1.stdout 2> UTILS_Epifany_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_Epifany_1 failed'; >&2 echo -e "stderr:\n$(cat UTILS_Epifany_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_Epifany_1.stdout)";fi
echo executing "UTILS_Epifany_2"
Epifany -test -in Epifany_2_input.consensusXML -algorithm:model_parameters:prot_prior 0.7 -algorithm:model_parameters:pep_spurious_emission 0.001 -algorithm:model_parameters:pep_emission 0.1 -out Epifany_2_out.tmp -out_type consensusXML > UTILS_Epifany_2.stdout 2> UTILS_Epifany_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_Epifany_2 failed'; >&2 echo -e "stderr:\n$(cat UTILS_Epifany_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_Epifany_2.stdout)";fi
echo executing "UTILS_Epifany_3"
Epifany -test -in Epifany_2_input.consensusXML -algorithm:keep_best_PSM_only false -algorithm:model_parameters:prot_prior 0.7 -algorithm:model_parameters:pep_spurious_emission 0.001 -algorithm:model_parameters:pep_emission 0.1 -out Epifany_3_out.tmp -out_type consensusXML > UTILS_Epifany_3.stdout 2> UTILS_Epifany_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_Epifany_3 failed'; >&2 echo -e "stderr:\n$(cat UTILS_Epifany_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_Epifany_3.stdout)";fi
echo executing "UTILS_Epifany_4"
Epifany -test -in FidoAdapter_1_input_singlerun.idXML -algorithm:model_parameters:prot_prior 0.7 -algorithm:model_parameters:pep_spurious_emission 0.001 -algorithm:model_parameters:pep_emission 0.1 -greedy_group_resolution remove_proteins_wo_evidence -out Epifany_4_out.tmp > UTILS_Epifany_4.stdout 2> UTILS_Epifany_4.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_Epifany_4 failed'; >&2 echo -e "stderr:\n$(cat UTILS_Epifany_4.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_Epifany_4.stdout)";fi
echo executing "UTILS_Epifany_5"
Epifany -test -in FidoAdapter_1_input_singlerun.idXML -algorithm:model_parameters:prot_prior 0.7 -algorithm:model_parameters:pep_spurious_emission 0.001 -algorithm:model_parameters:pep_emission 0.1 -greedy_group_resolution remove_proteins_wo_evidence -protein_fdr true -picked_fdr false -out Epifany_5_out.tmp > UTILS_Epifany_5.stdout 2> UTILS_Epifany_5.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_Epifany_5 failed'; >&2 echo -e "stderr:\n$(cat UTILS_Epifany_5.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_Epifany_5.stdout)";fi
echo executing "UTILS_QCCalculator_1"
QCCalculator -test -in QCCalculator_input.mzML -out QCCalculator_1.qcML > UTILS_QCCalculator_1.stdout 2> UTILS_QCCalculator_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_QCCalculator_1 failed'; >&2 echo -e "stderr:\n$(cat UTILS_QCCalculator_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_QCCalculator_1.stdout)";fi
echo executing "UTILS_QCCalculator_2"
QCCalculator -test -in QCCalculator_input.mzML -label label -name name -address address -description description -out QCCalculator_2.mzQC -feature FeatureFinderMetaboIdent_1_output.featureXML -id OpenPepXL_output.idXML > UTILS_QCCalculator_2.stdout 2> UTILS_QCCalculator_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_QCCalculator_2 failed'; >&2 echo -e "stderr:\n$(cat UTILS_QCCalculator_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_QCCalculator_2.stdout)";fi
echo executing "TOPP_OMSSAAdapter_1"
OMSSAAdapter -test -ini OMSSAAdapter_1.ini -database proteins.fasta -in spectra.mzML -out OMSSAAdapter_1_out.tmp -omssa_executable "${OMSSA_BINARY}" > TOPP_OMSSAAdapter_1.stdout 2> TOPP_OMSSAAdapter_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_OMSSAAdapter_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_OMSSAAdapter_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_OMSSAAdapter_1.stdout)";fi
echo executing "TOPP_XTandemAdapter_1"
XTandemAdapter -test -ini XTandemAdapter_1.ini -database proteins.fasta -in spectra.mzML -out XTandemAdapter_1_out.tmp -xtandem_executable "${XTANDEM_BINARY}" > TOPP_XTandemAdapter_1.stdout 2> TOPP_XTandemAdapter_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_XTandemAdapter_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_XTandemAdapter_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_XTandemAdapter_1.stdout)";fi
echo executing "TOPP_XTandemAdapter_2"
XTandemAdapter -test -ini XTandemAdapter_1.ini -database proteins.fasta -in spectra.mzML -out XTandemAdapter_2_out.tmp -output_results valid -xtandem_executable "${XTANDEM_BINARY}" -max_valid_expect 1e-14 > TOPP_XTandemAdapter_2.stdout 2> TOPP_XTandemAdapter_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_XTandemAdapter_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_XTandemAdapter_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_XTandemAdapter_2.stdout)";fi
echo executing "TOPP_XTandemAdapter_3"
XTandemAdapter -test -ini XTandemAdapter_1.ini -database proteinslong.fasta -in spectra.mzML -out XTandemAdapter_3_out.tmp -xtandem_executable "${XTANDEM_BINARY}" > TOPP_XTandemAdapter_3.stdout 2> TOPP_XTandemAdapter_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_XTandemAdapter_3 failed'; >&2 echo -e "stderr:\n$(cat TOPP_XTandemAdapter_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_XTandemAdapter_3.stdout)";fi
echo executing "TOPP_MyriMatchAdapter_1"
MyriMatchAdapter -test -ini MyriMatchAdapter_1.ini -database proteins.fasta -in spectra.mzML -out MyriMatchAdapter_1_out.tmp -myrimatch_executable "${MYRIMATCH_BINARY}" > TOPP_MyriMatchAdapter_1.stdout 2> TOPP_MyriMatchAdapter_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_MyriMatchAdapter_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_MyriMatchAdapter_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_MyriMatchAdapter_1.stdout)";fi
echo executing "TOPP_MSGFPlusAdapter_1"
MSGFPlusAdapter -test -ini MSGFPlusAdapter_1.ini -database proteins.fasta -in spectra.mzML -out MSGFPlusAdapter_1_out1.tmp -mzid_out MSGFPlusAdapter_1_out2.tmp.mzid -executable "${MSGFPLUS_BINARY}" > TOPP_MSGFPlusAdapter_1.stdout 2> TOPP_MSGFPlusAdapter_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_MSGFPlusAdapter_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_MSGFPlusAdapter_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_MSGFPlusAdapter_1.stdout)";fi
echo executing "TOPP_CruxAdapter_1"
CruxAdapter -test -ini CruxAdapter_1.ini -database proteins.fasta -in spectra_comet.mzML -out CruxAdapter_1_out1.tmp -crux_executable "${CRUX_BINARY}" -run_percolator false -decoy_format peptide-reverse > TOPP_CruxAdapter_1.stdout 2> TOPP_CruxAdapter_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_CruxAdapter_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_CruxAdapter_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_CruxAdapter_1.stdout)";fi
echo executing "TOPP_CometAdapter_1"
CometAdapter -test -ini CometAdapter_1.ini -database proteins.fasta -in spectra_comet.mzML -out CometAdapter_1_out1.tmp -pin_out CometAdapter_1_out2.tmp.tsv -comet_executable "${COMET_BINARY}" > TOPP_CometAdapter_1.stdout 2> TOPP_CometAdapter_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_CometAdapter_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_CometAdapter_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_CometAdapter_1.stdout)";fi
echo executing "TOPP_CometAdapter_2_prepare"
FileConverter -test -in CometAdapter_2_in.mzML -out CometAdapter_2_prepared.mzML -force_TPP_compatibility > TOPP_CometAdapter_2_prepare.stdout 2> TOPP_CometAdapter_2_prepare.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_CometAdapter_2_prepare failed'; >&2 echo -e "stderr:\n$(cat TOPP_CometAdapter_2_prepare.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_CometAdapter_2_prepare.stdout)";fi
echo executing "TOPP_CometAdapter_2"
CometAdapter -force -test -database CometAdapter_2_in.fasta -in CometAdapter_2_prepared.mzML -out CometAdapter_2_out1.tmp -pin_out CometAdapter_2_out2.tmp.tsv -comet_executable "${COMET_BINARY}" -precursor_mass_tolerance 3 -precursor_error_units Da -ini CometAdapter_1.ini > TOPP_CometAdapter_2.stdout 2> TOPP_CometAdapter_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_CometAdapter_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_CometAdapter_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_CometAdapter_2.stdout)";fi
echo executing "TOPP_CometAdapter_3"
CometAdapter -test -ini CometAdapter_3.ini -database CometAdapter_3.fasta -in CometAdapter_3.mzML -out CometAdapter_3_out1.tmp -pin_out CometAdapter_3_out2.tmp.tsv -comet_executable "${COMET_BINARY}" > TOPP_CometAdapter_3.stdout 2> TOPP_CometAdapter_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_CometAdapter_3 failed'; >&2 echo -e "stderr:\n$(cat TOPP_CometAdapter_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_CometAdapter_3.stdout)";fi
echo executing "TOPP_CometAdapter_4"
CometAdapter -test -ini CometAdapter_3.ini -digest_mass_range "600:1200" -variable_modifications "Met-loss (Protein N-term M)" -database examples/TOPPAS/data/BSA_Identification/18Protein_SoCe_Tr_detergents_trace_target_decoy.fasta -in examples/FRACTIONS/BSA1_F1.mzML -out CometAdapter_4_out1.tmp -comet_executable "${COMET_BINARY}" > TOPP_CometAdapter_4.stdout 2> TOPP_CometAdapter_4.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_CometAdapter_4 failed'; >&2 echo -e "stderr:\n$(cat TOPP_CometAdapter_4.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_CometAdapter_4.stdout)";fi
echo executing "TOPP_MaRaClusterAdapter_1"
MaRaClusterAdapter -test -ini MaRaClusterAdapter_1.ini -in MaRaClusterAdapter_1_in_1.mzML MaRaClusterAdapter_1_in_2.mzML -consensus_out MaRaClusterAdapter_1_out_1.tmp.mzML -maracluster_executable "${MARACLUSTER_BINARY}" > TOPP_MaRaClusterAdapter_1.stdout 2> TOPP_MaRaClusterAdapter_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_MaRaClusterAdapter_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_MaRaClusterAdapter_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_MaRaClusterAdapter_1.stdout)";fi
echo executing "TOPP_MaRaClusterAdapter_2"
MaRaClusterAdapter -test -ini MaRaClusterAdapter_2.ini -in MaRaClusterAdapter_1_in_1.mzML MaRaClusterAdapter_1_in_2.mzML -id_in MaRaClusterAdapter_1_in_3.idXML -out MaRaClusterAdapter_2_out_1.tmp.idXML -maracluster_executable "${MARACLUSTER_BINARY}" > TOPP_MaRaClusterAdapter_2.stdout 2> TOPP_MaRaClusterAdapter_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_MaRaClusterAdapter_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_MaRaClusterAdapter_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_MaRaClusterAdapter_2.stdout)";fi
echo executing "TOPP_PercolatorAdapter_1"
PercolatorAdapter -test -ini PercolatorAdapter_1.ini -in PercolatorAdapter_1.idXML -out PercolatorAdapter_1_out1.tmp -out_type idXML -percolator_executable "${PERCOLATOR_BINARY}" > TOPP_PercolatorAdapter_1.stdout 2> TOPP_PercolatorAdapter_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_PercolatorAdapter_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_PercolatorAdapter_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_PercolatorAdapter_1.stdout)";fi
echo executing "TOPP_PercolatorAdapter_2"
PercolatorAdapter -test -osw_level ms1 -in_osw PercolatorAdapter_2.osw -out PercolatorAdapter_2_out1.osw -out_type osw -percolator_executable "${PERCOLATOR_BINARY}" > TOPP_PercolatorAdapter_2.stdout 2> TOPP_PercolatorAdapter_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_PercolatorAdapter_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_PercolatorAdapter_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_PercolatorAdapter_2.stdout)";fi
echo executing "TOPP_PercolatorAdapter_3"
PercolatorAdapter -test -osw_level ms2 -in_osw PercolatorAdapter_2_out1.osw -out PercolatorAdapter_3_out1.osw -out_type osw -percolator_executable "${PERCOLATOR_BINARY}" > TOPP_PercolatorAdapter_3.stdout 2> TOPP_PercolatorAdapter_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_PercolatorAdapter_3 failed'; >&2 echo -e "stderr:\n$(cat TOPP_PercolatorAdapter_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_PercolatorAdapter_3.stdout)";fi
echo executing "TOPP_PercolatorAdapter_4"
PercolatorAdapter -test -osw_level transition -in_osw PercolatorAdapter_3_out1.osw -out PercolatorAdapter_4_out1.osw -out_type osw -percolator_executable "${PERCOLATOR_BINARY}" > TOPP_PercolatorAdapter_4.stdout 2> TOPP_PercolatorAdapter_4.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_PercolatorAdapter_4 failed'; >&2 echo -e "stderr:\n$(cat TOPP_PercolatorAdapter_4.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_PercolatorAdapter_4.stdout)";fi
echo executing "TOPP_PercolatorAdapter_5"
PercolatorAdapter -test -ini PercolatorAdapter_1.ini -in PercolatorAdapter_1.idXML -out PercolatorAdapter_1_out1.tmp -out_type idXML -percolator_executable "${PERCOLATOR_BINARY}" -out_pin PercolatorAdapter_1_out1.tsv  > TOPP_PercolatorAdapter_5.stdout 2> TOPP_PercolatorAdapter_5.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_PercolatorAdapter_5 failed'; >&2 echo -e "stderr:\n$(cat TOPP_PercolatorAdapter_5.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_PercolatorAdapter_5.stdout)";fi
echo executing "TOPP_MascotAdapterOnline_1"
MascotAdapterOnline -test -ini MascotAdapterOnline_1.ini -Mascot_parameters:database SwissProt -in spectra_comet.mzML -out MascotAdapterOnline_1_out1.tmp > TOPP_MascotAdapterOnline_1.stdout 2> TOPP_MascotAdapterOnline_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_MascotAdapterOnline_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_MascotAdapterOnline_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_MascotAdapterOnline_1.stdout)";fi
echo executing "TOPP_MascotAdapterOnline_2"
MascotAdapterOnline -test -ini MascotAdapterOnline_1.ini -debug 666 -Mascot_parameters:decoy -Mascot_parameters:database SwissProt -in spectra_comet.mzML -out MascotAdapterOnline_2_out1.tmp > TOPP_MascotAdapterOnline_2.stdout 2> TOPP_MascotAdapterOnline_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_MascotAdapterOnline_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_MascotAdapterOnline_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_MascotAdapterOnline_2.stdout)";fi
echo executing "TOPP_FidoAdapter_1"
FidoAdapter -test -in FidoAdapter_1_input.idXML -out FidoAdapter_1_output.tmp -fidocp_executable "${FIDOCHOOSEPARAMS_BINARY}" > TOPP_FidoAdapter_1.stdout 2> TOPP_FidoAdapter_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FidoAdapter_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FidoAdapter_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FidoAdapter_1.stdout)";fi
echo executing "TOPP_FidoAdapter_2"
FidoAdapter -test -in FidoAdapter_1_input.idXML -out FidoAdapter_2_output.tmp -fidocp_executable "${FIDOCHOOSEPARAMS_BINARY}" -separate_runs > TOPP_FidoAdapter_2.stdout 2> TOPP_FidoAdapter_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FidoAdapter_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FidoAdapter_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FidoAdapter_2.stdout)";fi
echo executing "TOPP_FidoAdapter_3"
FidoAdapter -test -in FidoAdapter_1_input.idXML -out FidoAdapter_3_output.tmp -fidocp_executable "${FIDOCHOOSEPARAMS_BINARY}" -group_level -all_PSMs > TOPP_FidoAdapter_3.stdout 2> TOPP_FidoAdapter_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FidoAdapter_3 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FidoAdapter_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FidoAdapter_3.stdout)";fi
echo executing "TOPP_FidoAdapter_4"
FidoAdapter -test -in FidoAdapter_4_input.idXML -out FidoAdapter_4_output.tmp -fidocp_executable "${FIDOCHOOSEPARAMS_BINARY}" > TOPP_FidoAdapter_4.stdout 2> TOPP_FidoAdapter_4.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FidoAdapter_4 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FidoAdapter_4.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FidoAdapter_4.stdout)";fi
echo executing "TOPP_FidoAdapter_5"
FidoAdapter -test -greedy_group_resolution -in FidoAdapter_5_input.idXML -out FidoAdapter_5_output.tmp -fidocp_executable "${FIDOCHOOSEPARAMS_BINARY}" > TOPP_FidoAdapter_5.stdout 2> TOPP_FidoAdapter_5.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FidoAdapter_5 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FidoAdapter_5.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FidoAdapter_5.stdout)";fi
echo executing "TOPP_FidoAdapter_6"
FidoAdapter -test -in FidoAdapter_1_input.idXML -out FidoAdapter_6_output.tmp -fido_executable "${FIDO_BINARY}" -prob:protein 0.9 -prob:peptide 0.01 -prob:spurious 0.0 > TOPP_FidoAdapter_6.stdout 2> TOPP_FidoAdapter_6.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_FidoAdapter_6 failed'; >&2 echo -e "stderr:\n$(cat TOPP_FidoAdapter_6.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_FidoAdapter_6.stdout)";fi
echo executing "TOPP_MSFraggerAdapter_7"
MSFraggerAdapter -test -java_heapmemory 2600 -in spectra.mzML -executable "${MSFRAGGER_BINARY}" -database proteins.fasta -out MSFraggerAdapter_7_out_tmp.idXML -opt_out MSFraggerAdapter_7_opt_out_tmp.pepXML -varmod:enable_common -digest:num_enzyme_termini semi > TOPP_MSFraggerAdapter_7.stdout 2> TOPP_MSFraggerAdapter_7.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_MSFraggerAdapter_7 failed'; >&2 echo -e "stderr:\n$(cat TOPP_MSFraggerAdapter_7.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_MSFraggerAdapter_7.stdout)";fi
echo executing "TOPP_MSFraggerAdapter_8"
MSFraggerAdapter -test -java_heapmemory 2600 -in spectra_comet.mzML -executable "${MSFRAGGER_BINARY}" -database proteins.fasta -out MSFraggerAdapter_8_out_tmp.idXML -varmod:enable_common -digest:num_enzyme_termini semi > TOPP_MSFraggerAdapter_8.stdout 2> TOPP_MSFraggerAdapter_8.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_MSFraggerAdapter_8 failed'; >&2 echo -e "stderr:\n$(cat TOPP_MSFraggerAdapter_8.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_MSFraggerAdapter_8.stdout)";fi
echo executing "TOPP_THERMORAWFILEPARSER_1"
FileConverter -test -in ginkgotoxin-ms-switching.raw -ThermoRaw_executable "${THERMORAWFILEPARSER_BINARY}" -out ginkgotoxin-ms-switching_out_tmp.mzML > TOPP_THERMORAWFILEPARSER_1.stdout 2> TOPP_THERMORAWFILEPARSER_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_THERMORAWFILEPARSER_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_THERMORAWFILEPARSER_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_THERMORAWFILEPARSER_1.stdout)";fi
echo executing "TOPP_SiriusAdapter_1"
SiriusAdapter -test -sirius_executable "${SIRIUS_BINARY}" -in SiriusAdapter_1_input.mzML -out_sirius SiriusAdapter_1_output.tmp -sirius:profile qtof -sirius:db all -project:processors 1 > TOPP_SiriusAdapter_1.stdout 2> TOPP_SiriusAdapter_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_SiriusAdapter_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_SiriusAdapter_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_SiriusAdapter_1.stdout)";fi
echo executing "TOPP_SiriusAdapter_2"
SiriusAdapter -test -sirius_executable "${SIRIUS_BINARY}" -in SiriusAdapter_2_input.mzML -in_featureinfo SiriusAdapter_2_input.featureXML -out_sirius SiriusAdapter_2_output.tmp -preprocessing:feature_only -preprocessing:filter_by_num_masstraces 3 -sirius:profile qtof -sirius:db all -project:processors 1 > TOPP_SiriusAdapter_2.stdout 2> TOPP_SiriusAdapter_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_SiriusAdapter_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_SiriusAdapter_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_SiriusAdapter_2.stdout)";fi
echo executing "TOPP_SiriusAdapter_3"
SiriusAdapter -test -sirius_executable "${SIRIUS_BINARY}" -in SiriusAdapter_3_input.mzML -in_featureinfo SiriusAdapter_3_input.featureXML -out_sirius SiriusAdapter_3_output.tmp -preprocessing:filter_by_num_masstraces 3 -sirius:profile qtof -sirius:db all -project:processors 1 > TOPP_SiriusAdapter_3.stdout 2> TOPP_SiriusAdapter_3.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_SiriusAdapter_3 failed'; >&2 echo -e "stderr:\n$(cat TOPP_SiriusAdapter_3.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_SiriusAdapter_3.stdout)";fi
echo executing "TOPP_SiriusAdapter_5"
SiriusAdapter -test -sirius_executable "${SIRIUS_BINARY}" -in SiriusAdapter_3_input.mzML -in_featureinfo SiriusAdapter_3_input.featureXML -out_ms SiriusAdapter_5_output.tmp -converter_mode > TOPP_SiriusAdapter_5.stdout 2> TOPP_SiriusAdapter_5.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_SiriusAdapter_5 failed'; >&2 echo -e "stderr:\n$(cat TOPP_SiriusAdapter_5.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_SiriusAdapter_5.stdout)";fi
echo executing "TOPP_SiriusAdapter_6"
SiriusAdapter -test -sirius_executable "${SIRIUS_BINARY}" -in SiriusAdapter_4_input.mzML -in_featureinfo SiriusAdapter_4_input.featureXML -out_ms SiriusAdapter_6_output.tmp -converter_mode > TOPP_SiriusAdapter_6.stdout 2> TOPP_SiriusAdapter_6.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_SiriusAdapter_6 failed'; >&2 echo -e "stderr:\n$(cat TOPP_SiriusAdapter_6.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_SiriusAdapter_6.stdout)";fi
echo executing "TOPP_SiriusAdapter_8"
SiriusAdapter -test -sirius_executable "${SIRIUS_BINARY}" -in AssayGeneratorMetabo_decoy_generation_input.mzML  -in_featureinfo AssayGeneratorMetabo_decoy_generation_input_multids.featureXML -out_sirius SiriusAdapter_8_output.tmp -preprocessing:feature_only -sirius:profile qtof -sirius:db all -project:processors 1 > TOPP_SiriusAdapter_8.stdout 2> TOPP_SiriusAdapter_8.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_SiriusAdapter_8 failed'; >&2 echo -e "stderr:\n$(cat TOPP_SiriusAdapter_8.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_SiriusAdapter_8.stdout)";fi
echo executing "TOPP_SiriusAdapter_9"
SiriusAdapter -test -sirius_executable "${SIRIUS_BINARY}" -in AssayGeneratorMetabo_decoy_generation_input.mzML  -in_featureinfo AssayGeneratorMetabo_decoy_generation_input_multids.featureXML -out_sirius SiriusAdapter_9_output.tmp -sirius:profile qtof -sirius:db all -project:processors 1 > TOPP_SiriusAdapter_9.stdout 2> TOPP_SiriusAdapter_9.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_SiriusAdapter_9 failed'; >&2 echo -e "stderr:\n$(cat TOPP_SiriusAdapter_9.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_SiriusAdapter_9.stdout)";fi
echo executing "TOPP_SiriusAdapter_10"
SiriusAdapter -test -sirius_executable "${SIRIUS_BINARY}" -in AssayGeneratorMetabo_decoy_generation_input.mzML  -in_featureinfo -out_sirius SiriusAdapter_10_output.tmp -sirius:profile qtof -sirius:db all -project:processors 1 > TOPP_SiriusAdapter_10.stdout 2> TOPP_SiriusAdapter_10.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_SiriusAdapter_10 failed'; >&2 echo -e "stderr:\n$(cat TOPP_SiriusAdapter_10.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_SiriusAdapter_10.stdout)";fi
echo executing "TOPP_SiriusAdapter_7"
SiriusAdapter -test -sirius_executable "${SIRIUS_BINARY}" -in SiriusAdapter_4_input.mzML -in_featureinfo SiriusAdapter_4_input.featureXML -out_sirius SiriusAdapter_7_output.tmp -preprocessing:feature_only -sirius:profile qtof -sirius:db all -project:processors 1 > TOPP_SiriusAdapter_7.stdout 2> TOPP_SiriusAdapter_7.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_SiriusAdapter_7 failed'; >&2 echo -e "stderr:\n$(cat TOPP_SiriusAdapter_7.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_SiriusAdapter_7.stdout)";fi
echo executing "UTILS_AssayGeneratorMetabo_7"
AssayGeneratorMetabo -test -sirius_executable "${SIRIUS_BINARY}" -in AssayGeneratorMetabo_input.mzML -in_id AssayGeneratorMetabo_ams_input.featureXML -out AssayGeneratorMetabo_ams_sirius_output.tmp.tsv -fragment_annotation sirius -use_exact_mass -transition_threshold 3.0 -min_transitions 2 -max_transitions 3 -preprocessing:filter_by_num_masstraces 1 -preprocessing:precursor_mz_tolerance 10 -preprocessing:precursor_mz_tolerance_unit ppm -preprocessing:feature_only -sirius:profile qtof -sirius:compound_timeout 100 > UTILS_AssayGeneratorMetabo_7.stdout 2> UTILS_AssayGeneratorMetabo_7.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_AssayGeneratorMetabo_7 failed'; >&2 echo -e "stderr:\n$(cat UTILS_AssayGeneratorMetabo_7.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_AssayGeneratorMetabo_7.stdout)";fi
echo executing "UTILS_AssayGeneratorMetabo_8"
AssayGeneratorMetabo -test -sirius_executable "${SIRIUS_BINARY}" -in AssayGeneratorMetabo_input.mzML -in_id AssayGeneratorMetabo_ams_input.featureXML -out AssayGeneratorMetabo_ams_sirius_ukn_output.tmp.tsv -fragment_annotation sirius -use_exact_mass -transition_threshold 3.0 -min_transitions 2 -max_transitions 3 -preprocessing:filter_by_num_masstraces 1 -preprocessing:precursor_mz_tolerance 10 -preprocessing:precursor_mz_tolerance_unit ppm -preprocessing:feature_only -sirius:db ALL -sirius:profile qtof -sirius:compound_timeout 100 -use_known_unknowns > UTILS_AssayGeneratorMetabo_8.stdout 2> UTILS_AssayGeneratorMetabo_8.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_AssayGeneratorMetabo_8 failed'; >&2 echo -e "stderr:\n$(cat UTILS_AssayGeneratorMetabo_8.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_AssayGeneratorMetabo_8.stdout)";fi
echo executing "UTILS_AssayGeneratorMetabo_9"
AssayGeneratorMetabo -test -sirius_executable "${SIRIUS_BINARY}" -in AssayGeneratorMetabo_intsort_input.mzML -in_id AssayGeneratorMetabo_intsort_input.featureXML -out AssayGeneratorMetabo_ams_sirius_intsort_output.tmp.tsv -fragment_annotation sirius -use_exact_mass -transition_threshold 3.0 -min_transitions 2 -max_transitions 3 -preprocessing:filter_by_num_masstraces 1 -preprocessing:precursor_mz_tolerance 10 -preprocessing:precursor_mz_tolerance_unit ppm -preprocessing:feature_only -sirius:profile qtof -sirius:compound_timeout 100 > UTILS_AssayGeneratorMetabo_9.stdout 2> UTILS_AssayGeneratorMetabo_9.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_AssayGeneratorMetabo_9 failed'; >&2 echo -e "stderr:\n$(cat UTILS_AssayGeneratorMetabo_9.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_AssayGeneratorMetabo_9.stdout)";fi
echo executing "UTILS_AssayGeneratorMetabo_10"
AssayGeneratorMetabo -test -sirius_executable "${SIRIUS_BINARY}" -in AssayGeneratorMetabo_input.mzML -in_id AssayGeneratorMetabo_ams_input.featureXML -out AssayGeneratorMetabo_ams_sirius_restrict_output.tmp.tsv  -fragment_annotation sirius -use_exact_mass -transition_threshold 3.0 -min_transitions 2 -max_transitions 3 -min_fragment_mz 100 -max_fragment_mz 900 -preprocessing:filter_by_num_masstraces 1 -preprocessing:precursor_mz_tolerance 10 -preprocessing:precursor_mz_tolerance_unit ppm -preprocessing:feature_only -sirius:profile qtof -sirius:compound_timeout 100 > UTILS_AssayGeneratorMetabo_10.stdout 2> UTILS_AssayGeneratorMetabo_10.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_AssayGeneratorMetabo_10 failed'; >&2 echo -e "stderr:\n$(cat UTILS_AssayGeneratorMetabo_10.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_AssayGeneratorMetabo_10.stdout)";fi
echo executing "UTILS_AssayGeneratorMetabo_11"
AssayGeneratorMetabo -test -sirius_executable "${SIRIUS_BINARY}" -in AssayGeneratorMetabo_input.mzML -in_id AssayGeneratorMetabo_ams_input.featureXML -out AssayGeneratorMetabo_ams_sirius_restrict_decoy_output.tmp.tsv  -fragment_annotation sirius -decoy_generation -decoy_generation_method original -use_exact_mass -transition_threshold 3.0 -min_transitions 3 -max_transitions 3 -min_fragment_mz 100 -max_fragment_mz 900 -preprocessing:filter_by_num_masstraces 1 -preprocessing:precursor_mz_tolerance 10 -preprocessing:precursor_mz_tolerance_unit ppm -preprocessing:feature_only -sirius:profile qtof -sirius:compound_timeout 100 > UTILS_AssayGeneratorMetabo_11.stdout 2> UTILS_AssayGeneratorMetabo_11.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_AssayGeneratorMetabo_11 failed'; >&2 echo -e "stderr:\n$(cat UTILS_AssayGeneratorMetabo_11.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_AssayGeneratorMetabo_11.stdout)";fi
echo executing "UTILS_AssayGeneratorMetabo_12"
AssayGeneratorMetabo -test -sirius_executable "${SIRIUS_BINARY}" -in AssayGeneratorMetabo_decoy_generation_input.mzML -in_id AssayGeneratorMetabo_decoy_generation_input.featureXML -out AssayGeneratorMetabo_decoy_generation_output_original.tmp.tsv  -fragment_annotation sirius -decoy_generation -decoy_generation_method original -use_exact_mass -transition_threshold 3.0 -min_transitions 1 -max_transitions 3 -min_fragment_mz 100 -max_fragment_mz 900 -preprocessing:filter_by_num_masstraces 1 -preprocessing:precursor_mz_tolerance 10 -preprocessing:precursor_mz_tolerance_unit ppm -preprocessing:feature_only -sirius:profile qtof -sirius:compound_timeout 100 > UTILS_AssayGeneratorMetabo_12.stdout 2> UTILS_AssayGeneratorMetabo_12.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_AssayGeneratorMetabo_12 failed'; >&2 echo -e "stderr:\n$(cat UTILS_AssayGeneratorMetabo_12.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_AssayGeneratorMetabo_12.stdout)";fi
echo executing "UTILS_AssayGeneratorMetabo_13"
AssayGeneratorMetabo -test -sirius_executable "${SIRIUS_BINARY}" -in AssayGeneratorMetabo_decoy_generation_input.mzML -in_id AssayGeneratorMetabo_decoy_generation_input.featureXML -out AssayGeneratorMetabo_decoy_generation_output_resolve_overlap.tmp.tsv  -fragment_annotation sirius -decoy_generation -decoy_generation_method resolve_overlap -use_exact_mass -transition_threshold 3.0 -min_transitions 1 -max_transitions 3 -min_fragment_mz 100 -max_fragment_mz 900 -preprocessing:filter_by_num_masstraces 1 -preprocessing:precursor_mz_tolerance 10 -preprocessing:precursor_mz_tolerance_unit ppm -preprocessing:feature_only -sirius:profile qtof -sirius:compound_timeout 100 > UTILS_AssayGeneratorMetabo_13.stdout 2> UTILS_AssayGeneratorMetabo_13.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_AssayGeneratorMetabo_13 failed'; >&2 echo -e "stderr:\n$(cat UTILS_AssayGeneratorMetabo_13.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_AssayGeneratorMetabo_13.stdout)";fi
echo executing "UTILS_AssayGeneratorMetabo_14"
AssayGeneratorMetabo -test -sirius_executable "${SIRIUS_BINARY}" -in AssayGeneratorMetabo_decoy_generation_input.mzML -in_id AssayGeneratorMetabo_decoy_generation_input.featureXML -out AssayGeneratorMetabo_decoy_generation_output_add_shift.tmp.tsv  -fragment_annotation sirius -decoy_generation -decoy_generation_method add_shift -use_exact_mass -transition_threshold 3.0 -min_transitions 1 -max_transitions 3 -min_fragment_mz 100 -max_fragment_mz 900 -preprocessing:filter_by_num_masstraces 1 -preprocessing:precursor_mz_tolerance 10 -preprocessing:precursor_mz_tolerance_unit ppm -preprocessing:feature_only -sirius:profile qtof -sirius:compound_timeout 100 > UTILS_AssayGeneratorMetabo_14.stdout 2> UTILS_AssayGeneratorMetabo_14.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_AssayGeneratorMetabo_14 failed'; >&2 echo -e "stderr:\n$(cat UTILS_AssayGeneratorMetabo_14.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_AssayGeneratorMetabo_14.stdout)";fi
echo executing "UTILS_AssayGeneratorMetabo_15"
AssayGeneratorMetabo -test -sirius_executable "${SIRIUS_BINARY}" -in AssayGeneratorMetabo_decoy_generation_input.mzML -in_id AssayGeneratorMetabo_decoy_generation_input.featureXML -out AssayGeneratorMetabo_decoy_generation_output_both.tmp.tsv  -fragment_annotation sirius -decoy_generation -decoy_generation_method both -use_exact_mass -transition_threshold 3.0 -min_transitions 1 -max_transitions 3 -min_fragment_mz 100 -max_fragment_mz 900 -preprocessing:filter_by_num_masstraces 1 -preprocessing:precursor_mz_tolerance 10 -preprocessing:precursor_mz_tolerance_unit ppm -preprocessing:feature_only -sirius:profile qtof -sirius:compound_timeout 100 > UTILS_AssayGeneratorMetabo_15.stdout 2> UTILS_AssayGeneratorMetabo_15.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_AssayGeneratorMetabo_15 failed'; >&2 echo -e "stderr:\n$(cat UTILS_AssayGeneratorMetabo_15.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_AssayGeneratorMetabo_15.stdout)";fi
echo executing "UTILS_AssayGeneratorMetabo_16"
AssayGeneratorMetabo -test -sirius_executable "${SIRIUS_BINARY}" -in AssayGeneratorMetabo_decoy_generation_input.mzML -in_id AssayGeneratorMetabo_decoy_generation_input_multids.featureXML -out AssayGeneratorMetabo_decoy_generation_output_both_multids.tmp.tsv  -fragment_annotation sirius -decoy_generation -decoy_generation_method both -use_exact_mass -transition_threshold 3.0 -min_transitions 1 -max_transitions 3 -min_fragment_mz 100 -max_fragment_mz 900 -preprocessing:filter_by_num_masstraces 1 -preprocessing:precursor_mz_tolerance 10 -preprocessing:precursor_mz_tolerance_unit ppm -preprocessing:feature_only -sirius:profile qtof -sirius:compound_timeout 100 > UTILS_AssayGeneratorMetabo_16.stdout 2> UTILS_AssayGeneratorMetabo_16.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_AssayGeneratorMetabo_16 failed'; >&2 echo -e "stderr:\n$(cat UTILS_AssayGeneratorMetabo_16.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_AssayGeneratorMetabo_16.stdout)";fi
echo executing "UTILS_AssayGeneratorMetabo_17"
AssayGeneratorMetabo -test -sirius_executable "${SIRIUS_BINARY}" -in AssayGeneratorMetabo_decoy_generation_input.mzML AssayGeneratorMetabo_decoy_generation_input.mzML AssayGeneratorMetabo_decoy_generation_input.mzML -in_id AssayGeneratorMetabo_decoy_generation_input.featureXML AssayGeneratorMetabo_decoy_generation_input_1.featureXML AssayGeneratorMetabo_decoy_generation_input_2.featureXML -out AssayGeneratorMetabo_decoy_generation_linking_output_both.tmp.tsv  -fragment_annotation sirius -ambiguity_resolution_mz_tolerance 10.0 -ambiguity_resolution_mz_tolerance_unit Da -ambiguity_resolution_rt_tolerance 10.0 -total_occurrence_filter 0.8 -decoy_generation -decoy_generation_method both -use_exact_mass -transition_threshold 3.0 -min_transitions 1 -max_transitions 6 -preprocessing:filter_by_num_masstraces 1 -preprocessing:precursor_mz_tolerance 10 -preprocessing:precursor_mz_tolerance_unit ppm -preprocessing:feature_only -sirius:profile qtof -sirius:compound_timeout 100 > UTILS_AssayGeneratorMetabo_17.stdout 2> UTILS_AssayGeneratorMetabo_17.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_AssayGeneratorMetabo_17 failed'; >&2 echo -e "stderr:\n$(cat UTILS_AssayGeneratorMetabo_17.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_AssayGeneratorMetabo_17.stdout)";fi
echo executing "UTILS_AssayGeneratorMetabo_18"
AssayGeneratorMetabo -test -sirius_executable "${SIRIUS_BINARY}" -in AssayGeneratorMetabo_decoy_generation_input.mzML AssayGeneratorMetabo_decoy_generation_input.mzML AssayGeneratorMetabo_decoy_generation_input.mzML -in_id AssayGeneratorMetabo_decoy_generation_input.featureXML AssayGeneratorMetabo_decoy_generation_input_1.featureXML AssayGeneratorMetabo_decoy_generation_input_2.featureXML -out AssayGeneratorMetabo_decoy_generation_linking_moladd_output_both.tmp.tsv  -fragment_annotation sirius -ambiguity_resolution_mz_tolerance 10.0 -ambiguity_resolution_mz_tolerance_unit Da -ambiguity_resolution_rt_tolerance 10.0 -decoy_generation -decoy_generation_method both -use_exact_mass -transition_threshold 3.0 -min_transitions 1 -max_transitions 6 -preprocessing:filter_by_num_masstraces 1 -preprocessing:precursor_mz_tolerance 10 -preprocessing:precursor_mz_tolerance_unit ppm -preprocessing:feature_only -sirius:profile qtof -sirius:compound_timeout 100 > UTILS_AssayGeneratorMetabo_18.stdout 2> UTILS_AssayGeneratorMetabo_18.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'UTILS_AssayGeneratorMetabo_18 failed'; >&2 echo -e "stderr:\n$(cat UTILS_AssayGeneratorMetabo_18.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat UTILS_AssayGeneratorMetabo_18.stdout)";fi
echo executing "TOPP_SiriusAdapter_4"
SiriusAdapter -test -sirius_executable "${SIRIUS_BINARY}" -in SiriusAdapter_2_input.mzML -in_featureinfo SiriusAdapter_2_input.featureXML  -out_sirius SiriusAdapter_4_output.tmp -out_fingerid SiriusAdapter_4_foutput.tmp -sirius:profile qtof -sirius:db ALL -fingerid:db BIO > TOPP_SiriusAdapter_4.stdout 2> TOPP_SiriusAdapter_4.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_SiriusAdapter_4 failed'; >&2 echo -e "stderr:\n$(cat TOPP_SiriusAdapter_4.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_SiriusAdapter_4.stdout)";fi
echo executing "TOPP_NovorAdapter_1"
NovorAdapter -test -java_memory 512 -executable "${NOVOR_BINARY}" -in NovorAdapter_in.mzML -out NovorAdapter_1_out.tmp -variable_modifications "Acetyl (K)" -fixed_modifications "Carbamidomethyl (C)" -forbiddenResidues "I" > TOPP_NovorAdapter_1.stdout 2> TOPP_NovorAdapter_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_NovorAdapter_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_NovorAdapter_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_NovorAdapter_1.stdout)";fi
echo executing "TOPP_SpectrastSearchAdapter_0_prepare"
FileConverter -test -force_TPP_compatibility -in spectra_spectrast.mzXML -out SpectrastAdapter_1_hack.mzML > TOPP_SpectrastSearchAdapter_0_prepare.stdout 2> TOPP_SpectrastSearchAdapter_0_prepare.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_SpectrastSearchAdapter_0_prepare failed'; >&2 echo -e "stderr:\n$(cat TOPP_SpectrastSearchAdapter_0_prepare.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_SpectrastSearchAdapter_0_prepare.stdout)";fi
echo executing "TOPP_SpectrastSearchAdapter_1"
SpectraSTSearchAdapter -test -library_file testLib.splib -spectra_files SpectrastAdapter_1_hack.mzML -output_files SpectrastAdapter_1_out1.tmp.pepXML -executable "${SPECTRAST_BINARY}" > TOPP_SpectrastSearchAdapter_1.stdout 2> TOPP_SpectrastSearchAdapter_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_SpectrastSearchAdapter_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_SpectrastSearchAdapter_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_SpectrastSearchAdapter_1.stdout)";fi
echo executing "TOPP_SpectrastSearchAdapter_2"
SpectraSTSearchAdapter -test -library_file testLib.splib -spectra_files SpectrastAdapter_1_hack.mzML -output_files SpectrastAdapter_1_out1.tmp.pep.tsv -executable "${SPECTRAST_BINARY}" > TOPP_SpectrastSearchAdapter_2.stdout 2> TOPP_SpectrastSearchAdapter_2.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_SpectrastSearchAdapter_2 failed'; >&2 echo -e "stderr:\n$(cat TOPP_SpectrastSearchAdapter_2.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_SpectrastSearchAdapter_2.stdout)";fi
echo executing "TOPP_LuciphorAdapter_1"
LuciphorAdapter -test -in LuciphorAdapter_1_input.mzML  -java_memory 1024 -id LuciphorAdapter_1_input.idXML -out LuciphorAdapter_1_output.tmp  -executable "${LUCIPHOR_BINARY}" -min_num_psms_model 1 > TOPP_LuciphorAdapter_1.stdout 2> TOPP_LuciphorAdapter_1.stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TOPP_LuciphorAdapter_1 failed'; >&2 echo -e "stderr:\n$(cat TOPP_LuciphorAdapter_1.stderr | sed 's/^/    /')"; echo -e "stdout:\n$(cat TOPP_LuciphorAdapter_1.stdout)";fi
