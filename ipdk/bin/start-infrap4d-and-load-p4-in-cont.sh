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

DIRECTORY="$1"
BASENAME="$2"

if [ ! -d /tmp/${DIRECTORY}/out ]
then
    1>&2 echo "No directory /tmp/${DIRECTORY}/out found.  Aborting."
    exit 1
fi

cd /tmp/${DIRECTORY}/out
set -x
/tmp/bin/tdi_pipeline_builder.sh -p . -s ${BASENAME}.p4
/tmp/bin/setup_tapports_in_default_ns.sh -n 8
/tmp/bin/load_p4_prog.sh -p ${BASENAME}.pb.bin -i ${BASENAME}.p4Info.txt

ps -C infrap4d | grep infrap4d
exit_status=$?
set +x
echo ""
if [ ${exit_status} -eq 0 ]
then
    echo "infrap4d is still running after loading P4 program ${BASENAME}.  Good!"
else
    echo "infrap4d appears to have died while loading P4 program ${BASENAME}"
    echo "Here are the last few lines in log file /var/log/stratum/infrap4d.ERROR:"
    echo "------------------------------------------------------------"
    tail -n 10 /var/log/stratum/infrap4d.ERROR
    echo "------------------------------------------------------------"
fi
