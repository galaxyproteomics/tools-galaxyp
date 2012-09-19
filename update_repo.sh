#!/bin/bash

sed -e '/BEGIN_VERSION_RAW/,/END_VERSION_RAW/d'  -e '/BEGIN_VERSION_3/,/END_VERSION_3/d'  -e 's/\$VERSION/2/g' -e 's/\$DESCRIPTION//g' msconvert.xml.template > msconvert2.xml
sed -e '/BEGIN_VERSION_DEFAULT/,/END_VERSION_DEFAULT/d' -e '/BEGIN_VERSION_3/,/END_VERSION_3/d'  -e 's/\$VERSION/2/g' -e 's/\$DESCRIPTION/_raw/g' msconvert.xml.template > msconvert2_raw.xml


sed -e '/BEGIN_VERSION_RAW/,/END_VERSION_RAW/d' -e 's/\$VERSION/3/g' -e 's/\$DESCRIPTION//g' msconvert.xml.template > msconvert3.xml
sed -e '/BEGIN_VERSION_DEFAULT/,/END_VERSION_DEFAULT/d' -e 's/\$VERSION/3/g' -e 's/\$DESCRIPTION/_raw/g' msconvert.xml.template > msconvert3_raw.xml

