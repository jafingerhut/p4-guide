#! /usr/bin/env python3

from scapy.all import *

pkt1=Ether(src='40:de:ad:be:ef:10', dst='00:00:00:00:00:05') / IP(dst='2.2.2.2', src='1.1.1.1') / ICMP(type=8)
wrpcap('pkt1.pcap', [pkt1])
