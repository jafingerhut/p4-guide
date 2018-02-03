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

usage() {
    2>&1 echo "usage: $0 [ update ]"
}

DO_UPDATE_FIRST=0
if [ $# -eq 1 ]
then
    if [ "$1" == "update" ]
    then
	DO_UPDATE_FIRST=1
    else
	usage
	exit 1
    fi
elif [ $# -ne 0 ]
then
    usage
    exit 1
fi

#echo "DO_UPDATE_FIRST=${DO_UPDATE_FIRST}"
if [ ${DO_UPDATE_FIRST} -eq 1 ]
then
    echo "Will update files before clean and build."
else
    echo "Will clean and build without updating any files."
fi

set -x

# Erase any old built files
make clean

if [ ${DO_UPDATE_FIRST} -eq 1 ]
then
    # Get updates from master repo
    git pull
fi

# Compile and install behavioral-model
./autogen.sh
# With debug enabled in binaries:
./configure 'CXXFLAGS=-O0 -g'
# With debug and P4_16 stack operation support enabled in binaries:
#./configure --enable-WP4-16-stacks 'CXXFLAGS=-O0 -g'
# Without debug enabled:
#./configure
make
sudo make install
