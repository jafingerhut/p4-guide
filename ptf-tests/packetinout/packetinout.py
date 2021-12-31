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


class PacketInOutTest(bt.P4RuntimeTest):
    CPU_PORT = 510

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
        # Create Python dicts from name to integer values, and integer
        # values to names, for the P4_16 serializable enum types
        # PuntReason_t and ControllerOpcode_t once here during setup.
        self.punt_reason_name2int, self.punt_reason_int2name = \
            self.serializable_enum_dict('PuntReason_t')
        self.opcode_name2int, self.opcode_int2name = \
            self.serializable_enum_dict('ControllerOpcode_t')

    #############################################################
    # Define a few small helper functions that help construct
    # parameters for the table_add() method.
    #############################################################

    def key_ipv4_da_lpm(self, ipv4_addr_string, prefix_len):
        return ('ipv4_da_lpm',
                [self.Lpm('hdr.ipv4.dstAddr',
                          bt.ipv4_to_int(ipv4_addr_string), prefix_len)])

    def act_set_port(self, port_int):
        return ('set_port', [('port', port_int)])

    def act_punt_to_controller(self):
        return ('punt_to_controller', [])


class FwdTest(PacketInOutTest):
    @bt.autocleanup
    def runTest(self):
        in_dmac = 'ee:30:ca:9d:1e:00'
        in_smac = 'ee:cd:00:7e:70:00'
        ig_port = 1
        eg_port = 1

        entries = []
        entries.append({'ip_dst_addr': '10.1.0.1',
                        'prefix_len': 32,
                        'pkt_in_dst_addr': '10.1.0.1',
                        'pkt_in_ig_port': 1,
                        'eg_port': 2})
        entries.append({'ip_dst_addr': '10.1.0.2',
                        'prefix_len': 32,
                        'pkt_in_dst_addr': '10.1.0.2',
                        'pkt_in_ig_port': 2,
                        'eg_port': self.CPU_PORT})
        entries.append({'ip_dst_addr': '10.1.0.3',
                        'prefix_len': 32,
                        'pkt_in_dst_addr': '10.1.0.3',
                        'pkt_in_ig_port': 3,
                        'eg_port': self.CPU_PORT})

        # Add a set of table entries
        for e in entries:
            if e['eg_port'] == self.CPU_PORT:
                action = self.act_punt_to_controller()
            else:
                action = self.act_set_port(e['eg_port'])
            self.table_add(self.key_ipv4_da_lpm(e['ip_dst_addr'],
                                                e['prefix_len']),
                           action)

        ttl_in = 200
        for e in entries:
            ip_dst_addr = e['pkt_in_dst_addr']
            ig_port = e['pkt_in_ig_port']
            eg_port = e['eg_port']
            pkt_in = tu.simple_tcp_packet(eth_src=in_smac, eth_dst=in_dmac,
                                          ip_dst=ip_dst_addr, ip_ttl=ttl_in)
            tu.send_packet(self, ig_port, pkt_in)
            if eg_port == self.CPU_PORT:
                # Packet should not go out of a regular port, but to
                # the CPU port, and then arrive to the controller as a
                # PacketIn message.
                pkt_pb = self.get_packet_in()
                #print("pkt=%s" % (pkt_pb))
                pktinfo = self.decode_packet_in_metadata(pkt_pb)
                exp_pktinfo = \
                    {'metadata':
                     {'input_port': ig_port,
                      'punt_reason': self.punt_reason_name2int['DEST_ADDRESS_FOR_US'],
                      'opcode': 0, 'operand0': 0, 'operand1': 0,
                      'operand2': 0, 'operand3': 0},
                     'payload': bytes(pkt_in)}
                self.verify_packet_in(exp_pktinfo, pktinfo)
                tu.verify_no_other_packets(self)
            else:
                exp_pkt = tu.simple_tcp_packet(eth_src=in_smac, eth_dst=in_dmac,
                                               ip_dst=ip_dst_addr,
                                               ip_ttl=ttl_in - 1)
                tu.verify_packets(self, exp_pkt, [eg_port])
                # Verify that no PacketIn message was received
                pkt_pb = self.get_packet_in()
                assert pkt_pb is None

            # Vary TTL in for each packet tested, just to make them
            # easy to distinguish from each other.
            ttl_in = ttl_in - 2


