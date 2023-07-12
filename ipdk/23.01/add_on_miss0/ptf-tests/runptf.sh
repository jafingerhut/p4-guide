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
    -i 17@TAP17 \
    -i 18@TAP18 \
    -i 19@TAP19 \
    -i 20@TAP20 \
    --test-params="grpcaddr='localhost:9559'" \
    --test-dir .
set +x

echo ""
echo "PTF test finished."
