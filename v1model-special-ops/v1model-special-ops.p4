/* -*- mode: P4_16 -*- */
/*
Copyright 2018 Cisco Systems, Inc.

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

// These definitions are derived from the numerical values of the enum
// named "PktInstanceType" in the p4lang/behavioral-model source file
// targets/simple_switch/simple_switch.h

// https://github.com/p4lang/behavioral-model/blob/master/targets/simple_switch/simple_switch.h#L126-L134

const bit<32> BMV2_V1MODEL_INSTANCE_TYPE_NORMAL        = 0;
const bit<32> BMV2_V1MODEL_INSTANCE_TYPE_INGRESS_CLONE = 1;
const bit<32> BMV2_V1MODEL_INSTANCE_TYPE_EGRESS_CLONE  = 2;
const bit<32> BMV2_V1MODEL_INSTANCE_TYPE_COALESCED     = 3;
const bit<32> BMV2_V1MODEL_INSTANCE_TYPE_RECIRC        = 4;
const bit<32> BMV2_V1MODEL_INSTANCE_TYPE_REPLICATION   = 5;
const bit<32> BMV2_V1MODEL_INSTANCE_TYPE_RESUBMIT      = 6;

#define IS_RESUBMITTED(std_meta) (std_meta.instance_type == BMV2_V1MODEL_INSTANCE_TYPE_RESUBMIT)
#define IS_RECIRCULATED(std_meta) (std_meta.instance_type == BMV2_V1MODEL_INSTANCE_TYPE_RECIRC)


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

struct fwd_meta_t {
    bit<32> l2ptr;
    bit<24> out_bd;
    bit<1>  was_resubmitted;
}

struct meta_t {
    fwd_meta_t fwd;
}

struct headers_t {
    ethernet_t ethernet;
    ipv4_t     ipv4;
}

action my_drop() {
    mark_to_drop();
}

parser ParserImpl(packet_in packet,
                  out headers_t hdr,
                  inout meta_t meta,
                  inout standard_metadata_t standard_metadata)
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

control debug_std_meta(in standard_metadata_t standard_metadata)
{
    table dbg_table {
        key = {
            // This is a complete list of fields inside of the struct
            // standard_metadata_t as of the 2018-Sep-01 version of
            // p4c in the file p4c/p4include/v1model.p4.

            // parser_error is commented out because the p4c back end
            // for bmv2 as of that date gives an error if you include
            // a field of type 'error' in a table key.
            standard_metadata.ingress_port : exact;
            standard_metadata.egress_spec : exact;
            standard_metadata.egress_port : exact;
            standard_metadata.clone_spec : exact;
            standard_metadata.instance_type : exact;
            standard_metadata.drop : exact;
            standard_metadata.recirculate_port : exact;
            standard_metadata.packet_length : exact;
            standard_metadata.enq_timestamp : exact;
            standard_metadata.enq_qdepth : exact;
            standard_metadata.deq_timedelta : exact;
            standard_metadata.deq_qdepth : exact;
            standard_metadata.ingress_global_timestamp : exact;
            standard_metadata.egress_global_timestamp : exact;
            standard_metadata.lf_field_list : exact;
            standard_metadata.mcast_grp : exact;
            standard_metadata.resubmit_flag : exact;
            standard_metadata.egress_rid : exact;
            standard_metadata.checksum_error : exact;
            standard_metadata.recirculate_flag : exact;
            //standard_metadata.parser_error : exact;
        }
        actions = { NoAction; }
        const default_action = NoAction();
    }
    apply {
        dbg_table.apply();
    }
}

control my_debug_1(in headers_t hdr, in meta_t meta)
{
    table dbg_table {
        key = {
            hdr.ipv4.dstAddr : exact;
            meta.fwd.l2ptr : exact;
            meta.fwd.out_bd : exact;
            meta.fwd.was_resubmitted : exact;
        }
        actions = { NoAction; }
        const default_action = NoAction();
    }
    apply {
        dbg_table.apply();
    }
}


control ingress(inout headers_t hdr,
                inout meta_t meta,
                inout standard_metadata_t standard_metadata)
{
    debug_std_meta() debug_std_meta_ingress_start;
    debug_std_meta() debug_std_meta_ingress_end;
    my_debug_1() my_debug_1_1;
    my_debug_1() my_debug_1_2;

    action set_l2ptr(bit<32> l2ptr) {
        meta.fwd.l2ptr = l2ptr;
    }
    action do_resubmit(bit<32> new_ipv4_dstAddr) {
        hdr.ipv4.dstAddr = new_ipv4_dstAddr;
        meta.fwd.was_resubmitted = 1;
        resubmit({meta.fwd.was_resubmitted});
        //resubmit(32w0xcafed00d);
    }
    action do_recirculate(bit<32> new_ipv4_dstAddr) {
        hdr.ipv4.dstAddr = new_ipv4_dstAddr;
        recirculate(32w0xdeadbeef);
    }
    table ipv4_da_lpm {
        key = {
            hdr.ipv4.dstAddr: lpm;
        }
        actions = {
            set_l2ptr;
            do_resubmit;
            do_recirculate;
            my_drop;
        }
        default_action = my_drop;
    }

    action set_bd_dmac_intf(bit<24> bd, bit<48> dmac, bit<9> intf) {
        meta.fwd.out_bd = bd;
        hdr.ethernet.dstAddr = dmac;
        standard_metadata.egress_spec = intf;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }
    table mac_da {
        key = {
            meta.fwd.l2ptr: exact;
        }
        actions = {
            set_bd_dmac_intf;
            my_drop;
        }
        default_action = my_drop;
    }

    apply {
        debug_std_meta_ingress_start.apply(standard_metadata);
        my_debug_1_1.apply(hdr, meta);

        // The actions below aren't necessarily terribly useful in
        // packet processing.  They are simply demonstrations of how
        // you can write a P4_16 program with the open source
        // BMv2/simple_switch v1model architecture, showing how to do
        // something _different_ for a packet that has been
        // resubmitted or recirculated, vs. the first time it is
        // processed.

        // Note that for resubmitted packets, everything else about
        // their contents and metadata _except_ the
        // standard_metadata.instance_type field will be the same
        // about them.

        // For recirculated packets, anything your P4 code did to
        // change the packet during the previous time(s) through
        // ingress and/or egress processing will have taken effect on
        // the packet processed this time.
        if (IS_RESUBMITTED(standard_metadata)) {
            hdr.ipv4.dstAddr = hdr.ipv4.dstAddr - 100;
        } else if (IS_RECIRCULATED(standard_metadata)) {
            hdr.ipv4.dstAddr = hdr.ipv4.dstAddr - 200;
        }
        ipv4_da_lpm.apply();
        if (meta.fwd.l2ptr != 0) {
            mac_da.apply();
        }
        my_debug_1_2.apply(hdr, meta);
        debug_std_meta_ingress_end.apply(standard_metadata);
    }
}

control egress(inout headers_t hdr,
               inout meta_t meta,
               inout standard_metadata_t standard_metadata)
{
    debug_std_meta() debug_std_meta_egress_start;
    debug_std_meta() debug_std_meta_egress_end;

    action rewrite_mac(bit<48> smac) {
        hdr.ethernet.srcAddr = smac;
    }
    table send_frame {
        key = {
            meta.fwd.out_bd: exact;
        }
        actions = {
            rewrite_mac;
            my_drop;
        }
        default_action = my_drop;
    }

    apply {
        debug_std_meta_egress_start.apply(standard_metadata);
        if (standard_metadata.recirculate_flag == 0) {
            send_frame.apply();
        }
        debug_std_meta_egress_end.apply(standard_metadata);
    }
}

control DeparserImpl(packet_out packet, in headers_t hdr) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
    }
}

control verifyChecksum(inout headers_t hdr, inout meta_t meta) {
    apply {
        verify_checksum(hdr.ipv4.isValid() && hdr.ipv4.ihl == 5,
            { hdr.ipv4.version,
                hdr.ipv4.ihl,
                hdr.ipv4.diffserv,
                hdr.ipv4.totalLen,
                hdr.ipv4.identification,
                hdr.ipv4.flags,
                hdr.ipv4.fragOffset,
                hdr.ipv4.ttl,
                hdr.ipv4.protocol,
                hdr.ipv4.srcAddr,
                hdr.ipv4.dstAddr },
            hdr.ipv4.hdrChecksum, HashAlgorithm.csum16);
    }
}

control computeChecksum(inout headers_t hdr, inout meta_t meta) {
    apply {
        update_checksum(hdr.ipv4.isValid() && hdr.ipv4.ihl == 5,
            { hdr.ipv4.version,
                hdr.ipv4.ihl,
                hdr.ipv4.diffserv,
                hdr.ipv4.totalLen,
                hdr.ipv4.identification,
                hdr.ipv4.flags,
                hdr.ipv4.fragOffset,
                hdr.ipv4.ttl,
                hdr.ipv4.protocol,
                hdr.ipv4.srcAddr,
                hdr.ipv4.dstAddr },
            hdr.ipv4.hdrChecksum, HashAlgorithm.csum16);
    }
}

V1Switch(ParserImpl(),
         verifyChecksum(),
         ingress(),
         egress(),
         computeChecksum(),
         DeparserImpl()) main;
