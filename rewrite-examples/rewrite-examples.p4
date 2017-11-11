/* -*- mode: P4_16 -*- */
/*
Copyright 2013-present Barefoot Networks, Inc. 

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


const bit<1> TRUE  = 1;
const bit<1> FALSE = 0;

/* Ethertypes */
const bit<16> ETHERTYPE_BF_FABRIC =  0x9000;
const bit<16> ETHERTYPE_VLAN      =  0x8100;
const bit<16> ETHERTYPE_QINQ      =  0x9100;
const bit<16> ETHERTYPE_MPLS      =  0x8847;
const bit<16> ETHERTYPE_IPV4      =  0x0800;
const bit<16> ETHERTYPE_IPV6      =  0x86dd;
const bit<16> ETHERTYPE_ARP       =  0x0806;
const bit<16> ETHERTYPE_RARP      =  0x8035;
const bit<16> ETHERTYPE_NSH       =  0x894f;
const bit<16> ETHERTYPE_ETHERNET  =  0x6558;
const bit<16> ETHERTYPE_ROCE      =  0x8915;
const bit<16> ETHERTYPE_FCOE      =  0x8906;
const bit<16> ETHERTYPE_TRILL     =  0x22f3;
const bit<16> ETHERTYPE_VNTAG     =  0x8926;
const bit<16> ETHERTYPE_LLDP      =  0x88cc;
const bit<16> ETHERTYPE_LACP      =  0x8809;

/* IP protocols */
const bit<8> IP_PROTOCOLS_ICMP       =   1;
const bit<8> IP_PROTOCOLS_IGMP       =   2;
const bit<8> IP_PROTOCOLS_IPV4       =   4;
const bit<8> IP_PROTOCOLS_TCP        =   6;
const bit<8> IP_PROTOCOLS_UDP        =  17;
const bit<8> IP_PROTOCOLS_IPV6       =  41;
const bit<8> IP_PROTOCOLS_GRE        =  47;
const bit<8> IP_PROTOCOLS_IPSEC_ESP  =  50;
const bit<8> IP_PROTOCOLS_IPSEC_AH   =  51;
const bit<8> IP_PROTOCOLS_ICMPV6     =  58;
const bit<8> IP_PROTOCOLS_EIGRP      =  88;
const bit<8> IP_PROTOCOLS_OSPF       =  89;
const bit<8> IP_PROTOCOLS_PIM        = 103;
const bit<8> IP_PROTOCOLS_VRRP       = 112;

/* Tunnel types - not from standards, just internal implementation constants */
const bit<5> INGRESS_TUNNEL_TYPE_NONE       =  0;
const bit<5> INGRESS_TUNNEL_TYPE_VXLAN      =  1;
const bit<5> INGRESS_TUNNEL_TYPE_GRE        =  2;
const bit<5> INGRESS_TUNNEL_TYPE_IP_IN_IP   =  3;
const bit<5> INGRESS_TUNNEL_TYPE_GENEVE     =  4;
const bit<5> INGRESS_TUNNEL_TYPE_NVGRE      =  5;
const bit<5> INGRESS_TUNNEL_TYPE_MPLS_L2VPN =  6;
const bit<5> INGRESS_TUNNEL_TYPE_MPLS_L3VPN =  9;
const bit<5> INGRESS_TUNNEL_TYPE_VXLAN_GPE  = 12;

