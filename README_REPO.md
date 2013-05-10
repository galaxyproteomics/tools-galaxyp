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
file.