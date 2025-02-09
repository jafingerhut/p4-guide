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

#ifndef SAI_ACL_INGRESS_P4_
#define SAI_ACL_INGRESS_P4_

#include <v1model.p4>
#include "../../fixed/headers.p4"
#include "../../fixed/metadata.p4"
#include "../../fixed/packet_io.p4"
#include "acl_common_actions.p4"
#include "ids.h"
#include "minimum_guaranteed_sizes.p4"

control acl_ingress(in headers_t headers,
                    inout local_metadata_t local_metadata,
                    inout standard_metadata_t standard_metadata) {
  // IPv4 TTL or IPv6 hoplimit bits (or 0, for non-IP packets)
  bit<8> ttl = 0;
  // First 6 bits of IPv4 TOS or IPv6 traffic class (or 0, for non-IP packets)
  bit<6> dscp = 0;
  // Last 2 bits of IPv4 TOS or IPv6 traffic class (or 0, for non-IP packets)
  bit<2> ecn = 0;
  // IPv4 IP protocol or IPv6 next_header (or 0, for non-IP packets)
  bit<8> ip_protocol = 0;
  // Cancels out local_metadata.marked_to_copy when true.
  bool cancel_copy = false;

  @id(ACL_INGRESS_METER_ID)
  @mode(single_rate_two_color)
  direct_meter<MeterColor_t>(MeterType.bytes) acl_ingress_meter;

  @id(ACL_INGRESS_QOS_METER_ID)
  @mode(single_rate_two_color)
  direct_meter<MeterColor_t>(MeterType.bytes) acl_ingress_qos_meter;

  @id(ACL_INGRESS_COUNTER_ID)
  direct_counter(CounterType.packets_and_bytes) acl_ingress_counter;

  @id(ACL_INGRESS_QOS_COUNTER_ID)
  direct_counter(CounterType.packets_and_bytes) acl_ingress_qos_counter;

  @id(ACL_INGRESS_COUNTING_COUNTER_ID)
  direct_counter(CounterType.packets_and_bytes) acl_ingress_counting_counter;

  @id(ACL_INGRESS_SECURITY_COUNTER_ID)
  direct_counter(CounterType.packets_and_bytes) acl_ingress_security_counter;

  // Copy the packet to the CPU, and forward the original packet.
  @id(ACL_INGRESS_COPY_ACTION_ID)
#if defined(SAI_INSTANTIATION_TOR) 
  // In ToRs, the acl_ingress_table copy action will not apply a rate limit.
  // Rate limits will be applied by acl_ingress_qos_table cancel_copy actions.
  @sai_action(SAI_PACKET_ACTION_COPY)
  action acl_copy(@sai_action_param(QOS_QUEUE) @id(1) qos_queue_t qos_queue) {
    acl_ingress_counter.count();
    local_metadata.marked_to_copy = true;
  }
#else
  @sai_action(SAI_PACKET_ACTION_COPY, SAI_PACKET_COLOR_GREEN)
  @sai_action(SAI_PACKET_ACTION_FORWARD, SAI_PACKET_COLOR_RED)
  action acl_copy(@sai_action_param(QOS_QUEUE) @id(1) qos_queue_t qos_queue) {
    acl_ingress_counter.count();
    acl_ingress_meter.read(local_metadata.color);

    // We model the behavior for GREEN packets only.
    // TODO: Branch on color and model behavior for all colors.
    local_metadata.marked_to_copy = true;
  }
#endif

  // Copy the packet to the CPU. The original packet is dropped.
  @id(ACL_INGRESS_TRAP_ACTION_ID)
#if defined(SAI_INSTANTIATION_TOR) 
  // In ToRs, the acl_ingress_table trap action will not apply a rate limit.
  // Rate limits will be applied by acl_ingress_qos_table cancel_copy actions.
  @sai_action(SAI_PACKET_ACTION_TRAP)
#else
  @sai_action(SAI_PACKET_ACTION_TRAP, SAI_PACKET_COLOR_GREEN)
  @sai_action(SAI_PACKET_ACTION_DROP, SAI_PACKET_COLOR_RED)
#endif
  action acl_trap(@sai_action_param(QOS_QUEUE) @id(1) qos_queue_t qos_queue) {
    acl_copy(qos_queue);
    // TODO: Use `acl_drop(local_metadata)` instead when supported
    // in P4-Symbolic.
    local_metadata.acl_drop = true;
  }

  // Forward the packet normally (i.e., perform no action). This is useful as
  // the default action, and to specify a meter but not otherwise perform any
  // action.
  @id(ACL_INGRESS_FORWARD_ACTION_ID)
#if defined(SAI_INSTANTIATION_TOR) 
  // ToRs rely on QoS queues to limit forwarded flows.
  @sai_action(SAI_PACKET_ACTION_FORWARD)
  action acl_forward() {
  }
#else
  @sai_action(SAI_PACKET_ACTION_FORWARD, SAI_PACKET_COLOR_GREEN)
  @sai_action(SAI_PACKET_ACTION_DROP, SAI_PACKET_COLOR_RED)
  action acl_forward() {
    acl_ingress_meter.read(local_metadata.color);
    // We model the behavior for GREEN packes only here.
    // TODO: Branch on color and model behavior for all colors.
  }
#endif

  // Forward the packet normally (i.e., perform no action).
  @id(ACL_INGRESS_COUNT_ACTION_ID)
  @sai_action(SAI_PACKET_ACTION_FORWARD)
  action acl_count() {
    acl_ingress_counting_counter.count();
  }

  @id(ACL_INGRESS_MIRROR_ACTION_ID)
  @sai_action(SAI_PACKET_ACTION_FORWARD)
  action acl_mirror(
      @id(1)
      @refers_to(mirror_session_table, mirror_session_id)
      @sai_action_param(SAI_ACL_ENTRY_ATTR_ACTION_MIRROR_INGRESS)
      mirror_session_id_t mirror_session_id) {
    acl_ingress_counter.count();
    local_metadata.marked_to_mirror = true;
    local_metadata.mirror_session_id = mirror_session_id;
  }

  @id(ACL_INGRESS_SET_QOS_QUEUE_AND_CANCEL_COPY_ABOVE_RATE_LIMIT_ACTION_ID)
  @sai_action(SAI_PACKET_ACTION_FORWARD, SAI_PACKET_COLOR_GREEN)
  @sai_action(SAI_PACKET_ACTION_COPY_CANCEL, SAI_PACKET_COLOR_RED)
  // TODO: Rename qos queue to cpu queue, as per action below.
  action set_qos_queue_and_cancel_copy_above_rate_limit(
      @id(1) @sai_action_param(QOS_QUEUE) qos_queue_t qos_queue) {
    acl_ingress_qos_meter.read(local_metadata.color);
    // TODO: Implement rate-limit flows for ToR use-case. Changes
    // needed:
    //  * acl_ingress.p4 shouldn't set rate limits.
    //  * acl_ingress_qos.p4 should have a meter.
    //  * This action should model behaviors.
  }

  // Forwards green packets normally. Otherwise, drops packets and ensures that
  // they are not copied to the CPU.
  // Also sets CPU queue and Multicast queue, with different multicast queues
  // set depending on packet color.
  @id(ACL_INGRESS_SET_CPU_AND_MULTICAST_QUEUES_AND_DENY_ABOVE_RATE_LIMIT_ACTION_ID)
  @sai_action(SAI_PACKET_ACTION_FORWARD, SAI_PACKET_COLOR_GREEN)
  @sai_action(SAI_PACKET_ACTION_DENY, SAI_PACKET_COLOR_RED)
  // TODO: Remove @unsupported annotation.
  @unsupported
  action set_cpu_and_multicast_queues_and_deny_above_rate_limit(
      @id(1) @sai_action_param(QOS_QUEUE) qos_queue_t cpu_queue,
      @id(2) @sai_action_param(MULTICAST_QOS_QUEUE, SAI_PACKET_COLOR_GREEN)
        qos_queue_t green_multicast_queue,
      @id(3) @sai_action_param(MULTICAST_QOS_QUEUE, SAI_PACKET_COLOR_RED)
        qos_queue_t red_multicast_queue) {
    acl_ingress_qos_meter.read(local_metadata.color);
    // We model the behavior for GREEN packes only here.
    // TODO: Branch on color and model behavior for all colors.
  }

  // Forwards green packets normally. Otherwise, drops packets and ensures that
  // they are not copied to the CPU.
  @id(ACL_INGRESS_SET_CPU_QUEUE_AND_DENY_ABOVE_RATE_LIMIT_ACTION_ID)
  @sai_action(SAI_PACKET_ACTION_FORWARD, SAI_PACKET_COLOR_GREEN)
  @sai_action(SAI_PACKET_ACTION_DENY, SAI_PACKET_COLOR_RED)
  action set_cpu_queue_and_deny_above_rate_limit(
      @id(1) @sai_action_param(QOS_QUEUE) qos_queue_t cpu_queue) {
    acl_ingress_qos_meter.read(local_metadata.color);
    // We model the behavior for GREEN packes only here.
    // TODO: Branch on color and model behavior for all colors.
  }

  // Forwards packets normally. Sets CPU queue.
  @id(ACL_INGRESS_SET_CPU_QUEUE_ACTION_ID)
  @sai_action(SAI_PACKET_ACTION_FORWARD)
  action set_cpu_queue(
      @id(1) @sai_action_param(QOS_QUEUE) qos_queue_t cpu_queue) {
  }

  // Drops the packet at the end of the the pipeline and ensures that it is not
  // copied to the CPU. See `acl_drop` for more information on the mechanism of
  // the drop.
  @id(ACL_INGRESS_DENY_ACTION_ID)
  @sai_action(SAI_PACKET_ACTION_DENY)
  action acl_deny() {
    cancel_copy = true;
    // TODO: Use `acl_drop(local_metadata)` instead when supported
    // in P4-Symbolic.
    local_metadata.acl_drop = true;
  }

  @p4runtime_role(P4RUNTIME_ROLE_SDN_CONTROLLER)
  @id(ACL_INGRESS_TABLE_ID)
  @sai_acl(INGRESS)
  @sai_acl_priority(5)
  @entry_restriction("
    // Forbid using ether_type for IP packets (by convention, use is_ip* instead).
    ether_type != 0x0800 && ether_type != 0x86dd;
    // Only allow IP field matches for IP packets.
    dst_ip::mask != 0 -> is_ipv4 == 1;
#if defined(SAI_INSTANTIATION_MIDDLEBLOCK) || defined(SAI_INSTANTIATION_FABRIC_BORDER_ROUTER)
    src_ip::mask != 0 -> is_ipv4 == 1;
#endif
    dst_ipv6::mask != 0 -> is_ipv6 == 1;
    src_ipv6::mask != 0 -> is_ipv6 == 1;
    ttl::mask != 0 -> (is_ip == 1 || is_ipv4 == 1 || is_ipv6 == 1);
#if defined(SAI_INSTANTIATION_MIDDLEBLOCK) || defined(SAI_INSTANTIATION_FABRIC_BORDER_ROUTER)
    dscp::mask != 0 -> (is_ip == 1 || is_ipv4 == 1 || is_ipv6 == 1);
    ecn::mask != 0 -> (is_ip == 1 || is_ipv4 == 1 || is_ipv6 == 1);
#endif
    ip_protocol::mask != 0 -> (is_ip == 1 || is_ipv4 == 1 || is_ipv6 == 1);
    // Only allow l4_dst_port and l4_src_port matches for TCP/UDP packets.
    l4_src_port::mask != 0 -> (ip_protocol == 6 || ip_protocol == 17);
    l4_dst_port::mask != 0 -> (ip_protocol == 6 || ip_protocol == 17);
#if defined(SAI_INSTANTIATION_MIDDLEBLOCK) || defined(SAI_INSTANTIATION_TOR)
    // Only allow arp_tpa matches for ARP packets.
    arp_tpa::mask != 0 -> ether_type == 0x0806;
#endif
#if defined(SAI_INSTANTIATION_FABRIC_BORDER_ROUTER) || defined(SAI_INSTANTIATION_TOR)
    // Only allow icmp_type matches for ICMP packets
    icmp_type::mask != 0 -> ip_protocol == 1;
#endif
    icmpv6_type::mask != 0 -> ip_protocol == 58;
    // Forbid illegal combinations of IP_TYPE fields.
    is_ip::mask != 0 -> (is_ipv4::mask == 0 && is_ipv6::mask == 0);
    is_ipv4::mask != 0 -> (is_ip::mask == 0 && is_ipv6::mask == 0);
    is_ipv6::mask != 0 -> (is_ip::mask == 0 && is_ipv4::mask == 0);
    // Forbid unsupported combinations of IP_TYPE fields.
    is_ipv4::mask != 0 -> (is_ipv4 == 1);
    is_ipv6::mask != 0 -> (is_ipv6 == 1);
  ")
  table acl_ingress_table {
    key = {
      headers.ipv4.isValid() || headers.ipv6.isValid() : optional @name("is_ip") @id(1)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_ACL_IP_TYPE/IP);
      headers.ipv4.isValid() : optional @name("is_ipv4") @id(2)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_ACL_IP_TYPE/IPV4ANY);
      headers.ipv6.isValid() : optional @name("is_ipv6") @id(3)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_ACL_IP_TYPE/IPV6ANY);
      headers.ethernet.ether_type : ternary @name("ether_type") @id(4)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_ETHER_TYPE);
      headers.ethernet.dst_addr : ternary @name("dst_mac") @id(5)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_DST_MAC) @format(MAC_ADDRESS);
      headers.ipv4.src_addr : ternary @name("src_ip") @id(6)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_SRC_IP) @format(IPV4_ADDRESS);
      headers.ipv4.dst_addr : ternary @name("dst_ip") @id(7)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_DST_IP) @format(IPV4_ADDRESS);
      headers.ipv6.src_addr[127:64] : ternary @name("src_ipv6") @id(8)
          @composite_field(
              @sai_field(SAI_ACL_TABLE_ATTR_FIELD_SRC_IPV6_WORD3),
              @sai_field(SAI_ACL_TABLE_ATTR_FIELD_SRC_IPV6_WORD2)
          ) @format(IPV6_ADDRESS);
      headers.ipv6.dst_addr[127:64] : ternary @name("dst_ipv6") @id(9)
          @composite_field(
              @sai_field(SAI_ACL_TABLE_ATTR_FIELD_DST_IPV6_WORD3),
              @sai_field(SAI_ACL_TABLE_ATTR_FIELD_DST_IPV6_WORD2)
          ) @format(IPV6_ADDRESS);
      // Field for v4 TTL and v6 hop_limit
      ttl : ternary @name("ttl") @id(10)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_TTL);