/* Egress tunnel types */
const bit<5> EGRESS_TUNNEL_TYPE_NONE           =  0;
const bit<5> EGRESS_TUNNEL_TYPE_IPV4_VXLAN     =  1;
const bit<5> EGRESS_TUNNEL_TYPE_IPV6_VXLAN     =  2;
const bit<5> EGRESS_TUNNEL_TYPE_IPV4_GENEVE    =  3;
const bit<5> EGRESS_TUNNEL_TYPE_IPV6_GENEVE    =  4;
const bit<5> EGRESS_TUNNEL_TYPE_IPV4_NVGRE     =  5;
const bit<5> EGRESS_TUNNEL_TYPE_IPV6_NVGRE     =  6;
const bit<5> EGRESS_TUNNEL_TYPE_IPV4_ERSPAN_T3 =  7;
const bit<5> EGRESS_TUNNEL_TYPE_IPV6_ERSPAN_T3 =  8;
const bit<5> EGRESS_TUNNEL_TYPE_IPV4_GRE       =  9;
const bit<5> EGRESS_TUNNEL_TYPE_IPV6_GRE       = 10;
const bit<5> EGRESS_TUNNEL_TYPE_IPV4_IP        = 11;
const bit<5> EGRESS_TUNNEL_TYPE_IPV6_IP        = 12;
const bit<5> EGRESS_TUNNEL_TYPE_MPLS_L2VPN     = 13;
const bit<5> EGRESS_TUNNEL_TYPE_MPLS_L3VPN     = 14;
const bit<5> EGRESS_TUNNEL_TYPE_FABRIC         = 15;
const bit<5> EGRESS_TUNNEL_TYPE_CPU            = 16;


struct egress_metadata_t {
    bit<1>  bypass;
    bit<2>  port_type;
    bit<16> payload_length;
    bit<9>  smac_idx;
    bit<16> bd;
    bit<16> outer_bd;
    bit<48> mac_da;
    bit<1>  routed;
    bit<16> same_bd_check;
    bit<8>  drop_reason;
    bit<16> ifindex;
}

struct ingress_metadata_t {
    bit<16> bd;
}

struct l3_metadata_t {
    bit<16> nexthop_index;
    bit<8>  mtu_index;
    bit<16> l3_mtu_check;
}

struct multicast_metadata_t {
    bit<1>  inner_replica;
    bit<1>  replica;
}

struct nexthop_metadata_t {
    bit<2> nexthop_type;
}

struct tunnel_metadata_t {
    bit<5>  ingress_tunnel_type;
    bit<5>  egress_tunnel_type;
    bit<14> tunnel_index;
    bit<9>  tunnel_src_index;
    bit<9>  tunnel_smac_index;
    bit<14> tunnel_dst_index;
    bit<14> tunnel_dmac_index;
    bit<1>  tunnel_terminate;
    bit<4>  egress_header_count;
    bit<8>  inner_ip_proto;
}

header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

header vlan_tag_t {
    bit<3>  pcp;
    bit<1>  cfi;
    bit<12> vid;
    bit<16> etherType;
}

header gre_t {
    bit<1>  C;
    bit<1>  R;
    bit<1>  K;
    bit<1>  S;
    bit<1>  s;
    bit<3>  recurse;
    bit<5>  flags;
    bit<3>  ver;
    bit<16> proto;
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

header ipv6_t {
    bit<4>   version;
    bit<8>   trafficClass;
    bit<20>  flowLabel;
    bit<16>  payloadLen;
    bit<8>   nextHdr;
    bit<8>   hopLimit;
    bit<128> srcAddr;
    bit<128> dstAddr;
}

header tcp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> seqNo;
    bit<32> ackNo;
    bit<4>  dataOffset;
    bit<4>  res;
    bit<8>  flags;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgentPtr;
}

header udp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<16> length_;
    bit<16> checksum;
}

header generic_20_byte_hdr_t {
    bit<32> word0;
    bit<32> word1;
    bit<32> word2;
    bit<32> word3;
    bit<32> word4;
}

header generic_28_byte_hdr_t {
    bit<32> word0;
    bit<32> word1;
    bit<32> word2;
    bit<32> word3;
    bit<32> word4;
    bit<32> word5;
    bit<32> word6;
}

header generic_40_byte_hdr_t {
    bit<32> word0;
    bit<32> word1;
    bit<32> word2;
    bit<32> word3;
    bit<32> word4;
    bit<32> word5;
    bit<32> word6;
    bit<32> word7;
    bit<32> word8;
    bit<32> word9;
}

struct metadata {
    egress_metadata_t    egress_metadata;
    ingress_metadata_t   ingress_metadata;
    l3_metadata_t        l3_metadata;
    multicast_metadata_t multicast;
    nexthop_metadata_t   nexthop_metadata;
    tunnel_metadata_t    tunnel;
}

