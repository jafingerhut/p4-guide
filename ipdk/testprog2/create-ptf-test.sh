#! /bin/bash

# It appears that either Linux TAP interfaces, or the way they
# interact with the P4 DPDK software switch, does not support sending
# packets smaller than 14 bytes (the standard Ethernet header size).
# Thus restrict p4testgen to only create test packets that are at
# least 14*=112 bits long, or longer.

TMP_DIR="ptf-tests-using-base-test-orig"
FINAL_DIR="ptf-tests-using-base-test"

p4testgen --target dpdk --arch pna --max-tests 1000 --packet-size-range 112:72000 --out-dir "${TMP_DIR}" --test-backend ptf testprog2.p4

mkdir -p "${FINAL_DIR}"
../bin/fixup-p4testgen-dpdk-ptf-test.sh "${TMP_DIR}/testprog2.py" > "${FINAL_DIR}/testprog2.py"
