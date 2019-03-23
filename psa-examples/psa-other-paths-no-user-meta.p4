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
#include <psa.p4>

error {
    IPv4IncorrectVersion
}

bit<8> convert_packetpath_to_bit (in PSA_PacketPath_t path)
{
    if (path == PSA_PacketPath_t.NORMAL) {
        return 1;
    } else if (path == PSA_PacketPath_t.NORMAL_UNICAST) {
        return 2;
    } else if (path == PSA_PacketPath_t.NORMAL_MULTICAST) {
        return 3;
    } else if (path == PSA_PacketPath_t.CLONE_I2E) {
        return 4;
    } else if (path == PSA_PacketPath_t.CLONE_E2E) {
        return 5;
    } else if (path == PSA_PacketPath_t.RESUBMIT) {
        return 6;
    } else if (path == PSA_PacketPath_t.RECIRCULATE) {
        return 7;
    } else {
        // This case should never happen.  It is included just in case
        // something weird happens and it does get executed.  Perhaps
        // we could catch a bug.
        return 0;
    }
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

struct empty_metadata_t {
}

// This is a header intended for sending copies of
// psa_ingress_parser_input_metadata_t fields into an output packet,
// for debug/test purposes.
header psa_ingress_parser_input_header_t {
    // cookie is just a value filled in with a constant, to ease
    // finding the boundary between headers visually in hex dump of
    // output packets.
    bit<16> cookie;
    bit<32> ingress_port;
    bit<8>  packet_path;
}

header psa_ingress_input_header_t {
    // cookie is just a value filled in with a constant, to ease
    // finding the boundary between headers visually in hex dump of
    // output packets.
    bit<16> cookie;
    bit<32> ingress_port;
    bit<8>  packet_path;
    bit<64> ingress_timestamp;
    bit<8>  parser_error;
}

header psa_egress_parser_input_header_t {
    // cookie is just a value filled in with a constant, to ease
    // finding the boundary between headers visually in hex dump of
    // output packets.
    bit<16> cookie;
    bit<32> egress_port;
    bit<8>  packet_path;
}

header psa_egress_input_header_t {
    // cookie is just a value filled in with a constant, to ease
    // finding the boundary between headers visually in hex dump of
    // output packets.
    bit<16> cookie;
    bit<8>  class_of_service;
    bit<32> egress_port;
    bit<8>  packet_path;
    bit<16> instance;
    bit<64> egress_timestamp;
    bit<8>  parser_error;
}

header psa_egress_deparser_input_header_t {
    bit<32> egress_port;
}

struct metadata_t {
    PortId_t parser_input_port;
    PSA_PacketPath_t parser_input_packet_path;
}

struct headers_t {
    ethernet_t       ethernet;
    ipv4_t           ipv4;
    psa_ingress_parser_input_header_t  igpi;
    psa_ingress_input_header_t         igi;
    psa_egress_parser_input_header_t   egpi;
    psa_egress_input_header_t          egi;
    psa_egress_deparser_input_header_t egdi;
}

parser ingressParserImpl(packet_in packet,
                         out headers_t hdr,
                         inout metadata_t meta,
                         in psa_ingress_parser_input_metadata_t istd,
                         in empty_metadata_t resubmit_meta,
                         in empty_metadata_t recirculate_meta)
{
    state start {
        meta.parser_input_port = istd.ingress_port;
        meta.parser_input_packet_path = istd.packet_path;
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

control ingressImpl(inout headers_t hdr,
                    inout metadata_t meta,
                    in    psa_ingress_input_metadata_t  istd,
                    inout psa_ingress_output_metadata_t ostd)
{
    apply {
        // Copy PSA standard metadata into header that will go out
        // with the packet
        hdr.igpi.setValid();
        hdr.igpi.cookie = 0xcafe;
        hdr.igpi.ingress_port = (bit<32>) (PortIdUint_t) meta.parser_input_port;
        hdr.igpi.packet_path = convert_packetpath_to_bit(meta.parser_input_packet_path);

        hdr.igi.setValid();
        hdr.igi.cookie = 0xd00d;
        hdr.igi.ingress_port = (bit<32>) (PortIdUint_t) istd.ingress_port;
        hdr.igi.packet_path = convert_packetpath_to_bit(istd.packet_path);
        hdr.igi.ingress_timestamp = (bit<64>) (TimestampUint_t) istd.ingress_timestamp;
        hdr.igi.parser_error = convert_error_to_bit(istd.parser_error);

        if ((istd.packet_path == PSA_PacketPath_t.RESUBMIT) ||
            (istd.packet_path == PSA_PacketPath_t.RECIRCULATE))
        {
            // Direct packets out of ports 0 through 3, based
            // upon the 2 least significant bits of the Ethernet
            // destination address.
            send_to_port(ostd,
                (PortId_t) ((PortIdUint_t) hdr.ethernet.dstAddr[1:0]));
            if (hdr.ethernet.dstAddr[1:0] == 0) {
                // This action should overwrite the ostd.drop field that
                // was assigned a value via the send_to_port() action
                // above, causing this packet to be dropped, _not_ sent
                // out of port 0.
                ingress_drop(ostd);
            }
        } else {
            if (hdr.ethernet.srcAddr[1:0] == 2) {
                // Perform an inress-to-egress clone.  The cloned
                // packet should be dropped, unless the control plane
                // has configured clone session 3 to direct the packet
                // to one or more output ports.

                ostd.clone = true;
                ostd.clone_session_id = (CloneSessionId_t) 5;

                // A cloned packet should be created, and the original
                // will also be sent to egress to a port selected by
                // different Ethernet dest address bits than above,
                // just to be different.
                send_to_port(ostd,
                    (PortId_t) ((PortIdUint_t) hdr.ethernet.dstAddr[9:8]));
            } else if (hdr.ethernet.srcAddr[1:0] == 1) {
                // resubmit the packet
                ostd.drop = false;
                ostd.resubmit = true;
            } else {
                // recirculate the packet
                send_to_port(ostd, PSA_PORT_RECIRCULATE);
            }
        }
    }
}

parser egressParserImpl(packet_in packet,
                        out headers_t hdr,
                        inout metadata_t meta,
                        in psa_egress_parser_input_metadata_t istd,
                        in empty_metadata_t normal_meta,
                        in empty_metadata_t clone_i2e_meta,
                        in empty_metadata_t clone_e2e_meta)
{
    state start {
        meta.parser_input_port = istd.egress_port;
        meta.parser_input_packet_path = istd.packet_path;
        transition accept;
    }
}

control egressImpl(inout headers_t hdr,
                   inout metadata_t meta,
                   in    psa_egress_input_metadata_t  istd,
                   inout psa_egress_output_metadata_t ostd)
{
    apply {
        // Copy PSA standard metadata into header that will go out
        // with the packet
        hdr.egpi.setValid();
        hdr.egpi.cookie = 0xdead;
        hdr.egpi.egress_port = (bit<32>) (PortIdUint_t) meta.parser_input_port;
        hdr.egpi.packet_path = convert_packetpath_to_bit(meta.parser_input_packet_path);

        hdr.egi.setValid();
        hdr.egi.cookie = 0xbeef;
        hdr.egi.class_of_service = (bit<8>) (ClassOfServiceUint_t) istd.class_of_service;
        hdr.egi.egress_port = (bit<32>) (PortIdUint_t) istd.egress_port;
        hdr.egi.packet_path = convert_packetpath_to_bit(istd.packet_path);
        hdr.egi.instance = (bit<16>) (EgressInstanceUint_t) istd.instance;
        hdr.egi.egress_timestamp = (bit<64>) (TimestampUint_t) istd.egress_timestamp;
        hdr.egi.parser_error = convert_error_to_bit(istd.parser_error);

        if ((istd.packet_path == PSA_PacketPath_t.CLONE_I2E) ||
            (istd.packet_path == PSA_PacketPath_t.CLONE_E2E))
        {
            // Let the packet go out with no further special
            // operations on it.
        } else {
            if (hdr.ethernet.srcAddr[8:8] == 1) {
                // Perform an egress-to-egress clone.  The cloned
                // packet should be dropped, unless the control plane
                // has configured clone session 5 to direct the packet
                // to one or more output ports.
                ostd.clone = true;
                ostd.clone_session_id = (CloneSessionId_t) 5;
            } else {
                // Let the packet go out with no further special
                // operations on it.
            }
        }
    }
}

control CommonDeparserImpl(packet_out packet,
                           inout headers_t hdr)
{
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.igi);
        packet.emit(hdr.egpi);
        packet.emit(hdr.egi);
        packet.emit(hdr.egdi);
    }
}

control ingressDeparserImpl(packet_out packet,
                            out empty_metadata_t clone_i2e_meta,
                            out empty_metadata_t resubmit_meta,
                            out empty_metadata_t normal_meta,
                            inout headers_t hdr,
                            in metadata_t meta,
                            in psa_ingress_output_metadata_t istd)
{
    CommonDeparserImpl() cp;
    apply {
        cp.apply(packet, hdr);
    }
}

control egressDeparserImpl(packet_out packet,
                           out empty_metadata_t clone_e2e_meta,
                           out empty_metadata_t recirculate_meta,
                           inout headers_t hdr,
                           in metadata_t meta,
                           in psa_egress_output_metadata_t istd,
                           in psa_egress_deparser_input_metadata_t edstd)
{
    CommonDeparserImpl() cp;
    apply {
        // I do not believe current p4c supports anything except
        // packet.emit() calls in the deparser, so there is not really
        // a way to copy the field of
        // psa_egress_deparser_input_metadata_t struct into a header
        // here.  Not a big deal.
        cp.apply(packet, hdr);
    }
}

IngressPipeline(ingressParserImpl(),
                ingressImpl(),
                ingressDeparserImpl()) ip;

EgressPipeline(egressParserImpl(),
               egressImpl(),
               egressDeparserImpl()) ep;

PSA_Switch(ip, PacketReplicationEngine(), ep, BufferingQueueingEngine()) main;
