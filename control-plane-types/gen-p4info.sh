#! /bin/bash

source env.sh

for p in prog1-v1model.p4
do
    j=`basename $p .p4`-p4info.json
    gen_p4info $p $j
done
