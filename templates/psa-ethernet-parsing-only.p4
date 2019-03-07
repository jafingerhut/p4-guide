/*
Copyright 2019 Cisco Systems, Inc.

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

typedef bit<48>  EthernetAddress;

header ethernet_t {
    EthernetAddress dstAddr;
    EthernetAddress srcAddr;
    bit<16>         etherType;
}

struct headers_t {
    ethernet_t       ethernet;
}

struct empty_metadata_t {
}

struct metadata_t {
/*
    bit<4>  a;
    bit<4>  b;
*/
}

parser ingressParserImpl(packet_in packet,
                         out headers_t hdr,
                         inout metadata_t meta,
                         in psa_ingress_parser_input_metadata_t istd,
                         in empty_metadata_t resubmit_meta,
                         in empty_metadata_t recirculate_meta)
{
    state start {
        packet.extract(hdr.ethernet);
        transition accept;
    }
}

control ingressImpl(inout headers_t hdr,
                    inout metadata_t meta,
                    in    psa_ingress_input_metadata_t  istd,
                    inout psa_ingress_output_metadata_t ostd)
{
/*
    action foo() {
        meta.b = meta.b + 5;
    }
    table guh {
        key = {
            hdr.ethernet.srcAddr : exact;
        }
        actions = {
            foo;
            ingress_drop(ostd);
            NoAction;
        }
        const default_action = ingress_drop(ostd);
    }
*/
    apply {
/*
        guh.apply();
*/
    }
}

parser egressParserImpl(packet_in packet,
                        out headers_t hdr,
                        inout metadata_t meta,
                        in psa_egress_parser_input_metadata_t istd,
                        in empty_metadata_t normal_meta,
                        in empty_metadata_t clone_i2e_meta,
                        in empty_metadata_t clone_e2e_meta)
{
    state start {
        transition accept;
    }
}

control egressImpl(inout headers_t hdr,
                   inout metadata_t meta,
                   in    psa_egress_input_metadata_t  istd,
                   inout psa_egress_output_metadata_t ostd)
{
    apply { }
}

control CommonDeparserImpl(packet_out packet,
                           inout headers_t hdr)
{
    apply {
        packet.emit(hdr.ethernet);
    }
}

control IngressDeparserImpl(packet_out packet,
                            out empty_metadata_t clone_i2e_meta,
                            out empty_metadata_t resubmit_meta,
                            out empty_metadata_t normal_meta,
                            inout headers_t hdr,
                            in metadata_t meta,
                            in psa_ingress_output_metadata_t istd)
{
    CommonDeparserImpl() cp;
    apply {
        cp.apply(packet, hdr);
    }
}

control EgressDeparserImpl(packet_out packet,
                           out empty_metadata_t clone_e2e_meta,
                           out empty_metadata_t recirculate_meta,
                           inout headers_t hdr,
                           in metadata_t meta,
                           in psa_egress_output_metadata_t istd,
                           in psa_egress_deparser_input_metadata_t edstd)
{
    CommonDeparserImpl() cp;
    apply {
        cp.apply(packet, hdr);
    }
}

IngressPipeline(ingressParserImpl(),
                ingressImpl(),
                IngressDeparserImpl()) ip;

EgressPipeline(egressParserImpl(),
               egressImpl(),
               EgressDeparserImpl()) ep;

PSA_Switch(ip, PacketReplicationEngine(), ep, BufferingQueueingEngine()) main;
