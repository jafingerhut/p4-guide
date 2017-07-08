/* -*- mode: P4_16 -*- */
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
 * By 2017 there should be a psa.p4 architecture defined.  PSA stands
 * for Portable Switch Architecture.  The work in progress version of
 * PSA is being done in the p4-spec Github repository at
 * https://github.com/p4lang/p4-spec in the directory p4-16/psa.  The
 * PSA should be very much like the only architecture defined for
 * P4_14, and close to v1model.p4, i.e.
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


/* P4_16 code that is auto-translated from a P4_14 program, as this
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
 * allow primitive actions to be used directly as actions of tables.
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

/* The ingress parser here is pretty simple.  It assumes every packet
 * starts with a 14-byte Ethernet header, and if the ether type is
 * 0x0800, it proceeds to parse the 20-byte mandatory part of an IPv4
 * header, ignoring whether IPv4 options might be present. */

parser ParserImpl(packet_in packet,
                  out headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata)
{
    /* The notation <decimal number>w<something> means that the
     * <something> represents a constant unsigned integer value.  The
     * <decimal number> is the width of that number in bits.  '0x' is
     * taken from C's method of specifying that what follows is
     * hexadecimal.  You can also do decimal (no special prefix),
     * binary (prefix 0b), or octal (0o), but note that octal is _not_
     * specified as it is in C.
     *
     * You can also have <decimal number>s<something> where the 's'
     * indicates the number is a 2's complement signed integer value.
     *
     * For just about every integer constant in your P4 program, it is
     * usually perfectly fine to leave out the '<number>w' width
     * specification, because the compiler infers the width it should
     * be from the context, e.g. for the assignment below, if you
     * leave off the '16w' the compiler infers that 0x0800 should be
     * 16 bits wide because it is being assigned as the value of a
     * bit<16> constant.
     */
    const bit<16> ETHERTYPE_IPV4 = 16w0x0800;

    /* A parser is specified as a finite state machine, with a 'state'
     * definition for each state of the FSM.  There must be a state
     * named 'start', which is the starting state.  'transition'
     * statements indicate what the next state will be.  There are
     * special states 'accept' and 'reject' indicating that parsing is
     * complete, where 'accept' indicates no error during parsing, and
     * 'reject' indicates some kind of parsing error. */
    state start {
        transition parse_ethernet;
    }
    state parse_ethernet {
        /* extract() is the name of a method defined for packets,
         * declared in core.p4 #include'd above.  The parser's
         * execution model starts with a 'pointer' to the beginning of
         * the received packet.  Whenever you call the extract()
         * method, it takes the size of the argument header in bits B,
         * copies the next B bits from the packet into that header
         * (making that header valid), and advances the pointer into
         * the packet by B bits.  I believe some P4 targets may
         * restrict the headers and pointer to be a multiple of 8
         * bits. */
        packet.extract(hdr.ethernet);
        /* The 'select' keyword introduces an expression that is like
         * a C 'switch' statement, except that the expression for each
         * of the cases must be a state name in the parser.  This
         * makes convenient the handling of many possible Ethernet
         * types or IPv4 protocol values. */
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

/* This program is for a P4 target architecture that has an ingress
 * and an egress match-action 'pipeline' (nothing about the P4
 * language requires that the target hardware must have a pipeline in
 * it, but 'pipeline' is the word often used since the current highest
 * performance target devices do have one).
 *
 * The ingress match-action pipeline specified here is very small --
 * simply 2 tables applied in sequence, each with simple actions. */

control ingress(inout headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {

    /* Note that there is no direction 'in', 'out', or 'inout' given
     * for the l2ptr parameter for action set_l2ptr.  Such
     * directionless parameters for actions indicate that the value of
     * l2ptr comes from the control plane.
     *
     * That is, it is the control plane's responsibility to create one
     * or more table entries in the table ipv4_da_lpm.  For each such
     * entry added, the control plane specifies:
     *
     * + a search key.  For table ipv4_da_lpm this is a prefix from 0
     *   to 32 bits long for the hdr.ipv4.dstAddr field.
     *
     * + one of the actions allowed in the P4 program.  In this case,
     *   either set_l2ptr or my_drop (from the 'actions' list
     *   specified in the table below).
     *
     * + a value for every directionless parameter of that action.
     *
     * If the control plane chooses the my_drop action for a table
     * entry, there are no action parameters at all, so the control
     * plane need not specify any.
     *
     * If the control plane chooses the set_l2ptr action for a table
     * entry, it must specify a 32-bit value for the 'l2ptr'
     * parameter.  This value will be stored in the target's
     * ipv4_da_lpm table result for that entry.  Whenever a packet is
     * being processed by the P4 program, and it searches the
     * ip4_da_lpm table and matches an entry with a set_l2ptr action
     * as its result, the value of l2ptr chosen by the control plane
     * will become the value of the l2ptr parameter for the set_l2ptr
     * action as it is executed at packet forwarding time. */
    action set_l2ptr(bit<32> l2ptr) {
        /* Nothing complicated here in the action.  The l2ptr value
         * specified by the control plane and stored in the table
         * entry is copied into a field of the packet's metadata.  It
         * will be used as the search key for the 'mac_da' table
         * below. */
        meta.fwd_metadata.l2ptr = l2ptr;
    }
    table ipv4_da_lpm {
        key = {
            /* lpm means 'Longest Prefix Match'.  It is called a
             * 'match_kind' in P4_16, and the two most common other
             * choices seen in P4 programs are 'exact' and
             * 'ternary'. */
            hdr.ipv4.dstAddr: lpm;
        }
        actions = {
            set_l2ptr;
            my_drop;
        }
        /* If at packet forwarding time, there is no matching entry
         * found in the table, the action specified by the
         * 'default_action' keyword will be performed on the packet.
         *
         * In this case, my_drop is only the default action for this
         * table when the P4 program is first loaded into the device.
         * The control plane can choose to change that default action,
         * via an appropriate API call, to a different action.  If you
         * put 'const' before 'default_action', then it means that
         * this default action cannot be changed by the control
         * plane. */
        default_action = my_drop;
    }

    /* This second table is no more complicated than the first.  The
     * search key in this case is 'exact', so no longest prefix match
     * going on here.  It would probably be implemented in the target
     * as a hash table.
     *
     * If the control plane adds an entry to this table and chooses
     * for that entry the action set_bd_dmac_intf, it must specify
     * values for all 3 of the directionless parameters bd, dmac, and
     * intf. */
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

    /* Every control block must contain an 'apply' block.  The
     * contents of the apply block specify the flow of control between
     * the tables.  This one is particularly simple -- always do the
     * ipv4_da_lpm table, and regardless of the result, always do the
     * mac_da table.  It is definitely possible to have 'if'
     * statements in apply blocks that handle many possible cases
     * differently from each other, based upon the values of packet
     * header fields or metadata fields. */
    apply {
        ipv4_da_lpm.apply();
        mac_da.apply();
    }
}

/* The egress match-action pipeline is even simpler than the one for
 * ingress -- just one table that can overwrite the packet's source
 * MAC address depending on its out_bd metadata field value. */
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

/* The deparser controls what headers are created for the outgoing
   packet. */
control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        /* The emit() method takes a header.  If that header's hidden
         * 'valid' bit is true, then emit() appends the contents of
         * the header (which may have been modified in the ingress or
         * egress pipelines above) into the outgoing packet.
         *
         * If that header's hidden 'valid' bit is false, emit() does
         * nothing. */
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);

        /* This ends the deparser definition.
         *
         * Note that the target device will have recorded for each
         * packet where parsing ended, and it considers every byte of
         * data in the packet after the last parsed header as
         * 'payload'.  For _this_ P4 program, even a TCP header
         * immediately following the IPv4 header is considered part of
         * the payload.  For a different P4 program that parsed the
         * TCP header, the TCP header would not be considered part of
         * the payload.
         * 
         * Whatever is considered as payload for this particular P4
         * program for this packet, that payload is appended after the
         * end of whatever sequence of bytes that the deparser
         * creates. */
    }
}

