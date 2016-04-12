GalaxyP - Percolator
=======================

- Home: <https://github.com/galaxyproteomics/tools-galaxyp/>
- Galaxy Tool Shed: <http://toolshed.g2.bx.psu.edu/view/galaxyp/percolator
- Tool ID: `percolator`, `percolator_converters`


Description
-----------
The first step in analyzing an mass spectrometry assay is to match the harvested spectra against a target database using database search engines such as Sequest and Mascot, a process that renders list of peptide-spectrum matches. However, it is not trivial to assess the accuracy of these identifications.

Percolator uses a semi-supervised machine learning to discriminate correct from incorrect peptide-spectrum matches, and calculates accurate statistics such as q-value (FDR) and posterior error probabilities. 

This package contains percolator and includes its converter msgf2pin to be able to convert mzIdentML data from MSGF+ to percolator input data. It further contains a metafile-creator to be able to combine fractionated search results into batches of specific amount of fractions to create percolator input data of.


GalaxyP Community
-----------------

Current governing community policies for GalaxyP_ and other information can be found at:

<https://github.com/galaxyproteomics>

.. _GalaxyP: https://github.com/galaxyproteomics/


Contributing
------------

Contributions to this repository are reviewed through pull requests. If you would like your work acknowledged, please also add yourself to the Authors section. If your pull request is accepted, you will also be acknowledged in <https://github.com/galaxyproteomics/tools-galaxyp/>


Authors
-------

Authors and contributors:

* Jorrit Boekel
