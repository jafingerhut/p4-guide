#! /usr/bin/env python3

from scapy.all import *

pkt1=Ether(src='40:de:ad:be:ef:10', dst='00:00:00:00:00:05') / IP(dst='2.2.2.2', src='1.1.1.1') / TCP(flags="S")
wrpcap('tcp-syn1.pcap', [pkt1])

pkt2=Ether(src='40:de:ad:be:ef:10', dst='00:00:00:00:00:05') / IP(dst='2.2.2.2', src='1.1.1.1') / TCP(flags="A")
wrpcap('tcp-ack1.pcap', [pkt2])

pkt3=Ether(src='40:de:ad:be:ef:10', dst='00:00:00:00:00:05') / IP(dst='2.2.2.2', src='1.1.1.1') / TCP(flags="F")
wrpcap('tcp-fin1.pcap', [pkt3])
