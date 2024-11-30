#ifndef SAI_ACL_WBB_INGRESS_P4_
#define SAI_ACL_WBB_INGRESS_P4_

#include <v1model.p4>
#include "../../fixed/headers.p4"
#include "../../fixed/metadata.p4"
#include "ids.h"
#include "roles.h"
#include "minimum_guaranteed_sizes.p4"

control acl_wbb_ingress(in headers_t headers,
                         inout local_metadata_t local_metadata,
                         inout standard_metadata_t standard_metadata) {
  // IPv4 TTL or IPv6 hoplimit bits (or 0, for non-IP packets)
  bit<8> ttl = 0;

  @id(ACL_WBB_INGRESS_METER_ID)
  direct_meter<MeterColor_t>(MeterType.bytes) acl_wbb_ingress_meter;

  @id(ACL_WBB_INGRESS_COUNTER_ID)
  direct_counter(CounterType.packets_and_bytes) acl_wbb_ingress_counter;

  // Copy the packet to the CPU, and forward the original packet.
  @id(ACL_WBB_INGRESS_COPY_ACTION_ID)
  @sai_action(SAI_PACKET_ACTION_COPY)
  action acl_wbb_ingress_copy() {
    acl_wbb_ingress_meter.read(local_metadata.color);
    clone(CloneType.I2E, COPY_TO_CPU_SESSION_ID);
    acl_wbb_ingress_counter.count();
  }

  // Copy the packet to the CPU. The original packet is dropped.
  @id(ACL_WBB_INGRESS_TRAP_ACTION_ID)
  @sai_action(SAI_PACKET_ACTION_TRAP)
  action acl_wbb_ingress_trap() {
    acl_wbb_ingress_meter.read(local_metadata.color);
    clone(CloneType.I2E, COPY_TO_CPU_SESSION_ID);
    mark_to_drop(standard_metadata);
    acl_wbb_ingress_counter.count();
  }

  @p4runtime_role(P4RUNTIME_ROLE_SDN_CONTROLLER)
  @id(ACL_WBB_INGRESS_TABLE_ID)
  @sai_acl(INGRESS)
  @entry_restriction("
    // WBB only allows for very specific table entries:

    // Traceroute (6 entries)
    (
      // IPv4 or IPv6
      ((is_ipv4 == 1 && is_ipv6::mask == 0) ||
        (is_ipv4::mask == 0 && is_ipv6 == 1)) &&
      // TTL 0, 1, and 2
      (ttl == 0 || ttl == 1 || ttl == 2) &&
      ether_type::mask == 0 && outer_vlan_id::mask == 0
    ) ||
    // LLDP
    (
      ether_type == 0x88cc &&
      is_ipv4::mask == 0 && is_ipv6::mask == 0 && ttl::mask == 0 &&
      outer_vlan_id::mask == 0
    ) ||
    // ND
    (
    // TODO remove optional match for VLAN ID once VLAN ID is
    // completely removed from ND flows.
      (( outer_vlan_id::mask == 0xfff && outer_vlan_id == 0x0FA0) ||
      outer_vlan_id::mask == 0);
      ether_type == 0x6007;
      is_ipv4::mask == 0;
      is_ipv6::mask == 0;
      ttl::mask == 0
    )
  ")
  table acl_wbb_ingress_table {
    key = {
      headers.ipv4.isValid() : optional @name("is_ipv4") @id(1)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_ACL_IP_TYPE/IPV4ANY);
      headers.ipv6.isValid() : optional @name("is_ipv6") @id(2)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_ACL_IP_TYPE/IPV6ANY);
      headers.ethernet.ether_type : ternary @name("ether_type") @id(3)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_ETHER_TYPE);
      // Field for v4 TTL and v6 hop_limit
      ttl : ternary @name("ttl") @id(4)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_TTL);
      // TODO: actually model vlan headers. For now, we just some
      // arbitrary 12 bits from the checksum.
      headers.ipv4.header_checksum[11:0] : ternary @name("outer_vlan_id") @id(5)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_OUTER_VLAN_ID);
    }
    actions = {
      @proto_id(1) acl_wbb_ingress_copy();
      @proto_id(2) acl_wbb_ingress_trap();
      @defaultonly NoAction;
    }
    const default_action = NoAction;
    meters = acl_wbb_ingress_meter;
    counters = acl_wbb_ingress_counter;
    size = ACL_WBB_INGRESS_TABLE_MINIMUM_GUARANTEED_SIZE;
  }

  apply {
    if (headers.ipv4.isValid()) {
      ttl = headers.ipv4.ttl;
    } else if (headers.ipv6.isValid()) {
      ttl = headers.ipv6.hop_limit;
    }

    acl_wbb_ingress_table.apply();
  }
}  // control acl_wbb_packetio

#endif  // SAI_ACL_WBB_INGRESS_P4_
