/* -*- mode: P4_16 -*- */
/*
Copyright 2024 Andy Fingerhut

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

typedef bool t;

struct s
{
  t f1;
  t f2;
}

header h_t {
    s b;
    bool x;
    bool y;
    bit<4> z;

    bit<8> f;
    bit<8> g;
}

struct metadata_t {
    bit<8> status;
}

struct headers_t {
    ethernet_t ethernet;
    h_t h;
}

parser parserImpl(packet_in packet,
                  out headers_t hdr,
                  inout metadata_t meta,
                  inout standard_metadata_t stdmeta)
{
    state start {
        meta.status = 0;
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            0x7fff: parse_h;
            default: accept;
        }
    }
    state parse_h {
        packet.extract(hdr.h);
        transition select(hdr.h.x, hdr.h.y) {
            (true, false): state1;
            (default, false): accept;
        }
    }
    state state1 {
        // Assign a different value to meta.status if we reach here,
        // so we can tell from the output packet whether we reached
        // here or not.
        meta.status = 5;
        transition accept;
    }
}

control ingressImpl(inout headers_t hdr,
                    inout metadata_t meta,
                    inout standard_metadata_t stdmeta)
{
    apply {
        stdmeta.egress_spec = 1;
        if (hdr.ethernet.isValid()) {
            // Use an 'if' statement to encourage p4testgen to create
            // a separate test case for each branch.
            if (meta.status != 0) {
                hdr.ethernet.srcAddr[47:40] = meta.status;
            } else {
                hdr.ethernet.srcAddr[47:40] = 0;
            }
            hdr.ethernet.srcAddr[39:32] = (bit<8>) ((bit<1>) hdr.h.isValid());
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
        packet.emit(hdr.h);
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
