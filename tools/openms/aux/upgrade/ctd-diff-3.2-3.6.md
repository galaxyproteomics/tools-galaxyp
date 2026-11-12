# CTD diff: 3.2.0-pre-exported-20241011 -> 3.6.0

## Tool set

- removed: `IDMassAccuracy`, `MascotAdapter`, `OpenPepXLLF`, `SpecLibCreator`, `SpecLibSearcher`, `TriqlerConverter`, `XTandemAdapter`
- added: `DIAuditor`, `FeatureFinderLFQ`, `INIUpdater`, `IsobaricWorkflow`, `MS1LabeledWorkflow`, `OpenNuXL`, `OpenSwathExport`, `OpenSwathInfer`, `OpenSwathPeakMapExtractor`, `OpenSwathPercolatorScoring`, `ParquetConverter`, `ParquetDiff`, `PeakPickerIM`, `ProSE`, `Resampler`, `TransitionListEvidenceFilter`, `UniPEFF`

## Summary

| tool | + | - | ~ | rename | flags |
|---|---|---|---|---|---|
| `CometAdapter` | 0 | 0 | 5 | 0 | autotest, filetypes.txt |
| `DatabaseFilter` | 0 | 0 | 1 | 0 | filetypes.txt |
| `DatabaseSuitability` | 0 | 0 | 2 | 0 | filetypes.txt |
| `DecoyDatabase` | 1 | 0 | 2 | 0 | autotest, filetypes.txt |
| `Digestor` | 1 | 0 | 2 | 0 | autotest, filetypes.txt |
| `DigestorMotif` | 0 | 0 | 2 | 0 | autotest, filetypes.txt |
| `EICExtractor` | 0 | 0 | 1 | 0 | autotest |
| `FLASHDeconv` | 31 | 18 | 2 | 10 | behaviour, filetypes.txt, ini, wrapper |
| `FalseDiscoveryRate` | 6 | 0 | 0 | 0 | - |
| `FeatureFinderCentroided` | 1 | 0 | 0 | 1 | ini |
| `FeatureFinderIdentification` | 0 | 9 | 5 | 3 | behaviour, filetypes.txt, ini, wrapper |
| `FeatureFinderMetabo` | 6 | 0 | 0 | 0 | - |
| `FeatureFinderMetaboIdent` | 2 | 0 | 1 | 0 | behaviour, wrapper |
| `FeatureFinderMultiplex` | 1 | 0 | 0 | 1 | ini |
| `FeatureLinkerLabeled` | 0 | 0 | 2 | 0 | filetypes.txt |
| `FeatureLinkerUnlabeled` | 0 | 1 | 1 | 0 | filetypes.txt, ini |
| `FeatureLinkerUnlabeledKD` | 7 | 1 | 1 | 0 | filetypes.txt, ini |
| `FeatureLinkerUnlabeledQT` | 0 | 1 | 1 | 0 | filetypes.txt, ini |
| `FileConverter` | 5 | 0 | 3 | 0 | autotest, filetypes.txt |
| `FileFilter` | 3 | 0 | 0 | 0 | - |
| `FileInfo` | 0 | 0 | 1 | 0 | filetypes.txt |
| `FuzzyDiff` | 1 | 0 | 0 | 0 | - |
| `IDConflictResolver` | 1 | 0 | 2 | 0 | filetypes.txt |
| `IDFileConverter` | 2 | 0 | 4 | 0 | autotest, filetypes.txt, hardcoded_params.json |
| `IDFilter` | 3 | 0 | 12 | 0 | autotest, behaviour, filetypes.txt |
| `IDMerger` | 0 | 0 | 2 | 0 | autotest, filetypes.txt |
| `IDRipper` | 0 | 0 | 1 | 0 | filetypes.txt |
| `IDScoreSwitcher` | 0 | 0 | 2 | 0 | filetypes.txt |
| `IDSplitter` | 0 | 0 | 2 | 0 | filetypes.txt |
| `IsobaricAnalyzer` | 69 | 0 | 1 | 0 | autotest |
| `MRMTransitionGroupPicker` | 1 | 0 | 0 | 0 | - |
| `MSFraggerAdapter` | 0 | 0 | 3 | 0 | autotest, filetypes.txt |
| `MSGFPlusAdapter` | 1 | 0 | 3 | 0 | autotest, filetypes.txt |
| `MSstatsConverter` | 1 | 0 | 0 | 0 | - |
| `MapAlignerIdentification` | 9 | 0 | 1 | 0 | filetypes.txt |
| `MapAlignerTreeGuided` | 9 | 0 | 0 | 0 | - |
| `MapRTTransformer` | 7 | 0 | 2 | 0 | filetypes.txt |
| `MassTraceExtractor` | 1 | 0 | 0 | 0 | - |
| `MetaProSIP` | 0 | 0 | 2 | 0 | autotest, filetypes.txt |
| `MetaboliteAdductDecharger` | 3 | 0 | 0 | 0 | - |
| `MetaboliteSpectralMatcher` | 1 | 0 | 0 | 0 | - |
| `MultiplexResolver` | 0 | 0 | 2 | 1 | behaviour, ini, wrapper |
| `MzTabExporter` | 0 | 0 | 1 | 0 | filetypes.txt |
| `NoiseFilterGaussian` | 0 | 0 | 2 | 0 | autotest |
| `NucleicAcidSearchEngine` | 0 | 0 | 2 | 0 | autotest, filetypes.txt |
| `OpenPepXL` | 0 | 0 | 3 | 0 | autotest, filetypes.txt |
| `OpenSwathAnalyzer` | 11 | 1 | 0 | 0 | ini |
| `OpenSwathAssayGenerator` | 2 | 0 | 3 | 0 | autotest, filetypes.txt |
| `OpenSwathDecoyGenerator` | 0 | 0 | 3 | 0 | autotest, filetypes.txt |
| `OpenSwathRTNormalizer` | 11 | 1 | 0 | 0 | ini |
| `OpenSwathWorkflow` | 117 | 16 | 6 | 12 | autotest, behaviour, filetypes.txt, ini, wrapper |
| `PSMFeatureExtractor` | 1 | 5 | 2 | 0 | autotest, filetypes.txt, ini |
| `PeakPickerHiRes` | 1 | 0 | 0 | 0 | - |
| `PeptideIndexer` | 0 | 0 | 4 | 0 | autotest, filetypes.txt |
| `PercolatorAdapter` | 3 | 0 | 4 | 0 | autotest, filetypes.txt, wrapper |
| `ProteinInference` | 1 | 0 | 0 | 0 | - |
| `ProteinQuantifier` | 3 | 2 | 0 | 1 | ini |
| `ProteomicsLFQ` | 55 | 9 | 4 | 4 | autotest, behaviour, filetypes.txt, ini, wrapper |
| `QualityControl` | 3 | 2 | 2 | 0 | filetypes.txt, ini |
| `RNADigestor` | 0 | 0 | 2 | 0 | autotest, filetypes.txt |
| `SageAdapter` | 7 | 0 | 4 | 0 | autotest, filetypes.txt |
| `SequenceCoverageCalculator` | 0 | 0 | 2 | 0 | filetypes.txt, hardcoded_params.json |
| `SimpleSearchEngine` | 2 | 0 | 2 | 0 | autotest, filetypes.txt |
| `SpectraSTSearchAdapter` | 0 | 0 | 1 | 0 | filetypes.txt |
| `TargetedFileConverter` | 0 | 0 | 3 | 0 | autotest, filetypes.txt |
| `TextExporter` | 4 | 0 | 1 | 0 | filetypes.txt |
| `XMLValidator` | 0 | 0 | 1 | 0 | filetypes.txt |

(142 parameter change(s) ignored: they are blacklisted in `aux/hardcoded_params.json` and never reach the wrapper.)

## Action list

### `aux/filetypes.txt` — Galaxy has no extension for these formats

- `cachedMzML`: FileConverter
- `consensusparquet`: FeatureLinkerLabeled, FeatureLinkerUnlabeled, FeatureLinkerUnlabeledKD, FeatureLinkerUnlabeledQT, FileConverter, IDConflictResolver, IDFilter, MapAlignerIdentification, MapRTTransformer, MzTabExporter, TextExporter
- `faa`: CometAdapter, DatabaseFilter, DatabaseSuitability, DecoyDatabase, Digestor, DigestorMotif, FileInfo, IDFileConverter, IDFilter, MSFraggerAdapter, MSGFPlusAdapter, MetaProSIP, NucleicAcidSearchEngine, OpenPepXL, PeptideIndexer, PercolatorAdapter, ProteomicsLFQ, QualityControl, RNADigestor, SageAdapter, SequenceCoverageCalculator, SimpleSearchEngine, SpectraSTSearchAdapter
- `feature`: FLASHDeconv
- `featureparquet`: FeatureFinderIdentification, FeatureLinkerLabeled, FileConverter, IDConflictResolver, MapAlignerIdentification, MapRTTransformer, MzTabExporter, TextExporter
- `fid`: FileConverter, FileInfo
- `idparquet`: CometAdapter, FeatureFinderIdentification, IDFileConverter, IDFilter, IDMerger, IDRipper, IDScoreSwitcher, MSGFPlusAdapter, MapAlignerIdentification, MapRTTransformer, MzTabExporter, PSMFeatureExtractor, PeptideIndexer, PercolatorAdapter, SageAdapter, TextExporter
- `ini`: XMLValidator
- `msalign`: FLASHDeconv
- `oswpq`: OpenSwathAssayGenerator, OpenSwathDecoyGenerator, OpenSwathWorkflow, TargetedFileConverter
- `prot.xml`: IDFileConverter
- `traml`: FileConverter
- `xic`: FileConverter, OpenSwathWorkflow, TextExporter

### `aux/hardcoded_params.json` — entries whose parameter vanished

- `algorithm:Preprocessing:tmp_dir` (all tools)
- `algorithm:tryptic_only` (CompNovo (no such tool any more))
- `algorithm:tryptic_only` (CompNovoCID (no such tool any more))
- `comet_version` (all tools)
- `crux_executable` (all tools)
- `fido_executable` (all tools)
- `fidocp_executable` (all tools)
- `in` (OpenSwathWorkflow)
- `mascot_directory` (all tools)
- `myrimatch_executable` (all tools)
- `out_workspace_directory` (all tools)
- `output_files` (SpectraSTSearchAdapter)
- `separator` (IDMassAccuracy (no such tool any more))
- `sirius:cores` (all tools)
- `sirius_executable` (all tools)
- `temp_data_directory` (all tools)
- `xml_out` (XTandemAdapter (no such tool any more))
- `xtandem_executable` (all tools)

### renamed parameters — check `.ini` fixtures, `test-data.sh` seds and hardcoded entries

- `FLASHDeconv`: `FLASHDeconv:1:Algorithm:max_charge` -> `FLASHDeconv:1:SD:min_charge`
- `FLASHDeconv`: `FLASHDeconv:1:Algorithm:min_charge` -> `FLASHDeconv:1:SD:max_charge`
- `FLASHDeconv`: `FLASHDeconv:1:Algorithm:min_mass` -> `FLASHDeconv:1:ft:min_cos`
- `FLASHDeconv`: `FLASHDeconv:1:FeatureTracing:max_trace_length` -> `FLASHDeconv:1:ft:min_trace_length`
- `FLASHDeconv`: `FLASHDeconv:1:FeatureTracing:min_trace_length` -> `FLASHDeconv:1:ft:max_trace_length`
- `FLASHDeconv`: `FLASHDeconv:1:in_log` -> `FLASHDeconv:1:FD:ida_log`
- `FLASHDeconv`: `FLASHDeconv:1:max_MS_level` -> `FLASHDeconv:1:max_ms_level`
- `FLASHDeconv`: `FLASHDeconv:1:out_promex` -> `FLASHDeconv:1:out_spec4`
- `FLASHDeconv`: `FLASHDeconv:1:target_precursor_charge` -> `FLASHDeconv:1:SD:precursor_charge`
- `FLASHDeconv`: `FLASHDeconv:1:target_precursor_mz` -> `FLASHDeconv:1:SD:precursor_mz`
- `FeatureFinderCentroided`: `FeatureFinderCentroided:1:algorithm:debug` -> `FeatureFinderCentroided:1:algorithm:write_debug`
- `FeatureFinderIdentification`: `FeatureFinderIdentification:1:extract:rt_quantile` -> `FeatureFinderIdentification:1:extract:IM_window`
- `FeatureFinderIdentification`: `FeatureFinderIdentification:1:svm:epsilon` -> `FeatureFinderIdentification:1:seed_apex_rt_tolerance`
- `FeatureFinderIdentification`: `FeatureFinderIdentification:1:svm:kernel` -> `FeatureFinderIdentification:1:faims:merge_features`
- `FeatureFinderMultiplex`: `FeatureFinderMultiplex:1:algorithm:missed_cleavages` -> `FeatureFinderMultiplex:1:algorithm:max_nr_labelled_aas`
- `MultiplexResolver`: `MultiplexResolver:1:algorithm:missed_cleavages` -> `MultiplexResolver:1:algorithm:max_nr_labelled_aas`
- `OpenSwathWorkflow`: `OpenSwathWorkflow:1:Calibration:debug_im_file` -> `OpenSwathWorkflow:1:Calibration:MassIMCorrection:debug_mz_file`
- `OpenSwathWorkflow`: `OpenSwathWorkflow:1:Calibration:debug_mz_file` -> `OpenSwathWorkflow:1:Calibration:MassIMCorrection:debug_im_file`
- `OpenSwathWorkflow`: `OpenSwathWorkflow:1:Calibration:im_correction_function` -> `OpenSwathWorkflow:1:Calibration:MassIMCorrection:mz_correction_function`
- `OpenSwathWorkflow`: `OpenSwathWorkflow:1:RTNormalization:InitialQualityCutoff` -> `OpenSwathWorkflow:1:Calibration:RTNormalization:OverallQualityCutoff`
- `OpenSwathWorkflow`: `OpenSwathWorkflow:1:RTNormalization:MinBinsFilled` -> `OpenSwathWorkflow:1:Calibration:RTNormalization:NrRTBins`
- `OpenSwathWorkflow`: `OpenSwathWorkflow:1:RTNormalization:NrRTBins` -> `OpenSwathWorkflow:1:Calibration:RTNormalization:MinBinsFilled`
- `OpenSwathWorkflow`: `OpenSwathWorkflow:1:RTNormalization:OverallQualityCutoff` -> `OpenSwathWorkflow:1:Calibration:RTNormalization:InitialQualityCutoff`
- `OpenSwathWorkflow`: `OpenSwathWorkflow:1:RTNormalization:RANSACMaxIterations` -> `OpenSwathWorkflow:1:Calibration:RTNormalization:RANSACMaxPercentRTThreshold`
- `OpenSwathWorkflow`: `OpenSwathWorkflow:1:RTNormalization:RANSACMaxPercentRTThreshold` -> `OpenSwathWorkflow:1:Calibration:RTNormalization:RANSACMaxIterations`
- `OpenSwathWorkflow`: `OpenSwathWorkflow:1:RTNormalization:lowess:span` -> `OpenSwathWorkflow:1:Calibration:RTNormalization:lowess:auto_span_min`
- `OpenSwathWorkflow`: `OpenSwathWorkflow:1:RTNormalization:outlierMethod` -> `OpenSwathWorkflow:1:Calibration:RTNormalization:alignmentMethod`
- `OpenSwathWorkflow`: `OpenSwathWorkflow:1:out_osw` -> `OpenSwathWorkflow:1:out_mobilogram`
- `ProteinQuantifier`: `ProteinQuantifier:1:best_charge_and_fraction` -> `ProteinQuantifier:1:best_charge`
- `ProteomicsLFQ`: `ProteomicsLFQ:1:PeptideQuantification:extract:rt_quantile` -> `ProteomicsLFQ:1:PeptideQuantification:extract:IM_window`
- `ProteomicsLFQ`: `ProteomicsLFQ:1:PeptideQuantification:svm:epsilon` -> `ProteomicsLFQ:1:PeptideQuantification:seed_apex_rt_tolerance`
- `ProteomicsLFQ`: `ProteomicsLFQ:1:PeptideQuantification:svm:kernel` -> `ProteomicsLFQ:1:PeptideQuantification:faims:merge_features`
- `ProteomicsLFQ`: `ProteomicsLFQ:1:ProteinQuantification:best_charge_and_fraction` -> `ProteomicsLFQ:1:ProteinQuantification:best_charge`

