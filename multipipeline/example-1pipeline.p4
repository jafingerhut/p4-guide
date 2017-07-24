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
#include "psa-1pipeline.p4"


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

#define BYTE_COUNT_SIZE 48
typedef bit<48> ByteCounter_t;
typedef bit<32> PacketCounter_t;
typedef bit<80> PacketByteCounter_t;

const PortId_t NUM_PORTS = 512;

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

control ingress(inout headers hdr,
                inout metadata user_meta,
                PacketReplicationEngine pre,
                in  psa_ingress_input_metadata_t  istd,
                out psa_ingress_output_metadata_t ostd)
{
    Counter<ByteCounter_t, PortId_t>(NUM_PORTS, BYTE_COUNT_SIZE,
        CounterType_t.bytes) port_bytes_in;
    Register<bit<32>, bit<7>>(64) reg1;
    apply {
        bit<32> tmp;
        port_bytes_in.count(istd.ingress_port,
                            (ByteCounter_t) hdr.ethernet.etherType);
        tmp = reg1.read((bit<7>) istd.ingress_port[5:0]);
        tmp = tmp + 0xdeadbeef;
        reg1.write((bit<7>) istd.ingress_port[5:0], tmp);
        ostd.egress_port = 0;
    }
}

control egress(inout headers hdr,
               inout metadata user_meta,
               BufferingQueueingEngine bqe,
               in  psa_egress_input_metadata_t  istd)
{
    Counter<ByteCounter_t, PortId_t>(NUM_PORTS, BYTE_COUNT_SIZE,
        CounterType_t.bytes) port_bytes_out;
    Meter<bit<9>>(256, MeterType_t.bytes) meter1;
    apply {
        MeterColor_t c1;
        port_bytes_out.count(istd.egress_port,
                             (ByteCounter_t) hdr.ethernet.etherType);
        c1 = meter1.execute((bit<9>) istd.egress_port[7:0], MeterColor_t.GREEN);
        if (c1 == MeterColor_t.RED) {
            bqe.drop();
        }
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
