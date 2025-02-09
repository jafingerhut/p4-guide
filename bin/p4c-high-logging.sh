#! /bin/bash
# Copyright 2019 Andy Fingerhut
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


# $ find backends/bmv2 | grep '\.cpp'
# backends/bmv2/psa_switch/midend.cpp
# backends/bmv2/psa_switch/main.cpp
# backends/bmv2/psa_switch/psaSwitch.cpp
# backends/bmv2/simple_switch/midend.cpp
# backends/bmv2/simple_switch/simpleSwitch.cpp
# backends/bmv2/simple_switch/main.cpp
# backends/bmv2/common/control.cpp
# backends/bmv2/common/programStructure.cpp
# backends/bmv2/common/extern.cpp
# backends/bmv2/common/sharedActionSelectorCheck.cpp
# backends/bmv2/common/globals.cpp
# backends/bmv2/common/controlFlowGraph.cpp
# backends/bmv2/common/metermap.cpp
# backends/bmv2/common/parser.cpp
# backends/bmv2/common/header.cpp
# backends/bmv2/common/deparser.cpp
# backends/bmv2/common/expression.cpp
# backends/bmv2/common/action.cpp
# backends/bmv2/common/lower.cpp
# backends/bmv2/common/JsonObjects.cpp
# backends/bmv2/common/helpers.cpp

#P4C="$HOME/forks/p4c/build/p4c-bm2-psa"
P4C="$HOME/forks/p4c/build/p4c-bm2-ss"
PROG="$1"
JSON="`basename ${PROG} .p4`.json"

${P4C} -T midend:5,main:5,psaSwitch:5,control:5,programStructure:5,extern:5,sharedActionSelectorCheck:5,globals:5,controlFlowGraph:5,metermap:5,parser:5,header:5,deparser:5,expression:5,action:5,lower:5,JsonObjects:5,helpers:5 ${PROG} -o ${JSON}