### type/required/advanced changed — the generator handles it, verify the wrapper diff

- `FLASHDeconv`: FLASHDeconv:1:mzml_mass_charge (advanced); FLASHDeconv:1:write_detail (type)
- `FeatureFinderIdentification`: FeatureFinderIdentification:1:EMGScoring:init_mom (type)
- `FeatureFinderMetaboIdent`: FeatureFinderMetaboIdent:1:EMGScoring:init_mom (type)
- `MultiplexResolver`: MultiplexResolver:1:algorithm:mz_tolerance (type); MultiplexResolver:1:algorithm:rt_tolerance (type)
- `OpenSwathWorkflow`: OpenSwathWorkflow:1:Scoring:Scores:use_ion_mobility_scores (advanced, type)
- `PercolatorAdapter`: PercolatorAdapter:1:percolator_executable (required)
- `ProteomicsLFQ`: ProteomicsLFQ:1:PeptideQuantification:EMGScoring:init_mom (type); ProteomicsLFQ:1:out (required)

## Per tool

### `CometAdapter`

- **~** `CometAdapter:1:PeptideIndexing:enzyme:name`  restrictions: `auto,Alpha-lytic protease,2-iodobenzoate,iodosobenzoate,staphylococcal protease/D,proline-endopeptidase/HKR,Glu-C+P,PepsinA + P,cyanogen-bromide,Clostripain/P,elastase-trypsin-chymotrypsin,no cleavage,unspecific cleavage,Asp-N,Asp-N/B,Asp-N_ambic,Trypsin,Arg-C,Arg-C/P,V8-DE,V8-E,leukocyte elastase,proline endopeptidase,glutamyl endopeptidase,Lys-C,Lys-N,Chymotrypsin,Chymotrypsin/P,CNBr,Formic_acid,Lys-C/P,PepsinA,TrypChymo,Trypsin/P` -> `auto,leukocyte elastase,proline endopeptidase,glutamyl endopeptidase,Alpha-lytic protease,2-iodobenzoate,Chymotrypsin,Chymotrypsin/P,Clostripain/P,iodosobenzoate,CNBr,staphylococcal protease/D,proline-endopeptidase/HKR,Trypsin,Arg-C,Formic_acid,Glu-C+P,Arg-C/P,Asp-N,Lys-C,Lys-N,cyanogen-bromide,Asp-N/B,PepsinA + P,Lys-C/P,PepsinA,elastase-trypsin-chymotrypsin,TrypChymo,no cleavage,unspecific cleavage,Trypsin/P,Asp-N_ambic,V8-DE,V8-E`  [autotest]
- **~** `CometAdapter:1:database`  formats: `*.FASTA` -> `*.FASTA,*.fa,*.faa`  [filetypes.txt; filetypes.txt MISSING: faa]
- **~** `CometAdapter:1:enzyme`  restrictions: `Arg-C/P,Asp-N,Chymotrypsin,CNBr,Trypsin,Arg-C,no cleavage,unspecific cleavage,Lys-C,Lys-N,PepsinA,Trypsin/P,glutamyl endopeptidase` -> `V8-E,leukocyte elastase,proline endopeptidase,glutamyl endopeptidase,Alpha-lytic protease,2-iodobenzoate,iodosobenzoate,staphylococcal protease/D,proline-endopeptidase/HKR,Glu-C+P,PepsinA + P,cyanogen-bromide,Clostripain/P,elastase-trypsin-chymotrypsin,no cleavage,unspecific cleavage,Lys-C,Lys-N,Lys-C/P,PepsinA,TrypChymo,Trypsin/P,V8-DE,Asp-N_ambic,Chymotrypsin,Trypsin,Arg-C,Asp-N,Asp-N/B,Arg-C/P,Chymotrypsin/P,CNBr,Formic_acid`  [autotest]
- **~** `CometAdapter:1:out`  formats: `*.idXML` -> `*.idXML,*.idparquet`  [filetypes.txt; filetypes.txt MISSING: idparquet]
- **~** `CometAdapter:1:second_enzyme`  restrictions: `Arg-C/P,Asp-N,Chymotrypsin,CNBr,Trypsin,Arg-C,no cleavage,unspecific cleavage,Lys-C,Lys-N,PepsinA,Trypsin/P,glutamyl endopeptidase` -> `V8-E,leukocyte elastase,proline endopeptidase,glutamyl endopeptidase,Alpha-lytic protease,2-iodobenzoate,iodosobenzoate,staphylococcal protease/D,proline-endopeptidase/HKR,Glu-C+P,PepsinA + P,cyanogen-bromide,Clostripain/P,elastase-trypsin-chymotrypsin,no cleavage,unspecific cleavage,Lys-C,Lys-N,Lys-C/P,PepsinA,TrypChymo,Trypsin/P,V8-DE,Asp-N_ambic,Chymotrypsin,Trypsin,Arg-C,Asp-N,Asp-N/B,Arg-C/P,Chymotrypsin/P,CNBr,Formic_acid`  [autotest]

### `DatabaseFilter`

- **~** `DatabaseFilter:1:in`  formats: `*.fasta` -> `*.fasta,*.fa,*.faa`  [filetypes.txt; filetypes.txt MISSING: faa]

### `DatabaseSuitability`

- **~** `DatabaseSuitability:1:database`  formats: `*.FASTA` -> `*.FASTA,*.fa,*.faa`  [filetypes.txt; filetypes.txt MISSING: faa]
- **~** `DatabaseSuitability:1:novo_database`  formats: `*.FASTA` -> `*.FASTA,*.fa,*.faa`  [filetypes.txt; filetypes.txt MISSING: faa]

### `DecoyDatabase`

- **+** `DecoyDatabase:1:shuffle_decoy_ratio` (int)
- **~** `DecoyDatabase:1:NeighborSearch:in_relevant_proteins`  formats: `*.fasta` -> `*.fasta,*.fa,*.faa`  [filetypes.txt; filetypes.txt MISSING: faa]
- **~** `DecoyDatabase:1:enzyme`  restrictions: `Arg-C/P,Asp-N,Asp-N/B,Glu-C+P,PepsinA + P,cyanogen-bromide,Clostripain/P,elastase-trypsin-chymotrypsin,Trypsin,Arg-C,glutamyl endopeptidase,Alpha-lytic protease,no cleavage,unspecific cleavage,Asp-N_ambic,Chymotrypsin,Chymotrypsin/P,CNBr,Formic_acid,Lys-C,Lys-N,Lys-C/P,PepsinA,TrypChymo,Trypsin/P,V8-DE,V8-E,leukocyte elastase,proline endopeptidase,2-iodobenzoate,iodosobenzoate,staphylococcal protease/D,proline-endopeptidase/HKR` -> `V8-E,leukocyte elastase,proline endopeptidase,glutamyl endopeptidase,Alpha-lytic protease,2-iodobenzoate,iodosobenzoate,staphylococcal protease/D,proline-endopeptidase/HKR,Glu-C+P,PepsinA + P,cyanogen-bromide,Clostripain/P,elastase-trypsin-chymotrypsin,no cleavage,unspecific cleavage,Formic_acid,Lys-C,Lys-N,Lys-C/P,PepsinA,TrypChymo,Trypsin/P,V8-DE,Asp-N/B,Asp-N_ambic,Trypsin,Arg-C/P,Asp-N,Arg-C,Chymotrypsin,Chymotrypsin/P,CNBr`  [autotest]

### `Digestor`

- **+** `Digestor:1:replace_ambiguous` (bool)
- **~** `Digestor:1:enzyme`  restrictions: `2-iodobenzoate,iodosobenzoate,staphylococcal protease/D,proline-endopeptidase/HKR,Glu-C+P,PepsinA + P,cyanogen-bromide,Clostripain/P,Trypsin,Arg-C,elastase-trypsin-chymotrypsin,no cleavage,unspecific cleavage,V8-E,leukocyte elastase,Arg-C/P,Asp-N,Asp-N/B,Asp-N_ambic,Chymotrypsin,Chymotrypsin/P,CNBr,Formic_acid,Lys-C,Lys-N,Lys-C/P,PepsinA,TrypChymo,Trypsin/P,V8-DE,proline endopeptidase,glutamyl endopeptidase,Alpha-lytic protease` -> `V8-E,leukocyte elastase,proline endopeptidase,glutamyl endopeptidase,Alpha-lytic protease,2-iodobenzoate,iodosobenzoate,staphylococcal protease/D,proline-endopeptidase/HKR,Glu-C+P,PepsinA + P,cyanogen-bromide,Clostripain/P,elastase-trypsin-chymotrypsin,no cleavage,unspecific cleavage,Arg-C,Arg-C/P,Asp-N,Asp-N/B,Asp-N_ambic,Chymotrypsin,Chymotrypsin/P,CNBr,Formic_acid,Lys-C,Trypsin,Lys-N,Lys-C/P,PepsinA,TrypChymo,Trypsin/P,V8-DE`  [autotest]
- **~** `Digestor:1:in`  formats: `*.fasta` -> `*.fasta,*.fa,*.faa`  [filetypes.txt; filetypes.txt MISSING: faa]

### `DigestorMotif`

- **~** `DigestorMotif:1:enzyme`  restrictions: `Lys-C,Lys-N,Lys-C/P,PepsinA,TrypChymo,Trypsin/P,V8-DE,V8-E,leukocyte elastase,proline endopeptidase,glutamyl endopeptidase,Alpha-lytic protease,2-iodobenzoate,iodosobenzoate,staphylococcal protease/D,proline-endopeptidase/HKR,Glu-C+P,PepsinA + P,cyanogen-bromide,Clostripain/P,elastase-trypsin-chymotrypsin,no cleavage,Trypsin,Arg-C,unspecific cleavage,Arg-C/P,Asp-N,Asp-N/B,Asp-N_ambic,Chymotrypsin,Chymotrypsin/P,CNBr,Formic_acid` -> `V8-E,leukocyte elastase,proline endopeptidase,glutamyl endopeptidase,Alpha-lytic protease,2-iodobenzoate,iodosobenzoate,staphylococcal protease/D,proline-endopeptidase/HKR,Glu-C+P,PepsinA + P,cyanogen-bromide,Clostripain/P,elastase-trypsin-chymotrypsin,no cleavage,unspecific cleavage,Arg-C/P,Asp-N,Asp-N/B,Asp-N_ambic,Chymotrypsin,Chymotrypsin/P,CNBr,Formic_acid,Lys-C,Trypsin,Arg-C,Lys-N,Lys-C/P,PepsinA,TrypChymo,Trypsin/P,V8-DE`  [autotest]
- **~** `DigestorMotif:1:in`  formats: `*.fasta` -> `*.fasta,*.fa,*.faa`  [filetypes.txt; filetypes.txt MISSING: faa]

### `EICExtractor`

- **~** `EICExtractor:1:rt_collect`  restrictions: `-` -> `0:`  [autotest]

### `FLASHDeconv`

