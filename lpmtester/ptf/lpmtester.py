#!/usr/bin/env python3

# Copyright 2025 Andy Fingerhut
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
import random
import time

import ptf
import ptf.packet as packet
import ptf.testutils as tu
from ptf.base_tests import BaseTest
import p4runtime_sh.shell as sh
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

# Examples of some kinds of calls that can be made to generate
# logging messages.
#logger.debug("10 logger.debug message")
#logger.info("20 logger.info message")
#logger.warn("30 logger.warn message")
#logger.error("40 logger.error message")
#logging.debug("10 logging.debug message")
#logging.info("20 logging.info message")
#logging.warn("30 logging.warn message")
#logging.error("40 logging.error message")

def int_to_ipv6_addr(n):
    assert 0 <= n
    assert n < (1 << 128)
    hex_str = '%032x' % (n)
    lst = []
    while len(hex_str) > 0:
        lst.append(hex_str[:4])
        hex_str = hex_str[4:]
    return ':'.join(lst)


KEY_WIDTH_BITS = 128
prefix_mask = None
suffix_mask = None
bit_after_prefix = None

IG_PORT = 1
EG_PORT = 1

# I have tried this code with FLUSH_THRESHOLD > 1, but it fails for
# reasons I have not determined yet.  My intent with implementing
# FLUSH_THRESHOLD > 1 was to speed up the test runs significantly.
#
# Later I found that if you run with 8 ports, then verify_packets()
# calls take about 0.8 sec per call, even when it finds the expected
# packet.  If you run with 1 port, then verify_packets() calls take
# about 0.1 sec per call.  That is enough faster that I will postpone
# attempting to make FLUSH_THRESHOLD > 1 work for a while longer.

#FLUSH_THRESHOLD = 16
FLUSH_THRESHOLD = 1
pending_packets_to_send = []
pending_packets_to_expect = []

#MISS_IP_SRC_ADDR = 'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff'
MISS_IP_SRC_ADDR = int_to_ipv6_addr((1 << KEY_WIDTH_BITS) - 1)
#IN_IP_SRC_ADDR = '0::0'
IN_IP_SRC_ADDR = int_to_ipv6_addr((1 << KEY_WIDTH_BITS) - 2)

def init_prefix_masks():
    global prefix_mask
    global suffix_mask
    global bit_after_prefix
    if prefix_mask is not None:
        return
    prefix_mask = [0] * (KEY_WIDTH_BITS + 1)
    suffix_mask = [0] * (KEY_WIDTH_BITS + 1)
    bit_after_prefix = [0] * (KEY_WIDTH_BITS)
    full_width_mask = (1 << KEY_WIDTH_BITS) - 1
    for prefix_len in range(KEY_WIDTH_BITS, -1, -1):
        mask = (1 << (KEY_WIDTH_BITS - prefix_len)) - 1
        suffix_mask[prefix_len] = mask
        prefix_mask[prefix_len] = full_width_mask & (~mask)
        if prefix_len != KEY_WIDTH_BITS:
            bit_after_prefix[prefix_len] = (1 << (KEY_WIDTH_BITS - 1 - prefix_len))
        if False:
            logging.info("prefix_len=%3d prefix_mask=0x%032x suffix_mask=0x%032x"
                         "" % (prefix_len, prefix_mask[prefix_len],
                               suffix_mask[prefix_len]))

prefixes_by_length = {}
unused_small_entry_id_lst = []
unused_small_entry_id_set = set()
min_large_unused_entry_id = 1

def clear_all_allocated_entry_ids():
    global unused_small_entry_id_lst
    global unused_small_entry_id_set
    global min_large_unused_entry_id
    unused_small_entry_id_lst = []
    unused_small_entry_id_set = set()
    min_large_unused_entry_id = 1

def allocate_unused_entry_id():
    global unused_small_entry_id_lst
    global unused_small_entry_id_set
    global min_large_unused_entry_id
    if len(unused_small_entry_id_lst) != 0:
        entry_id = unused_small_entry_id_lst[0]
        unused_small_entry_id_lst = unused_small_entry_id_lst[1:]
        unused_small_entry_id_set.remove(entry_id)
    else:
        entry_id = min_large_unused_entry_id
        min_large_unused_entry_id += 1
    return entry_id

