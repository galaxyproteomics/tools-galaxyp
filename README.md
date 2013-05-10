Tool wrapper for MaxQuant. 

MaxQuant is a Windows only program and so you will likely need to
deploy this tool to run on a remote Windows system via the LWR
(https://lwr.readthedocs.org).

The sample mods file maxquant_mods.loc.sample corresponds to the
default modifications MaxQuant is configured with. The Galaxy-P
project uses a MaxQuant that has been extended with all of Unimod. To
modify MaxQuant in this fashion replace MaxQuant's modifications.xml
file with the extended_modifications.xml distributed with this tool
and configure Galaxy with the maxquant_mods.loc.sample.extended loc
file.# Obtaining Tools

Repositories for all Galaxy-P tools can be found at
https:/bitbucket.org/galaxyp/.

# Contact

Please send suggestions for improvements and bug reports to
jmchilton@gmail.com.

# License

All Galaxy-P tools are licensed under the Apache License Version 2.0
unless otherwise documented.

# Tool Versioning

Galaxy-P tools will have versions of the form X.Y.Z. Versions
differing only after the second decimal should be completely
compatible with each other. Breaking changes should result in an
increment of the number before and/or after the first decimal. All
tools of version less than 1.0.0 should be considered beta.
