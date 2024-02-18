#! /bin/bash

T="`realpath /tmp/pylib`"
if [ x"${PYTHONPATH}" == "x" ]
then
    P="${T}"
else
    P="${T}:${PYTHONPATH}"
fi

# Note: The bash script `setup_tapports_in_default_ns.sh` creates N
# ports such that port number j in the P4 program corresponds to Linux
# interface TAP<j>, e.g. port 3 corresponds to Linux interface TAP3.
# The ptf command line options use this mapping.  Changing them is
# likely to confuse you when writing PTF tests that send and receive
# packets.

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
