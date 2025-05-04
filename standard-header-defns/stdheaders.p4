// SPDX-License-Identifier: Apache-2.0

// Copyright 2021 Alan Lo (loa.alan@gmail.com)
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

// Some common field types
typedef bit<48>   mac_address_t;
typedef bit<12>   vlan_id_t;
typedef bit<32>   ipv4_address_t;
typedef bit<128>  ipv6_address_t;
typedef bit<24>   vni_t;

// Some typical ether_types from IANA RFC9542
const bit<16> ETHERTYPE_MAC            = 0x6558;
const bit<16> ETHERTYPE_IPV4           = 0x0800;
const bit<16> ETHERTYPE_ARP            = 0x0806;
const bit<16> ETHERTYPE_IPV6           = 0x86DD;
const bit<16> ETHERTYPE_MPLS_UCAST     = 0x8847;
const bit<16> ETHERTYPE_MPLS_MCAST     = 0x8848;
const bit<16> ETHERTYPE_PPOE_D         = 0x8863;
const bit<16> ETHERTYPE_PPOE_S         = 0x8864;
const bit<16> ETHERTYPE_VLAN           = 0x8100;
const bit<16> ETHERTYPE_VLACP          = 0x8103;
const bit<16> ETHERTYPE_PTP            = 0x88F7;
const bit<16> ETHERTYPE_CFM            = 0x8902;
const bit<16> ETHERTYPE_RoCE           = 0x8915;



// Some typical IP protocols from IANA RFC5237 RFC7045
// In IPv4 there is a field called "Protocol" to identify the next level protocol.  
// In IPv6 this field  is called the "Next Header" field.

const bit<8>  IP_PROTOCOL_ICMP         = 1;
const bit<8>  IP_PROTOCOL_IGMP         = 2;
const bit<8>  IP_PROTOCOL_IPv4         = 4;
const bit<8>  IP_PROTOCOL_TCP          = 6;
const bit<8>  IP_PROTOCOL_UDP          = 17;
const bit<8>  IP_PROTOCOL_IPv6         = 41;
const bit<8>  IP_PROTOCOL_IPv6_ICMP    = 48;
const bit<8>  IP_PROTOCOL_IPIP         = 94;
const bit<8>  IP_PROTOCOL_PTP          = 123;
const bit<8>  IP_PROTOCOL_MPLS_in_IP   = 137;

// Ethernet from IEEE 802.3
header ethernet_t
{
    mac_address_t dst_addr;
    mac_address_t src_addr;
    bit<16>       ether_type;
}

// Virtual LAN from IEEE 802.1
header vlan_tag_t {
    bit<3>     pcp;         
    bit<1>     dei;         
    vlan_id_t  vlan_id;  
    bit<16>    ether_type;
}

// Internet Protocol, Version 4 (IPv4) from IETF RFC3927
header ipv4_t {
    bit<4>      version;
    bit<4>      ihl;
    bit<8>      diffserv;
    bit<16>     total_length;
    bit<16>     identification;
    bit<3>      flags;
    bit<13>     frag_offset;
    bit<8>      ttl;
    bit<8>      protocol;
    bit<16>     header_checksum;
    ipv4_address_t src_addr;
    ipv4_address_t dst_addr;
}

header ipv4_option_t {
    bit<8>   type;
    bit<8>   length;
    bit<16>  value;
}

// Internet Protocol, Version 6 (IPv6) from IETF RFC8200
header ipv6_t {
    bit<4>       version;
    bit<8>       traffic_class;
    bit<20>      flow_label;
    bit<16>      payload_length;
    bit<8>       next_header;
    bit<8>       hop_limit;
    ipv6_address_t  src_addr;
    ipv6_address_t  dst_addr;
}

// Internet Protocol Security (IPsec) from IETF RFC6071
header ipsec_t {
    bit<8>       next_header;
    bit<8>       payload_length;
    bit<16>      reserved;
    bit<16>      payload_length;
    bit<32>      spi; //Security Parameters Index;
    bit<32>      sequence_number;
}


