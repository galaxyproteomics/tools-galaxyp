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
