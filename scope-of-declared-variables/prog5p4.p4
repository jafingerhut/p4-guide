/*
Copyright 2026 Andy Fingerhut

SPDX-License-Identifier: Apache-2.0
*/

#include <core.p4>
#include <v1model.p4>

header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

struct headers_t {
    ethernet_t eth;
}

struct metadata_t {
}

control foo (
    inout bit<8> i,
    out bit<8> o1,
    out bit<8> o2,
    out bit<8> o3)
{
    bit<8> i = i + 1;            // line 1
    apply {
        o1 = i;                  // line 2
        {
            bit<8> i = i + 1;    // line 3
            o2 = i;              // line 4
        }
        o3 = i;                  // line 5
    }
}

control ingressImpl(inout headers_t hdr,
                    inout metadata_t meta,
                    inout standard_metadata_t stdmeta)
{
    bit<8> i;
    bit<8> o1;
    bit<8> o2;
    bit<8> o3;
    apply {
        i = hdr.eth.srcAddr[7:0];
        foo.apply(i, o1, o2, o3);
        log_msg("i={} o1={} o2={} o3={}",
            {i, o1, o2, o3});
    }
}

parser parserImpl(packet_in packet,
                  out headers_t hdr,
                  inout metadata_t meta,
                  inout standard_metadata_t stdmeta)
{
    state start {
        packet.extract(hdr.eth);
        transition accept;
    }
}

control egressImpl(inout headers_t hdr,
                   inout metadata_t meta,
                   inout standard_metadata_t stdmeta)
{ apply { } }

control deparserImpl(packet_out packet, in headers_t hdr)
{ apply { } }

control verifyChecksum(inout headers_t hdr, inout metadata_t meta)
{ apply { } }

control updateChecksum(inout headers_t hdr, inout metadata_t meta)
{ apply { } }

V1Switch(parserImpl(),
         verifyChecksum(),
         ingressImpl(),
         egressImpl(),
         updateChecksum(),
         deparserImpl()) main;
