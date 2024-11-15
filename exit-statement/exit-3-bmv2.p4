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

bit<8> fn1 (in bit<8> x, inout bit<8> y, inout standard_metadata_t stdmeta) {
    if (x < 10) {
        y = y + 127;
        return x;
    } else {
        y = y - 1;
        mark_to_drop(stdmeta);
        return x + 10;
    }
    // exit statement is not allowed in functions
    //if (x[1:1] == 1) {
    //    exit;
    //}
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
    action t1_a3() {
        stdmeta.egress_spec = 2;
    }
    table t1 {
        key = { hdr.ethernet.dst_addr[7:0] : exact; }
        actions = { t1_a1; t1_a2; t1_a3; NoAction; }
        const default_action = NoAction;
    }
    apply {
        stdmeta.egress_spec = 1;
        if (hdr.ethernet.isValid()) {
            // If t1.apply().hit executes `exit` statement, then
            // assignment to hdr.ethernet.src_addr[15:8] should _not_
            // happen, but any side effects from calling `fn1`
            // _should_ happen, as well as any side effects before the
            // `exit` statement is executed in t1's action.
            hdr.ethernet.src_addr[15:8] =
                fn1(hdr.ethernet.dst_addr[15:8], hdr.ethernet.src_addr[23:16],
                    stdmeta) +
                (bit<8>) ((bit<1>) t1.apply().hit);
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
