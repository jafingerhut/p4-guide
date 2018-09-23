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

const bit<32> PKT_INSTANCE_TYPE_RESUBMIT      = 6;

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

struct meta_t {
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
                  inout standard_metadata_t stdmeta)
{
    const bit<16> ETHERTYPE_IPV4 = 0x0800;
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

control debug_tables(in standard_metadata_t stdmeta,
                     in headers_t hdr)
{
    table dbg_table {
        key = {
            // This is a complete list of fields inside of the struct
            // standard_metadata_t as of the 2018-Sep-01 version of
            // p4c in the file p4c/p4include/v1model.p4.

            // parser_error is commented out because the p4c back end
            // for bmv2 as of that date gives an error if you include
            // a field of type 'error' in a table key.
            stdmeta.ingress_port : exact;
            stdmeta.egress_spec : exact;
            stdmeta.egress_port : exact;
            stdmeta.clone_spec : exact;
            stdmeta.instance_type : exact;
            stdmeta.drop : exact;
            stdmeta.recirculate_port : exact;
            stdmeta.packet_length : exact;
            stdmeta.enq_timestamp : exact;
            stdmeta.enq_qdepth : exact;
            stdmeta.deq_timedelta : exact;
            stdmeta.deq_qdepth : exact;
            stdmeta.ingress_global_timestamp : exact;
            stdmeta.egress_global_timestamp : exact;
            stdmeta.lf_field_list : exact;
            stdmeta.mcast_grp : exact;
            stdmeta.resubmit_flag : exact;
            stdmeta.egress_rid : exact;
            stdmeta.checksum_error : exact;
            stdmeta.recirculate_flag : exact;
            //stdmeta.parser_error : exact;
            hdr.ipv4.srcAddr : exact;
            hdr.ipv4.dstAddr : exact;
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
                inout standard_metadata_t stdmeta)
{
    bool resubmit_invoked;
    debug_tables() debug_tables_ingress_start;
    debug_tables() debug_tables_ingress_end;

    apply {
        debug_tables_ingress_start.apply(stdmeta, hdr);
        if (stdmeta.instance_type == PKT_INSTANCE_TYPE_RESUBMIT) {
            // Packets that were resubmitted will not have any changes
            // made to them.  They will go out the output port that is
            // in stdmeta.egress_spec at this point of execution,
            // because it will not be changed below.
            resubmit_invoked = false;
        } else {
            // All packets newly received from a port will be
            // resubmitted.
            stdmeta.egress_spec = 1;
            // At the time of this call to resubmit(),
            // stdmeta.egress_spec is 1.  It will be assigned a value
            // of 5 below, but only after the call to resubmit() has
            // returned.
            resubmit(stdmeta);
            resubmit_invoked = true;
        }
        if (resubmit_invoked) {
            stdmeta.egress_spec = 5;
        }
        debug_tables_ingress_end.apply(stdmeta, hdr);
    }
}

control egress(inout headers_t hdr,
               inout meta_t meta,
               inout standard_metadata_t stdmeta)
{
    debug_tables() debug_tables_egress_start;
    apply {
        debug_tables_egress_start.apply(stdmeta, hdr);
    }
}

control DeparserImpl(packet_out packet, in headers_t hdr) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
    }
}

control verifyChecksum(inout headers_t hdr, inout meta_t meta) {
    apply { }
}

control computeChecksum(inout headers_t hdr, inout meta_t meta) {
    apply { }
}

V1Switch(ParserImpl(),
         verifyChecksum(),
         ingress(),
         egress(),
         computeChecksum(),
         DeparserImpl()) main;
