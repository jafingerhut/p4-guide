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
from ptf import config
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

# Examples of some kinds of calls that can be made to generate
# logging messages.
#logger.debug("10 logger.debug message")
#logger.info("20 logger.info message")
#logger.warn("30 logger.warn message")
#logger.error("40 logger.error message")
#logging.debug("10 logging.debug message")
#logging.info("20 logging.info message")
#logging.warn("30 logging.warn message")
#logging.error("40 logging.error message")


class Demo1Test(bt.P4RuntimeTest):
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

    def key_ipv4_da_lpm(self, ipv4_addr_string, prefix_len):
        return ('ipv4_da_lpm',
                [self.Lpm('hdr.ipv4.dstAddr',
                          bt.ipv4_to_binary(ipv4_addr_string), prefix_len)])

    def act_set_l2ptr(self, l2ptr_int_val):
        return ('set_l2ptr', [('l2ptr', bt.stringify(l2ptr_int_val))])

    def key_mac_da(self, l2ptr_int_val):
        return ('mac_da', [self.Exact('meta.fwd_metadata.l2ptr',
                           bt.stringify(l2ptr_int_val))])

    def act_set_bd_dmac_intf(self, bd_int_val, dmac_string, intf_int_val):
        return ('set_bd_dmac_intf',
                [('bd', bt.stringify(bd_int_val)),
                 ('dmac', bt.mac_to_binary(dmac_string)),
                 ('intf', bt.stringify(intf_int_val))])

    def key_send_frame(self, bd_int_val):
        return ('send_frame', [self.Exact('meta.fwd_metadata.out_bd',
                               bt.stringify(bd_int_val))])

    def act_rewrite_mac(self, smac_string):
        return ('rewrite_mac', [('smac', bt.mac_to_binary(smac_string))])


class FwdTest(Demo1Test):
    @bt.autocleanup
    def runTest(self):
        in_dmac = 'ee:30:ca:9d:1e:00'
        in_smac = 'ee:cd:00:7e:70:00'
        ip_dst_addr = '10.1.0.1'
        ig_port = 1

        eg_port = 2
        l2ptr = 58
        bd = 9
        out_dmac = '02:13:57:ab:cd:ef'
        out_smac = '00:11:22:33:44:55'

        # Before adding any table entries, the default behavior for
        # sending in an IPv4 packet is to drop it.
        pkt = tu.simple_tcp_packet(eth_src=in_smac, eth_dst=in_dmac,
                                   ip_dst=ip_dst_addr, ip_ttl=64)
        tu.send_packet(self, ig_port, pkt)
        tu.verify_no_other_packets(self)
        
        # Add a set of table entries that the packet should match, and
        # be forwarded out with the desired dest and source MAC
        # addresses.
        self.table_add(self.key_ipv4_da_lpm(ip_dst_addr, 32),
                       self.act_set_l2ptr(l2ptr))
        self.table_add(self.key_mac_da(l2ptr),
                       self.act_set_bd_dmac_intf(bd, out_dmac, eg_port))
        self.table_add(self.key_send_frame(bd), self.act_rewrite_mac(out_smac))

        # Check that the entry is hit, expected source and dest MAC
        # have been written into output packet, TTL has been
        # decremented, and that no other packets are received.
        exp_pkt = tu.simple_tcp_packet(eth_src=out_smac, eth_dst=out_dmac,
                                       ip_dst=ip_dst_addr, ip_ttl=63)
        tu.send_packet(self, ig_port, pkt)
        tu.verify_packets(self, exp_pkt, [eg_port])


class PrefixLen0Test(Demo1Test):
    @bt.autocleanup
    def runTest(self):
        in_dmac = 'ee:30:ca:9d:1e:00'
        in_smac = 'ee:cd:00:7e:70:00'
        ig_port = 1

        entries = []
        # 'ip_dst_addr' and 'prefix_len' fields represent the key to
        # add to the LPM table.  'pkt_in_dst_addr' is one IPv4 address
        # such that if a packet is sent in with that as the dest
        # address, it should match the given table entry, not one of
        # the others.  There may be many other such addresses, but we
        # just need one for this particular test.
        entries.append({'ip_dst_addr': '10.1.0.1',
                        'prefix_len': 32,
                        'pkt_in_dst_addr': '10.1.0.1',
                        'eg_port': 2,
                        'l2ptr': 58,
                        'bd': 9,
                        'out_dmac': '02:13:57:ab:cd:ef',
                        'out_smac': '00:11:22:33:44:55'})
        entries.append({'ip_dst_addr': '10.1.0.0',
                        'prefix_len': 16,
                        'pkt_in_dst_addr': '10.1.2.3',
                        'eg_port': 3,
                        'l2ptr': 59,
                        'bd': 10,
                        'out_dmac': '02:13:57:ab:cd:f0',
                        'out_smac': '00:11:22:33:44:56'})
        entries.append({'ip_dst_addr': '0.0.0.0',
                        'prefix_len': 0,
                        'pkt_in_dst_addr': '20.0.0.1',
                        'eg_port': 4,
                        'l2ptr': 60,
                        'bd': 11,
                        'out_dmac': '02:13:57:ab:cd:f1',
                        'out_smac': '00:11:22:33:44:57'})

        for e in entries:
            self.table_add(self.key_ipv4_da_lpm(e['ip_dst_addr'],
                                                e['prefix_len']),
                           self.act_set_l2ptr(e['l2ptr']))
            self.table_add(self.key_mac_da(e['l2ptr']),
                           self.act_set_bd_dmac_intf(e['bd'], e['out_dmac'],
                                                     e['eg_port']))
            self.table_add(self.key_send_frame(e['bd']),
                           self.act_rewrite_mac(e['out_smac']))

        ttl_in = 100
        for e in entries:
            ip_dst_addr = e['pkt_in_dst_addr']
            eg_port = e['eg_port']
            pkt_in = tu.simple_tcp_packet(eth_src=in_smac, eth_dst=in_dmac,
                                          ip_dst=ip_dst_addr, ip_ttl=ttl_in)
            exp_pkt = tu.simple_tcp_packet(eth_src=e['out_smac'],
                                           eth_dst=e['out_dmac'],
                                           ip_dst=ip_dst_addr,
                                           ip_ttl=ttl_in - 1)
            tu.send_packet(self, ig_port, pkt_in)
            tu.verify_packets(self, exp_pkt, [eg_port])
            # Vary TTL in for each packet tested, just to make them
            # easy to distinguish from each other.
            ttl_in = ttl_in - 10


class DupEntryTest(Demo1Test):
    @bt.autocleanup
    def runTest(self):
        ip_dst_addr = '10.0.0.1'
        l2ptr = 58

        def add_entry_once():
            self.table_add(self.key_ipv4_da_lpm(ip_dst_addr, 32),
                           self.act_set_l2ptr(l2ptr))

        add_entry_once()
        with self.assertP4RuntimeError():
            add_entry_once()