header_union ip_t {
  ipv4_t v4;
  ipv6_t v6;
}

// Multiprotocol Label Switching (MPLS) IETF RFC3031
header mpls_t {
    bit<20> label;
    bit<3>  tc;
    bit<1>  bos;
    bit<8>  ttl;
}

// Internet Control Message Protocol (ICMP) from DARPA RFC792
header icmp_t {
    bit<8>  type;
    bit<8>  code;
    bit<16> checksum;
    // ICMP payload is not parsed
}

// User Datagram Protocol (UDP) from IETF RFC768
header udp_t {
    bit<16> src_port;
    bit<16> dst_port;
    bit<16> length;
    bit<16> checksum;
}

// Transmission Control Protocol( TCP) from IETF RFC791 and RFC793
header tcp_t {
    bit<16> src_port;
    bit<16> dst_port;
    bit<32> seq_no;
    bit<32> ack_no;
    bit<4>  data_offset;
    bit<4>  res;
    bit<3>  ecn;
    bit<6>  flags;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgent_ptr;
}

// Virtual Extensible LAN (VXLAN) from IETF RFC 7348
header vxlan_t {
    bit<8>  flags;
    bit<24> reserved;
    bit<24> vni;
    bit<8>  reserved2;
}

// Generic Protocol Extension (GPE) fo Virtual Extensible LAN (VXLAN) from IETF RFC 7348
header vxlan_gpe_t {
    bit<8>  flags;
    bit<16> reserved;
    bit<8>  next_proto;
    bit<24> vni;
    bit<8>  reserved2;
}

// Generic Routing Encapsulation (GRE) from IETF RFC 2784
header gre_t {
    bit<1>  checksum_present;
    bit<1>  routing_present;
    bit<1>  key_present;
    bit<1>  sequence_present;
    bit<1>  strict_source_route;
    bit<3>  recursion_control;
    bit<5>  flags;
    bit<3>  version;
    bit<16> protocol;
}

header nvgre_t {
    bit<24> vsid;
    bit<8> flow_id;
}

// Point-to-Point Over Ethernet (PPPoE) from IANA RFC2516
header pppoe_t {
    bit<4>  version;
    bit<4>  pppoe_type;
    bit<8>  code;
    bit<16> session_id;
    bit<16> length;
}

// Precision Time Protocol (PTP) from IEEE 1588
header ptp_t {
    bit<4>  transport_specifics;
    bit<4>  message_type;
    bit<4>  reserved;
    bit<4>  version;
    bit<8>  message_legth;
    bit<8>  domain_number;
    bit<8>  reserved;
    bit<8>  correction_field;
    bit<8>  reserved;
    bit<8>  source_port_identity;
    bit<8>  sequence_id;
    bit<8>  control_field;
    bit<8>  log_message_interval;
}

// Ethernet Connectivity Fault Management (CFM) 802.1ag
header cfm_t {
    bit<3>  md_levels;
    bit<5>  version;
    bit<8>  op_code;
}

// Internet Group Management Protocol, Version 2 (IGMP) from IETF RFC2236
header igmpv2_t {
    bit<8>  igmp_type;
    bit<8>  maximum_response_time;
    bit<16> checksum;
    bit<32> group_address;
}

// Internet Group Management Protocol, Version 3 (IGMP) from IETF RFC3376
header igmpv3_t {
    bit<8>  igmp_type;
    bit<8>  maximum_response_time;
    bit<16> checksum;
    bit<32> group_address;
    bit<4>  reserved;
    bit<1>  s;    // Suppress Router-side Processing
    bit<3>  qvr;  // Querier's Robustness Variable
    bit<8>  qqic; // Querier's Query Interval Code
    bit<16> number_of_source;
    bit<32> source_address;
}