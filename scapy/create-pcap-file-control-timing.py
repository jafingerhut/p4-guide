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


# Prerequisites: Same as create-pcap-file.py.  See comments there.

# If you use tcpreplay, and AVOID giving any command line options that
# control the packet sending rate, e.g. --pps, then tcpreplay will try
# to send the packets spaced out in time in a way that is at least
# close to the relative time stamp files recorded in the pcap file.

# Example tcpreplay command line that can send the contents of a pcap
# file to a specified interface (example 'veth0' below) with
# inter-packet spacing similar to those in the pcap file:

# sudo tcpreplay --preload-pcap -i veth0 pkts.pcap

from scapy.all import *

f = PcapWriter('pkts.pcap')
#print("type(f)=%s" % (type(f)))
#print("dir(f)=%s" % (dir(f)))

for i in range(0, 10 * 1000):
    payload_str = "The quick brown fox jumped over the lazy dog."
    payload_data = payload_str.encode('utf-8')
    pkt = Ether(src='00:00:00:00:00:10', dst='00:00:00:00:00:05') / IP(src='10.2.2.2', dst='10.1.0.1') / UDP(sport=5792, dport=8005) / Raw(payload_data)

    # Make times of packets such that every pair of them occurs 1
    # microsec apart, but the next pair is 2 millisec after the
    # previous pair.
    microsec = 2000 * int(i/2)
    # Odd packets are always 1 microsec after the previous one
    if i % 2 == 1:
        microsec += 1
    second = int(microsec / 1_000_000)
    microsec = microsec % 1_000_000
    #print("second=%d microsec=%d" % (second, microsec))

    # TBD: I do not know why I need to call this once for the entire
    # output file, and if so, why it needs a packet as an argument.
    if i == 0:
        f._write_header(pkt)

    # On-line Scapy documentation has a description of a method named
    # write_packet, with no leading underscore, but I could not find
    # any definition of such a method for class PcapWriter in the
    # source code installed by the command `sudo pip3 install
    # scapy==2.4.4`.  I could find a definition of the method
    # _write_packet with a leading underscore in its name.  That seems
    # odd.
    f._write_packet(bytes(pkt), sec=second, usec=microsec)

f.close()
