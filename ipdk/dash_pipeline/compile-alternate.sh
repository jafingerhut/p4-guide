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


set -x
BASENAME="dash_pipeline"
mkdir -p out


p4c-dpdk \
    -DTARGET_DPDK_PNA \
    -DPNA_CONNTRACK \
    -DDISABLE_128BIT_ARITHMETIC \
    -DUSE_64BIT_FOR_IPV6_ADDRESSES \
    --arch pna \
    --p4runtime-files out/${BASENAME}.p4Info.txt \
    --context out/${BASENAME}.context.json \
    --bf-rt-schema out/${BASENAME}.bf-rt.json \
    -o out/${BASENAME}.spec \
    ${BASENAME}.p4
