#! /bin/bash

if [ $# -ne 2 ]
then
    1>&2 echo "usage: `basename $0` <in1_int> <in2_int>"
    exit 1
fi

IN1="$1"
IN2="$2"

for p in prog1c prog2c prog3c
do
    echo "${p}"
    ./${p} ${IN1} ${IN2}
done

for p in prog1cpp prog2cpp prog3cpp
do
    echo "${p}"
    ./${p} ${IN1} ${IN2}
done

# Java program gives compile-time error.  Nothing to run.
#javac prog1java.java

for p in prog1rs prog2rs prog3rs
do
    echo "${p}"
    ./${p} ${IN1} ${IN2}
done

