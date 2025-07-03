#!/usr/bin/env python3

# Copyright 2025 Andy Fingerhut
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
import ptf.packet as packet
import ptf.testutils as tu
from ptf.base_tests import BaseTest
import p4runtime_sh.shell as sh
import p4runtime_shell_utils as shu


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

IN_IP_SRC_ADDR = '0::0'
MISS_IP_SRC_ADDR = 'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff'

class LpmTesterTest(BaseTest):
    def setUp(self):
        # Setting up PTF dataplane
        self.dataplane = ptf.dataplane_instance
        self.dataplane.flush()

        logging.debug("LpmTesterTest.setUp()")
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
        #shu.dump_table("ipv4_da_lpm")
        #shu.dump_table("mac_da")
        #shu.dump_table("send_frame")

    def tearDown(self):
        logging.debug("LpmTesterTest.tearDown()")
        sh.teardown()

#############################################################
# Define a few small helper functions that make adding entries to
# particular tables in demo2.p4 slightly shorter to write.
#############################################################

def int_to_ipv6_addr(n):
    assert 0 <= n
    assert n < (1 << 128)
    hex_str = '%032x' % (n)
    lst = []
    while len(hex_str) > 0:
        lst.append(hex_str[:4])
        hex_str = hex_str[4:]
    return ':'.join(lst)

def fail_if_table_not_empty(table_name):
    nentries = shu.entry_count(table_name)
    if nentries == 0:
        logging.info("Table '%s' has 0 entries, as expected"
                     "" % (table_name))
    else:
        logging.error("Expected table '%s' to be empty, but it contains %d entries:"
                      "" % (table_name, nentries))
        shu.entry_count(table_name, print_entries=True)
        assert nentries != 0

# TODO: Verify that some kind of error is returned, or exception is
# raised, if we attempt to insert a prefix that is already inserted,
# or to delete a prefix that is not currently in the table.  Add extra
# error checking if that is not the case.

def insert_lpm_entry(prefix_str, prefix_len_int, entry_id_int):
    te = sh.TableEntry('ipv6_da_lpm')(action='hit_action')
    # Note: p4runtime-shell raises an exception if you attempt to
    # explicitly assign to te.match['dstAddr'] a prefix with length 0.
    # Just skip assigning to te.match['dstAddr'] completely, and then
    # inserting the entry will give a wildcard match for that field,
    # as defined in the P4Runtime API spec.
    if prefix_len_int != 0:
        te.match['dst_addr'] = '%s/%d' % (prefix_str, prefix_len_int)
    te.action['entry_id'] = '%d' % (entry_id_int)
    te.insert()

def delete_lpm_entry(prefix_str, prefix_len_int):
    te = sh.TableEntry('ipv6_da_lpm')(action='set_l2ptr')
    if prefix_len_int != 0:
        te.match['dst_addr'] = '%s/%d' % (prefix_str, prefix_len_int)
    te.delete()

def simple_ipv6_pkt(src_ip, dst_ip,
                    ipv6_fl=0,
                    ipv6_tc=0,
                    ipv6_hlim=64):
    dmac = 'ee:30:ca:9d:1e:00'
    smac = 'ee:cd:00:7e:70:00'
    pkt = packet.Ether(dst=dmac, src=smac)
    pkt /= packet.IPv6(
        src=src_ip, dst=dst_ip, fl=ipv6_fl, tc=ipv6_tc, hlim=ipv6_hlim
    )
    return pkt

def verify_lookup_misses(self, ip_dst_addr):
    in_dmac = 'ee:30:ca:9d:1e:00'
    in_smac = 'ee:cd:00:7e:70:00'
    ig_port = 1
    eg_port = 1
    pkt = simple_ipv6_pkt(IN_IP_SRC_ADDR, ip_dst_addr)
    tu.send_packet(self, ig_port, pkt)
    # Check that the lookup misses, by confirming that its IPv6 source
    # address is replaced with the expected value encoding a lookup
    # miss.
    pkt[IPv6].src = MISS_IP_SRC_ADDR
    #logging.info("BasicTest1 show exp_pkt #1")
    #pkt.show()
    tu.verify_packets(self, pkt, [eg_port])

def verify_lookup_hits(self, ip_dst_addr, expected_entry_id):
    in_dmac = 'ee:30:ca:9d:1e:00'
    in_smac = 'ee:cd:00:7e:70:00'
    ig_port = 1
    eg_port = 1
    pkt = simple_ipv6_pkt(IN_IP_SRC_ADDR, ip_dst_addr)
    tu.send_packet(self, ig_port, pkt)
    # Check that the desired entry is hit, by confirming that its IPv6
    # source address is replaced with the expected entry id.
    pkt[IPv6].src = int_to_ipv6_addr(expected_entry_id)
    #logging.info("BasicTest1 show exp_pkt #2")
    #pkt.show()
    tu.verify_packets(self, pkt, [eg_port])


class BasicTest1(LpmTesterTest):
    def runTest(self):
        ip_dst_addr = 'fe80::1'
        fail_if_table_not_empty('ipv6_da_lpm')
        # Before adding any table entries, verify with at least one
        # lookup key that the table gives a miss.
        verify_lookup_misses(self, ip_dst_addr)
        # Add a single table entry that the next packet should match.
        entry_id = 42
        insert_lpm_entry('fe80::0', 10, entry_id)
        verify_lookup_hits(self, ip_dst_addr, entry_id)


class BasicTest2(LpmTesterTest):
    def runTest(self):
        ip_dst_addr = 'fe80::1'
        fail_if_table_not_empty('ipv6_da_lpm')
        verify_lookup_misses(self, ip_dst_addr)
