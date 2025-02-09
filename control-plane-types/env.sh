# Copyright 2018 Andy Fingerhut
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

P4C_INSTALL=${HOME}/p4c
P4SPEC_INSTALL=${HOME}/p4-spec
P4TEST=${P4C_INSTALL}/build/p4test

translate_p414_to_p416() {
    p4_14_file=$1
    p4_16_file=$2
    ${P4TEST} -I ${P4C_INSTALL}/p4include --p4v 14 --pp ${p4_16_file} ${p4_14_file}
}

gen_p4info() {
    p4_16_file=$1
    p4info_file=$2
    echo "${P4TEST} --p4runtime-format json --p4runtime-file ${p4info_file} ${p4_16_file}"
    ${P4TEST} --p4runtime-format json --p4runtime-file ${p4info_file} ${p4_16_file}
}
