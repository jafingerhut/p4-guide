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

#include <core.p4>
#include "example-arch.p4"


typedef bit<48>  EthernetAddress;

header ethernet_t {
    EthernetAddress dstAddr;
    EthernetAddress srcAddr;
    bit<16>         etherType;
}

// Make all of the types ing_in_headers, ing_out_headers,
// egr_in_headers, and egr_out_headers at least slightly different
// from each other, so they cannot be unified.  This helps us to know
// whether we have type parameters for constructors correct in later
// code.

struct ing_in_headers {
    ethernet_t       ethernet;
    bit<10> a0;
}

struct ing_out_headers {
    ethernet_t       ethernet;
    bit<11> a1;
}

struct egr_in_headers {
    ethernet_t       ethernet;
    bit<12> a2;
}

struct egr_out_headers {
    ethernet_t       ethernet;
    bit<13> a3;
}

struct ing_to_egr {
    PortId x;
}

parser ing_parse(packet_in buffer,
                 out ing_in_headers parsed_hdr)
{
    state start {
        buffer.extract(parsed_hdr.ethernet);
        transition accept;
    }
}

control ingress(in ing_in_headers ihdr,
                in InControl inCtrl,
                out ing_out_headers ohdr,
                out ing_to_egr toEgress,
                out OutControl outCtrl)
{
    apply {
        ohdr.ethernet = ihdr.ethernet;
        toEgress.x = inCtrl.inputPort;
        outCtrl.outputPort = inCtrl.inputPort;
    }
}

control ing_deparse(in ing_out_headers ohdr,
                    packet_out b)
{
    apply { b.emit(ohdr.ethernet); }
}

parser egr_parse(packet_in buffer,
                 out egr_in_headers parsed_hdr)
{
    state start {
        buffer.extract(parsed_hdr.ethernet);
        transition accept;
    }
}

control egress(in egr_in_headers ihdr,
               in InControl inCtrl,
               in ing_to_egr fromIngress,
               out egr_out_headers ohdr,
               out OutControl outCtrl)
{
    apply {
        ohdr.ethernet = ihdr.ethernet;
        outCtrl.outputPort = fromIngress.x;
    }
}

control egr_deparse(in egr_out_headers ohdr,
                    packet_out b)
{
    apply { b.emit(ohdr.ethernet); }
}

// It is normal for the compiler to give "unused instance" warnings
// messages for the package instantiations for Ingress and Egress
// below, if the instances are not used later.

Ingress(ing_parse(), ingress(), ing_deparse()) ig1;
Ingress<ing_to_egr, ing_in_headers, ing_out_headers>
    (ing_parse(), ingress(), ing_deparse()) ig2;

Egress(egr_parse(), egress(), egr_deparse()) eg1;
Egress<ing_to_egr, egr_in_headers, egr_out_headers>
    (egr_parse(), egress(), egr_deparse()) eg2;

// Next instantiation gives error, as expected:
// "Cannot unify struct egr_in_headers to struct ing_in_headers"

//Egress<ing_to_egr, ing_in_headers, egr_out_headers>
//    (egr_parse(), egress(), egr_deparse()) eg3;

// If you try any one of the attempted instantiations of package
// Switch below, it causes the latest version of p4test as of
// 2017-Jul-19 to give an error message like this;

// example-arch-use.p4(140): error: main: Cannot unify package Egress to package Egress
// Switch(ig1, eg2) main;
//                  ^^^^

Switch(ig1, eg1) main;
//Switch(ig1, eg2) main;
//Switch(ig2, eg1) main;
//Switch(ig2, eg2) main;
//Switch<ing_to_egr>(ig1, eg1) main;
//Switch(Ingress(ing_parse(), ingress(), ing_deparse()),
//       Egress(egr_parse(), egress(), egr_deparse())) main;
