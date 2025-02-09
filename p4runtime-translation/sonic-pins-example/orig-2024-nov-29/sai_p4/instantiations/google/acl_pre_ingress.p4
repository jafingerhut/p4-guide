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

#ifndef SAI_ACL_PRE_INGRESS_P4_
#define SAI_ACL_PRE_INGRESS_P4_

#include <v1model.p4>
#include "../../fixed/headers.p4"
#include "../../fixed/metadata.p4"
#include "ids.h"
#include "roles.h"
#include "minimum_guaranteed_sizes.p4"

#if defined(SAI_INSTANTIATION_TOR)
#define ACL_PRE_INGRESS_TABLE_MINIMUM_GUARANTEED_SIZE \
  ACL_TOR_PRE_INGRESS_TABLE_MINIMUM_GUARANTEED_SIZE
#else
#define ACL_PRE_INGRESS_TABLE_MINIMUM_GUARANTEED_SIZE \
  ACL_DEFAULT_PRE_INGRESS_TABLE_MINIMUM_GUARANTEED_SIZE
#endif

control acl_pre_ingress(in headers_t headers,
                   inout local_metadata_t local_metadata,
                   in standard_metadata_t standard_metadata) {
  // First 6 bits of IPv4 TOS or IPv6 traffic class (or 0, for non-IP packets)
  bit<6> dscp = 0;
  // Last 2 bits of IPv4 TOS or IPv6 traffic class (or 0, for non-IP packets)
  bit<2> ecn = 0;

  // IPv4 IP protocol or IPv6 next_header (or 0, for non-IP packets)
  bit<8> ip_protocol = 0;

  @id(ACL_PRE_INGRESS_COUNTER_ID)
  direct_counter(CounterType.packets_and_bytes) acl_pre_ingress_counter;

  @id(ACL_PRE_INGRESS_VLAN_COUNTER_ID)
  direct_counter(CounterType.packets_and_bytes) acl_pre_ingress_vlan_counter;

  @id(ACL_PRE_INGRESS_METADATA_COUNTER_ID)
  direct_counter(CounterType.packets_and_bytes) acl_pre_ingress_metadata_counter;

  @id(ACL_PRE_INGRESS_SET_VRF_ACTION_ID)
  @sai_action(SAI_PACKET_ACTION_FORWARD)
  action set_vrf(@sai_action_param(SAI_ACL_ENTRY_ATTR_ACTION_SET_VRF)
                 @refers_to(vrf_table, vrf_id)
                 @id(1)
                 vrf_id_t vrf_id) {
    local_metadata.vrf_id = vrf_id;
    acl_pre_ingress_counter.count();
  }

  @id(ACL_PRE_INGRESS_SET_OUTER_VLAN_ACTION_ID)
  @sai_action(SAI_PACKET_ACTION_FORWARD)
  action set_outer_vlan_id(
      @id(1) @sai_action_param(SAI_ACL_ENTRY_ATTR_ACTION_SET_OUTER_VLAN_ID)
        vlan_id_t vlan_id) {
    local_metadata.vlan_id = vlan_id;
    acl_pre_ingress_vlan_counter.count();
  }

  @id(ACL_PRE_INGRESS_SET_ACL_METADATA_ACTION_ID)
  @sai_action(SAI_PACKET_ACTION_FORWARD)
  action set_acl_metadata(
       @id(1) @sai_action_param(SAI_ACL_ENTRY_ATTR_ACTION_SET_ACL_META_DATA)
         acl_metadata_t acl_metadata) {
    local_metadata.acl_metadata = acl_metadata;
    acl_pre_ingress_metadata_counter.count();
  }

  @p4runtime_role(P4RUNTIME_ROLE_SDN_CONTROLLER)
  @id(ACL_PRE_INGRESS_TABLE_ID)
  @sai_acl(PRE_INGRESS)
  @sai_acl_priority(11)
  @entry_restriction("
    // Only allow IP field matches for IP packets.
    dscp::mask != 0 -> (is_ip == 1 || is_ipv4 == 1 || is_ipv6 == 1);
    ecn::mask != 0 -> (is_ip == 1 || is_ipv4 == 1 || is_ipv6 == 1);
    dst_ip::mask != 0 -> is_ipv4 == 1;
    dst_ipv6::mask != 0 -> is_ipv6 == 1;
    // Forbid illegal combinations of IP_TYPE fields.
    is_ip::mask != 0 -> (is_ipv4::mask == 0 && is_ipv6::mask == 0);
    is_ipv4::mask != 0 -> (is_ip::mask == 0 && is_ipv6::mask == 0);
    is_ipv6::mask != 0 -> (is_ip::mask == 0 && is_ipv4::mask == 0);
    // Forbid unsupported combinations of IP_TYPE fields.
    is_ipv4::mask != 0 -> (is_ipv4 == 1);
    is_ipv6::mask != 0 -> (is_ipv6 == 1);
    // Reserve high priorities for switch-internal use.
    // TODO: Remove once inband workaround is obsolete.
    ::priority < 0x7fffffff;
  ")
  table acl_pre_ingress_table {
    key = {
      headers.ipv4.isValid() || headers.ipv6.isValid() : optional @name("is_ip") @id(1)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_ACL_IP_TYPE/IP);
      headers.ipv4.isValid() : optional @name("is_ipv4") @id(2)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_ACL_IP_TYPE/IPV4ANY);
      headers.ipv6.isValid() : optional @name("is_ipv6") @id(3)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_ACL_IP_TYPE/IPV6ANY);
      headers.ethernet.src_addr : ternary @name("src_mac") @id(4)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_SRC_MAC) @format(MAC_ADDRESS);
