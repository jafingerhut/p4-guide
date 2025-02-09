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


F=typedef-test1.p4

B=`basename $F .p4`

# TBD: Change this to your local p4c executable, or if you leave this
# as is it will use the first one in your shell's command path.
#P4C=p4c-bm2-ss
P4C=$HOME/forks/p4c/build/p4c
#P4TEST=p4test
P4TEST=$HOME/forks/p4c/build/p4test

DELETEDUPS=$HOME/p4-guide/bin/p4c-delete-duplicate-passes.sh
DUMP_FEW_PASSES="FrontEndLast,FrontEndDump,MidEndLast"
DUMP_MANY_PASSES="Front,Mid"

set -x
mkdir -p tmp
$P4C --target bmv2 --arch v1model --p4runtime-files ${B}.p4info.txtpb --dump tmp --top4 ${DUMP_MANY_PASSES} $F
$DELETEDUPS $F tmp
$P4TEST --toJSON ${B}.ir.json $F
$P4C --version
