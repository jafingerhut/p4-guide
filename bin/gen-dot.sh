#! /bin/bash

set -x
for F in png pdf
do
    dot -T${F} dependencies.dot > dependencies.${F}
    dot -T${F} p4-16-allowed-constructs.dot > p4-16-allowed-constructs.${F}
done
