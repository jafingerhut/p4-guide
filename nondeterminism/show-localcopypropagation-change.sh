#! /bin/bash
# Copyright 2022 Andy Fingerhut
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


if [ $# -ne 1 ]
then
    1>&2 echo "usage: `basename $0` <program.p4>"
    exit 1
fi

PROG_NAME="$1"

if [ ! -e "${PROG_NAME}" ]
then
    1>&2 echo "File not found: ${PROG_NAME}"
    exit 1
fi

k=`basename $PROG_NAME .p4`

set -x
/bin/rm -fr tmp
mkdir -p tmp
p4c-bm2-ss --version
p4c-bm2-ss --dump tmp --top4 Front,Mid $k.p4
diff -c tmp/$k-BMV2::SimpleSwitchMidEnd_27_ConstantFolding.p4 tmp/$k-BMV2::SimpleSwitchMidEnd_28_LocalCopyPropagation.p4
