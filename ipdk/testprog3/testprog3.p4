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

typedef bit<48>  EthernetAddress;
typedef bit<32>  IPv4Address;
#ifdef USE_64BIT_FOR_IPV6_ADDRESSES
typedef bit<64>  IPv6Address;
typedef bit<64>  IPv4ORv6Address;
#else
typedef bit<128> IPv6Address;
typedef bit<128> IPv4ORv6Address;
#endif

header ethernet_t {
    EthernetAddress dst_addr;
    EthernetAddress src_addr;
    bit<16>         ether_type;
}

header ipv4_t {
    bit<4>      version;
    bit<4>      ihl;
    bit<8>      diffserv;
    bit<16>     total_len;
    bit<16>     identification;
    bit<3>      flags;
    bit<13>     frag_offset;
    bit<8>      ttl;
    bit<8>      protocol;
    bit<16>     hdr_checksum;
    IPv4Address src_addr;
    IPv4Address dst_addr;
}

header ipv6_t {
    bit<4>      version;
    bit<8>      traffic_class;
    bit<20>     flow_label;
    bit<16>     payload_length;
    bit<8>      next_header;
    bit<8>      hop_limit;
    IPv6Address src_addr;
    IPv6Address dst_addr;
}

struct headers_t {
    ethernet_t    ethernet;
    ipv4_t        ipv4;
    ipv6_t        ipv6;
}

struct metadata_t {
}

parser MainParserImpl(
    packet_in pkt,
    out headers_t hdr,
    inout metadata_t meta,
    in pna_main_parser_input_metadata_t istd)
{
    state start {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            0x0800:  parse_ipv4;
            0x86dd:  parse_ipv6;
            default: accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition accept;
    }

    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        transition accept;
    }
}

// As of 2024-Feb-26, p4c-dpdk implementation of PNA architecture
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

control MainControlImpl(
    inout headers_t  hdr,
    inout metadata_t meta,
    in    pna_main_input_metadata_t  istd,
    inout pna_main_output_metadata_t ostd)
{
    action drop () {
        drop_packet();
    }

    action simple_send (PortId_t p) {
        send_to_port(p);
    }

    action send (
        PortId_t p,
        bit<8> x
#ifdef USE_128BIT_ACTION_PARAMETER
        , bit<128> y
#endif
    ) {
        send_to_port(p);
        hdr.ipv6.traffic_class = x;
    }

    table t1 {
        key = {
#ifdef USE_RANGE_MATCH_KIND
            hdr.ipv6.next_header: range;
#else
            hdr.ipv6.next_header: exact;
#endif
        }
        actions = { send; simple_send; }
        const default_action = simple_send((PortId_t) 1);
    }

    apply {
        if (hdr.ipv6.isValid()) {
            t1.apply();
        } else {
            drop();
        }
    }
}

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

PNA_NIC(
    MainParserImpl(),
    PreControlImpl(),
    MainControlImpl(),
    MainDeparserImpl()
    ) main;
