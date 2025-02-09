#!/usr/bin/env python3
# Copyright 2019 Andy Fingerhut
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



import os
import queue
import subprocess
import sys
import time
import threading

try:
    from scapy.all import sniff, sendp, Ether, IP, UDP
except:
    print("Install Scapy.  On Ubuntu 16.04 or 18.04, you can use these commands:")
    print("    sudo apt-get install python3-pip")
    print("    pip3 install scapy")
    sys.exit(1)

def clean_veth_pair(veth0, veth1):
    
    if check_intf_exists(veth0):
        print("Deleting interface pair %s<->%s" % (veth0, veth1))
        subprocess.call(['ip', 'link', 'del', veth0])

    #removing one side of the pair is enough
    #if check_intf_exists(veth1):
    #    print("Deleting interface %s" % (veth1))
    #    subprocess.call(['ip', 'link', 'del', veth1])

def check_intf_exists(intf_name):
    intf_exists = False
    try:
        args=['ip', 'link', 'show', intf_name]
        subprocess.check_output(args)
        intf_exists = True
    except subprocess.CalledProcessError as e:
        print("Error status %d while trying to show the interface" % (e.returncode))
        # We expect it to be 1 if the error was that the interface
        # does not exist.
        assert e.returncode == 1
        intf_exists = False
    return intf_exists


def create_and_cfg_veth_intf(intf_name, peer_intf_name):
    print("Creating interface '%s' with peer '%s'..."
          "" % (intf_name, peer_intf_name))

    intf_exists = check_intf_exists(intf_name)
    if not intf_exists:
        args=['ip', 'link', 'add', 'name', intf_name, 'type', 'veth',
              'peer', 'name', peer_intf_name]
        subprocess.check_output(args)

    for i in range(2):
        if i == 0:
            iname = intf_name
        else:
            iname = peer_intf_name
        print("Configuring interface '%s'" % (iname))
        args=['ip', 'link', 'set', 'dev', iname, 'up']
        subprocess.check_output(args)
        args=['ip', 'link', 'set', iname, 'mtu', '9500']
        subprocess.check_output(args)
        args=['sysctl', 'net.ipv6.conf.' + iname + '.disable_ipv6=1']
        subprocess.check_output(args)
    print("Interface creation done.")


def sniff_record(q, intf_name):
    print("sniff start")
    pkts = sniff(timeout=3, iface=intf_name)
    print("sniff stop returned %d packet" % (len(pkts)))
    q.put(pkts)

def send_pkts_and_capture(intf_name, packet_list):
    '''Send packets in list `port_packet_list` to simple_switch
    process, while capturing packets sent to simple_switch, and
    output by simple_switch, by Scapy sniff() call.'''

    q = queue.Queue()
    thd = threading.Thread(name="sniff_thread",
                           target=lambda: sniff_record(q, intf_name))
    thd.start()

    # The time.sleep() call here gives time for thread 'thd' to start
    # sniffing packets, before we begin sending packets to the
    # simple_switch process immediately after that.
    time.sleep(1)

    for pkt in packet_list:
        sendp(pkt, iface=intf_name)
    thd.join()
    captured_pkt_list = q.get(True)
#    for pkt in captured_pkt_list:
#        print("dbg pkt.sniffed_on=%s" % (pkt.sniffed_on))
#        assert pkt.sniffed_on == intf_name
    return captured_pkt_list


def scapy_pkt_to_hex_str(pkt):
    return ''.join(['%02x' % (x) for x in bytes(pkt)])



sent_pkt = Ether(src='00:de:ad:be:ef:fa',dst='00:ca:fe:d0:0d:0f') / IP() / UDP()

intf_name = 'veth0'
peer_intf_name = 'veth1'
create_and_cfg_veth_intf(intf_name, peer_intf_name)
send_pkt_list = [sent_pkt]
captured_pkt_list = send_pkts_and_capture(intf_name, send_pkt_list)
print("Packet sent to interface '%s':" % (intf_name))
print("   len %3d %s" % (len(sent_pkt), scapy_pkt_to_hex_str(sent_pkt)))
print("Number of captured packets: %d" % (len(captured_pkt_list)))
for i in range(len(captured_pkt_list)):
    pkt = captured_pkt_list[i]
    print("%2d len %3d %s" % (i+1, len(pkt), scapy_pkt_to_hex_str(pkt)))

print()
print("output of 'uname -a' command:")
output = subprocess.check_output(['uname', '-a'], stderr=subprocess.STDOUT)
print(output.rstrip())
print("output of 'uname -r' command:")
output = subprocess.check_output(['uname', '-r'], stderr=subprocess.STDOUT)
print(output.rstrip())

assert len(captured_pkt_list) == 1
cap_pkt = captured_pkt_list[0]
cap_pkt_bytes = bytes(cap_pkt)
sent_pkt_bytes = bytes(sent_pkt)
if cap_pkt_bytes == sent_pkt_bytes:
    print("GOOD - Captured packet matches sent packet")
else:
    mismatch_found = False
    for i in range(min(len(cap_pkt_bytes), len(sent_pkt_bytes))):
        if cap_pkt_bytes[i] != sent_pkt_bytes[i]:
            print("At byte position %d sent packet contains 0x%02x but captured packet contains 0x%02x"
                  "" % (i, ord(sent_pkt_bytes[i]), ord(cap_pkt_bytes[i])))
            mismatch_found = True
            break
    if mismatch_found:
        print("VERY BAD - Captured packet differs at byte position %d from sent packet" % (i))
        print("""
Please try running this test script several times to see if a 'VERY
BAD' result is reproducible.  It could be due to some other Linux
process, or the kernel, sending a packet to the test veth interface
while this program was capturing packets sent to that interface.  Such
events should not be common.  If you can get 100%, or a large
fraction, of failures of this type, then it is more believable that
the veth implementation is at fault.
""")
    else:
        print("BAD - Captured packet is %d bytes longer than sent packet - this looks like a known Linux kernel issue for veth interfaces"
              "" % (len(cap_pkt_bytes) - len(sent_pkt_bytes)))

clean_veth_pair(intf_name, peer_intf_name)
