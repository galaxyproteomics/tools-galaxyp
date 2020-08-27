MSSimulator -test -in DecoyDatabase_1.fasta -out MSsimulator.mzml -algorithm:RandomNumberGenerators:biological reproducible -algorithm:RandomNumberGenerators:technical reproducible > MSSimulator_1.stdout 2> stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'MSSimulator_1 failed'; >&2 echo -e "stderr:\n$(cat stderr | sed 's/^/    /')"; fi

MSSimulator -test -in DecoyDatabase_1.fasta -out MSsimulator_MALDI.mzml -algorithm:RandomNumberGenerators:biological reproducible -algorithm:RandomNumberGenerators:technical reproducible -algorithm:MSSim:Global:ionization_type MALDI > MSSimulator_2.stdout 2> stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'MSSimulator_2 failed'; >&2 echo -e "stderr:\n$(cat stderr | sed 's/^/    /')"; fi

ClusterMassTracesByPrecursor -test -in_ms1 ConsensusMapNormalizer_input.consensusXML -in_swath ConsensusMapNormalizer_input.consensusXML -out ClusterMassTracesByPrecursor.mzml > ClusterMassTracesByPrecursor.stdout 2> stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'ClusterMassTracesByPrecursor failed'; >&2 echo -e "stderr:\n$(cat stderr | sed 's/^/    /')"; fi

ClusterMassTraces -test -in ConsensusMapNormalizer_input.consensusXML -out ClusterMassTraces.mzml > ClusterMassTraces.stdout 2> stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'ClusterMassTraces failed'; >&2 echo -e "stderr:\n$(cat stderr | sed 's/^/    /')"; fi

CVInspector -test -cv_files CHEMISTRY/XLMOD.obo -cv_names XLMOD -mapping_file MAPPING/ms-mapping.xml -html CVInspector.html > CVInspector.stdout 2> stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'CVInspector failed'; >&2 echo -e "stderr:\n$(cat stderr | sed 's/^/    /')"; fi

DeMeanderize -test -in MSsimulator_MALDI.mzml -out DeMeanderize.mzml > DeMeanderize.stdout 2> stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'DeMeanderize failed'; >&2 echo -e "stderr:\n$(cat stderr | sed 's/^/    /')"; fi

# TODO DigestorMotif

Digestor -test -in random.fa -out Digestor.fasta -out_type fasta > Digestor.stdout 2> stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'Digestor failed'; >&2 echo -e "stderr:\n$(cat stderr | sed 's/^/    /')"; fi

EICExtractor -test -in spectra.mzML -pos FileConverter_10_input.edta -out EICExtractor.csv > EICExtractor.stdout 2> stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'EICExtractor failed'; >&2 echo -e "stderr:\n$(cat stderr | sed 's/^/    /')"; fi

#TODO ERPairFinder

FeatureFinderIsotopeWavelet -test -in FeatureFinderCentroided_1_input.mzML -out  FeatureFinderIsotopeWavelet.featureXML > FeatureFinderIsotopeWavelet.stdout 2> stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'FeatureFinderIsotopeWavelet failed'; >&2 echo -e "stderr:\n$(cat stderr | sed 's/^/    /')"; fi


FFEval -test -in  FeatureFinderCentroided_1_output.featureXML -truth  FeatureFinderCentroided_1_output.featureXML -out  FFEval.featureXML -out_roc FFEval_roc.csv  > FFEval.stdout 2> stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'FFEval failed'; >&2 echo -e "stderr:\n$(cat stderr | sed 's/^/    /')"; fi

# TODO? deprecated IDDecoyProbability

IDExtractor -test -in MSGFPlusAdapter_1_out.idXML -best_hits -number_of_peptides  1 -out  IDExtractor.idXML   > IDExtractor.stdout 2> stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'IDExtractor failed'; >&2 echo -e "stderr:\n$(cat stderr | sed 's/^/    /')"; fi

