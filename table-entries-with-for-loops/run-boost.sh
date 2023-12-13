#! /bin/bash

BOOSTINCLUDE=/usr/include
P4INCLUDE=/usr/local/sare/p4c/p4include

set -x
p4c -E -I ${BOOSTINCLUDE} -I ${P4INCLUDE} example2.p4 > example2.preprocessed.p4
