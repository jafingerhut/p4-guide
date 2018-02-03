#! /bin/bash

if [ $# -ne 1 ]
then
    1>&2 echo "usage: `basename $0` <p4_source_filename>"
    exit 1
fi


P4_SRC_FNAME="$1"

mkdir -p tmp
p4c-bm2-ss --dump tmp --top4 Front,Mid "${P4_SRC_FNAME}"
