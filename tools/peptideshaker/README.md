GalaxyP - PeptideShaker
=======================

* Home: <https://github.com/galaxyproteomics/tools-galaxyp/>
* Galaxy Tool Shed: <http://toolshed.g2.bx.psu.edu/view/galaxyp/peptideshaker>
* Tool ID: `peptideshaker`, `search_gui`


Description
-----------

Perform protein identification combining X! Tandem and OMSSA (using SearchGUI) and PeptideShaker pipeline.

Tool wrapper for SearchGUI and PeptideShaker. This tool takes any number of mgf files and performs X! Tandem and OMSSA searches on these via SearchGUI and merges the results using PeptideShaker.


Configuration
-------------

This tool requires a Java runtime 1.6 or greater to work. To avoid out of memory errors you should set the maximum heapspace for java processes as the default is most likely too small. For example, to set this in your shell:

    export _JAVA_OPTIONS='-Xmx1500M'

It is also possible to set this on a per tool basis using advanced features of the galaxy job config system.

Note:

- PeptideShaker may require xvfb to simulate an X environment if this is installed on a headless server.

See:

* <https://code.google.com/p/peptide-shaker/>
* <https://code.google.com/p/searchgui/>


GalaxyP Community
-----------------

Current governing community policies for [GalaxyP](https://github.com/galaxyproteomics/) and other information can be found at:

<https://github.com/galaxyproteomics>


License
-------

Copyright (c) 2014 Regents of the University of Minnesota and Authors listed below.

To the extent possible under law, the author(s) have dedicated all copyright and related and neighboring rights to this software to the public domain worldwide. This software is distributed without any warranty.

You should have received a copy of the CC0 Public Domain Dedication along with this software. If not, see <https://creativecommons.org/publicdomain/zero/1.0/>.

You can copy, modify, distribute and perform the work, even for commercial purposes, all without asking permission.


Contributing
------------

Contributions to this repository are reviewed through pull requests. If you would like your work acknowledged, please also add yourself to the Authors section. If your pull request is accepted, you will also be acknowledged in <https://github.com/galaxyproteomics/tools-galaxyp/>


Authors
-------

Authors and contributors:

* Bjoern Gruening <bjoern.gruening@gmail.com>
* Ira Cooke
* Cody Wang
* Fred Sadler
* John Chilton <jmchilton@gmail.com>
* Minnesota Supercomputing Institute, Univeristy of Minnesota
