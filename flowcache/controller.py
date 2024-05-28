#!/usr/bin/env python3

# Copyright 2024 Andy Fingerhut (andy.fingerhut@gmail.com)
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
import time

import p4runtime_sh.shell as sh
import p4runtime_sh.p4runtime as shp4rt
import p4runtime_shell_utils as shu
from scapy.all import *


######################################################################
# Configure logging
######################################################################

# Note: I am not an expert at configuring the Python logging library.
# Recommendations welcome on improvements here.

# TODO: Where do logging messages go when this program is executed?

logger = logging.getLogger(None)
ch = logging.StreamHandler()
logger.setLevel(logging.INFO)
#logger.setLevel(logging.DEBUG)
# create formatter and add it to the handlers
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
ch.setFormatter(formatter)
logger.addHandler(ch)

global_data = {}

# These values must correspond with ones in the P4 source code
global_data['CPU_PORT'] = 510
global_data['CPU_PORT_CLONE_SESSION_ID'] = 57
global_data['NUM_PORTS'] = 5

def setUp(grpc_addr='localhost:9559',
          p4info_txt_fname='flowcache.p4info.txtpb'):
    logger.info("setUp()")
    sh.setup(device_id=0,
             grpc_addr=grpc_addr,
             election_id=(0, 1), # (high_32bits, lo_32bits)
             config=None,
             verbose=False)

    # Create Python dicts from name to integer values, and integer
    # values to names, for the P4_16 serializable enum types
    # PuntReason_t and ControllerOpcode_t once here during setup.
    logger.info("Reading p4info from {}".format(p4info_txt_fname))
    p4info_data = shu.read_p4info_txt_file(p4info_txt_fname)

    global_data['punt_reason_name2int'], global_data['punt_reason_int2name'] = \
        shu.serializable_enum_dict(p4info_data, 'PuntReason_t')
    global_data['opcode_name2int'], global_data['opcode_int2name'] = \
        shu.serializable_enum_dict(p4info_data, 'ControllerOpcode_t')
    logger.debug("punt_reason_name2int=%s" % (global_data['punt_reason_name2int']))
    logger.debug("punt_reason_int2name=%s" % (global_data['punt_reason_int2name']))
    logger.debug("opcode_name2int=%s" % (global_data['opcode_name2int']))
    logger.debug("opcode_int2name=%s" % (global_data['opcode_int2name']))

    global_data['p4info_obj_map'] = shu.make_p4info_obj_map(p4info_data)
    global_data['cpm_packetin_id2data'] = \
        shu.controller_packet_metadata_dict_key_id(global_data['p4info_obj_map'],
                                                   "packet_in")
    logger.debug("cpm_packetin_id2data=%s" % (global_data['cpm_packetin_id2data']))

    global_data['pktin'] = sh.PacketIn()

def tearDown():
    logger.info("tearDown()")
    sh.teardown()

def get_all_packetins(pktin, timeout_sec):
    pktlist = []
    pktin.sniff(lambda p: pktlist.append(p), timeout=timeout_sec)
    return pktlist

def writeCloneSession(clone_session_id, port_list):
    replication_id = 0
    cse = sh.CloneSessionEntry(clone_session_id)
    for p in port_list:
        cse.add(p, replication_id)
    cse.insert()

#############################################################
# Define a few small helper functions that help construct
# parameters for the table_add() method.
#############################################################

def add_flow_cache_entry_action_cached_action(ipv4_proto_int,
                                              ipv4_src_addr_str,
                                              ipv4_dst_addr_str,
                                              port_int,
                                              decrement_ttl_bool,
                                              new_dscp_int):
    te = sh.TableEntry('flow_cache')(action='cached_action')
    te.match['protocol'] = '%s' % (ipv4_proto_int)
    te.match['src_addr'] = ipv4_src_addr_str
    te.match['dst_addr'] = ipv4_dst_addr_str
    te.action['port'] = '%d' % (port_int)
    if decrement_ttl_bool:
        x = 1
    else:
        x = 0
    te.action['decrement_ttl'] = '%d' % (x)
    te.action['new_dscp'] = '%d' % (new_dscp_int)
    te.insert()


