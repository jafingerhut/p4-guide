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
import time
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

        ############################################################
        # Attempting to add an entry with the 'idle_timeout_ns' field
        # set to a non-0 value, must return an INVALID_ARGUMENT error
        # if the table being added to does not have the
        # support_idletimeout table property.  Reference:
        # https://p4.org/p4-spec/p4runtime/v1.3.0/P4Runtime-Spec.html#sec-idle-timeout
        ############################################################
        logger.info("Subtest #1")
        print("Subtest #1")
        got_error = False
        try:
            self.table_add(self.key_redirect_by_ethertype(0x86dd),
                           self.act_set_port(5),
                           options={'idle_timeout_ns': 1000000})
        except bt.P4RuntimeWriteException as e:
            #print("Got exception: %s" % (e))
            #n = len(e.errors)
            #print("len(e.errors)=%s" % (n))
            #print("e.as_list_of_dicts() ----------")
            lst = e.as_list_of_dicts()
            #pp.pprint(lst)
            #print("e.as_list_of_dicts() ----------")
            assert len(lst) == 1
            lst0 = lst[0]
            assert lst0['code_name'] == 'INVALID_ARGUMENT'
            assert lst0['message'] == 'idle_timeout_ns must be set to 0 for tables which do not support idle timeout'
            got_error = True
        assert got_error

        ############################################################
        # Attempting to add an entry with the 'time_since_last_hit' field
        # set to a non-0 value, must return an INVALID_ARGUMENT error
        # if the table being added to does not have the
        # support_idletimeout table property.  Reference:
        # https://p4.org/p4-spec/p4runtime/v1.3.0/P4Runtime-Spec.html#sec-idle-timeout
        ############################################################
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

        ############################################################
        # Attempting to modify a table's default entry with the
        # 'idle_timeout_ns' field set to a non-0 value, must return an
        # INVALID_ARGUMENT error, whether the being modified has the
        # support_idletimeout table property or not.  Reference:
        # https://p4.org/p4-spec/p4runtime/v1.3.0/P4Runtime-Spec.html#sec-idle-timeout
        ############################################################
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
        # TODO: The following line is commented out because at least
        # with latest versions of P4 open source dev tools as of
        # 2021-Dec-31, simple_switch_grpc does NOT return an
        # INVALID_ARGUMENT for this WriteRequest, even though the
        # P4Runtime API spec says it should.
        if got_error:
            print("Subtest #3 is passing.  You can uncomment the `assert got_error` line for it in the PTF test now.")
        else:
            print("Subtest #3 attempt to modify the default action for table mac_da_fwd should be failing, but is succeeding.  TODO: Create an issue for the p4lang/PI repository for this.")
        #assert got_error

        ############################################################
        # Attempting to modify a table's default entry with the
        # 'time_since_last_hit' field set to a non-0 value, must
        # return an INVALID_ARGUMENT error, whether the being modified
        # has the support_idletimeout table property or not.
        # Reference:
        # https://p4.org/p4-spec/p4runtime/v1.3.0/P4Runtime-Spec.html#sec-idle-timeout
        ############################################################
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

        # TODO: There are likely other operations that should return
        # error status as well related to idle timeout.  Feel free to
        # add more here.


class OneEntryTest(IdleTimeoutTest):
    @bt.autocleanup
    def runTest(self):
        in_dmac = 'ee:30:ca:9d:1e:00'
        in_smac = 'ee:cd:00:7e:70:00'
        ig_port = 0
        eg_port = 1

        # Add one table entry with a 5-second idle timeout.

        # Then send approximately one packet every 2 seconds for 10
        # seconds, all of which match that one table entry.  There
        # should be no idle timeout notifications from the switch to
        # the controller during this entire time.

        # Then stop sending packets completely and wait for 10
        # seconds.  There should be an idle timeout notification
        # message sent from the switch to the controller approximately
        # 5 seconds after the last packet was sent that matched the
        # entry.

        # From running this test with simple_switch_grpc built from
        # latest source code as of 2021-Dec-31, the switch sends the
        # first notification after about 5 to 6 seconds, and then if
        # it continues to be the case that no packets match the entry,
        # it generates another notification once every 2 seconds after
        # that.  I do not know if that 2 seconds is configurable.

        # TODO: Does the P4Runtime API specification say anything
        # about this situation?

        NSEC_PER_SEC = 1000 * 1000 * 1000
        self.table_add(self.key_mac_da_fwd(in_dmac),
                       self.act_set_port(eg_port),
                       options={'idle_timeout_ns': 5 * NSEC_PER_SEC})

        # Read back and show the table entries, to see if there are
        # any extra properties related to the idle timeout.
        entries_read, default_entry_read = self.table_dump_data('mac_da_fwd')
        print("entries_read:")
        print(entries_read)

        print("default_entry_read:")
        print(default_entry_read)

        ip_dst_addr = '192.168.0.1'
        pkt_in = tu.simple_tcp_packet(eth_src=in_smac, eth_dst=in_dmac,
                                      ip_dst=ip_dst_addr)
        exp_pkt = tu.simple_tcp_packet(eth_src=in_smac, eth_dst=in_dmac,
                                       ip_dst=ip_dst_addr)
        start = time.time()
        next_send_time = start
        num_packets = 0
        msginfo = None
        while True:
            msginfo = self.get_stream_packet2(None, 0.1)
            if msginfo is not None:
                break
            now = time.time()
            print("time %.2f next_send_time = %.2f"
                  "" % (now - start, next_send_time - start))
            if now < next_send_time:
                print("      sleeping %.2f sec" % (next_send_time - now))
                time.sleep(next_send_time - now)
            tu.send_packet(self, ig_port, pkt_in)
            last_packet_sent = time.time()
            tu.verify_packets(self, exp_pkt, [eg_port])
            num_packets += 1
            print("time %.2f Sent packet #%d and verified expected output packet"
                  "" % (time.time() - start, num_packets))
            if num_packets >= 5:
                break
            next_send_time = next_send_time + 2.0

        print("time %.2f Sent packets: %d" % (time.time() - start,
                                              num_packets))
        print("First packet sent time: %.2f" % (start))
        print("Last  packet sent time: %.2f abs, %.2f rel"
              "" % (last_packet_sent, last_packet_sent - start))
        if msginfo is None:
            print("No notification message received")
        else:
            print("Notification message received while sending packets periodically")
            pp.pprint(msginfo)
        entries_read, default_entry_read = self.table_dump_data('mac_da_fwd')
        print("entries_read:")
        print(entries_read)

        n_checks = 0
        while True:
            n_checks += 1
            msginfo = self.get_stream_packet2(None, 1.0)
            now = time.time()
            if msginfo is not None:
                break
            print("time %.2f (%.2f after last pkt) %d checks for notifications - none rcvd yet"
                  "" % (now - start, now - last_packet_sent, n_checks))
            if n_checks == 10:
                break

        assert msginfo is not None
        print("time %.2f (%.2f after last pkt) %d checks for notifications - one received"
              "" % (now - start, now - last_packet_sent, n_checks))
        pp.pprint(msginfo)

        stop_time = time.time() + 10
        while True:
            msginfo = self.get_stream_packet2(None, stop_time - time.time())
            now = time.time()
            if msginfo is None:
                break
            print("time %.2f (%.2f after last pt) received another notification"
                  "" % (now - start, now - last_packet_sent))
            pp.pprint(msginfo)

        print("%.2f Reading table entries..." % (time.time() - start))
        entries_read, default_entry_read = self.table_dump_data('mac_da_fwd')
        print("entries_read:")
        print(entries_read)
