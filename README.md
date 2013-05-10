Tool wrapper for SearchGUI + PeptideShaker. This tool takes any number
of mgf files and performs X! Tandem and OMSSA searches on these via
SearchGUI and merges the results using PeptideShaker.

For Galaxy-P we are installing this tool via CloudBioLinux
(https://github.com/jmchilton/cloudbiolinux/blob/proteomics/cloudbio/custom/bio_proteomics.py). While
this fabric script may not be exactly appropriate for your environment
it may serve as a template for how to install this software. In
particular these tools require CLI wrappers to be placed for
PeptideShaker and SearchGUI that can be installed as demostrated in
these fabric functions.

Note: Also SearchGUI requires a version greater than 1.12.2 which
contained several bugs preventing this from working on the
command-line and via Linux.

Also, PeptideShaker may require xvfb to simulate an X environment if
this is installed on a headless server.
# Obtaining Tools

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
