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

        logging.info("IdleTimeoutTest.setUp()")
        grpc_addr = tu.test_param_get("grpcaddr")
        if grpc_addr is None:
            grpc_addr = 'localhost:9559'
        certs_dir = '/usr/share/stratum/certs'
        root_certificate = certs_dir + '/ca.crt'
        private_key = certs_dir + '/client.key'
        certificate_chain = certs_dir + '/client.crt'
        ssl_opts = p4rt.SSLOptions(False, root_certificate, certificate_chain,
                                   private_key)
        sh.setup(device_id=1,
                 grpc_addr=grpc_addr,
                 election_id=(0, 1),
                 ssl_options=ssl_opts)

    def tearDown(self):
        logging.info("IdleTimeoutTest.tearDown()")
        sh.teardown()

#############################################################
# Define a few small helper functions that help construct
# parameters for the table_add() method.
#############################################################

def entry_count(table_name):
    te = sh.TableEntry(table_name)
    n = 0
    for x in te.read():
        n = n + 1
    return n

def init_key_from_read_tableentry(read_te):
    new_te = sh.TableEntry(read_te.name)
    # This is only written to work for tables where all key fields are
    # match_kind exact.
    for f in read_te.match._fields:
        new_te.match[f] = '%d' % (int.from_bytes(read_te.match[f].exact.value, 'big'))
    return new_te

def delete_all_entries(tname):
    te = sh.TableEntry(tname)
    for e in te.read():
        d = init_key_from_read_tableentry(e)
        d.delete()

def add_ipv4_host_entry_action_send(ipv4_addr_str, port_int):
    te = sh.TableEntry('ipv4_host')(action='send')
    te.match['dst_addr'] = '%s' % (ipv4_addr_str)
    te.action['port'] = '%d' % (port_int)
    te.insert()

def add_set_ct_options_entry_action_tcp_syn_packet(flags_value_int,
                                                   flags_mask_int,
                                                   priority_int):
    te = sh.TableEntry('set_ct_options')(action='tcp_syn_packet')
    te.match['flags'] = '%d&&&%d' % (flags_value_int, flags_mask_int)
    te.priority = priority_int
    te.insert()

def add_set_ct_options_entry_action_tcp_fin_or_rst_packet(flags_value_int,
                                                          flags_mask_int,
                                                          priority_int):
    te = sh.TableEntry('set_ct_options')(action='tcp_fin_or_rst_packet')
    te.match['flags'] = '%d&&&%d' % (flags_value_int, flags_mask_int)
    te.priority = priority_int
    te.insert()

def init_table_ipv4_host(ig_port, ip_src_addr, eg_port, ip_dst_addr):
    logging.info("Attempting to delete all entries in ipv4_host")
    delete_all_entries('ipv4_host')
    logging.info("Attempting to add entries to ipv4_host")
    add_ipv4_host_entry_action_send(ip_src_addr, ig_port)
    add_ipv4_host_entry_action_send(ip_dst_addr, eg_port)
    logging.info("Now ipv4_host contains %d entries"
                 "" % (entry_count('ipv4_host')))

TCP_URG_MASK = 0x20;
TCP_ACK_MASK = 0x10;
TCP_PSH_MASK = 0x08;
TCP_RST_MASK = 0x04;
TCP_SYN_MASK = 0x02;
TCP_FIN_MASK = 0x01;

def init_table_set_ct_options():
    tname = 'set_ct_options'
    num_entries = entry_count(tname)
    logging.info("Now %s contains %d entries" % (tname, num_entries))
    if num_entries == 0:
        logging.info("Attempting to add entries to set_ct_options")
        add_set_ct_options_entry_action_tcp_syn_packet(
            TCP_SYN_MASK, TCP_SYN_MASK, 30)
        add_set_ct_options_entry_action_tcp_fin_or_rst_packet(
            TCP_FIN_MASK, TCP_FIN_MASK, 20)
        add_set_ct_options_entry_action_tcp_fin_or_rst_packet(
            TCP_RST_MASK, TCP_RST_MASK, 10)
    num_entries = entry_count(tname)
    logging.info("Now %s contains %d entries" % (tname, num_entries))
    if num_entries != 3:
        logging.error("%s should have 3 entries, but found %d instead."
                      "" % (tname, num_entries))
        assert num_entries == 3