struct headers {
    /* The headers with a prefix of "outer_" in their names are never
     * part of a parsed input packet.  They only become valid for some
     * tunnel encapsulation cases, and are then emitted in the
     * deparser, in addition to any original headers (below) that are
     * still valid. */
    ethernet_t    outer_ethernet;
    vlan_tag_t[2] outer_vlan_tag_;
    ipv4_t        outer_ipv4;
    ipv6_t        outer_ipv6;
    tcp_t         outer_tcp;
    udp_t         outer_udp;
    gre_t         outer_gre;
    generic_20_byte_hdr_t generic_20_byte_hdr;
    generic_28_byte_hdr_t generic_28_byte_hdr;
    generic_40_byte_hdr_t generic_40_byte_hdr;

    /* From here down, all headers may have been parsed as part of the
     * original received packet. */
    ethernet_t    ethernet;
    vlan_tag_t[2] vlan_tag_;
    ipv4_t        ipv4;
    ipv6_t        ipv6;
    tcp_t         tcp;
    udp_t         udp;
    gre_t         gre;

    ipv4_t        inner_ipv4;
    tcp_t         inner_tcp;
    udp_t         inner_udp;
}

parser ParserImpl(packet_in packet,
                  out headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {
    state start {
        transition parse_ethernet;
    }
    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            ETHERTYPE_VLAN: parse_vlan;
            ETHERTYPE_IPV4: parse_ipv4;
            ETHERTYPE_IPV6: parse_ipv6;
            default: accept;
        }
    }
    state parse_vlan {
        packet.extract(hdr.vlan_tag_[0]);
        transition select(hdr.vlan_tag_[0].etherType) {
            ETHERTYPE_IPV4: parse_ipv4;
            ETHERTYPE_IPV6: parse_ipv6;
            default: accept;
        }
    }
    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition select(hdr.ipv4.fragOffset, hdr.ipv4.ihl,
                          hdr.ipv4.protocol) {
            (13w0x0, 4w0x5, IP_PROTOCOLS_TCP): parse_tcp;
            (13w0x0, 4w0x5, IP_PROTOCOLS_UDP): parse_udp;
            (13w0x0, 4w0x5, IP_PROTOCOLS_GRE): parse_gre;
            default: accept;
        }
    }
    state parse_ipv6 {
        packet.extract(hdr.ipv6);
        transition select(hdr.ipv6.nextHdr) {
            IP_PROTOCOLS_TCP: parse_tcp;
            IP_PROTOCOLS_UDP: parse_udp;
            IP_PROTOCOLS_GRE: parse_gre;
            default: accept;
        }
    }
    state parse_tcp {
        packet.extract(hdr.tcp);
        transition accept;
    }
    state parse_udp {
        packet.extract(hdr.udp);
        transition accept;
    }
    state parse_gre {
        packet.extract(hdr.gre);
        transition select(hdr.gre.C, hdr.gre.R, hdr.gre.K, hdr.gre.S,
                          hdr.gre.s, hdr.gre.recurse, hdr.gre.flags,
                          hdr.gre.ver, hdr.gre.proto) {
            (1w0x0, 1w0x0, 1w0x0,
             1w0x0, 1w0x0, 3w0x0,
             5w0x0, 3w0x0, ETHERTYPE_IPV4): parse_gre_ipv4;
            default: accept;
        }
    }
    state parse_gre_ipv4 {
        meta.tunnel.ingress_tunnel_type = INGRESS_TUNNEL_TYPE_GRE;
        transition parse_inner_ipv4;
    }
    state parse_inner_ipv4 {
        packet.extract(hdr.inner_ipv4);
        transition select(hdr.inner_ipv4.fragOffset, hdr.inner_ipv4.ihl,
                          hdr.inner_ipv4.protocol) {
            (13w0x0, 4w0x5, IP_PROTOCOLS_TCP): parse_inner_tcp;
            (13w0x0, 4w0x5, IP_PROTOCOLS_UDP): parse_inner_udp;
            default: accept;
        }
    }
    state parse_inner_tcp {
        packet.extract(hdr.inner_tcp);
        transition accept;
    }
    state parse_inner_udp {
        packet.extract(hdr.inner_udp);
        transition accept;
    }
}

