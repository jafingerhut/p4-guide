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


class PacketInOutTest(BaseTest):
    CPU_PORT = 510

    def setUp(self):
        # Setting up PTF dataplane
        self.dataplane = ptf.dataplane_instance
        self.dataplane.flush()

        logging.info("PacketInOutTest.setUp()")
        grpc_addr = tu.test_param_get("grpcaddr")
        if grpc_addr is None:
            grpc_addr = 'localhost:9559'
        p4info_txt_fname = tu.test_param_get("p4info")
        p4prog_binary_fname = tu.test_param_get("config")
        sh.setup(device_id=0,
                 grpc_addr=grpc_addr,
                 election_id=(0, 1), # (high_32bits, lo_32bits)
                 config=sh.FwdPipeConfig(p4info_txt_fname, p4prog_binary_fname))
        p4rtutil.dump_table("ipv4_da_lpm")

        # Create Python dicts from name to integer values, and integer
        # values to names, for the P4_16 serializable enum types
        # PuntReason_t and ControllerOpcode_t once here during setup.
        logging.info("Reading p4info from {}".format(p4info_txt_fname))
        p4info_data = p4rtutil.read_p4info_txt_file(p4info_txt_fname)

        self.punt_reason_name2int, self.punt_reason_int2name = \
            p4rtutil.serializable_enum_dict(p4info_data, 'PuntReason_t')
        self.opcode_name2int, self.opcode_int2name = \
            p4rtutil.serializable_enum_dict(p4info_data, 'ControllerOpcode_t')
        logging.debug("punt_reason_name2int=%s" % (self.punt_reason_name2int))
        logging.debug("punt_reason_int2name=%s" % (self.punt_reason_int2name))
        logging.debug("opcode_name2int=%s" % (self.opcode_name2int))
        logging.debug("opcode_int2name=%s" % (self.opcode_int2name))

        self.p4info_obj_map = p4rtutil.make_p4info_obj_map(p4info_data)
        self.cpm_packetin_id2data = \
            p4rtutil.controller_packet_metadata_dict_key_id(self.p4info_obj_map,
                                                            "packet_in")
        logging.debug("cpm_packetin_id2data=%s" % (self.cpm_packetin_id2data))

        self.pktin = sh.PacketIn()

    def tearDown(self):
        logging.info("PacketInOutTest.tearDown()")
        sh.teardown()

#############################################################
# Define a few small helper functions that help construct
# parameters for the table_add() method.
#############################################################

def add_ipv4_da_lpm_entry_action_set_port(ipv4_addr_str, prefix_len_int,
                                          port_int):
    te = sh.TableEntry('ipv4_da_lpm')(action='set_port')
    # Note: p4runtime-shell raises an exception if you attempt to
    # explicitly assign to te.match['dstAddr'] a prefix with length 0.
    # Just skip assigning to te.match['dstAddr'] completely, and then
    # inserting the entry will give a wildcard match for that field,
    # as defined in the P4Runtime API spec.
    if prefix_len_int != 0:
        te.match['dstAddr'] = '%s/%d' % (ipv4_addr_str, prefix_len_int)
    te.action['port'] = '%d' % (port_int)
    te.insert()

def add_ipv4_da_lpm_entry_action_punt_to_controller(ipv4_addr_str,
                                                    prefix_len_int):
    te = sh.TableEntry('ipv4_da_lpm')(action='punt_to_controller')
    if prefix_len_int != 0:
        te.match['dstAddr'] = '%s/%d' % (ipv4_addr_str, prefix_len_int)
    te.insert()

def get_exp_num_packetins(pktin, exp_num_packets, timeout_sec):
    pktlist = []
    pktin.sniff(lambda p: pktlist.append(p), timeout=timeout_sec)
    assert len(pktlist) == exp_num_packets
    return pktlist


