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

        logging.info("IdleTimeoutTest.setUp()")
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
        self.idlenotes = sh.IdleTimeoutNotification()

    def tearDown(self):
        logging.info("IdleTimeoutTest.tearDown()")
        sh.teardown()

#############################################################
# Define a few small helper functions that help construct
# parameters for the table_add() method.
#############################################################

def get_idle_notes_block_until_timeout_reached(idlenotes, timeout_sec):
    pktlist = []
    logging.info("Sniffing for idlenotes for timeout_sec=%s" % (timeout_sec))
    idlenotes.sniff(lambda p: pktlist.append(p), timeout=timeout_sec)
    logging.info("    returning %d idle notifications" % (len(pktlist)))
    return pktlist

def get_idle_notes(idlenotes, timeout_sec):
    pktlist = []
    logging.info("Checking for idlenotes for timeout_sec=%s" % (timeout_sec))
    start_time = time.time()
    try:
        pktlist.append(idlenotes.notification_queue.get(block=True,
                                                        timeout=timeout_sec))
    except KeyboardInterrupt:
        # User sends an interrupt (e.g. Ctrl-C).
        pass
    except queue.Empty:
        # No item available during timeout.  Exiting
        pass
    logging.info("    returning %d idle notifications after %s wait time"
                 "" % (len(pktlist), time.time() - start_time))
    return pktlist

def add_mac_da_fwd_entry_action_set_port(mac_addr_str, port_int,
                                         idle_timeout_nsec):
    te = sh.TableEntry('mac_da_fwd')(action='set_port')
    te.match['dstAddr'] = mac_addr_str
    te.action['port'] = '%d' % (port_int)
    te.idle_timeout_ns = idle_timeout_nsec
    logging.info("add_mac_da_fwd_entry_action_set_port attempting to send this write request:")
    logging.info(te)
    te.insert()

def modify_mac_da_fwd_default_action_NoAction(idle_timeout_nsec):
    te = sh.TableEntry('mac_da_fwd')(action='NoAction')
    te.is_default = True
    te.idle_timeout_ns = idle_timeout_nsec
    logging.debug("modify_mac_da_fwd_default_action_NoAction attempting to send this write request:")
    logging.debug(te)
    te.modify()

def modify_mac_da_fwd_default_action_my_drop(elapsed_nsec):
    te = sh.TableEntry('mac_da_fwd')(action='my_drop')
    te.is_default = True
    te.time_since_last_hit.elapsed_ns = elapsed_nsec
    logging.debug("modify_mac_da_fwd_default_action_my_drop attempting to send this write request:")
    logging.debug(te)
    te.modify()

