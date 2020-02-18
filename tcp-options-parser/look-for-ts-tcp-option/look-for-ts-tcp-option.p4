/*
Copyright 2020 Cisco Systems, Inc.

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
The TCP option parsing part of this program has been adapted from
testdata/p4_16_samples/spec-ex19.p4 within the repository
https://github.com/p4lang/p4c by Andy Fingerhut
(andy.fingerhut@gmail.com).  That earlier version also appears in
the P4_16 v1.0.0 specification document.

As of 2017-Nov-09, the P4_16 compiler `p4test` in
https://github.com/p4lang/p4c compiles tcp-options-parser.p4 without
any errors, but `p4c-bm2-ss` gives an error that Tcp_option_h is not a
header type.  This is because as of that date the bmv2 back end code
in `p4c-bm2-ss` code does not yet handle header_union.
*/

#include <core.p4>
#include <v1model.p4>

typedef bit<48>  EthernetAddress;

header ethernet_t {
    EthernetAddress dstAddr;
    EthernetAddress srcAddr;
    bit<16>         etherType;
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

/* The portion of a TCP header that is present in all TCP packets,
 * which is the first 20 bytes, with a fixed format, and no TCP
 * options inside of it.  Any TCP options follow these 20 bytes, and
 * the length of the full TCP header is in the dataOffset field,
 * represented as an integer number of 32-bit words, which includes
 * the 4 32-bit words present in this base header.  Thus dataOffset
 * values less than 5 are an error, and the longest TCP header is when
 * dataOffset=15, or 15*4=60 bytes long, which is this 20-byte fixed
 * header plus 40 bytes of TCP options. */

header tcp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> seqNo;
    bit<32> ackNo;
    bit<4>  dataOffset;
    bit<3>  res;
    bit<3>  ecn;
    bit<6>  ctrl;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgentPtr;
}

const bit<8> TCP_OPTION_END_OF_OPTIONS = 0;  // End of Option List - RFC 793
const bit<8> TCP_OPTION_NOP            = 1;  // No-Operation - RFC 793
const bit<8> TCP_OPTION_MSS            = 2;  // Maximum Segment Size - RFC 793
const bit<8> TCP_OPTION_WINDOW_SCALE   = 3;  // Window Scale - RFC 7323
const bit<8> TCP_OPTION_SACK_PERMITTED = 4;  // SACK Permitted - RFC 2018
const bit<8> TCP_OPTION_SACK           = 5;  // SACK - RFC 2018
const bit<8> TCP_OPTION_TIMESTAMPS     = 8;  // Timestamps - RFC 7323

#include "generated-code/define_tcp_options_headers.p4"

struct headers_t {
    ethernet_t       ethernet;
    ipv4_t           ipv4;
    tcp_t            tcp;
#include "generated-code/tcp_options_headers_inside_headers_t_definition.p4"
}

struct fwd_metadata_t {
}

struct metadata_t {
    fwd_metadata_t fwd_metadata;
}

error {
    TcpDataOffsetTooSmall
}

parser parserImpl(packet_in packet,
                  out headers_t hdr,
                  inout metadata_t meta,
                  inout standard_metadata_t stdmeta)
{
    const bit<16> ETHERTYPE_IPV4 = 0x0800;

    state start {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            ETHERTYPE_IPV4: parse_ipv4;
            default: accept;
        }
    }
    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            6: parse_tcp;
            default: accept;
        }
    }
    state parse_tcp {
        packet.extract(hdr.tcp);
        verify(hdr.tcp.dataOffset >= 5, error.TcpDataOffsetTooSmall);
        transition select(hdr.tcp.dataOffset) {
#include "generated-code/parse_tcp_select_dataOffset_transitions.p4"
        }
    }
#include "generated-code/tcp_options_parser_states.p4"
}

control verifyChecksum(inout headers_t hdr, inout metadata_t meta) {
    apply { }
}

control get_tcp_options_byte(
    in headers_t hdr,
    in bit<8> offset,
    out bit<8> val)
{
#include "generated-code/get_tcp_options_byte.p4"
}

control get_tcp_options_bit32(
    in headers_t hdr,
    in bit<8> offset,
    out bit<32> val)
{
#include "generated-code/get_tcp_options_bit32.p4"
}

control get_option_kind_info(
    in bit<8> option_kind,
    out bool known_option,
    out bool kind_followed_by_length,
    out bool fixed_length,
    out bit<8> expected_fixed_length)
{
    // Note 1: This assignment is not here because it is needed for a
    // correctly functioning program, because the caller should never
    // use the value of this variable, given the values assigned to
    // the other 'out' parameters earlier.  The assignment is here
    // only to avoid a warning about a possibly uninitialized variable
    // from the p4c compiler.
    
    action kind_only() {
        known_option = true;
        kind_followed_by_length = false;
        fixed_length = false;  // See Note 1
        expected_fixed_length = 0;  // See Note 1
    }
    action one_legal_length(
        bit<8> expected_fixed_length_val)
    {
        known_option = true;
        kind_followed_by_length = true;
        fixed_length = true;
        expected_fixed_length = expected_fixed_length_val;
    }
    action variable_length() {
        known_option = true;
        kind_followed_by_length = true;
        fixed_length = false;
        expected_fixed_length = 0;  // See Note 1
    }
    action unknown_option() {
        known_option = false;
        kind_followed_by_length = false;  // See Note 1
        fixed_length = false;  // See Note 1
        expected_fixed_length = 0;  // See Note 1
    }
    table t_get_option_kind_info {
        key = {
            option_kind : exact;
        }
        actions = {
            kind_only;
            one_legal_length;
            variable_length;
            unknown_option;
        }
        const entries = {
            TCP_OPTION_END_OF_OPTIONS: kind_only();
            TCP_OPTION_NOP:            kind_only();
            TCP_OPTION_MSS:            one_legal_length(4);
            TCP_OPTION_WINDOW_SCALE:   one_legal_length(4);
            TCP_OPTION_SACK_PERMITTED: one_legal_length(2);
            TCP_OPTION_SACK:           variable_length();
            TCP_OPTION_TIMESTAMPS:     one_legal_length(10);
        }
        const default_action = unknown_option;
    }
    apply {
        t_get_option_kind_info.apply();
    }
}

