/*
Copyright 2025 Andy Fingerhut

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

SPDX-License-Identifier: Apache-2.0
*/

#include <core.p4>
#include <v1model.p4>

typedef bit<48>  EthernetAddress;
typedef bit<16>  etype_t;
const etype_t ETYPE_IPV6      = 0x86DD; /* IP protocol version 6 */
typedef bit<128> IPv6Address;
typedef bit<8>   ipproto_t;

// https://en.wikipedia.org/wiki/Ethernet_frame
header ethernet_t {
    EthernetAddress dst_addr;
    EthernetAddress src_addr;
    etype_t ether_type;
}

// Formerly RFC 2460 and errata, combined into RFC 8200 as of 2017
// https://en.wikipedia.org/wiki/IPv6
// https://tools.ietf.org/html/rfc8200
header ipv6_t {
    bit<4>  version;
    bit<8>  traffic_class;
    bit<20> flow_label;
    bit<16> payload_len;
    ipproto_t next_hdr;
    bit<8>  hop_limit;
    IPv6Address src_addr;
    IPv6Address dst_addr;
}

struct metadata_t {
}

struct headers_t {
    ethernet_t ethernet;
    ipv6_t     ipv6;
}

parser parserImpl(packet_in packet,
                  out headers_t hdr,
                  inout metadata_t meta,
                  inout standard_metadata_t stdmeta)
{
    state start {
        transition parse_ethernet;
    }
    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            ETYPE_IPV6: parse_ipv6;
            default: accept;
        }
    }
    state parse_ipv6 {
        packet.extract(hdr.ipv6);
        transition accept;
    }
}

control ingressImpl(inout headers_t hdr,
                    inout metadata_t meta,
                    inout standard_metadata_t stdmeta)
{
    action my_drop() {
        mark_to_drop(stdmeta);
    }
    action miss_action() {
        hdr.ipv6.src_addr = 0xffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff;
    }
    action hit_action(IPv6Address entry_id) {
        hdr.ipv6.src_addr = entry_id;
    }
    table ipv6_da_lpm {
        size = 100000;
        key = {
            hdr.ipv6.dst_addr: lpm;
        }
        actions = {
            @tableonly hit_action;
            @defaultonly miss_action;
        }
        const default_action = miss_action;
    }

    apply {
        if (hdr.ipv6.isValid()) {
            ipv6_da_lpm.apply();
            stdmeta.egress_spec = 1;
        } else {
            my_drop();
        }
    }
}

control egressImpl(inout headers_t hdr,
                   inout metadata_t meta,
                   inout standard_metadata_t stdmeta)
{
    apply {
    }
}

control deparserImpl(packet_out packet,
                     in headers_t hdr)
{
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv6);
    }
}

control verifyChecksum(inout headers_t hdr, inout metadata_t meta) {
    apply {
    }
}

control updateChecksum(inout headers_t hdr, inout metadata_t meta) {
    apply {
    }
}

V1Switch(parserImpl(),
         verifyChecksum(),
         ingressImpl(),
         egressImpl(),
         updateChecksum(),
         deparserImpl()) main;
