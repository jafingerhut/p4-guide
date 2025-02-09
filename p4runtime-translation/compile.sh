#! /bin/bash
# Copyright 2020 Andy Fingerhut
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


P4C="p4c"

for j in weird-case*.p4
do
    k=`basename $j .p4`
    echo "------------------------------------------------------------"
    set -x
    ${P4C} --target bmv2 --arch v1model --p4runtime-files ${k}.p4info.txtpb $j
    set +x
done
