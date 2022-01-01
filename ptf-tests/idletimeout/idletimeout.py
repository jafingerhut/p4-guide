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
import pprint
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

pp = pprint.PrettyPrinter(indent=4)


class IdleTimeoutTest(bt.P4RuntimeTest):
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

    #############################################################
    # Define a few small helper functions that help construct
    # parameters for the table_add() method.
    #############################################################

    def key_mac_da_fwd(self, dmac_string):
        # Pass dmac_string as None if you want to make a None key,
        # which the base_test.table_add() method uses to modify the
        # default entry of a table.
        if dmac_string is None:
            return ('mac_da_fwd', None)
        return ('mac_da_fwd',
                [self.Exact('hdr.ethernet.dstAddr',
                            bt.mac_to_int(dmac_string))])

    def act_set_port(self, port_int):
        return ('set_port', [('port', port_int)])

    def act_my_drop(self):
        return ('my_drop', [])

    def act_NoAction(self):
        return ('NoAction', [])

    def key_redirect_by_ethertype(self, ethertype_int):
        # Pass ethertype_int if you want to make a None key, which the
        # base_test.table_add() method uses to modify the default
        # entry of a table.
        if ethertype_int is None:
            return ('redirect_by_ethertype', None)
        return ('redirect_by_ethertype',
                [self.Exact('hdr.ethernet.etherType', ethertype_int)])


class ServerDetectsBadTableEntryOptionsTest(IdleTimeoutTest):
    def runTest(self):

        # Attempting to add an entry with the 'idle_timeout_ns' field
        # set to a non-0 value, must return an INVALID_ARGUMENT error
        # if the table being added to does not have the
        # support_idletimeout table property.  Reference:
        # https://p4.org/p4-spec/p4runtime/v1.3.0/P4Runtime-Spec.html#sec-idle-timeout
        logger.info("Subtest #1")
        print("Subtest #1")
        got_error = False
        try:
            self.table_add(self.key_redirect_by_ethertype(0x86dd),
                           self.act_set_port(5),
                           options={'idle_timeout_ns': 1000000})
        except bt.P4RuntimeWriteException as e:
#            print("Got exception: %s" % (e))
#            n = len(e.errors)
#            print("len(e.errors)=%s" % (n))
#            print("e.as_list_of_dicts() ----------")
            lst = e.as_list_of_dicts()
