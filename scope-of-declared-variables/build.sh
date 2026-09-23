#! /bin/bash

P4GUIDE_BIN="../bin"
CC="gcc"
CPP="g++"
RUSTC="rustc"

set -x
for p in prog1p4 prog2p4 prog3p4 prog4p4 prog5p4 prog6p4 shadowing1 function-disallows-shadowing-param1
do
    mkdir -p tmp
    ${P4GUIDE_BIN}/p4c-dump-many-passes.sh ${p}.p4
    ${P4GUIDE_BIN}/p4c-delete-duplicate-passes.sh ${p}.p4 tmp
done
exit 0

for p in prog1c prog2c prog3c prog4c prog5c
do
    set -x
    ${CC} -o ${p} ${p}.c
    set +x
done

for p in prog1cpp prog2cpp prog3cpp prog4cpp prog5cpp
do
    set -x
    ${CPP} -o ${p} ${p}.cpp
    set +x
done

for p in prog1rs prog2rs prog3rs prog4rs prog5rs
do
    set -x
    ${RUSTC} ${p}.rs
    set +x
done

for p in prog1 prog4 prog5
do
    set -x
    javac ${p}.java
    set +x
done
