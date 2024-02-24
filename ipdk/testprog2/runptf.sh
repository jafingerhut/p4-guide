#! /bin/bash

T="`realpath /tmp/testlib/backends/dpdk`"
if [ x"${PYTHONPATH}" == "x" ]
then
    P="${T}"
else
    P="${T}:${PYTHONPATH}"
fi

set -x
`which ptf` \
    --pypath "$P" \
    -i 0@TAP0 \
    -i 1@TAP1 \
    -i 2@TAP2 \
    -i 3@TAP3 \
    -i 4@TAP4 \
    -i 5@TAP5 \
    -i 6@TAP6 \
    -i 7@TAP7 \
    --test-params="grpcaddr='localhost:9559';device_id=1;p4info='out/testprog2.p4Info.txt'" \
    --test-dir ptf-tests-using-base-test
set +x

echo ""
echo "PTF test finished."