class FwdTest(PacketInOutTest):
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
                add_ipv4_da_lpm_entry_action_punt_to_controller(
                    e['ip_dst_addr'], e['prefix_len'])
            else:
                add_ipv4_da_lpm_entry_action_set_port(
                    e['ip_dst_addr'], e['prefix_len'], e['eg_port'])

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
                pktlist = get_exp_num_packetins(self.pktin, 1, 2)
                pkt_pb = pktlist[0]
                pktinfo = p4rtutil.decode_packet_in_metadata(
                    self.cpm_packetin_id2data, pkt_pb.packet)
                exp_pktinfo = \
                    {'metadata':
                     {'input_port': ig_port,
                      'punt_reason': self.punt_reason_name2int['DEST_ADDRESS_FOR_US'],
                      'opcode': 0, 'operand0': 0, 'operand1': 0,
                      'operand2': 0, 'operand3': 0},
                     'payload': bytes(pkt_in)}
                p4rtutil.verify_packet_in(exp_pktinfo, pktinfo)
                tu.verify_no_other_packets(self)
            else:
                print("Sending packet expected to cause switch to send packet out port %d" % (eg_port))
                exp_pkt = tu.simple_tcp_packet(eth_src=in_smac, eth_dst=in_dmac,
                                               ip_dst=ip_dst_addr,
                                               ip_ttl=ttl_in - 1)
                tu.verify_packets(self, exp_pkt, [eg_port])
                # Verify that no PacketIn message was received
                pktlist = get_exp_num_packetins(self.pktin, 0, 2)

            # Vary TTL in for each packet tested, just to make them
            # easy to distinguish from each other.
            ttl_in = ttl_in - 2


class IPOptionsTest(PacketInOutTest):
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
                add_ipv4_da_lpm_entry_action_punt_to_controller(
                    e['ip_dst_addr'], e['prefix_len'])
            else:
                add_ipv4_da_lpm_entry_action_set_port(
                    e['ip_dst_addr'], e['prefix_len'], e['eg_port'])

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
                    # send a packet that has the ihl field of the IPv4
                    # header greater than 5.  That is all that the P4
                    # program is using to distinguish packets with
                    # IPv4 options vs. those that do not.
                    pkt_in[IP].ihl = 6
                tu.send_packet(self, ig_port, pkt_in)
                if send_ip_options:
                    pktlist = get_exp_num_packetins(self.pktin, 1, 2)
                    pkt_pb = pktlist[0]
                    pktinfo = p4rtutil.decode_packet_in_metadata(
                        self.cpm_packetin_id2data, pkt_pb.packet)
                    exp_pktinfo = \
                        {'metadata':
                         {'input_port': ig_port,
                          'punt_reason': self.punt_reason_name2int['IP_OPTIONS'],
                          'opcode': 0, 'operand0': 0, 'operand1': 0,
                          'operand2': 0, 'operand3': 0},
                         'payload': bytes(pkt_in)}
                    p4rtutil.verify_packet_in(exp_pktinfo, pktinfo)
                    tu.verify_no_other_packets(self)
                else:
                    if eg_port == self.CPU_PORT:
                        # Packet should not go out of a regular port,
                        # but to the CPU port, and then arrive to the
                        # controller as a PacketIn message.
                        pktlist = get_exp_num_packetins(self.pktin, 1, 2)
                        pkt_pb = pktlist[0]
                        pktinfo = p4rtutil.decode_packet_in_metadata(
                            self.cpm_packetin_id2data, pkt_pb.packet)
                        exp_pktinfo = \
                            {'metadata':
                             {'input_port': ig_port,
                              'punt_reason': self.punt_reason_name2int['DEST_ADDRESS_FOR_US'],
                              'opcode': 0, 'operand0': 0, 'operand1': 0,
                              'operand2': 0, 'operand3': 0},
                             'payload': bytes(pkt_in)}
                        p4rtutil.verify_packet_in(exp_pktinfo, pktinfo)
                        tu.verify_no_other_packets(self)
                    else:
                        exp_pkt = tu.simple_tcp_packet(eth_src=in_smac, eth_dst=in_dmac,
                                                       ip_dst=ip_dst_addr,
                                                       ip_ttl=ttl_in - 1)
                        tu.verify_packets(self, exp_pkt, [eg_port])
                        # Verify that no PacketIn message was received
                        pktlist = get_exp_num_packetins(self.pktin, 0, 2)

                # Vary TTL in for each packet tested, just to make
                # them easy to distinguish from each other.
                ttl_in = ttl_in - 2


class ControllerPacketToPortTest(PacketInOutTest):
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
            pktout = sh.PacketOut()
            pktout.payload = bytes(pkt)
            pktout.metadata['opcode'] = \
                '%d' % (self.opcode_name2int['SEND_TO_PORT_IN_OPERAND0'])
            pktout.metadata['reserved1'] = '0'
            pktout.metadata['operand0'] = '%d' % (eg_port)
            pktout.metadata['operand1'] = '0'
            pktout.metadata['operand2'] = '0'
            pktout.metadata['operand3'] = '0'
            pktout.send()
            tu.verify_packets(self, exp_pkt, [eg_port])
            # Verify that no PacketIn message was received
            pktlist = get_exp_num_packetins(self.pktin, 0, 2)
