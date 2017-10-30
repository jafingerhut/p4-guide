#! /bin/bash

set -x

for j in $*
do
    f=`basename $j .dot`
    dot $f.dot -Tpng > $f.png
done