def free_entry_id(entry_id):
    global unused_small_entry_id_lst
    global unused_small_entry_id_set
    global min_large_unused_entry_id
    assert entry_id < min_large_unused_entry_id
    assert entry_id not in unused_small_entry_id_set
    unused_small_entry_id_set.add(entry_id)
    unused_small_entry_id_lst.append(entry_id)

def clear_all_prefixes():
    global prefixes_by_length
    prefixes_by_length = {}
    clear_all_allocated_entry_ids()

def insert_prefix(prefix_int, prefix_len_int, entry_id=None):
    assert 0 <= prefix_len_int
    assert prefix_len_int <= KEY_WIDTH_BITS
    assert prefix_int == prefix_int & prefix_mask[prefix_len_int]
    global prefixes_by_length
    if prefix_len_int not in prefixes_by_length:
        prefixes_by_length[prefix_len_int] = {}
    if prefix_int in prefixes_by_length[prefix_len_int]:
        return {'error': True,
                'error_type': 'prefix_already_inserted'}
#        logging.error("Attempting to insert_prefix that is already installed: prefix_len_int=%d prefix_int=0x%032x"
#                      "" % (prefix_len_int, prefix_int))
#        assert False
    if entry_id is None:
        entry_id = allocate_unused_entry_id()
    prefixes_by_length[prefix_len_int][prefix_int] = entry_id
    return {'error': False, 'entry_id': entry_id}

def delete_prefix(prefix_int, prefix_len_int):
    assert 0 <= prefix_len_int
    assert prefix_len_int <= KEY_WIDTH_BITS
    assert prefix_int == prefix_int & prefix_mask[prefix_len_int]
    global prefixes_by_length
    if prefix_len_int not in prefixes_by_length:
        prefixes_by_length[prefix_len_int] = {}
    if prefix_int not in prefixes_by_length[prefix_len_int]:
        logging.error("Attempting to delete_prefix that is not installed: prefix_len_int=%d prefix_int=0x%032x"
                      "" % (prefix_len_int, prefix_int))
        assert False
    entry_id = prefixes_by_length[prefix_len_int][prefix_int]
    del prefixes_by_length[prefix_len_int][prefix_int]
    free_entry_id(entry_id)
    return entry_id

def lookup_lpm_key(key_int):
    assert 0 <= key_int
    assert key_int < (1 << KEY_WIDTH_BITS)
    entry_id = None
    for prefix_len in range(KEY_WIDTH_BITS, -1, -1):
        if prefix_len not in prefixes_by_length:
            continue
        masked_key = key_int & prefix_mask[prefix_len]
        entry_id = prefixes_by_length[prefix_len].get(masked_key, None)
        if entry_id is not None:
            return entry_id
    return None


class LpmTesterTest(BaseTest):
    def setUp(self):
        init_prefix_masks()
        # Setting up PTF dataplane
        self.dataplane = ptf.dataplane_instance
        self.dataplane.flush()

        logging.debug("LpmTesterTest.setUp()")
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
        #shu.dump_table("ipv4_da_lpm")
        #shu.dump_table("mac_da")
        #shu.dump_table("send_frame")

    def tearDown(self):
        logging.debug("LpmTesterTest.tearDown()")
        sh.teardown()

#############################################################
# Define a few small helper functions that make adding entries to
# particular tables in demo2.p4 slightly shorter to write.
#############################################################

def fail_if_table_not_empty(table_name):
    nentries = shu.entry_count(table_name)
    if nentries == 0:
        logging.info("Table '%s' has 0 entries, as expected"
                     "" % (table_name))
    else:
        logging.error("Expected table '%s' to be empty, but it contains %d entries:"
                      "" % (table_name, nentries))
        shu.entry_count(table_name, print_entries=True)
        assert nentries != 0

# TODO: Verify that some kind of error is returned, or exception is
# raised, if we attempt to insert a prefix that is already inserted,
# or to delete a prefix that is not currently in the table.  Add extra
# error checking if that is not the case.

