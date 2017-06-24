/* -*- mode: P4_14 -*- */
/*
Copyright 2017 Cisco Systems, Inc.

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

header_type ethernet_t {
    fields {
        dstAddr : 48;
        srcAddr : 48;
        etherType : 16;
    }
}

header_type ipv4_t {
    fields {
        version : 4;
        ihl : 4;
        diffserv : 8;
        totalLen : 16;
        identification : 16;
        flags : 3;
        fragOffset : 13;
        ttl : 8;
        protocol : 8;
        hdrChecksum : 16;
        srcAddr : 32;
        dstAddr: 32;
    }
}

#define NEXTHOP_TYPE_L2PTR     0
#define NEXTHOP_TYPE_ECMP_IDX  1

header_type fwd_metadata_t {
    fields {
        nexthop_type : 1;
        l2ptr     : 32;
        out_bd    : 24;
        ecmp_idx  : 10;
    }
}

header ethernet_t ethernet;
header ipv4_t ipv4;
metadata fwd_metadata_t fwd_metadata;

field_list ipv4_checksum_list {
        ipv4.version;
        ipv4.ihl;
        ipv4.diffserv;
        ipv4.totalLen;
        ipv4.identification;
        ipv4.flags;
        ipv4.fragOffset;
        ipv4.ttl;
        ipv4.protocol;
        ipv4.srcAddr;
        ipv4.dstAddr;
}

field_list_calculation ipv4_checksum {
    input {
        ipv4_checksum_list;
    }
    algorithm : csum16;
    output_width : 16;
}

calculated_field ipv4.hdrChecksum  {
    verify ipv4_checksum if (ipv4.ihl == 5);
    update ipv4_checksum if (ipv4.ihl == 5);
}

parser start {
    return parse_ethernet;
}

#define ETHERTYPE_IPV4 0x0800

parser parse_ethernet {
    extract(ethernet);
    return select(latest.etherType) {
        ETHERTYPE_IPV4 : parse_ipv4;
        default: ingress;
    }
}

parser parse_ipv4 {
    extract(ipv4);
    return ingress;
}

action my_drop() {
    drop();
}

action set_l2ptr(l2ptr) {
    modify_field(fwd_metadata.nexthop_type, NEXTHOP_TYPE_L2PTR);
    modify_field(fwd_metadata.l2ptr, l2ptr);
}

action set_ecmp_idx(ecmp_idx) {
    modify_field(fwd_metadata.nexthop_type, NEXTHOP_TYPE_ECMP_IDX);
    modify_field(fwd_metadata.ecmp_idx, ecmp_idx);
}

counter ipv4_da_lpm_stats {
    type : packets;
    direct : ipv4_da_lpm;
}

table ipv4_da_lpm {
    reads {
        ipv4.dstAddr       : lpm;
    }
    actions {
        set_l2ptr;
        set_ecmp_idx;
        my_drop;
    }
}

field_list ipv4_l3_hash_fields {
    ipv4.srcAddr;
    ipv4.dstAddr;
    ipv4.protocol;
    // Normally would also have L4 ports here, too, but leaving that
    // out of this program to avoid the need to parse TCP/UDP headers.
}

field_list_calculation ecmp_hash {
    input {
        ipv4_l3_hash_fields;
    }
    algorithm : crc16;
    output_width : 10;
}

action_selector ecmp_selector {
    selection_key : ecmp_hash;
    selection_mode : fair;
}

action_profile ecmp_action_profile {
    actions {
        set_l2ptr;
    }
    size : 256;
    dynamic_action_selection : ecmp_selector;
}

table ecmp_group {
    reads {
        fwd_metadata.ecmp_idx : exact;
    }
    action_profile: ecmp_action_profile;
    size : 16384;
}

action set_bd_dmac_intf (bd, dmac, intf) {
    modify_field(fwd_metadata.out_bd, bd);
    modify_field(ethernet.dstAddr, dmac);
    modify_field(standard_metadata.egress_spec, intf);
    add_to_field(ipv4.ttl, -1);
}

table mac_da {
    reads {
        fwd_metadata.l2ptr : exact;
    }
    actions {
        set_bd_dmac_intf;
        my_drop;
    }
}

action rewrite_mac(smac) {
    modify_field(ethernet.srcAddr, smac);
}

table send_frame {
    reads {
        fwd_metadata.out_bd : exact;
    }
    actions {
        rewrite_mac;
        my_drop;
    }
}

control ingress {
    apply(ipv4_da_lpm);
    if (fwd_metadata.nexthop_type == NEXTHOP_TYPE_ECMP_IDX) {
        apply(ecmp_group);
    }
    apply(mac_da);
}

control egress {
    apply(send_frame);
}