#if defined(SAI_INSTANTIATION_MIDDLEBLOCK) || defined(SAI_INSTANTIATION_FABRIC_BORDER_ROUTER)
      dscp : ternary @name("dscp") @id(11)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_DSCP);
      // Field for v4 and v6 ECN bits.
      ecn : ternary @name("ecn") @id(12)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_ECN);
#endif
      // Field for v4 IP protocol and v6 next header.
      ip_protocol : ternary
          @id(13) @name("ip_protocol")
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_IP_PROTOCOL);
#if defined(SAI_INSTANTIATION_FABRIC_BORDER_ROUTER) || defined(SAI_INSTANTIATION_TOR)
      headers.icmp.type : ternary @name("icmp_type") @id(19)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_ICMP_TYPE);
#endif
      headers.icmp.type : ternary @name("icmpv6_type") @id(14)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_ICMPV6_TYPE);
      local_metadata.l4_src_port : ternary @name("l4_src_port") @id(20)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_L4_SRC_PORT);
      local_metadata.l4_dst_port : ternary @name("l4_dst_port") @id(15)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_L4_DST_PORT);
#if defined(SAI_INSTANTIATION_MIDDLEBLOCK) || defined(SAI_INSTANTIATION_TOR)
      headers.arp.target_proto_addr : ternary @name("arp_tpa") @id(16)
          @composite_field(
              @sai_udf(base=SAI_UDF_BASE_L3, offset=24, length=2),
              @sai_udf(base=SAI_UDF_BASE_L3, offset=26, length=2)
          ) @format(IPV4_ADDRESS);
