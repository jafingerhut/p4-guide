#! /usr/bin/env python3
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


# Prerequisites: Python3 version of Scapy library is installed.  For
# example, to do so on Ubuntu 16.04, 18.04, or 20.04 systems:

# sudo apt-get install python3-pip
# sudo pip3 install scapy

# Example tcpreplay command line that can send the contents of a pcap
# file to a specified interface (example 'veth0' below) at a rate of
# 1000 packets/second.

# sudo tcpreplay --preload-pcap -i veth0 --pps=1000 pkts.pcap

# Example output when I tested the command above on an Ubuntu 18.04
# Linux system with tcpreplay version 4.2.6 installed via `sudo
# apt-get install tcpreplay`.

# $ sudo tcpreplay --preload-pcap -i enp0s3 --pps=1000 pkts.pcap 
# File Cache is enabled
# Actual: 10000 packets (870000 bytes) sent in 9.99 seconds
# Rated: 87008.5 Bps, 0.696 Mbps, 1000.09 pps
# Flows: 1 flows, 0.10 fps, 10000 flow packets, 0 non-flow
# Statistics for network device: enp0s3
# 	Successful packets:        10000
# 	Failed packets:            0
# 	Truncated packets:         0
# 	Retried packets (ENOBUFS): 0
# 	Retried packets (EAGAIN):  0

from scapy.all import *

pkt_list = []
for i in range(0, 10 * 1000):
    payload_str = "The quick brown fox jumped over the lazy dog."
    payload_data = payload_str.encode('utf-8')
    pkt = Ether(src='00:00:00:00:00:10', dst='00:00:00:00:00:05') / IP(src='10.2.2.2', dst='10.1.0.1') / UDP(sport=5792, dport=8005) / Raw(payload_data)
    pkt_list.append(pkt)

wrpcap('pkts.pcap', pkt_list)
