#!/bin/bash

LICENSE_FILE=LICENSE
# Ensure repository contains license file.
if [ ! -e "$LICENSE_FILE" ];
then
    wget http://www.apache.org/licenses/LICENSE-2.0.txt -O "$LICENSE_FILE"
fi

# Run repository specific update actions.
if [ -f update_repo.sh ];
then
    ./update_repo.sh
fi

wget https://raw.github.com/gist/3749747/README_GALAXYP.md -O README_GALAXYP.md

# Create repository README
if [ ! -e README_REPO.md ];
then
    echo "TODO: Document this tool repository." > README_REPO.md
fi
cat README_REPO.md README_GALAXYP.md > README.md


# If version file exists, update all tools to this version
VERSION_FILE=version
if [ -e "$VERSION_FILE" ];
then
    VERSION=`cat $VERSION_FILE`
    
    # Replace tool version in each tool XML file   `
    find -iname "*xml" -exec sed -i'' -e '0,/version="\(.\+\)"/s/version="\(.\+\)"/version="'$VERSION'"/1g' {} \;

fi
