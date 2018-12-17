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


/* v1model.p4 defines one P4_16 'architecture', i.e. is there an
 * ingress and an egress pipeline, or just one?  Where is parsing
 * done, and how many parsers does the target device have?  etc.
 *
 * You can see its contents here:
 * https://github.com/p4lang/p4c/blob/master/p4include/v1model.p4
 *
 * The standard P4_16 architecture called PSA (Portable Switch
 * Architecture) version 1.1 was published on November 22, 2018 here:
 *
 * https://p4.org/specs/
 *
 * P4_16 programs written for the PSA architecture should include the
 * file psa.p4 instead of v1model.p4, and several parts of the program
 * after that would use different extern objects and functions than
 * this example program shows.
 *
 * In the v1model.p4 architecture, ingress consists of these things,
 * programmed in P4.  Each P4 program can name these things as they
 * choose.  The name used in this program for that piece is given in
 * parentheses:
 *
 * + a parser (ParserImpl)
 * + a specialized control block intended for verifying checksums
 *   in received headers (verifyChecksum)
 * + ingress match-action pipeline (ingress)
 *
 * Then there is a packet replication engine and packet buffer, which
 * are not P4-programmable.
 *
 * Egress consists of these things, programmed in P4:
 *
 * + egress match-action pipeline (egress)
 * + a specialized control block intended for computing checksums in
 *   transmitted headers (computeChecksum)
 * + deparser (also called rewrite in some networking chips, DeparserImpl)
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

/* "Metadata" is the term used for information about a packet, but
 * that might not be inside of the packet contents itself, e.g. a
 * bridge domain (BD) or VRF (Virtual Routing and Forwarding) id.
 * They can also contain copies of packet header fields if you wish,
 * which can be useful if they can be filled in from one of several
 * possible places in a packet, e.g. an outer IPv4 destination address
 * for non-IP-tunnel packets, or an inner IPv4 destination address for
 * IP tunnel packets.
 *
 * You can define as many or as few structs for metadata as you wish.
 * Some people like to have more than one struct so that metadata for
 * a forwarding feature can be grouped together, but separated from
 * unrelated metadata. */

struct fwd_metadata_t {
    bit<32> l2ptr;
    bit<24> out_bd;
}


/* The v1model.p4 and psa.p4 architectures require you to define one
 * type that contains instances of all headers you care about, which
 * will typically be a struct with one member for each header instance
 * that your parser code might parse.
 *
 * You must also define another type that contains all metadata fields
 * that you use in your program.  It is typically a struct type, and
 * may contain bit vector fields, nested structs, or any other types
 * you want.
 *
 * Instances of these two types are then passed as parameters to the
 * top level controls defined by the architectures.  For example, the
 * ingress parser takes a parameter that contains your header type as
 * an 'out' parameter, returning filled-in headers when parsing is
 * complete, whereas the ingress control block takes that same
 * parameter with direction 'inout', since it is initially filled in
 * by the parser, but the ingress control block is allowed to modify
 * the contents of the headers during packet processing.
 *
 * Note: If you ever want to parse an outer and an inner IPv4 header
 * from a packet, the struct containing headers that you define should
 * contain two members, both with type ipv4_t, perhaps with field
 * names like "outer_ipv4" and "inner_ipv4", but the names are
 * completely up to you.  Similarly the struct type names 'metadata'
 * and 'headers' below can be anything you want to name them. */

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
 * mark_to_drop() is an extern function defined in v1model.h,
 * implemented in the behavioral model by setting an appropriate
 * 'intrinsic metadata' field with a code indicating the packet should
 * be dropped.
 *
 * See the following page if you are interestd in more detailed
 * documentation on the behavior of mark_to_drop and several other
 * operations in the v1model architecture, as implemented in the open
 * source behavioral-model BMv2 software switch:
 * https://github.com/p4lang/behavioral-model/blob/master/docs/simple_switch.md
 */

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
         * the packet by B bits.  Some P4 targets, such as the
         * behavioral model called BMv2 simple_switch, restrict the
         * headers and pointer to be a multiple of 8 bits. */
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
     * contents of the apply block specify the sequential flow of
     * control of packet processing, including applying the tables you
     * wish, in the order you wish.
     *
     * This one is particularly simple -- always apply the ipv4_da_lpm
     * table, and regardless of the result, always apply the mac_da
     * table.  It is definitely possible to have 'if' statements in
     * apply blocks that handle many possible cases differently from
     * each other, based upon the values of packet header fields or
     * metadata fields. */
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
 * packet. */
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
         * Note that for each packet, the target device records where
         * parsing ended, and it considers every byte of data in the
         * packet after the last parsed header as 'payload'.  For
         * _this_ P4 program, even a TCP header immediately following
         * the IPv4 header is considered part of the payload.  For a
         * different P4 program that parsed the TCP header, the TCP
         * header would not be considered part of the payload.
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
control verifyChecksum(inout headers hdr, inout metadata meta) {
    apply {
        /* The verify_checksum() extern function is declared in
         * v1model.p4.  Its behavior is implementated in the target,
         * e.g. the BMv2 software switch.
         *
         * It can takes a single header field by itself as the second
         * parameter, but more commonly you want to use a list of
         * header fields inside curly braces { }.  They are
         * concatenated together and the checksum calculation is
         * performed over all of them.
         *
         * The computed checksum is compared against the received
         * checksum in the field hdr.ipv4.hdrChecksum, given as the
         * 3rd argument.
         *
         * The verify_checksum() primitive can perform multiple kinds
         * of hash or checksum calculations.  The 4th argument
         * specifies that we want 'HashAlgorithm.csum16', which is the
         * Internet checksum.
         *
         * The first argument is a Boolean true/false value.  The
         * entire verify_checksum() call does nothing if that value is
         * false.  In this case it is true only when the parsed packet
         * had an IPv4 header, which is true exactly when
         * hdr.ipv4.isValid() is true, and if that IPv4 header has a
         * header length 'ihl' of 5 32-bit words.
         *
         * In September 2018, the simple_switch process in the
         * p4lang/behavioral-model Github repository was enhanced so
         * that it initializes the value of
         * standard_metadata.checksum_error to 0 for all received
         * packets, and if any call to verify_checksum() with a first
         * parameter of true finds an incorrect checksum value, it
         * assigns 1 to the checksum_error field.  This field can be
         * read in your ingress control block code, e.g. using it in
         * an 'if' condition to choose to drop the packet.  This
         * example program does not demonstrate that.
         */
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

/* Also in the v1model.p4 architecture, there is a slot for a control
 * block that comes after the egress match-action pipeline, before the
 * deparser, that can be used to calculate checksums for the outgoing
 * packet. */
control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
        /* update_checksum() is declared in v1model.p4, and its
         * arguments are similar to verify_checksum() above.  The
         * primary difference is that after calculating the checksum,
         * it modifies the value of the field given as the 3rd
         * parameter to be equal to the newly computed checksum. */
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


/* This is a "package instantiation".  There must be at least one
 * named "main" in any complete P4_16 program.  It is what specifies
 * which pieces to plug into which "slot" in the target
 * architecture. */

V1Switch(ParserImpl(),
         verifyChecksum(),
         ingress(),
         egress(),
         computeChecksum(),
         DeparserImpl()) main;
