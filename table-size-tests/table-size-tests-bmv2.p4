/*
Copyright 2023 Intel Corporation

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

struct fwd_metadata_t {
    bit<32> l2ptr;
    bit<24> out_bd;
}

struct metadata_t {
    fwd_metadata_t fwd_metadata;
}

struct headers_t {
    ethernet_t ethernet;
    ipv4_t     ipv4;
}

parser parserImpl(packet_in packet,
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

control ingressImpl(inout headers_t hdr,
                    inout metadata_t meta,
                    inout standard_metadata_t stdmeta)
{
    action send_to_port(bit<9> p) {
        stdmeta.egress_spec = p;
    }
    action my_drop() {
        mark_to_drop(stdmeta);
    }

    // "Normal" tables, i.e. one or more key fields, no 'const
    // entries' nor 'entries'.
    table t_normal_size_none {
        key = { hdr.ethernet.dstAddr: exact; }
        actions = { my_drop; }
        default_action = my_drop;
    }
    table t_normal_size_0 {
        key = { hdr.ethernet.dstAddr: exact; }
        actions = { my_drop; }
        default_action = my_drop;
        size = 0;
    }
    table t_normal_size_1 {
        key = { hdr.ethernet.dstAddr: exact; }
        actions = { my_drop; }
        default_action = my_drop;
        size = 1;
    }
    table t_normal_size_256 {
        key = { hdr.ethernet.dstAddr: exact; }
        actions = { my_drop; }
        default_action = my_drop;
        size = 256;
    }

    // Tables with 'const entries', regardless of whether they are
    // keyless.
    table t_with_key_const_entries_1_size_none {
        key = { hdr.ethernet.dstAddr: exact; }
        actions = { my_drop; }
        const entries = { 0: my_drop; }
        default_action = my_drop;
    }
    table t_with_key_const_entries_1_size_0 {
        key = { hdr.ethernet.dstAddr: exact; }
        actions = { my_drop; }
        const entries = { 0: my_drop; }
        default_action = my_drop;
        size = 0;
    }
    table t_with_key_const_entries_1_size_1 {
        key = { hdr.ethernet.dstAddr: exact; }
        actions = { my_drop; }
        const entries = { 0: my_drop; }
        default_action = my_drop;
        size = 1;
    }
    table t_with_key_const_entries_1_size_256 {
        key = { hdr.ethernet.dstAddr: exact; }
        actions = { my_drop; }
        const entries = { 0: my_drop; }
        default_action = my_drop;
        size = 256;
    }

#undef ENABLE_TABLES_WITH_EMPTY_ENTRIES_LIST
#ifdef ENABLE_TABLES_WITH_EMPTY_ENTRIES_LIST
    table t_no_key_empty_const_entries_size_none {
        actions = { my_drop; }
        const entries = { }
        default_action = my_drop;
    }
    table t_no_key_empty_const_entries_size_0 {
        actions = { my_drop; }
        const entries = { }
        default_action = my_drop;
        size = 0;
    }
    table t_no_key_empty_const_entries_size_1 {
        actions = { my_drop; }
        const entries = { }
        default_action = my_drop;
        size = 1;
    }
    table t_no_key_empty_const_entries_size_256 {
        actions = { my_drop; }
        const entries = { }
        default_action = my_drop;
        size = 256;
    }
#endif  // ENABLE_TABLES_WITH_EMPTY_ENTRIES_LIST

    // "keyless" tables, i.e. 0 key fields, with no 'const entries'
    // nor 'entries'
    table t_no_key_size_none {
        actions = { my_drop; }
        default_action = my_drop;
    }
    table t_no_key_size_0 {
        actions = { my_drop; }
        default_action = my_drop;
        size = 0;
    }
    table t_no_key_size_1 {
        actions = { my_drop; }
        default_action = my_drop;
        size = 1;
    }
    table t_no_key_size_256 {
        actions = { my_drop; }
        default_action = my_drop;
        size = 256;
    }
    table t_empty_key_size_none {
        key = { }
        actions = { my_drop; }
        default_action = my_drop;
    }
    table t_empty_key_size_0 {
        key = { }
        actions = { my_drop; }
        default_action = my_drop;
        size = 0;
    }
    table t_empty_key_size_1 {
        key = { }
        actions = { my_drop; }
        default_action = my_drop;
        size = 1;
    }
    table t_empty_key_size_256 {
        key = { }
        actions = { my_drop; }
        default_action = my_drop;
        size = 256;
    }

    apply {
        t_normal_size_none.apply();
        t_normal_size_0.apply();
        t_normal_size_1.apply();
        t_normal_size_256.apply();

        t_with_key_const_entries_1_size_none.apply();
        t_with_key_const_entries_1_size_0.apply();
        t_with_key_const_entries_1_size_1.apply();
        t_with_key_const_entries_1_size_256.apply();

#ifdef ENABLE_TABLES_WITH_EMPTY_ENTRIES_LIST
        t_no_key_empty_const_entries_size_none.apply();
        t_no_key_empty_const_entries_size_0.apply();
        t_no_key_empty_const_entries_size_1.apply();
        t_no_key_empty_const_entries_size_256.apply();
#endif  // ENABLE_TABLES_WITH_EMPTY_ENTRIES_LIST

        t_no_key_size_none.apply();
        t_no_key_size_0.apply();
        t_no_key_size_1.apply();
        t_no_key_size_256.apply();

        t_empty_key_size_none.apply();
        t_empty_key_size_0.apply();
        t_empty_key_size_1.apply();
        t_empty_key_size_256.apply();
    }
}

control egressImpl(inout headers_t hdr,
                   inout metadata_t meta,
                   inout standard_metadata_t stdmeta)
{
    apply { }
}

control deparserImpl(packet_out packet,
                     in headers_t hdr)
{
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
    }
}

control verifyChecksum(inout headers_t hdr, inout metadata_t meta) {
    apply { }
}

control updateChecksum(inout headers_t hdr, inout metadata_t meta) {
    apply { }
}

V1Switch(parserImpl(),
         verifyChecksum(),
         ingressImpl(),
         egressImpl(),
         updateChecksum(),
         deparserImpl()) main;
