/*
Copyright 2022 Intel Corporation

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
#include <tna.p4>


typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;

header ethernet_h {
    mac_addr_t dstAddr;
    mac_addr_t srcAddr;
    bit<16>    etherType;
}

header ipv4_h {
    bit<4>       version;
    bit<4>       ihl;
    bit<8>       diffserv;
    bit<16>      total_len;
    bit<16>      identification;
    bit<3>       flags;
    bit<13>      frag_offset;
    bit<8>       ttl;
    bit<8>       protocol;
    bit<16>      hdr_checksum;
    ipv4_addr_t  src_addr;
    ipv4_addr_t  dst_addr;
}

header bridge_metadata_t {
    // user-defined metadata carried over from ingress to egress.
}

struct my_ingress_headers_t {
    bridge_metadata_t bridge_md;
    ethernet_h ethernet;
    ipv4_h     ipv4;
}

struct my_egress_headers_t {
    bridge_metadata_t bridge_md;
    ethernet_h ethernet;
}

struct my_ingress_metadata_t {
    // user-defined ingress metadata
}

struct my_egress_metadata_t {
    // user-defined egress metadata
}

parser MyIngressParser(
    packet_in pkt,
    out my_ingress_headers_t  ig_hdr,
    out my_ingress_metadata_t ig_md,
    out ingress_intrinsic_metadata_t ig_intr_md)
{
    state start {
        pkt.extract(ig_intr_md);
        transition select(ig_intr_md.resubmit_flag) {
            1: parse_resubmit;
            0: parse_port_metadata;
        }
    }
    state parse_resubmit {
        // Skip over resubmit header data here.  Extract it if you
        // wish, instead of ignoring it, but this template program
        // never resubmits packets, so this parser state will never be
        // executed.
        pkt.advance(PORT_METADATA_SIZE);
        transition parse_ethernet;
    }
    state parse_port_metadata {
        pkt.advance(PORT_METADATA_SIZE);
        transition parse_ethernet;
    }
    state parse_ethernet {
        pkt.extract(ig_hdr.ethernet);
        transition select(ig_hdr.ethernet.etherType) {
            0x0800:  parse_ipv4;
            default: accept;
        }
    }
    state parse_ipv4 {
        pkt.extract(ig_hdr.ipv4);
        transition accept;
    }
}

control MyIngress(
    inout my_ingress_headers_t  hdr,
    inout my_ingress_metadata_t ig_md,
    in    ingress_intrinsic_metadata_t              ig_intr_md,
    in    ingress_intrinsic_metadata_from_parser_t  ig_prsr_md,
    inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
    inout ingress_intrinsic_metadata_for_tm_t       ig_tm_md)
