#! /bin/bash

ptf \
    -i 0@TAP0 \
    -i 1@TAP1 \
    --test-params="grpcaddr='localhost:9559'" \
    --test-dir .

echo ""
echo "PTF test finished."
