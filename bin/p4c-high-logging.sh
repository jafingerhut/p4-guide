#! /bin/bash

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