#endif
#if defined(SAI_INSTANTIATION_FABRIC_BORDER_ROUTER) || defined(SAI_INSTANTIATION_TOR) 
      local_metadata.ingress_port : optional @name("in_port") @id(17)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_IN_PORT);
      local_metadata.route_metadata : optional @name("route_metadata") @id(18)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_ROUTE_DST_USER_META);
#endif
    }
    actions = {
      @proto_id(1) acl_copy();
      @proto_id(2) acl_trap();
      @proto_id(3) acl_forward();
      @proto_id(4) acl_mirror();
      @proto_id(5) acl_drop(local_metadata);
      @defaultonly NoAction;
    }
    const default_action = NoAction;
#if defined(SAI_INSTANTIATION_MIDDLEBLOCK) || defined(SAI_INSTANTIATION_FABRIC_BORDER_ROUTER)
    meters = acl_ingress_meter;
    counters = acl_ingress_counter;
#else
    counters = acl_ingress_counter;
#endif
    size = ACL_INGRESS_TABLE_MINIMUM_GUARANTEED_SIZE;
  }

  @id(ACL_INGRESS_QOS_TABLE_ID)
  @sai_acl(INGRESS)
  @sai_acl_priority(10)
  @p4runtime_role(P4RUNTIME_ROLE_SDN_CONTROLLER)
  @entry_restriction("
    // Forbid using ether_type for IP packets (by convention, use is_ip* instead).
    ether_type != 0x0800 && ether_type != 0x86dd;
    // Only allow IP field matches for IP packets.
    ttl::mask != 0 -> (is_ip == 1 || is_ipv4 == 1 || is_ipv6 == 1);
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
    // Only allow icmp_type matches for ICMP packets
    icmpv6_type::mask != 0 -> ip_protocol == 58;
#ifdef SAI_INSTANTIATION_FABRIC_BORDER_ROUTER
    // Only allow l4_dst_port matches for TCP/UDP packets.
    l4_src_port::mask != 0 -> (ip_protocol == 6 || ip_protocol == 17);
    // Only allow icmp_type matches for ICMP packets
    icmp_type::mask != 0 -> ip_protocol == 1;
#endif
#if defined(SAI_INSTANTIATION_TOR)
    // Only allow arp_tpa matches for ARP packets.
    arp_tpa::mask != 0 -> ether_type == 0x0806;
#endif
  ")
  table acl_ingress_qos_table {
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
      headers.ethernet.ether_type : ternary
          @id(4) @name("ether_type")
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_ETHER_TYPE);
      ttl : ternary
          @id(7) @name("ttl")
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_TTL);
      ip_protocol : ternary
          @id(8) @name("ip_protocol")
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_IP_PROTOCOL);
      headers.icmp.type : ternary
          @id(9) @name("icmpv6_type")
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_ICMPV6_TYPE);
      local_metadata.l4_dst_port : ternary
          @id(10) @name("l4_dst_port")
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_L4_DST_PORT);
#ifdef SAI_INSTANTIATION_FABRIC_BORDER_ROUTER
      local_metadata.l4_src_port : ternary
          @id(12) @name("l4_src_port")
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_L4_SRC_PORT);
      headers.icmp.type : ternary
          @id(14) @name("icmp_type")
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_ICMP_TYPE);
      local_metadata.route_metadata : ternary
          @id(15) @name("route_metadata")
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_ROUTE_DST_USER_META);
#endif
#if defined(SAI_INSTANTIATION_TOR)
      headers.ethernet.dst_addr : ternary
          @id(5) @name("dst_mac")
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_DST_MAC) @format(MAC_ADDRESS);
      headers.arp.target_proto_addr : ternary
          @id(6) @name("arp_tpa")
          @composite_field(
              @sai_udf(base=SAI_UDF_BASE_L3, offset=24, length=2),
              @sai_udf(base=SAI_UDF_BASE_L3, offset=26, length=2)
          ) @format(IPV4_ADDRESS);
      local_metadata.ingress_port : optional
          @id(11) @name("in_port")
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_IN_PORT);
      local_metadata.acl_metadata : ternary
          @id(13) @name("acl_metadata")
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_ACL_USER_META);
#endif
    }
    actions = {
      @proto_id(1) set_qos_queue_and_cancel_copy_above_rate_limit();
      @proto_id(2) set_cpu_queue_and_deny_above_rate_limit();
      @proto_id(3) acl_forward();
      @proto_id(4) acl_drop(local_metadata);
      @proto_id(5) set_cpu_queue();
      @proto_id(6)
        set_cpu_and_multicast_queues_and_deny_above_rate_limit();
      @defaultonly NoAction;
    }
    const default_action = NoAction;
    meters = acl_ingress_qos_meter;
    counters = acl_ingress_qos_counter;
    size = ACL_INGRESS_QOS_TABLE_MINIMUM_GUARANTEED_SIZE;
  }

  @p4runtime_role(P4RUNTIME_ROLE_SDN_CONTROLLER)
  @id(ACL_INGRESS_COUNTING_TABLE_ID)
  @sai_acl_priority(7)
  @sai_acl(INGRESS)
  @entry_restriction("
    // Only allow IP field matches for IP packets.
    dscp::mask != 0 -> (is_ip == 1 || is_ipv4 == 1 || is_ipv6 == 1);
    // Forbid illegal combinations of IP_TYPE fields.
    is_ip::mask != 0 -> (is_ipv4::mask == 0 && is_ipv6::mask == 0);
    is_ipv4::mask != 0 -> (is_ip::mask == 0 && is_ipv6::mask == 0);
    is_ipv6::mask != 0 -> (is_ip::mask == 0 && is_ipv4::mask == 0);
    // Forbid unsupported combinations of IP_TYPE fields.
    is_ipv4::mask != 0 -> (is_ipv4 == 1);
    is_ipv6::mask != 0 -> (is_ipv6 == 1);
  ")
  table acl_ingress_counting_table {
    key = {
      headers.ipv4.isValid() || headers.ipv6.isValid() : optional
          @id(1) @name("is_ip")
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_ACL_IP_TYPE/IP);
      headers.ipv4.isValid() : optional
          @id(2) @name("is_ipv4")
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_ACL_IP_TYPE/IPV4ANY);
      headers.ipv6.isValid() : optional @name("is_ipv6") @id(3)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_ACL_IP_TYPE/IPV6ANY);
      // Field for v4 and v6 DSCP bits.
      dscp : ternary @name("dscp") @id(11)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_DSCP);
      local_metadata.route_metadata : ternary @name("route_metadata") @id(18)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_ROUTE_DST_USER_META);
    }
    actions = {
      @proto_id(3) acl_count();
      @defaultonly NoAction;
    }
    const default_action = NoAction;
    counters = acl_ingress_counting_counter;
    size = ACL_INGRESS_COUNTING_TABLE_MINIMUM_GUARANTEED_SIZE;
  }

  @id(ACL_INGRESS_REDIRECT_TO_NEXTHOP_ACTION_ID)
  action redirect_to_nexthop(
    @sai_action_param(SAI_ACL_ENTRY_ATTR_ACTION_REDIRECT)
    @sai_action_param_object_type(SAI_OBJECT_TYPE_NEXT_HOP)
    @refers_to(nexthop_table, nexthop_id)
    nexthop_id_t nexthop_id) {

    // Set nexthop id.
    local_metadata.nexthop_id_valid = true;
    local_metadata.nexthop_id_value = nexthop_id;

    // Cancel other forwarding decisions (if any).
    local_metadata.wcmp_group_id_valid = false;
    standard_metadata.mcast_grp = 0;
  }

  @id(ACL_INGRESS_REDIRECT_TO_IPMC_GROUP_ACTION_ID)
  @action_restriction("
    // Disallow 0 since it encodes 'no multicast' in V1Model.
    multicast_group_id != 0;
  ")
  action redirect_to_ipmc_group(
    @sai_action_param(SAI_ACL_ENTRY_ATTR_ACTION_REDIRECT)
    @sai_action_param_object_type(SAI_OBJECT_TYPE_IPMC_GROUP)
    @refers_to(builtin::multicast_group_table, multicast_group_id)
    multicast_group_id_t multicast_group_id) {
    standard_metadata.mcast_grp = multicast_group_id;

    // Cancel other forwarding decisions (if any).
    local_metadata.nexthop_id_valid = false;
    local_metadata.wcmp_group_id_valid = false;
  }


  // ACL table that mirrors and redirects packets.
  @id(ACL_INGRESS_MIRROR_AND_REDIRECT_TABLE_ID)
  @sai_acl(INGRESS)
  @sai_acl_priority(15)
  @p4runtime_role(P4RUNTIME_ROLE_SDN_CONTROLLER)
  @entry_restriction("
    // Only allow IP field matches for IP packets.
    dst_ip::mask != 0 -> is_ipv4 == 1;
    dst_ipv6::mask != 0 -> is_ipv6 == 1;
    // Forbid illegal combinations of IP_TYPE fields.
    is_ip::mask != 0 -> (is_ipv4::mask == 0 && is_ipv6::mask == 0);
    is_ipv4::mask != 0 -> (is_ip::mask == 0 && is_ipv6::mask == 0);
    is_ipv6::mask != 0 -> (is_ip::mask == 0 && is_ipv4::mask == 0);
    // Forbid unsupported combinations of IP_TYPE fields.
    is_ipv4::mask != 0 -> (is_ipv4 == 1);
    is_ipv6::mask != 0 -> (is_ipv6 == 1);
  ")
  table acl_ingress_mirror_and_redirect_table {
    key = {
#if defined(SAI_INSTANTIATION_TOR)
      local_metadata.ingress_port : optional
        @name("in_port")
        @sai_field(SAI_ACL_TABLE_ATTR_FIELD_IN_PORT)
        @id(1);

      local_metadata.acl_metadata : ternary
        @name("acl_metadata")
        @sai_field(SAI_ACL_TABLE_ATTR_FIELD_ACL_USER_META)
        @id(6);

      local_metadata.vlan_id : ternary
        @name("vlan_id")
        @sai_field(SAI_ACL_TABLE_ATTR_FIELD_OUTER_VLAN_ID)
        @id(7);
#endif

      headers.ipv4.isValid() || headers.ipv6.isValid() : optional
        @name("is_ip")
        @sai_field(SAI_ACL_TABLE_ATTR_FIELD_ACL_IP_TYPE/IP)
        @id(2);

      headers.ipv4.isValid() : optional
        @name("is_ipv4")
        @sai_field(SAI_ACL_TABLE_ATTR_FIELD_ACL_IP_TYPE/IPV4ANY)
        @id(3);

      headers.ipv6.isValid() : optional
        @name("is_ipv6")
        @sai_field(SAI_ACL_TABLE_ATTR_FIELD_ACL_IP_TYPE/IPV6ANY)
        @id(4);

      headers.ipv4.dst_addr : ternary
        @name("dst_ip")
        @sai_field(SAI_ACL_TABLE_ATTR_FIELD_DST_IP)
        @format(IPV4_ADDRESS)
        @id(10);

      headers.ipv6.dst_addr[127:64] : ternary
        @name("dst_ipv6")
        @composite_field(
            @sai_field(SAI_ACL_TABLE_ATTR_FIELD_DST_IPV6_WORD3),
            @sai_field(SAI_ACL_TABLE_ATTR_FIELD_DST_IPV6_WORD2))
        @format(IPV6_ADDRESS)
        @id(5);

      local_metadata.vrf_id : optional
        @id(8) @name("vrf_id")
        @sai_field(SAI_ACL_TABLE_ATTR_FIELD_VRF_ID);
      local_metadata.ipmc_table_hit : optional
        @id(9) @name("ipmc_table_hit")
        @sai_field(SAI_ACL_TABLE_ATTR_FIELD_IPMC_NPU_META_DST_HIT);
    }
    actions = {
// We don't usually restrict actions to instantiations because they don't
// require resources but we make an exception here because of issues with
// metering (go/gpins-meter-consistency for details).
// `acl_forward` in `mirror_and_redirect` is needed for `experimental_tor` and is an
// unmetered action there. `middleblock` needs `mirror_and_redirect` but NOT
// `acl_forward` which is a metered action there. If we include it in
// `middleblock` we run into resource issues.
#if defined(SAI_INSTANTIATION_EXPERIMENTAL_TOR)
      @proto_id(4) acl_forward();
#endif
      @proto_id(1) acl_mirror();
      @proto_id(2) redirect_to_nexthop();
      @proto_id(3) redirect_to_ipmc_group();
      @defaultonly NoAction;
    }
    const default_action = NoAction;
    size = ACL_INGRESS_MIRROR_AND_REDIRECT_TABLE_MINIMUM_GUARANTEED_SIZE;
  }

  // ACL table that only drops or denies packets, and is otherwise a no-op.
  @id(ACL_INGRESS_SECURITY_TABLE_ID)
  @sai_acl(INGRESS)
  @sai_acl_priority(20)
  @p4runtime_role(P4RUNTIME_ROLE_SDN_CONTROLLER)
  @entry_restriction("
    // Forbid using ether_type for IP packets (by convention, use is_ip* instead).
    ether_type != 0x0800 && ether_type != 0x86dd;
#if defined(SAI_INSTANTIATION_MIDDLEBLOCK)
    // Only allow IP field matches for IP packets.
    dst_ip::mask != 0 -> is_ipv4 == 1;
    src_ip::mask != 0 -> is_ipv4 == 1;
    src_ipv6::mask != 0 -> is_ipv6 == 1;
#endif
  // TODO: This comment is required for the preprocessor to not
  // spit out nonsense.
#if defined(SAI_INSTANTIATION_TOR)
    dscp::mask != 0 -> (is_ip == 1 || is_ipv4 == 1 || is_ipv6 == 1);
    ip_protocol::mask != 0 -> (is_ip == 1 || is_ipv4 == 1 || is_ipv6 == 1);
    // Only allow l4_dst_port and l4_src_port matches for TCP/UDP packets.
    l4_src_port::mask != 0 -> (ip_protocol == 6 || ip_protocol == 17);
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
  table acl_ingress_security_table {
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
      headers.ethernet.ether_type : ternary
          @id(4) @name("ether_type")
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_ETHER_TYPE);
#if defined(SAI_INSTANTIATION_MIDDLEBLOCK)
      headers.ipv4.src_addr : ternary
          @id(5) @name("src_ip")
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_SRC_IP) @format(IPV4_ADDRESS);
      headers.ipv4.dst_addr : ternary
          @id(6) @name("dst_ip")
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_DST_IP) @format(IPV4_ADDRESS);
      headers.ipv6.src_addr[127:64] : ternary
          @id(7) @name("src_ipv6")
          @composite_field(
              @sai_field(SAI_ACL_TABLE_ATTR_FIELD_SRC_IPV6_WORD3),
              @sai_field(SAI_ACL_TABLE_ATTR_FIELD_SRC_IPV6_WORD2)
          ) @format(IPV6_ADDRESS);
#endif
#if defined(SAI_INSTANTIATION_TOR)
      dscp : ternary
          @id(8) @name("dscp")
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_DSCP);
      ip_protocol : ternary
          @id(9) @name("ip_protocol")
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_IP_PROTOCOL);
      local_metadata.l4_src_port : ternary
          @id(10) @name("l4_src_port")
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_L4_SRC_PORT);
      local_metadata.l4_dst_port : ternary
          @id(11) @name("l4_dst_port")
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_L4_DST_PORT);
      local_metadata.route_metadata : ternary
          @id(12) @name("route_metadata")
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_ROUTE_DST_USER_META);
      local_metadata.acl_metadata : ternary
          @id(13) @name("acl_metadata")
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_ACL_USER_META);
#endif
    }
    actions = {
      @proto_id(1) acl_forward();
      @proto_id(2) acl_drop(local_metadata);
      @proto_id(3) acl_deny();
      @defaultonly NoAction;
    }
    const default_action = NoAction;
    counters = acl_ingress_security_counter;
    size = ACL_INGRESS_TABLE_MINIMUM_GUARANTEED_SIZE;
  }

  apply {
    if (headers.ipv4.isValid()) {
      ttl = headers.ipv4.ttl;
      dscp = headers.ipv4.dscp;
      ecn = headers.ipv4.ecn;
      ip_protocol = headers.ipv4.protocol;
    } else if (headers.ipv6.isValid()) {
      ttl = headers.ipv6.hop_limit;
      dscp = headers.ipv6.dscp;
      ecn = headers.ipv6.ecn;
      ip_protocol = headers.ipv6.next_header;
    }

#if defined(SAI_INSTANTIATION_MIDDLEBLOCK)
    acl_ingress_table.apply();
    acl_ingress_mirror_and_redirect_table.apply();
    acl_ingress_security_table.apply();
#elif defined(SAI_INSTANTIATION_FABRIC_BORDER_ROUTER)
    acl_ingress_table.apply();
    acl_ingress_counting_table.apply();
    acl_ingress_qos_table.apply();
#elif defined(SAI_INSTANTIATION_TOR)
    // These tables are currently order agnostic, but we should be careful to
    // ensure that the ordering is correct if we add new actions or model
    // additional parts of SAI in the future.
    acl_ingress_table.apply();
    acl_ingress_qos_table.apply();
    acl_ingress_mirror_and_redirect_table.apply();
#endif

    if (cancel_copy) {
      local_metadata.marked_to_copy = false;
    }
  }
}  // control ACL_INGRESS

#endif  // SAI_ACL_INGRESS_P4_
