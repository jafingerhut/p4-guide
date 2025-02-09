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


print_usage() {
    1>&2 echo "usage: $0 <directory> <base-name-of-p4-program>"
    1>&2 echo ""
    1>&2 echo "<directory> is relative to the root directory shared"
    1>&2 echo "between the base OS and container, e.g. if the program"
    1>&2 echo "is in directory $HOME/.ipdk/volume/sample, then"
    1>&2 echo "<directory> should be: sample"
    1>&2 echo ""
    1>&2 echo "<base-name-of-p4-program> is the base name of the top"
    1>&2 echo "level P4 source file, without the .p4 suffix."
}

if [ $# -ne 2 ]
then
    print_usage
    exit 1
fi

cd ${IPDK_HOME}
ipdk execute --- /tmp/bin/start-infrap4d-and-load-p4-in-cont.sh $*
