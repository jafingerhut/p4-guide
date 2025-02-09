// Copyright 2024 Andy Fingerhut
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// SPDX-License-Identifier: Apache-2.0

/* -*- P4_16 -*- */

#include <core.p4>
#include <psa.p4>

/*************************************************************************
 ************* C O N S T A N T S    A N D   T Y P E S  *******************
 *************************************************************************/
const int IPV4_HOST_SIZE = 65536;

typedef bit<48> ethernet_addr_t;

const bit<16> ETHERTYPE_TPID = 0x8100;
const bit<16> ETHERTYPE_IPV4 = 0x0800;

/*************************************************************************
 ***********************  H E A D E R S  *********************************
 *************************************************************************/

/*  Define all the headers the program will recognize             */
/*  The actual sets of headers processed by each gress can differ */

/* Standard ethernet header */
header ethernet_h {
    ethernet_addr_t  dst_addr;
    ethernet_addr_t  src_addr;
    bit<16>   ether_type;
}

header vlan_tag_h {
    bit<16> pcp_cfi_vid;
    bit<16>  ether_type;
}

const bit<8> IPPROTO_ICMP = 1;

header ipv4_h {
    bit<8>       version_ihl;
    bit<8>       diffserv;
    bit<16>      total_len;
    bit<16>      identification;
    bit<16>      flags_frag_offset;
    bit<8>       ttl;
    bit<8>       protocol;
    bit<16>      hdr_checksum;
    bit<32>      src_addr;
    bit<32>      dst_addr;
}

/* Note: There are many other formats of ICMP messages besides the
 * following one, which is specific to echo request and echo reply
 * messages.  This P4 program is NOT trying to be general and parsing
 * all kinds of ICMP messages. */

const bit<8> ICMP_TYPE_ECHO_REPLY = 0;
const bit<8> ICMP_TYPE_ECHO_REQUEST = 8;

header icmp_echo_req_or_reply_h {
    bit<8>     icmp_type;
    bit<8>     code;
    bit<16>    checksum;
    bit<16>    identifier;
    bit<16>    sequence_num;
}

/*************************************************************************
 **************  I N G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/

    /***********************  H E A D E R S  ************************/

struct my_ingress_headers_t {
    ethernet_h   ethernet;
    vlan_tag_h   vlan_tag;
    ipv4_h       ipv4;
    icmp_echo_req_or_reply_h icmp;
}

    /******  G L O B A L   I N G R E S S   M E T A D A T A  *********/

struct my_ingress_metadata_t {
}

struct empty_metadata_t {
}

    /***********************  P A R S E R  **************************/
