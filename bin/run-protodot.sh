#! /bin/bash

# Copyright 2018 Cisco Systems, Inc.
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


# protodot is an open source program written in Go that can read
# Google Protobuf files and generate GraphViz dot files representing
# the Protobuf messages and the relationships between them.

#     https://github.com/seamia/protodot

# This script assumes a system where protodot has been installed in
# $HOME/protodot via the install-protodot.sh script

# Also that the following command has been run successfully in the
# user's $HOME directory:

# git clone https://github.com/p4lang/p4runtime

PROTODOT_DIR="${HOME}/protodot"
P4RUNTIME_DIR="${HOME}/p4runtime"

CMD="${PROTODOT_DIR}/protodot"

PROBLEM_FOUND=0
if [ ! -d "${PROTODOT_DIR}" ]
then
    1>&2 echo ""
fi

if [ ! -x "${CMD}" ]
then
    1>&2 echo "No such executable file: ${CMD}"
    1>&2 echo "Run this install script:"
    1>&2 echo "    p4-guide/bin/install-protodot.sh"
    PROBLEM_FOUND=1
fi

if [ ! -d "${P4RUNTIME_DIR}" ]
then
    1>&2 echo "No such directory: ${P4RUNTIME_DIR}"
    1>&2 echo "Run this command:"
    1>&2 echo "    git clone https://github.com/p4lang/p4runtime"
    PROBLEM_FOUND=1
fi

if [ ${PROBLEM_FOUND} == 1 ]
then
    exit 1
fi

# A directory where both of these files can be found:
# google/protobuf/any.proto
# google/rpc/status.proto

INC_DIR1="${HOME}/protodot/proto-files"

ALL_INC_DIRS="${INC_DIR1}"
#ALL_INC_DIRS="${INC_DIR1};${INC_DIR2}"

set -ex
cd "${P4RUNTIME_DIR}/proto"
${CMD} -config ${PROTODOT_DIR}/config.json -inc "${ALL_INC_DIRS}" -src p4/v1/p4runtime.proto

set +ex
echo ""
echo "See line above 'creating file: ...' for name of .dot file created."
echo ""
echo "If you see an error message after that like 'error on exec exit"
echo "status 1', you can run a command similar to the one below to"
echo "create an .svg file:"
echo ""
echo "    dot -Tsvg protodot/generated/7860383553d6ae4c.dot > protodot/generated/7860383553d6ae4c.svg"
echo ""
echo "Replace the two occurrences of 'svg' with another suffix like"
echo "'pdf' or 'png' to create a different format of graphic file."
echo ""
echo "On Ubuntu Linux, you can use any of these programs to view an .svg file:"
echo ""
echo "    xdg-open"
echo "    inkscape  (can be installed using command: 'sudo apt-get install inkscape'"
echo "    Google Chrome"