- **rename** `FLASHDeconv:1:Algorithm:max_charge` -> `FLASHDeconv:1:SD:min_charge` (similarity 0.75)  [ini fixture/autotest]
- **rename** `FLASHDeconv:1:Algorithm:min_charge` -> `FLASHDeconv:1:SD:max_charge` (similarity 0.75)  [ini fixture/autotest]
- **rename** `FLASHDeconv:1:Algorithm:min_mass` -> `FLASHDeconv:1:ft:min_cos` (similarity 0.75)  [ini fixture/autotest]
- **rename** `FLASHDeconv:1:FeatureTracing:max_trace_length` -> `FLASHDeconv:1:ft:min_trace_length` (similarity 0.77)  [ini fixture/autotest]
- **rename** `FLASHDeconv:1:FeatureTracing:min_trace_length` -> `FLASHDeconv:1:ft:max_trace_length` (similarity 0.77)  [ini fixture/autotest]
- **rename** `FLASHDeconv:1:in_log` -> `FLASHDeconv:1:FD:ida_log` (similarity 0.86)  [ini fixture/autotest]
- **rename** `FLASHDeconv:1:max_MS_level` -> `FLASHDeconv:1:max_ms_level` (similarity 0.92)  [ini fixture/autotest]
- **rename** `FLASHDeconv:1:out_promex` -> `FLASHDeconv:1:out_spec4` (similarity 0.85)  [ini fixture/autotest]
- **rename** `FLASHDeconv:1:target_precursor_charge` -> `FLASHDeconv:1:SD:precursor_charge` (similarity 0.86)  [ini fixture/autotest]
- **rename** `FLASHDeconv:1:target_precursor_mz` -> `FLASHDeconv:1:SD:precursor_mz` (similarity 0.84)  [ini fixture/autotest]
- **+** `FLASHDeconv:1:FD:allowed_isotope_error` (int)
- **+** `FLASHDeconv:1:FD:isolation_window` (double)
- **+** `FLASHDeconv:1:FD:merging_max_ms_level` (int)
- **+** `FLASHDeconv:1:FD:merging_method` (int)
- **+** `FLASHDeconv:1:FD:merging_min_ms_level` (int)
- **+** `FLASHDeconv:1:FD:precursor_MS1_window` (int)
- **+** `FLASHDeconv:1:FD:report_FDR` (bool)
- **+** `FLASHDeconv:1:FD:use_RNA_averagine` (bool)
- **+** `FLASHDeconv:1:SD:max_mass` (double)
- **+** `FLASHDeconv:1:SD:min_mass` (double)
- **+** `FLASHDeconv:1:ft:ion_mobility_tolerance` (double)
- **+** `FLASHDeconv:1:ft:mass_error_ppm` (double)
- **+** `FLASHDeconv:1:ft:min_sample_rate` (double)
- **+** `FLASHDeconv:1:ft:quant_method` (string)
- **+** `FLASHDeconv:1:iq:isotope_correction` (string)
- **+** `FLASHDeconv:1:iq:only_fully_quantified` (bool)
- **+** `FLASHDeconv:1:iq:reporter_mz_tol` (double)
- **+** `FLASHDeconv:1:iq:type` (string)
- **+** `FLASHDeconv:1:keep_empty_out` (bool)
- **+** `FLASHDeconv:1:max_mz` (double)
- **+** `FLASHDeconv:1:max_rt` (double)
- **+** `FLASHDeconv:1:min_mz` (double)
- **+** `FLASHDeconv:1:min_rt` (double)
- **+** `FLASHDeconv:1:out_feature1` (output-file)  [filetypes.txt MISSING: feature]
- **+** `FLASHDeconv:1:out_feature2` (output-file)  [filetypes.txt MISSING: feature]
- **+** `FLASHDeconv:1:out_msalign1` (output-file)  [filetypes.txt MISSING: msalign]
- **+** `FLASHDeconv:1:out_msalign2` (output-file)  [filetypes.txt MISSING: msalign]
- **+** `FLASHDeconv:1:out_quant` (output-file)
- **+** `FLASHDeconv:1:out_spec1` (output-file)
- **+** `FLASHDeconv:1:out_spec2` (output-file)
- **+** `FLASHDeconv:1:out_spec3` (output-file)
- **-** `FLASHDeconv:1:Algorithm:allowed_isotope_error` (int)  [ini fixture/autotest]
- **-** `FLASHDeconv:1:Algorithm:isolation_window` (double)  [ini fixture/autotest]
- **-** `FLASHDeconv:1:Algorithm:max_mass` (double)  [ini fixture/autotest]
- **-** `FLASHDeconv:1:Algorithm:max_mz` (double)  [ini fixture/autotest]
- **-** `FLASHDeconv:1:Algorithm:max_rt` (double)  [ini fixture/autotest]
- **-** `FLASHDeconv:1:Algorithm:min_intensity` (double)  [ini fixture/autotest]
- **-** `FLASHDeconv:1:Algorithm:min_mz` (double)  [ini fixture/autotest]
- **-** `FLASHDeconv:1:Algorithm:min_rt` (double)  [ini fixture/autotest]
- **-** `FLASHDeconv:1:FeatureTracing:mass_error_ppm` (double)  [ini fixture/autotest]
- **-** `FLASHDeconv:1:FeatureTracing:min_isotope_cosine` (double)  [ini fixture/autotest]
- **-** `FLASHDeconv:1:FeatureTracing:min_sample_rate` (double)  [ini fixture/autotest]
- **-** `FLASHDeconv:1:FeatureTracing:quant_method` (string)  [ini fixture/autotest]
- **-** `FLASHDeconv:1:forced_MS_level` (int)  [ini fixture/autotest]
- **-** `FLASHDeconv:1:merging_method` (int)  [ini fixture/autotest]
- **-** `FLASHDeconv:1:min_precursor_snr` (double)  [ini fixture/autotest]
- **-** `FLASHDeconv:1:preceding_MS1_count` (int)  [ini fixture/autotest]
- **-** `FLASHDeconv:1:report_FDR` (int)  [ini fixture/autotest]
- **-** `FLASHDeconv:1:use_RNA_averagine` (int)  [ini fixture/autotest]
- **~** `FLASHDeconv:1:mzml_mass_charge`  advanced: `false` -> `true`  [wrapper structure]
- **~** `FLASHDeconv:1:write_detail`  type: `int` -> `bool`; restrictions: `0:1` -> `-`; default: `0` -> `false`  [behaviour; wrapper structure]

### `FalseDiscoveryRate`

- **+** `FalseDiscoveryRate:1:PSM_peptide_base_score` (string)
- **+** `FalseDiscoveryRate:1:PSM_peptide_base_score_orientation` (string)
- **+** `FalseDiscoveryRate:1:protein_base_score` (string)
- **+** `FalseDiscoveryRate:1:protein_base_score_orientation` (string)
- **+** `FalseDiscoveryRate:1:protein_score` (string)
- **+** `FalseDiscoveryRate:1:proteingroup` (bool)

### `FeatureFinderCentroided`

- **rename** `FeatureFinderCentroided:1:algorithm:debug` -> `FeatureFinderCentroided:1:algorithm:write_debug` (similarity 0.93)  [ini fixture/autotest]
- **+** `FeatureFinderCentroided:1:faims_merge_features` (string)

### `FeatureFinderIdentification`

- **rename** `FeatureFinderIdentification:1:extract:rt_quantile` -> `FeatureFinderIdentification:1:extract:IM_window` (similarity 0.83)  [ini fixture/autotest]
- **rename** `FeatureFinderIdentification:1:svm:epsilon` -> `FeatureFinderIdentification:1:seed_apex_rt_tolerance` (similarity 0.75)  [ini fixture/autotest]
- **rename** `FeatureFinderIdentification:1:svm:kernel` -> `FeatureFinderIdentification:1:faims:merge_features` (similarity 0.78)  [ini fixture/autotest]
- **-** `FeatureFinderIdentification:1:id_ext` (input-file)  [ini fixture/autotest]
- **-** `FeatureFinderIdentification:1:svm:cache_size` (double)  [ini fixture/autotest]
- **-** `FeatureFinderIdentification:1:svm:min_prob` (double)  [ini fixture/autotest]
- **-** `FeatureFinderIdentification:1:svm:no_selection` (bool)  [ini fixture/autotest]
- **-** `FeatureFinderIdentification:1:svm:no_shrinking` (bool)  [ini fixture/autotest]
- **-** `FeatureFinderIdentification:1:svm:predictors` (string)  [ini fixture/autotest]
- **-** `FeatureFinderIdentification:1:svm:samples` (int)  [ini fixture/autotest]
- **-** `FeatureFinderIdentification:1:svm:xval` (int)  [ini fixture/autotest]
- **-** `FeatureFinderIdentification:1:svm:xval_out` (output-file)  [ini fixture/autotest]
- **~** `FeatureFinderIdentification:1:EMGScoring:init_mom`  type: `bool` -> `string`; restrictions: `-` -> `true,false`; default: `false` -> `true`  [behaviour; wrapper structure]
- **~** `FeatureFinderIdentification:1:candidates_in`  formats: `*.featureXML` -> `*.featureXML,*.featureparquet`  [filetypes.txt; filetypes.txt MISSING: featureparquet]
- **~** `FeatureFinderIdentification:1:candidates_out`  formats: `*.featureXML` -> `*.featureXML,*.featureparquet`  [filetypes.txt; filetypes.txt MISSING: featureparquet]
- **~** `FeatureFinderIdentification:1:id`  formats: `*.idXML` -> `*.idXML,*.idparquet`  [filetypes.txt; filetypes.txt MISSING: idparquet]
- **~** `FeatureFinderIdentification:1:out`  formats: `*.featureXML` -> `*.featureXML,*.featureparquet`  [filetypes.txt; filetypes.txt MISSING: featureparquet]

### `FeatureFinderMetabo`

- **+** `FeatureFinderMetabo:1:algorithm:ffm:isotope_rt_overlap_reference` (string)
- **+** `FeatureFinderMetabo:1:algorithm:ffm:local_im_range` (double)
- **+** `FeatureFinderMetabo:1:algorithm:ffm:min_isotope_rt_overlap` (double)
- **+** `FeatureFinderMetabo:1:algorithm:ffm:report_smoothed_intensities` (string)
- **+** `FeatureFinderMetabo:1:algorithm:mtd:ion_mobility_tolerance` (double)
- **+** `FeatureFinderMetabo:1:faims_merge_features` (string)

### `FeatureFinderMetaboIdent`

- **+** `FeatureFinderMetaboIdent:1:extract:im_window` (double)
- **+** `FeatureFinderMetaboIdent:1:faims:merge_features` (string)
- **~** `FeatureFinderMetaboIdent:1:EMGScoring:init_mom`  type: `bool` -> `string`; restrictions: `-` -> `true,false`; default: `false` -> `true`  [behaviour; wrapper structure]

### `FeatureFinderMultiplex`

- **rename** `FeatureFinderMultiplex:1:algorithm:missed_cleavages` -> `FeatureFinderMultiplex:1:algorithm:max_nr_labelled_aas` (similarity 0.80)  [ini fixture/autotest]
- **+** `FeatureFinderMultiplex:1:faims_merge_features` (string)

### `FeatureLinkerLabeled`

- **~** `FeatureLinkerLabeled:1:in`  formats: `*.featureXML` -> `*.featureXML,*.featureparquet`  [filetypes.txt; filetypes.txt MISSING: featureparquet]
- **~** `FeatureLinkerLabeled:1:out`  formats: `*.consensusXML` -> `*.consensusXML,*.consensusparquet`  [filetypes.txt; filetypes.txt MISSING: consensusparquet]

### `FeatureLinkerUnlabeled`

- **-** `FeatureLinkerUnlabeled:1:design` (input-file)  [ini fixture/autotest]
- **~** `FeatureLinkerUnlabeled:1:out`  formats: `*.consensusXML` -> `*.consensusXML,*.consensusparquet`  [filetypes.txt; filetypes.txt MISSING: consensusparquet]

### `FeatureLinkerUnlabeledKD`

- **+** `FeatureLinkerUnlabeledKD:1:algorithm:LOWESS:auto_k_folds` (int)
- **+** `FeatureLinkerUnlabeledKD:1:algorithm:LOWESS:auto_metric` (string)
- **+** `FeatureLinkerUnlabeledKD:1:algorithm:LOWESS:auto_min_neighbors` (int)
- **+** `FeatureLinkerUnlabeledKD:1:algorithm:LOWESS:auto_span` (bool)
- **+** `FeatureLinkerUnlabeledKD:1:algorithm:LOWESS:auto_span_grid` (string)
- **+** `FeatureLinkerUnlabeledKD:1:algorithm:LOWESS:auto_span_max` (double)
- **+** `FeatureLinkerUnlabeledKD:1:algorithm:LOWESS:auto_span_min` (double)
- **-** `FeatureLinkerUnlabeledKD:1:design` (input-file)  [ini fixture/autotest]
- **~** `FeatureLinkerUnlabeledKD:1:out`  formats: `*.consensusXML` -> `*.consensusXML,*.consensusparquet`  [filetypes.txt; filetypes.txt MISSING: consensusparquet]

### `FeatureLinkerUnlabeledQT`

- **-** `FeatureLinkerUnlabeledQT:1:design` (input-file)  [ini fixture/autotest]
- **~** `FeatureLinkerUnlabeledQT:1:out`  formats: `*.consensusXML` -> `*.consensusXML,*.consensusparquet`  [filetypes.txt; filetypes.txt MISSING: consensusparquet]

### `FileConverter`

- **+** `FileConverter:1:OpenSwathWorkflow:legacy_traml_id` (bool)
- **+** `FileConverter:1:OpenSwathWorkflow:tr` (input-file)  [filetypes.txt MISSING: traml]
- **+** `FileConverter:1:OpenSwathWorkflow:tr_type` (string)
- **+** `FileConverter:1:RawToMzML:reader` (string)
- **+** `FileConverter:1:zstd_compression` (bool)
- **~** `FileConverter:1:in`  formats: `*.mzML,*.mzXML,*.mgf,*.raw,*.cachedMzML,*.mzData,*.dta,*.dta2d,*.featureXML,*.consensusXML,*.ms2,*.fid,*.tsv,*.peplist,*.kroenik,*.edta,*.oms` -> `*.mzML,*.mzXML,*.mgf,*.msp,*.raw,*.cachedMzML,*.mzData,*.dta,*.dta2d,*.featureXML,*.consensusXML,*.featureparquet,*.consensusparquet,*.ms2,*.fid,*.tsv,*.peplist,*.kroenik,*.edta,*.oms,*.sqMass`  [filetypes.txt; filetypes.txt MISSING: cachedMzML,featureparquet,consensusparquet,fid]
- **~** `FileConverter:1:out`  formats: `*.mzML,*.mzXML,*.cachedMzML,*.mgf,*.featureXML,*.consensusXML,*.edta,*.mzData,*.dta2d,*.csv,*.sqmass,*.oms` -> `*.mzML,*.mzXML,*.cachedMzML,*.mgf,*.msp,*.featureXML,*.consensusXML,*.featureparquet,*.consensusparquet,*.edta,*.mzData,*.dta2d,*.csv,*.sqMass,*.xic,*.oms`  [filetypes.txt; filetypes.txt MISSING: cachedMzML,featureparquet,consensusparquet,xic]
- **~** `FileConverter:1:out_type`  restrictions: `mzML,mzXML,cachedMzML,mgf,featureXML,consensusXML,edta,mzData,dta2d,csv,sqmass,oms` -> `mzML,mzXML,cachedMzML,mgf,msp,featureXML,consensusXML,featureparquet,consensusparquet,edta,mzData,dta2d,csv,sqMass,xic,oms`  [autotest]

### `FileFilter`

- **+** `FileFilter:1:peak_options:remove_metadataarrays` (bool)
- **+** `FileFilter:1:peak_options:zstd_compression` (bool)
- **+** `FileFilter:1:rt_block_mode` (string)

### `FileInfo`

- **~** `FileInfo:1:in`  formats: `*.mzData,*.mzXML,*.mzML,*.sqMass,*.dta,*.dta2d,*.mgf,*.featureXML,*.consensusXML,*.idXML,*.pepXML,*.fid,*.mzid,*.trafoXML,*.fasta,*.pqp` -> `*.mzData,*.mzXML,*.mzML,*.sqMass,*.dta,*.dta2d,*.mgf,*.featureXML,*.consensusXML,*.idXML,*.pepXML,*.pep.xml,*.mzTab,*.fid,*.mzid,*.trafoXML,*.fasta,*.fa,*.faa,*.pqp`  [filetypes.txt; filetypes.txt MISSING: fid,faa]

### `FuzzyDiff`

- **+** `FuzzyDiff:1:sort` (bool)

### `IDConflictResolver`

- **+** `IDConflictResolver:1:resolve_method` (string)
- **~** `IDConflictResolver:1:in`  formats: `*.featureXML,*.consensusXML` -> `*.featureXML,*.consensusXML,*.featureparquet,*.consensusparquet`  [filetypes.txt; filetypes.txt MISSING: featureparquet,consensusparquet]
- **~** `IDConflictResolver:1:out`  formats: `*.featureXML,*.consensusXML` -> `*.featureXML,*.consensusXML,*.featureparquet,*.consensusparquet`  [filetypes.txt; filetypes.txt MISSING: featureparquet,consensusparquet]

### `IDFileConverter`

