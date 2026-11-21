Deprecated OpenMS wrappers
==========================

Wrappers for tools that OpenMS no longer ships, kept for reference so that an
old analysis can still be understood (and restored). They are not linted,
tested or installed by CI — `deprecated/**` is excluded in
`.github/workflows/pr.yaml`.

Layout: one directory per state of the wrapper suite the wrappers were archived
from, each self-contained (`<import>macros.xml</import>` and
`$__tool_directory__/fill_ctd.py` resolve inside the directory). Test data is
not included.

`3.1/` — the last suite that still contained these tools; archived when OpenMS
3.2 removed them:

| tool | last shipped in |
|---|---|
| ERPairFinder | 3.1 |
| FeatureFinderIsotopeWavelet | 3.1 |
| FeatureFinderMRM | 3.1 |
| MapAlignerSpectrum | 3.1 |
| PeakPickerWavelet | 3.1 |
| PrecursorMassCorrector | 3.1 |
| ProteinResolver | 3.1 |
| RNPxlSearch | 3.1 |
| SiriusAdapter | 3.1 (replaced by `SiriusExport` and `AssayGeneratorMetaboSirius`) |
| SpectraFilterBernNorm | 3.1 |
| SpectraFilterMarkerMower | 3.1 |
| SpectraFilterParentPeakMower | 3.1 |
| SpectraFilterScaler | 3.1 |
| SpectraFilterSqrtMower | 3.1 |
| TOFCalibration | 3.1 |

`3.2/` — archived when upgrading the suite from OpenMS 3.2 to 3.6; the wrappers
are the 3.2-generated ones (that is the version their `macros.xml` pins), while
the tools themselves survived into later releases:

| tool | last shipped in |
|---|---|
| MascotAdapter | 3.3 |
| XTandemAdapter | 3.3 |
| IDMassAccuracy | 3.4 |
| OpenPepXLLF | 3.4 |
| SpecLibCreator | 3.4 |
| SpecLibSearcher | 3.4 |
| TriqlerConverter | 3.5 |

If a wrapper is needed again, install it from the ToolShed (older suite
revisions are still available there) or restore it from this directory — for the
`3.2/` group, note that the requirements pin 3.2 and that a tool removed in 3.5
only exists up to 3.4 upstream.