LabeledEval -test -in  FeatureLinkerLabeled_1_input.featureXML -truth  FeatureLinkerLabeled_1_output.consensusXML> LabeledEval.txt > LabeledEval.stdout 2> stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'LabeledEval failed'; >&2 echo -e "stderr:\n$(cat stderr | sed 's/^/    /')"; fi

MapStatistics -test -in SiriusAdapter_3_input.featureXML -out MapStatistics.txt > MapStatistics_1.stdout 2> stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'MapStatistics_1 failed'; >&2 echo -e "stderr:\n$(cat stderr | sed 's/^/    /')"; fi

MapStatistics -test -in ConsensusXMLFile_1.consensusXML -out MapStatistics2.txt > MapStatistics_2.stdout 2> stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'MapStatistics_2 failed'; >&2 echo -e "stderr:\n$(cat stderr | sed 's/^/    /')"; fi

MetaboliteAdductDecharger -test -in Decharger_input.featureXML -out_cm MetaboliteAdductDecharger_cm.consensusXML -out_fm MetaboliteAdductDecharger_fm.featureXML -outpairs MetaboliteAdductDecharger_pairs.consensusXML > MetaboliteAdductDecharger.stdout 2> stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'MetaboliteAdductDecharger failed'; >&2 echo -e "stderr:\n$(cat stderr | sed 's/^/    /')"; fi

MetaboliteSpectralMatcher -test -in spectra.mzML -database MetaboliteSpectralDB.mzML -out MetaboliteSpectralMatcher.mzTab > MetaboliteSpectralMatcher.stdout 2> stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'MetaboliteSpectralMatcher failed'; >&2 echo -e "stderr:\n$(cat stderr | sed 's/^/    /')"; fi

# TODO MRMPairFinder

# TODO OpenSwathDIAPreScoring

OpenSwathRewriteToFeatureXML -featureXML OpenSwathFeatureXMLToTSV_input.featureXML -out OpenSwathRewriteToFeatureXML.featureXML > OpenSwathRewriteToFeatureXML.stdout 2> stderr
# if [[ "$?" -ne "0" ]]; then >&2 echo 'OpenSwathRewriteToFeatureXML failed'; >&2 echo -e "stderr:\n$(cat stderr | sed 's/^/    /')"; fi

# adapted from the commented tests in OpenMS TODO may be removed later https://github.com/OpenMS/OpenMS/issues/4719
FileConverter -in PepNovo.mzXML -out PepNovo_1.mzML > /dev/null 2> stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'FileConverter failed'; >&2 echo -e "stderr:\n$(cat stderr | sed 's/^/    /')"; fi

PepNovoAdapter -ini PepNovoAdapter_1_parameters.ini -in PepNovo_1.mzML -out PepNovoAdapter_3_output.idXML -model_directory pepnovo_models/ -pepnovo_executable pepnovo > PepNovo_1.stdout 2> stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'PhosphoScoring failed'; >&2 echo -e "stderr:\n$(cat stderr | sed 's/^/    /')"; fi

FileConverter -in PepNovo.mzData -out PepNovo_4.mzML > /dev/null 2> stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'FileConverter failed'; >&2 echo -e "stderr:\n$(cat stderr | sed 's/^/    /')"; fi
PepNovoAdapter -ini PepNovoAdapter_1_parameters.ini -in PepNovo_4.mzML -out PepNovoAdapter_4_output.idXML -model_directory pepnovo_models/ -pepnovo_executable pepnovo > PepNovo_1.stdout 2> stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'PhosphoScoring failed'; >&2 echo -e "stderr:\n$(cat stderr | sed 's/^/    /')"; fi

#PepNovoAdapter -ini PepNovoAdapter_5_parameters.ini -in PepNovoAdapter_5_output.pepnovo_out -out PepNovoAdapter_5_output.idXML -model_directory pepnovo_models/ 

