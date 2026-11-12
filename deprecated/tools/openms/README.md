Deprecated OpenMS wrappers
==========================

These wrappers target **OpenMS 3.1** and are kept for reference only. They are
not linted, tested or installed by CI (`deprecated/**` is excluded in
`.github/workflows/pr.yaml`).

The corresponding tools were removed from OpenMS in release 3.2 and the
wrappers were therefore dropped from the active suite in `tools/openms/`:

- ERPairFinder
- FeatureFinderIsotopeWavelet
- FeatureFinderMRM
- MapAlignerSpectrum
- MascotAdapterOnline (already blacklisted for OpenMS 3.1)
- PeakPickerWavelet
- PrecursorMassCorrector
- ProteinResolver
- RNPxlSearch
- SiriusAdapter (replaced by `SiriusExport` and `AssayGeneratorMetaboSirius`)
- SpectraFilterBernNorm
- SpectraFilterMarkerMower
- SpectraFilterParentPeakMower
- SpectraFilterScaler
- SpectraFilterSqrtMower
- TOFCalibration

`macros.xml` and `fill_ctd.py` are copies of the OpenMS 3.1 versions from
`tools/openms/` so that the wrappers stay self-contained (`<import>macros.xml</import>`
and `$__tool_directory__/fill_ctd.py`). Test data is not included.

If a wrapper is needed again, install it from the ToolShed (older suite
revisions are still available there) or restore it from this directory.
