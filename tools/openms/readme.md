Galaxy wrapper for OpenMS
=========================

OpenMS is an open-source software C++ library for LC/MS data management and analyses.
It offers an infrastructure for the rapid development of mass spectrometry related software.
OpenMS is free software available under the three clause BSD license and runs under Windows, MacOSX and Linux.

More informations are available at:

 * https://github.com/OpenMS/OpenMS
 * https://www.openms.de/

The wrappers for these tools and most of their tests are automatically
generated using the `generate.sh` script. The generation of the tools is
based on the CTDConverter (https://github.com/WorkflowConversion/CTDConverter)
which can be fine tuned via the `hardcoded_params.json` file. This file allows
to blacklist and hardcode parameters and to modify or set arbitrary
CTD/XML attributes.

Note that, due to its size, the test data is excluded from this repository. In
order to generate the test data on call `test-data.sh`.

Manual updates should only be done to

- and the manually contributed tests in `macros_test.xml` (The goal is that all
  tools that do not have an automatically generated test are covered here)
- the `hardcoded_params.json` files

Wrapper versions are managed in `bump.json`. For tools listed in the file
the wrapper version will be set accordingly and otherwise `0` is used. 
For a major update of the tool version the bump file should be reset (to `{}`).

In a few cases patches may be acceptable.

Installation
============

The Galaxy OpenMS tools can be installed from the toolshed. While most tools
will work out of the box some need attention since requirements can not be
fulfilled via Conda:

Not yet in Conda are:

- SpectraST (http://tools.proteomecenter.org/wiki/index.php?title=SpectraST)
- MaRaCluster (https://github.com/statisticalbiotechnology/maracluster)

Binaries for these tools can easily be obtained via: 

```
VERSION=....
git git clone -b release/$VERSION.0 https://github.com/OpenMS/OpenMS.git OpenMS$VERSION.0-git
git submodule init OpenMS$VERSION.0-git
git submodule update OpenMS$VERSION.0-git
```

They are located in `OpenMS$VERSION-git/THIRDPARTY/`. 

Not in Conda due to licencing restrictions:

- Mascot http://www.matrixscience.com/
- MSFragger https://github.com/Nesvilab/MSFragger
- Novor http://www.rapidnovor.org/novor

There are multiple ways to enable the Galaxy tools to use these binaries. 

- Just copy them to the `bin` path within Galaxy's conda environment
- Put them in any other path that that is included in PATH
- Edit the corresponding tools: In the command line part search for the parameters `-executable`, `-maracluster_executable`, or `-mascot_directory` and edit them appropriately.

Working
=======

The tools work by:

Preprocessing:

- For input data set parameters the links to the actual location of the data
  sets are created, the link names are `element_identifier`.`EXT`, where `EXT`
  is an extension that is known by OpenMS
- In order to avoid name collisions for the created links each is placed in a
  unique directory: `PARAM_NAME/DATASET_ID`, where `PARAM_NAME` is the name
  of the parameter and `DATASET_ID` is the id of the Galaxy dataset 
- the same happens for output parameters that are in 1:1 correspondence with
  an input parameter


Main:

- The galaxy wrapper create two json config files: one containing the
  parameters and the values chosen by the user and the other the values of
  hardcoded parameters.
- With `OpenMSTool -write_ctd ./` a CTD (names OpenMSTool.ctd) file is
  generated that contains the default values.
- A call to `fill_ctd.py` fills in the values from the json config files into
  the CTD file
- The actual tool is called `OpenMSTool -ini OpenMSTool.ctd` and also all input
  and output parameters are given on the command line.

Postprocessing:

- output data sets are moved to the final locations

Note: The reason for handling data sets on the command line (and not specifying
them in the CTD file) is mainly that all files in Galaxy have the extension
`.dat` and OpenMS tools require an appropriate extension. But this may change
in the future.

Generating OpenMS wrappers
==========================

1. remove old test data: `rm -rf $(ls -d test-data/* | egrep -v "random|\.loc")`
2. `./generate.sh`

Whats happening:

1. The binaries of the OpenMS package can generate a CTD file that describes
   the parameters. These CTD files are converted to xml Galaxy tool descriptions
   using the `CTDConverter`.

2. The CI testing framework of OpenMS contains command lines and test data 
   (https://github.com/OpenMS/OpenMS/tree/develop/src/tests/topp). These tests
   are described in two CMake files.

   - From these CMake files Galaxy tests are auto generated and stored in `macros_autotest.xml`
   - The command lines are stored in `prepare_test_data.sh` for regeneration of test data

More details can be found in the comments of the shell script.

Open problems
=============

Licence (MIT)
=============

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

