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

typedef bit<16> etype_t;
typedef bit<48>  EthernetAddress;

// https://en.wikipedia.org/wiki/Ethernet_frame
header ethernet_h {
    EthernetAddress dst_addr;
    EthernetAddress src_addr;
    etype_t ether_type;
}

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
    action a() {}
    action a_params(bit<48> param) {
        hdr.ethernet.dst_addr = param;
    }
    table t1 {
        key = {
            hdr.ethernet.src_addr : exact;
        }
        actions = { a; a_params; }
        default_action = a;
    }
    apply {
        t1.apply();
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
