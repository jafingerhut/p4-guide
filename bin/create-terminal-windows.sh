#! /bin/bash

# Copyright 2017-present Cisco Systems, Inc.

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


# On Ubuntu 16.04 gnome-terminal no longer supports the --title option.
# mate-terminal does.
if [ `which mate-terminal` ]; then
    CMD=mate-terminal
elif [ `which gnome-terminal` ]; then
    CMD=gnome-terminal
else
    echo "Could note find gnome-terminal or mate-terminal in command path"
    exit 1
fi

# Nice to have separate terminal windows to watch what is going on.

# Upper right: bmv2/simpel_switch execution, with its debug logging to
# stdout/stderr
# Wider terminal is good for --log-console messages from simple_switch
${CMD} --geometry=100x23+540+0 --title=simple_switch &

# Upper left: tabs 'compile' for compiling P4 code,
# 'simple_switch_CLI' for running that process and installing table
# entries, and 'scapy' for sending packets
${CMD} --geometry=80x21+0+0 --tab --title=compile --tab --title=simple_switch_CLI --tab --title=scapy &

# Bottom left: tcpdump/tshark running on veth2
${CMD} --geometry=80x19+0+485 --title="port 0 veth2" &

# Bottom right: tcpdump/tshark running on veth6
${CMD} --geometry=80x19+700+485 --title="port 2 veth6" &
