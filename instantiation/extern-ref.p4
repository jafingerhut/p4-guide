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
#include "psa-local-copy.p4"


extern Random2 {
  Random2();
  bit<10> read();
}


typedef bit<48>  EthernetAddress;

header ethernet_t {
    EthernetAddress dstAddr;
    EthernetAddress srcAddr;
    bit<16>         etherType;
}

struct fwd_metadata_t {
}

struct metadata {
    fwd_metadata_t fwd_metadata;
}

struct headers {
    ethernet_t       ethernet;
}

parser ParserImpl(packet_in buffer,
                  out headers parsed_hdr,
                  inout metadata user_meta,
                  in psa_parser_input_metadata_t istd)
{
    state start {
        transition parse_ethernet;
    }
    state parse_ethernet {
        buffer.extract(parsed_hdr.ethernet);
        transition accept;
    }
}


action nop() {
}

control foo2(inout headers my_headers,
             inout metadata meta,
             Random2 rand)
{
    action foo2_action() {
        my_headers.ethernet.dstAddr[40:40] = 1;
        my_headers.ethernet.srcAddr[47:38] = ~rand.read();
    }
    table foo2_table {
        key = {
            my_headers.ethernet.srcAddr : exact;
        }
        actions = {
            foo2_action;
            NoAction;
        }
        default_action = NoAction;
    }
    apply {
        foo2_table.apply();
    }
}


control ingress(inout headers hdr,
                inout metadata user_meta,
                PacketReplicationEngine pre,
                in  psa_ingress_input_metadata_t  istd,
                out psa_ingress_output_metadata_t ostd)
{
    //Random<bit<10>>(RandomDistribution.PRNG, 0, 1023) rand1;
    Random2() rand1;
    foo2() foo2_inst;
    apply {
        ostd.egress_port = 0;
        foo2_inst.apply(hdr, user_meta, rand1);
    }
}


control egress(inout headers hdr,
               inout metadata user_meta,
               BufferingQueueingEngine bqe,
               in  psa_egress_input_metadata_t  istd)
{
    //Random<bit<10>>(RandomDistribution.PRNG, 0, 1023) rand2;
    Random2() rand2;
    foo2() foo2_inst;
    apply {
        hdr.ethernet.etherType[15:6] = rand2.read();
        foo2_inst.apply(hdr, user_meta, rand2);
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
    }
}

control verifyChecksum(in headers hdr, inout metadata meta) {
    apply { }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply { }
}

PSA_Switch(ParserImpl(),
           verifyChecksum(),
           ingress(),
           egress(),
           computeChecksum(),
           DeparserImpl()) main;
