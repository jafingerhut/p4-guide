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


/*
 * standard #include in just about every P4 program.  You can see its
 * (short) contents here:
 *
 * https://github.com/p4lang/p4c/blob/master/p4include/core.p4
 */
#include <core.p4>


/* v1model.p4 defines the P4_16 'architecture', i.e. is there an
 * ingress and an egress pipeline, or just one?  Where is parsing
 * done, and how many parsers does the target device have?  etc.
 *
 * You can see its contents here:
 * https://github.com/p4lang/p4c/blob/master/p4include/v1model.p4
 *
 * By mid-2017 there should be a psa.p4 architecture defined.  PSA
 * stands for Portable Switch Architecture.  It should be very much
 * like the only architecture defined for P4_14, and close to
 * v1model.p4, i.e.
 *
 * ingress consists of these things, programmed in P4:
 * + parser
 * + ingress match-action pipeline
 *
 * Then there is a packet replication engine and packet buffer, which
 * are not P4-programmable.
 *
 * egress consists of these things, programmed in P4:
 * + egress match-action pipeline
 * + deparser (also called rewrite in some networking chips)
 */

#include <v1model.p4>


/* bit<48> is just an unsigned integer that is exactly 48 bits wide.
 * P4_16 also has int<N> for 2's complement signed integers, and
 * varbit<N> for variable length header fields with a maximum size of
 * N bits. */

/* header types are required for all headers you want to parse in
 * received packets, or transmit in packets sent. */

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

/* metadata is the term used for information about a packet, but that
 * might not be inside of the packet contents itself, e.g. a bridge
 * domain (BD) or VRF (Virtual Routing and Forwarding) id.  They can
 * also contain copies of packet header fields if you wish, which can
 * be useful if they can be filled in from one of several possible
 * places in a packet, e.g. an outer IPv4 destination address for
 * non-IP-tunnel packets, or an inner IPv4 destination address for IP
 * tunnel packets.
 *
 * You can define as many or as few structs for metadata as you wish.
 * Some people like to have more than one struct so that metadata for
 * a forwarding feature can be grouped together, but separated from
 * unrelated metadata. */

struct fwd_metadata_t {
    bit<32> l2ptr;
    bit<24> out_bd;
}


/* P4_16 code that is auto-tranlated from a P4_14 program, as this
 * program began, often collects together all headers into one big
 * struct, and all metadata we care about for a packet into another
 * big struct.  This enables passing fewer arguments when control
 * blocks call each other. */

struct metadata {
    fwd_metadata_t fwd_metadata;
}

struct headers {
    ethernet_t ethernet;
    ipv4_t     ipv4;
}


/* Why bother creating an action that just does one primitive action?
 * That is, why not just use 'mark_to_drop' as one of the possible
 * actions when defining a table?  Because the P4_16 compiler does not
 * allow primitve actions to be used directly as actions of tables.
 * You must use 'compound actions', i.e. ones explicitly defined with
 * the 'action' keyword like below.
 *
 * mark_to_drop() is an extern defined in v1model.h, I believe
 * implemented in the behavioral model by setting an appropriate
 * 'intrinsic metadata' field with a code indicating the packet should
 * be dropped. */

action my_drop() {
    mark_to_drop();
}

parser ParserImpl(packet_in packet,
                  out headers hdr,
                  inout metadata meta,
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

control ingress(inout headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {

    action set_l2ptr(bit<32> l2ptr) {
        meta.fwd_metadata.l2ptr = l2ptr;
    }
    table ipv4_da_lpm {
        key = {
            hdr.ipv4.dstAddr: lpm;
        }
        actions = {
            set_l2ptr;
            my_drop;
        }
        default_action = my_drop;
    }

    action set_bd_dmac_intf(bit<24> bd, bit<48> dmac, bit<9> intf) {
        meta.fwd_metadata.out_bd = bd;
        hdr.ethernet.dstAddr = dmac;
        standard_metadata.egress_spec = intf;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }
    table mac_da {
        key = {
            meta.fwd_metadata.l2ptr: exact;
        }
        actions = {
            set_bd_dmac_intf;
            my_drop;
        }
        default_action = my_drop;
    }

    apply {
        ipv4_da_lpm.apply();
        mac_da.apply();
    }
}

control egress(inout headers hdr,
               inout metadata meta,
               inout standard_metadata_t standard_metadata)
{
    action rewrite_mac(bit<48> smac) {
        hdr.ethernet.srcAddr = smac;
    }
    table send_frame {
        key = {
            meta.fwd_metadata.out_bd: exact;
        }
        actions = {
            rewrite_mac;
            my_drop;
        }
        default_action = my_drop;
    }

    apply {
        send_frame.apply();
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
    }
}

control verifyChecksum(in headers hdr, inout metadata meta) {
    Checksum16() ipv4_checksum;
    apply {
        if ((hdr.ipv4.ihl == 4w5) &&
            (hdr.ipv4.hdrChecksum ==
             ipv4_checksum.get({ hdr.ipv4.version,
                         hdr.ipv4.ihl,
                         hdr.ipv4.diffserv,
                         hdr.ipv4.totalLen,
                         hdr.ipv4.identification,
                         hdr.ipv4.flags,
                         hdr.ipv4.fragOffset,
                         hdr.ipv4.ttl,
                         hdr.ipv4.protocol,
                         hdr.ipv4.srcAddr,
                         hdr.ipv4.dstAddr })))
        {
            mark_to_drop();
        }
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    Checksum16() ipv4_checksum;
    apply {
        if (hdr.ipv4.ihl == 4w5) {
            hdr.ipv4.hdrChecksum =
                ipv4_checksum.get({ hdr.ipv4.version,
                            hdr.ipv4.ihl,
                            hdr.ipv4.diffserv,
                            hdr.ipv4.totalLen,
                            hdr.ipv4.identification,
                            hdr.ipv4.flags,
                            hdr.ipv4.fragOffset,
                            hdr.ipv4.ttl,
                            hdr.ipv4.protocol,
                            hdr.ipv4.srcAddr,
                            hdr.ipv4.dstAddr });
        }
    }
}


/* This is a "package instantiation".  There must be at least one
 * named "main" in any complete P4_16 program.  It is what specifies
 * which pieces to plug into which slot in the target architecture. */

V1Switch(ParserImpl(),
         verifyChecksum(),
         ingress(),
         egress(),
         computeChecksum(),
         DeparserImpl()) main;