def insert_lpm_entry(prefix_str, prefix_len_int, entry_id_int):
    te = sh.TableEntry('ipv6_da_lpm')(action='hit_action')
    # Note: p4runtime-shell raises an exception if you attempt to
    # explicitly assign to te.match['dstAddr'] a prefix with length 0.
    # Just skip assigning to te.match['dstAddr'] completely, and then
    # inserting the entry will give a wildcard match for that field,
    # as defined in the P4Runtime API spec.
    if prefix_len_int != 0:
        te.match['dst_addr'] = '%s/%d' % (prefix_str, prefix_len_int)
    te.action['entry_id'] = '%d' % (entry_id_int)
    te.insert()

def delete_lpm_entry(prefix_str, prefix_len_int):
    te = sh.TableEntry('ipv6_da_lpm')(action='set_l2ptr')
    if prefix_len_int != 0:
        te.match['dst_addr'] = '%s/%d' % (prefix_str, prefix_len_int)
    te.delete()

def simple_ipv6_pkt(src_ip, dst_ip,
                    ipv6_fl=0,
                    ipv6_tc=0,
                    ipv6_hlim=64):
    dmac = 'ee:30:ca:9d:1e:00'
    smac = 'ee:cd:00:7e:70:00'
    pkt = packet.Ether(dst=dmac, src=smac)
    pkt /= packet.IPv6(
        src=src_ip, dst=dst_ip, fl=ipv6_fl, tc=ipv6_tc, hlim=ipv6_hlim
    )
    return pkt

def execute_pending_tests(self):
    global pending_packets_to_send
    global pending_packets_to_expect
    start_time = time.time()
    logging.info("execute_pending_tests sending %d packets then expecting %d"
                 "" % (len(pending_packets_to_send),
                       len(pending_packets_to_expect)))
    for pkt in pending_packets_to_send:
        tu.send_packet(self, IG_PORT, pkt)
    for pkt in pending_packets_to_expect:
        tu.verify_packets(self, pkt, [EG_PORT])
    end_time = time.time()
    logging.info("execute_pending_tests completed in %.1f sec"
                 "" % (end_time - start_time))
    pending_packets_to_send = []
    pending_packets_to_expect = []

def verify_lookup_misses(self, ip_dst_addr, postpone=True):
    in_dmac = 'ee:30:ca:9d:1e:00'
    in_smac = 'ee:cd:00:7e:70:00'
    pkt = simple_ipv6_pkt(IN_IP_SRC_ADDR, ip_dst_addr)
    if postpone:
        global pending_packets_to_send
        pending_packets_to_send.append(pkt)
    else:
        tu.send_packet(self, IG_PORT, pkt)
    # Check that the lookup misses, by confirming that its IPv6 source
    # address is replaced with the expected value encoding a lookup
    # miss.
    if postpone:
        exp_pkt = simple_ipv6_pkt(MISS_IP_SRC_ADDR, ip_dst_addr)
        global pending_packets_to_expect
        pending_packets_to_expect.append(exp_pkt)
    else:
        pkt[IPv6].src = MISS_IP_SRC_ADDR
        #logging.info("BasicTest1 show exp_pkt #1")
        #pkt.show()
        tu.verify_packets(self, pkt, [EG_PORT])
    if (len(pending_packets_to_send) >= FLUSH_THRESHOLD) or (len(pending_packets_to_expect) >= FLUSH_THRESHOLD):
        execute_pending_tests(self)

def verify_lookup_hits(self, ip_dst_addr, expected_entry_id, postpone=True):
    in_dmac = 'ee:30:ca:9d:1e:00'
    in_smac = 'ee:cd:00:7e:70:00'
    pkt = simple_ipv6_pkt(IN_IP_SRC_ADDR, ip_dst_addr)
    if postpone:
        global pending_packets_to_send
        pending_packets_to_send.append(pkt)
    else:
        tu.send_packet(self, IG_PORT, pkt)
    # Check that the desired entry is hit, by confirming that its IPv6
    # source address is replaced with the expected entry id.
    a = int_to_ipv6_addr(expected_entry_id)
    if postpone:
        exp_pkt = simple_ipv6_pkt(a, ip_dst_addr)
        global pending_packets_to_expect
        pending_packets_to_expect.append(exp_pkt)
    else:
        pkt[IPv6].src = a
        #logging.info("BasicTest1 show exp_pkt #2")
        #pkt.show()
        tu.verify_packets(self, pkt, [EG_PORT])
    if (len(pending_packets_to_send) >= FLUSH_THRESHOLD) or (len(pending_packets_to_expect) >= FLUSH_THRESHOLD):
        execute_pending_tests(self)


