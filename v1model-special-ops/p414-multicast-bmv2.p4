/*
Copyright 2019 Cisco Systems, Inc. 

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

header_type intrinsic_metadata_t {
    fields {
        ingress_global_timestamp : 48;
        egress_global_timestamp : 48;
        lf_field_list : 8;
        mcast_grp : 16;
        egress_rid : 16;
        resubmit_flag : 8;
        recirculate_flag : 8;
    }
}

header_type temporaries_t {
    fields {
        temp1 : 48;
    }
}

header ethernet_t ethernet;
metadata intrinsic_metadata_t intrinsic_metadata;
metadata temporaries_t temporaries;

parser start {
    return parse_ethernet;
}

parser parse_ethernet {
    extract(ethernet);
    return ingress;
}

action _drop() {
    drop();
}

action _nop() {
}

#define ENABLE_DEBUG_TABLE
#ifdef ENABLE_DEBUG_TABLE

        //standard_metadata.egress_instance: exact;
        //standard_metadata.parser_status: exact;
        //standard_metadata.parser_error: exact;
        //standard_metadata.clone_spec: exact;

#define DEBUG_FIELD_LIST \
        standard_metadata.ingress_port: exact; \
        standard_metadata.packet_length: exact; \
        standard_metadata.egress_spec: exact; \
        standard_metadata.egress_port: exact; \
        standard_metadata.instance_type: exact; \
        intrinsic_metadata.ingress_global_timestamp: exact; \
        intrinsic_metadata.egress_global_timestamp: exact; \
        intrinsic_metadata.lf_field_list: exact; \
        intrinsic_metadata.mcast_grp: exact; \
        intrinsic_metadata.egress_rid: exact; \
        intrinsic_metadata.resubmit_flag: exact; \
        intrinsic_metadata.recirculate_flag: exact; \
        ethernet.dstAddr: exact; \
        ethernet.srcAddr: exact; \
        ethernet.etherType: exact;

table t_ing_debug_table1 {
    reads { DEBUG_FIELD_LIST }
    actions { _nop; }
    default_action: _nop;
}

table t_ing_debug_table2 {
    reads { DEBUG_FIELD_LIST }
    actions { _nop; }
    default_action: _nop;
}

table t_egr_debug_table1 {
    reads { DEBUG_FIELD_LIST }
    actions { _nop; }
    default_action: _nop;
}

table t_egr_debug_table2 {
    reads { DEBUG_FIELD_LIST }
    actions { _nop; }
    default_action: _nop;
}
#endif  // ENABLE_DEBUG_TABLE

action set_mcast_grp_and_egress_spec() {
    bit_and(intrinsic_metadata.mcast_grp, ethernet.dstAddr, 0xf);
    shift_right(temporaries.temp1, ethernet.dstAddr, 8);
    bit_and(standard_metadata.egress_spec, temporaries.temp1, 0xf);
}

table t_ing_mac_da {
    reads { }
    actions { set_mcast_grp_and_egress_spec; }
    default_action: set_mcast_grp_and_egress_spec;
}

control ingress {
#ifdef ENABLE_DEBUG_TABLE
    apply(t_ing_debug_table1);
#endif  // ENABLE_DEBUG_TABLE
    apply(t_ing_mac_da);
#ifdef ENABLE_DEBUG_TABLE
    apply(t_ing_debug_table2);
#endif  // ENABLE_DEBUG_TABLE
}

action put_debug_vals_in_eth_dstaddr () {
    // By copying values of selected metadata fields into the output
    // packet, we enable an automated STF test that checks the output
    // packet contents, to also check that the values of these
    // intermediate metadata field values are also correct.
    modify_field(ethernet.dstAddr, 0);

    bit_and(temporaries.temp1, intrinsic_metadata.mcast_grp, 0xffff);
    shift_left(temporaries.temp1, temporaries.temp1, 32);
    bit_or(ethernet.dstAddr, ethernet.dstAddr, temporaries.temp1);

    bit_and(temporaries.temp1, standard_metadata.instance_type, 0xff);
    shift_left(temporaries.temp1, temporaries.temp1, 24);
    bit_or(ethernet.dstAddr, ethernet.dstAddr, temporaries.temp1);

    bit_and(temporaries.temp1, intrinsic_metadata.egress_rid, 0xffff);
    bit_or(ethernet.dstAddr, ethernet.dstAddr, temporaries.temp1);
}

action mark_packet () {
    put_debug_vals_in_eth_dstaddr();
}

table t_mark_packet {
    reads { }
    actions { mark_packet; }
    default_action: mark_packet;
}

control egress {
#ifdef ENABLE_DEBUG_TABLE
    apply(t_egr_debug_table1);
#endif  // ENABLE_DEBUG_TABLE
    apply(t_mark_packet);
#ifdef ENABLE_DEBUG_TABLE
    apply(t_egr_debug_table2);
#endif  // ENABLE_DEBUG_TABLE
}