/* In the v1model.p4 architecture this program is written for, there
 * is a 'slot' for a control block that performs checksums on the
 * already-parsed packet, and can modify metadata fields with the
 * results of those checks, e.g. to set error flags, increment error
 * counts, drop the packet, etc. */
control verifyChecksum(in headers hdr, inout metadata meta) {
    /* The next line is an instantiation of an 'extern' object called
     * Checksum16, declared in the v1model.p4 #include'd above.
     *
     * Why is it an extern, instead of just writing it in P4 code?
     *
     * One reason is that high performance targets implement custom
     * logic for these kinds of things to make them efficient.
     *
     * Another is that sometimes we want checksums over things that
     * are variable length (e.g. IPv4 headers with options), and
     * because P4 does not have loops, it would be very awkward to
     * write such checksum code in P4. */
    Checksum16() ipv4_checksum;
    apply {
        /* The call to the get() method of the 'ipv4_checksum' object
         * below has one parameter.  The curly braces are the P4_16
         * syntax for a 'tuple', which is an ordered collection of
         * other data objects.  A tuple is similar to a struct, except
         * its elements do not have names.
         *
         * In this case, the tuple contains a sequence of header field
         * values that the get() method will concatenate together and
         * calculate an IP 16-bit one's complement checksum for. */
        if ((hdr.ipv4.ihl == 5) &&
            // TBD: bug?  I think this == should be !=
            // Probably the current open source compiler/behavioral
            // model does not actually implement the behavior of this
            // control block yet, and that is why I haven't discovered
            // the bug before now.
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

/* Also in the v1model.p4 architecture, there is a slot for a control
 * block that comes after the egress match-action pipeline, before the
 * deparser, that can be used to calculate checksums for the outgoing
 * packet. */
control computeChecksum(inout headers hdr, inout metadata meta) {
    Checksum16() ipv4_checksum;
    apply {
        if (hdr.ipv4.ihl == 5) {
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
