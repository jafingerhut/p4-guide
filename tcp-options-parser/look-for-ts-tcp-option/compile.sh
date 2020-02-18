#! /bin/bash

set -x
mkdir -p generated-code
cd generated-code
../generate.py
cd ..
p4c --target bmv2 --arch v1model look-for-ts-tcp-option.p4
