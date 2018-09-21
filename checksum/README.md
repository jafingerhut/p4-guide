# Introduction

checksum-ipv4-with-options.p4 is a small P4_16 program using the
latest v1model.p4 as of 2017-Oct-03, with correct syntax for checking
the received IPv4 header checksum, and updating the outgoing IPv4
header checksum.

The test cases given in this repository demonstrate that the outgoing
IPv4 header checksums are correct (at least for the couple of test
cases included).

With an update to p4lang/behavioral-model code made on 2018-Sep-21, I
have confirmed that some test cases below that send in packets with an
incorrect IPv4 header checksum _are_ detected, and as a result assign
a value of 1 to the `checksum_error` field in the standard_metadata_t
struct of v1model.p4.  This field can be used by your P4 program code
to determine what to do with the packet.

One of the test cases also confirms that a `PacketTooShort` parser
error is visible to ingress code in the `parser_error` field.

The PSA v1.0 specification's InternetChecksum extern API is quite
different from v1model.p4, and does specify and include an example
P4_16 program showing how to detect and handle differently received
packets that have a bad checksum.  It is not yet implemented in the
open source P4 tools, though.


# Compiling

See [README-using-bmv2.md](../README-using-bmv2.md) for some things
that are common across different P4 programs executed using bmv2.

To compile the P4_16 version of the code:

    p4c-bm2-ss checksum-ipv4-with-options.p4 -o checksum-ipv4-with-options.json

This program currently only compiles without errors using a version of
p4c after this 2017-Oct-03 commit:

    https://github.com/p4lang/p4c/commit/52e273d402cc4e18eb9a6db6c2b52d4bbc89a91b

I have checked in a file checksum-ipv4-with-options.json generated
with the p4c-bm2-ss command above, using a version of p4c-bm2-ss
compiled from the p4c repository, the latest master version as of
2017-Oct-30.

# Running

To run the behavioral model with 1 port numbered 0:

    sudo simple_switch --log-console -i 0@veth2 checksum-ipv4-with-options.json


No table entries need to be added for the default action 'foo' to be
run on all packets.


----------------------------------------------------------------------
scapy session for sending packets
----------------------------------------------------------------------
We must run scapy as root for it to have permission to send packets on
veth interfaces.

I found a working example of using Scapy to generate IPv4 headers with
IP options here: http://allievi.sssup.it/techblog/archives/631

```
sudo scapy

# See README-scapy.md section on incorrect values for auto-calculated
# fields for a few more details.

pkt1_bad=Ether() / IP(dst='10.1.0.1') / TCP(sport=5793, dport=80)
pkt1_good=Ether(str(pkt1_bad))
pkt1_bad[IP].chksum=pkt1_good[IP].chksum+1

len(pkt1_good)
# => 54
pkt1_truncated2=Ether(str(pkt1_good)[:-21])
len(pkt1_truncated2)
# => 33

pkt2_bad=Ether() / IP(dst='10.2.3.4', options=IPOption('\x83\x03\x10')) / TCP(sport=5501, dport=80)
pkt2_good=Ether(str(pkt2_bad))
pkt2_bad[IP].chksum=pkt2_good[IP].chksum+1

pkt2_truncated1=Ether(str(pkt2_good)[:-1])
pkt2_truncated2=Ether(str(pkt2_good)[:-21])

def str_to_hex(s):
    return ''.join(map(lambda x: '%02x' % (ord(x)), s))

import re
def hex_to_str(hex_s):
    tmp = re.sub('[ \t]', '', hex_s)
    return str(bytearray.fromhex(tmp))

pkt2_good_hexstr=str_to_hex(str(pkt2_good))
pkt2_truncated2_hexstr=pkt2_good_hexstr[:-2*21]
len(pkt2_truncated2_hexstr)
# => 74
pkt2_truncated2_str=hex_to_str(pkt2_truncated2_hexstr)
len(pkt2_truncated2_str)
# => 37
pkt2_truncated2=Ether(pkt2_truncated2_str)
len(pkt2_truncated2)
# => 38

# This looks like a bug in Scapy version 2.2.0 Ether() parsing code.
# It seems to be automatically adding another byte at the end of the
# given string.  It doesn't do that when the IPv4 hlen field is 5 for
# 20 bytes, without options, but it does do that when the hlen field
# is 6 for 24 bytes, with 4 bytes of options.

# Scapy 2.2.0 is the default version installed on Ubuntu 16.04 via
# python-scapy package as of 2018-Sep-21.

# Scapy 2.3.3 is the default version installed on Ubuntu 18.04 via
# python-scapy package as of 2018-Sep-21, and it seems to have fixed
# this bug.


str_to_hex(str(pkt2_good))
# => '525400123502080027561a7708004600002c000100004006cdb30a00020f0a02030483031000157d005000000000000000005002200061010000'
len(pkt2_good)
# => 58
# 14 Ethernet + 24 IPv4 + 20 TCP

str_to_hex(str(pkt2_truncated1))
# => '525400123502080027561a7708004600002c000100004006cdb30a00020f0a02030483031000157d0050000000000000000050022000610100'
len(pkt2_truncated1)
# => 57
# 14 Ethernet + 24 IPv4 + 19 incomplete TCP

str_to_hex(str(pkt2_truncated2))
# => '525400123502080027561a7708004600002c000100004006cdb30a00020f0a020304830310'
len(pkt2_truncated2)
# => 37
# 14 Ethernet + 23 incomplete IPv4

# Send packet at layer2, specifying interface
sendp(pkt1_good, iface="veth2")
sendp(pkt1_bad, iface="veth2")
sendp(pkt2_good, iface="veth2")
sendp(pkt2_bad, iface="veth2")
sendp(pkt2_truncated1, iface="veth2")
sendp(pkt2_truncated2, iface="veth2")
```

