GalaxyP - PeptideShaker
=======================

* Home: <https://bitbucket.org/galaxyp/peptideshaker>
* Galaxy Tool Shed: <http://toolshed.g2.bx.psu.edu/view/galaxyp/peptideshaker>
* Tool ID: `peptideshaker`
* Tool Type: `default`


Description
-----------

Peform protein identification combining X! Tandem and OMSSA (using SearchGUI) and PeptideShaker pipeline.

Tool wrapper for SearchGUI and PeptideShaker. This tool takes any number of mgf files and performs X! Tandem and OMSSA searches on these via SearchGUI and merges the results using PeptideShaker.

Note:

- SearchGUI requires a version greater than 1.12.2 which contained several bugs preventing this from working on the command-line and via Linux.

- PeptideShaker may require xvfb to simulate an X environment if this is installed on a headless server.

See:

* <https://code.google.com/p/peptide-shaker/>
* <https://code.google.com/p/searchgui/>


GalaxyP Community
-----------------

Current governing community policies for [GalaxyP](https://bitbucket.org/galaxyp/) and other information can be found at:

<https://bitbucket.org/galaxyp/galaxyp>


License
-------

Copyright (c) 2014 Regents of the University of Minnesota and Authors listed below.

To the extent possible under law, the author(s) have dedicated all copyright and related and neighboring rights to this software to the public domain worldwide. This software is distributed without any warranty.

You should have received a copy of the CC0 Public Domain Dedication along with this software. If not, see <https://creativecommons.org/publicdomain/zero/1.0/>.

You can copy, modify, distribute and perform the work, even for commercial purposes, all without asking permission.


Contributing
------------

Contributions to this repository are reviewed through pull requests. If you would like your work acknowledged, please also add yourself to the Authors section. If your pull request is accepted, you will also be acknowledged in <https://bitbucket.org/galaxyp/galaxyp/CONTRIBUTORS.md> unless you opt-out.


Authors
-------

Authors and contributors:

* Cody Wang
* Fred Sadler
* John Chilton <jmchilton@gmail.com>
* Minnesota Supercomputing Institute, Univeristy of Minnesota
