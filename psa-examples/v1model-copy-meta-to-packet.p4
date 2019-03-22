/*
Copyright 2019 Cisco Systems, Inc.

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
#include <v1model.p4>

error {
    IPv4IncorrectVersion
}

bit<8> convert_error_to_bit (in error err)
{
    if (err == error.NoError) {
        return 0;
    } else if (err == error.PacketTooShort) {
        return 1;
    } else if (err == error.NoMatch) {
        return 2;
    } else if (err == error.StackOutOfBounds) {
        return 3;
    } else if (err == error.HeaderTooShort) {
        return 4;
    } else if (err == error.ParserTimeout) {
        return 5;
    } else if (err == error.IPv4IncorrectVersion) {
        return 6;
    } else {
        // This branch should not execute for an error value returned
        // during packet parsing, unless the user's P4_16 program
        // defines additional kinds of parser errors.
        return 0xff;
    }
}


typedef bit<48>  EthernetAddress;

header ethernet_t {
    EthernetAddress dstAddr;
    EthernetAddress srcAddr;
    bit<16>         etherType;
}

header ipv4_t {
    bit<4>   version;
    bit<4>   ihl;
    bit<8>   diffserv;
    bit<16>  totalLen;
    bit<16>  identification;
    bit<3>   flags;
    bit<13>  fragOffset;
    bit<8>   ttl;
    bit<8>   protocol;
    bit<16>  hdrChecksum;
    bit<32>  srcAddr;
    bit<32>  dstAddr;
}

// This is a header intended for sending copies of v1model-specific
// metadata that should arrive already initialized for packets whle
// they are being parsed on ingress, for debug/test purposes.
header v1model_ingress_parser_input_header_t {
    // cookie is just a value filled in with a constant, to ease
    // finding the boundary between headers visually in hex dump of
    // output packets.
    bit<16> cookie;
    bit<32> ingress_port;
    bit<32> instance_type;
}

header v1model_ingress_input_header_t {
    // cookie is just a value filled in with a constant, to ease
    // finding the boundary between headers visually in hex dump of
    // output packets.
    bit<16> cookie;  
    bit<32> ingress_port;
    bit<32> instance_type;
    bit<64> ingress_global_timestamp;
    bit<8>  parser_error;
    bit<8>  checksum_error;
}

header v1model_egress_input_header_t {
    // cookie is just a value filled in with a constant, to ease
    // finding the boundary between headers visually in hex dump of
    // output packets.
    bit<16> cookie;
    bit<32> egress_port;
    bit<32> instance_type;
    bit<16> egress_rid;
    bit<64> egress_global_timestamp;
}

struct headers_t {
    ethernet_t    ethernet;
    ipv4_t        ipv4;
    v1model_ingress_parser_input_header_t  igpi;
    v1model_ingress_input_header_t         igi;
    v1model_egress_input_header_t          egi;
}

struct metadata_t {
}

parser parserImpl(packet_in packet,
                  out headers_t hdr,
                  inout metadata_t meta,
                  inout standard_metadata_t stdmeta)
{
    state start {
        // Copy v1model standard metadata into header that will go out
        // with the packet.
        hdr.igpi.setValid();
        hdr.igpi.cookie = 0xcafe;
        hdr.igpi.ingress_port = (bit<32>) stdmeta.ingress_port;
        hdr.igpi.instance_type = stdmeta.instance_type;

        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            0x0800: parse_ipv4;
            default: accept;
        }
    }
    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        verify(hdr.ipv4.version == 4w4, error.IPv4IncorrectVersion);
        transition accept;
    }
}

control verifyChecksum(inout headers_t hdr,
                       inout metadata_t meta)
{
    apply {
        verify_checksum(hdr.ipv4.isValid(),
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
                hdr.ipv4.dstAddr
            },
            hdr.ipv4.hdrChecksum, HashAlgorithm.csum16);
    }
}

control ingressImpl(inout headers_t hdr,
                    inout metadata_t meta,
                    inout standard_metadata_t stdmeta)
{
    apply {
        hdr.igi.setValid();
        hdr.igi.cookie = 0xd00d;
        hdr.igi.ingress_port = (bit<32>) stdmeta.ingress_port;
        hdr.igi.instance_type = stdmeta.instance_type;
        hdr.igi.ingress_global_timestamp = (bit<64>) stdmeta.ingress_global_timestamp;
        hdr.igi.parser_error = convert_error_to_bit(stdmeta.parser_error);

        stdmeta.egress_spec = (bit<9>) hdr.ethernet.dstAddr[1:0];
        if (hdr.ethernet.dstAddr[1:0] == 0) {
            // This action should overwrite the egress_spec field that
            // was assigned a value via the assignment above, causing
            // this packet to be dropped, _not_ sent out of port 0.
            mark_to_drop();
        }
    }
}

control egressImpl(inout headers_t hdr,
                   inout metadata_t meta,
                   inout standard_metadata_t stdmeta)
{
    apply {
        hdr.egi.setValid();
        hdr.egi.cookie = 0xbeef;
        hdr.egi.egress_port = (bit<32>) stdmeta.egress_port;
        hdr.egi.instance_type = stdmeta.instance_type;
        hdr.egi.egress_rid = stdmeta.egress_rid;
        hdr.egi.egress_global_timestamp = (bit<64>) stdmeta.egress_global_timestamp;
    }
}

control updateChecksum(inout headers_t hdr,
                       inout metadata_t meta)
{
    apply { }
}

control deparserImpl(packet_out packet,
                     in headers_t hdr)
{
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.igpi);
        packet.emit(hdr.igi);
        packet.emit(hdr.egi);
    }
}

V1Switch(parserImpl(),
         verifyChecksum(),
         ingressImpl(),
         egressImpl(),
         updateChecksum(),
         deparserImpl()) main;