- **+** `IDFileConverter:1:fasta_to_mzml:add_internal_fragments` (bool)
- **+** `IDFileConverter:1:fasta_to_mzml:add_term_losses` (bool)
- **~** `IDFileConverter:1:fasta_to_mzml:enzyme`  restrictions: `2-iodobenzoate,iodosobenzoate,staphylococcal protease/D,proline-endopeptidase/HKR,no cleavage,unspecific cleavage,Trypsin,Arg-C,glutamyl endopeptidase,Alpha-lytic protease,Arg-C/P,Asp-N,Asp-N/B,Asp-N_ambic,Chymotrypsin,Chymotrypsin/P,CNBr,Formic_acid,Lys-C,Lys-N,Lys-C/P,PepsinA,TrypChymo,Trypsin/P,V8-DE,V8-E,leukocyte elastase,proline endopeptidase,Glu-C+P,PepsinA + P,cyanogen-bromide,Clostripain/P,elastase-trypsin-chymotrypsin` -> `Trypsin,Asp-N,Asp-N/B,Asp-N_ambic,Chymotrypsin,Chymotrypsin/P,Clostripain/P,elastase-trypsin-chymotrypsin,no cleavage,unspecific cleavage,Arg-C,Arg-C/P,CNBr,Formic_acid,Lys-C,Lys-N,Lys-C/P,PepsinA,TrypChymo,Trypsin/P,V8-DE,V8-E,leukocyte elastase,proline endopeptidase,glutamyl endopeptidase,Alpha-lytic protease,2-iodobenzoate,iodosobenzoate,staphylococcal protease/D,proline-endopeptidase/HKR,Glu-C+P,PepsinA + P,cyanogen-bromide`  [autotest]
- **~** `IDFileConverter:1:in`  formats: `*.oms,*.idXML,*.mzid,*.fasta,*.pepXML,*.protXML,*.mascotXML,*.omssaXML,*.xml,*.psms,*.tsv,*.xquest.xml` -> `*.oms,*.idXML,*.mzid,*.idparquet,*.fasta,*.fa,*.faa,*.pepXML,*.pep.xml,*.protXML,*.prot.xml,*.mascotXML,*.omssaXML,*.xml,*.psms,*.tsv,*.xquest.xml`  [hardcoded_params.json (review); filetypes.txt; filetypes.txt MISSING: idparquet,faa,prot.xml]
- **~** `IDFileConverter:1:out`  formats: `*.oms,*.idXML,*.mzid,*.pepXML,*.fasta,*.xquest.xml,*.mzML` -> `*.oms,*.idXML,*.mzid,*.idparquet,*.pepXML,*.fasta,*.xquest.xml,*.mzML`  [filetypes.txt; filetypes.txt MISSING: idparquet]
- **~** `IDFileConverter:1:out_type`  restrictions: `oms,idXML,mzid,pepXML,fasta,xquest.xml,mzML` -> `oms,idXML,mzid,idparquet,pepXML,fasta,xquest.xml,mzML`  [autotest]

### `IDFilter`

- **+** `IDFilter:1:score:peptide` (double)
- **+** `IDFilter:1:score:type_peptide` (string)
- **+** `IDFilter:1:score:type_protein` (string)
- **~** `IDFilter:1:blacklist:peptides`  formats: `*.idXML` -> `*.idXML,*.idparquet`  [filetypes.txt; filetypes.txt MISSING: idparquet]
- **~** `IDFilter:1:blacklist:proteins`  formats: `*.fasta` -> `*.fasta,*.fa,*.faa`  [filetypes.txt; filetypes.txt MISSING: faa]
- **~** `IDFilter:1:in`  formats: `*.idXML,*.consensusXML` -> `*.idXML,*.consensusXML,*.idparquet,*.consensusparquet`  [filetypes.txt; filetypes.txt MISSING: idparquet,consensusparquet]
- **~** `IDFilter:1:in_silico_digestion:enzyme`  restrictions: `Trypsin,Asp-N,Asp-N/B,Asp-N_ambic,Lys-N,Lys-C/P,PepsinA,TrypChymo,cyanogen-bromide,Clostripain/P,elastase-trypsin-chymotrypsin,no cleavage,unspecific cleavage,Chymotrypsin,Chymotrypsin/P,CNBr,Formic_acid,Lys-C,Arg-C,Arg-C/P,Trypsin/P,V8-DE,V8-E,leukocyte elastase,iodosobenzoate,staphylococcal protease/D,proline-endopeptidase/HKR,Glu-C+P,PepsinA + P,proline endopeptidase,glutamyl endopeptidase,Alpha-lytic protease,2-iodobenzoate` -> `iodosobenzoate,2-iodobenzoate,Alpha-lytic protease,glutamyl endopeptidase,proline endopeptidase,Glu-C+P,unspecific cleavage,no cleavage,elastase-trypsin-chymotrypsin,Clostripain/P,cyanogen-bromide,PepsinA + P,staphylococcal protease/D,proline-endopeptidase/HKR,leukocyte elastase,Trypsin,Arg-C,Arg-C/P,Asp-N,Asp-N/B,Asp-N_ambic,V8-DE,Chymotrypsin,Chymotrypsin/P,V8-E,CNBr,Formic_acid,Lys-C,Lys-N,Lys-C/P,PepsinA,TrypChymo,Trypsin/P`  [autotest]
- **~** `IDFilter:1:in_silico_digestion:fasta`  formats: `*.fasta` -> `*.fasta,*.fa,*.faa`  [filetypes.txt; filetypes.txt MISSING: faa]
- **~** `IDFilter:1:missed_cleavages:enzyme`  restrictions: `Trypsin,Asp-N,Asp-N/B,Asp-N_ambic,Lys-N,Lys-C/P,PepsinA,TrypChymo,cyanogen-bromide,Clostripain/P,elastase-trypsin-chymotrypsin,no cleavage,unspecific cleavage,Chymotrypsin,Chymotrypsin/P,CNBr,Formic_acid,Lys-C,Arg-C,Arg-C/P,Trypsin/P,V8-DE,V8-E,leukocyte elastase,iodosobenzoate,staphylococcal protease/D,proline-endopeptidase/HKR,Glu-C+P,PepsinA + P,proline endopeptidase,glutamyl endopeptidase,Alpha-lytic protease,2-iodobenzoate` -> `iodosobenzoate,2-iodobenzoate,Alpha-lytic protease,glutamyl endopeptidase,proline endopeptidase,Glu-C+P,unspecific cleavage,no cleavage,elastase-trypsin-chymotrypsin,Clostripain/P,cyanogen-bromide,PepsinA + P,staphylococcal protease/D,proline-endopeptidase/HKR,leukocyte elastase,Trypsin,Arg-C,Arg-C/P,Asp-N,Asp-N/B,Asp-N_ambic,V8-DE,Chymotrypsin,Chymotrypsin/P,V8-E,CNBr,Formic_acid,Lys-C,Lys-N,Lys-C/P,PepsinA,TrypChymo,Trypsin/P`  [autotest]
- **~** `IDFilter:1:out`  formats: `*.idXML,*.consensusXML` -> `*.idXML,*.consensusXML,*.idparquet,*.consensusparquet`  [filetypes.txt; filetypes.txt MISSING: idparquet,consensusparquet]
- **~** `IDFilter:1:score:protein`  default: `nan` -> `NaN`  [behaviour]
- **~** `IDFilter:1:score:proteingroup`  default: `nan` -> `NaN`  [behaviour]
- **~** `IDFilter:1:score:psm`  default: `nan` -> `NaN`  [behaviour]
- **~** `IDFilter:1:whitelist:peptides`  formats: `*.idXML` -> `*.idXML,*.idparquet`  [filetypes.txt; filetypes.txt MISSING: idparquet]
- **~** `IDFilter:1:whitelist:proteins`  formats: `*.fasta` -> `*.fasta,*.fa,*.faa`  [filetypes.txt; filetypes.txt MISSING: faa]

### `IDMerger`

- **~** `IDMerger:1:out`  formats: `*.idXML,*.oms` -> `*.idXML,*.oms,*.idparquet`  [filetypes.txt; filetypes.txt MISSING: idparquet]
- **~** `IDMerger:1:out_type`  restrictions: `idXML,oms` -> `idXML,oms,idparquet`  [autotest]

### `IDRipper`

- **~** `IDRipper:1:in`  formats: `*.idXML` -> `*.idXML,*.idparquet`  [filetypes.txt; filetypes.txt MISSING: idparquet]

### `IDScoreSwitcher`

- **~** `IDScoreSwitcher:1:in`  formats: `*.idXML` -> `*.idXML,*.idparquet`  [filetypes.txt; filetypes.txt MISSING: idparquet]
- **~** `IDScoreSwitcher:1:out`  formats: `*.idXML` -> `*.idXML,*.idparquet`  [filetypes.txt; filetypes.txt MISSING: idparquet]

### `IDSplitter`

- **~** `IDSplitter:1:in`  formats: `*.mzML,*.featureXML,*.consensusXML` -> `*.featureXML,*.consensusXML`  [filetypes.txt]
- **~** `IDSplitter:1:out`  formats: `*.mzML,*.featureXML,*.consensusXML` -> `*.featureXML,*.consensusXML`  [filetypes.txt]

### `IsobaricAnalyzer`

- **+** `IsobaricAnalyzer:1:tmt32plex:channel_126_description` (string)
- **+** `IsobaricAnalyzer:1:tmt32plex:channel_127C_description` (string)
- **+** `IsobaricAnalyzer:1:tmt32plex:channel_127D_description` (string)
- **+** `IsobaricAnalyzer:1:tmt32plex:channel_127N_description` (string)
- **+** `IsobaricAnalyzer:1:tmt32plex:channel_128CD_description` (string)
- **+** `IsobaricAnalyzer:1:tmt32plex:channel_128C_description` (string)
- **+** `IsobaricAnalyzer:1:tmt32plex:channel_128ND_description` (string)
- **+** `IsobaricAnalyzer:1:tmt32plex:channel_128N_description` (string)
- **+** `IsobaricAnalyzer:1:tmt32plex:channel_129CD_description` (string)
- **+** `IsobaricAnalyzer:1:tmt32plex:channel_129C_description` (string)
- **+** `IsobaricAnalyzer:1:tmt32plex:channel_129ND_description` (string)
- **+** `IsobaricAnalyzer:1:tmt32plex:channel_129N_description` (string)
- **+** `IsobaricAnalyzer:1:tmt32plex:channel_130CD_description` (string)
- **+** `IsobaricAnalyzer:1:tmt32plex:channel_130C_description` (string)
- **+** `IsobaricAnalyzer:1:tmt32plex:channel_130ND_description` (string)
- **+** `IsobaricAnalyzer:1:tmt32plex:channel_130N_description` (string)
- **+** `IsobaricAnalyzer:1:tmt32plex:channel_131CD_description` (string)
- **+** `IsobaricAnalyzer:1:tmt32plex:channel_131C_description` (string)
- **+** `IsobaricAnalyzer:1:tmt32plex:channel_131ND_description` (string)
- **+** `IsobaricAnalyzer:1:tmt32plex:channel_131N_description` (string)
- **+** `IsobaricAnalyzer:1:tmt32plex:channel_132CD_description` (string)
- **+** `IsobaricAnalyzer:1:tmt32plex:channel_132C_description` (string)
- **+** `IsobaricAnalyzer:1:tmt32plex:channel_132ND_description` (string)
- **+** `IsobaricAnalyzer:1:tmt32plex:channel_132N_description` (string)
- **+** `IsobaricAnalyzer:1:tmt32plex:channel_133CD_description` (string)
- **+** `IsobaricAnalyzer:1:tmt32plex:channel_133C_description` (string)
- **+** `IsobaricAnalyzer:1:tmt32plex:channel_133ND_description` (string)
- **+** `IsobaricAnalyzer:1:tmt32plex:channel_133N_description` (string)
- **+** `IsobaricAnalyzer:1:tmt32plex:channel_134CD_description` (string)
- **+** `IsobaricAnalyzer:1:tmt32plex:channel_134ND_description` (string)
- **+** `IsobaricAnalyzer:1:tmt32plex:channel_134N_description` (string)
- **+** `IsobaricAnalyzer:1:tmt32plex:channel_135ND_description` (string)
- **+** `IsobaricAnalyzer:1:tmt32plex:reference_channel` (string)
- **+** `IsobaricAnalyzer:1:tmt35plex:channel_126_description` (string)
- **+** `IsobaricAnalyzer:1:tmt35plex:channel_127C_description` (string)
- **+** `IsobaricAnalyzer:1:tmt35plex:channel_127D_description` (string)
- **+** `IsobaricAnalyzer:1:tmt35plex:channel_127N_description` (string)
- **+** `IsobaricAnalyzer:1:tmt35plex:channel_128CD_description` (string)
- **+** `IsobaricAnalyzer:1:tmt35plex:channel_128C_description` (string)
- **+** `IsobaricAnalyzer:1:tmt35plex:channel_128ND_description` (string)
- **+** `IsobaricAnalyzer:1:tmt35plex:channel_128N_description` (string)
- **+** `IsobaricAnalyzer:1:tmt35plex:channel_129CD_description` (string)
- **+** `IsobaricAnalyzer:1:tmt35plex:channel_129C_description` (string)
- **+** `IsobaricAnalyzer:1:tmt35plex:channel_129ND_description` (string)
- **+** `IsobaricAnalyzer:1:tmt35plex:channel_129N_description` (string)
- **+** `IsobaricAnalyzer:1:tmt35plex:channel_130CD_description` (string)
- **+** `IsobaricAnalyzer:1:tmt35plex:channel_130C_description` (string)
- **+** `IsobaricAnalyzer:1:tmt35plex:channel_130ND_description` (string)
- **+** `IsobaricAnalyzer:1:tmt35plex:channel_130N_description` (string)
- **+** `IsobaricAnalyzer:1:tmt35plex:channel_131CD_description` (string)
- **+** `IsobaricAnalyzer:1:tmt35plex:channel_131C_description` (string)
- **+** `IsobaricAnalyzer:1:tmt35plex:channel_131ND_description` (string)
- **+** `IsobaricAnalyzer:1:tmt35plex:channel_131N_description` (string)
- **+** `IsobaricAnalyzer:1:tmt35plex:channel_132CD_description` (string)
- **+** `IsobaricAnalyzer:1:tmt35plex:channel_132C_description` (string)
- **+** `IsobaricAnalyzer:1:tmt35plex:channel_132ND_description` (string)
- **+** `IsobaricAnalyzer:1:tmt35plex:channel_132N_description` (string)
- **+** `IsobaricAnalyzer:1:tmt35plex:channel_133CD_description` (string)
- **+** `IsobaricAnalyzer:1:tmt35plex:channel_133C_description` (string)
- **+** `IsobaricAnalyzer:1:tmt35plex:channel_133ND_description` (string)
- **+** `IsobaricAnalyzer:1:tmt35plex:channel_133N_description` (string)
- **+** `IsobaricAnalyzer:1:tmt35plex:channel_134CD_description` (string)
- **+** `IsobaricAnalyzer:1:tmt35plex:channel_134C_description` (string)
- **+** `IsobaricAnalyzer:1:tmt35plex:channel_134ND_description` (string)
- **+** `IsobaricAnalyzer:1:tmt35plex:channel_134N_description` (string)
- **+** `IsobaricAnalyzer:1:tmt35plex:channel_135CD_description` (string)
- **+** `IsobaricAnalyzer:1:tmt35plex:channel_135ND_description` (string)
- **+** `IsobaricAnalyzer:1:tmt35plex:channel_135N_description` (string)
- **+** `IsobaricAnalyzer:1:tmt35plex:reference_channel` (string)
- **~** `IsobaricAnalyzer:1:type`  restrictions: `itraq4plex,itraq8plex,tmt10plex,tmt11plex,tmt16plex,tmt18plex,tmt6plex` -> `itraq4plex,itraq8plex,tmt10plex,tmt11plex,tmt16plex,tmt18plex,tmt32plex,tmt35plex,tmt6plex`  [autotest]