class TcpSynPktsOnlyTest(IdleTimeoutTest):
    def runTest(self):
        in_dmac = 'ee:30:ca:9d:1e:00'
        in_smac = 'ee:cd:00:7e:70:00'
        ig_port = 0
        eg_port = 1

        ip_src_addr = '1.1.1.1'
        ip_dst_addr = '2.2.2.2'
        sport = 59597
        dport = 7503

        init_table_ipv4_host(ig_port, ip_src_addr, eg_port, ip_dst_addr)
        init_table_set_ct_options()

        pkt_in = {}
        exp_pkt_for_miss = {}
        exp_pkt_for_hit = {}
        for flags in ['S', 'A', 'F']:
            pkt_in[flags] = \
                tu.simple_tcp_packet(eth_src=in_smac, eth_dst=in_dmac,
                                     ip_src=ip_src_addr, ip_dst=ip_dst_addr,
                                     tcp_sport=sport, tcp_dport=dport,
                                     tcp_flags=flags)
            # add_on_miss1.p4 replaces least significant 8 bits of source
            # MAC address with 0xf1 on a hit of table ct_tcp_table, or
            # 0xa5 on a miss.
            out_smac_for_miss = in_smac[:-2] + 'a5'
            out_smac_for_hit = in_smac[:-2] + 'f1'
            exp_pkt_for_miss[flags] = \
                tu.simple_tcp_packet(eth_src=out_smac_for_miss, eth_dst=in_dmac,
                                     ip_src=ip_src_addr, ip_dst=ip_dst_addr,
                                     tcp_sport=sport, tcp_dport=dport,
                                     tcp_flags=flags)
            exp_pkt_for_hit[flags] = \
                tu.simple_tcp_packet(eth_src=out_smac_for_hit, eth_dst=in_dmac,
                                     ip_src=ip_src_addr, ip_dst=ip_dst_addr,
                                     tcp_sport=sport, tcp_dport=dport,
                                     tcp_flags=flags)

        # Send in a first packet that should experience a miss on
        # table ct_tcp_table, cause a new entry to be added by the
        # data plane with a 30-second expiration time (expire time
        # profile id 1), and be forwarded with a change to its source
        # MAC address that is used by add_on_miss1.p4 to indicate that
        # a miss occurred.
        logging.info("Sending packet #1 - SYN")
        tu.send_packet(self, ig_port, pkt_in['S'])
        first_pkt_time = time.time()
        tu.verify_packets(self, exp_pkt_for_miss['S'], [eg_port])
        logging.info("    packet experienced a miss in ct_tcp_table as expected")

        # Unlike add_on_miss0.p4, each time we send a SYN packet that
        # hits in table ct_tcp_table, it refreshes the timeout to be
        # 30 sec after the last such SYN packet to be sent.  Thus each
        # of the first 2 packets below should hit, and only the last
        # one should miss, because the last one is the only one that
        # arrives more than 30 sec after the previous packet.
        schedule = [
            {'delta_time': 25, 'flags': 'S', 'exp_hit': True},
            {'delta_time': 50, 'flags': 'S', 'exp_hit': True},
            {'delta_time': 85, 'flags': 'S', 'exp_hit': False}
            ]
        
        for sched_item in schedule:
            delta_time = sched_item['delta_time']
            flags = sched_item['flags']
            exp_hit = sched_item['exp_hit']
            if exp_hit:
                exp_word = 'hit'
                exp_pkt = exp_pkt_for_hit[flags]
            else:
                exp_word = 'miss'
                exp_pkt = exp_pkt_for_miss[flags]

            next_send_time = first_pkt_time + delta_time
            now = time.time()
            if now < next_send_time:
                logging.info("sleeping %.2f sec" % (next_send_time - now))
                time.sleep(next_send_time - now)
            logging.info("Sending packet %s sec after packet #1" % (delta_time))
            tu.send_packet(self, ig_port, pkt_in[flags])
            tu.verify_packets(self, exp_pkt, [eg_port])
            logging.info("    packet experienced a %s in ct_tcp_table"
                         " as expected" % (exp_word))


