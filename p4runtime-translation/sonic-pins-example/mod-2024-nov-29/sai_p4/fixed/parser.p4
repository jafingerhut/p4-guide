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

#ifndef SAI_PARSER_P4_
#define SAI_PARSER_P4_

#include <v1model.p4>
#include "headers.p4"
#include "ids.h"
#include "metadata.p4"

parser packet_parser(packet_in packet, out headers_t headers,
                     inout local_metadata_t local_metadata,
                     inout standard_metadata_t standard_metadata) {
  state start {
    // Initialize local metadata fields.
    local_metadata.enable_vlan_checks = false;
    local_metadata.vlan_id = 0;
    local_metadata.admit_to_l3 = false;
    local_metadata.vrf_id = kDefaultVrf;
    local_metadata.enable_decrement_ttl = false;
    local_metadata.enable_src_mac_rewrite = false;
    local_metadata.enable_dst_mac_rewrite = false;
    local_metadata.enable_vlan_rewrite = false;
    local_metadata.packet_rewrites.src_mac = 0;
    local_metadata.packet_rewrites.dst_mac = 0;
    local_metadata.l4_src_port = 0;
    local_metadata.l4_dst_port = 0;
    local_metadata.wcmp_selector_input = 0;
    local_metadata.apply_tunnel_decap_at_end_of_pre_ingress = false;
    local_metadata.apply_tunnel_encap_at_egress = false;
    local_metadata.tunnel_encap_src_ipv6 = 0;
    local_metadata.tunnel_encap_dst_ipv6 = 0;
    local_metadata.marked_to_copy = false;
    local_metadata.marked_to_mirror = false;
    local_metadata.mirror_session_id = 0;
    local_metadata.mirror_egress_port = 0;
    local_metadata.color = MeterColor_t.GREEN;
    local_metadata.ingress_port = (port_id_t)standard_metadata.ingress_port;
    local_metadata.route_metadata = 0;
    local_metadata.bypass_ingress = false;
    local_metadata.wcmp_group_id_valid = false;
    local_metadata.wcmp_group_id_value = 0;
    local_metadata.nexthop_id_valid = false;
    local_metadata.nexthop_id_value = 0;
    local_metadata.ipmc_table_hit = false;
    local_metadata.acl_drop = false;

  transition select(standard_metadata.ingress_port) {
      SAI_P4_CPU_PORT: parse_packet_out_header;
      _              : parse_ethernet;
    }
  }

  state parse_packet_out_header {
    packet.extract(headers.packet_out_header);
    transition parse_ethernet;
  }

  state parse_ethernet {
    packet.extract(headers.ethernet);
    transition select(headers.ethernet.ether_type) {
      ETHERTYPE_IPV4: parse_ipv4;
      ETHERTYPE_IPV6: parse_ipv6;
      ETHERTYPE_ARP:  parse_arp;
      // TODO: Parse 802.1Q VLAN-tagged packets correctly.
      _:              accept;
    }
  }

  state parse_ipv4 {
    packet.extract(headers.ipv4);
    transition select(headers.ipv4.protocol) {
      IP_PROTOCOL_IPV4: parse_ipv4_in_ip;
      IP_PROTOCOL_IPV6: parse_ipv6_in_ip;
      IP_PROTOCOL_ICMP: parse_icmp;
      IP_PROTOCOL_TCP:  parse_tcp;
      IP_PROTOCOL_UDP:  parse_udp;
      _:                accept;
    }
  }

  state parse_ipv4_in_ip {
    packet.extract(headers.inner_ipv4);
    transition select(headers.inner_ipv4.protocol) {
      IP_PROTOCOL_ICMP: parse_icmp;
      IP_PROTOCOL_TCP:  parse_tcp;
      IP_PROTOCOL_UDP:  parse_udp;
      _:                accept;
    }
  }

  state parse_ipv6 {
    packet.extract(headers.ipv6);
    transition select(headers.ipv6.next_header) {
      IP_PROTOCOL_IPV4: parse_ipv4_in_ip;
      IP_PROTOCOL_IPV6: parse_ipv6_in_ip;
      IP_PROTOCOL_ICMPV6: parse_icmp;
      IP_PROTOCOL_TCP:    parse_tcp;
      IP_PROTOCOL_UDP:    parse_udp;
      _:                  accept;
    }
  }

  state parse_ipv6_in_ip {
    packet.extract(headers.inner_ipv6);
    transition select(headers.inner_ipv6.next_header) {
      IP_PROTOCOL_ICMPV6: parse_icmp;
      IP_PROTOCOL_TCP:    parse_tcp;
      IP_PROTOCOL_UDP:    parse_udp;
      _:                  accept;
    }
  }

  state parse_tcp {
    packet.extract(headers.tcp);
    // Normalize TCP port metadata to common port metadata.
    local_metadata.l4_src_port = headers.tcp.src_port;
    local_metadata.l4_dst_port = headers.tcp.dst_port;
    transition accept;
  }

  state parse_udp {
    packet.extract(headers.udp);
    // Normalize UDP port metadata to common port metadata.
    local_metadata.l4_src_port = headers.udp.src_port;
    local_metadata.l4_dst_port = headers.udp.dst_port;
    transition accept;
  }

  state parse_icmp {
    packet.extract(headers.icmp);
    transition accept;
  }

  state parse_arp {
    packet.extract(headers.arp);
    transition accept;
  }
}  // parser packet_parser

control packet_deparser(packet_out packet, in headers_t headers) {
  apply {
    // We always expect the packet_out_header to be invalid at the end of the
    // pipeline, so this line has no effect on the output packet.
    packet.emit(headers.packet_out_header);
// TODO: Clean up once we have better solution to handle packet-in
// across platforms.
#if defined(PLATFORM_BMV2) || defined(PLATFORM_P4SYMBOLIC)
    packet.emit(headers.packet_in_header);
#endif
    packet.emit(headers.mirror_encap_ethernet);
    packet.emit(headers.mirror_encap_vlan);
    packet.emit(headers.mirror_encap_ipv6);
    packet.emit(headers.mirror_encap_udp);
    packet.emit(headers.ipfix);
    packet.emit(headers.psamp_extended);
    packet.emit(headers.ethernet);
    packet.emit(headers.tunnel_encap_ipv6);
    packet.emit(headers.tunnel_encap_gre);
    packet.emit(headers.ipv4);
    packet.emit(headers.ipv6);
    packet.emit(headers.inner_ipv4);
    packet.emit(headers.inner_ipv6);
    packet.emit(headers.arp);
    packet.emit(headers.icmp);
    packet.emit(headers.tcp);
    packet.emit(headers.udp);
  }
}  // control packet_deparser

#endif  // SAI_PARSER_P4_
