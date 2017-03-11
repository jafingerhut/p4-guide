#! /bin/bash

set -x
for F in png pdf
do
    dot -T${F} dependencies.dot > dependencies.${F}
done
