#! /bin/bash

P4GUIDE_BIN="../bin"
CC="gcc"
CPP="g++"
RUSTC="rustc"

set -x
/bin/rm -fr tmp
for p in prog1p4 prog2p4 prog3p4
do
    mkdir -p tmp
    ${P4GUIDE_BIN}/p4c-dump-many-passes.sh ${p}.p4
    ${P4GUIDE_BIN}/p4c-delete-duplicate-passes.sh ${p}.p4 tmp
done

for p in prog1c prog2c prog3c
do
    ${CC} -o ${p} ${p}.c
done

for p in prog1cpp prog2cpp prog3cpp
do
    ${CPP} -o ${p} ${p}.cpp
done

javac prog1java.java

for p in prog1rs prog2rs prog3rs
do
    ${RUSTC} ${p}.rs
done

