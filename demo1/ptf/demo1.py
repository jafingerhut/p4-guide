#!/usr/bin/env python3

# Copyright 2023 Intel Corporation
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
import ptf.testutils as tu
from ptf.base_tests import BaseTest
import p4runtime_sh.shell as sh
import p4runtime_shell_utils as p4rtutil


# Links to many Python methods useful when writing automated tests:

# The package `ptf.testutils` contains many useful Python methods for
# writing automated tests, some of which are demonstrated below with
# calls prefixed by the local alias `tu.`.  You can see the
# definitions for all Python code in this package, including some
# documentation for these methods, here:

# https://github.com/p4lang/ptf/blob/master/src/ptf/testutils.py


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
ch.setLevel(logging.INFO)
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

class Demo1Test(BaseTest):
    def setUp(self):
        # Setting up PTF dataplane
        self.dataplane = ptf.dataplane_instance
        self.dataplane.flush()

        logging.debug("Demo1Test.setUp()")
        grpc_addr = tu.test_param_get("grpcaddr")
        if grpc_addr is None:
            grpc_addr = 'localhost:9559'
        p4info_txt_fname = tu.test_param_get("p4info")
        p4prog_binary_fname = tu.test_param_get("config")
        sh.setup(device_id=0,
                 grpc_addr=grpc_addr,
                 election_id=(0, 1), # (high_32bits, lo_32bits)
                 config=sh.FwdPipeConfig(p4info_txt_fname, p4prog_binary_fname),
                 verbose=False)
        #p4rtutil.dump_table("ipv4_da_lpm")
        #p4rtutil.dump_table("mac_da")
        #p4rtutil.dump_table("send_frame")

    def tearDown(self):
        logging.debug("Demo1Test.tearDown()")
        sh.teardown()

#############################################################
# Define a few small helper functions that make adding entries to
# particular tables in demo2.p4 slightly shorter to write.
#############################################################

def add_ipv4_da_lpm_entry_action_set_l2ptr(ipv4_addr_str, prefix_len_int,
                                           l2ptr_int):
    te = sh.TableEntry('ipv4_da_lpm')(action='set_l2ptr')
    # Note: p4runtime-shell raises an exception if you attempt to
    # explicitly assign to te.match['dstAddr'] a prefix with length 0.
    # Just skip assigning to te.match['dstAddr'] completely, and then
    # inserting the entry will give a wildcard match for that field,
    # as defined in the P4Runtime API spec.
    if prefix_len_int != 0:
        te.match['dstAddr'] = '%s/%d' % (ipv4_addr_str, prefix_len_int)
    te.action['l2ptr'] = '%d' % (l2ptr_int)
    te.insert()

def add_mac_da_entry_action_set_bd_dmac_intf(l2ptr_int, bd_int, dmac_str,
                                             intf_int):
    te = sh.TableEntry('mac_da')(action='set_bd_dmac_intf')
    te.match['l2ptr'] = '%d' % (l2ptr_int)
    te.action['bd'] = '%d' % (bd_int)
    te.action['dmac'] = dmac_str
    te.action['intf'] = '%d' % (intf_int)
    te.insert()

def add_send_frame_entry_action_rewrite_mac(out_bd_int, smac_str):
    te = sh.TableEntry('send_frame')(action='rewrite_mac')
    te.match['out_bd'] = '%d' % (out_bd_int)
    te.action['smac'] = smac_str
    te.insert()

class FwdTest(Demo1Test):
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
        add_ipv4_da_lpm_entry_action_set_l2ptr(ip_dst_addr, 32, l2ptr)
        add_mac_da_entry_action_set_bd_dmac_intf(l2ptr, bd, out_dmac, eg_port)
        add_send_frame_entry_action_rewrite_mac(bd, out_smac)

        # Check that the entry is hit, expected source and dest MAC
        # have been written into output packet, TTL has been
        # decremented, and that no other packets are received.
        exp_pkt = tu.simple_tcp_packet(eth_src=out_smac, eth_dst=out_dmac,
                                       ip_dst=ip_dst_addr, ip_ttl=63)
        tu.send_packet(self, ig_port, pkt)
        tu.verify_packets(self, exp_pkt, [eg_port])


class PrefixLen0Test(Demo1Test):
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
            add_ipv4_da_lpm_entry_action_set_l2ptr(e['ip_dst_addr'],
                                                   e['prefix_len'], e['l2ptr'])
            add_mac_da_entry_action_set_bd_dmac_intf(e['l2ptr'], e['bd'],
                                                     e['out_dmac'],
                                                     e['eg_port'])
            add_send_frame_entry_action_rewrite_mac(e['bd'], e['out_smac'])

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
    def runTest(self):
        ip_dst_addr = '10.0.0.1'
        l2ptr = 58

        def add_entry_once():
            add_ipv4_da_lpm_entry_action_set_l2ptr(ip_dst_addr, 32, l2ptr)

        add_entry_once()
        with p4rtutil.assertP4RuntimeError(self):
            add_entry_once()
