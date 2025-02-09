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

SPDX-License-Identifier: Apache-2.0
*/

#include <core.p4>
#include "../pna.p4"

// Note: An architecture such as PNA can define an extern like
// DirectRegister, and this requires NO changes to the language spec.
//
// Yes, externs can be defined that are target-specific (such as the
// LPF extern in TNA [1]), but there _is_ value to P4 developers in
// defining externs that are common across multiple targets.  That is
// what the externs defined in an architecture like PSA and PNA _are_
// -- intended to be common across multiple targets, so that a P4
// developer learns them once, and can use them on multiple targets.

// [1] https://github.com/barefootnetworks/Open-Tofino/blob/master/share/p4c/p4include/tofino1_base.p4#L586-L589

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
    
    DirectRegister<bit<8>>() r1;
    DirectRegister<bit<16>>() r2;
    DirectRegister<bit<24>>() r3;

    // Because a1 only accesses r1 and r2, but never r3
    // (straightforward to analyze at compile time in P4 compiler),
    // the back end is free NOT to allocate storage for r3 in table
    // entries that have action a1.
    action a1(bit<8> p1) {
        bit<8> v1;
        bit<16> v2;
        v1 = r1.read() + p1;
        v2 = r2.read();
        if (hdr.ipv4.protocol == 17) {
            v2 = v2 + hdr.ipv4.totalLen;
        } else {
            v2 = v2 + hdr.ipv4.identification;
        }
        r1.write(v1);
        r2.write(v2);
    }

    // Because a2 can only access r1, but never r2 nor r3, the target
    // only needs to allocate space for r1 in table entries with
    // action a2.
    action a2() {
        control_global = control_global + r1.read();
        r1.write(control_global);
    }

    // Because a3 access none of r1, nor r2, nor r3, target need not
    // allocate space to store any of them in table entries with
    // action a3.
    action a3(PortId_t p) {
        send_to_port(p);
    }

    // Because a4 accesses only r3, the target only needs to allocate
    // space for r3 in table entries using action a4, but not allocate
    // space for r1 or r2.
    action a4() {
        bit<24> tmp = r3.read();
        if (hdr.ipv4.protocol == 6) {
            tmp = tmp + (bit<24>) (hdr.ipv4.totalLen - hdr.ipv4.minSizeInBytes());
        }
        r3.write(tmp);
    }

    table t1 {
        key = {
            hdr.ipv4.dstAddr: lpm;
        }
        actions = {
            a1; a2; a3; a4;
        }
        registers = { r1, r2, r3 };
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
