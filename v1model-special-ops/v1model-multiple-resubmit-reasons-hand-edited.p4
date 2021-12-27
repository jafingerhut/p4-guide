#include <core.p4>
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
    mymeta_t mymeta;
}

struct headers {
    ethernet_t ethernet;
}

parser ParserImpl(packet_in packet,
    out headers hdr,
    inout metadata meta,
    inout standard_metadata_t standard_metadata)
{
    state start {
        transition parse_ethernet;
    }
    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition accept;
    }
}

control egress(inout headers hdr,
    inout metadata meta,
    inout standard_metadata_t standard_metadata)
{
    apply {
    }
}

control ingress(inout headers hdr,
    inout metadata meta,
    inout standard_metadata_t standard_metadata)
{
    action set_port_to_mac_da_lsbs() {
        standard_metadata.egress_spec = (bit<9>) hdr.ethernet.dstAddr & 0xf;
    }
    action do_resubmit_reason1() {
        meta.mymeta.resubmit_reason = 1;
        meta.mymeta.f1 = meta.mymeta.f1 + 17;
        resubmit_preserving_field_list((bit<8>)FieldLists.resubmit_fl1);
    }
    action do_resubmit_reason2(bit<160> f2_val) {
        meta.mymeta.resubmit_reason = 2;
        meta.mymeta.f2 = f2_val;
        resubmit_preserving_field_list((bit<8>)FieldLists.resubmit_fl2);
    }
    action nop() {
    }
    action my_drop() {
        mark_to_drop(standard_metadata);
    }
    action do_resubmit_reason3() {
        meta.mymeta.resubmit_reason = 3;
        meta.mymeta.f3 = (bit<256>) hdr.ethernet.srcAddr;
        meta.mymeta.f3 = meta.mymeta.f3 + (bit<256>) hdr.ethernet.dstAddr;
        resubmit_preserving_field_list((bit<8>)FieldLists.resubmit_fl3);
    }
    action do_resubmit_reason4() {
        meta.mymeta.resubmit_reason = 4;
        meta.mymeta.f4 = (bit<64>) hdr.ethernet.etherType;
        resubmit_preserving_field_list((bit<8>)FieldLists.resubmit_fl4);
    }
    action update_metadata(bit<64> x) {
        meta.mymeta.f1 = meta.mymeta.f1 - 2;
        meta.mymeta.f2 = 8;
        meta.mymeta.f3 = (bit<256>) hdr.ethernet.etherType;
        meta.mymeta.f4 = meta.mymeta.f4 + x;
    }
    table t_first_pass_t1 {
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
    table t_first_pass_t2 {
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
    table t_first_pass_t3 {
        actions = {
            update_metadata;
            @defaultonly nop;
        }
        key = {
            hdr.ethernet.etherType: ternary;
        }
        default_action = nop();
    }
    table t_second_pass_reason1 {
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
    table t_second_pass_reason2 {
        actions = {
            nop;
            do_resubmit_reason1;
        }
        key = {
            meta.mymeta.f2: ternary;
        }
        default_action = nop();
    }
    table t_second_pass_reason3 {
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
    table t_second_pass_reason4 {
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
        if (meta.mymeta.resubmit_reason == 0) {
            // This is a new packet, not a resubmitted one
            t_first_pass_t1.apply();
            // Note that even if a resubmit_preserving_field_list()
            // call was performed while executing an action for table
            // t_first_pass_t1, we may do another
            // resubmit_preserving_field_list() call while executing
            // an action for table t_first_pass_t2.  In general, the
            // last resubmit_preserving_field_list() call should have
            // its field list preserved.  Each
            // resubmit_preserving_field_list() call causes any
            // earlier resubmit_preserving_field_list() calls made
            // during the same execution of the ingress control to
            // have their field list overwritten.
            t_first_pass_t2.apply();
            // Also note that any modifications made to field values
            // in a field list given to
            // resubmit_preserving_field_list(), _after_ the
            // resubmit_preserving_field_list call is made, should be
            // preserved in the recirculated packet.  That is, the
            // value of the fields that they have when ingress
            // processing is complete is the value that should be
            // preserved with the resubmitted packet, _not_ the value
            // that the field had when the
            // resubmit_preserving_field_list() call was made.
            t_first_pass_t3.apply();
        }
        else if (meta.mymeta.resubmit_reason == 1) {
            t_second_pass_reason1.apply();
        } else if (meta.mymeta.resubmit_reason == 2) {
            t_second_pass_reason2.apply();
        } else if (meta.mymeta.resubmit_reason == 3) {
            t_second_pass_reason3.apply();
        } else {
            t_second_pass_reason4.apply();
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

V1Switch(ParserImpl(), verifyChecksum(), ingress(),
    egress(), computeChecksum(), DeparserImpl()) main;

