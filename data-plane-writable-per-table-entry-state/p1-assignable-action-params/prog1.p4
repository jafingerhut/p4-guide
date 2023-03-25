/*
Copyright 2023 Intel Corporation

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
#include "../pna.p4"

extern DirectRegister<T> {
  DirectRegister();
  T read();
  void write(in T value);
}

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

struct empty_metadata_t {
}

typedef bit<48> ByteCounter_t;
typedef bit<32> PacketCounter_t;
typedef bit<80> PacketByteCounter_t;

const bit<32> NUM_PORTS = 4;


struct main_metadata_t {
}

struct headers_t {
    ethernet_t ethernet;
    ipv4_t ipv4;
}

parser MainParserImpl(
    packet_in pkt,
    out   headers_t       hdr,
    inout main_metadata_t main_meta,
    in    pna_main_parser_input_metadata_t istd)
{
    state start {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            0x0800: parse_ipv4;
            default: accept;
        }
    }
    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition accept;
    }
}


control MainControlImpl(
    inout headers_t       hdr,
    inout main_metadata_t user_meta,
    in    pna_main_input_metadata_t  istd,
    inout pna_main_output_metadata_t ostd)
{
    bit<8> control_global;
    
    // Because a1 assigns to r1 and r2 in its body, their assigned
    // values are recorded in the table entry for future packets to
    // access.  Because p1 is only read, a1 never modifies it and only
    // the control plane can change its value.
    action a1(bit<8> p1, bit<8> r1, bit<16> r2) {
        bit<8> v1;
        bit<16> v2;
        v1 = r1 + p1;
        v2 = r2;
        if (hdr.ipv4.protocol == 17) {
            v2 = v2 + hdr.ipv4.totalLen;
        } else {
            v2 = v2 + hdr.ipv4.identification;
        }
#ifdef P4C_SUPPORTS_ASSIGNING_TO_ACTION_PARAMETERS
        // The #ifdef is here to make it easy to compile the rest of
        // this code with open source p4test and see that there are no
        // compile-time errors.  If you include these assignments
        // below, as of 2023-Mar p4test DOES give compile-time errors
        // for those lines, by design.  Enabling such assignments
        // requires not only a change to p4c, but if it is to be an
        // official part of the language, changes to the P4 language
        // spec as well.
        r1 = v1;
        r2 = v2;
#endif
    }

    // Because a2 assigns to r1 in its body, its value persists across
    // packets.
    action a2(bit<8> r1) {
        control_global = control_global + r1;
#ifdef P4C_SUPPORTS_ASSIGNING_TO_ACTION_PARAMETERS
        r1 = control_global;
#endif
    }

    // Because p is not assigned a value, only the control plane can
    // change its value.
    action a3(PortId_t p) {
        send_to_port(p);
    }

    // Because a4 assigns to r3 in its body, its value persists across
    // packets.
    action a4(bit<24> r3) {
        if (hdr.ipv4.protocol == 6) {
#ifdef P4C_SUPPORTS_ASSIGNING_TO_ACTION_PARAMETERS
            r3 = r3 + (bit<24>) (hdr.ipv4.totalLen - hdr.ipv4.minSizeInBytes());
#endif
        }
    }

    table t1 {
        key = {
            hdr.ipv4.dstAddr: lpm;
        }
        actions = {
            a1; a2; a3; a4;
        }
    }
    apply {
        if (hdr.ipv4.isValid()) {
            control_global = (bit<8>) hdr.ipv4.totalLen;
            t1.apply();
            hdr.ipv4.identification = (bit<16>) control_global;
        }
    }
}

control MainDeparserImpl(
    packet_out pkt,
    in    headers_t hdr,
    in    main_metadata_t user_meta,
    in    pna_main_output_metadata_t ostd)
{
    apply {
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.ipv4);
    }
}

PNA_NIC(
    MainParserImpl(),
    MainControlImpl(),
    MainDeparserImpl()
    ) main;
