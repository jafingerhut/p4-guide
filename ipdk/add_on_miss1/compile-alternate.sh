#! /bin/bash
# Copyright 2024 Andy Fingerhut
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


# This is a command line I used to compile add_on_miss1.p4 using the
# version of p4c built from this source code of repository
# https://github.com/p4lang/p4c

# $ git log -n 1 | head -n 5
# commit ca1f3474d532aa5c8eea5db5adbd838bc8b52d07
# Author: Fabian Ruffy <5960321+fruffy@users.noreply.github.com>
# Date:   Thu Feb 23 10:40:19 2023 -0500
# 
#     Deprecate unified build in favor of unity build. (#3491)

set -x
mkdir -p pipe

# This section of the script is intended to enable you to
# enable/disable these preprocessor #define symbols by
# commenting/uncommenting individual lines.
MACRO_DEFINES=""
#MACRO_DEFINES="-DDONT_USE_IDLE_TIMEOUT_WITH_AUTO_DELETE $MACRO_DEFINES"
# As of the version of p4c shown above, p4c-dpdk always gives an error
# if you attempt to assign a value of PNA_IdleTimeout_t.AUTO_DELETE to
# table property pna_idle_timeout, because AUTO_DELETE is not in
# DPDK's versionn of pna.p4 yet.
#MACRO_DEFINES="-DUSE_PNA_IDLE_TIMEOUT_AUTO_DELETE $MACRO_DEFINES"

p4c-dpdk ${MACRO_DEFINES} \
    --arch pna \
    --p4runtime-files p4Info.txt \
    --bf-rt-schema bf-rt.json \
    --context pipe/context.json \
    -o pipe/add_on_miss1.spec \
    add_on_miss1.p4
