/* -*- P4_16 -*- */

/*
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
*/

#include <core.p4>
#include <pna.p4>

const int IPV4_HOST_SIZE = 65536;
const MirrorSlotId_t MIR_SLOT_PRIMARY = (MirrorSlotId_t) 1;

typedef bit<48>  EthernetAddress;
typedef bit<32>  IPv4Address;
typedef bit<128> IPv6Address;

typedef bit<16> etype_t;
const etype_t ETYPE_IPV4      = 0x0800;

typedef bit<8> ipproto_t;

// https://en.wikipedia.org/wiki/Ethernet_frame
header ethernet_h {
    EthernetAddress dst_addr;
    EthernetAddress src_addr;
    etype_t ether_type;
}

// RFC 791
// https://en.wikipedia.org/wiki/IPv4
// https://tools.ietf.org/html/rfc791
header ipv4_h {
    bit<4>  version;            // version always 4 for IPv4
    bit<4>  ihl;                // ihl=header length
    bit<8>  diffserv;           // 6 bits of DSCP followed by 2-bit ECN
    bit<16> total_len;          // in bytes, including IPv4 header
    bit<16> identification;
    bit<16> flags_frag_offset;
    bit<8>  ttl;                // time to live
    ipproto_t protocol;
    bit<16> hdr_checksum;
    IPv4Address src_addr;
    IPv4Address dst_addr;
}

struct headers_t {
    ethernet_h   ethernet;
    ipv4_h       ipv4;
}

struct metadata_t {
}

parser MainParserImpl(
    packet_in pkt,
    out   headers_t  hdr,
    inout metadata_t meta,
    in    pna_main_parser_input_metadata_t istd)
{
     state start {
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select (hdr.ethernet.ether_type) {
            ETYPE_IPV4:  parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition accept;
    }
}

// As of 2023-Mar-14, p4c-dpdk implementation of PNA architecture
// still requires PreControl.

control PreControlImpl(
    in    headers_t hdr,
    inout metadata_t meta,
    in    pna_pre_input_metadata_t  istd,
    inout pna_pre_output_metadata_t ostd)
{
    apply {
    }
}

    /***************** M A T C H - A C T I O N  *********************/

control MainControlImpl(
    inout headers_t  hdr,
    inout metadata_t meta,
    in    pna_main_input_metadata_t  istd,
    inout pna_main_output_metadata_t ostd)
{
    action drop () {
        drop_packet();
    }

    action drop_and_mirror (MirrorSessionId_t mirror_session_id) {
        drop_packet();
        mirror_packet(MIR_SLOT_PRIMARY, mirror_session_id);
    }

    action send(PortId_t port) {
        send_to_port(port);
    }

    action send_and_mirror(PortId_t port, MirrorSessionId_t mirror_session_id) {
        send_to_port(port);
        mirror_packet(MIR_SLOT_PRIMARY, mirror_session_id);
    }

    table ipv4_host {
        key = {
            hdr.ipv4.dst_addr : exact;
        }
        actions = {
            send;
            drop;
            send_and_mirror;
            drop_and_mirror;
        }
        const default_action = drop();
        size = IPV4_HOST_SIZE;
    }

    apply {
        if (hdr.ipv4.isValid()) {
            ipv4_host.apply();
        } else {
            drop();
        }
    }
}

    /*********************  D E P A R S E R  ************************/

control MainDeparserImpl(
    packet_out pkt,
    in    headers_t hdr,
    in    metadata_t meta,
    in    pna_main_output_metadata_t ostd)
{
    apply {
        pkt.emit(hdr);
    }
}

/************ F I N A L   P A C K A G E ******************************/

PNA_NIC(
    MainParserImpl(),
    PreControlImpl(),
    MainControlImpl(),
    MainDeparserImpl()
    ) main;
