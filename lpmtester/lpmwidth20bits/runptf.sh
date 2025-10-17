#! /bin/bash
# Copyright 2025 Andy Fingerhut
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


T="`realpath ../../testlib`"
if [ x"${PYTHONPATH}" == "x" ]
then
    P="${T}"
else
    P="${T}:${PYTHONPATH}"
fi

#echo "P is: $P"

# Only show a list of tests
#ptf --pypath "$P" --test-dir ptf --list
#exit 0

set -x
p4c --target bmv2 \
    --arch v1model \
    --p4runtime-files lpmtester.p4info.txtpb \
    lpmtester.p4

# Remove any log file written in an earlier run, otherwise
# simple_switch_grpc will append the new log messages to the end of
# the existing file.
/bin/rm -f ss-log.txt

sudo simple_switch_grpc \
     --log-file ss-log \
     --log-flush \
     --dump-packet-data 10000 \
     -i 1@veth2 \
     --no-p4 &
echo ""
echo "Started simple_switch_grpc.  Waiting 2 seconds before starting PTF test ..."
sleep 2

# Note that the mapping between switch port number and Linux interface
# names is best to make it correspond with those given when starting
# the simple_switch_grpc process.  The `ptf` process has no other way
# of getting this mapping other than by telling it on its command
# line.

sudo ${P4_EXTRA_SUDO_OPTS} `which ptf` \
    --pypath "$P" \
    -i 1@veth3 \
    --test-params="grpcaddr='localhost:9559';p4info='lpmtester.p4info.txtpb';config='lpmtester.json'" \
    --test-dir ptf

echo ""
echo "PTF test finished.  Waiting 2 seconds before killing simple_switch_grpc ..."
sleep 2
sudo pkill --signal 9 --list-name simple_switch
echo ""
echo "Verifying that there are no simple_switch_grpc processes running any longer in 4 seconds ..."
sleep 4
ps axguwww | grep simple_switch
