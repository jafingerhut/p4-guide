#!/usr/bin/env python3

# Copyright 2024 Andy Fingerhut, andy.fingerhut@gmail.com
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


import logging
import pprint
import queue
import time

import ptf
import ptf.testutils as tu
from ptf.base_tests import BaseTest
import p4runtime_sh.shell as sh
import p4runtime_sh.utils as shutils
import p4runtime_sh.p4runtime as p4rt
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

pp = pprint.PrettyPrinter(indent=4)


class MirrorPktTest(BaseTest):
    def setUp(self):
        # Setting up PTF dataplane
        self.dataplane = ptf.dataplane_instance
        self.dataplane.flush()

        logging.info("MirrorPktTest.setUp() for %s" % (self))
        grpc_addr = tu.test_param_get("grpcaddr")
        if grpc_addr is None:
            grpc_addr = 'localhost:9559'
        certs_dir = tu.test_param_get("certificates")
        if certs_dir is None:
            certs_dir = '/usr/share/stratum/certs'
        ssl_opts = shu.ssl_opts_for_certs_directory(certs_dir)
        sh.setup(device_id=1,
                 grpc_addr=grpc_addr,
                 election_id=(0, 1),
                 ssl_options=ssl_opts,
                 verbose=False)

    def tearDown(self):
        logging.info("MirrorPktTest.tearDown() for %s" % (self))
        sh.teardown()

#############################################################
# Define a few small helper functions that help construct
# parameters for the table_add() method.
#############################################################

def add_ipv4_host_entry_action_drop(ipv4_addr_str):
    te = sh.TableEntry('ipv4_host')(action='drop')
    te.match['dst_addr'] = '%s' % (ipv4_addr_str)
    te.insert()

def add_ipv4_host_entry_action_drop_and_mirror(ipv4_addr_str,
                                               mirror_session_id_int):
    te = sh.TableEntry('ipv4_host')(action='drop_and_mirror')
    te.match['dst_addr'] = '%s' % (ipv4_addr_str)
    te.action['mirror_session_id'] = '%d' % (mirror_session_id_int)
    te.insert()

def add_ipv4_host_entry_action_send(ipv4_addr_str, port_int):
    te = sh.TableEntry('ipv4_host')(action='send')
    te.match['dst_addr'] = '%s' % (ipv4_addr_str)
    te.action['port'] = '%d' % (port_int)
    te.insert()

def add_ipv4_host_entry_action_send_and_mirror(ipv4_addr_str, port_int,
                                               mirror_session_id_int):
    te = sh.TableEntry('ipv4_host')(action='send_and_mirror')
    te.match['dst_addr'] = '%s' % (ipv4_addr_str)
    te.action['port'] = '%d' % (port_int)
    te.action['mirror_session_id'] = '%d' % (mirror_session_id_int)
    te.insert()


class OneEntryTest(MirrorPktTest):
    def runTest(self):
        in_dmac = 'ee:30:ca:9d:1e:00'
        in_smac = 'ee:cd:00:7e:70:00'
        ig_port = 0
        eg_port = 7

        ip_src_addr = '1.1.1.1'
        ip_dst_addr = '2.2.2.2'
        sport = 59597
        dport = 7503

        # TODO: Does P4 DPDK support run-time configuration of mirror
        # sessions?  If so, how?
        mirror_session_id = 81

        logging.info("Attempting to delete all entries in ipv4_host")
        shu.delete_all_entries('ipv4_host')
        logging.info("Attempting to add entries to ipv4_host")
        add_ipv4_host_entry_action_send(ip_src_addr, ig_port)
        add_ipv4_host_entry_action_send_and_mirror(ip_dst_addr, eg_port,
                                                   mirror_session_id)
        logging.info("Now ipv4_host contains %d entries"
                     "" % (shu.entry_count('ipv4_host')))

        pkt_in = tu.simple_tcp_packet(eth_src=in_smac, eth_dst=in_dmac,
                                      ip_src=ip_src_addr, ip_dst=ip_dst_addr,
                                      tcp_sport=sport, tcp_dport=dport)
        exp_pkt = \
            tu.simple_tcp_packet(eth_src=in_smac, eth_dst=in_dmac,
                                 ip_src=ip_src_addr, ip_dst=ip_dst_addr,
                                 tcp_sport=sport, tcp_dport=dport)

        logging.info("Sending packet #1")
        tu.send_packet(self, ig_port, pkt_in)
        tu.verify_packets(self, exp_pkt, [eg_port])
        logging.info("    Saw expected packet on output port %d" % (eg_port))

        logging.info("Sending packet #2")
        pkt_in2 = tu.simple_tcp_packet(eth_src=in_smac, eth_dst=in_dmac,
                                       ip_src=ip_dst_addr, ip_dst=ip_src_addr,
                                       tcp_sport=sport, tcp_dport=dport)
        tu.send_packet(self, 6, pkt_in2)
