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

struct metadata_t {
}

struct headers_t {
    ethernet_t ethernet;
}

parser parserImpl(packet_in packet,
                  out headers_t hdr,
                  inout metadata_t meta,
                  inout standard_metadata_t stdmeta)
{
    state start {
        packet.extract(hdr.ethernet);
        transition accept;
    }
}

control ingressImpl(inout headers_t hdr,
                    inout metadata_t meta,
                    inout standard_metadata_t stdmeta)
{
    bit<8> n = hdr.ethernet.srcAddr[15:8];  // line [1]
    bit<8> i;
    apply {
        {
            // Statements in comments below are correct for this p4c version:
            // $ p4c --version
            // p4c 1.2.4.12 (SHA: d5df09b77 BUILD: DEBUG)
            bit<8> k = n + 1;  // right-hand side n is def'd at [1]
            // Q: Does the language spec say anything relevant about
            // this situation?
            // A: I do not know yet.
            bit<8> n = n + 5;  // line [2].  Right-hand side n is def'd at [1]
            // Trying to also have the following declaration is a
            // compile-time error, because it is a duplicate
            // declaration of `n` in the same scope.
            //bit<8> n = n + 3;
            bit<8> j = n + 3;  // right-hande side n is def'd at [2]

            hdr.ethernet.srcAddr[23:16] = k;
            hdr.ethernet.srcAddr[15:8] = n;
            hdr.ethernet.srcAddr[7:0] = j;
            stdmeta.egress_spec = 1;
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
