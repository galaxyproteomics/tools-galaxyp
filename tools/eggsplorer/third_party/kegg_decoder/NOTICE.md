# KEGG-Decoder (vendored, unmodified)

- File: `KEGG_decoder.py`, KEGG-Decoder V.1.3
- Upstream: https://github.com/bjtully/BioData/blob/master/KEGGDecoder/KEGG_decoder.py
- Licence: MIT, Copyright (c) 2019 Benjamin Tully (see `LICENSE` in this folder)
- Retrieved: 2026-10-22
- SHA256: fdc4bbc14d0dd457c5d4841a09c0c7e868c057a509f0428b10818777216b617c

The file is kept byte-for-byte identical to upstream. Only its scoring
functions are used, through `decoder_core.py`; its `main()`, plotting and
clustering code are never executed, so pandas, seaborn, matplotlib and scipy
are not needed for this part.

`function_map.json` is generated from this file by `decoder_core.py`
(sensitivity analysis of the scoring functions) and is keyed to the SHA256
above; it is rebuilt automatically if `KEGG_decoder.py` is replaced.

Issues found in V1.3 by that analysis (scores in the default mode keep them
so results match the published tool; `--corrected` fixes or flags them):
- `mixedacid`: alcohol dehydrogenase KOs never count (`==` instead of `=`).
- `pectinesterase`, `exo-poly-alpha-galacturonosidase`: no KO is checked.
- `sulfur`: 'thiosulfate disproportionation' is initialised but never scored
  and is not written to the output.
- Many complete functions score 0.99 or 0.98 because of weights such as
  3 x 0.33; a few score slightly above 1 (e.g. 6 x 0.167).

Please cite when using results from this module:
Graham ED, Heidelberg JF, Tully BJ (2018). Potential for primary productivity
in a globally-distributed bacterial phototroph. ISME J 12, 1861–1866.