### `MRMTransitionGroupPicker`

- **+** `MRMTransitionGroupPicker:1:algorithm:PeakPickerChromatogram:report_sn` (bool)

### `MSFraggerAdapter`

- **~** `MSFraggerAdapter:1:PeptideIndexing:enzyme:name`  restrictions: `auto,Lys-C/P,PepsinA,glutamyl endopeptidase,Alpha-lytic protease,2-iodobenzoate,iodosobenzoate,staphylococcal protease/D,Arg-C,Arg-C/P,Asp-N,Formic_acid,Lys-C,Lys-N,Asp-N/B,Asp-N_ambic,Chymotrypsin,Chymotrypsin/P,CNBr,no cleavage,unspecific cleavage,TrypChymo,Trypsin/P,proline-endopeptidase/HKR,Glu-C+P,PepsinA + P,cyanogen-bromide,Clostripain/P,elastase-trypsin-chymotrypsin,V8-DE,V8-E,leukocyte elastase,proline endopeptidase,Trypsin` -> `auto,Asp-N,Asp-N/B,Asp-N_ambic,Chymotrypsin,Chymotrypsin/P,CNBr,Formic_acid,Lys-C,no cleavage,unspecific cleavage,iodosobenzoate,staphylococcal protease/D,proline-endopeptidase/HKR,Glu-C+P,PepsinA + P,cyanogen-bromide,Clostripain/P,elastase-trypsin-chymotrypsin,Arg-C,Arg-C/P,V8-E,leukocyte elastase,proline endopeptidase,glutamyl endopeptidase,Alpha-lytic protease,2-iodobenzoate,Lys-N,Lys-C/P,PepsinA,TrypChymo,Trypsin/P,V8-DE,Trypsin`  [autotest]
- **~** `MSFraggerAdapter:1:database`  formats: `*.FASTA,*.fasta,*.fa,*.fas` -> `*.FASTA,*.fa,*.faa,*.fas`  [filetypes.txt; filetypes.txt MISSING: faa]
- **~** `MSFraggerAdapter:1:digest:search_enzyme_name`  restrictions: `Arg-C/P,Asp-N,Asp-N/B,Asp-N_ambic,Chymotrypsin,2-iodobenzoate,iodosobenzoate,staphylococcal protease/D,Trypsin,Arg-C,Clostripain/P,elastase-trypsin-chymotrypsin,no cleavage,unspecific cleavage,Chymotrypsin/P,CNBr,Formic_acid,Lys-C,Lys-N,Lys-C/P,PepsinA,TrypChymo,Trypsin/P,V8-DE,V8-E,leukocyte elastase,proline endopeptidase,glutamyl endopeptidase,Alpha-lytic protease,proline-endopeptidase/HKR,Glu-C+P,PepsinA + P,cyanogen-bromide` -> `V8-DE,V8-E,leukocyte elastase,proline endopeptidase,glutamyl endopeptidase,Alpha-lytic protease,2-iodobenzoate,iodosobenzoate,staphylococcal protease/D,proline-endopeptidase/HKR,Glu-C+P,PepsinA + P,cyanogen-bromide,Clostripain/P,elastase-trypsin-chymotrypsin,no cleavage,unspecific cleavage,Formic_acid,Lys-C,Lys-N,Lys-C/P,PepsinA,TrypChymo,Trypsin/P,Asp-N/B,Asp-N_ambic,Trypsin,Arg-C/P,Asp-N,Arg-C,Chymotrypsin,Chymotrypsin/P,CNBr`  [autotest]

### `MSGFPlusAdapter`

- **+** `MSGFPlusAdapter:1:allow_dense_centroided_peaks` (bool)
- **~** `MSGFPlusAdapter:1:PeptideIndexing:enzyme:name`  restrictions: `auto,PepsinA + P,cyanogen-bromide,Clostripain/P,elastase-trypsin-chymotrypsin,no cleavage,unspecific cleavage,Arg-C,Arg-C/P,Asp-N,Trypsin,Formic_acid,Lys-C,Lys-N,Lys-C/P,proline endopeptidase,glutamyl endopeptidase,Alpha-lytic protease,2-iodobenzoate,iodosobenzoate,staphylococcal protease/D,proline-endopeptidase/HKR,Glu-C+P,Asp-N/B,Asp-N_ambic,Chymotrypsin,Chymotrypsin/P,CNBr,PepsinA,TrypChymo,Trypsin/P,V8-DE,V8-E,leukocyte elastase` -> `auto,Glu-C+P,PepsinA + P,cyanogen-bromide,Clostripain/P,elastase-trypsin-chymotrypsin,Trypsin/P,V8-DE,PepsinA,no cleavage,V8-E,unspecific cleavage,Asp-N,Asp-N/B,Asp-N_ambic,Chymotrypsin,Chymotrypsin/P,CNBr,leukocyte elastase,Formic_acid,Lys-C,proline endopeptidase,Lys-C/P,Lys-N,glutamyl endopeptidase,Alpha-lytic protease,2-iodobenzoate,Trypsin,Arg-C/P,Arg-C,iodosobenzoate,TrypChymo,staphylococcal protease/D,proline-endopeptidase/HKR`  [autotest]
- **~** `MSGFPlusAdapter:1:database`  formats: `*.FASTA` -> `*.FASTA,*.fa,*.faa`  [filetypes.txt; filetypes.txt MISSING: faa]
- **~** `MSGFPlusAdapter:1:out`  formats: `*.idXML` -> `*.idXML,*.idparquet`  [filetypes.txt; filetypes.txt MISSING: idparquet]

### `MSstatsConverter`

- **+** `MSstatsConverter:1:remove_shared_peptides` (string)

### `MapAlignerIdentification`

- **+** `MapAlignerIdentification:1:algorithm:auto_reference` (string)
- **+** `MapAlignerIdentification:1:algorithm:auto_reference_min_points` (int)
- **+** `MapAlignerIdentification:1:model:lowess:auto_k_folds` (int)
- **+** `MapAlignerIdentification:1:model:lowess:auto_metric` (string)
- **+** `MapAlignerIdentification:1:model:lowess:auto_min_neighbors` (int)
- **+** `MapAlignerIdentification:1:model:lowess:auto_span` (bool)
- **+** `MapAlignerIdentification:1:model:lowess:auto_span_grid` (string)
- **+** `MapAlignerIdentification:1:model:lowess:auto_span_max` (double)
- **+** `MapAlignerIdentification:1:model:lowess:auto_span_min` (double)
- **~** `MapAlignerIdentification:1:reference:file`  formats: `*.featureXML,*.consensusXML,*.idXML,*.oms` -> `*.featureXML,*.featureparquet,*.consensusXML,*.consensusparquet,*.idXML,*.idparquet,*.oms`  [filetypes.txt; filetypes.txt MISSING: featureparquet,consensusparquet,idparquet]

### `MapAlignerTreeGuided`

- **+** `MapAlignerTreeGuided:1:algorithm:align_algorithm:auto_reference` (string)
- **+** `MapAlignerTreeGuided:1:algorithm:align_algorithm:auto_reference_min_points` (int)
- **+** `MapAlignerTreeGuided:1:algorithm:model:lowess:auto_k_folds` (int)
- **+** `MapAlignerTreeGuided:1:algorithm:model:lowess:auto_metric` (string)
- **+** `MapAlignerTreeGuided:1:algorithm:model:lowess:auto_min_neighbors` (int)
- **+** `MapAlignerTreeGuided:1:algorithm:model:lowess:auto_span` (bool)
- **+** `MapAlignerTreeGuided:1:algorithm:model:lowess:auto_span_grid` (string)
- **+** `MapAlignerTreeGuided:1:algorithm:model:lowess:auto_span_max` (double)
- **+** `MapAlignerTreeGuided:1:algorithm:model:lowess:auto_span_min` (double)

### `MapRTTransformer`

- **+** `MapRTTransformer:1:model:lowess:auto_k_folds` (int)
- **+** `MapRTTransformer:1:model:lowess:auto_metric` (string)
- **+** `MapRTTransformer:1:model:lowess:auto_min_neighbors` (int)
- **+** `MapRTTransformer:1:model:lowess:auto_span` (bool)
- **+** `MapRTTransformer:1:model:lowess:auto_span_grid` (string)
- **+** `MapRTTransformer:1:model:lowess:auto_span_max` (double)
- **+** `MapRTTransformer:1:model:lowess:auto_span_min` (double)
- **~** `MapRTTransformer:1:in`  formats: `*.mzML,*.featureXML,*.consensusXML,*.idXML` -> `*.mzML,*.featureXML,*.featureparquet,*.consensusXML,*.consensusparquet,*.idXML,*.idparquet`  [filetypes.txt; filetypes.txt MISSING: featureparquet,consensusparquet,idparquet]
- **~** `MapRTTransformer:1:out`  formats: `*.mzML,*.featureXML,*.consensusXML,*.idXML` -> `*.mzML,*.featureXML,*.featureparquet,*.consensusXML,*.consensusparquet,*.idXML,*.idparquet`  [filetypes.txt; filetypes.txt MISSING: featureparquet,consensusparquet,idparquet]

### `MassTraceExtractor`

- **+** `MassTraceExtractor:1:algorithm:mtd:ion_mobility_tolerance` (double)

### `MetaProSIP`

- **~** `MetaProSIP:1:heatmap_bins`  restrictions: `-` -> `1:`  [autotest]
- **~** `MetaProSIP:1:in_fasta`  formats: `*.fasta` -> `*.fasta,*.fa,*.faa`  [filetypes.txt; filetypes.txt MISSING: faa]

### `MetaboliteAdductDecharger`

- **+** `MetaboliteAdductDecharger:1:algorithm:MetaboliteFeatureDeconvolution:max_multimer` (int)
- **+** `MetaboliteAdductDecharger:1:algorithm:MetaboliteFeatureDeconvolution:multimer_log_penalty` (double)
- **+** `MetaboliteAdductDecharger:1:algorithm:MetaboliteFeatureDeconvolution:rt_overlap_reference` (string)

### `MetaboliteSpectralMatcher`

- **+** `MetaboliteSpectralMatcher:1:algorithm:ccs_error_percent` (double)

### `MultiplexResolver`

- **rename** `MultiplexResolver:1:algorithm:missed_cleavages` -> `MultiplexResolver:1:algorithm:max_nr_labelled_aas` (similarity 0.78)  [ini fixture/autotest]
- **~** `MultiplexResolver:1:algorithm:mz_tolerance`  type: `int` -> `double`; restrictions: `-` -> `0.000000:`; default: `10` -> `10.0`  [behaviour; wrapper structure]
- **~** `MultiplexResolver:1:algorithm:rt_tolerance`  type: `int` -> `double`; restrictions: `-` -> `0.000000:`; default: `5` -> `5.0`  [behaviour; wrapper structure]

### `MzTabExporter`

- **~** `MzTabExporter:1:in`  formats: `*.featureXML,*.consensusXML,*.idXML,*.mzid` -> `*.featureXML,*.featureparquet,*.consensusXML,*.consensusparquet,*.idXML,*.idparquet,*.mzid`  [filetypes.txt; filetypes.txt MISSING: featureparquet,consensusparquet,idparquet]

### `NoiseFilterGaussian`

- **~** `NoiseFilterGaussian:1:algorithm:gaussian_width`  restrictions: `-` -> `0.000000:`  [autotest]
- **~** `NoiseFilterGaussian:1:algorithm:ppm_tolerance`  restrictions: `-` -> `0.000000:`  [autotest]

### `NucleicAcidSearchEngine`

- **~** `NucleicAcidSearchEngine:1:database`  formats: `*.fasta` -> `*.fasta,*.fa,*.faa`  [filetypes.txt; filetypes.txt MISSING: faa]
- **~** `NucleicAcidSearchEngine:1:oligo:enzyme`  restrictions: `unspecific cleavage,RNase_U2,RNase_T1_Phosphatase,cusativin,RNase_MC1,RNase_H,RNase_4,RNase_4p,mazF,colicin_E5,no cleavage,RNase_A,RNase_T1` -> `colicin_E5,no cleavage,unspecific cleavage,RNase_T1_Phosphatase,cusativin,RNase_U2,RNase_A,RNase_MC1,RNase_H,RNase_4,RNase_4p,RNase_4c,mazF,RNase_T1`  [autotest]

### `OpenPepXL`

- **~** `OpenPepXL:1:database`  formats: `*.fasta` -> `*.fasta,*.fa,*.faa`  [filetypes.txt; filetypes.txt MISSING: faa]
- **~** `OpenPepXL:1:decoy_database`  formats: `*.fasta` -> `*.fasta,*.fa,*.faa`  [filetypes.txt; filetypes.txt MISSING: faa]
- **~** `OpenPepXL:1:peptide:enzyme`  restrictions: `Arg-C,Arg-C/P,Asp-N,Asp-N/B,Asp-N_ambic,Chymotrypsin,Lys-C/P,PepsinA,TrypChymo,Trypsin/P,Lys-C,Lys-N,Chymotrypsin/P,CNBr,Formic_acid,cyanogen-bromide,Clostripain/P,elastase-trypsin-chymotrypsin,no cleavage,unspecific cleavage,Trypsin,V8-DE,V8-E,leukocyte elastase,proline endopeptidase,glutamyl endopeptidase,Alpha-lytic protease,2-iodobenzoate,iodosobenzoate,staphylococcal protease/D,proline-endopeptidase/HKR,Glu-C+P,PepsinA + P` -> `2-iodobenzoate,Alpha-lytic protease,glutamyl endopeptidase,proline endopeptidase,proline-endopeptidase/HKR,PepsinA + P,Clostripain/P,Glu-C+P,unspecific cleavage,iodosobenzoate,staphylococcal protease/D,leukocyte elastase,cyanogen-bromide,Arg-C/P,Trypsin/P,Asp-N,Asp-N/B,Asp-N_ambic,Chymotrypsin,Chymotrypsin/P,Trypsin,V8-DE,Arg-C,CNBr,V8-E,Formic_acid,Lys-C,Lys-N,Lys-C/P,PepsinA,TrypChymo,elastase-trypsin-chymotrypsin,no cleavage`  [autotest]

### `OpenSwathAnalyzer`

- **+** `OpenSwathAnalyzer:1:algorithm:TransitionGroupPicker:PeakPickerChromatogram:report_sn` (bool)
- **+** `OpenSwathAnalyzer:1:algorithm:apply_im_peak_picking` (bool)
- **+** `OpenSwathAnalyzer:1:algorithm:enzyme` (string)
- **+** `OpenSwathAnalyzer:1:algorithm:irt_mz_extraction_window` (double)
- **+** `OpenSwathAnalyzer:1:algorithm:irt_mz_extraction_window_unit` (string)
- **+** `OpenSwathAnalyzer:1:algorithm:merge_spectra_by_peak_width_fraction` (double)
- **+** `OpenSwathAnalyzer:1:algorithm:mz_extraction_window` (double)
- **+** `OpenSwathAnalyzer:1:algorithm:mz_extraction_window_ms1` (double)
- **+** `OpenSwathAnalyzer:1:algorithm:mz_extraction_window_ms1_unit` (string)
- **+** `OpenSwathAnalyzer:1:algorithm:mz_extraction_window_unit` (string)
- **+** `OpenSwathAnalyzer:1:algorithm:spectrum_merge_method_type` (string)
- **-** `OpenSwathAnalyzer:1:algorithm:Scores:use_sonar_scores` (bool)  [ini fixture/autotest]

