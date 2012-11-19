# msconvert

This repository contains Galaxy tool wrappers for msconvert, part of
the ProteoWizard (http://proteowizard.sourceforge.net/) package.

# Installing

Due to potential difficulties installing ProteoWizard with vendor
library support, tools for interacting with vendor types are seperated
out into their own wrappers. Galaxy is generally deployed under Linux,
but vendor support in ProteoWizard requires .NET 4.0. There are at
least two ways to get this to work:

  * Galaxy jobs may be configured to submit to a Windows host with
    ProteoWizard installed using the
    LWR. http://wiki.g2.bx.psu.edu/Admin/Config/LWR

  * ProteoWizard can be installed under Wine. Guidance on how to set
    this up and package such environments for cloud deployments can be
    found here: https://github.com/jmchilton/proteomics-wine-env

Wrappers for both msconvert version 2 and version 3+ are provided
because version 3+ of msconvert with vendor library support requires
.NET 4.0 and this may difficult or impossible under Wine in Linux with
all but the most recent versions of Wine (1.4+).
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
