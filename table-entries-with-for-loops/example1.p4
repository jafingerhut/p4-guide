/*
Copyright 2023 Intel Corporation

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

header ipv4_t {
    bit<4>  version;
    bit<4>  ihl;
    bit<8>  diffserv;
    bit<16> totalLen;
    bit<16> identification;
    bit<3>  flags;
    bit<13> fragOffset;
    bit<8>  ttl;
    bit<8>  protocol;
    bit<16> hdrChecksum;
    bit<32> srcAddr;
    bit<32> dstAddr;
}

struct fwd_metadata_t {
}

struct metadata_t {
    fwd_metadata_t fwd_metadata;
}

struct headers_t {
    ethernet_t ethernet;
    ipv4_t     ipv4;
}

parser parserImpl(packet_in packet,
                  out headers_t hdr,
                  inout metadata_t meta,
                  inout standard_metadata_t stdmeta)
{
    const bit<16> ETHERTYPE_IPV4 = 16w0x0800;

    state start {
        transition parse_ethernet;
    }
    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            ETHERTYPE_IPV4: parse_ipv4;
            default: accept;
        }
    }
    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition accept;
    }
}

const bit<9> CPU_PORT = 255;

control ingressImpl(inout headers_t hdr,
                    inout metadata_t meta,
                    inout standard_metadata_t stdmeta)
{
    action my_drop() {
        mark_to_drop(stdmeta);
    }
    action set_port(bit<9> port) {
        stdmeta.egress_spec = port;
    }
    table ing_filter {
        key = {
            stdmeta.ingress_port : ternary;
            hdr.ipv4.ttl : ternary;
            hdr.ipv4.protocol : ternary;
        }
        actions = {
            my_drop;
            set_port;
            NoAction;
        }
        entries = {
            (_, 0, _): set_port(CPU_PORT);
#ifdef NEW_FEATURE
            for (p in (list<bit<8>>) {3, 18, 19, 28, 42, 52}) {
                // Note: Within a for loop body, the loop variable is
                // a local compile-time known value.
                (_, _, p) : my_drop();
                // There can be additional entries here, and all of
                // them within the { } of the for loop are generated
                // once per loop iteration.
            }
            for (bit<8> p = 128; p <= 255; p = p + 1) {
                for (bit<9> port = 0; port <= MAX_PORT_ID; port = port + 1) {
                    (port, _, p) : my_drop();
                }
            }
            for (bit<8> p = 80; p <= 120; p = p + 1) {
                if (p != 99) {
                    (_, _, p) : my_drop();
                }
            }
#endif // NEW_FEATURE
        }
        const default_action = NoAction();
    }

    apply {
        if (hdr.ipv4.isValid()) {
            ing_filter.apply();
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
        packet.emit(hdr.ipv4);
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
