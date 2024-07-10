#! /usr/bin/env python3

import time
from scapy.all import *

pkts = []
for i in range(4):
    smac = ('00:11:22:33:44:%x%x' % (i, i))
    pkts.append(Ether(src=smac, dst='00:00:00:00:00:05') / IP(dst='10.1.0.1', src='10.2.2.2'))
    time.sleep(i)

wrpcap('test-pkts1.pcap', pkts)