control parse_one_tcp_option(
    in headers_t hdr,
    in bit<8> options_length,
    in bit<8> offset,
    out bit<8> next_offset,
    out bool found_ts_option,
    out bool executed_break)
{
    get_tcp_options_byte() get_tcp_options_byte_inst1;
    get_tcp_options_byte() get_tcp_options_byte_inst2;

    bit<8> option_kind;
    bool known_option;
    bool kind_followed_by_length;
    bool fixed_length;
    bit<8> expected_fixed_length;
    bit<8> option_len_bytes;

    apply {
        next_offset = offset;  // See Note 1
        found_ts_option = false;
        get_tcp_options_byte_inst1.apply(hdr, offset, option_kind);
        get_option_kind_info.apply(option_kind, known_option,
                      kind_followed_by_length, fixed_length,
                      expected_fixed_length);
        log_msg("---- offset={} option_kind={} known_option={}",
            {offset, option_kind, (bit<1>) known_option});
        log_msg("     kind_followed_by_length={} fixed_length={} expected_fixed_length={}",
            {(bit<1>) kind_followed_by_length, (bit<1>) fixed_length, expected_fixed_length});
        if (!known_option) {
            executed_break = true;
            return;
        }
        if (kind_followed_by_length) {
            if ((offset + 1) >= options_length) {
                // malformed TCP options - fell off end of TCP options header
                executed_break = true;
                return;
            }
            get_tcp_options_byte_inst2.apply(hdr, offset+1, option_len_bytes);
            if (fixed_length && (option_len_bytes != expected_fixed_length)) {
                // malformed TCP options - incorrect length
                executed_break = true;
                return;
            }
            // This code assumes that if fixed_length is FALSE, the
            // length in the packet is correct.  For the SACK option,
            // it is possible to check that the option length is one
            // of a few legal values.
        } else {
            option_len_bytes = 1;
        }
        if ((offset + option_len_bytes) > options_length) {
            // option is too long to fit in packet's TCP options
            executed_break = true;
            return;
        }
        // This code stops when the first Timestamps option is found.
        if (option_kind == TCP_OPTION_TIMESTAMPS) {
            found_ts_option = true;
            executed_break = true;
            return;
        }
        if (option_kind == TCP_OPTION_END_OF_OPTIONS) {
            // Stop if End of Options option is encountered.
            executed_break = true;
            return;
        }
        next_offset = offset + option_len_bytes;
        executed_break = false;
    }
}

control ingressImpl(inout headers_t hdr,
                    inout metadata_t meta,
                    inout standard_metadata_t stdmeta)
{
#include "generated-code/instantiate_controls.p4"
    get_tcp_options_bit32() get_tcp_options_bit32_inst1;
    get_tcp_options_bit32() get_tcp_options_bit32_inst2;

    bit<8> options_length;
    bit<8> offset;
    bool found_ts_option;
    bool executed_break;
    bit<8> iteration_count;
    bit<32> TSval;
    bit<32> TSecr;

    apply {
        stdmeta.egress_spec = 1;
        if (hdr.tcp.isValid()) {
            offset = 0;
            options_length = (((bit<8>) hdr.tcp.dataOffset) << 2) - 20;

            // Unrolled loop to parse TCP options.  Each iteration
            // assigns a value of true to executed_break if no more
            // iterations should be performed, either because a
            // Timstamps TCP option was found, or for a few other
            // reasons, e.g. End Of Options option was found, the end
            // of the TCP header was reached without finding a
            // Timestamps option, some malformed TCP option was found,
            // etc.

            found_ts_option = false;
            iteration_count = 0;
            executed_break = false;

            if (offset < options_length) {
                // Loop iteration #1
                iteration_count = iteration_count + 1;
                parse_one_tcp_option_inst1.apply(hdr, options_length, offset, offset,
                    found_ts_option, executed_break);
            }
#include "generated-code/tcp_parse_iterations_1_through_n.p4"

            log_msg("found_ts_option={} iteration_count={} executed_break={} offset={}",
                {(bit<1>) found_ts_option, iteration_count,
                    (bit<1>) executed_break, offset});

            if (found_ts_option) {
                get_tcp_options_bit32_inst1.apply(hdr, offset + 2, TSval);
                get_tcp_options_bit32_inst2.apply(hdr, offset + 6, TSecr);
                log_msg("Found Timestamps option with TSval={} TSecr={}",
                    {TSval, TSecr});
            }
        }
    }
}

control egressImpl(inout headers_t hdr,
                   inout metadata_t meta,
                   inout standard_metadata_t stdmeta)
{
    apply {
    }
}

control updateChecksum(inout headers_t hdr, inout metadata_t meta) {
    apply { }
}

control deparserImpl(packet_out packet,
                     in headers_t hdr)
{
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.tcp);
#include "generated-code/emit_tcp_options_headers.p4"
    }
}

V1Switch(parserImpl(),
         verifyChecksum(),
         ingressImpl(),
         egressImpl(),
         updateChecksum(),
         deparserImpl()) main;