class IPOptionsTest(PacketInOutTest):
    @bt.autocleanup
    def runTest(self):
        in_dmac = 'ee:30:ca:9d:1e:00'
        in_smac = 'ee:cd:00:7e:70:00'
        ig_port = 1
        eg_port = 1

        entries = []
        entries.append({'ip_dst_addr': '10.1.0.1',
                        'prefix_len': 32,
                        'pkt_in_dst_addr': '10.1.0.1',
                        'pkt_in_ig_port': 1,
                        'eg_port': 2})
        entries.append({'ip_dst_addr': '10.1.0.2',
                        'prefix_len': 32,
                        'pkt_in_dst_addr': '10.1.0.2',
                        'pkt_in_ig_port': 2,
                        'eg_port': self.CPU_PORT})

        # Add a set of table entries
        for e in entries:
            if e['eg_port'] == self.CPU_PORT:
                action = self.act_punt_to_controller()
            else:
                action = self.act_set_port(e['eg_port'])
            self.table_add(self.key_ipv4_da_lpm(e['ip_dst_addr'],
                                                e['prefix_len']),
                           action)

        ttl_in = 200
        for e in entries:
            ip_dst_addr = e['pkt_in_dst_addr']
            ig_port = e['pkt_in_ig_port']
            eg_port = e['eg_port']
            for send_ip_options in [False, True]:
                pkt_in = tu.simple_tcp_packet(eth_src=in_smac, eth_dst=in_dmac,
                                              ip_dst=ip_dst_addr, ip_ttl=ttl_in)
                if send_ip_options:
                    # We do not need to create a packet with 'valid'
                    # IPv4 options in the header.  We simply need to
                    # send a packet that has the ihl field of the Ipv4
                    # header greater than 5.  That is all that the P4
                    # program is using to distinguish packets with
                    # IPv4 options vs. those that do not.
                    pkt_in[IP].ihl = 6
                tu.send_packet(self, ig_port, pkt_in)
                if send_ip_options:
                    pkt_pb = self.get_packet_in()
                    pktinfo = self.decode_packet_in_metadata(pkt_pb)
                    exp_pktinfo = \
                        {'metadata':
                         {'input_port': ig_port,
                          'punt_reason': self.punt_reason_name2int['IP_OPTIONS'],
                          'opcode': 0, 'operand0': 0, 'operand1': 0,
                          'operand2': 0, 'operand3': 0},
                         'payload': bytes(pkt_in)}
                    self.verify_packet_in(exp_pktinfo, pktinfo)
                    tu.verify_no_other_packets(self)
                else:
                    if eg_port == self.CPU_PORT:
                        # Packet should not go out of a regular port,
                        # but to the CPU port, and then arrive to the
                        # controller as a PacketIn message.
                        pkt_pb = self.get_packet_in()
                        pktinfo = self.decode_packet_in_metadata(pkt_pb)
                        exp_pktinfo = \
                            {'metadata':
                             {'input_port': ig_port,
                              'punt_reason': self.punt_reason_name2int['DEST_ADDRESS_FOR_US'],
                              'opcode': 0, 'operand0': 0, 'operand1': 0,
                              'operand2': 0, 'operand3': 0},
                             'payload': bytes(pkt_in)}
                        self.verify_packet_in(exp_pktinfo, pktinfo)
                        tu.verify_no_other_packets(self)
                    else:
                        exp_pkt = tu.simple_tcp_packet(eth_src=in_smac, eth_dst=in_dmac,
                                                       ip_dst=ip_dst_addr,
                                                       ip_ttl=ttl_in - 1)
                        tu.verify_packets(self, exp_pkt, [eg_port])
                        # Verify that no PacketIn message was received
                        pkt_pb = self.get_packet_in()
                        assert pkt_pb is None

                # Vary TTL in for each packet tested, just to make
                # them easy to distinguish from each other.
                ttl_in = ttl_in - 2


class ControllerPacketToPortTest(PacketInOutTest):
    @bt.autocleanup
    def runTest(self):
        in_dmac = 'ee:30:ca:9d:1e:00'
        in_smac = 'ee:cd:00:7e:70:00'
        ip_dst_addr = '100.2.3.4'

        # No table entries required for testing this P4 program
        # behavior.  Just send in a packet from the controller to the
        # switch, and verify that it sends a packet out of the proper
        # switch port.

        ttl_in = 200
        for eg_port in [5, 8]:
            pkt = tu.simple_tcp_packet(eth_src=in_smac, eth_dst=in_dmac,
                                       ip_dst=ip_dst_addr, ip_ttl=ttl_in)
            exp_pkt = pkt
            pktout_dict = {'payload': bytes(pkt),
                           'metadata': {
                               'opcode': self.opcode_name2int['SEND_TO_PORT_IN_OPERAND0'],
                               'reserved1': 0,
                               'operand0': eg_port,
                               'operand1': 0,
                               'operand2': 0,
                               'operand3': 0}}
            pktout_pb = self.encode_packet_out_metadata(pktout_dict)
            self.send_packet_out(pktout_pb)
            tu.verify_packets(self, exp_pkt, [eg_port])
            # Verify that no PacketIn message was received
            pkt_pb = self.get_packet_in()
            assert pkt_pb is None