control process_rewrite(inout headers hdr,
                        inout metadata meta,
                        inout standard_metadata_t standard_metadata) {
    action nop() {
    }
    action set_l2_rewrite() {
        meta.egress_metadata.routed = FALSE;
        meta.egress_metadata.bd = meta.ingress_metadata.bd;
        meta.egress_metadata.outer_bd = meta.ingress_metadata.bd;
    }
    action set_l2_rewrite_with_tunnel(bit<14> tunnel_index,
                                      bit<5> tunnel_type) {
        meta.egress_metadata.routed = FALSE;
        meta.egress_metadata.bd = meta.ingress_metadata.bd;
        meta.egress_metadata.outer_bd = meta.ingress_metadata.bd;
        meta.tunnel.tunnel_index = tunnel_index;
        meta.tunnel.egress_tunnel_type = tunnel_type;
    }
    action set_l3_rewrite(bit<16> bd,
                          bit<8> mtu_index,
                          bit<48> dmac) {
        meta.egress_metadata.routed = TRUE;
        meta.egress_metadata.mac_da = dmac;
        meta.egress_metadata.bd = bd;
        meta.egress_metadata.outer_bd = bd;
        meta.l3_metadata.mtu_index = mtu_index;
    }
    action set_l3_rewrite_with_tunnel(bit<16> bd,
                                      bit<48> dmac,
                                      bit<14> tunnel_index,
                                      bit<5> tunnel_type) {
        meta.egress_metadata.routed = TRUE;
        meta.egress_metadata.mac_da = dmac;
        meta.egress_metadata.bd = bd;
        meta.egress_metadata.outer_bd = bd;
        meta.tunnel.tunnel_index = tunnel_index;
        meta.tunnel.egress_tunnel_type = tunnel_type;
    }
    action rewrite_ipv4_multicast() {
        hdr.ethernet.dstAddr[22:0] = hdr.ipv4.dstAddr[22:0];
    }
    action rewrite_ipv6_multicast() {
    }
    table rewrite {
        key = {
            meta.l3_metadata.nexthop_index: exact;
        }
        actions = {
            nop;
            set_l2_rewrite;
            set_l2_rewrite_with_tunnel;
            set_l3_rewrite;
            set_l3_rewrite_with_tunnel;
        }
        size = 1024;
    }
    table rewrite_multicast {
        key = {
            hdr.ipv4.isValid()       : exact;
            hdr.ipv6.isValid()       : exact;
            hdr.ipv4.dstAddr[31:28]  : ternary;
            hdr.ipv6.dstAddr[127:120]: ternary;
        }
        actions = {
            nop;
            rewrite_ipv4_multicast;
            rewrite_ipv6_multicast;
        }
    }
    apply {
        if (meta.egress_metadata.routed == FALSE ||
            meta.l3_metadata.nexthop_index != 0)
        {
            rewrite.apply();
        } else {
            rewrite_multicast.apply();
        }
    }
}