#ifdef SAI_INSTANTIATION_FABRIC_BORDER_ROUTER
      headers.ethernet.dst_addr : ternary @name("dst_mac") @id(9)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_DST_MAC) @format(MAC_ADDRESS);
#endif
      headers.ipv4.dst_addr : ternary @name("dst_ip") @id(5)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_DST_IP) @format(IPV4_ADDRESS);
      headers.ipv6.dst_addr[127:64] : ternary @name("dst_ipv6") @id(6)
          @composite_field(
              @sai_field(SAI_ACL_TABLE_ATTR_FIELD_DST_IPV6_WORD3),
              @sai_field(SAI_ACL_TABLE_ATTR_FIELD_DST_IPV6_WORD2)
          ) @format(IPV6_ADDRESS);
      dscp : ternary @name("dscp") @id(7)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_DSCP);
      ecn : ternary @name("ecn") @id(10)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_ECN);
      local_metadata.ingress_port : optional @name("in_port") @id(8)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_IN_PORT);
    }
    actions = {
      @proto_id(1) set_vrf;
      @defaultonly NoAction;
    }
    const default_action = NoAction;
    counters = acl_pre_ingress_counter;
    size = ACL_PRE_INGRESS_TABLE_MINIMUM_GUARANTEED_SIZE;
  }

  @id(ACL_PRE_INGRESS_VLAN_TABLE_ID)
  @sai_acl(PRE_INGRESS)
  @p4runtime_role(P4RUNTIME_ROLE_SDN_CONTROLLER)
  @sai_acl_priority(1)
  @entry_restriction("
    // Forbid using ether_type for IP packets (by convention, use is_ip* instead).
    ether_type != 0x0800 && ether_type != 0x86dd;
    // Forbid illegal combinations of IP_TYPE fields.
    is_ip::mask != 0 -> (is_ipv4::mask == 0 && is_ipv6::mask == 0);
    is_ipv4::mask != 0 -> (is_ip::mask == 0 && is_ipv6::mask == 0);
    is_ipv6::mask != 0 -> (is_ip::mask == 0 && is_ipv4::mask == 0);
    // Forbid unsupported combinations of IP_TYPE fields.
    is_ipv4::mask != 0 -> (is_ipv4 == 1);
    is_ipv6::mask != 0 -> (is_ipv6 == 1);
    // Disallow match on reserved VLAN IDs to rule out vendor specific behavior.
    vlan_id::mask != 0 -> (vlan_id != 4095);
    // TODO: Disallow setting to reserved VLAN IDs when supported.
  ")
  table acl_pre_ingress_vlan_table {
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
      headers.ethernet.ether_type : ternary @name("ether_type") @id(4)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_ETHER_TYPE);
      local_metadata.vlan_id : ternary @id(5) @name("vlan_id")
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_OUTER_VLAN_ID);
    }
    actions = {
      @proto_id(1) set_outer_vlan_id;
      @defaultonly NoAction;
    }
    const default_action = NoAction;
    counters = acl_pre_ingress_vlan_counter;
    size = ACL_PRE_INGRESS_TABLE_MINIMUM_GUARANTEED_SIZE;
  }

  @id(ACL_PRE_INGRESS_METADATA_TABLE_ID)
  @sai_acl(PRE_INGRESS)
  @p4runtime_role(P4RUNTIME_ROLE_SDN_CONTROLLER)
  @sai_acl_priority(5)
  @entry_restriction("
    // Forbid illegal combinations of IP_TYPE fields.
    is_ip::mask != 0 -> (is_ipv4::mask == 0 && is_ipv6::mask == 0);
    is_ipv4::mask != 0 -> (is_ip::mask == 0 && is_ipv6::mask == 0);
    is_ipv6::mask != 0 -> (is_ip::mask == 0 && is_ipv4::mask == 0);
    // DSCP is only allowed on IP traffic.
    dscp::mask != 0 -> (is_ip == 1 || is_ipv4 == 1 || is_ipv6 == 1);
    ecn::mask != 0 -> (is_ip == 1 || is_ipv4 == 1 || is_ipv6 == 1);
    // Forbid unsupported combinations of IP_TYPE fields.
    is_ipv4::mask != 0 -> (is_ipv4 == 1);
    is_ipv6::mask != 0 -> (is_ipv6 == 1);
    // Only allow icmp_type matches for ICMP packets
    icmpv6_type::mask != 0 -> ip_protocol == 58;
  ")
  table acl_pre_ingress_metadata_table {
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
          @id(4) @name("ip_protocol")
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_IP_PROTOCOL);
      headers.icmp.type : ternary
          @id(5) @name("icmpv6_type")
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_ICMPV6_TYPE);
      dscp : ternary
          @id(6) @name("dscp")
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_DSCP);
      ecn : ternary
          @id(7) @name("ecn")
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_ECN);
    }
    actions = {
      @proto_id(1) set_acl_metadata;
      @defaultonly NoAction;
    }
    const default_action = NoAction;
    counters = acl_pre_ingress_metadata_counter;
    size = ACL_PRE_INGRESS_TABLE_MINIMUM_GUARANTEED_SIZE;
  }

  apply {
    if (headers.ipv4.isValid()) {
      dscp = headers.ipv4.dscp;
      ecn = headers.ipv4.ecn;
      ip_protocol = headers.ipv4.protocol;
    } else if (headers.ipv6.isValid()) {
      dscp = headers.ipv6.dscp;
      ecn = headers.ipv6.ecn;
      ip_protocol = headers.ipv6.next_header;
    }

#if defined(SAI_INSTANTIATION_MIDDLEBLOCK)
    acl_pre_ingress_table.apply();
#elif defined(SAI_INSTANTIATION_FABRIC_BORDER_ROUTER)
    acl_pre_ingress_table.apply();
#elif defined(SAI_INSTANTIATION_TOR) 
    acl_pre_ingress_vlan_table.apply();
    acl_pre_ingress_metadata_table.apply();
    acl_pre_ingress_table.apply();
#endif
  }
}  // control acl_pre_ingress

#endif  // SAI_ACL_PRE_INGRESS_P4_
