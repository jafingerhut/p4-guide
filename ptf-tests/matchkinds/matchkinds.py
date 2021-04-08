#!/usr/bin/env python3

# Copyright 2021 Intel Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Andy Fingerhut, andy.fingerhut@gmail.com

import logging
import ptf
import os
import ptf
import ptf.testutils as tu

from google.rpc import code_pb2

import base_test as bt


# Links to many Python methods useful when writing automated tests:

# The package `ptf.testutils` contains many useful Python methods for
# writing automated tests, some of which are demonstrated below with
# calls prefixed by the local alias `tu.`.  You can see the
# definitions for all Python code in this package, including some
# documentation for these methods, here:

# https://github.com/p4lang/ptf/blob/master/src/ptf/testutils.py

# The package `base_test` is included in this repository, and can also
# be seen at this link:

# https://github.com/jafingerhut/p4-guide/blob/master/testlib/base_test.py


######################################################################
# Configure logging
######################################################################

# Note: I am not an expert at configuring the Python logging library.
# Recommendations welcome on improvements here.

# The effect achieved by the code below seems to be that many DEBUG
# and higher priority logging messages go to the console, and also to
# a file named 'ptf.log'.  Some of the messages written to the
# 'ptf.log' file do not go to the console, and appear to be created
# from within the ptf library.

logger = logging.getLogger(None)
ch = logging.StreamHandler()
ch.setLevel(logging.DEBUG)
# create formatter and add it to the handlers
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
ch.setFormatter(formatter)
logger.addHandler(ch)


class MatchKindsTest(bt.P4RuntimeTest):
    def setUp(self):
        bt.P4RuntimeTest.setUp(self)
        # This setUp method will be executed once for each test case.
        # It may be a little bit wasteful in time to load the compiled
        # P4 program for each test, but for only a few tests it is
        # still quick.  Suggestions welcome on good ways to load the
        # compiled P4 program only once, yet still allow someone to
        # select a subset of the test cases to be run from the `ptf`
        # command line.
        success = bt.P4RuntimeTest.updateConfig(self)
        assert success

    #############################################################
    # Define a few small helper functions that help construct
    # parameters for the table_add() method.
    #############################################################

    def key_t1(self, byte1_val_int, byte1_mask_int,
               byte2_min_int, byte2_max_int):
               #byte3_val_int, byte3_exact_match):
        return ('t1',
                [self.Ternary('hdr.ipv4.dstAddr[31:24]',
                              byte1_val_int, byte1_mask_int),
                 self.Range('hdr.ipv4.dstAddr[23:16]',
                            byte2_min_int, byte2_max_int)])

    def act_set_dmac(self, dmac_string):
        return ('set_dmac', [('dmac', bt.mac_to_int(dmac_string))])


class FwdTest(MatchKindsTest):
    @bt.autocleanup
    def runTest(self):
        in_dmac = 'ee:30:ca:9d:1e:00'
        in_smac = 'ee:cd:00:7e:70:00'
        ig_port = 0
        eg_port = 1

        entries = []
        entries.append({'b1_val': 192,
                        'b1_mask': 0xff,
                        'b2_min': 172,
                        'b2_max': 172,
                        'priority': 100,
                        'pkt_in_dst_addr': '192.172.1.1',
                        'out_dmac': '00:00:00:00:00:01'})
        entries.append({'b1_val': 0,
                        'b1_mask': 0,
                        'b2_min': 172,
                        'b2_max': 172,
                        'priority': 90,
                        'pkt_in_dst_addr': '193.172.255.255',
                        'out_dmac': '00:00:00:00:00:02'})
        entries.append({'b1_val': 192,
                        'b1_mask': 0xff,
                        'b2_min': 0,
                        'b2_max': 255,
                        'priority': 80,
                        'pkt_in_dst_addr': '192.255.0.0',
                        'out_dmac': '00:00:00:00:00:03'})
        
        # Add a set of table entries
        for e in entries:
            self.table_add(self.key_t1(e['b1_val'], e['b1_mask'],
                                       e['b2_min'], e['b2_max']),
                           self.act_set_dmac(e['out_dmac']),
                           e['priority'])

        ttl_in = 200
        for e in entries:
            ip_dst_addr = e['pkt_in_dst_addr']
            pkt_in = tu.simple_tcp_packet(eth_src=in_smac, eth_dst=in_dmac,
                                          ip_dst=ip_dst_addr, ip_ttl=ttl_in)
            exp_pkt = tu.simple_tcp_packet(eth_src=in_smac,
                                           eth_dst=e['out_dmac'],
                                           ip_dst=ip_dst_addr, ip_ttl=ttl_in)
            tu.send_packet(self, ig_port, pkt_in)
            tu.verify_packets(self, exp_pkt, [eg_port])
            # Vary TTL in for each packet tested, just to make them
            # easy to distinguish from each other.
            ttl_in = ttl_in - 2
