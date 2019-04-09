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


// This is just a toy demonstration program, but imagine that you have
// 4 different reasons why the first ingress pass is not enough to
// finish ingress processing for a newly received packet from a switch
// port.

// To continue processing the packet after resubmitting, each has a
// minimum requirement for a different subset of metadata calculated
// during the previous pass to be preserved.

// Each of these subsets of metadata is large enough that we want to
// make the resubmit operations more efficient, by only preserving the
// minimum necessary.

// For example, the minimum data necessary to be preserved for any one
// packet might be "only" 16 bytes, but the union of all of those
// might be 64 bytes, which would be doubling the size of a
// minimum-sized Ethernet frame.  There are platforms where this much
// extra data associated with a resubmitted, recirculated, cloned, or
// even normal-ingress-to-egress unicast packet would noticeably
// reduce performance in terms of packet rate.


header_type ethernet_t {
    fields {
        dstAddr : 48;
        srcAddr : 48;
        etherType : 16;
    }
}

header ethernet_t ethernet;

header_type mymeta_t {
    fields {
        resubmit_reason : 3;
        f1 : 128;
        f2 : 160;
        f3 : 256;
        f4 : 64;
    }
}

metadata mymeta_t mymeta;

field_list resubmit_fl1 {
    mymeta.resubmit_reason;
    mymeta.f1;
}

field_list resubmit_fl2 {
    mymeta.resubmit_reason;
    mymeta.f2;
}

field_list resubmit_fl3 {
    mymeta.resubmit_reason;
    mymeta.f3;
}

field_list resubmit_fl4 {
    mymeta.resubmit_reason;
    mymeta.f4;
}

parser start {
    return parse_ethernet;
}

parser parse_ethernet {
    extract(ethernet);
    return ingress;
}

action do_resubmit_reason1() {
    modify_field(mymeta.resubmit_reason, 1);
    add_to_field(mymeta.f1, 17);
    resubmit(resubmit_fl1);
}

action do_resubmit_reason2(f2_val) {
    modify_field(mymeta.resubmit_reason, 2);
    modify_field(mymeta.f2, f2_val);
    resubmit(resubmit_fl2);
}

action do_resubmit_reason3() {
    modify_field(mymeta.resubmit_reason, 3);
    modify_field(mymeta.f3, ethernet.srcAddr);
    add_to_field(mymeta.f3, ethernet.dstAddr);
    resubmit(resubmit_fl3);
}

action do_resubmit_reason4() {
    modify_field(mymeta.resubmit_reason, 4);
    modify_field(mymeta.f4, ethernet.etherType);
    resubmit(resubmit_fl4);
}

action set_port_to_mac_da_lsbs() {
    bit_and(standard_metadata.egress_spec, ethernet.dstAddr, 0xf);
}

action my_drop() {
    drop();
}

action nop() {
}

table t_first_pass_t1 {
    reads {
        ethernet.srcAddr : ternary;
    }
    actions {
        set_port_to_mac_da_lsbs;
        do_resubmit_reason1;
        do_resubmit_reason2;
    }
    default_action: nop;
}

table t_first_pass_t2 {
    reads {
        ethernet.dstAddr : ternary;
    }
    actions {
        my_drop;
        do_resubmit_reason3;
        do_resubmit_reason4;
    }
    default_action: my_drop;
}

action update_metadata (x) {
    subtract_from_field(mymeta.f1, 2);
    modify_field(mymeta.f2, 8);
    modify_field(mymeta.f3, ethernet.etherType);
    add_to_field(mymeta.f4, x);
}

table t_first_pass_t3 {
    reads {
        ethernet.etherType : ternary;
    }
    actions {
        update_metadata;
    }
    default_action: nop;
}

table t_second_pass_reason1 {
    reads {
        mymeta.f1 : exact;
    }
    actions {
        my_drop;
        nop;
        set_port_to_mac_da_lsbs;
    }
    default_action: nop;
}

table t_second_pass_reason2 {
    reads {
        mymeta.f2 : ternary;
    }
    actions {
        nop;
        do_resubmit_reason1;
    }
    default_action: nop;
}

table t_second_pass_reason3 {
    reads {
        mymeta.f3 : exact;
        ethernet.etherType : exact;
    }
    actions {
        my_drop;
        set_port_to_mac_da_lsbs;
    }
    default_action: nop;
}

table t_second_pass_reason4 {
    reads {
        mymeta.f4 : ternary;
        ethernet.srcAddr : exact;
    }
    actions {
        my_drop;
        nop;
        set_port_to_mac_da_lsbs;
    }
    default_action: nop;
}

control ingress {
    if (mymeta.resubmit_reason == 0) {
        // This is a new packet, not a resubmitted one
        apply(t_first_pass_t1);
        // Note that even if a resubmit() call was performed while
        // executing an action for table t_first_pass_t1, we may do
        // another resubmit() call while executing an action for table
        // t_first_pass_t2.  In general, the last resubmit() call
        // should have its field list preserved.  Each resubmit() call
        // causes any earlier resubmit() calls made during the same
        // call to the ingress control to be "forgotten".
        apply(t_first_pass_t2);
        // Also note that any modifications made to field values in a
        // field_list given to resubmit(), _after_ the resubmit call
        // is made, should be preserved in the recirculated packet.
        // That is, the value of the fields that they have when
        // ingress processing is complete is the value that should be
        // preserved with the resubmitted packet, _not_ the value that
        // the field had when the resubmit() call was made.

        // recirculate and clone operations are similar in this
        // regard, in P4_14.
        apply(t_first_pass_t3);
    } else if (mymeta.resubmit_reason == 1) {
        apply(t_second_pass_reason1);
    } else if (mymeta.resubmit_reason == 2) {
        apply(t_second_pass_reason2);
    } else if (mymeta.resubmit_reason == 3) {
        apply(t_second_pass_reason3);
    } else {
        apply(t_second_pass_reason4);
    }
}

control egress {
}
