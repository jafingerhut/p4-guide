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

#ifndef SAI_ACL_EGRESS_P4_
#define SAI_ACL_EGRESS_P4_

#include <v1model.p4>
#include "../../fixed/headers.p4"
#include "../../fixed/metadata.p4"
#include "acl_common_actions.p4"
#include "ids.h"
#include "minimum_guaranteed_sizes.p4"
#include "roles.h"

control acl_egress(in headers_t headers,
                    inout local_metadata_t local_metadata,
                    inout standard_metadata_t standard_metadata) {
  // First 6 bits of IPv4 TOS or IPv6 traffic class (or 0, for non-IP packets)
  bit<6> dscp = 0;
  // IPv4 IP protocol or IPv6 next_header (or 0, for non-IP packets)
  bit<8> ip_protocol = 0;

  @id(ACL_EGRESS_COUNTER_ID)
  direct_counter(CounterType.packets_and_bytes) acl_egress_counter;

  @id(ACL_EGRESS_DHCP_TO_HOST_COUNTER_ID)
  direct_counter(CounterType.packets_and_bytes) acl_egress_dhcp_to_host_counter;

  // A forwarding action specific to the egress pipeline.
  @id(ACL_EGRESS_FORWARD_ACTION_ID)
  @sai_action(SAI_PACKET_ACTION_FORWARD)
  action acl_egress_forward() {
    acl_egress_counter.count();
  }

  @p4runtime_role(P4RUNTIME_ROLE_SDN_CONTROLLER)
  @id(ACL_EGRESS_TABLE_ID)
  @sai_acl(EGRESS)
  @entry_restriction("
#ifdef SAI_INSTANTIATION_FABRIC_BORDER_ROUTER
    // Forbid using ether_type for IP packets (by convention, use is_ip* instead).
    ether_type != 0x0800 && ether_type != 0x86dd;
    dscp::mask != 0 -> (is_ip == 1 || is_ipv4 == 1 || is_ipv6 == 1);
#endif
    // Only allow IP field matches for IP packets.
    ip_protocol::mask != 0 -> (is_ip == 1 || is_ipv4 == 1 || is_ipv6 == 1);
#if defined(SAI_INSTANTIATION_TOR) 
    dst_ipv6::mask != 0 -> is_ipv6 == 1;
#endif
#ifdef SAI_INSTANTIATION_FABRIC_BORDER_ROUTER
    // Only allow l4_dst_port matches for TCP/UDP packets.
    l4_dst_port::mask != 0 -> (ip_protocol == 6 || ip_protocol == 17);
#endif
    // Forbid illegal combinations of IP_TYPE fields.
    is_ip::mask != 0 -> (is_ipv4::mask == 0 && is_ipv6::mask == 0);
    is_ipv4::mask != 0 -> (is_ip::mask == 0 && is_ipv6::mask == 0);
    is_ipv6::mask != 0 -> (is_ip::mask == 0 && is_ipv4::mask == 0);
    // Forbid unsupported combinations of IP_TYPE fields.
    is_ipv4::mask != 0 -> (is_ipv4 == 1);
    is_ipv6::mask != 0 -> (is_ipv6 == 1);
  ")
  table acl_egress_table {
    key = {
#ifdef SAI_INSTANTIATION_FABRIC_BORDER_ROUTER
      headers.ethernet.ether_type : ternary @name("ether_type") @id(1)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_ETHER_TYPE);
#endif
      ip_protocol : ternary @name("ip_protocol") @id(2)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_IP_PROTOCOL);
#ifdef SAI_INSTANTIATION_FABRIC_BORDER_ROUTER
      local_metadata.l4_dst_port : ternary @name("l4_dst_port") @id(3)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_L4_DST_PORT);
#endif
      (port_id_t)standard_metadata.egress_port: optional @name("out_port")
          @id(4) @sai_field(SAI_ACL_TABLE_ATTR_FIELD_OUT_PORT);
      headers.ipv4.isValid() || headers.ipv6.isValid() : optional @name("is_ip")
          @id(5) @sai_field(SAI_ACL_TABLE_ATTR_FIELD_ACL_IP_TYPE/IP);
      headers.ipv4.isValid() : optional @name("is_ipv4") @id(6)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_ACL_IP_TYPE/IPV4ANY);
      headers.ipv6.isValid() : optional @name("is_ipv6") @id(7)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_ACL_IP_TYPE/IPV6ANY);
#ifdef SAI_INSTANTIATION_FABRIC_BORDER_ROUTER
      // Field for v4 and v6 DSCP bits.
      dscp : ternary @name("dscp") @id(8)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_DSCP);
