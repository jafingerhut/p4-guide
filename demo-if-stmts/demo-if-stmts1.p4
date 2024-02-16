/* -*- P4_16 -*- */
/*
Copyright 2024 Andy Fingerhut (andy.fingerhut@gmail.com)

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

/*

This program is not intended to be functionally useful, except as a
test program demonstrating where `if` statements are supported by the
behavioral-model back end implementation.

*/

#include <core.p4>
#define V1MODEL_VERSION 20200408
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

struct headers_t {
    ethernet_t ethernet;
    ipv4_t     ipv4;
}

struct metadata_t {
    bit<1>         dmac_is_mcast;
    bit<1>         smac_is_mcast;
    bit<1>         smac_lsb_is_de;
}

parser parserImpl(
    packet_in packet,
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
        if (hdr.ethernet.dstAddr[40:40] == 1) {
            meta.dmac_is_mcast = 1;
        } else {
            meta.dmac_is_mcast = 0;
        }
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

counter<bit<8>>(256, CounterType.packets_and_bytes) mycounter;

bit<8> myfunc1(in bit<8> x) {
    if (x > 127) {
        return x-1;
    }
    return x+1;
}

bit<8> myfunc2(in bit<8> x) {
    // This is not supported by BMv2 when myfunc2 is called from
    // within an action, for the same reasons that if this code were
    // directly inside of an action body, it is not supported by BMv2
    // (see comments for action set_port4).
    if (x > 127) {
        mycounter.count(x);
        return x-1;
    }
    return x+1;
}

control ingressImpl(
    inout headers_t hdr,
    inout metadata_t meta,
    inout standard_metadata_t stdmeta)
{
    action my_drop() {
        mark_to_drop(stdmeta);
    }
    action set_port1(PortId_t p) {
        stdmeta.egress_spec = p;
    }
    action set_port2(PortId_t p) {
        stdmeta.egress_spec = p;
        meta.smac_lsb_is_de = 0;
        // This use of an if statement within an action body is
        // supported by BMv2, because it has only assignment
        // statements in every branch.  Thus the P4 compiler is able
        // to transform it into a sequence of assignment statements of
        // the form:
        //
        // myvar = (boolean_condition) ? (then_expression) : (else_expression)
        if (hdr.ethernet.srcAddr[7:0] == 0xde) {
            meta.smac_lsb_is_de = 1;
        }
        // You can also call a function that has similar kinds of
        // restricted if statements within it.
        hdr.ethernet.dstAddr[15:8] = myfunc1(hdr.ethernet.dstAddr[15:8]);
    }
    action set_port3(PortId_t p, bit<8> count_idx) {
        stdmeta.egress_spec = p;
        // No if statement here.  BMv2 supports unconditional extern
        // method calls like this just fine (if it supports the extern
        // method call at all).
        mycounter.count(count_idx);
    }
//#define BMV2_SUPPORTS_NON_ASSIGNMENT_STATEMENTS_INSIDE_IF_STATEMENTS_IN_ACTIONS
#ifdef BMV2_SUPPORTS_NON_ASSIGNMENT_STATEMENTS_INSIDE_IF_STATEMENTS_IN_ACTIONS
    action set_port4(PortId_t p, bit<8> count_idx) {
        stdmeta.egress_spec = p;
        // This use of an if statement within an action body is _not_
        // supported by BMv2, because it calls an extern function in
        // at least one branch.  The P4 compiler does not support
        // attempting to transform this into a sequence of assignment
        // statements with conditional expressions on the right-hand
        // side.  In this case I believe it is not even possible to do
        // so, because method count's return value is void.
        if (hdr.ethernet.srcAddr[15:8] == 0xde) {
            mycounter.count(count_idx);
        }
    }
    action set_port5(PortId_t p) {
        stdmeta.egress_spec = p;
        hdr.ethernet.dstAddr[15:8] = myfunc2(hdr.ethernet.dstAddr[15:8]);
    }
#endif
    table ipv4_da {
        key = {
            hdr.ipv4.dstAddr: exact;
        }
        actions = {
            set_port1;
            set_port2;
            set_port3;
#ifdef BMV2_SUPPORTS_NON_ASSIGNMENT_STATEMENTS_INSIDE_IF_STATEMENTS_IN_ACTIONS
            set_port4;
            set_port5;
#endif
            my_drop;
        }
        default_action = my_drop;
    }

    apply {
        if (hdr.ethernet.srcAddr[40:40] == 1) {
            meta.smac_is_mcast = 1;
        } else {
            meta.smac_is_mcast = 0;
        }
        // It is supported by BMv2 to call myfunc2 within a control
        // apply body, for the same reason that general if statements
        // are supported here.
        hdr.ethernet.dstAddr[23:16] = myfunc2(hdr.ethernet.dstAddr[23:16]);
        if (hdr.ipv4.isValid()) {
            ipv4_da.apply();
        }
    }
}

control egressImpl(
    inout headers_t hdr,
    inout metadata_t meta,
    inout standard_metadata_t stdmeta)
{
    apply {
        if (hdr.ethernet.isValid()) {
            hdr.ethernet.dstAddr[7:0] = 0;
            hdr.ethernet.dstAddr[7:7] = meta.smac_is_mcast;
            hdr.ethernet.dstAddr[6:6] = meta.dmac_is_mcast;
            hdr.ethernet.dstAddr[5:5] = meta.smac_lsb_is_de;
        }
    }
}

control deparserImpl(
    packet_out packet,
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