setUp()

PUNT_REASON_FLOW_UNKNOWN = global_data['punt_reason_name2int']['FLOW_UNKNOWN']
logger.info("Found numeric code %d for punt reason FLOW_UNKNOWN"
            "" % (PUNT_REASON_FLOW_UNKNOWN))

logger.info("Initializing clone session id CPU_PORT_CLONE_SESSION_ID")
try:
    writeCloneSession(global_data['CPU_PORT_CLONE_SESSION_ID'],
                      [global_data['CPU_PORT']])
except shp4rt.P4RuntimeWriteException as e:
    logger.warning("Got exception trying to configure clone session %d."
                   "  Assuming it was initialized already in an earlier"
                   " run of the controller."
                   "" % (global_data['CPU_PORT_CLONE_SESSION_ID']))
tname = 'flow_cache'
n = shu.entry_count(tname)
logger.info("Found %d entries in table '%s'" % (n, tname))
if n > 0:
    shu.delete_all_entries(tname)
    n = shu.entry_count(tname)
    logger.info("After deleting all entries in table '%s' found %d entries"
                "" % (tname, n))

while True:
    pktin_lst = get_all_packetins(global_data['pktin'], 0.01)
    print("Received %d PacketIn messages" % (len(pktin_lst)))
    if len(pktin_lst) > 0:
        i = 0
        for pktin in pktin_lst:
            pkt = Ether(pktin.packet.payload)
            ip_proto = pkt[IP].proto
            ip_sa_str = pkt[IP].src
            ip_sa_int = shu.ipv4_to_int(ip_sa_str)
            ip_da_str = pkt[IP].dst
            ip_da_int = shu.ipv4_to_int(ip_da_str)
            pktinfo = shu.decode_packet_in_metadata(
                global_data['cpm_packetin_id2data'], pktin.packet)
            debug_packetin = False
            if debug_packetin:
                i += 1
                print("")
                print("pktin %d of %d" % (i, len(pktin_lst)))
                print("type(pktin.packet.payload)=%s"
                      "" % (type(pktin.packet.payload)))
                print(pktin)
                print(pktinfo)
                print("Scapy decode:")
                print(pkt)
                print("IPv4 proto %d (type %s)"
                      "" % (ip_proto, type(ip_proto)))
                print("IPv4 SA %08x (type %s)"
                      "" % (ip_sa_int, type(ip_sa_int)))
                print("IPv4 DA %08x (type %s)"
                      "" % (ip_da_int, type(ip_da_int)))
            if pktinfo['metadata']['punt_reason'] == PUNT_REASON_FLOW_UNKNOWN:
                # Note that a controller can be written to do
                # _anything you want_ when receiving packets from the
                # switch.  Below is a toy example that simply
                # calculates an output port from some fields of the
                # packet, and installs a single entry in one table
                # that should cause future packets to be sent to that
                # output port.
                #
                # However, a controller can be written to do other
                # things, such as:
                #
                # + Installing entries in multiple tables, and/or
                #   modifying or removing entries.
                # + Modify multicast group or clone/mirror configurations.
                # + Bring links down.
                # + Load a different P4 program into the switch.
                flow_hash = ip_sa_int ^ ip_da_int ^ ip_proto
                dest_port_int = 1 + (flow_hash % global_data['NUM_PORTS'])
                decrement_ttl_bool = True
                new_dscp_int = 5
                add_flow_cache_entry_action_cached_action(ip_proto,
                                                          ip_sa_str,
                                                          ip_da_str,
                                                          dest_port_int,
                                                          decrement_ttl_bool,
                                                          new_dscp_int)
                logger.info("For flow (SA=%s, DA=%s, proto=%d)"
                            " added table entry to send packets"
                            " to port %d with new DSCP %d"
                            "" % (ip_sa_str, ip_da_str, ip_proto,
                                  dest_port_int, new_dscp_int))
    time.sleep(5)

tearDown()