### `OpenSwathAssayGenerator`

- **+** `OpenSwathAssayGenerator:1:disable_decoy_transitions` (bool)
- **+** `OpenSwathAssayGenerator:1:ipf_decoy_seed` (int)
- **~** `OpenSwathAssayGenerator:1:in`  formats: `*.tsv,*.mrm,*.pqp,*.TraML` -> `*.tsv,*.mrm,*.pqp,*.TraML,*.oswpq`  [filetypes.txt; filetypes.txt MISSING: oswpq]
- **~** `OpenSwathAssayGenerator:1:out`  formats: `*.tsv,*.pqp,*.TraML` -> `*.tsv,*.pqp,*.TraML,*.oswpq`  [filetypes.txt; filetypes.txt MISSING: oswpq]
- **~** `OpenSwathAssayGenerator:1:out_type`  restrictions: `tsv,pqp,TraML` -> `tsv,pqp,TraML,oswpq`  [autotest]

### `OpenSwathDecoyGenerator`

- **~** `OpenSwathDecoyGenerator:1:in`  formats: `*.tsv,*.mrm,*.pqp,*.TraML` -> `*.tsv,*.mrm,*.pqp,*.TraML,*.oswpq`  [filetypes.txt; filetypes.txt MISSING: oswpq]
- **~** `OpenSwathDecoyGenerator:1:out`  formats: `*.tsv,*.pqp,*.TraML` -> `*.tsv,*.pqp,*.TraML,*.oswpq`  [filetypes.txt; filetypes.txt MISSING: oswpq]
- **~** `OpenSwathDecoyGenerator:1:out_type`  restrictions: `tsv,pqp,TraML` -> `tsv,pqp,TraML,oswpq`  [autotest]

### `OpenSwathRTNormalizer`

- **+** `OpenSwathRTNormalizer:1:algorithm:TransitionGroupPicker:PeakPickerChromatogram:report_sn` (bool)
- **+** `OpenSwathRTNormalizer:1:algorithm:apply_im_peak_picking` (bool)
- **+** `OpenSwathRTNormalizer:1:algorithm:enzyme` (string)
- **+** `OpenSwathRTNormalizer:1:algorithm:irt_mz_extraction_window` (double)
- **+** `OpenSwathRTNormalizer:1:algorithm:irt_mz_extraction_window_unit` (string)
- **+** `OpenSwathRTNormalizer:1:algorithm:merge_spectra_by_peak_width_fraction` (double)
- **+** `OpenSwathRTNormalizer:1:algorithm:mz_extraction_window` (double)
- **+** `OpenSwathRTNormalizer:1:algorithm:mz_extraction_window_ms1` (double)
- **+** `OpenSwathRTNormalizer:1:algorithm:mz_extraction_window_ms1_unit` (string)
- **+** `OpenSwathRTNormalizer:1:algorithm:mz_extraction_window_unit` (string)
- **+** `OpenSwathRTNormalizer:1:algorithm:spectrum_merge_method_type` (string)
- **-** `OpenSwathRTNormalizer:1:algorithm:Scores:use_sonar_scores` (bool)  [ini fixture/autotest]

### `OpenSwathWorkflow`

- **rename** `OpenSwathWorkflow:1:Calibration:debug_im_file` -> `OpenSwathWorkflow:1:Calibration:MassIMCorrection:debug_mz_file` (similarity 0.82)  [ini fixture/autotest]
- **rename** `OpenSwathWorkflow:1:Calibration:debug_mz_file` -> `OpenSwathWorkflow:1:Calibration:MassIMCorrection:debug_im_file` (similarity 0.82)  [ini fixture/autotest]
- **rename** `OpenSwathWorkflow:1:Calibration:im_correction_function` -> `OpenSwathWorkflow:1:Calibration:MassIMCorrection:mz_correction_function` (similarity 0.86)  [ini fixture/autotest]
- **rename** `OpenSwathWorkflow:1:RTNormalization:InitialQualityCutoff` -> `OpenSwathWorkflow:1:Calibration:RTNormalization:OverallQualityCutoff` (similarity 0.82)  [ini fixture/autotest]
- **rename** `OpenSwathWorkflow:1:RTNormalization:MinBinsFilled` -> `OpenSwathWorkflow:1:Calibration:RTNormalization:NrRTBins` (similarity 0.76)  [ini fixture/autotest]
- **rename** `OpenSwathWorkflow:1:RTNormalization:NrRTBins` -> `OpenSwathWorkflow:1:Calibration:RTNormalization:MinBinsFilled` (similarity 0.76)  [ini fixture/autotest]
- **rename** `OpenSwathWorkflow:1:RTNormalization:OverallQualityCutoff` -> `OpenSwathWorkflow:1:Calibration:RTNormalization:InitialQualityCutoff` (similarity 0.82)  [ini fixture/autotest]
- **rename** `OpenSwathWorkflow:1:RTNormalization:RANSACMaxIterations` -> `OpenSwathWorkflow:1:Calibration:RTNormalization:RANSACMaxPercentRTThreshold` (similarity 0.75)  [ini fixture/autotest]
- **rename** `OpenSwathWorkflow:1:RTNormalization:RANSACMaxPercentRTThreshold` -> `OpenSwathWorkflow:1:Calibration:RTNormalization:RANSACMaxIterations` (similarity 0.75)  [ini fixture/autotest]
- **rename** `OpenSwathWorkflow:1:RTNormalization:lowess:span` -> `OpenSwathWorkflow:1:Calibration:RTNormalization:lowess:auto_span_min` (similarity 0.82)  [ini fixture/autotest]
- **rename** `OpenSwathWorkflow:1:RTNormalization:outlierMethod` -> `OpenSwathWorkflow:1:Calibration:RTNormalization:alignmentMethod` (similarity 0.80)  [ini fixture/autotest]
- **rename** `OpenSwathWorkflow:1:out_osw` -> `OpenSwathWorkflow:1:out_mobilogram` (similarity 0.82)  [ini fixture/autotest]
- **+** `OpenSwathWorkflow:1:Calibration:MassIMCorrection:im_correction_function` (string)
- **+** `OpenSwathWorkflow:1:Calibration:MassIMCorrection:im_estimation_padding_factor` (double)
- **+** `OpenSwathWorkflow:1:Calibration:MassIMCorrection:im_estimation_percentile` (double)
- **+** `OpenSwathWorkflow:1:Calibration:MassIMCorrection:im_extraction_window` (double)
- **+** `OpenSwathWorkflow:1:Calibration:MassIMCorrection:ms1_im_calibration` (bool)
- **+** `OpenSwathWorkflow:1:Calibration:MassIMCorrection:mz_estimation_padding_factor` (double)
- **+** `OpenSwathWorkflow:1:Calibration:MassIMCorrection:mz_estimation_percentile` (double)
- **+** `OpenSwathWorkflow:1:Calibration:MassIMCorrection:mz_extraction_window` (double)
- **+** `OpenSwathWorkflow:1:Calibration:MassIMCorrection:mz_extraction_window_ppm` (bool)
- **+** `OpenSwathWorkflow:1:Calibration:RTNormalization:MinPeptidesPerBin` (int)
- **+** `OpenSwathWorkflow:1:Calibration:RTNormalization:RANSACSamplingSize` (int)
- **+** `OpenSwathWorkflow:1:Calibration:RTNormalization:b_spline:num_nodes` (int)
- **+** `OpenSwathWorkflow:1:Calibration:RTNormalization:estimateBestPeptides` (bool)
- **+** `OpenSwathWorkflow:1:Calibration:RTNormalization:lowess:auto_span` (string)
- **+** `OpenSwathWorkflow:1:Calibration:RTNormalization:lowess:auto_span_grid` (string)
- **+** `OpenSwathWorkflow:1:Calibration:RTNormalization:lowess:auto_span_max` (double)
- **+** `OpenSwathWorkflow:1:Calibration:RTNormalization:lowess:span` (double)
- **+** `OpenSwathWorkflow:1:Calibration:RTNormalization:useIterativeChauvenet` (bool)
- **+** `OpenSwathWorkflow:1:Calibration:auto_irt:enabled` (string)
- **+** `OpenSwathWorkflow:1:Calibration:auto_irt:irt_bins` (int)
- **+** `OpenSwathWorkflow:1:Calibration:auto_irt:irt_bins_nonlinear` (int)
- **+** `OpenSwathWorkflow:1:Calibration:auto_irt:irt_nonlinear_rt_extraction_window` (double)
- **+** `OpenSwathWorkflow:1:Calibration:auto_irt:irt_peptides_per_bin` (int)
- **+** `OpenSwathWorkflow:1:Calibration:auto_irt:irt_peptides_per_bin_nonlinear` (int)
- **+** `OpenSwathWorkflow:1:Calibration:auto_irt:irt_seed` (int)
- **+** `OpenSwathWorkflow:1:Calibration:auto_irt:linear_top_fraction` (double)
- **+** `OpenSwathWorkflow:1:Calibration:auto_irt:nonlinear_top_fraction` (double)
- **+** `OpenSwathWorkflow:1:Calibration:auto_irt:prefilter:enabled` (string)
- **+** `OpenSwathWorkflow:1:Calibration:auto_irt:prefilter:evidence_sources` (string)
- **+** `OpenSwathWorkflow:1:Calibration:auto_irt:prefilter:min_supported_precursors` (int)
- **+** `OpenSwathWorkflow:1:Calibration:auto_irt:prefilter:ms1_top_peaks_per_spectrum` (int)
- **+** `OpenSwathWorkflow:1:Calibration:auto_irt:prefilter:ms2_min_fragment_hits` (int)
- **+** `OpenSwathWorkflow:1:Calibration:auto_irt:prefilter:ms2_top_peaks_per_spectrum` (int)
- **+** `OpenSwathWorkflow:1:Calibration:auto_irt:prefilter:ms2_top_transitions_per_precursor` (int)
- **+** `OpenSwathWorkflow:1:Calibration:auto_irt:prefilter:peak_picking:PeakPickerHiRes:SignalToNoise:auto_max_percentile` (int)
- **+** `OpenSwathWorkflow:1:Calibration:auto_irt:prefilter:peak_picking:PeakPickerHiRes:SignalToNoise:auto_max_stdev_factor` (double)
- **+** `OpenSwathWorkflow:1:Calibration:auto_irt:prefilter:peak_picking:PeakPickerHiRes:SignalToNoise:auto_mode` (int)
- **+** `OpenSwathWorkflow:1:Calibration:auto_irt:prefilter:peak_picking:PeakPickerHiRes:SignalToNoise:bin_count` (int)
- **+** `OpenSwathWorkflow:1:Calibration:auto_irt:prefilter:peak_picking:PeakPickerHiRes:SignalToNoise:max_intensity` (int)
- **+** `OpenSwathWorkflow:1:Calibration:auto_irt:prefilter:peak_picking:PeakPickerHiRes:SignalToNoise:min_required_elements` (int)
- **+** `OpenSwathWorkflow:1:Calibration:auto_irt:prefilter:peak_picking:PeakPickerHiRes:SignalToNoise:noise_for_empty_window` (double)
- **+** `OpenSwathWorkflow:1:Calibration:auto_irt:prefilter:peak_picking:PeakPickerHiRes:SignalToNoise:win_len` (double)
- **+** `OpenSwathWorkflow:1:Calibration:auto_irt:prefilter:peak_picking:PeakPickerHiRes:SignalToNoise:write_log_messages` (string)
- **+** `OpenSwathWorkflow:1:Calibration:auto_irt:prefilter:peak_picking:PeakPickerHiRes:allow_missing_flank` (bool)
- **+** `OpenSwathWorkflow:1:Calibration:auto_irt:prefilter:peak_picking:PeakPickerHiRes:missing` (int)
- **+** `OpenSwathWorkflow:1:Calibration:auto_irt:prefilter:peak_picking:PeakPickerHiRes:report_FWHM` (bool)
- **+** `OpenSwathWorkflow:1:Calibration:auto_irt:prefilter:peak_picking:PeakPickerHiRes:report_FWHM_unit` (string)
- **+** `OpenSwathWorkflow:1:Calibration:auto_irt:prefilter:peak_picking:PeakPickerHiRes:signal_to_noise` (double)
- **+** `OpenSwathWorkflow:1:Calibration:auto_irt:prefilter:peak_picking:PeakPickerHiRes:spacing_difference` (double)
- **+** `OpenSwathWorkflow:1:Calibration:auto_irt:prefilter:peak_picking:PeakPickerHiRes:spacing_difference_gap` (double)
- **+** `OpenSwathWorkflow:1:Calibration:auto_irt:prefilter:peak_picking:enabled` (bool)
- **+** `OpenSwathWorkflow:1:Calibration:auto_irt:prefilter:peak_picking:use_gauss` (string)
- **+** `OpenSwathWorkflow:1:Calibration:files:linear_irt_file` (string)
- **+** `OpenSwathWorkflow:1:Calibration:files:nonlinear_irt_file` (string)
- **+** `OpenSwathWorkflow:1:Calibration:linear:outlier_detection` (string)
- **+** `OpenSwathWorkflow:1:Calibration:nonlinear:outlier_detection` (string)
- **+** `OpenSwathWorkflow:1:Calibration:qc:min_coverage` (double)
- **+** `OpenSwathWorkflow:1:Calibration:qc:min_rsq` (double)
- **+** `OpenSwathWorkflow:1:Calibration:rt_norm` (string)
- **+** `OpenSwathWorkflow:1:Calibration:tr_irt_priority_sampling` (string)
- **+** `OpenSwathWorkflow:1:Calibration:windows:estimate_im` (string)
- **+** `OpenSwathWorkflow:1:Calibration:windows:estimate_mz` (string)
- **+** `OpenSwathWorkflow:1:Calibration:windows:estimate_rt` (string)
- **+** `OpenSwathWorkflow:1:Calibration:windows:max_rt_window` (double)
- **+** `OpenSwathWorkflow:1:Calibration:windows:min_rt_window` (double)
- **+** `OpenSwathWorkflow:1:Calibration:windows:rt_estimation_padding_factor` (double)
- **+** `OpenSwathWorkflow:1:Calibration:windows:rt_percentile` (double)
- **+** `OpenSwathWorkflow:1:Library:prefilter:aggregation_method` (string)
- **+** `OpenSwathWorkflow:1:Library:prefilter:decoy_handling` (string)
- **+** `OpenSwathWorkflow:1:Library:prefilter:decoy_prefix` (string)
- **+** `OpenSwathWorkflow:1:Library:prefilter:enabled` (bool)
- **+** `OpenSwathWorkflow:1:Library:prefilter:evidence_sources` (string)
- **+** `OpenSwathWorkflow:1:Library:prefilter:min_supported_precursors` (int)
- **+** `OpenSwathWorkflow:1:Library:prefilter:ms1_top_peaks_per_spectrum` (int)
- **+** `OpenSwathWorkflow:1:Library:prefilter:ms2_min_fragment_hits` (int)
- **+** `OpenSwathWorkflow:1:Library:prefilter:ms2_top_peaks_per_spectrum` (int)
- **+** `OpenSwathWorkflow:1:Library:prefilter:ms2_top_transitions_per_precursor` (int)
- **+** `OpenSwathWorkflow:1:Library:prefilter:peak_picking:PeakPickerHiRes:SignalToNoise:auto_max_percentile` (int)
- **+** `OpenSwathWorkflow:1:Library:prefilter:peak_picking:PeakPickerHiRes:SignalToNoise:auto_max_stdev_factor` (double)
- **+** `OpenSwathWorkflow:1:Library:prefilter:peak_picking:PeakPickerHiRes:SignalToNoise:auto_mode` (int)
- **+** `OpenSwathWorkflow:1:Library:prefilter:peak_picking:PeakPickerHiRes:SignalToNoise:bin_count` (int)
- **+** `OpenSwathWorkflow:1:Library:prefilter:peak_picking:PeakPickerHiRes:SignalToNoise:max_intensity` (int)
- **+** `OpenSwathWorkflow:1:Library:prefilter:peak_picking:PeakPickerHiRes:SignalToNoise:min_required_elements` (int)
- **+** `OpenSwathWorkflow:1:Library:prefilter:peak_picking:PeakPickerHiRes:SignalToNoise:noise_for_empty_window` (double)
- **+** `OpenSwathWorkflow:1:Library:prefilter:peak_picking:PeakPickerHiRes:SignalToNoise:win_len` (double)
- **+** `OpenSwathWorkflow:1:Library:prefilter:peak_picking:PeakPickerHiRes:SignalToNoise:write_log_messages` (string)
- **+** `OpenSwathWorkflow:1:Library:prefilter:peak_picking:PeakPickerHiRes:allow_missing_flank` (bool)
- **+** `OpenSwathWorkflow:1:Library:prefilter:peak_picking:PeakPickerHiRes:missing` (int)
- **+** `OpenSwathWorkflow:1:Library:prefilter:peak_picking:PeakPickerHiRes:report_FWHM` (bool)
- **+** `OpenSwathWorkflow:1:Library:prefilter:peak_picking:PeakPickerHiRes:report_FWHM_unit` (string)
- **+** `OpenSwathWorkflow:1:Library:prefilter:peak_picking:PeakPickerHiRes:signal_to_noise` (double)
- **+** `OpenSwathWorkflow:1:Library:prefilter:peak_picking:PeakPickerHiRes:spacing_difference` (double)
- **+** `OpenSwathWorkflow:1:Library:prefilter:peak_picking:PeakPickerHiRes:spacing_difference_gap` (double)
- **+** `OpenSwathWorkflow:1:Library:prefilter:peak_picking:enabled` (bool)
- **+** `OpenSwathWorkflow:1:Library:prefilter:peak_picking:use_gauss` (string)
- **+** `OpenSwathWorkflow:1:MRMMapping:error_on_unmapped` (bool)
- **+** `OpenSwathWorkflow:1:MRMMapping:irt_precursor_tolerance` (double)
- **+** `OpenSwathWorkflow:1:MRMMapping:irt_product_tolerance` (double)
- **+** `OpenSwathWorkflow:1:MRMMapping:map_multiple_assays` (bool)
- **+** `OpenSwathWorkflow:1:MRMMapping:precursor_tolerance` (double)
- **+** `OpenSwathWorkflow:1:MRMMapping:product_tolerance` (double)
- **+** `OpenSwathWorkflow:1:Scoring:TransitionGroupPicker:PeakPickerChromatogram:report_sn` (bool)
- **+** `OpenSwathWorkflow:1:Scoring:apply_im_peak_picking` (bool)
- **+** `OpenSwathWorkflow:1:Scoring:enzyme` (string)
- **+** `OpenSwathWorkflow:1:Scoring:irt_mz_extraction_window` (double)
- **+** `OpenSwathWorkflow:1:Scoring:irt_mz_extraction_window_unit` (string)
- **+** `OpenSwathWorkflow:1:Scoring:merge_spectra_by_peak_width_fraction` (double)
- **+** `OpenSwathWorkflow:1:Scoring:mz_extraction_window` (double)
- **+** `OpenSwathWorkflow:1:Scoring:mz_extraction_window_ms1` (double)
- **+** `OpenSwathWorkflow:1:Scoring:mz_extraction_window_ms1_unit` (string)
- **+** `OpenSwathWorkflow:1:Scoring:mz_extraction_window_unit` (string)
- **+** `OpenSwathWorkflow:1:Scoring:spectrum_merge_method_type` (string)
- **+** `OpenSwathWorkflow:1:append_oswpq` (bool)
- **+** `OpenSwathWorkflow:1:innerBatchSize` (int)
- **+** `OpenSwathWorkflow:1:keep_cached_files` (bool)
- **+** `OpenSwathWorkflow:1:maxConcurrentSwaths` (int)
- **+** `OpenSwathWorkflow:1:out_features_type` (string)
- **-** `OpenSwathWorkflow:1:Calibration:ms1_im_calibration` (bool)  [ini fixture/autotest]
- **-** `OpenSwathWorkflow:1:RTNormalization:MinPeptidesPerBin` (int)  [ini fixture/autotest]
- **-** `OpenSwathWorkflow:1:RTNormalization:RANSACSamplingSize` (int)  [ini fixture/autotest]
- **-** `OpenSwathWorkflow:1:RTNormalization:alignmentMethod` (string)  [ini fixture/autotest]
- **-** `OpenSwathWorkflow:1:RTNormalization:b_spline:num_nodes` (int)  [ini fixture/autotest]
- **-** `OpenSwathWorkflow:1:RTNormalization:estimateBestPeptides` (bool)  [ini fixture/autotest]
- **-** `OpenSwathWorkflow:1:RTNormalization:useIterativeChauvenet` (bool)  [ini fixture/autotest]
- **-** `OpenSwathWorkflow:1:Scoring:Scores:use_sonar_scores` (bool)  [ini fixture/autotest]
- **-** `OpenSwathWorkflow:1:min_coverage` (double)  [ini fixture/autotest]
- **-** `OpenSwathWorkflow:1:min_rsq` (double)  [ini fixture/autotest]
- **-** `OpenSwathWorkflow:1:mz_correction_function` (string)  [ini fixture/autotest]
- **-** `OpenSwathWorkflow:1:out_tsv` (output-file)  [ini fixture/autotest]
- **-** `OpenSwathWorkflow:1:rt_norm` (input-file)  [ini fixture/autotest]
- **-** `OpenSwathWorkflow:1:sonar` (bool)  [ini fixture/autotest]
- **-** `OpenSwathWorkflow:1:tr_irt` (input-file)  [ini fixture/autotest]
- **-** `OpenSwathWorkflow:1:tr_irt_nonlinear` (input-file)  [ini fixture/autotest]
- **~** `OpenSwathWorkflow:1:Scoring:Scores:use_ion_mobility_scores`  type: `bool` -> `string`; advanced: `true` -> `false`; restrictions: `-` -> `true,false,auto`; default: `false` -> `auto`  [wrapper structure; behaviour; wrapper structure]
- **~** `OpenSwathWorkflow:1:batchSize`  default: `1000` -> `0`  [behaviour]
- **~** `OpenSwathWorkflow:1:out_chrom`  formats: `*.mzML,*.sqMass` -> `*.mzML,*.sqMass,*.xic`  [filetypes.txt; filetypes.txt MISSING: xic]
- **~** `OpenSwathWorkflow:1:out_features`  formats: `*.featureXML` -> `*.osw,*.featureXML,*.oswpq`  [filetypes.txt; filetypes.txt MISSING: oswpq]
- **~** `OpenSwathWorkflow:1:tr`  formats: `*.traML,*.tsv,*.pqp` -> `*.traML,*.tsv,*.pqp,*.oswpq`  [filetypes.txt; filetypes.txt MISSING: oswpq]
- **~** `OpenSwathWorkflow:1:tr_type`  restrictions: `traML,tsv,pqp` -> `traML,tsv,pqp,oswpq`  [autotest]

