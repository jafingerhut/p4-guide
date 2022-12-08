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
#include <psa.p4>

#include <stdheaders.p4>

struct ingress_headers_t {
    ethernet_h       ethernet;
}

struct egress_headers_t {
    ethernet_h       ethernet;
}

struct empty_metadata_t {
}

struct metadata_t {
}

parser ingressParserImpl(
    packet_in pkt,
    out ingress_headers_t hdr,
    inout metadata_t umd,
    in psa_ingress_parser_input_metadata_t istd,
    in empty_metadata_t resubmit_meta,
    in empty_metadata_t recirculate_meta)
{
    state start {
        pkt.extract(hdr.ethernet);
        transition accept;
    }
}

control ingressImpl(
    inout ingress_headers_t hdr,
    inout metadata_t umd,
    in    psa_ingress_input_metadata_t  istd,
    inout psa_ingress_output_metadata_t ostd)
{
    action unicast_to_port (PortId_t p) {
        ostd.drop = false;
        ostd.egress_port = p;
    }
    action mcast_to_group (MulticastGroup_t group_id) {
        ostd.drop = false;
        ostd.multicast_group = group_id;
    }
    action drop () {
        ostd.drop = true;
    }
    table fwd_by_dest_mac {
        key = {
            hdr.ethernet.dst_addr : exact;
        }
        actions = {
            unicast_to_port;
            mcast_to_group;
            drop;
        }
        const default_action = drop;
        size = 1024;
    }
    apply {
        fwd_by_dest_mac.apply();
    }
}

control ingressDeparserImpl(
    packet_out pkt,
    out empty_metadata_t clone_i2e_meta,
    out empty_metadata_t resubmit_meta,
    out empty_metadata_t normal_meta,
    inout ingress_headers_t hdr,
    in metadata_t umd,
    in psa_ingress_output_metadata_t istd)
{
    apply {
        pkt.emit(hdr.ethernet);
    }
}

parser egressParserImpl(
    packet_in pkt,
    out egress_headers_t hdr,
    inout metadata_t umd,
    in psa_egress_parser_input_metadata_t istd,
    in empty_metadata_t normal_meta,
    in empty_metadata_t clone_i2e_meta,
    in empty_metadata_t clone_e2e_meta)
{
    state start {
        pkt.extract(hdr.ethernet);
        transition accept;
    }
}

control egressImpl(
    inout egress_headers_t hdr,
    inout metadata_t umd,
    in    psa_egress_input_metadata_t  istd,
    inout psa_egress_output_metadata_t ostd)
{
    apply {
    }
}

control egressDeparserImpl(
    packet_out pkt,
    out empty_metadata_t clone_e2e_meta,
    out empty_metadata_t recirculate_meta,
    inout egress_headers_t hdr,
    in metadata_t umd,
    in psa_egress_output_metadata_t istd,
    in psa_egress_deparser_input_metadata_t edstd)
{
    apply {
        pkt.emit(hdr.ethernet);
    }
}

IngressPipeline(
    ingressParserImpl(),
    ingressImpl(),
    ingressDeparserImpl()) ip;

EgressPipeline(
    egressParserImpl(),
    egressImpl(),
    egressDeparserImpl()) ep;

PSA_Switch(
    ip,
    PacketReplicationEngine(),
    ep,
    BufferingQueueingEngine()) main;
