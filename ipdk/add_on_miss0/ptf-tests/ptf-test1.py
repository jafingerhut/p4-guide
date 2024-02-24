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


class IdleTimeoutTest(BaseTest):
    def setUp(self):
        # Setting up PTF dataplane
        self.dataplane = ptf.dataplane_instance
        self.dataplane.flush()

        logging.info("IdleTimeoutTest.setUp() for %s" % (self))
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
        logging.info("IdleTimeoutTest.tearDown() for %s" % (self))
        sh.teardown()

#############################################################
# Define a few small helper functions that help construct
# parameters for the table_add() method.
#############################################################

def add_ipv4_host_entry_action_send(ipv4_addr_str, port_int):
    te = sh.TableEntry('ipv4_host')(action='send')
    te.match['dst_addr'] = '%s' % (ipv4_addr_str)
    te.action['port'] = '%d' % (port_int)
    te.insert()


class OneEntryTest(IdleTimeoutTest):
    def runTest(self):
        in_dmac = 'ee:30:ca:9d:1e:00'
        in_smac = 'ee:cd:00:7e:70:00'
        ig_port = 0
        eg_port = 1

        ip_src_addr = '1.1.1.1'
        ip_dst_addr = '2.2.2.2'
        sport = 59597
        dport = 7503

        logging.info("Attempting to delete all entries in ipv4_host")
        shu.delete_all_entries('ipv4_host')
        logging.info("Attempting to add entries to ipv4_host")
        add_ipv4_host_entry_action_send(ip_src_addr, ig_port)
        add_ipv4_host_entry_action_send(ip_dst_addr, eg_port)
        logging.info("Now ipv4_host contains %d entries"
                     "" % (shu.entry_count('ipv4_host')))

        pkt_in = tu.simple_tcp_packet(eth_src=in_smac, eth_dst=in_dmac,
                                      ip_src=ip_src_addr, ip_dst=ip_dst_addr,
                                      tcp_sport=sport, tcp_dport=dport)
        # add_on_miss0.p4 replaces least significant 8 bits of source
        # MAC address with 0xf1 on a hit of table ct_tcp_table, or
        # 0xa5 on a miss.
        out_smac_for_miss = in_smac[:-2] + 'a5'
        out_smac_for_hit = in_smac[:-2] + 'f1'
        exp_pkt_for_miss = \
            tu.simple_tcp_packet(eth_src=out_smac_for_miss, eth_dst=in_dmac,
                                 ip_src=ip_src_addr, ip_dst=ip_dst_addr,
                                 tcp_sport=sport, tcp_dport=dport)
        exp_pkt_for_hit = \
            tu.simple_tcp_packet(eth_src=out_smac_for_hit, eth_dst=in_dmac,
                                 ip_src=ip_src_addr, ip_dst=ip_dst_addr,
                                 tcp_sport=sport, tcp_dport=dport)

        # Send in a first packet that should experience a miss on
        # table ct_tcp_table, cause a new entry to be added by the
        # data plane with a 30-second expiration time, and be
        # forwarded with a change to its source MAC address that the
        # add_on_miss0.p4 program uses to indicate that a miss
        # occurred.
        logging.info("Sending packet #1")
        tu.send_packet(self, ig_port, pkt_in)
        first_pkt_time = time.time()
        tu.verify_packets(self, exp_pkt_for_miss, [eg_port])
        logging.info("    packet experienced a miss in ct_tcp_table as expected")

        # 5 seconds after the first packet send, send in another
        # identical packet that should hit.

        # 25 seconds after the first packet send, send in another
        # identical packet that should hit.

        # 35 seconds after the first packet send, send in another
        # identical packet that should get a miss, and trigger adding
        # a new table entry, as the first packet did.

        # 40 seconds after the first packet send, send in another
        # identical packet that should hit.
        schedule = [
            {'delta_time':  5, 'exp_hit': True},
            {'delta_time': 25, 'exp_hit': True},
            {'delta_time': 35, 'exp_hit': False},
            {'delta_time': 40, 'exp_hit': True}
            ]
        
        for sched_item in schedule:
            delta_time = sched_item['delta_time']
            exp_hit = sched_item['exp_hit']
            if exp_hit:
                exp_word = 'hit'
                exp_pkt = exp_pkt_for_hit
            else:
                exp_word = 'miss'
                exp_pkt = exp_pkt_for_miss

            next_send_time = first_pkt_time + delta_time
            now = time.time()
            if now < next_send_time:
                logging.info("sleeping %.2f sec" % (next_send_time - now))
                time.sleep(next_send_time - now)
            logging.info("Sending packet %s sec after packet #1" % (delta_time))
            tu.send_packet(self, ig_port, pkt_in)
            tu.verify_packets(self, exp_pkt, [eg_port])
            logging.info("    packet experienced a %s in ct_tcp_table"
                         " as expected" % (exp_word))
