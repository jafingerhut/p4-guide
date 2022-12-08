/*
Copyright 2022 Intel Corporation

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
#define V1MODEL_VERSION 20200408
#include <v1model.p4>

#include <stdheaders.p4>

typedef bit<16>  MulticastGroup_t;

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
    apply {
    }
}

control ingressImpl(
    inout headers_t hdr,
    inout metadata_t umd,
    inout standard_metadata_t stdmeta)
{
    action unicast_to_port (PortId_t p) {
        stdmeta.egress_spec = p;
    }
    action mcast_to_group (MulticastGroup_t group_id) {
        stdmeta.mcast_grp = group_id;
    }
    action drop () {
        mark_to_drop(stdmeta);
    }
    table fwd_by_dest_mac {
        key = {
            hdr.ethernet.dst_addr : exact;
        }
        actions = {
            unicast_to_port;
            mcast_to_group;
            drop;
        }
        const default_action = drop;
        size = 1024;
    }
    apply {
        fwd_by_dest_mac.apply();
    }
}

control egressImpl(
    inout headers_t hdr,
    inout metadata_t umd,
    inout standard_metadata_t stdmeta)
{
    apply {
    }
}

control updateChecksum(
    inout headers_t hdr,
    inout metadata_t umd)
{
    apply {
    }
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
