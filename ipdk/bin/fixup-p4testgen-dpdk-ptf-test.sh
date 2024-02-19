#! /bin/bash

FNAME="$1"

grep -v "^sys\.path\.append(str(BASE_TEST_PATH))$" ${FNAME} | sed 's/^PIPELINE_PUSHED = False/PIPELINE_PUSHED = True/'
