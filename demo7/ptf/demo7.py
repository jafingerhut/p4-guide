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


def int_to_mac_string(mac_int):
    assert isinstance(mac_int, int)
    assert (0 <= mac_int) and (mac_int < (1 << 48))
    return ('%02x:%02x:%02x:%02x:%02x:%02x'
            % ((mac_int >> 40) & 0xff,
               (mac_int >> 32) & 0xff,
               (mac_int >> 24) & 0xff,
               (mac_int >> 16) & 0xff,
               (mac_int >>  8) & 0xff,
               (mac_int >>  0) & 0xff))


def set_of_all_ports():
    """Return a set of all ports.  Assumes a single device."""
    portmap = ptf.config['port_map']
    port_set = set()
    for t, intf_name in portmap.items():
        #device = t[0]
        port = t[1]
        #print("device=%d port=%d intf_name=%s" % (device, port, intf_name))
        port_set.add(port)
    return port_set


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


class Demo7Test(BaseTest):
    def setUp(self):
        # Setting up PTF dataplane
        self.dataplane = ptf.dataplane_instance
        self.dataplane.flush()

        logging.info("Demo7Test.setUp()")
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
        p4rtutil.dump_table("ipv4_mc_route_lookup")
        p4rtutil.dump_table("send_frame")

    def tearDown(self):
        logging.info("Demo7Test.tearDown()")
        sh.teardown()

#############################################################
# Define a few small helper functions that help construct
# parameters for the table_add() method.
#############################################################

def add_ipv4_mc_route_lookup_entry_action_set_mcast_grp(ipv4_addr_str,
                                                        prefix_len_int,
                                                        mcast_grp_int):
    te = sh.TableEntry('ipv4_mc_route_lookup')(action='set_mcast_grp')
    # Note: p4runtime-shell raises an exception if you attempt to
    # explicitly assign to te.match['dstAddr'] a prefix with length 0.
    # Just skip assigning to te.match['dstAddr'] completely, and then
    # inserting the entry will give a wildcard match for that field,
    # as defined in the P4Runtime API spec.
    if prefix_len_int != 0:
        te.match['dstAddr'] = '%s/%d' % (ipv4_addr_str, prefix_len_int)
    te.action['mcast_grp'] = '%d' % (mcast_grp_int)
    te.insert()

def add_send_frame_entry_action_rewrite_mac(eg_port_int, smac_str):
    te = sh.TableEntry('send_frame')(action='rewrite_mac')
    te.match['egress_port'] = '%d' % (eg_port_int)
    te.action['smac'] = smac_str
    te.insert()


