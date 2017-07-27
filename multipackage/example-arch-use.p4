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

struct ing_in_headers {
    ethernet_t       ethernet;
}

struct ing_out_headers {
    ethernet_t       ethernet;
}

struct egr_in_headers {
    ethernet_t       ethernet;
}

struct egr_out_headers {
    ethernet_t       ethernet;
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
        ohdr = ihdr;
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
        ohdr = ihdr;
        outCtrl.outputPort = fromIngress.x;
    }
}

control egr_deparse(in egr_out_headers ohdr,
                    packet_out b)
{
    apply { b.emit(ohdr.ethernet); }
}

Ingress(ing_parse(), ingress(), ing_deparse()) ig;
Egress(egr_parse(), egress(), egr_deparse()) eg;
Switch(ig, eg) main;

//Switch(Ingress(ing_parse(), ingress(), ing_deparse()),
//       Egress(egr_parse(), egress(), egr_deparse())) main;