class TcpSynThenAckThenFinPktsTest(IdleTimeoutTest):
    def runTest(self):
        in_dmac = 'ee:30:ca:9d:1e:00'
        in_smac = 'ee:cd:00:7e:70:00'
        ig_port = 0
        eg_port = 1

        ip_src_addr = '1.1.1.1'
        ip_dst_addr = '2.2.2.2'
        # Use different source/dest TCP ports than the test above, so
        # that any entries left behind by one test should not affect
        # the other test, regardless of which order they may be run
        # in.
        sport = 58000
        dport = 7500

        init_table_ipv4_host(ig_port, ip_src_addr, eg_port, ip_dst_addr)
        init_table_set_ct_options()

        pkt_in = {}
        exp_pkt_for_miss = {}
        exp_pkt_for_hit = {}
        for flags in ['S', 'A', 'F']:
            pkt_in[flags] = \
                tu.simple_tcp_packet(eth_src=in_smac, eth_dst=in_dmac,
                                     ip_src=ip_src_addr, ip_dst=ip_dst_addr,
                                     tcp_sport=sport, tcp_dport=dport,
                                     tcp_flags=flags)
            # add_on_miss1.p4 replaces least significant 8 bits of source
            # MAC address with 0xf1 on a hit of table ct_tcp_table, or
            # 0xa5 on a miss.
            out_smac_for_miss = in_smac[:-2] + 'a5'
            out_smac_for_hit = in_smac[:-2] + 'f1'
            exp_pkt_for_miss[flags] = \
                tu.simple_tcp_packet(eth_src=out_smac_for_miss, eth_dst=in_dmac,
                                     ip_src=ip_src_addr, ip_dst=ip_dst_addr,
                                     tcp_sport=sport, tcp_dport=dport,
                                     tcp_flags=flags)
            exp_pkt_for_hit[flags] = \
                tu.simple_tcp_packet(eth_src=out_smac_for_hit, eth_dst=in_dmac,
                                     ip_src=ip_src_addr, ip_dst=ip_dst_addr,
                                     tcp_sport=sport, tcp_dport=dport,
                                     tcp_flags=flags)

        # Send in a first packet that should experience a miss on
        # table ct_tcp_table, cause a new entry to be added by the
        # data plane with a 30-second expiration time (expire time
        # profile id 1), and be forwarded with a change to its source
        # MAC address that is used by add_on_miss1.p4 to indicate that
        # a miss occurred.
        logging.info("Sending packet #1 - SYN")
        tu.send_packet(self, ig_port, pkt_in['S'])
        first_pkt_time = time.time()
        tu.verify_packets(self, exp_pkt_for_miss['S'], [eg_port])
        logging.info("    packet experienced a miss in ct_tcp_table as expected")

        # ACK packet should change the timeout of the entry to profile
        # id 2, which has timeout interval 60 sec.  Then FIN packet
        # should change the entry to profile id 0, which has a timeout
        # interval of 10 sec.  Every FIN packet after that should
        # reset the timeout and give an additional 10 sec for the
        # entry to remain in the table.
        schedule = [
            {'delta_time': 1, 'flags': 'A', 'exp_hit': True, 'drop': False},
            {'delta_time': 2, 'flags': 'A', 'exp_hit': True, 'drop': False},
            {'delta_time': 5, 'flags': 'F', 'exp_hit': True, 'drop': False},
            {'delta_time': 10, 'flags': 'F', 'exp_hit': True, 'drop': False},
            {'delta_time': 15, 'flags': 'F', 'exp_hit': True, 'drop': False},
            {'delta_time': 20, 'flags': 'F', 'exp_hit': True, 'drop': False},
            # 15 sec after prev packet, entry should be deleted, and
            # packets without a SYN flag should miss and be dropped,
            # and NOT cause a new entry to be added.
            {'delta_time': 35, 'flags': 'F', 'exp_hit': False, 'drop': True},
            {'delta_time': 40, 'flags': 'A', 'exp_hit': False, 'drop': True},
            # But another SYN packet should cause a new entry to be created.
            {'delta_time': 45, 'flags': 'S', 'exp_hit': False, 'drop': False},
            {'delta_time': 50, 'flags': 'A', 'exp_hit': True, 'drop': False},
            ]
        
        for sched_item in schedule:
            delta_time = sched_item['delta_time']
            flags = sched_item['flags']
            exp_hit = sched_item['exp_hit']
            drop = sched_item['drop']
            if not drop:
                if exp_hit:
                    exp_word = 'hit'
                    exp_pkt = exp_pkt_for_hit[flags]
                else:
                    exp_word = 'miss'
                    exp_pkt = exp_pkt_for_miss[flags]

            next_send_time = first_pkt_time + delta_time
            now = time.time()
            if now < next_send_time:
                logging.info("sleeping %.2f sec" % (next_send_time - now))
                time.sleep(next_send_time - now)
            logging.info("Sending flags %s packet %s sec after packet #1"
                         "" % (flags, delta_time))
            tu.send_packet(self, ig_port, pkt_in[flags])
            if drop:
                tu.verify_no_other_packets(self)
                logging.info("    no packet out seen, as expected")
            else:
                tu.verify_packets(self, exp_pkt, [eg_port])
                logging.info("    packet experienced a %s in ct_tcp_table"
                             " as expected" % (exp_word))
