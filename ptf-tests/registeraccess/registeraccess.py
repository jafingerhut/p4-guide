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
import scapy.all as scapy

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

    def write_SeqNumReg(self, idx_int, seqnum_int):
        logging.debug("write_seqNumReg idx={} seqnum={}".format(
            idx_int, seqnum_int))
        pkt = scapy.Ether()
        pktout_dict = {'payload': bytes(pkt),
                       'metadata': {
                           'opcode': self.opcode_name2int['WRITE_REGISTER'],
                           'reserved1': 0,
                           'operand0': idx_int,
                           'operand1': seqnum_int,
                           'operand2': 0,
                           'operand3': 0}}
        pktout_pb = self.encode_packet_out_metadata(pktout_dict)
        self.send_packet_out(pktout_pb)
        logging.debug("write_seqNumReg pktout_dict={}".format(pktout_dict))

        exp_pkt = pkt
        exp_pktinfo = \
            {'metadata':
             {'input_port': self.CPU_PORT,
              'punt_reason': self.punt_reason_name2int['OPERATION_RESPONSE'],
              'opcode': self.opcode_name2int['WRITE_REGISTER'],
              'operand0': idx_int,
              'operand1': seqnum_int,
              'operand2': 0,
              'operand3': 0},
             'payload': bytes(exp_pkt)}
        logging.debug("write_seqNumReg exp_pktinfo={}".format(exp_pktinfo))
        tu.verify_no_other_packets(self)
        pkt_pb = self.get_packet_in()
        pktinfo = self.decode_packet_in_metadata(pkt_pb)
        logging.debug("write_seqNumReg pktinfo={}".format(pktinfo))
        self.verify_packet_in(exp_pktinfo, pktinfo)

    def read_SeqNumReg(self, idx_int):
        logging.debug("read_seqNumReg idx={}".format(idx_int))
        pkt = scapy.Ether()
        pktout_dict = {'payload': bytes(pkt),
                       'metadata': {
                           'opcode': self.opcode_name2int['READ_REGISTER'],
                           'reserved1': 0,
                           'operand0': idx_int,
                           'operand1': 0,
                           'operand2': 0,
                           'operand3': 0}}
        pktout_pb = self.encode_packet_out_metadata(pktout_dict)
        self.send_packet_out(pktout_pb)
        logging.debug("read_seqNumReg pktout_dict={}".format(pktout_dict))

        exp_pkt = pkt
        exp_pktinfo = \
            {'metadata':
             {'input_port': self.CPU_PORT,
              'punt_reason': self.punt_reason_name2int['OPERATION_RESPONSE'],
              'opcode': self.opcode_name2int['READ_REGISTER'],
              'operand0': idx_int,
              'operand1': 0,
              'operand2': 0,
              'operand3': 0},
             'payload': bytes(exp_pkt)}
        tu.verify_no_other_packets(self)
        pkt_pb = self.get_packet_in()
        pktinfo = self.decode_packet_in_metadata(pkt_pb)

        # We want to check the contents of the response packet that
        # comes back from reading, but we want this function to work
        # even if we do not know what the read value is.  So take the
        # read value from the response packet, and make that value
        # part of the expected value.  That field will thus always
        # match.  We will still catch any problems if any of the other
        # fields contain unxpected values.
        seqnum_int = pktinfo['metadata']['operand1']
        exp_pktinfo['metadata']['operand1'] = seqnum_int
        logging.debug("read_seqNumReg exp_pktinfo={}".format(exp_pktinfo))
        logging.debug("read_seqNumReg pktinfo={}".format(pktinfo))
        self.verify_packet_in(exp_pktinfo, pktinfo)
        return seqnum_int


class WriteRegThenReadTest(PacketInOutTest):
    @bt.autocleanup
    def runTest(self):
        seqnum_idx1 = 20
        seqnum_val1 = 75

        seqnum_idx2 = 21
        seqnum_val2 = 88

        self.write_SeqNumReg(seqnum_idx1, seqnum_val1)
        self.write_SeqNumReg(seqnum_idx2, seqnum_val2)

        seqnum_read_val1 = self.read_SeqNumReg(seqnum_idx1)
        seqnum_read_val2 = self.read_SeqNumReg(seqnum_idx2)

        assert seqnum_read_val1 == seqnum_val1
        assert seqnum_read_val2 == seqnum_val2
