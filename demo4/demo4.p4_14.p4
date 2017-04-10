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
#define NEXTHOP_TYPE_ECMP_GROUP_IDX  1

header_type fwd_metadata_t {
    fields {
        hash1          : 16;
        nexthop_type   : 1;
        ecmp_group_idx : 10;
        ecmp_path_selector : 8;  // 8 bits allows up to 256-way ECMP
        l2ptr          : 32;
        out_bd         : 24;
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

// lkp_ipv4_hash1_fields, lkp_ipv4_hash1, compute_lkp_ipv4_hash,
// compute_ipv4_hashes are copied from a recent version of switch.p4
// from the p4lang/switch Github repository, and then modified only
// slightly.

field_list lkp_ipv4_hash1_fields {
    ipv4.srcAddr;
    ipv4.dstAddr;
    ipv4.protocol;
    // Normally we would also have L4 ports extracted from the packet
    // here, too, but they are left that out of this program to avoid
    // the need to parse TCP/UDP headers.
}

field_list_calculation lkp_ipv4_hash1 {
    input {
        lkp_ipv4_hash1_fields;
    }
    algorithm : crc16;
    output_width : 16;
}

action compute_lkp_ipv4_hash() {
    modify_field_with_hash_based_offset(fwd_metadata.hash1, 0,
                                        lkp_ipv4_hash1, 65536);
}

table compute_ipv4_hashes {
    actions {
        compute_lkp_ipv4_hash;
    }
}

action set_l2ptr(l2ptr) {
    modify_field(fwd_metadata.nexthop_type, NEXTHOP_TYPE_L2PTR);
    modify_field(fwd_metadata.l2ptr, l2ptr);
}

action set_ecmp_group_idx(ecmp_group_idx) {
    modify_field(fwd_metadata.nexthop_type, NEXTHOP_TYPE_ECMP_GROUP_IDX);
    modify_field(fwd_metadata.ecmp_group_idx, ecmp_group_idx);
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
        set_ecmp_group_idx;
        my_drop;
    }
}

field_list l3_hash_fields {
    fwd_metadata.hash1;
}

field_list_calculation ecmp_hash {
    input {
        l3_hash_fields;
    }
    algorithm : identity;
    output_width : 16;
}

action set_ecmp_path_idx(num_paths) {
    // The following statement, combined with the definition of
    // ecmp_hash and l3_hash_fields above, are equivalent to the
    // following C assignment statement:
    //
    // fwd_metadata.ecmp_path_selector = 0 + (fwd_metadata.hash1 % num_paths)
    //
    // TBD: How does the compiler know how many bits are in num_paths?
    // Does it need to be assigned to a metadata field with a defined
    // width, before executing the following line?

    modify_field_with_hash_based_offset(fwd_metadata.ecmp_path_selector,
                                        0, ecmp_hash, num_paths);
}

table ecmp_group {
    reads {
        fwd_metadata.ecmp_group_idx : exact;
    }
    actions {
        set_ecmp_path_idx;
        set_l2ptr;
    }
    size : 32768;
}

table ecmp_path {
    reads {
        fwd_metadata.ecmp_group_idx : exact;
        fwd_metadata.ecmp_path_selector : exact;
    }
    actions {
        set_l2ptr;
    }
    size : 32768;
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
    apply(compute_ipv4_hashes);
    apply(ipv4_da_lpm);
    if (fwd_metadata.nexthop_type != NEXTHOP_TYPE_L2PTR) {
        apply(ecmp_group);
        if (fwd_metadata.nexthop_type != NEXTHOP_TYPE_L2PTR) {
            apply(ecmp_path);
        }
    }
    apply(mac_da);
}

control egress {
    apply(send_frame);
}
