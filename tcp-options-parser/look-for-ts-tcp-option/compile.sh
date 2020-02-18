#! /bin/bash

set -x
mkdir -p generated-code
cd generated-code
../generate.py --num-parse-iterations 8
cd ..
p4c --target bmv2 --arch v1model look-for-ts-tcp-option.p4