Tested behavior with latest versions of behavioral-model and p4c as of
2018-Sep-21, showing values of standard_metadata.checksum_error and
standard_metadata.parser_error for each packet, at the time that
ingress processing began executing:

+ pkt1_good - checksum_error=0, parser_error=0 (error.NoError) packet_length=0x36=54
+ pkt1_bad -  checksum_error=1, parser_error=0 (error.NoError) packet_length=0x36=54
+ pkt2_good - checksum_error=0, parser_error=0 (error.NoError) packet_length=0x3a=58
+ pkt2_bad -  checksum_error=1, parser_error=0 (error.NoError) packet_length=0x3a=58
+ pkt1_truncated2 -  checksum_error=0, parser_error=1 (error.PacketTooShort) packet_length=0x21=33

The file `packets-in-port0.pcap` in this directory contains a capture
of the input packets generated by the above Scapy function calls, as
sent to simple_switch.

The file `packets-out-port0.pcap` contains a capture of the output
packets produced by the checksum-ipv4-with-options.p4 program, when
given the above packets as input.

    % cp packets-in-port0.pcap 0_in.pcap

    # This command will read the pcap file 0_in.pcap for packets to
    # send into port 0 of simple_switch, and write output packets
    # transmitted on port 0 to file 0_out.pcap.
    
    % simple_switch -i 0@0 --use-files 0 checksum-ipv4-with-options.json

    [ Use Ctrl-C to kill simple_switch process after a second or two
      of inactivity ]

    % ls -l 0_out.pcap
    -rw-r--r-- 1 jafinger jafinger 168 Sep  5 02:31 0_out.pcap

    # Use editcap to change the link type of the pcap file from 'None'
    # to Ethernet, and the snaplen from 0 to 262144.  The resulting
    # output file 0_out_ether.pcap is more easily usable by programs
    # that read and process pcap files.
    
    % editcap -F pcap -T ether 0_out.pcap 0_out_ether.pcap

    # Use Scapy to verify that the packets out in 0_out_ether.pcap are
    # the same as those in packets-out-port0.pcap
    
    % scapy
    Welcome to Scapy (2.3.3)
    >>> p1=rdpcap('packets-out-port0.pcap')
    >>> p2=rdpcap('0_out_ether.pcap')
    >>> len(p1)
    2
    >>> len(p2)
    2
    >>> str(p1[0])==str(p2[0])
    True
    >>> str(p1[1])==str(p2[1])
    True

----------------------------------------
