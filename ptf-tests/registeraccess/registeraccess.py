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
import p4runtime_shell_utils as shu
import scapy.all as scapy


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


verbose = False

def get_exp_num_packetins(pktin, exp_num_packets, timeout_sec):
    pktlist = []
    pktin.sniff(lambda p: pktlist.append(p), timeout=timeout_sec)
    assert len(pktlist) == exp_num_packets
    return pktlist


class RegisterAccessTest(BaseTest):
    CPU_PORT = 510

    def setUp(self):
        # Setting up PTF dataplane
        self.dataplane = ptf.dataplane_instance
        self.dataplane.flush()

        logging.info("RegisterAccessTest.setUp()")
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

        # Create Python dicts from name to integer values, and integer
        # values to names, for the P4_16 serializable enum types
        # PuntReason_t and ControllerOpcode_t once here during setup.
        logging.info("Reading p4info from {}".format(p4info_txt_fname))
        p4info_data = shu.read_p4info_txt_file(p4info_txt_fname)

        self.punt_reason_name2int, self.punt_reason_int2name = \
            shu.serializable_enum_dict(p4info_data, 'PuntReason_t')
        self.opcode_name2int, self.opcode_int2name = \
            shu.serializable_enum_dict(p4info_data, 'ControllerOpcode_t')
        logging.debug("punt_reason_name2int=%s" % (self.punt_reason_name2int))
        logging.debug("punt_reason_int2name=%s" % (self.punt_reason_int2name))
        logging.debug("opcode_name2int=%s" % (self.opcode_name2int))
        logging.debug("opcode_int2name=%s" % (self.opcode_int2name))

        self.p4info_obj_map = shu.make_p4info_obj_map(p4info_data)
        self.cpm_packetin_id2data = \
            shu.controller_packet_metadata_dict_key_id(self.p4info_obj_map,
                                                       "packet_in")
        logging.debug("cpm_packetin_id2data=%s" % (self.cpm_packetin_id2data))

        self.pktin = sh.PacketIn()

    def tearDown(self):
        logging.info("RegisterAccessTest.tearDown()")
        sh.teardown()

    def write_SeqNumReg(self, idx_int, seqnum_int):
        logging.info("write_seqNumReg idx={} seqnum={}".format(
            idx_int, seqnum_int))
        # Giving an explicit dst MAC address here avoids some warnings
        # from Scapy.
        pkt = scapy.Ether(dst='00:00:00:00:00:00')
        pktout = sh.PacketOut()
        pktout.payload = bytes(pkt)
        pktout.metadata['opcode'] = \
            '%d' % (self.opcode_name2int['WRITE_REGISTER'])
        pktout.metadata['reserved1'] = '0'
        pktout.metadata['operand0'] = '%d' % (idx_int)
        pktout.metadata['operand1'] = '%d' % (seqnum_int)
        pktout.metadata['operand2'] = '0'
        pktout.metadata['operand3'] = '0'
        pktout.send()
        if verbose:
            logging.info("write_seqNumReg pktout={}".format(pktout))

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
        if verbose:
            logging.info("write_seqNumReg exp_pktinfo={}".format(exp_pktinfo))
        tu.verify_no_other_packets(self)
        pktlist = get_exp_num_packetins(self.pktin, 1, 2)
        pkt_pb = pktlist[0]
        pktinfo = shu.decode_packet_in_metadata(self.cpm_packetin_id2data,
                                                pkt_pb.packet)
        if verbose:
            logging.info("write_seqNumReg pktinfo={}".format(pktinfo))
        shu.verify_packet_in(exp_pktinfo, pktinfo)

    def read_SeqNumReg(self, idx_int):
        logging.info("read_seqNumReg idx={}".format(idx_int))
        pkt = scapy.Ether(dst='00:00:00:00:00:00')
        pktout = sh.PacketOut()
        pktout.payload = bytes(pkt)
        pktout.metadata['opcode'] = \
            '%d' % (self.opcode_name2int['READ_REGISTER'])
        pktout.metadata['reserved1'] = '0'
        pktout.metadata['operand0'] = '%d' % (idx_int)
        pktout.metadata['operand1'] = '0'
        pktout.metadata['operand2'] = '0'
        pktout.metadata['operand3'] = '0'
        pktout.send()
        if verbose:
            logging.info("read_seqNumReg pktout={}".format(pktout))

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
        pktlist = get_exp_num_packetins(self.pktin, 1, 2)
        pkt_pb = pktlist[0]
        pktinfo = shu.decode_packet_in_metadata(self.cpm_packetin_id2data,
                                                pkt_pb.packet)

        # We want to check the contents of the response packet that
        # comes back from reading, but we want this function to work
        # even if we do not know what the read value is.  So take the
        # read value from the response packet, and make that value
        # part of the expected value.  That field will thus always
        # match.  We will still catch any problems if any of the other
        # fields contain unxpected values.
        seqnum_int = pktinfo['metadata']['operand1']
        logging.info("read_seqNumReg idx={} seqnum={}".format(idx_int,
                                                              seqnum_int))
        exp_pktinfo['metadata']['operand1'] = seqnum_int
        if verbose:
            logging.info("read_seqNumReg exp_pktinfo={}".format(exp_pktinfo))
            logging.info("read_seqNumReg pktinfo={}".format(pktinfo))
        shu.verify_packet_in(exp_pktinfo, pktinfo)
        return seqnum_int

    def make_pkt(self, idx, pkt_seqnum):
        ip_dst_addr = '10.1.1.%d' % (idx)
        return tu.simple_tcp_packet(ip_dst=ip_dst_addr, ip_id=pkt_seqnum)

    def send_pkt_expect_it_passed(self, idx, pkt_seqnum):
        ig_port = 0
        eg_port = 2

        pkt_in = self.make_pkt(idx, pkt_seqnum)
        logging.info("Sending data packet with seqnum={}"
                     " expecting it to be forwarded".format(pkt_seqnum))
        tu.send_packet(self, ig_port, pkt_in)

        exp_pkt = pkt_in
        exp_next_seqnum = (pkt_seqnum + 1) % (1 << 16)
        tu.verify_packets(self, exp_pkt, [eg_port])
        seqnum_read_val = self.read_SeqNumReg(idx)
        if seqnum_read_val != exp_next_seqnum:
            logging.error("seqnum_read_val={} != {}=exp_next_seqnum"
                          " pkt_seqnum={}".format(
                              seqnum_read_val, exp_next_seqnum, pkt_seqnum))
            assert seqnum_read_val == exp_next_seqnum

    def send_pkt_expect_it_dropped(self, idx, pkt_seqnum):
        ig_port = 0
        eg_port = 2

        pkt_in = self.make_pkt(idx, pkt_seqnum)
        logging.info("Sending data packet with seqnum={}"
                     " expecting it to be dropped".format(pkt_seqnum))
        tu.send_packet(self, ig_port, pkt_in)
        tu.verify_no_other_packets(self)


