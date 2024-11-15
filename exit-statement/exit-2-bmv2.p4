/*
Copyright 2024 Cisco Systems, Inc.

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

#include "stdlib/stdheaders.p4"

struct headers_t {
    ethernet_h    ethernet;
}

struct metadata_t {
}

parser ingressParserImpl(
    packet_in pkt,
    out headers_t hdr,
    inout metadata_t umd,
    inout standard_metadata_t stdmeta)
{
    state start {
        pkt.extract(hdr.ethernet);
        transition accept;
    }
}

control verifyChecksum(
    inout headers_t hdr,
    inout metadata_t umd)
{
    apply { }
}

control ingressImpl(
    inout headers_t hdr,
    inout metadata_t umd,
    inout standard_metadata_t stdmeta)
{
    bit<8> ret1 = 0;
    action my_drop() {
        mark_to_drop(stdmeta);
    }
    action t1_a1() {
        hdr.ethernet.src_addr[7:0] = 1;
    }
    action t1_a2() {
        hdr.ethernet.src_addr[7:0] = 2;
        exit;
    }
    table t1 {
        key = { hdr.ethernet.dst_addr[7:0] : exact; }
        actions = { t1_a1; t1_a2; NoAction; }
        const default_action = NoAction;
    }
    action t2_a1() {
        hdr.ethernet.src_addr[7:0] = 3;
    }
    action t2_a2() {
        hdr.ethernet.src_addr[7:0] = 4;
        exit;
    }
    table t2 {
        key = { hdr.ethernet.dst_addr[15:8] : exact; }
        actions = { t2_a1; t2_a2; NoAction; }
        const default_action = NoAction;
    }
    action t3_a1() {
        hdr.ethernet.src_addr[7:0] = 5;
    }
    action t3_a2() {
        hdr.ethernet.src_addr[7:0] = 6;
        exit;
    }
    table t3 {
        key = { hdr.ethernet.dst_addr[23:16] : exact; }
        actions = { t3_a1; t3_a2; NoAction; }
        const default_action = NoAction;
    }
    apply {
        if (hdr.ethernet.isValid()) {
            switch (
                ((bit<2>) ((bit<1>) t1.apply().hit)) +
                ((bit<2>) ((bit<1>) t2.apply().hit)) +
                ((bit<2>) ((bit<1>) t3.apply().hit))) {
                0: { hdr.ethernet.src_addr[15:8] = 1; }
                1: { hdr.ethernet.src_addr[15:8] = 2; }
                2: { hdr.ethernet.src_addr[15:8] = 3; }
                3: { hdr.ethernet.src_addr[15:8] = 4; }
            }
        }
    }
}

control egressImpl(
    inout headers_t hdr,
    inout metadata_t umd,
    inout standard_metadata_t stdmeta)
{
    apply { }
}

control updateChecksum(
    inout headers_t hdr,
    inout metadata_t umd)
{
    apply { }
}

control egressDeparserImpl(
    packet_out pkt,
    in headers_t hdr)
{
    apply {
        pkt.emit(hdr.ethernet);
    }
}

V1Switch(ingressParserImpl(),
         verifyChecksum(),
         ingressImpl(),
         egressImpl(),
         updateChecksum(),
         egressDeparserImpl()) main;
