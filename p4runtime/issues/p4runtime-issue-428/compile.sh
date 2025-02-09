#! /bin/bash
# Copyright 2023 Andy Fingerhut
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


OUTPUT_DIR="out"
set -x
p4test --version
mkdir -p "${OUTPUT_DIR}"
p4test \
    --target bmv2 --arch v1model \
    --pp ${OUTPUT_DIR}/bit0b-bmv2.p4 \
    --dump ${OUTPUT_DIR} \
    --top4 FrontEndDump,FrontEndLast,MidEndLast \
    --testJson --maxErrorCount 100 \
    --p4runtime-files ${OUTPUT_DIR}/bit0b-bmv2.p4.p4info.txtpb \
    --p4runtime-entries-files ${OUTPUT_DIR}/bit0b-bmv2.p4.entries.txt \
    bit0b-bmv2.p4