control process_tunnel_encap(inout headers hdr,
                             inout metadata meta,
                             inout standard_metadata_t standard_metadata) {
    action nop() {
    }
    action inner_ipv4_rewrite() {
        meta.egress_metadata.payload_length = hdr.ipv4.totalLen;
        meta.tunnel.inner_ip_proto = IP_PROTOCOLS_IPV4;
    }
    action inner_ipv6_rewrite() {
        /* 40 bytes is the length of the base IPv6 header, which is
         * not included in hdr.ipv6.payloadLen */
        meta.egress_metadata.payload_length = 40 + hdr.ipv6.payloadLen;
        meta.tunnel.inner_ip_proto = IP_PROTOCOLS_IPV6;
    }
    action inner_non_ip_rewrite() {
        meta.egress_metadata.payload_length =
            (bit<16>)standard_metadata.packet_length - 14;
    }
    table tunnel_encap_process_inner {
        key = {
            hdr.ipv4.isValid(): exact;
            hdr.ipv6.isValid(): exact;
        }
        actions = {
            inner_ipv4_rewrite;
            inner_ipv6_rewrite;
            inner_non_ip_rewrite;
        }
        size = 1024;
    }

    action f_insert_gre_header() {
        /* This code only handles the GRE encapsulation cases with no
         * optional checksum, key, or sequence number. */
        hdr.outer_gre.setValid();
        hdr.outer_gre.C = 0;
        hdr.outer_gre.R = 0;
        hdr.outer_gre.K = 0;
        hdr.outer_gre.S = 0;
        hdr.outer_gre.s = 0;
        hdr.outer_gre.recurse = 0;
        hdr.outer_gre.flags = 0;
        hdr.outer_gre.ver = 0;
        /* The proto field will be set elsewhere, depending upon the
         * type of the inner packet being encapsulated. */
        //hdr.outer_gre.proto = filled_in_later;
    }
    action f_insert_ipv4_header(bit<8> proto) {
        /* Fill in all fields except totalLen, srcAddr, and dstAddr,
         * which will be filled in by later table actions.
         * hdrChecksum will be calculated just before deparsing. */
        hdr.outer_ipv4.setValid();
        hdr.outer_ipv4.version = 4;
        hdr.outer_ipv4.ihl = 5;
        hdr.outer_ipv4.diffserv = 0;
        //hdr.outer_ipv4.totalLen = filled_in_later;
        hdr.outer_ipv4.identification = 0;
        hdr.outer_ipv4.flags = 0;
        hdr.outer_ipv4.fragOffset = 0;
        hdr.outer_ipv4.ttl = 64;
        hdr.outer_ipv4.protocol = proto;
        //hdr.outer_ipv4.hdrChecksum = filled_in_later;
        //hdr.outer_ipv4.srcAddr = filled_in_later;
        //hdr.outer_ipv4.dstAddr = filled_in_later;
    }
    action ipv4_gre_rewrite() {
        f_insert_gre_header();
        hdr.outer_gre.proto = hdr.ethernet.etherType;
        f_insert_ipv4_header(IP_PROTOCOLS_GRE);
        /* 24 is size in bytes of outer_ipv4 plus outer_gre headers */
        hdr.outer_ipv4.totalLen = meta.egress_metadata.payload_length + 24;
        hdr.outer_ethernet.setValid();
        hdr.outer_ethernet.etherType = ETHERTYPE_IPV4;
    }
    action ipv4_ip_rewrite() {
        f_insert_ipv4_header(meta.tunnel.inner_ip_proto);
        /* 20 is size in bytes of outer_ipv4 header */
        hdr.outer_ipv4.totalLen = meta.egress_metadata.payload_length + 20;
        hdr.outer_ethernet.setValid();
        hdr.outer_ethernet.etherType = ETHERTYPE_IPV4;
    }
    action f_insert_ipv6_header(bit<8> proto) {
        /* Fill in all fields except payloadLen, srcAddr, and dstAddr,
         * which will be filled in by later table actions. */
        hdr.outer_ipv6.setValid();
        hdr.outer_ipv6.version = 6;
        hdr.outer_ipv6.trafficClass = 0;
        hdr.outer_ipv6.flowLabel = 0;
        //hdr.outer_ipv6.payloadLen = filled_in_later;
        hdr.outer_ipv6.nextHdr = proto;
        hdr.outer_ipv6.hopLimit = 64;
        //hdr.outer_ipv6.srcAddr = filled_in_later;
        //hdr.outer_ipv6.dstAddr = filled_in_later;
    }
    action ipv6_gre_rewrite() {
        f_insert_gre_header();
        hdr.outer_gre.proto = hdr.ethernet.etherType;
        f_insert_ipv6_header(IP_PROTOCOLS_GRE);
        /* 4 is size in bytes of outer_gre header.  IPv6 payloadLen
         * does not include the length of the IPv6 header itself. */
        hdr.outer_ipv6.payloadLen = meta.egress_metadata.payload_length + 4;
        hdr.outer_ethernet.setValid();
        hdr.outer_ethernet.etherType = ETHERTYPE_IPV6;
    }
    action ipv6_ip_rewrite() {
        f_insert_ipv6_header(meta.tunnel.inner_ip_proto);
        hdr.outer_ipv6.payloadLen = meta.egress_metadata.payload_length;
        hdr.outer_ethernet.setValid();
        hdr.outer_ethernet.etherType = ETHERTYPE_IPV6;
    }
    action add_generic_20_byte_header(bit<16> etherType,
                                      bit<32> word0, bit<32> word1,
                                      bit<32> word2, bit<32> word3,
                                      bit<32> word4) {
        hdr.outer_ethernet.setValid();
        hdr.outer_ethernet.etherType = etherType;
        hdr.generic_20_byte_hdr.setValid();
        hdr.generic_20_byte_hdr.word0 = word0;
        hdr.generic_20_byte_hdr.word1 = word1;
        hdr.generic_20_byte_hdr.word2 = word2;
        hdr.generic_20_byte_hdr.word3 = word3;
        hdr.generic_20_byte_hdr.word4 = word4;
    }
    action add_generic_28_byte_header(bit<16> etherType,
                                      bit<32> word0, bit<32> word1,
                                      bit<32> word2, bit<32> word3,
                                      bit<32> word4, bit<32> word5,
                                      bit<32> word6) {
        hdr.outer_ethernet.setValid();
        hdr.outer_ethernet.etherType = etherType;
        hdr.generic_28_byte_hdr.setValid();
        hdr.generic_28_byte_hdr.word0 = word0;
        hdr.generic_28_byte_hdr.word1 = word1;
        hdr.generic_28_byte_hdr.word2 = word2;
        hdr.generic_28_byte_hdr.word3 = word3;
        hdr.generic_28_byte_hdr.word4 = word4;
        hdr.generic_28_byte_hdr.word5 = word5;
        hdr.generic_28_byte_hdr.word6 = word6;
    }
    action add_generic_40_byte_header(bit<16> etherType,
                                      bit<32> word0, bit<32> word1,
                                      bit<32> word2, bit<32> word3,
                                      bit<32> word4, bit<32> word5,
                                      bit<32> word6, bit<32> word7,
                                      bit<32> word8, bit<32> word9) {
        hdr.outer_ethernet.setValid();
        hdr.outer_ethernet.etherType = etherType;
        hdr.generic_40_byte_hdr.setValid();
        hdr.generic_40_byte_hdr.word0 = word0;
        hdr.generic_40_byte_hdr.word1 = word1;
        hdr.generic_40_byte_hdr.word2 = word2;
        hdr.generic_40_byte_hdr.word3 = word3;
        hdr.generic_40_byte_hdr.word4 = word4;
        hdr.generic_40_byte_hdr.word5 = word5;
        hdr.generic_40_byte_hdr.word6 = word6;
        hdr.generic_40_byte_hdr.word7 = word7;
        hdr.generic_40_byte_hdr.word8 = word8;
        hdr.generic_40_byte_hdr.word9 = word9;
    }
    table tunnel_encap_process_outer {
        key = {
            meta.tunnel.egress_tunnel_type : exact;
            meta.tunnel.egress_header_count: exact;
            meta.multicast.replica         : exact;
        }
        actions = {
            nop;
            ipv4_gre_rewrite;
            ipv4_ip_rewrite;
            ipv6_gre_rewrite;
            ipv6_ip_rewrite;
            add_generic_20_byte_header;
            add_generic_28_byte_header;
            add_generic_40_byte_header;
        }
        size = 1024;
    }
    action set_tunnel_rewrite_details(bit<16> outer_bd, bit<9> smac_idx,
                                      bit<14> dmac_idx, bit<9> sip_index,
                                      bit<14> dip_index) {
        meta.egress_metadata.outer_bd = outer_bd;
        meta.tunnel.tunnel_smac_index = smac_idx;
        meta.tunnel.tunnel_dmac_index = dmac_idx;
        meta.tunnel.tunnel_src_index = sip_index;
        meta.tunnel.tunnel_dst_index = dip_index;
    }
    table tunnel_rewrite {
        key = { meta.tunnel.tunnel_index: exact; }
        actions = { nop; set_tunnel_rewrite_details; }
        size = 1024;
    }
    action tunnel_mtu_check(bit<16> l3_mtu) {
        meta.l3_metadata.l3_mtu_check =
            l3_mtu - meta.egress_metadata.payload_length;
    }
    action tunnel_mtu_miss() { meta.l3_metadata.l3_mtu_check = 0xffff; }
    table tunnel_mtu {
        key = { meta.tunnel.tunnel_index: exact; }
        actions = { tunnel_mtu_check; tunnel_mtu_miss; }
        size = 1024;
    }
    action rewrite_tunnel_ipv4_src(bit<32> ip) { hdr.outer_ipv4.srcAddr = ip; }
    action rewrite_tunnel_ipv6_src(bit<128> ip) { hdr.outer_ipv6.srcAddr = ip; }
    table tunnel_src_rewrite {
        key = { meta.tunnel.tunnel_src_index: exact; }
        actions = { nop; rewrite_tunnel_ipv4_src; rewrite_tunnel_ipv6_src; }
        size = 1024;
    }
    action rewrite_tunnel_ipv4_dst(bit<32> ip) { hdr.outer_ipv4.dstAddr = ip; }
    action rewrite_tunnel_ipv6_dst(bit<128> ip) { hdr.outer_ipv6.dstAddr = ip; }
    table tunnel_dst_rewrite {
        key = { meta.tunnel.tunnel_dst_index: exact; }
        actions = { nop; rewrite_tunnel_ipv4_dst; rewrite_tunnel_ipv6_dst; }
        size = 1024;
    }
    action rewrite_tunnel_smac(bit<48> smac) {
        hdr.outer_ethernet.srcAddr = smac;
    }
    table tunnel_smac_rewrite {
        key = { meta.tunnel.tunnel_smac_index: exact; }
        actions = { nop; rewrite_tunnel_smac; }
        size = 1024;
    }
    action rewrite_tunnel_dmac(bit<48> dmac) {
        hdr.outer_ethernet.dstAddr = dmac;
    }
    table tunnel_dmac_rewrite {
        key = { meta.tunnel.tunnel_dmac_index: exact; }
        actions = { nop; rewrite_tunnel_dmac; }
        size = 1024;
    }
    apply {
        if (meta.tunnel.egress_tunnel_type != EGRESS_TUNNEL_TYPE_FABRIC &&
            meta.tunnel.egress_tunnel_type != EGRESS_TUNNEL_TYPE_CPU)
        {
            /* Store the payload length and type of the packet to be
             * tunnel-encapsulated, in these metadata fields:
             *     meta.egress_metadata.payload_length
             *     meta.tunnel.inner_ip_proto */
            tunnel_encap_process_inner.apply();
        }
        /* For any headers we want to add to the packet, make the
         * outer_* headers valid, and initialize most of their
         * fields. */
        tunnel_encap_process_outer.apply();
        /* Based on the value of meta.tunnel.tunnel_index, determined
         * earlier in the route lookup, retrieve indices into tables
         * that will determine the IP SA, IP DA, Ethernet SA, and
         * Ethernet DA values to write into the new headers made valid
         * above. */
        tunnel_rewrite.apply();
        tunnel_mtu.apply();
        /* Fill in IP SA, IP DA, Ethernet SA, Ethernet DA. */
        tunnel_src_rewrite.apply();
        tunnel_dst_rewrite.apply();
        tunnel_smac_rewrite.apply();
        tunnel_dmac_rewrite.apply();
    }
}