# TODO PhosphoScoring 
PhosphoScoring -in spectra.mzML -id MSGFPlusAdapter_1_out1.tmp -out PhosphoScoring.idxml > PhosphoScoring.stdout 2> stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'PhosphoScoring failed'; >&2 echo -e "stderr:\n$(cat stderr | sed 's/^/    /')"; fi

PSMFeatureExtractor -test -in MSGFPlusAdapter_1_out.idXML XTandemAdapter_1_out.idXML -multiple_search_engines -skip_db_check -out PSMFeatureExtractor.idxml > PSMFeatureExtractor_1.stdout 2> stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'PSMFeatureExtractor_1 failed'; >&2 echo -e "stderr:\n$(cat stderr | sed 's/^/    /')"; fi
PSMFeatureExtractor -test -in MSGFPlusAdapter_1_out.idXML XTandemAdapter_1_out.idXML -multiple_search_engines -skip_db_check -out PSMFeatureExtractor.mzid > PSMFeatureExtractor_2.stdout 2> stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'PSMFeatureExtractor_2 failed'; >&2 echo -e "stderr:\n$(cat stderr | sed 's/^/    /')"; fi

QCCalculator -test -in OpenPepXL_input.mzML -out QCCalculator1.qcML > QCCalculator_1.stdout 2> stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'QCCalculator_1 failed'; >&2 echo -e "stderr:\n$(cat stderr | sed 's/^/    /')"; fi
QCCalculator -test -in OpenPepXL_input.mzML -id OpenPepXL_output.idXML -consensus OpenPepXL_input.consensusXML -out QCCalculator2.qcML > QCCalculator_2.stdout 2> stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'QCCalculator_2 failed'; >&2 echo -e "stderr:\n$(cat stderr | sed 's/^/    /')"; fi
QCCalculator -test -in IDMapper_4_input.mzML -id IDMapper_4_input.idXML -feature IDMapper_4_input.featureXML -out QCCalculator3.qcML > QCCalculator_3.stdout 2> stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'QCCalculator_3 failed'; >&2 echo -e "stderr:\n$(cat stderr | sed 's/^/    /')"; fi

# TODO QCEmbedder
# TODO QCExporter
# TODO QCExtractor
# TODO QCImporter

QCMerger -test -in QCCalculator1.qcML QCCalculator3.qcML -out QCMerger.qcML > QCMerger.stdout 2> stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'QCMerger failed'; >&2 echo -e "stderr:\n$(cat stderr | sed 's/^/    /')"; fi

QCShrinker -test -in QCCalculator1.qcML -out QCShrinker.qcML > QCShrinker.stdout 2> stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'QCShrinker failed'; >&2 echo -e "stderr:\n$(cat stderr | sed 's/^/    /')"; fi

RNADigestor -test -in random_RNA.fa -out RNADigestor.fasta > RNADigestor.stdout 2> stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'RNADigestor failed'; >&2 echo -e "stderr:\n$(cat stderr | sed 's/^/    /')"; fi

RNPxlXICFilter -test -control FileFilter_1_input.mzML -treatment FileFilter_1_input.mzML -out RNPxlXICFilter.mzML > RNPxlXICFilter.stdout 2> stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'RNPxlXICFilter failed'; >&2 echo -e "stderr:\n$(cat stderr | sed 's/^/    /')"; fi

# TODO out should be tsv, but needs https://github.com/OpenMS/OpenMS/pull/4533
RTEvaluation -in PeptideIndexer_1.idXML -out RTEvaluation.csv > RTEvaluation.stdout 2> stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'RTEvaluation failed'; >&2 echo -e "stderr:\n$(cat stderr | sed 's/^/    /')"; fi
ln -fs RTEvaluation.csv RTEvaluation.tsv > .stdout 2> stderr

SemanticValidator -test -in FileFilter_1_input.mzML -mapping_file MAPPING/ms-mapping.xml > SemanticValidator.stdout 2> stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'SemanticValidator failed'; >&2 echo -e "stderr:\n$(cat stderr | sed 's/^/    /')"; fi