class BasicTest1(LpmTesterTest):
    def runTest(self):
        ip_dst_addr = 'fe80::1'
        fail_if_table_not_empty('ipv6_da_lpm')
        # Before adding any table entries, verify with at least one
        # lookup key that the table gives a miss.
        verify_lookup_misses(self, ip_dst_addr)
        # Execute all pending tests before changing the set of
        # installed table entries.
        execute_pending_tests(self)
        # Add a single table entry that the next packet should match.
        entry_id = 42
        insert_lpm_entry('fe80::0', 10, entry_id)
        verify_lookup_hits(self, ip_dst_addr, entry_id)
        execute_pending_tests(self)


class BasicTest2(LpmTesterTest):
    def runTest(self):
        return
        ip_dst_addr_int = 0xdead_beef_c001_d00d_cafe_9889_1234_5678
        ip_dst_addr = int_to_ipv6_addr(ip_dst_addr_int)
        fail_if_table_not_empty('ipv6_da_lpm')
        verify_lookup_misses(self, ip_dst_addr)
        # Execute all pending tests before changing the set of
        # installed table entries.
        execute_pending_tests(self)

        for prefix_len in range(1, KEY_WIDTH_BITS+1):
            entry_id = prefix_len
            a = ip_dst_addr_int & prefix_mask[prefix_len]
            logging.info("Inserting entry with prefix len %d"
                         "" % (prefix_len))
            insert_lpm_entry(int_to_ipv6_addr(a), prefix_len, entry_id)
        for prefix_len in range(1, KEY_WIDTH_BITS+1):
            entry_id = prefix_len
            if prefix_len == KEY_WIDTH_BITS:
                a = ip_dst_addr_int
            else:
                # By flipping the bit just after the most significant
                # prefix_len bits, we guarantee that the lookup should
                # not match any installed entry with length longer
                # than prefix_len.
                a = ip_dst_addr_int ^ bit_after_prefix[prefix_len]
            logging.info("Attempting to match entry with prefix len %d"
                         "" % (prefix_len))
            verify_lookup_hits(self, int_to_ipv6_addr(a), entry_id)
        execute_pending_tests(self)


def add_random_prefixes(num_prefixes, prefix_len_weight):
    # Create array of cumulative weights of prefix lengths.
    prefix_weight_dist = [0] * (KEY_WIDTH_BITS + 1)
    total_weight = 0
    for prefix_len in range(0, KEY_WIDTH_BITS+1):
        total_weight += prefix_len_weight[prefix_len]
        prefix_weight_dist[prefix_len] = total_weight
    n = 0
    nfails = 0
    ret = []
    while True:
        key = random.getrandbits(KEY_WIDTH_BITS)
        prefix_len_idx = random.randint(0, total_weight-1)
        prefix_len = 0
        while prefix_len < KEY_WIDTH_BITS:
            if prefix_len_idx < prefix_weight_dist[prefix_len]:
                break
            prefix_len += 1
        success = False
        while True:
            try_key = key & prefix_mask[prefix_len]
            status = insert_prefix(try_key, prefix_len)
            if status['error']:
                nfails += 1
                # Try a longer prefix length for the same randomly
                # generated key, unless we are already at the maximum
                # prefix length.
                if prefix_len < KEY_WIDTH_BITS:
                    prefix_len += 1
                else:
                    success = False
                    break
            else:
                key_info = {'key': try_key,
                            'prefix_len': prefix_len,
                            'entry_id': status['entry_id']}
                ret.append(key_info)
                success = True
                break
        if success:
            n += 1
            if n == num_prefixes:
                logging.info("Got %d failures while inserting %d random prefixes"
                             "" % (nfails, num_prefixes))
                return ret


