#! /bin/bash

T="`realpath /tmp/pylib`"
if [ x"${PYTHONPATH}" == "x" ]
then
    P="${T}"
else
    P="${T}:${PYTHONPATH}"
fi

set -x
ptf \
    --pypath "$P" \
    -i 0@TAP0 \
    -i 1@TAP1 \
    -i 2@TAP2 \
    -i 3@TAP3 \
    -i 4@TAP4 \
    -i 5@TAP5 \
    -i 6@TAP6 \
    -i 7@TAP7 \
    --test-params="grpcaddr='localhost:9559'" \
    --test-dir .
set +x

echo ""
echo "PTF test finished."