IDFilter -in PeptideIndexer_1.idXML -best:strict -out SequenceCoverageCalculator_1.idXML > IDFilter.stdout 2> stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'IDFilter failed'; >&2 echo -e "stderr:\n$(cat stderr | sed 's/^/    /')"; fi
SequenceCoverageCalculator -test -in_database  PeptideIndexer_1.fasta -in_peptides  SequenceCoverageCalculator_1.idXML  -out  SequenceCoverageCalculator.txt > SequenceCoverageCalculator.stdout 2> stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'SequenceCoverageCalculator failed'; >&2 echo -e "stderr:\n$(cat stderr | sed 's/^/    /')"; fi

# TODO SpecLibCreator

SpectraFilterBernNorm -test -in  SpectraFilterSqrtMower_1_input.mzML -out  SpectraFilterBernNorm.mzML > SpectraFilterBernNorm.stdout 2> stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'SpectraFilterBernNorm failed'; >&2 echo -e "stderr:\n$(cat stderr | sed 's/^/    /')"; fi

SpectraFilterMarkerMower -test -in  SpectraFilterSqrtMower_1_input.mzML -out  SpectraFilterMarkerMower.mzML > SpectraFilterMarkerMower.stdout 2> stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'SpectraFilterMarkerMower failed'; >&2 echo -e "stderr:\n$(cat stderr | sed 's/^/    /')"; fi

SpectraFilterNLargest -test -in  SpectraFilterSqrtMower_1_input.mzML -out  SpectraFilterNLargest.mzML > SpectraFilterNLargest.stdout 2> stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'SpectraFilterNLargest failed'; >&2 echo -e "stderr:\n$(cat stderr | sed 's/^/    /')"; fi

SpectraFilterNormalizer -test -in  SpectraFilterSqrtMower_1_input.mzML -out  SpectraFilterNormalizer.mzML > SpectraFilterNormalizer.stdout 2> stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'SpectraFilterNormalizer failed'; >&2 echo -e "stderr:\n$(cat stderr | sed 's/^/    /')"; fi

SpectraFilterParentPeakMower -test -in  SpectraFilterSqrtMower_1_input.mzML -out  SpectraFilterParentPeakMower.mzML > SpectraFilterParentPeakMower.stdout 2> stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'SpectraFilterParentPeakMower failed'; >&2 echo -e "stderr:\n$(cat stderr | sed 's/^/    /')"; fi

SpectraFilterScaler -test -in  SpectraFilterSqrtMower_1_input.mzML -out  SpectraFilterScaler.mzML > SpectraFilterScaler.stdout 2> stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'SpectraFilterScaler failed'; >&2 echo -e "stderr:\n$(cat stderr | sed 's/^/    /')"; fi

SpectraFilterThresholdMower -test -in  SpectraFilterSqrtMower_1_input.mzML -out  SpectraFilterThresholdMower.mzML > SpectraFilterThresholdMower.stdout 2> stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'SpectraFilterThresholdMower failed'; >&2 echo -e "stderr:\n$(cat stderr | sed 's/^/    /')"; fi

SpectraMerger -test -in NovorAdapter_in.mzML -out SpectraMerger_1.mzML > SpectraMerger.stdout 2> stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'SpectraMerger failed'; >&2 echo -e "stderr:\n$(cat stderr | sed 's/^/    /')"; fi

# TODO SvmTheoreticalSpectrumGeneratorTrainer

TransformationEvaluation -test -in FileInfo_16_input.trafoXML -out TransformationEvaluation.trafoXML > TransformationEvaluation.stdout 2> stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'TransformationEvaluation failed'; >&2 echo -e "stderr:\n$(cat stderr | sed 's/^/    /')"; fi

XMLValidator -test -in FileFilter_1_input.mzML > XMLValidator.stdout 2> stderr
if [[ "$?" -ne "0" ]]; then >&2 echo 'XMLValidator failed'; >&2 echo -e "stderr:\n$(cat stderr | sed 's/^/    /')"; fi