control ingress(inout headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control egress(inout headers hdr,
               inout metadata meta,
               inout standard_metadata_t standard_metadata) {
    apply {
        process_tunnel_encap.apply(hdr, meta, standard_metadata);
    }
}

control DeparserImpl(packet_out packet,
                     in headers hdr) {
    apply {
        packet.emit(hdr.outer_ethernet);
        packet.emit(hdr.outer_vlan_tag_[0]);
        packet.emit(hdr.outer_vlan_tag_[1]);
        packet.emit(hdr.generic_20_byte_hdr);
        packet.emit(hdr.generic_28_byte_hdr);
        packet.emit(hdr.generic_40_byte_hdr);
        packet.emit(hdr.outer_ipv4);
        packet.emit(hdr.outer_ipv6);
        packet.emit(hdr.outer_tcp);
        packet.emit(hdr.outer_udp);
        packet.emit(hdr.outer_gre);

        packet.emit(hdr.ethernet);
        packet.emit(hdr.vlan_tag_[0]);
        packet.emit(hdr.vlan_tag_[1]);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.ipv6);
        packet.emit(hdr.tcp);
        packet.emit(hdr.udp);
        packet.emit(hdr.gre);

        packet.emit(hdr.inner_ipv4);
        packet.emit(hdr.inner_tcp);
        packet.emit(hdr.inner_udp);
        /* Any part of the packet that wasn't parsed as a header in
         * the parser block, is considered part of the payload of the
         * packet (as far as this P4 program is concerned, at least).
         * It is appended after the last emitted header before the
         * packet is transmitted out of the system. */
    }
}

