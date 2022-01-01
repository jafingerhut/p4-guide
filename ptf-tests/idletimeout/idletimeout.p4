/*
Copyright 2021 Intel Corporation

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

struct headers_t {
    ethernet_t ethernet;
}

struct metadata_t {
}

parser parserImpl(
    packet_in pkt,
    out headers_t hdr,
    inout metadata_t meta,
    inout standard_metadata_t stdmeta)
{
    state start {
        transition parse_ethernet;
    }
    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition accept;
    }
}

control ingressImpl(
    inout headers_t hdr,
    inout metadata_t meta,
    inout standard_metadata_t stdmeta)
{
    action my_drop() {
        mark_to_drop(stdmeta);
    }

    action set_port(bit<9> port) {
        stdmeta.egress_spec = port;
    }
    table mac_da_fwd {
        key = {
            hdr.ethernet.dstAddr: exact;
        }
        actions = {
            @tableonly set_port;
            my_drop;
            @defaultonly NoAction;
        }
        support_timeout = true;
        default_action = my_drop;
    }

    table redirect_by_ethertype {
        key = {
            hdr.ethernet.etherType: exact;
        }
        actions = {
            @tableonly set_port;
            @defaultonly NoAction;
        }
        const default_action = NoAction;
    }

    apply {
        if (hdr.ethernet.isValid()) {
            mac_da_fwd.apply();
            redirect_by_ethertype.apply();
        }
    }
}

control egressImpl(
    inout headers_t hdr,
    inout metadata_t meta,
    inout standard_metadata_t stdmeta)
{
    apply { }
}

control deparserImpl(
    packet_out pkt,
    in headers_t hdr)
{
    apply {
        pkt.emit(hdr.ethernet);
    }
}

control verifyChecksum(inout headers_t hdr, inout metadata_t meta) { apply { } }

control updateChecksum(inout headers_t hdr, inout metadata_t meta) { apply { } }

V1Switch(
    parserImpl(),
    verifyChecksum(),
    ingressImpl(),
    egressImpl(),
    updateChecksum(),
    deparserImpl()) main;
