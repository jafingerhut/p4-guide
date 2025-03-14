// Copyright 2019 Andy Fingerhut
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// SPDX-License-Identifier: Apache-2.0

#include <core.p4>
#define V1MODEL_VERSION 20200408
#include <v1model.p4>

enum bit<8> FieldLists {
    resubmit_fl1 = 0,
    resubmit_fl2 = 1,
    resubmit_fl3 = 2,
    resubmit_fl4 = 3
}

struct mymeta_t {
    @field_list(FieldLists.resubmit_fl1, FieldLists.resubmit_fl2, FieldLists.resubmit_fl3, FieldLists.resubmit_fl4) 
    bit<3>   resubmit_reason;
    @field_list(FieldLists.resubmit_fl1) 
    bit<128> f1;
    @field_list(FieldLists.resubmit_fl2) 
    bit<160> f2;
    @field_list(FieldLists.resubmit_fl3) 
    bit<256> f3;
    @field_list(FieldLists.resubmit_fl4) 
    bit<64>  f4;
}

header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

struct metadata {
    @name(".mymeta") 
    mymeta_t mymeta;
}

struct headers {
    @name(".ethernet") 
    ethernet_t ethernet;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".parse_ethernet") state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition accept;
    }
    @name(".start") state start {
        transition parse_ethernet;
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".set_port_to_mac_da_lsbs") action set_port_to_mac_da_lsbs() {
        standard_metadata.egress_spec = (bit<9>)hdr.ethernet.dstAddr & 9w0xf;
    }
    @name(".do_resubmit_reason1") action do_resubmit_reason1() {
        meta.mymeta.resubmit_reason = 3w1;
        meta.mymeta.f1 = meta.mymeta.f1 + 128w17;
        resubmit_preserving_field_list((bit<8>)FieldLists.resubmit_fl1);
    }
    @name(".do_resubmit_reason2") action do_resubmit_reason2(bit<160> f2_val) {
        meta.mymeta.resubmit_reason = 3w2;
        meta.mymeta.f2 = f2_val;
        resubmit_preserving_field_list((bit<8>)FieldLists.resubmit_fl2);
    }
    @name(".nop") action nop() {
    }
    @name(".my_drop") action my_drop() {
        mark_to_drop(standard_metadata);
    }
    @name(".do_resubmit_reason3") action do_resubmit_reason3() {
        meta.mymeta.resubmit_reason = 3w3;
        meta.mymeta.f3 = (bit<256>)hdr.ethernet.srcAddr;
        meta.mymeta.f3 = meta.mymeta.f3 + (bit<256>)hdr.ethernet.dstAddr;
        resubmit_preserving_field_list((bit<8>)FieldLists.resubmit_fl3);
    }
    @name(".do_resubmit_reason4") action do_resubmit_reason4() {
        meta.mymeta.resubmit_reason = 3w4;
        meta.mymeta.f4 = (bit<64>)hdr.ethernet.etherType;
        resubmit_preserving_field_list((bit<8>)FieldLists.resubmit_fl4);
    }
    @name(".update_metadata") action update_metadata(bit<64> x) {
        meta.mymeta.f1 = meta.mymeta.f1 - 128w2;
        meta.mymeta.f2 = 160w8;
        meta.mymeta.f3 = (bit<256>)hdr.ethernet.etherType;
        meta.mymeta.f4 = meta.mymeta.f4 + x;
    }
    @name(".t_first_pass_t1") table t_first_pass_t1 {
        actions = {
            set_port_to_mac_da_lsbs;
            do_resubmit_reason1;
            do_resubmit_reason2;
            @defaultonly nop;
        }
        key = {
            hdr.ethernet.srcAddr: ternary;
        }
        default_action = nop();
    }
    @name(".t_first_pass_t2") table t_first_pass_t2 {
        actions = {
            my_drop;
            do_resubmit_reason3;
            do_resubmit_reason4;
        }
        key = {
            hdr.ethernet.dstAddr: ternary;
        }
        default_action = my_drop();
    }
    @name(".t_first_pass_t3") table t_first_pass_t3 {
        actions = {
            update_metadata;
            @defaultonly nop;
        }
        key = {
            hdr.ethernet.etherType: ternary;
        }
        default_action = nop();
    }
    @name(".t_second_pass_reason1") table t_second_pass_reason1 {
        actions = {
            my_drop;
            nop;
            set_port_to_mac_da_lsbs;
        }
        key = {
            meta.mymeta.f1: exact;
        }
        default_action = nop();
    }
    @name(".t_second_pass_reason2") table t_second_pass_reason2 {
        actions = {
            nop;
            do_resubmit_reason1;
        }
        key = {
            meta.mymeta.f2: ternary;
        }
        default_action = nop();
    }
    @name(".t_second_pass_reason3") table t_second_pass_reason3 {
        actions = {
            my_drop;
            set_port_to_mac_da_lsbs;
            @defaultonly nop;
        }
        key = {
            meta.mymeta.f3        : exact;
            hdr.ethernet.etherType: exact;
        }
        default_action = nop();
    }
    @name(".t_second_pass_reason4") table t_second_pass_reason4 {
        actions = {
            my_drop;
            nop;
            set_port_to_mac_da_lsbs;
        }
        key = {
            meta.mymeta.f4      : ternary;
            hdr.ethernet.srcAddr: exact;
        }
        default_action = nop();
    }
    apply {
        if (meta.mymeta.resubmit_reason == 3w0) {
            t_first_pass_t1.apply();
            t_first_pass_t2.apply();
            t_first_pass_t3.apply();
        } else {
            if (meta.mymeta.resubmit_reason == 3w1) {
                t_second_pass_reason1.apply();
            } else {
                if (meta.mymeta.resubmit_reason == 3w2) {
                    t_second_pass_reason2.apply();
                } else {
                    if (meta.mymeta.resubmit_reason == 3w3) {
                        t_second_pass_reason3.apply();
                    } else {
                        t_second_pass_reason4.apply();
                    }
                }
            }
        }
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
    }
}

control verifyChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

V1Switch(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;