#            pp.pprint(lst)
#            print("e.as_list_of_dicts() ----------")
            assert len(lst) == 1
            lst0 = lst[0]
            assert lst0['code_name'] == 'INVALID_ARGUMENT'
            assert lst0['message'] == 'idle_timeout_ns must be set to 0 for tables which do not support idle timeout'
            got_error = True
        assert got_error

        # Attempting to add an entry with the 'time_since_last_hit' field
        # set to a non-0 value, must return an INVALID_ARGUMENT error
        # if the table being added to does not have the
        # support_idletimeout table property.  Reference:
        # https://p4.org/p4-spec/p4runtime/v1.3.0/P4Runtime-Spec.html#sec-idle-timeout
        logger.info("Subtest #2")
        print("Subtest #2")
        got_error = False
        try:
            self.table_add(self.key_redirect_by_ethertype(0x86dd),
                           self.act_set_port(5),
                           options={'elapsed_ns': 1000000})
        except bt.P4RuntimeWriteException as e:
            lst = e.as_list_of_dicts()
            #pp.pprint(lst)
            #print("e.as_list_of_dicts() ----------")
            assert len(lst) == 1
            lst0 = lst[0]
            assert lst0['code_name'] == 'INVALID_ARGUMENT'
            assert lst0['message'] == 'has_time_since_last_hit must not be set in WriteRequest'
            got_error = True
        assert got_error

        # Attempting to modify a table's default entry with the
        # 'idle_timeout_ns' field set to a non-0 value, must return an
        # INVALID_ARGUMENT error, whether the being modified has the
        # support_idletimeout table property or not.  Reference:
        # https://p4.org/p4-spec/p4runtime/v1.3.0/P4Runtime-Spec.html#sec-idle-timeout
        logger.info("Subtest #3")
        print("Subtest #3")
        got_error = False
        try:
            self.table_add(self.key_mac_da_fwd(None),
                           self.act_NoAction(),
                           options={'idle_timeout_ns': 1000000})
        except bt.P4RuntimeWriteException as e:
            lst = e.as_list_of_dicts()
            pp.pprint(lst)
            print("e.as_list_of_dicts() ----------")
            assert len(lst) == 1
            lst0 = lst[0]
            assert lst0['code_name'] == 'INVALID_ARGUMENT'
            #assert lst0['message'] == 'has_time_since_last_hit must not be set in WriteRequest'
            got_error = True
        # The following line is commented out because at least with
        # latest versions of P4 open source dev tools as of
        # 2021-Dec-31, simple_switch_grpc does NOT return an
        # INVALID_ARGUMENT for this WriteRequest, even though the
        # P4Runtime API spec says it should.
        #assert got_error

        # Attempting to modify a table's default entry with the
        # 'time_since_last_hit' field set to a non-0 value, must
        # return an INVALID_ARGUMENT error, whether the being modified
        # has the support_idletimeout table property or not.
        # Reference:
        # https://p4.org/p4-spec/p4runtime/v1.3.0/P4Runtime-Spec.html#sec-idle-timeout
        logger.info("Subtest #4")
        print("Subtest #4")
        got_error = False
        try:
            self.table_add(self.key_mac_da_fwd(None),
                           self.act_my_drop(),
                           options={'elapsed_ns': 1000000})
        except bt.P4RuntimeWriteException as e:
            lst = e.as_list_of_dicts()
            #pp.pprint(lst)
            #print("e.as_list_of_dicts() ----------")
            assert len(lst) == 1
            lst0 = lst[0]
            assert lst0['code_name'] == 'INVALID_ARGUMENT'
            assert lst0['message'] == 'has_time_since_last_hit must not be set in WriteRequest'
            got_error = True
        assert got_error


        # Read back and show the table entries, to see if there are
        # any extra properties related to the idle timeout.
        entries_read, default_entry_read = self.table_dump_data('mac_da_fwd')
        print("entries_read:")
        print(entries_read)

        print("default_entry_read:")
        print(default_entry_read)


# class OneEntryTest(IdleTimeoutTest):
#     @bt.autocleanup
#     def runTest(self):
#         in_dmac = 'ee:30:ca:9d:1e:00'
#         in_smac = 'ee:cd:00:7e:70:00'
#         ig_port = 0
#         eg_port = 1

#         # Add one table entry
#         entries = []
#         entries.append({'dmac_string': in_dmac,
#                         'output_port': eg_port})
        
#         for e in entries:
#             self.table_add(self.key_mac_da_fwd(e['dmac_string']),
#                            self.act_set_port(e['output_port']))

#         # Read back and show the table entries, to see if there are
#         # any extra properties related to the idle timeout.
#         entries_read, default_entry_read = self.table_dump_data('mac_da_fwd')
#         print("entries_read:")
#         print(entries_read)

#         print("default_entry_read:")
#         print(default_entry_read)

# #        for e in entries:
# #            ip_dst_addr = e['pkt_in_dst_addr']
# #            pkt_in = tu.simple_tcp_packet(eth_src=in_smac, eth_dst=in_dmac,
# #                                          ip_dst=ip_dst_addr)
# #            exp_pkt = tu.simple_tcp_packet(eth_src=in_smac,
# #                                           eth_dst=e['out_dmac'],
# #                                           ip_dst=ip_dst_addr)
# #            tu.send_packet(self, ig_port, pkt_in)
# #            tu.verify_packets(self, exp_pkt, [eg_port])
