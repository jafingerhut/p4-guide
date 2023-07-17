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


class DuplicateKeysTest(BaseTest):
    def setUp(self):
        # Setting up PTF dataplane
        self.dataplane = ptf.dataplane_instance
        self.dataplane.flush()

        logging.info("DuplicateKeysTest.setUp()")
        grpc_addr = tu.test_param_get("grpcaddr")
        if grpc_addr is None:
            grpc_addr = 'localhost:9559'
        p4info_txt_fname = tu.test_param_get("p4info")
        p4prog_binary_fname = tu.test_param_get("config")
        sh.setup(device_id=0,
                 grpc_addr=grpc_addr,
                 election_id=(0, 1), # (high_32bits, lo_32bits)
                 config=sh.FwdPipeConfig(p4info_txt_fname, p4prog_binary_fname))
        p4rtutil.dump_table("t1")

    def tearDown(self):
        logging.info("DuplicateKeysTest.tearDown()")
        sh.teardown()

#############################################################
# Define a few small helper functions that help construct
# parameters for the table_add() method.
#############################################################

def add_t1_entry_action_set_dmac(ipv4addr_val_int, ipv4addr_mask_int,
                                 dmac_str, priority_int):
    te = sh.TableEntry('t1')(action='set_dmac')
    # Note: p4runtime-shell raises an exception if you attempt to
    # explicitly assign to a ternary field like te.match['dstAddr'] a
    # mask of 0.  Just skip assigning to te.match['dstAddr']
    # completely, and then inserting the entry will give a wildcard
    # match for that field, as defined in the P4Runtime API spec.
    if ipv4addr_mask_int != 0:
        te.match['dstAddr'] = '%d&&&%d' % (ipv4addr_val_int, ipv4addr_mask_int)
    te.action['dmac'] = dmac_str
    te.priority = priority_int
    te.insert()

def modify_t1_default_action_set_dmac(dmac_str):
    te = sh.TableEntry('t1')(action='set_dmac')
    # To cause p4runtime-shell to modify a table's default action:
    # + set is_default property of the entry to True
    # + Do NOT assign values to any match ields
    # + Use modify() method, not insert() method
    te.action['dmac'] = dmac_str
    te.is_default = True
    te.modify()


class IPv4FwdTest(DuplicateKeysTest):
    def runTest(self):
        in_dmac = 'ee:30:ca:9d:1e:00'
        in_smac = 'ee:cd:00:7e:70:00'
        ig_port = 0
        eg_port = 1

        entries = []
        entries.append({'ipv4addr_val': 192,
                        'ipv4addr_mask': 0xff,
                        'priority': 100,
                        'pkt_in_dst_addr': '192.172.1.1',
                        'out_dmac': '00:00:00:00:00:01'})
        entries.append({'ipv4addr_val': 0,
                        'ipv4addr_mask': 0,
                        'priority': 90,
                        'pkt_in_dst_addr': '193.172.255.255',
                        'out_dmac': '00:00:00:00:00:02'})
        entries.append({'ipv4addr_val': 192,
                        'ipv4addr_mask': 0xff,
                        'priority': 80,
                        'pkt_in_dst_addr': '192.255.0.0',
                        'out_dmac': '00:00:00:00:00:03'})
        entries.append({'ipv4addr_val': 192,
                        'ipv4addr_mask': 0xff,
                        'priority': 70,
                        'pkt_in_dst_addr': '192.172.50.0',
                        'out_dmac': '00:00:00:00:00:04'})
        entries.append({ # priority None causes t1's default action to be modified below
                        'priority': None,
                        'pkt_in_dst_addr': '10.10.1.1',
                        'out_dmac': '00:00:00:00:00:05'})
        
        # Add a set of table entries
        for e in entries:
            if e['priority'] is None:
                logging.info("=== default entry before =========================")
                de = p4rtutil.read_table_default_entry('t1')
                logging.info("%s" % (de))
                logging.info("==================================================")
                logging.info("Attempting to modify t1's default action")
                modify_t1_default_action_set_dmac(e['out_dmac'])
                # Try reading the default entry
                logging.info("=== default entry after ==========================")
                de = p4rtutil.read_table_default_entry('t1')
                logging.info("%s" % (de))
                logging.info("==================================================")
            else:
                logging.info("Attempting to add entry with priority %s"
                             "" % (e['priority']))
                add_t1_entry_action_set_dmac(e['ipv4addr_val'], e['ipv4addr_mask'],
                                             e['out_dmac'],
                                             e['priority'])
                # Try reading all non-default entries
                logging.info("==================================================")
                te = sh.TableEntry('t1')
                for x in te.read():
                    logging.info("%s" % (x))
                logging.info("==================================================")

        ttl_in = 200
        for e in entries:
            if e['priority'] is None:
                logging.info("Sending packet that should miss and execute t1's default action")
            else:
                logging.info("Sending packet that should match entry with priority %s"
                             "" % (e['priority']))
            ip_dst_addr = e['pkt_in_dst_addr']
            pkt_in = tu.simple_tcp_packet(eth_src=in_smac, eth_dst=in_dmac,
                                          ip_dst=ip_dst_addr, ip_ttl=ttl_in)
            exp_pkt = tu.simple_tcp_packet(eth_src=in_smac,
                                           eth_dst=e['out_dmac'],
                                           ip_dst=ip_dst_addr, ip_ttl=ttl_in)
            tu.send_packet(self, ig_port, pkt_in)
            tu.verify_packets(self, exp_pkt, [eg_port])
            # Vary TTL in for each packet tested, just to make them
            # easy to distinguish from each other.
            ttl_in = ttl_in - 2
