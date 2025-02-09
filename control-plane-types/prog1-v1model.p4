// Copyright 2018 Andy Fingerhut
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// SPDX-License-Identifier: Apache-2.0

#include <core.p4>
#include <v1model.p4>

typedef bit<9> PortId_t;

header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> ethType;
}

header ipv4_t {
    bit<4>  version;
    bit<4>  ihl;
    bit<8>  diffserv;
    bit<16> ipv4_length;
    bit<16> id;
    bit<3>  flags;
    bit<13> offset;
    bit<8>  ttl;
    bit<8>  protocol;
    bit<16> checksum;
    bit<32> srcAddr;
    bit<32> dstAddr;
}

struct metadata {
}

struct headers {
    ethernet_t eth;
    ipv4_t     ipv4;
}

parser ParserImpl(packet_in packet,
    out headers hdr,
    inout metadata meta,
    inout standard_metadata_t standard_metadata)
{
    state start {
        transition parse_eth;
    }
    state parse_eth {
        packet.extract(hdr.eth);
        transition select(hdr.eth.ethType) {
            0x800: parse_ipv4;
            default: accept;
        }
    }
    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition accept;
    }
}

control egress(inout headers hdr,
    inout metadata meta,
    inout standard_metadata_t standard_metadata)
{
    apply { }
}

struct mac_learn_digest {
    bit<48> srcAddr;
    bit<9>  ingress_port;
}

control ingress(inout headers hdr,
    inout metadata meta,
    inout standard_metadata_t standard_metadata)
{
    action nop() { }
    action generate_learn_notify() {

        // Current p4c does not allow operations inside digest() call
        // in runs when generating P4Info file, e.g. like this:

        // p4test --p4runtime-format json --p4runtime-file prog1.json prog1.p4

        // For example, it gives an error if I try to do '& 0xff'
        // after ingress_port.  It also gives an error if I try to
        // replace 'standard_metadata.ingress_port' with a constant
        // like 0xff.

        // The names in P4Info file currently are generated from the
        // fields below, not from the names of the member fields of
        // struct mac_learn_digest.
        
        digest<mac_learn_digest>((bit<32>) 1024,
            { hdr.eth.srcAddr,
              standard_metadata.ingress_port
            });
    }
    action action_with_parameters(PortId_t port, bit<48> new_dest_mac) {
        standard_metadata.egress_port = port;
        hdr.eth.dstAddr = new_dest_mac;
    }
    table learn_notify {
        key = {
            standard_metadata.ingress_port : exact;
            hdr.eth.srcAddr                : exact;
        }
        actions = {
            nop;
            generate_learn_notify;
            action_with_parameters;
        }
    }
    apply {
        learn_notify.apply();
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.eth);
        packet.emit(hdr.ipv4);
    }
}

control verifyChecksum(inout headers hdr, inout metadata meta) {
    apply { }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply { }
}

V1Switch(ParserImpl(),
    verifyChecksum(),
    ingress(),
    egress(),
    computeChecksum(),
    DeparserImpl()) main;
