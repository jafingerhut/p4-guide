/*
Copyright 2013-2020 Barefoot Networks, Inc. 
Copyright 2020-2022 Intel Corporation

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

#ifndef _STDHEADERS_P4_
#define _STDHEADERS_P4_

#include "etype.p4"
#include "ipproto.p4"

typedef bit<48>  EthernetAddress;
typedef bit<32>  IPv4Address;
typedef bit<128> IPv6Address;

// https://en.wikipedia.org/wiki/Ethernet_frame
header ethernet_h {
    EthernetAddress dst_addr;
    EthernetAddress src_addr;
    etype_t ether_type;
}

// https://en.wikipedia.org/wiki/IEEE_802.1Q
header vlan_tag_h {
    bit<3>  pcp;    // priority code point
    bit<1>  dei;    // drop eligible indicator.
                    // Formerly CFI - canonical format indicator
    bit<12> vid;    // VLAN identifier
    etype_t ether_type;
}

// RFC 3031 and several later RFCs with addenda and errata
// https://en.wikipedia.org/wiki/Multiprotocol_Label_Switching
// https://tools.ietf.org/html/rfc3031
header mpls_h {
    bit<20> label;
    bit<3>  tc;   // traffic class.  Formerly EXP (before 2009, RFC 5462)
    bit<1>  bos;  // bottom of stack
    bit<8>  ttl;  // time to live
}

// RFC 791
// https://en.wikipedia.org/wiki/IPv4
// https://tools.ietf.org/html/rfc791
header ipv4_h {
    bit<4>  version;            // always 4 for IPv4
    bit<4>  ihl;                // Internet header length
    bit<8>  diffserv;           // 6 bits of DSCP followed by 2-bit ECN
    bit<16> total_len;          // in bytes, including IPv4 header
    bit<16> identification;
    bit<3>  flags;              // rsvd:1, DF (don't fragment):1,
                                // MF (more fragments):1
    bit<13> frag_offset;
    bit<8>  ttl;                // time to live
    ipproto_t protocol;
    bit<16> hdr_checksum;
    IPv4Address src_addr;
    IPv4Address dst_addr;
}

// Formerly RFC 2460 and errata, combined into RFC 8200 as of 2017
// https://en.wikipedia.org/wiki/IPv6
// https://tools.ietf.org/html/rfc8200
header ipv6_h {
    bit<4>  version;
    bit<8>  traffic_class;
    bit<20> flow_label;
    bit<16> payload_len;
    ipproto_t next_hdr;
    bit<8>  hop_limit;
    IPv6Address src_addr;
    IPv6Address dst_addr;
}

// Segment Routing Extension (SRH) -- IETFv7
header ipv6_srh_h {
    ipproto_t next_hdr;
    bit<8>  hdr_ext_len;
    bit<8>  routing_type;
    bit<8>  seg_left;
    bit<8>  last_entry;
    bit<8>  flags;
    bit<16> tag;
}

// Address Resolution Protocol -- RFC 6747
// https://tools.ietf.org/html/rfc6747
header arp_h {
    // TODO: Is etype_t an accurate type for field hw_type?
    bit<16> hw_type;
    // TODO: Is etype_t an accurate type for field proto_type?
    bit<16> proto_type;
    bit<8>  hw_addr_len;
    bit<8>  proto_addr_len;
    bit<16> opcode;
    // ...
}

header arp_rarp_ipv4_h {
    bit<48> src_hw_addr;
    IPv4Address src_proto_addr;
    bit<48> dst_hw_addr;
    IPv4Address dst_proto_addr;
}

// RFC 792, updated by several other later RFCs
// https://en.wikipedia.org/wiki/Internet_Control_Message_Protocol
// https://tools.ietf.org/html/rfc792
header icmp_h {
    bit<8>  type;
    bit<8>  code;
    bit<16> checksum;
    // ICMP Payload follows, but not parsing
}

// RFC 768
// https://en.wikipedia.org/wiki/User_Datagram_Protocol
// https://tools.ietf.org/html/rfc768
header udp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<16> length;
    bit<16> checksum;
}

// RFC 793 and several later RFCs that update it
// https://en.wikipedia.org/wiki/Transmission_Control_Protocol
// https://tools.ietf.org/html/rfc793
header tcp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<32> seq_no;
    bit<32> ack_no;
    bit<4>  data_offset;
    bit<4>  res;
    bit<8>  flags;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgent_ptr;
}

header sctp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<32> verif_tag;
    bit<32> checksum;
}

// IGMPv1 in RFC 1112
// IGMPv2 in RFC 2236
// IGMPv3 in RFC 3376
// https://en.wikipedia.org/wiki/Internet_Group_Management_Protocol
// https://tools.ietf.org/html/rfc1112
// https://tools.ietf.org/html/rfc2236
// https://tools.ietf.org/html/rfc3376
// Fixed-length and fixed-format beginning has some similarities
// between the different versions of IGMP
header igmp_h {
    bit<8>  type;
    bit<8>  code;
    bit<16> checksum;
    // ...
}

// VXLAN -- RFC 7348
// https://en.wikipedia.org/wiki/Virtual_Extensible_LAN
// https://tools.ietf.org/html/rfc7348
header vxlan_h {
    bit<8>  flags;
    bit<24> reserved;
    bit<24> vni;
    bit<8>  reserved2;
}

// Generic Protocol Extension for VXLAN -- IETFv4
// https://datatracker.ietf.org/doc/draft-ietf-nvo3-vxlan-gpe/
header vxlan_gpe_h {
    bit<8>  flags;
    bit<16> reserved;
    // TODO: Is ipproto_t an accurate type for field next_proto?
    bit<8>  next_proto;
    bit<24> vni;
    bit<8>  reserved2;
}

// Generic Routing Encapsulation (GRE)
// RFC 1701 was obsoleted by RFC 2784 and RFC 2890
// https://en.wikipedia.org/wiki/Generic_Routing_Encapsulation
// https://tools.ietf.org/html/rfc1701
// https://tools.ietf.org/html/rfc2784
// https://tools.ietf.org/html/rfc2890
header gre_h {
    bit<1>  C;
    bit<12> reserved0;
    bit<3>  version;
    // TODO: Is etype_t an accurate type for field proto?
    bit<16> proto;
    // Omit variable length portions.
}

// Network Virtualisation using GRE (NVGRE) -- RFC 7637
// https://tools.ietf.org/html/rfc7637
header nvgre_h {
    bit<24> vsid;
    bit<8>  flow_id;
}

// RFC 8926 "Geneve: Generic Network Virtualization Encapsulation"
// 3 possible options with known type, known length.

header geneve_h {
    bit<2>  version;
    bit<6>  opt_len;
    bit<1>  oam;
    bit<1>  critical;
    bit<6>  reserved;
    // TODO: Is etype_t an accurate type for field proto_type?
    bit<16> proto_type;
    bit<24> vni;
    bit<8>  reserved2;
}

#define GENEVE_OPTION_A_TYPE 0x000001
/* TODO: Would it be convenient to have some kind of sizeof macro ? */
#define GENEVE_OPTION_A_LENGTH 2 /* in bytes */

