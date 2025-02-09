#! /bin/bash
# Copyright 2024 Andy Fingerhut
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# SPDX-License-Identifier: Apache-2.0


# It appears that either Linux TAP interfaces, or the way they
# interact with the P4 DPDK software switch, does not support sending
# packets smaller than 14 bytes (the standard Ethernet header size).
# Thus restrict p4testgen to only create test packets that are at
# least 14*=112 bits long, or longer.

TMP_DIR="ptf-tests-using-base-test-orig"
FINAL_DIR="ptf-tests-using-base-test"
BASENAME="dash_pipeline"

MAXTESTS=2

p4testgen \
    -DTARGET_DPDK_PNA -DPNA_CONNTRACK -DDISABLE_128BIT_ARITHMETIC \
    --target dpdk \
    --arch pna \
    --max-tests ${MAXTESTS} \
    --packet-size-range 112:72000 \
    --out-dir "${TMP_DIR}" \
    --test-backend ptf \
    ${BASENAME}.p4

mkdir -p "${FINAL_DIR}"
../bin/fixup-p4testgen-dpdk-ptf-test.sh "${TMP_DIR}/${BASENAME}.py" > "${FINAL_DIR}/${BASENAME}.py"
