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


header bridge_metadata_t {
    // user-defined metadata carried over from ingress to egress.
}

struct my_ingress_headers_t {
    bridge_metadata_t bridge_md;
}

struct my_egress_headers_t {
    bridge_metadata_t bridge_md;
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
        // parser code begins here
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
    apply {
        // ingress control code here
    }
}

control MyIngressDeparser(
    packet_out pkt,
    inout my_ingress_headers_t  ig_hdr,
    in    my_ingress_metadata_t ig_md,
    in    ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md)
{
    apply {
        // emit headers for out-of-ingress packets here
    }
}

parser MyEgressParser(
    packet_in pkt,
    out my_egress_headers_t  eg_hdr,
    out my_egress_metadata_t eg_md,
    out egress_intrinsic_metadata_t eg_intr_md)
{
    state start {
        // parser code begins here
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
        // egress control code here
    }
}

control MyEgressDeparser(
    packet_out pkt,
    inout my_egress_headers_t  eg_hdr,
    in    my_egress_metadata_t eg_md,
    in    egress_intrinsic_metadata_for_deparser_t eg_dprsr_md)
{
    apply {
        // emit desired egress headers here
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
