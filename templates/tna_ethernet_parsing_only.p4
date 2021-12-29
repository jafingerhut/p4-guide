/*
Copyright 2021 Intel Corporation

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

header ethernet_h {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    bit<16>    ether_type;
}

header bridge_metadata_t {
    // user-defined metadata carried over from ingress to egress.
}

struct my_ingress_headers_t {
    bridge_metadata_t bridge_md;
    ethernet_h ethernet;
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
        transition accept;
    }
}

control MyIngress(
    inout my_ingress_headers_t  ig_hdr,
    inout my_ingress_metadata_t ig_md,
    in    ingress_intrinsic_metadata_t              ig_intr_md,
    in    ingress_intrinsic_metadata_from_parser_t  ig_prsr_md,
    inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
    inout ingress_intrinsic_metadata_for_tm_t       ig_tm_md)
{
    action unicast_to_port (PortId_t p) {
        ig_tm_md.ucast_egress_port = p;
    }
    action my_drop () {
        ig_dprsr_md.drop_ctl = 1;
    }
    table forward_by_destmac {
        key = {
            ig_hdr.ethernet.dst_addr : exact;
        }
        actions = {
            unicast_to_port;
            my_drop;
            NoAction;
        }
        const default_action = my_drop;
        size = 1024;
    }

    apply {
        forward_by_destmac.apply();
    }
}

control MyIngressDeparser(
    packet_out pkt,
    inout my_ingress_headers_t  ig_hdr,
    in    my_ingress_metadata_t ig_md,
    in    ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md)
{
    apply {
        pkt.emit(ig_hdr.bridge_md);
        pkt.emit(ig_hdr.ethernet);
    }
}

parser MyEgressParser(
    packet_in pkt,
    out my_egress_headers_t  eg_hdr,
    out my_egress_metadata_t eg_md,
    out egress_intrinsic_metadata_t eg_intr_md)
{
    state start {
        pkt.extract(eg_intr_md);
        transition parse_bridge_metadata;
    }

    state parse_bridge_metadata {
        pkt.extract(eg_hdr.bridge_md);
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(eg_hdr.ethernet);
        transition accept;
    }
}

control MyEgress(
    inout my_egress_headers_t  eg_hdr,
    inout my_egress_metadata_t eg_md,
    in    egress_intrinsic_metadata_t                 eg_intr_md,
    in    egress_intrinsic_metadata_from_parser_t     eg_prsr_md,
    inout egress_intrinsic_metadata_for_deparser_t    eg_dprsr_md,
    inout egress_intrinsic_metadata_for_output_port_t eg_oport_md)
{
    apply {
    }
}

control MyEgressDeparser(
    packet_out pkt,
    inout my_egress_headers_t  eg_hdr,
    in    my_egress_metadata_t eg_md,
    in    egress_intrinsic_metadata_for_deparser_t eg_dprsr_md)
{
    apply {
        pkt.emit(eg_hdr.ethernet);
    }
}

Pipeline(MyIngressParser(),
         MyIngress(),
         MyIngressDeparser(),
         MyEgressParser(),
         MyEgress(),
         MyEgressDeparser()) pipe;

// In a multi-pipe Tofino device, the TNA package instantiation below
// implies that the same P4 code behavior is loaded into all of the
// pipes.

Switch(pipe) main;