### `PSMFeatureExtractor`

- **+** `PSMFeatureExtractor:1:in` (input-file)  [filetypes.txt MISSING: idparquet]
- **-** `PSMFeatureExtractor:1:concat` (bool)  [ini fixture/autotest]
- **-** `PSMFeatureExtractor:1:impute` (bool)  [ini fixture/autotest]
- **-** `PSMFeatureExtractor:1:limit_imputation` (bool)  [ini fixture/autotest]
- **-** `PSMFeatureExtractor:1:multiple_search_engines` (bool)  [ini fixture/autotest]
- **-** `PSMFeatureExtractor:1:skip_db_check` (bool)  [ini fixture/autotest]
- **~** `PSMFeatureExtractor:1:out`  formats: `*.idXML,*.mzid` -> `*.idXML,*.mzid,*.idparquet`  [filetypes.txt; filetypes.txt MISSING: idparquet]
- **~** `PSMFeatureExtractor:1:out_type`  restrictions: `idXML,mzid` -> `idXML,mzid,idparquet`  [autotest]

### `PeakPickerHiRes`

- **+** `PeakPickerHiRes:1:algorithm:allow_missing_flank` (bool)

### `PeptideIndexer`

- **~** `PeptideIndexer:1:enzyme:name`  restrictions: `auto,Arg-C/P,Asp-N,Asp-N/B,V8-DE,V8-E,leukocyte elastase,proline endopeptidase,Asp-N_ambic,Chymotrypsin,Chymotrypsin/P,CNBr,Formic_acid,glutamyl endopeptidase,Alpha-lytic protease,2-iodobenzoate,iodosobenzoate,staphylococcal protease/D,proline-endopeptidase/HKR,Glu-C+P,PepsinA + P,cyanogen-bromide,Clostripain/P,elastase-trypsin-chymotrypsin,no cleavage,Trypsin,Arg-C,Lys-C,Lys-N,unspecific cleavage,Lys-C/P,PepsinA,TrypChymo,Trypsin/P` -> `auto,proline endopeptidase,glutamyl endopeptidase,Alpha-lytic protease,2-iodobenzoate,iodosobenzoate,staphylococcal protease/D,proline-endopeptidase/HKR,Glu-C+P,PepsinA + P,cyanogen-bromide,Clostripain/P,elastase-trypsin-chymotrypsin,no cleavage,unspecific cleavage,Lys-C/P,PepsinA,TrypChymo,Trypsin/P,V8-DE,V8-E,leukocyte elastase,Arg-C/P,Asp-N,Asp-N/B,Asp-N_ambic,Chymotrypsin,Chymotrypsin/P,CNBr,Formic_acid,Lys-C,Lys-N,Trypsin,Arg-C`  [autotest]
- **~** `PeptideIndexer:1:fasta`  formats: `*.fasta` -> `*.fasta,*.fa,*.faa`  [filetypes.txt; filetypes.txt MISSING: faa]
- **~** `PeptideIndexer:1:in`  formats: `*.idXML` -> `*.idXML,*.idparquet`  [filetypes.txt; filetypes.txt MISSING: idparquet]
- **~** `PeptideIndexer:1:out`  formats: `*.idXML` -> `*.idXML,*.idparquet`  [filetypes.txt; filetypes.txt MISSING: idparquet]

### `PercolatorAdapter`

- **+** `PercolatorAdapter:1:best_per_spectrum_only` (bool)
- **+** `PercolatorAdapter:1:score:fdr` (double)
- **+** `PercolatorAdapter:1:use_subprocess` (bool)
- **~** `PercolatorAdapter:1:fasta`  formats: `*.FASTA` -> `*.FASTA,*.fa,*.faa`  [filetypes.txt; filetypes.txt MISSING: faa]
- **~** `PercolatorAdapter:1:out`  formats: `*.idXML,*.mzid,*.osw` -> `*.idXML,*.mzid,*.osw,*.idparquet`  [filetypes.txt; filetypes.txt MISSING: idparquet]
- **~** `PercolatorAdapter:1:out_type`  restrictions: `mzid,idXML,osw` -> `mzid,idXML,osw,idparquet`  [autotest]
- **~** `PercolatorAdapter:1:percolator_executable`  required: `true` -> `false`  [wrapper structure]

### `ProteinInference`

- **+** `ProteinInference:1:Algorithm:score_type` (string)

### `ProteinQuantifier`

- **rename** `ProteinQuantifier:1:best_charge_and_fraction` -> `ProteinQuantifier:1:best_charge` (similarity 0.83)  [ini fixture/autotest]
- **+** `ProteinQuantifier:1:file_and_channel_level_output` (bool)
- **+** `ProteinQuantifier:1:fractions:aggregate` (string)
- **+** `ProteinQuantifier:1:out_qpx` (output-dir)
- **-** `ProteinQuantifier:1:ratios` (bool)  [ini fixture/autotest]
- **-** `ProteinQuantifier:1:ratiosSILAC` (bool)  [ini fixture/autotest]

### `ProteomicsLFQ`

