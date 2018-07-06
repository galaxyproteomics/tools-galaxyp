PathwayMatcher
=======================

- Home: <https://github.com/LuisFranciscoHS/PathwayMatcher/>
- Galaxy Tool Shed: <http://toolshed.g2.bx.psu.edu/view/galaxyp/reactome_pathwaymatcher>
- Tools ID: `reactome_pathwaymatcher`


Description
-----------

PathwayMatcher is a software tool written in Java to search for pathways related to a list of proteins in Reactome.


General Requirements
--------------------

This tool requires a Java runtime 1.8 or greater to work. To avoid out of memory errors you should set the maximum heapspace for java processes as the default is most likely too small. For example, to set this in your shell:

    export _JAVA_OPTIONS='-Xmx1500M'

It is also possible to set this on a per tool basis using advanced features of the galaxy job config system.


License
-------

PathwayMatcher is a free open-source project, following an Apache License 2.0.


Authors
-------

Authors and contributors:

* Luis Francisco Hernández Sánchez <luis.sanchez@uib.no>
* Carlos Horro Marcos <carlos.horro@uib.no>
