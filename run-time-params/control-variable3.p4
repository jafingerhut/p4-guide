/*
Copyright 2017 Cisco Systems, Inc.

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

typedef bit<48>  EthernetAddress;

header Ethernet_h {
    EthernetAddress dstAddr;
    EthernetAddress srcAddr;
    bit<16>         etherType;
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

struct Parsed_packet {
    Ethernet_h    ethernet;
    ipv4_t     ipv4;
}

struct mystruct1 {
    bit<4>  a;
    bit<4>  b;
}

control DeparserI(packet_out packet,
                  in Parsed_packet hdr) {
    apply { packet.emit(hdr.ethernet); }
}

parser parserI(packet_in pkt,
               out Parsed_packet hdr,
               inout mystruct1 meta,
               inout standard_metadata_t stdmeta) {
    state start {
        pkt.extract(hdr.ethernet);
        transition accept;
    }
}

control C1(inout Parsed_packet hdr,
           inout mystruct1 meta,
           inout standard_metadata_t stdmeta);

control MyC1(inout Parsed_packet hdr,
             inout mystruct1 meta,
             inout standard_metadata_t stdmeta) {
    apply {
        hdr.ethernet.dstAddr = hdr.ethernet.dstAddr + 1;
    }
}

control MyC2(inout Parsed_packet hdr,
             inout mystruct1 meta,
             inout standard_metadata_t stdmeta) {
    apply {
        hdr.ethernet.srcAddr = hdr.ethernet.srcAddr + 1;
    }
}

control cIngress(inout Parsed_packet hdr,
                 inout mystruct1 meta,
                 inout standard_metadata_t stdmeta) {
    MyC1() c0;
    MyC1() c1;
    MyC2() c2;
    apply {
        c0 = c1;
        // 2017-Aug-16 version of p4test gives the following error on
        // the line above:
        //
        // control-variable3.p4(95): error: Expression c0 cannot be the target of an assignment
        //         c0 = c1;
        //         ^^
        if (hdr.ipv4.dstAddr[0:0] == 1) {
            c0 = c2;
        }
        hdr.ipv4.dstAddr[0:0] = hdr.ipv4.dstAddr[0:0] + 1;
        c0.apply(hdr, meta, stdmeta);
    }
}

control cEgress(inout Parsed_packet hdr,
                inout mystruct1 meta,
                inout standard_metadata_t stdmeta) {
    apply { }
}

control vc(in Parsed_packet hdr,
           inout mystruct1 meta) {
    apply { }
}

control uc(inout Parsed_packet hdr,
           inout mystruct1 meta) {
    apply { }
}

V1Switch<Parsed_packet, mystruct1>(parserI(),
                                   vc(),
                                   cIngress(),
                                   cEgress(),
                                   uc(),
                                   DeparserI()) main;