class FwdTest(Demo7Test):
    def runTest(self):
        in_dmac = 'ee:30:ca:9d:1e:00'
        in_smac = 'ee:cd:00:7e:70:00'
        ip_dst_addr = '224.3.3.3'
        ig_port = 1

        mcast_grp = 91
        port_to_smac = {0: '00:de:ad:00:00:ff',
                        1: '00:de:ad:11:11:ff',
                        2: '00:de:ad:22:22:ff',
                        3: '00:de:ad:33:33:ff',
                        4: '00:de:ad:44:44:ff',
                        5: '00:de:ad:55:55:ff'}

        for eg_port, smac in port_to_smac.items():
            logging.info("adding table entry for eg_port=%d -> smac=%s"
                         "" % (eg_port, smac))
            add_send_frame_entry_action_rewrite_mac(eg_port, smac)

        all_ports = set_of_all_ports()

        # When a packet is sent from ingress to the packet buffer with
        # mcast_grp=91, configure the (egress_port, instance) places
        # to which the packet will be copied.
            
        # The first parameter is the mcast_grp value.

        # The second is a list of 2-tuples.  The first element of each
        # 2-tuples is the egress port to which the copy should be
        # sent, and the second is the "replication id", also called
        # "egress_rid" in the P4_16 v1model architecture
        # standard_metadata struct, or "instance" in the P4_16 PSA
        # architecture psa_egress_input_metadata_t struct.  That value
        # can be useful if you want to send multiple copies of the
        # same packet out of the same output port, but want each one
        # to be processed differently during egress processing.  If
        # you want that, put multiple pairs with the same egress port
        # in the replication list, but each with a different value of
        # "replication id".
        mcast_grp_recipients = [{'eg_port': 2, 'egress_rid': 5},
                                {'eg_port': 5, 'egress_rid': 75},
                                {'eg_port': 1, 'egress_rid': 111}]

        try_long_mcast_replication_list = False
        if try_long_mcast_replication_list:
            mcast_grp_recipients = []

            num_copies = 100  # works

            # num_copies 200 seems to hang somewhere.  I see these results
            # in simple_switch log file ss-log.txt:

            # $ grep 'Replicating packet on port ' ss-log.txt  | wc
            #     200    2600   16800
            # $ grep 'Sending packet of length ' ss-log.txt | wc
            #     151    2114   42582

            # Some internal buffer size limit within simple_switch,
            # perhaps?
            #num_copies = 200

            #num_copies = 150
            # num_copies = 150 hangs
            # 150 replicated packets in ss-log.txt
            # 123 sent packets in ss-log.txt

            #num_copies = 125
            # num_copies = 125 try 1 hangs
            # 125 replicated packets in ss-log.txt
            # 101 sent packets in ss-log.txt

            # num_copies = 125 try 2 hangs
            # 125 replicated packets in ss-log.txt
            # 120 sent packets in ss-log.txt

            # num_copies = 125 try 3 hangs
            # 125 replicated packets in ss-log.txt
            # 125 sent packets in ss-log.txt
            # 93 'Expecting output packets on port ' lines in PTF log output
            # Perhaps some packets are getting lost between egres and PTF
            # receiving them on veth port?

            #num_copies = 100
            # num_copies = 100 hangs
            # 100 replicated packets in ss-log.txt
            # 92 sent packets in ss-log.txt

            # Then it worked 3 out of 3 times in a row after that.

            for x in range(1,num_copies+1):
                mcast_grp_recipients.append({'eg_port': 2, 'egress_rid': x})

        logging.info("len(mcast_grp_recipients)=%d"
                     "" % (len(mcast_grp_recipients)))
        mcg = sh.MulticastGroupEntry(mcast_grp)
        for x in mcast_grp_recipients:
            mcg.add(x['eg_port'], x['egress_rid'])
        mcg.insert()

        # Before adding any entries to the table ipv4_mc_route_lookup,
        # the default behavior for sending in an IPv4 packet with a
        # multicast dest address is to drop it.
        pkt = tu.simple_udp_packet(eth_src=in_smac, eth_dst=in_dmac,
                                   ip_dst=ip_dst_addr, ip_ttl=64)
        tu.send_packet(self, ig_port, pkt)
        tu.verify_no_other_packets(self)
        
        # Add a set of table entries that the packet should match, and
        # be forwarded with multicast replication.
        add_ipv4_mc_route_lookup_entry_action_set_mcast_grp(
            ip_dst_addr, 32, mcast_grp)

        # Check that the entry is hit, expected source and dest MAC
        # have been written into output packet, TTL has been
        # decremented, and that no other packets are received.
        tu.send_packet(self, ig_port, pkt)

        # See Section 6.4 of RFC 1112 for how the dest MAC address of
        # a forwarded IPv4 multicast packet should be calculated.
        ip_dst_addr_int = p4rtutil.ipv4_to_int(ip_dst_addr)
        mask_23_lsbs = (1 << 23) - 1
        exp_dmac_int = 0x01_00_5e_00_00_00 + (ip_dst_addr_int & mask_23_lsbs)
        exp_dmac = int_to_mac_string(exp_dmac_int)

        # Check that a packet appeared on all ports where copies
        # should have been sent.
        ports_with_pkts = set()
        timeout_len = 20   # seconds
        for x in mcast_grp_recipients:
            exp_eg_port = x['eg_port']
            exp_smac = port_to_smac[exp_eg_port]
            exp_pkt = tu.simple_udp_packet(eth_src=exp_smac, eth_dst=exp_dmac,
                                           ip_dst=ip_dst_addr, ip_ttl=63)
            logging.info("Expecting output packet on port %s" % (exp_eg_port))
            tu.verify_packet(self, exp_pkt, exp_eg_port, timeout=timeout_len)
            ports_with_pkts.add(exp_eg_port)

        # Verify that no packets appeared on any other ports
        for port in all_ports - ports_with_pkts:
            logging.info("Expecting no packet on port %s" % (port))
            tu.verify_no_packet(self, exp_pkt, port)
