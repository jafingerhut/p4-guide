/* -*- mode: P4_16 -*- */
/*
Copyright 2018 Cisco Systems, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

#include <core.p4>
#include <v1model.p4>

header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

header ipv6_t {
    bit<4>   version;
    bit<8>   traffic_class;
    bit<20>  flow_label;
    bit<16>  payload_length;
    bit<8>   next_header;
    bit<8>   hop_limit;
    bit<128> srcAddr;
    bit<128> dstAddr;
}

header ipv6_exthdr_segroute_fixedpart_t {
    bit<8>   next_header;
    bit<8>   hdr_ext_len;
    bit<8>   routing_type;
    bit<8>   segments_left;
    bit<8>   last_entry;
    bit<8>   flags;
    bit<16>  tag;
}

header ipv6_exthdr_segroute_1_no_opts_t {
    bit<128> seg_list_0;
}

header ipv6_exthdr_segroute_2_no_opts_t {
    bit<128> seg_list_0;
    bit<128> seg_list_1;
}

header ipv6_exthdr_segroute_3_no_opts_t {
    bit<128> seg_list_0;
    bit<128> seg_list_1;
    bit<128> seg_list_2;
}

header ipv6_exthdr_segroute_4_or_more_no_opts_t {
    bit<128> seg_list_0;
    bit<128> seg_list_1;
    bit<128> seg_list_2;
    bit<128> seg_list_3;
    // How long should this varbit field be?  It is really a design
    // choice for the person writing the code: what is the longest
    // segment routing header that they want their P4 code to handle?
    // I will choose for this example program up to 4 more IPv6
    // addresses.
#define MAX_IPV6_ADDRESSES_MINUS_4  4
    varbit<(128*MAX_IPV6_ADDRESSES_MINUS_4)> rest_of_exthdr;
}

header udp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<16> udp_length;
    bit<16> checksum;
}

struct headers_t {
    ethernet_t ethernet;
    ipv6_t     ipv6;
    ipv6_exthdr_segroute_fixedpart_t ipv6_sr_fixedpart;
    ipv6_exthdr_segroute_1_no_opts_t ipv6_sr_1;
    ipv6_exthdr_segroute_2_no_opts_t ipv6_sr_2;
    ipv6_exthdr_segroute_3_no_opts_t ipv6_sr_3;
    ipv6_exthdr_segroute_4_or_more_no_opts_t ipv6_sr_4_or_more;
    udp_t      udp;
}

struct metadata_t {
    bit<4> num_srv6_addresses;
}

error {
    BadSRv6HdrExtLen
}

parser ParserImpl(packet_in packet,
                  out headers_t hdr,
                  inout metadata_t meta,
                  inout standard_metadata_t stdmeta)
{
    const bit<16> ETHERTYPE_IPV6 = 0x86dd;
    const bit<8> IPPROTO_UDP = 17;
    const bit<8> IPPROTO_IPV6EXTHDR_ROUTING = 43;

    state start {
        transition parse_ethernet;
    }
    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select (hdr.ethernet.etherType) {
            ETHERTYPE_IPV6: parse_ipv6;
            default: accept;
        }
    }
    state parse_ipv6 {
        packet.extract(hdr.ipv6);
        transition select (hdr.ipv6.next_header) {
            IPPROTO_IPV6EXTHDR_ROUTING: parse_ipv6_exthdr_routing_fixedpart;
            IPPROTO_UDP: parse_udp;
            default: accept;
        }
    }
    state parse_ipv6_exthdr_routing_fixedpart {
        packet.extract(hdr.ipv6_sr_fixedpart);

        // The hdr_ext_len is defined in RFC 8200 as: "Length of the
        // Routing header in 8-octet units, not including the first 8
        // octets."  The first 8 octets are in ipv6_sr_fixedpart in
        // this program.  This program is not intended to handle the
        // cases with options inside of the IPv6 Segment Routing
        // extension header, so the rest of the extension header is 1
        // or more IPv6 addresses, each counting as 2 groups of 8
        // octets in the hdr_ext_len field.

        // This program only processes SRv6 ext headers with at least
        // 1 IPv6 address in them.
        verify(hdr.ipv6_sr_fixedpart.hdr_ext_len != 0, error.BadSRv6HdrExtLen);
        // This program only processes SRv6 ext headers with an
        // integer number of IPv6 addresses in the segment list, and
        // no options inside the IPv6 extension header after that.
        // Thus hdr_ext_len must be even.
        verify(hdr.ipv6_sr_fixedpart.hdr_ext_len[0:0] == 0,
            error.BadSRv6HdrExtLen);
        transition select (hdr.ipv6_sr_fixedpart.hdr_ext_len) {
            2: parse_ipv6_sr_1;
            4: parse_ipv6_sr_2;
            6: parse_ipv6_sr_3;
            8: parse_ipv6_sr_4_or_more;
            10: parse_ipv6_sr_4_or_more;
            12: parse_ipv6_sr_4_or_more;
            14: parse_ipv6_sr_4_or_more;
            16: parse_ipv6_sr_4_or_more;
            default: reject;
        }
    }
    state parse_ipv6_sr_1 {
        packet.extract(hdr.ipv6_sr_1);
        transition parse_ipv6_after_sr;
    }
    state parse_ipv6_sr_2 {
        packet.extract(hdr.ipv6_sr_2);
        transition parse_ipv6_after_sr;
    }
    state parse_ipv6_sr_3 {
        packet.extract(hdr.ipv6_sr_3);
        transition parse_ipv6_after_sr;
    }
    state parse_ipv6_sr_4_or_more {
        // When hdr.ipv6_sr_fixedpart.hdr_ext_len is 8, then the
        // length of the varbit field should be 0 bits.  Each 1 larger
        // value of hdr_ext_len corresponds to 64 more bits (8 octets)
        // in the IPv6 extension header.
        packet.extract(hdr.ipv6_sr_4_or_more,
            (bit<32>)
            (64 * (((bit<10>) hdr.ipv6_sr_fixedpart.hdr_ext_len) - 8)));
        transition parse_ipv6_after_sr;
    }
    state parse_ipv6_after_sr {
        transition select (hdr.ipv6_sr_fixedpart.next_header) {
            IPPROTO_UDP: parse_udp;
            default: accept;
        }
    }
    state parse_udp {
        packet.extract(hdr.udp);
        transition accept;
    }
}

control ingress(inout headers_t hdr,
                inout metadata_t meta,
                inout standard_metadata_t stdmeta)
{
    action srv6_handle_1_address () {
        // TBD: code here to handle case of 1 IPv6 address in SRv6
        // header.
    }
    action srv6_handle_2_addresses () {
        // TBD: code here to handle case of 2 IPv6 addresses in SRv6
        // header.
    }
    action srv6_handle_3_addresses () {
        // TBD: code here to handle case of 3 IPv6 addresses in SRv6
        // header.
    }
    action srv6_handle_4_or_more_addresses () {
        // TBD: code here to handle case of 4 or more IPv6 addresses
        // in SRv6 header.
    }
    table process_srv6_hdr_step1 {
        key = {
            meta.num_srv6_addresses : exact;
        }
        actions = {
            srv6_handle_1_address;
            srv6_handle_2_addresses;
            srv6_handle_3_addresses;
            srv6_handle_4_or_more_addresses;
        }
    }
    apply {
        // Other code here unrelated to SRv6 processing
        
        if (hdr.ipv6_sr_fixedpart.isValid()) {
            meta.num_srv6_addresses =
                (bit<4>) (hdr.ipv6_sr_fixedpart.hdr_ext_len >> 1);
            process_srv6_hdr_step1.apply();
        }

        // Other code here unrelated to SRv6 processing
    }
}

control egress(inout headers_t hdr,
               inout metadata_t meta,
               inout standard_metadata_t stdmeta)
{
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers_t hdr) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv6);
        packet.emit(hdr.ipv6_sr_fixedpart);
        packet.emit(hdr.ipv6_sr_1);
        packet.emit(hdr.ipv6_sr_2);
        packet.emit(hdr.ipv6_sr_3);
        packet.emit(hdr.ipv6_sr_4_or_more);
        packet.emit(hdr.udp);
    }
}

control verifyChecksum(inout headers_t hdr, inout metadata_t meta) {
    apply { }
}

control computeChecksum(inout headers_t hdr, inout metadata_t meta) {
    apply { }
}

V1Switch(ParserImpl(),
         verifyChecksum(),
         ingress(),
         egress(),
         computeChecksum(),
         DeparserImpl()) main;