#endif
#if defined(SAI_INSTANTIATION_TOR) 
      ((bit<128>) headers.ipv6.dst_addr)[127:64] : ternary @name("dst_ipv6") @id(9)
          @composite_field(
              @sai_field(SAI_ACL_TABLE_ATTR_FIELD_DST_IPV6_WORD3),
              @sai_field(SAI_ACL_TABLE_ATTR_FIELD_DST_IPV6_WORD2)
          ) @format(IPV6_ADDRESS);
#endif
#if defined(SAI_INSTANTIATION_TOR) || defined(SAI_INSTANTIATION_MIDDLEBLOCK)
      headers.ethernet.src_addr : ternary @name("src_mac") @id(10)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_SRC_MAC) @format(MAC_ADDRESS);
#endif
    }
    actions = {
      @proto_id(1) acl_drop(local_metadata);
#if defined(SAI_INSTANTIATION_TOR) 
      @proto_id(2) acl_egress_forward();
#endif
      @defaultonly NoAction;
    }
    const default_action = NoAction;
    counters = acl_egress_counter;
    size = ACL_EGRESS_TABLE_MINIMUM_GUARANTEED_SIZE;
  }

  @id(ACL_EGRESS_DHCP_TO_HOST_TABLE_ID)
  @sai_acl(EGRESS)
  @p4runtime_role(P4RUNTIME_ROLE_SDN_CONTROLLER)
  @entry_restriction("
    // Only allow IP field matches for IP packets.
    ip_protocol::mask != 0 -> (is_ip == 1 || is_ipv4 == 1 || is_ipv6 == 1);
    // Only allow l4_dst_port matches for TCP/UDP packets.
    l4_dst_port::mask != 0 -> (ip_protocol == 6 || ip_protocol == 17);
    // Forbid illegal combinations of IP_TYPE fields.
    is_ip::mask != 0 -> (is_ipv4::mask == 0 && is_ipv6::mask == 0);
    is_ipv4::mask != 0 -> (is_ip::mask == 0 && is_ipv6::mask == 0);
    is_ipv6::mask != 0 -> (is_ip::mask == 0 && is_ipv4::mask == 0);
    // Forbid unsupported combinations of IP_TYPE fields.
    is_ipv4::mask != 0 -> (is_ipv4 == 1);
    is_ipv6::mask != 0 -> (is_ipv6 == 1);
  ")
  table acl_egress_dhcp_to_host_table {
    key = {
      headers.ipv4.isValid() || headers.ipv6.isValid() : optional
          @id(1) @name("is_ip")
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_ACL_IP_TYPE/IP);
      headers.ipv4.isValid() : optional
          @id(2) @name("is_ipv4")
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_ACL_IP_TYPE/IPV4ANY);
      headers.ipv6.isValid() : optional
          @id(3) @name("is_ipv6")
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_ACL_IP_TYPE/IPV6ANY);
      ip_protocol : ternary
          @id(5) @name("ip_protocol")
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_IP_PROTOCOL);
      local_metadata.l4_dst_port : ternary
          @id(6) @name("l4_dst_port")
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_L4_DST_PORT);
      (port_id_t)standard_metadata.egress_port: optional
          @id(7) @name("out_port")
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_OUT_PORT);
    }
    actions = {
      @proto_id(1) acl_drop(local_metadata);
      @defaultonly NoAction;
    }
    const default_action = NoAction;
    counters = acl_egress_dhcp_to_host_counter;
    size = ACL_EGRESS_TABLE_MINIMUM_GUARANTEED_SIZE;
  }

  apply {
    // We configure the hardware to explictly ignore the ACL egress tables for
    // CPU traffic.
    if (standard_metadata.egress_port != SAI_P4_CPU_PORT) {
      if (headers.ipv4.isValid()) {
        dscp = headers.ipv4.dscp;
        ip_protocol = headers.ipv4.protocol;
      } else if (headers.ipv6.isValid()) {
        dscp = headers.ipv6.dscp;
        ip_protocol = headers.ipv6.next_header;
      } else {
        ip_protocol = 0;
      }

      acl_egress_table.apply();
#if defined(SAI_INSTANTIATION_TOR)
      acl_egress_dhcp_to_host_table.apply();
#endif
    // Act on ACL drop metadata.
      if (local_metadata.acl_drop) {
        mark_to_drop(standard_metadata);
      }
    }
  }
}  // control ACL_EGRESS

#endif  // SAI_ACL_EGRESS_P4_