def add_redirect_by_ethertype_entry_action_set_port(ethertype_int,
                                                    port_int,
                                                    timeout_nsec,
                                                    elapsed_nsec):
    te = sh.TableEntry('redirect_by_ethertype')(action='set_port')
    te.match['etherType'] = '%d' % (ethertype_int)
    te.action['port'] = '%d' % (port_int)
    if timeout_nsec is not None:
        te.idle_timeout_ns = timeout_nsec
    if elapsed_nsec is not None:
        te.time_since_last_hit.elapsed_ns = elapsed_nsec
    te.insert()


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
            add_redirect_by_ethertype_entry_action_set_port(
                0x86dd, 5, 1000000, None)
        except p4rt.P4RuntimeWriteException as e:
            #print("Got exception: %s" % (e))
            #n = len(e.errors)
            #print("len(e.errors)=%s" % (n))
            #print("e.as_list_of_dicts() ----------")
            lst = shu.as_list_of_dicts(e)
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
            add_redirect_by_ethertype_entry_action_set_port(
                0x86dd, 5, None, 1000000)
        except shutils.UserError as e:
            # p4runtime-shell detects an attempt to create a
            # WriteRequest for a TableEntry with elapsed_ns field set
            # BEFORE ever sending the message to the server, if that
            # table does not have the table property enabling idle
            # timeout (support_timeout=true in v1model architecture).
            # Check for that exception instead of checking for an
            # error response from the P4Runtime server, because the
            # server never even saw the WriteRequest.
            assert e.info == 'Table has no idle timeouts'
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
            modify_mac_da_fwd_default_action_NoAction(1000000)
        except p4rt.P4RuntimeWriteException as e:
            lst = shu.as_list_of_dicts(e)
            pp.pprint(lst)
            print("e.as_list_of_dicts() ----------")
            assert len(lst) == 1
            lst0 = lst[0]
            assert lst0['code_name'] == 'INVALID_ARGUMENT'
            #assert lst0['message'] == 'has_time_since_last_hit must not be set in WriteRequest'
            got_error = True
        # TODO: With latest versions of P4 open source dev tools as of
        # 2023-Jan-08, simple_switch_grpc does NOT return an
        # INVALID_ARGUMENT for this WriteRequest, even though the
        # P4Runtime API spec says it should.
        if got_error:
            logging.info("Subtest #3 is passing.  You can uncomment the `assert got_error` line for it in the PTF test now.")
        else:
            logging.info("Subtest #3 attempt to modify the default action for table mac_da_fwd should be failing, but is succeeding.  TODO: Create an issue for the p4lang/PI repository for this.")
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
            modify_mac_da_fwd_default_action_my_drop(1000000)
        except p4rt.P4RuntimeWriteException as e:
            lst = shu.as_list_of_dicts(e)
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
        add_mac_da_fwd_entry_action_set_port(in_dmac, eg_port,
                                             5 * NSEC_PER_SEC)

        # Read back and show the table entries, to see if there are
        # any extra properties related to the idle timeout.
        entries_read, default_entry_read = shu.read_all_table_entries('mac_da_fwd')
        logging.info("entries_read:")
        logging.info(entries_read)

        logging.info("default_entry_read:")
        logging.info(default_entry_read)

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
            msginfos = get_idle_notes(self.idlenotes, 0.1)
            if len(msginfos) != 0:
                break
            now = time.time()
            logging.info("time %.2f next_send_time = %.2f"
                         "" % (now - start, next_send_time - start))
            if now < next_send_time:
                logging.info("      sleeping %.2f sec" % (next_send_time - now))
                time.sleep(next_send_time - now)
            tu.send_packet(self, ig_port, pkt_in)
            last_packet_sent = time.time()
            tu.verify_packets(self, exp_pkt, [eg_port])
            num_packets += 1
            logging.info("time %.2f Sent packet #%d and verified expected output packet"
                         "" % (time.time() - start, num_packets))
            if num_packets >= 5:
                break
            next_send_time = next_send_time + 2.0

        logging.info("time %.2f Sent packets: %d" % (time.time() - start,
                                                     num_packets))
        logging.info("First packet sent time: %.2f" % (start))
        logging.info("Last  packet sent time: %.2f abs, %.2f rel"
                     "" % (last_packet_sent, last_packet_sent - start))
        if len(msginfos) == 0:
            logging.info("No notification message received")
        else:
            logging.info("Notification message received while sending packets periodically")
            logging.info(pp.pformat(msginfos))
        entries_read, default_entry_read = shu.read_all_table_entries('mac_da_fwd')
        logging.info("entries_read:")
        logging.info(entries_read)

        n_checks = 0
        while True:
            n_checks += 1
            msginfos = get_idle_notes(self.idlenotes, 1.0)
            now = time.time()
            if len(msginfos) != 0:
                break
            logging.info("time %.2f (%.2f after last pkt) %d checks for notifications - none rcvd yet"
                  "" % (now - start, now - last_packet_sent, n_checks))
            if n_checks == 10:
                break

        assert len(msginfos) != 0
        logging.info("time %.2f (%.2f after last pkt) %d checks for notifications - one received"
                     "" % (now - start, now - last_packet_sent, n_checks))
        logging.info(pp.pformat(msginfos))

        stop_time = time.time() + 10
        while True:
            wait_time = stop_time - time.time()
            if wait_time <= 0:
                wait_time = 0.001
            msginfos = get_idle_notes(self.idlenotes, wait_time)
            now = time.time()
            if len(msginfos) == 0:
                break
            logging.info("time %.2f (%.2f after last pt) received another notification"
                  "" % (now - start, now - last_packet_sent))
            logging.info(pp.pformat(msginfos))

        logging.info("%.2f Reading table entries..." % (time.time() - start))
        entries_read, default_entry_read = shu.read_all_table_entries('mac_da_fwd')
        logging.info("entries_read:")
        logging.info(entries_read)