header geneve_opt_a_h {
    bit<16> opt_class;
    bit<8>  opt_type;
    bit<3>  reserved;
    bit<5>  opt_len;
    bit<32> dt;
}

#define GENEVE_OPTION_B_TYPE 0x000002
#define GENEVE_OPTION_B_LENGTH 3 /* in bytes */

header geneve_opt_b_h {
    bit<16> opt_class;
    bit<8>  opt_type;
    bit<3>  reserved;
    bit<5>  opt_len;
    bit<64> dt;
}

#define GENEVE_OPTION_C_TYPE 0x000003
#define GENEVE_OPTION_C_LENGTH 2 /* in bytes */

header geneve_opt_c_h {
    bit<16> opt_class;
    bit<8>  opt_type;
    bit<3>  reserved;
    bit<5>  opt_len;
    bit<32> dt;
}

/* 8 bytes */
header erspan_header_v1_h {
    bit<4>  version;
    bit<12> vlan;
    bit<6>  priority;
    bit<10> span_id;
    bit<8>  direction;
    bit<8>  truncated;
}

/* 8 bytes */
header erspan_header_v2_h {
    bit<4>  version;
    bit<12> vlan;
    bit<6>  priority;
    bit<10> span_id;
    bit<32> unknown7;
}

header ipsec_esp_h {
    bit<32> spi;
    bit<32> seq_no;
}

header ipsec_ah_h {
    ipproto_t next_hdr;
    bit<8>  length;
    bit<16> zero;
    bit<32> spi;
    bit<32> seq_no;
}

header eompls_h {
    bit<4>  zero;
    bit<12> reserved;
    bit<16> seq_no;
}

// RFC 8300 "Network Service Header (NSH)"

header nsh_h {
    bit<1>  oam;
    bit<1>  context;
    bit<6>  flags;
    bit<8>  reserved;
    // TODO: Is etype_t an accurate type for field proto_type?
    bit<16> proto_type;
    bit<24> spath;
    bit<8>  sindex;
}

header nsh_context_h {
    bit<32> network_platform;
    bit<32> network_shared;
    bit<32> service_platform;
    bit<32> service_shared;
}
#endif  // _STDHEADERS_P4_
