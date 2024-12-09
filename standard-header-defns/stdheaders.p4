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

// Some typical ether_types
const bit<16> ETHERTYPE_MAC    = 0x6558;
const bit<16> ETHERTYPE_IPV4   = 0x0800;
const bit<16> ETHERTYPE_ARP    = 0x0806;
const bit<16> ETHERTYPE_IPV6   = 0x86DD;

header ethernet_t
{
    mac_address_t dst_addr;
    mac_address_t src_addr;
    bit<16>       ether_type;
}

header vlan_tag_t {
    bit<3>     pcp;         
    bit<1>     dei;         
    vlan_id_t  vlan_id;  
    bit<16>    ether_type;
}

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

header_union ip_t {
  ipv4_t v4;
  ipv6_t v6;
}

header mpls_t {
    bit<20> label;
    bit<3>  tc;
    bit<1>  bos;
    bit<8>  ttl;
}

header icmp_t {
    bit<8>  type;
    bit<8>  code;
    bit<16> checksum;
    // ICMP payload is not parsed
}

header udp_t {
    bit<16> src_port;
    bit<16> dst_port;
    bit<16> length;
    bit<16> checksum;
}

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

header vxlan_t {
    bit<8>  flags;
    bit<24> reserved;
    bit<24> vni;
    bit<8>  reserved2;
}

header vxlan_gpe_t {
    bit<8>  flags;
    bit<16> reserved;
    bit<8>  next_proto;
    bit<24> vni;
    bit<8>  reserved2;
}

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
