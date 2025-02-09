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


# Get copies of other repositories that I use to test an open source
# P4 development tool installation.

set -x

git clone https://github.com/p4pktgen/p4pktgen

# Basic testing of p4pktgen functionality:

# cd p4pktgen
# ./tools/install.sh
# ./tools/pytest.sh

git clone https://github.com/p4lang/tutorials

# Basic testing of functionality for tutorials repo:

# cd tutorials/exercises/basic
# cp solutions/basic.p4 .
# make run

# at mininet prompt:
# h1 ping h2
# Ctrl-C after a few seconds
# h4 ping h3
# Ctrl-C after a few seconds
# Ctrl-D to exit mininet


# fairly extensive testing of p4c functionality, and some of
# behavioral-model.

# cd $HOME/p4c/build
# make check