class WriteRegThenReadTest(RegisterAccessTest):
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


class PacketsUpdateRegisterTest(RegisterAccessTest):
    def runTest(self):
        seqnum_idx = 20

        self.write_SeqNumReg(seqnum_idx, 0)
        seqnum_read_val = self.read_SeqNumReg(seqnum_idx)
        assert seqnum_read_val == 0

        full_seqnum_span = (1 << 16)
        half_seqnum_span = (1 << 15)
        # Sending expected seqnum value should pass the packet
        self.send_pkt_expect_it_passed(idx=seqnum_idx, pkt_seqnum=0)
        self.send_pkt_expect_it_passed(idx=seqnum_idx, pkt_seqnum=1)
        # And packet should also be passed if pkt seqnum is
        # (half_seqnum_span-1) larger than the expected seqnum, with
        # wrapping.
        self.send_pkt_expect_it_passed(idx=seqnum_idx,
                                       pkt_seqnum=half_seqnum_span)
        self.send_pkt_expect_it_passed(idx=seqnum_idx,
                                       pkt_seqnum=full_seqnum_span-1)
        seqnum_read_val = self.read_SeqNumReg(seqnum_idx)
        assert seqnum_read_val == 0

        # Packets should be dropped if they are anywhere in the
        # 'previous half space', with wrapping.
        self.send_pkt_expect_it_dropped(idx=seqnum_idx,
                                        pkt_seqnum=half_seqnum_span)
        self.send_pkt_expect_it_dropped(idx=seqnum_idx,
                                        pkt_seqnum=full_seqnum_span-1)
        seqnum_read_val = self.read_SeqNumReg(seqnum_idx)
        assert seqnum_read_val == 0

        self.send_pkt_expect_it_passed(idx=seqnum_idx,
                                       pkt_seqnum=half_seqnum_span-1)
        self.send_pkt_expect_it_dropped(idx=seqnum_idx, pkt_seqnum=0)
        self.send_pkt_expect_it_dropped(idx=seqnum_idx,
                                        pkt_seqnum=half_seqnum_span-1)
        seqnum_read_val = self.read_SeqNumReg(seqnum_idx)
        assert seqnum_read_val == half_seqnum_span
