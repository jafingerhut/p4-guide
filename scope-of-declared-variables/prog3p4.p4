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

control ingressImpl(inout headers_t hdr,
                    inout metadata_t meta,
                    inout standard_metadata_t stdmeta)
{
    bit<8> i;                                 // line 1
    apply {
        i = hdr.eth.srcAddr[7:0];             // line 2
        {
            bit<4> j = i[3:0];                // line 3
            bit<8> i = i + 2;                 // line 4
            hdr.eth.dstAddr[15:8] = i;        // line 5
            hdr.eth.dstAddr[19:16] = j;       // line 6
        }
        hdr.eth.dstAddr[7:0] = i;             // line 7
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