control verifyChecksum(inout headers hdr,
                       inout metadata meta) {
    apply {
        verify_checksum(hdr.inner_ipv4.isValid() && hdr.inner_ipv4.ihl == 5,
            { hdr.inner_ipv4.version,
                hdr.inner_ipv4.ihl,
                hdr.inner_ipv4.diffserv,
                hdr.inner_ipv4.totalLen,
                hdr.inner_ipv4.identification,
                hdr.inner_ipv4.flags,
                hdr.inner_ipv4.fragOffset,
                hdr.inner_ipv4.ttl,
                hdr.inner_ipv4.protocol,
                hdr.inner_ipv4.srcAddr,
                hdr.inner_ipv4.dstAddr },
            hdr.inner_ipv4.hdrChecksum, HashAlgorithm.csum16);
        verify_checksum(hdr.ipv4.isValid() && hdr.ipv4.ihl == 5,
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
                hdr.ipv4.dstAddr },
            hdr.ipv4.hdrChecksum, HashAlgorithm.csum16);
    }
}

control computeChecksum(inout headers hdr,
                        inout metadata meta) {
    apply {
        update_checksum(hdr.inner_ipv4.isValid() && hdr.inner_ipv4.ihl == 5,
            { hdr.inner_ipv4.version,
                hdr.inner_ipv4.ihl,
                hdr.inner_ipv4.diffserv,
                hdr.inner_ipv4.totalLen,
                hdr.inner_ipv4.identification,
                hdr.inner_ipv4.flags,
                hdr.inner_ipv4.fragOffset,
                hdr.inner_ipv4.ttl,
                hdr.inner_ipv4.protocol,
                hdr.inner_ipv4.srcAddr,
                hdr.inner_ipv4.dstAddr },
            hdr.inner_ipv4.hdrChecksum, HashAlgorithm.csum16);
        update_checksum(hdr.ipv4.isValid() && hdr.ipv4.ihl == 5,
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
                hdr.ipv4.dstAddr },
            hdr.ipv4.hdrChecksum, HashAlgorithm.csum16);
        update_checksum(hdr.outer_ipv4.isValid() && hdr.outer_ipv4.ihl == 5,
            { hdr.outer_ipv4.version,
                hdr.outer_ipv4.ihl,
                hdr.outer_ipv4.diffserv,
                hdr.outer_ipv4.totalLen,
                hdr.outer_ipv4.identification,
                hdr.outer_ipv4.flags,
                hdr.outer_ipv4.fragOffset,
                hdr.outer_ipv4.ttl,
                hdr.outer_ipv4.protocol,
                hdr.outer_ipv4.srcAddr,
                hdr.outer_ipv4.dstAddr },
            hdr.outer_ipv4.hdrChecksum, HashAlgorithm.csum16);
    }
}

V1Switch(ParserImpl(),
         verifyChecksum(),
         ingress(),
         egress(),
         computeChecksum(),
         DeparserImpl()) main;