class BigTest1(LpmTesterTest):
    def runTest(self):
        fail_if_table_not_empty('ipv6_da_lpm')
        random.seed(42)
        #random.seed(99)

        t1 = time.time()
        # Weight the random generation of prefix lengths so that
        # prefix length L has relatively likelihood 2^L of being
        # generated, since that is how many such prefixes there are.
        prefix_len_weight = [0] * (KEY_WIDTH_BITS + 1)
        for prefix_len in range(8, 24+1):
            prefix_len_weight[prefix_len] = 1 << prefix_len
            #prefix_len_weight[prefix_len] = 1

        # Measure how many prefixes per second we can test before
        # going larger than a relatively small number.

        # 100 takes about 30 sec to test with test packets, about 0.3
        # sec per key for 3 packets/key.
        #num_prefixes = 100
        num_prefixes = 1000
        #num_prefixes = 1100
        
        key_lst = add_random_prefixes(num_prefixes, prefix_len_weight)
        if True:
            num_prefixes_of_len = [0] * (KEY_WIDTH_BITS + 1)
            for k in key_lst:
                num_prefixes_of_len[k['prefix_len']] += 1
            for prefix_len in range(0, KEY_WIDTH_BITS+1):
                if num_prefixes_of_len[prefix_len] != 0:
                    logging.info("%8d prefixes with length %3d"
                                 "" % (num_prefixes_of_len[prefix_len], prefix_len))
        assert len(key_lst) == num_prefixes
        t2 = time.time()

        # Insert all entries in the table
        for key in key_lst:
            insert_lpm_entry(int_to_ipv6_addr(key['key']), key['prefix_len'],
                             key['entry_id'])
        t3 = time.time()

        # For each entry, send packets that might match it (depending
        # upon what longer prefixes that might shadow it have been
        # installed, which we are not trying to account for here yet),
        # and that definitely will not.
        num_shadow = 0
        test_pkts = []
        for key in key_lst:
            k = key['key']
            prefix_len = key['prefix_len']
            target_entry_id = key['entry_id']
            if prefix_len < KEY_WIDTH_BITS:
                suffix_rand_bits = (random.getrandbits(KEY_WIDTH_BITS) &
                                    suffix_mask[prefix_len])
                k1 = k | suffix_rand_bits
                eid1 = lookup_lpm_key(k1)
                if eid1 != target_entry_id:
                    num_shadow += 1
                pkt = {'lookup_key': k1, 'expected_entry_id': eid1}
                test_pkts.append(pkt)
                k2 = k1 ^ bit_after_prefix[prefix_len]
                eid2 = lookup_lpm_key(k2)
                if eid2 != target_entry_id:
                    num_shadow += 1
                pkt = {'lookup_key': k1, 'expected_entry_id': eid1}
                test_pkts.append(pkt)
            if prefix_len > 0:
                suffix_rand_bits = (random.getrandbits(KEY_WIDTH_BITS) &
                                    suffix_mask[prefix_len])
                k3 = k | suffix_rand_bits
                # Modify key so that it cannot match the current
                # entry.
                k3 = k3 ^ bit_after_prefix[prefix_len - 1]
                eid3 = lookup_lpm_key(k3)
                pkt = {'lookup_key': k3, 'expected_entry_id': eid3}
                test_pkts.append(pkt)
        t4 = time.time()
        num_exp_miss = 0
        for pkt in test_pkts:
            exp_entry_id = pkt['expected_entry_id']
            a = int_to_ipv6_addr(pkt['lookup_key'])
            if exp_entry_id is None:
                num_exp_miss += 1
                verify_lookup_misses(self, a)
            else:
                verify_lookup_hits(self, a, exp_entry_id)
        t5 = time.time()
        logging.info("%8.1f sec to generate %d random entries"
                     "" % (t2 - t1, num_prefixes))
        logging.info("%8.1f sec to install entries in P4 table"
                     "" % (t3 - t2))
        logging.info("%8.1f sec to generate %d test lookup keys in memory"
                     "" % (t4 - t3, len(test_pkts)))
        logging.info("     %d of the test lookup keys unintentionally match longer prefixes"
                     "" % (num_shadow))
        logging.info("%8.1f sec to test %d lookup keys in the device"
                     "" % (t5 - t4, len(test_pkts)))
        logging.info("     %d of the test lookup keys got miss result"
                     "" % (num_exp_miss))
