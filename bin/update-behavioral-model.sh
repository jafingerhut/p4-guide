#! /bin/bash

if [ -d .git -a -d m4 ]
then
    echo "Found directories .git and m4"
else
    2>&1 echo "At least one of .git and m4 directories is not present."
    2>&1 echo ""
    2>&1 echo "This command must be run from inside top level directory of"
    2>&1 echo "a clone of the Github repository https://github.com/p4lang/p4c"
    exit 1
fi

set -x

# Erase any old built files
make clean

# Get updates from master repo
git pull

# Compile and install behavioral-model
./autogen.sh
# With debug enabled in binaries:
./configure 'CXXFLAGS=-O0 -g'
# Without debug enabled:
#./configure
make
sudo make install
