#! /usr/bin/env python3
# Copyright 2024 Andy Fingerhut
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


import time
from scapy.all import *

pkts = []
for i in range(4):
    smac = ('00:11:22:33:44:%x%x' % (i, i))
    pkts.append(Ether(src=smac, dst='00:00:00:00:00:05') / IP(dst='10.1.0.1', src='10.2.2.2'))
    time.sleep(i)

wrpcap('test-pkts1.pcap', pkts)
