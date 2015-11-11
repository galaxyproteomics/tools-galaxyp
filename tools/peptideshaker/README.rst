GalaxyP - PeptideShaker
=======================

- Home: <https://github.com/galaxyproteomics/tools-galaxyp/>
- Galaxy Tool Shed: <http://toolshed.g2.bx.psu.edu/view/galaxyp/peptideshaker>
- Tool ID: `peptideshaker`, `search_gui`


Description
-----------

Perform protein identification combining numerous search engines (using SearchGUI) followed by peptide and protein inference with PeptideShaker.

Includes tool wrappers for SearchGUI and PeptideShaker. The SearchGUI tool takes any number of mgf files and performs searches on these.  It creates a large zip archive with all search results, the original database and spectra.  This can then be fed to the PeptideShaker tool which merges the results and performs peptide and protein inference.


General Requirements
--------------------

This tool requires a Java runtime 1.6 or greater to work. To avoid out of memory errors you should set the maximum heapspace for java processes as the default is most likely too small. For example, to set this in your shell:

    export _JAVA_OPTIONS='-Xmx1500M'

On some systems you may also need to adjust the amount of memory available for class definitions in addition to the maximum heapspace. For example:

	export _JAVA_OPTIONS='-Xmx1500M -XX:MaxPermSize=256M'

It is also possible to set this on a per tool basis using advanced features of the galaxy job config system.

MSAmanda on linux
-----------------

Running MS Amanda on Linux requires that you have Mono installed. Mono 3.2.1 or newer is required.  If you install via the toolshed Mono should be installed automatically, however if this does not work you can install it manually.
  
On ubuntu Mono can be installed as follows

	sudo apt-get install mono-runtime
	sudo apt-get install libmono-system-core4.0-cil

For more help on installing Mono please see http://www.mono-project.com/download. 

Note
----

- Requires Galaxy release v15.10 or later, which fixes the installation of package_peptideshaker_1_1 and provides a searchgui_archive datatype that includes a version

- PeptideShaker may require xvfb to simulate an X environment if this is installed on a headless server.

See:

* <https://code.google.com/p/peptide-shaker/>
* <https://code.google.com/p/searchgui/>


Search GUI - Fixed and Variable Modifications
-------------------------------------------

 - Options for modifications are read from local data file: searchgui_mods.loc
   This is copied from searchgui_mods.loc.sample on the first installation.  

The modifications are from:  https://github.com/compomics/compomics-utilities/blob/master/src/main/java/com/compomics/util/experiment/identification/search_parameters_cli/IdentificationParametersInputBean.java

GalaxyP Community
-----------------

Current governing community policies for GalaxyP_ and other information can be found at:

<https://github.com/galaxyproteomics>

.. _GalaxyP: https://github.com/galaxyproteomics/


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
* Gerben Menschaert
* Elvis Ndah
* Minnesota Supercomputing Institute, Univeristy of Minnesota
