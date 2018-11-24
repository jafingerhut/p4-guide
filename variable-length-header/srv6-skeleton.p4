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

// Note that P4 does not know the language standards.  If you want to
// take what is one header in a standards document and divide it up
// into multiple headers in P4, you may do that, and should if it
// helps you write correct and understandable code.

// In this example we define one header type for the first 8 bytes of
// the SRv6 (Segment Routing IPv6) extension header, since it always
// has the same format for all such headers.  It also contains the
// hdr_ext_len field, which indicates the length of the entire SRv6
// header.

header srv6_fixedpart_t {
    bit<8>   next_header;
    bit<8>   hdr_ext_len;
    bit<8>   routing_type;
    bit<8>   segments_left;
    bit<8>   last_entry;
    bit<8>   flags;
    bit<16>  tag;
}

// Now define one header for each of several cases that we want our
// program to handle explicitly.

header srv6_seg_list_1_t {
    bit<128> seg_list_0;
}

header srv6_seg_list_2_t {
    bit<128> seg_list_0;
    bit<128> seg_list_1;
}

header srv6_seg_list_3_t {
    bit<128> seg_list_0;
    bit<128> seg_list_1;
    bit<128> seg_list_2;
}

header srv6_seg_list_4_or_more_t {
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
    srv6_fixedpart_t srv6_fixedpart;
    srv6_seg_list_1_t srv6_1_seg;
    srv6_seg_list_2_t srv6_2_seg;
    srv6_seg_list_3_t srv6_3_seg;
    srv6_seg_list_4_or_more_t srv6_4_or_more_seg;
    udp_t      udp;
}

struct metadata_t {
    bit<4> num_srv6_addresses;
}

error {
    BadSRv6HdrExtLen
}

#include "debug-srv6.p4"

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
        packet.extract(hdr.srv6_fixedpart);
        // The hdr_ext_len is defined in RFC 8200 as: "Length of the
        // Routing header in 8-octet units, not including the first 8
        // octets."  The first 8 octets are in srv6_fixedpart in
        // this program.  This program is not intended to handle the
        // cases with options inside of the IPv6 Segment Routing
        // extension header, so the rest of the extension header is 1
        // or more IPv6 addresses, each counting as 2 groups of 8
        // octets in the hdr_ext_len field.

        // This program only handles SRv6 ext headers with one or more
        // IPv6 addresses in the segment list, and no options inside
        // the IPv6 extension header after that.  Thus hdr_ext_len
        // must be even, and not 0.  This example program is only
        // written to handle SRv6 headers with up to 8 such IPv6
        // addresses.
        transition select (hdr.srv6_fixedpart.hdr_ext_len) {
            2: parse_srv6_1;
            4: parse_srv6_2;
            6: parse_srv6_3;
            8: parse_srv6_4_or_more;
            10: parse_srv6_4_or_more;
            12: parse_srv6_4_or_more;
            14: parse_srv6_4_or_more;
            16: parse_srv6_4_or_more;
            default: parse_srv6_bad_len;
        }
    }
    state parse_srv6_bad_len {
        verify(false, error.BadSRv6HdrExtLen);
        transition reject;
    }
    state parse_srv6_1 {
        packet.extract(hdr.srv6_1_seg);
        transition parse_ipv6_after_srv6;
    }
    state parse_srv6_2 {
        packet.extract(hdr.srv6_2_seg);
        transition parse_ipv6_after_srv6;
    }
    state parse_srv6_3 {
        packet.extract(hdr.srv6_3_seg);
        transition parse_ipv6_after_srv6;
    }
    state parse_srv6_4_or_more {
        // When hdr.srv6_fixedpart.hdr_ext_len is 8, then the
        // length of the varbit field should be 0 bits.  Each 1 larger
        // value of hdr_ext_len corresponds to 64 more bits (8 octets)
        // in the IPv6 extension header.
        packet.extract(hdr.srv6_4_or_more_seg,
            (bit<32>)
            (64 * (((bit<10>) hdr.srv6_fixedpart.hdr_ext_len) - 8)));
        transition parse_ipv6_after_srv6;
    }
    state parse_ipv6_after_srv6 {
        transition select (hdr.srv6_fixedpart.next_header) {
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
    debug_srv6_fixedpart() debug_srv6_fixedpart_inst;

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
        
        if (hdr.srv6_fixedpart.isValid()) {
            // Debug table to show in simple_switch console log the
            // values of the fields in hdr.srv6_fixedpart
            debug_srv6_fixedpart_inst.apply(hdr.srv6_fixedpart);

            meta.num_srv6_addresses =
                (bit<4>) (hdr.srv6_fixedpart.hdr_ext_len >> 1);
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
        packet.emit(hdr.srv6_fixedpart);
        packet.emit(hdr.srv6_1_seg);
        packet.emit(hdr.srv6_2_seg);
        packet.emit(hdr.srv6_3_seg);
        packet.emit(hdr.srv6_4_or_more_seg);
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
