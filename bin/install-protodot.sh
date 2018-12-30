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


# protodot is an open source program written in Golang that can read
# Google Protobuf .proto files and generate GraphViz dot files
# representing the Protobuf messages and the relationships between
# them.
#
#     https://github.com/seamia/protodot

# This script does the following:

# + Downloads a pre-built Linux binary for protodot and puts it in the
#   file $HOME/protodot/protodot
# + Runs "protodot -install" from the "$HOME/protodot" directory,
#   which creates some files needed to run protodot.
# + Installs the graphviz package, which includes the command "dot"
#   that is needed for turning the ".dot" files that protodot creates,
#   into one of several graphics formats such as: PDF PNG SVG etc.

# All files created as a result of running this script (except those
# created while installing the graphviz package) will be in the
# directory $HOME/protodot, and you may wish to add that directory to
# your shell's command path, since that is where the protodot binary
# is put.

# I found this bit of trickery at the StackOverflow link below.
# http://stackoverflow.com/questions/421772/how-can-a-bash-script-know-the-directory-it-is-installed-in-when-it-is-sourced-w
INSTALL_DIR=$(dirname $(readlink -f "$BASH_SOURCE"))

set -ex
cd $HOME
mkdir -p protodot
cd protodot
curl --output protodot https://protodot.seamia.net/binaries/linux
chmod 755 protodot
./protodot -install

mkdir -p proto-files/google/protobuf
curl --output proto-files/google/protobuf/any.proto https://raw.githubusercontent.com/protocolbuffers/protobuf/v3.2.0/src/google/protobuf/any.proto

mkdir -p proto-files/google/rpc
curl --output proto-files/google/rpc/status.proto https://raw.githubusercontent.com/p4lang/p4c/master/control-plane/google/rpc/status.proto

sudo apt-get install graphviz

DOT_CMD=`which dot`
${INSTALL_DIR}/edit-protodot-config.py config.json config.json.orig "${DOT_CMD}"
