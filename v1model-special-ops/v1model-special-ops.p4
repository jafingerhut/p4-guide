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
#define IS_I2E_CLONE(std_meta) (std_meta.instance_type == BMV2_V1MODEL_INSTANCE_TYPE_INGRESS_CLONE)
#define IS_E2E_CLONE(std_meta) (std_meta.instance_type == BMV2_V1MODEL_INSTANCE_TYPE_EGRESS_CLONE)

const bit<32> I2E_CLONE_SESSION_ID = 5;
const bit<32> E2E_CLONE_SESSION_ID = 11;


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

header switch_to_cpu_header_t {
    bit<32> word0;
    bit<32> word1;
}

struct fwd_meta_t {
    bit<32> l2ptr;
    bit<24> out_bd;
}

struct meta_t {
    fwd_meta_t fwd;
}

struct headers_t {
    switch_to_cpu_header_t switch_to_cpu;
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
        // By giving a list of fields inside the curly braces { } to
        // resubmit, when things go well p4c creates a field list of
        // those field names in the BMv2 JSON file output by the
        // compiler.  All of those field names should have their
        // values preserved from the packet being processed now, to
        // the packet that will be processed by the ingress control
        // block in the future.

        // Note: There is what might be considered a bug in p4c that
        // if you give a metadata field name in the list below, and
        // the compiler can simplify it to a constant value,
        // e.g. because you assign that field a constant value shortly
        // before the resubmit() call, then the BMv2 JSON file will
        // have that constant value in it instead of the field name.
        // I believe in that case that BMv2 simple_switch will _not_
        // have that metadata field value preserved.
        resubmit({standard_metadata.ingress_port,
            standard_metadata.packet_length});
    }
    action do_recirculate(bit<32> new_ipv4_dstAddr) {
        hdr.ipv4.dstAddr = new_ipv4_dstAddr;
        // See the resubmit() call above for comments about the
        // parameter to recirculate(), which has the same form as for
        // resubmit.
        recirculate({standard_metadata.ingress_port});
    }
    action do_clone_i2e(bit<32> new_ipv4_dstAddr) {
        hdr.ipv4.dstAddr = new_ipv4_dstAddr;
        // If you want to pass a list of metadata field to preserve
        // for the cloned packet, similar to the resubmit() and
        // recirculate() calls above, use the operation 'clone3'
        // instead of 'clone', and give the field list as the last
        // argument.

        // BMv2 simple_switch can have multiple different clone
        // "sessions" at the same time.  Each one can be configured to
        // go to an independent output port of the switch.  You can
        // use the 'simple_switch_CLI' command mirroring_add to do
        // that.  A 'mirroring session' and 'clone session' are simply
        // two different names for the same thing.
        clone(CloneType.I2E, I2E_CLONE_SESSION_ID);
    }
    table ipv4_da_lpm {
        key = {
            hdr.ipv4.dstAddr: lpm;
        }
        actions = {
            set_l2ptr;
            do_resubmit;
            do_recirculate;
            do_clone_i2e;
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
        if (IS_I2E_CLONE(standard_metadata)) {
            // whatever you want to do special for ingress-to-egress
            // clone packets here.
            hdr.switch_to_cpu.setValid();
            hdr.switch_to_cpu.word0 = 0xa5a5a5a5;
            hdr.switch_to_cpu.word1 = 0x5a5a5a5a;
        } else if (IS_E2E_CLONE(standard_metadata)) {
            // whatever you want to do special for egress-to-egress
            // clone packets here.
        } else if (standard_metadata.recirculate_flag != 0) {
            // If you want to do something in egress special for
            // packets that during ingress were specified to be
            // recirculated, do that here.
        } else {
            // For all other packets, do this branch.
            send_frame.apply();
        }
        debug_std_meta_egress_end.apply(standard_metadata);
    }
}

control DeparserImpl(packet_out packet, in headers_t hdr) {
    apply {
        packet.emit(hdr.switch_to_cpu);
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