parser Ingress_Parser(
    packet_in pkt,
    out my_ingress_headers_t hdr,
    inout my_ingress_metadata_t meta,
    in psa_ingress_parser_input_metadata_t ig_intr_md,
    in empty_metadata_t resub_meta, 
    in empty_metadata_t recirc_meta)
{
     state start {
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select (hdr.ethernet.ether_type) {
            ETHERTYPE_TPID:  parse_vlan_tag;
            ETHERTYPE_IPV4:  parse_ipv4;
            default: accept;
        }
    }

    state parse_vlan_tag {
        pkt.extract(hdr.vlan_tag);
        transition select (hdr.vlan_tag.ether_type) {
            ETHERTYPE_IPV4:  parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select (hdr.ipv4.protocol) {
            IPPROTO_ICMP: parse_icmp;
            default: accept;
        }
    }

    state parse_icmp {
        pkt.extract(hdr.icmp);
        transition accept;
    }
}

    /***************** M A T C H - A C T I O N  *********************/

control ingress(
    inout my_ingress_headers_t hdr,
    inout my_ingress_metadata_t meta,
    in psa_ingress_input_metadata_t ig_intr_md,
    inout psa_ingress_output_metadata_t ostd
)
{
    InternetChecksum() ck;
    InternetChecksum() ck2;

    // recalculate the IPv4 header checksum
    action calc_ipv4_no_option_header_checksum() {
        ck.clear();
        // The following version did not work correctly with p4c-dpdk,
        // probably because of known issues with DPDK IPv4 checksum
        // implementation:
//        ck.add({
//            /* 16-bit word  0   */ hdr.ipv4.version_ihl, hdr.ipv4.diffserv,
//            /* 16-bit word  1   */ hdr.ipv4.total_len,
//            /* 16-bit word  2   */ hdr.ipv4.identification,
//            /* 16-bit word  3   */ hdr.ipv4.flags_frag_offset,
//            /* 16-bit word  4   */ hdr.ipv4.ttl, hdr.ipv4.protocol,
//            /* 16-bit word  5 skip hdr.ipv4.hdr_checksum, */
//            /* 16-bit words 6-7 */ hdr.ipv4.src_addr,
//            /* 16-bit words 8-9 */ hdr.ipv4.dst_addr
//            });
        // It seems to work correctly if you only pass fields whose
        // lengths are multiples of 16 bits long to the add() method.
        bit<16> word0 = hdr.ipv4.version_ihl ++ hdr.ipv4.diffserv;
        bit<16> word4 = hdr.ipv4.ttl ++ hdr.ipv4.protocol;
        ck.add({
            /* 16-bit word  0   */ word0,
            /* 16-bit word  1   */ hdr.ipv4.total_len,
            /* 16-bit word  2   */ hdr.ipv4.identification,
            /* 16-bit word  3   */ hdr.ipv4.flags_frag_offset,
            /* 16-bit word  4   */ word4,
            /* 16-bit word  5 skip hdr.ipv4.hdr_checksum, */
            /* 16-bit words 6-7 */ hdr.ipv4.src_addr,
            /* 16-bit words 8-9 */ hdr.ipv4.dst_addr
            });
        hdr.ipv4.hdr_checksum = ck.get();
    }

    action calc_icmp_header_checksum() {
        // For some reason, DPDK seems to have a bug if I try to use
        // instance ck in this action.  Use a separate instance ck2 as
        // a workaround.
        ck2.clear();
        bit<16> word0 = hdr.icmp.icmp_type ++ hdr.icmp.code;
        ck2.add({
            /* 16-bit word  0 */ word0,
            /* 16-bit word  1 skip hdr.icmp.checksum, */
            /* 16-bit word  2 */ hdr.icmp.identifier,
            /* 16-bit word  3 */ hdr.icmp.sequence_num
            });
        hdr.icmp.checksum = ck2.get();
    }

    action copy_src_mac_to_icmp_and_id_fields() {
        hdr.ipv4.identification = hdr.ethernet.src_addr[47:32];
        hdr.icmp.identifier = hdr.ethernet.src_addr[31:16];
        hdr.icmp.sequence_num = hdr.ethernet.src_addr[15:0];
    }

    action send(PortId_t port) {
        send_to_port(ostd, port);
        //hdr.ipv4.ttl = 42;
        copy_src_mac_to_icmp_and_id_fields();
        calc_ipv4_no_option_header_checksum();
        calc_icmp_header_checksum();
    }

    action drop() {
        ingress_drop(ostd);
    }
    
    table ipv4_host {
        key = { hdr.ipv4.dst_addr : exact; }
        actions = {
            send;
            drop;
            @defaultonly NoAction;
        }
        const default_action = drop();
        size = IPV4_HOST_SIZE;
    }

    apply {
        if (hdr.ipv4.isValid()) {
            ipv4_host.apply();
        }
    }
}

    /*********************  D E P A R S E R  ************************/

control Ingress_Deparser(packet_out pkt,
    out empty_metadata_t clone_i2e_meta, 
    out empty_metadata_t resubmit_meta, 
    out empty_metadata_t normal_meta,
    inout my_ingress_headers_t hdr,
    in    my_ingress_metadata_t meta,
    in psa_ingress_output_metadata_t istd)
{
    apply {
        pkt.emit(hdr);
    }
}


/*************************************************************************
 ****************  E G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/

    /***********************  H E A D E R S  ************************/

struct my_egress_headers_t {
}

    /********  G L O B A L   E G R E S S   M E T A D A T A  *********/

struct my_egress_metadata_t {
}

    /***********************  P A R S E R  **************************/

parser Egress_Parser(
    packet_in pkt,
    out my_egress_headers_t hdr,
    inout my_ingress_metadata_t meta,
    in psa_egress_parser_input_metadata_t istd, 
    in empty_metadata_t normal_meta, 
    in empty_metadata_t clone_i2e_meta, 
    in empty_metadata_t clone_e2e_meta)
{
    state start {
        transition accept;
    }
}

    /***************** M A T C H - A C T I O N  *********************/

control egress(
    inout my_egress_headers_t hdr,
    inout my_ingress_metadata_t meta,
    in psa_egress_input_metadata_t istd, 
    inout psa_egress_output_metadata_t ostd)
{
    apply {
    }
}

    /*********************  D E P A R S E R  ************************/

control Egress_Deparser(packet_out pkt,
    out empty_metadata_t clone_e2e_meta, 
    out empty_metadata_t recirculate_meta,
    inout my_egress_headers_t hdr,
    in my_ingress_metadata_t meta,
    in psa_egress_output_metadata_t istd, 
    in psa_egress_deparser_input_metadata_t edstd)
{
    apply {
        pkt.emit(hdr);
    }
}

#if __p4c__
bit<32> test_version = __p4c_version__;
#endif

/************ F I N A L   P A C K A G E ******************************/

IngressPipeline(Ingress_Parser(), ingress(), Ingress_Deparser()) pipe;

EgressPipeline(Egress_Parser(), egress(), Egress_Deparser()) ep;

PSA_Switch(pipe, PacketReplicationEngine(), ep, BufferingQueueingEngine()) main;