- **rename** `ProteomicsLFQ:1:PeptideQuantification:extract:rt_quantile` -> `ProteomicsLFQ:1:PeptideQuantification:extract:IM_window` (similarity 0.86)  [ini fixture/autotest]
- **rename** `ProteomicsLFQ:1:PeptideQuantification:svm:epsilon` -> `ProteomicsLFQ:1:PeptideQuantification:seed_apex_rt_tolerance` (similarity 0.79)  [ini fixture/autotest]
- **rename** `ProteomicsLFQ:1:PeptideQuantification:svm:kernel` -> `ProteomicsLFQ:1:PeptideQuantification:faims:merge_features` (similarity 0.81)  [ini fixture/autotest]
- **rename** `ProteomicsLFQ:1:ProteinQuantification:best_charge_and_fraction` -> `ProteomicsLFQ:1:ProteinQuantification:best_charge` (similarity 0.88)  [ini fixture/autotest]
- **+** `ProteomicsLFQ:1:Alignment:align_algorithm:auto_reference` (string)
- **+** `ProteomicsLFQ:1:Alignment:align_algorithm:auto_reference_min_points` (int)
- **+** `ProteomicsLFQ:1:Alignment:model:lowess:auto_k_folds` (int)
- **+** `ProteomicsLFQ:1:Alignment:model:lowess:auto_metric` (string)
- **+** `ProteomicsLFQ:1:Alignment:model:lowess:auto_min_neighbors` (int)
- **+** `ProteomicsLFQ:1:Alignment:model:lowess:auto_span` (bool)
- **+** `ProteomicsLFQ:1:Alignment:model:lowess:auto_span_grid` (string)
- **+** `ProteomicsLFQ:1:Alignment:model:lowess:auto_span_max` (double)
- **+** `ProteomicsLFQ:1:Alignment:model:lowess:auto_span_min` (double)
- **+** `ProteomicsLFQ:1:Centroiding:allow_missing_flank` (bool)
- **+** `ProteomicsLFQ:1:PipEcho:distance_MZ:max_difference` (double)
- **+** `ProteomicsLFQ:1:PipEcho:distance_MZ:unit` (string)
- **+** `ProteomicsLFQ:1:PipEcho:fdr` (double)
- **+** `ProteomicsLFQ:1:PipEcho:local_rt:anchor_window` (double)
- **+** `ProteomicsLFQ:1:PipEcho:local_rt:anchors` (int)
- **+** `ProteomicsLFQ:1:PipEcho:local_rt:auto` (string)
- **+** `ProteomicsLFQ:1:PipEcho:local_rt:enabled` (string)
- **+** `ProteomicsLFQ:1:PipEcho:local_rt:fallback_window` (double)
- **+** `ProteomicsLFQ:1:PipEcho:local_rt:max_window` (double)
- **+** `ProteomicsLFQ:1:PipEcho:local_rt:median_fwhm` (double)
- **+** `ProteomicsLFQ:1:PipEcho:local_rt:min_window` (double)
- **+** `ProteomicsLFQ:1:PipEcho:local_rt:rt_score` (string)
- **+** `ProteomicsLFQ:1:PipEcho:local_rt:sigma_scale` (double)
- **+** `ProteomicsLFQ:1:PipEcho:max_training_points` (int)
- **+** `ProteomicsLFQ:1:PipEcho:min_decoys` (int)
- **+** `ProteomicsLFQ:1:PipEcho:random_seed` (int)
- **+** `ProteomicsLFQ:1:ProteinQuantification:fractions:aggregate` (string)
- **+** `ProteomicsLFQ:1:Seeding:Biosaur2:cmax` (int)
- **+** `ProteomicsLFQ:1:Seeding:Biosaur2:cmin` (int)
- **+** `ProteomicsLFQ:1:Seeding:Biosaur2:convex_hulls` (string)
- **+** `ProteomicsLFQ:1:Seeding:Biosaur2:faims_merge_features` (string)
- **+** `ProteomicsLFQ:1:Seeding:Biosaur2:hrttol` (double)
- **+** `ProteomicsLFQ:1:Seeding:Biosaur2:htol` (double)
- **+** `ProteomicsLFQ:1:Seeding:Biosaur2:hvf` (double)
- **+** `ProteomicsLFQ:1:Seeding:Biosaur2:ignore_iso_calib` (bool)
- **+** `ProteomicsLFQ:1:Seeding:Biosaur2:itol` (double)
- **+** `ProteomicsLFQ:1:Seeding:Biosaur2:iuse` (int)
- **+** `ProteomicsLFQ:1:Seeding:Biosaur2:ivf` (double)
- **+** `ProteomicsLFQ:1:Seeding:Biosaur2:maxmz` (double)
- **+** `ProteomicsLFQ:1:Seeding:Biosaur2:mini` (double)
- **+** `ProteomicsLFQ:1:Seeding:Biosaur2:minlh` (int)
- **+** `ProteomicsLFQ:1:Seeding:Biosaur2:minmz` (double)
- **+** `ProteomicsLFQ:1:Seeding:Biosaur2:nm` (bool)
- **+** `ProteomicsLFQ:1:Seeding:Biosaur2:pasefmini` (double)
- **+** `ProteomicsLFQ:1:Seeding:Biosaur2:pasefminlh` (int)
- **+** `ProteomicsLFQ:1:Seeding:Biosaur2:paseftol` (double)
- **+** `ProteomicsLFQ:1:Seeding:Biosaur2:profile` (bool)
- **+** `ProteomicsLFQ:1:Seeding:Biosaur2:tof` (bool)
- **+** `ProteomicsLFQ:1:Seeding:Biosaur2:use_hill_calib` (bool)
- **+** `ProteomicsLFQ:1:Seeding:algorithm` (string)
- **+** `ProteomicsLFQ:1:detect_only` (bool)
- **+** `ProteomicsLFQ:1:feat_dir` (output-dir)
- **+** `ProteomicsLFQ:1:force_recompute` (bool)
- **+** `ProteomicsLFQ:1:out_qpx` (output-dir)
- **+** `ProteomicsLFQ:1:pip_echo` (bool)
- **-** `ProteomicsLFQ:1:PeptideQuantification:svm:cache_size` (double)  [ini fixture/autotest]
- **-** `ProteomicsLFQ:1:PeptideQuantification:svm:min_prob` (double)  [ini fixture/autotest]
- **-** `ProteomicsLFQ:1:PeptideQuantification:svm:no_selection` (bool)  [ini fixture/autotest]
- **-** `ProteomicsLFQ:1:PeptideQuantification:svm:no_shrinking` (bool)  [ini fixture/autotest]
- **-** `ProteomicsLFQ:1:PeptideQuantification:svm:predictors` (string)  [ini fixture/autotest]
- **-** `ProteomicsLFQ:1:PeptideQuantification:svm:samples` (int)  [ini fixture/autotest]
- **-** `ProteomicsLFQ:1:PeptideQuantification:svm:xval` (int)  [ini fixture/autotest]
- **-** `ProteomicsLFQ:1:PeptideQuantification:svm:xval_out` (output-file)  [ini fixture/autotest]
- **-** `ProteomicsLFQ:1:out_triqler` (output-file)  [ini fixture/autotest]
- **~** `ProteomicsLFQ:1:PeptideQuantification:EMGScoring:init_mom`  type: `bool` -> `string`; restrictions: `-` -> `true,false`; default: `false` -> `true`  [behaviour; wrapper structure]
- **~** `ProteomicsLFQ:1:alignment_order`  restrictions: `star` -> `star,tree_guided`  [autotest]
- **~** `ProteomicsLFQ:1:fasta`  formats: `*.fasta` -> `*.fasta,*.fa,*.faa`  [filetypes.txt; filetypes.txt MISSING: faa]
- **~** `ProteomicsLFQ:1:out`  required: `true` -> `false`  [wrapper structure]

### `QualityControl`

- **+** `QualityControl:1:out_txt:directory` (output-dir)
- **+** `QualityControl:1:out_txt:omit_mq_evidence` (bool)
- **+** `QualityControl:1:out_txt:omit_mq_msms` (bool)
- **-** `QualityControl:1:out_evd` (string)  [ini fixture/autotest]
- **-** `QualityControl:1:out_msms` (string)  [ini fixture/autotest]
- **~** `QualityControl:1:in_contaminants`  formats: `*.fasta` -> `*.fasta,*.fa,*.faa`  [filetypes.txt; filetypes.txt MISSING: faa]
- **~** `QualityControl:1:in_fasta`  formats: `*.fasta` -> `*.fasta,*.fa,*.faa`  [filetypes.txt; filetypes.txt MISSING: faa]

### `RNADigestor`

- **~** `RNADigestor:1:enzyme`  restrictions: `RNase_U2,RNase_A,RNase_MC1,RNase_H,RNase_4,RNase_4p,mazF,colicin_E5,no cleavage,unspecific cleavage,RNase_T1,cusativin,RNase_T1_Phosphatase` -> `RNase_4,RNase_4p,RNase_4c,mazF,colicin_E5,no cleavage,RNase_U2,RNase_A,RNase_MC1,RNase_H,unspecific cleavage,RNase_T1,RNase_T1_Phosphatase,cusativin`  [autotest]
- **~** `RNADigestor:1:in`  formats: `*.fasta` -> `*.fasta,*.fa,*.faa`  [filetypes.txt; filetypes.txt MISSING: faa]

### `SageAdapter`

- **+** `SageAdapter:1:annotate_matches` (string)
- **+** `SageAdapter:1:chimera` (string)
- **+** `SageAdapter:1:deisotope` (string)
- **+** `SageAdapter:1:predict_rt` (string)
- **+** `SageAdapter:1:q_value_threshold` (double)
- **+** `SageAdapter:1:smoothing` (string)
- **+** `SageAdapter:1:wide_window` (string)
- **~** `SageAdapter:1:PeptideIndexing:enzyme:name`  restrictions: `auto,Arg-C,Arg-C/P,Asp-N_ambic,Chymotrypsin,Chymotrypsin/P,Trypsin,PepsinA + P,cyanogen-bromide,Clostripain/P,elastase-trypsin-chymotrypsin,no cleavage,unspecific cleavage,Lys-N,Lys-C/P,PepsinA,TrypChymo,Asp-N,Asp-N/B,CNBr,Formic_acid,Lys-C,Trypsin/P,V8-DE,V8-E,leukocyte elastase,proline endopeptidase,glutamyl endopeptidase,Alpha-lytic protease,2-iodobenzoate,iodosobenzoate,staphylococcal protease/D,proline-endopeptidase/HKR,Glu-C+P` -> `auto,Clostripain/P,unspecific cleavage,no cleavage,elastase-trypsin-chymotrypsin,Glu-C+P,proline-endopeptidase/HKR,cyanogen-bromide,staphylococcal protease/D,Arg-C,PepsinA + P,iodosobenzoate,proline endopeptidase,leukocyte elastase,V8-E,V8-DE,Trypsin,Trypsin/P,TrypChymo,2-iodobenzoate,PepsinA,Asp-N/B,Alpha-lytic protease,Arg-C/P,glutamyl endopeptidase,Lys-C/P,Lys-N,Lys-C,Formic_acid,CNBr,Chymotrypsin/P,Chymotrypsin,Asp-N_ambic,Asp-N`  [autotest]
- **~** `SageAdapter:1:database`  formats: `*.FASTA` -> `*.FASTA,*.fa,*.faa`  [filetypes.txt; filetypes.txt MISSING: faa]
- **~** `SageAdapter:1:enzyme`  restrictions: `Arg-C/P,Asp-N,Asp-N/B,Trypsin,Arg-C,staphylococcal protease/D,proline-endopeptidase/HKR,Glu-C+P,PepsinA + P,cyanogen-bromide,Clostripain/P,elastase-trypsin-chymotrypsin,no cleavage,unspecific cleavage,leukocyte elastase,proline endopeptidase,Asp-N_ambic,Chymotrypsin,Chymotrypsin/P,CNBr,Formic_acid,Lys-C,Lys-N,Lys-C/P,PepsinA,TrypChymo,Trypsin/P,V8-DE,V8-E,glutamyl endopeptidase,Alpha-lytic protease,2-iodobenzoate,iodosobenzoate` -> `Formic_acid,Lys-C,Lys-N,Lys-C/P,PepsinA,TrypChymo,Trypsin/P,Asp-N/B,Asp-N_ambic,Trypsin,Arg-C/P,Asp-N,Arg-C,Chymotrypsin,Chymotrypsin/P,CNBr,V8-DE,V8-E,leukocyte elastase,proline endopeptidase,glutamyl endopeptidase,Alpha-lytic protease,2-iodobenzoate,iodosobenzoate,staphylococcal protease/D,proline-endopeptidase/HKR,Glu-C+P,PepsinA + P,cyanogen-bromide,Clostripain/P,elastase-trypsin-chymotrypsin,no cleavage,unspecific cleavage`  [autotest]
- **~** `SageAdapter:1:out`  formats: `*.idXML` -> `*.idXML,*.idparquet`  [filetypes.txt; filetypes.txt MISSING: idparquet]

### `SequenceCoverageCalculator`

- **~** `SequenceCoverageCalculator:1:in_database`  formats: `*.fasta` -> `*.fasta,*.fa,*.faa`  [filetypes.txt; filetypes.txt MISSING: faa]
- **~** `SequenceCoverageCalculator:1:out`  formats: `*.txt` -> `*.idXML`  [hardcoded_params.json (review); filetypes.txt]

### `SimpleSearchEngine`

- **+** `SimpleSearchEngine:1:Search:FDR:PSM` (double)
- **+** `SimpleSearchEngine:1:Search:peptide:enzyme_specificity` (string)
- **~** `SimpleSearchEngine:1:Search:enzyme`  restrictions: `glutamyl endopeptidase,Alpha-lytic protease,2-iodobenzoate,iodosobenzoate,staphylococcal protease/D,proline-endopeptidase/HKR,Glu-C+P,Arg-C,Arg-C/P,Asp-N,Asp-N/B,Asp-N_ambic,Formic_acid,Lys-C,Lys-N,Lys-C/P,PepsinA,Trypsin,Chymotrypsin,Chymotrypsin/P,CNBr,V8-DE,V8-E,leukocyte elastase,proline endopeptidase,TrypChymo,Trypsin/P,PepsinA + P,cyanogen-bromide,Clostripain/P,elastase-trypsin-chymotrypsin,no cleavage,unspecific cleavage` -> `V8-E,2-iodobenzoate,Alpha-lytic protease,glutamyl endopeptidase,proline-endopeptidase/HKR,cyanogen-bromide,PepsinA + P,elastase-trypsin-chymotrypsin,Glu-C+P,iodosobenzoate,staphylococcal protease/D,Clostripain/P,proline endopeptidase,Asp-N/B,Lys-N,Lys-C/P,Asp-N_ambic,PepsinA,Chymotrypsin,Trypsin,V8-DE,Arg-C,Arg-C/P,leukocyte elastase,Chymotrypsin/P,Asp-N,CNBr,Formic_acid,Lys-C,TrypChymo,Trypsin/P,no cleavage,unspecific cleavage`  [autotest]
- **~** `SimpleSearchEngine:1:database`  formats: `*.fasta` -> `*.fasta,*.fa,*.faa`  [filetypes.txt; filetypes.txt MISSING: faa]

### `SpectraSTSearchAdapter`

- **~** `SpectraSTSearchAdapter:1:sequence_database_file`  formats: `*.fasta` -> `*.fasta,*.fa,*.faa`  [filetypes.txt; filetypes.txt MISSING: faa]

### `TargetedFileConverter`

- **~** `TargetedFileConverter:1:in`  formats: `*.tsv,*.mrm,*.pqp,*.TraML` -> `*.tsv,*.mrm,*.pqp,*.TraML,*.oswpq`  [filetypes.txt; filetypes.txt MISSING: oswpq]
- **~** `TargetedFileConverter:1:out`  formats: `*.tsv,*.pqp,*.TraML` -> `*.tsv,*.pqp,*.TraML,*.oswpq`  [filetypes.txt; filetypes.txt MISSING: oswpq]
- **~** `TargetedFileConverter:1:out_type`  restrictions: `tsv,pqp,TraML` -> `tsv,pqp,TraML,oswpq`  [autotest]

### `TextExporter`

- **+** `TextExporter:1:id:add_usi` (bool)
- **+** `TextExporter:1:id:annotations` (string)
- **+** `TextExporter:1:id:usi_dataset_id` (string)
- **+** `TextExporter:1:xic:mode` (string)
- **~** `TextExporter:1:in`  formats: `*.featureXML,*.consensusXML,*.idXML,*.mzML` -> `*.featureXML,*.featureparquet,*.consensusXML,*.consensusparquet,*.idXML,*.idparquet,*.mzML,*.xic`  [filetypes.txt; filetypes.txt MISSING: featureparquet,consensusparquet,idparquet,xic]

### `XMLValidator`

- **~** `XMLValidator:1:in`  formats: `*.mzML,*.mzData,*.featureXML,*.mzid,*.idXML,*.consensusXML,*.mzXML,*.ini,*.pepXML,*.traML,*.xml` -> `*.mzML,*.mzData,*.featureXML,*.mzid,*.idXML,*.consensusXML,*.mzXML,*.ini,*.pepXML,*.pep.xml,*.traML,*.xml`  [filetypes.txt; filetypes.txt MISSING: ini]

