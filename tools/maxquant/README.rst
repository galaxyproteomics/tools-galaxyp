
GalaxyP - MaxQuant
==================


* Home: https://github.com/galaxyproteomics/tools-galaxyp/
* Tool ID: ``maxquant``
* Tool Type: ``default``

Description
-----------

Wrapper for the MaxQuant version available in conda.

Updating
--------

MaxQuant often changes the layout of its parameters file.
So changes to the code are likely to be necessary when
updating to a new version of MaxQuant. The init.py script
can be used to initialize the tool with a new list of
modifications or enzymes. From the tool dir run:

./init.py -m MODIFICATIONS.XML -e ENZYMES.XML

The location of these xml files usually is:
ANACONDA_DIR/bin/conf/
