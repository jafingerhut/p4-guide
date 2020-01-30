#! /bin/bash

if [ $# -ne 1 ]
then
    1>&2 echo "usage: `basename $0` <p4_source_filename>"
    1>&2 echo ""
    1>&2 echo "Note: You should set up your command path so that an appropriate"
    1>&2 echo "version of the 'p4c' command is first in your path."
    1>&2 echo ""
    1>&2 echo "Note: Some of the command line options to the 'p4c' command"
    1>&2 echo "used by this script give an error if you are running a 'p4c'"
    1>&2 echo "executable installed in a system-wide location like"
    1>&2 echo "/usr/local/bin.  They should work if you are using an"
    1>&2 echo "a 'p4c' executable that you compiled from source code and is"
    1>&2 echo "in a directory like $HOME/p4c/build/p4c"
    exit 1
fi


P4_SRC_FNAME="$1"

mkdir -p tmp
p4c-bm2-ss --dump tmp --top4 Front,Mid "${P4_SRC_FNAME}"
