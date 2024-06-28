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
    bit<8> n = hdr.ethernet.srcAddr[15:8];
    bit<8> i;
    apply {
        {
            // Answers to these questions are for this version of p4c:
            // $ p4c --version
            // p4c 1.2.4.12 (SHA: d5df09b77 BUILD: DEBUG)

            // p4c makes the following `n` the one from before this
            // scope began, which makes sense since it is the only
            // visible definition of `n` at this point.
            bit<8> k = n + 1;

            // Q: Does p4c support the declaration below?

            // A: Yes, with a warning that `n` shadows `n`.

            // Q: If yes, is the right-hand side `n` the one defined
            // earlier above, or the one just being defined now?
            
            // A: It is the earlier one defined above.

            // Q: Does the language spec say anything relevant about
            // this situation?

            // A: I do not know yet.
            
            bit<8> n = n + 5;

            // Trying to also have the following declaration is a
            // compile-time error, because it is a duplicate
            // declaration of `n` in the same scope.
            //bit<8> n = n + 3;

            // Q: Is the following `n` the one from before this block,
            // or from inside this block?

            // A: It is the one from inside this block.
            bit<8> j = n + 3;

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
