#! /bin/bash
# Copyright 2021 Andy Fingerhut
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


# grep for some selected lines of interest in the simple_switch_grpc log

#cat ss-log.txt | egrep '((Received|Sending) packet of length|Transmitting packet of size |Transmitting packet-in|Extracting header '.*'|Pipeline '.*': start|(Read|Wrote) register |Processing (packet-out|IPv4 packet|non-IPv4 packet:) )' | grep -v log_msg

cat ss-log.txt | egrep '((Received) packet of length|(Read|Wrote) register |Processing (packet-out|IPv4 packet|non-IPv4 packet:) )' | grep -v log_msg
