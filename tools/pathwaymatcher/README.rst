PathwayMatcher
=======================

- Home: <https://github.com/LuisFranciscoHS/PathwayMatcher/>
- Galaxy Tool Shed: <http://toolshed.g2.bx.psu.edu/view/galaxyp/pathwaymatcher>
- Tools ID: `pathwaymatcher`


Description
-----------

PathwayMatcher is a software tool written in Java to search for pathways related to a list of proteins in Reactome.


General Requirements
--------------------

This tool requires a Java runtime 1.6 or greater to work. To avoid out of memory errors you should set the maximum heapspace for java processes as the default is most likely too small. For example, to set this in your shell:

    export _JAVA_OPTIONS='-Xmx1500M'

On some systems you may also need to adjust the amount of memory available for class definitions in addition to the maximum heapspace. For example:

	export _JAVA_OPTIONS='-Xmx1500M -XX:MaxPermSize=256M'

It is also possible to set this on a per tool basis using advanced features of the galaxy job config system.


License
-------

PathwayMatcher is a free open-source project, following an Apache License 2.0.


Authors
-------

Authors and contributors:

* Luis Francisco Hernández Sánchez <luis.sanchez@uib.no>
* Carlos Horro Marcos <carlos.horro@uib.no>
