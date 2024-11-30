#ifndef SAI_ROUTING_P4_
#define SAI_ROUTING_P4_

#include <v1model.p4>
#include "common_actions.p4"
#include "drop_martians.p4"
#include "headers.p4"
#include "metadata.p4"
#include "ids.h"
#include "roles.h"
#include "minimum_guaranteed_sizes.p4"

// This file contains two control blocks that together model the L3 routing
// pipeline: routing_lookup and routing_resolution.
//
// --lookup---|A|------------------------resolution-----------------------------
//            |C|
// +-------+  |L|  +-------+ wcmp +---------+       +-----------+
// |       |  | |  |       |----->|         |       |           |--> vlan_id
// |  lpm  |--|i|->| group |----->| nexthop |----+->| router    |--> egress_port
// |       |  |n|  |       |----->|         |-+  |  | interface |--> src_mac
// +-------+  |g|  +-------+      +---------+ |  |  +-----------+
//   |   |    |r|                     ^       |  |  +-----------+
//   |   |    |e|                     |       |  +->| neighbor  |
//   |   +----|s|---------------------+       +---->|           |--> dst_mac
//   |        |s|                                   +-----------+
//   +--------| |--------------------------------------------------> drop
//
// For packets that are admitted for L3 routing, the routing_lookup block
// performs a longest prefix match on the packet's destination IP address (along
// with an exact match on VRF id). The action associated with the
// match then either drops the packet, points to a nexthop, or points to a WCMP
// group, or multicast.
// After the packet goes through the ACL ingress stage (which can potentially
// change the nexthop or group set by LPM), the routing_resolution block
// resolves the group/nexthop as follows:
// A WCMP group uses a hash of the packet to choose from a set of nexthops. The
// nexthop points to a router interface, which determines the packet's vlan_id,
// src_mac, and the egress_port to forward the packet to. The nexthop also
// points to a neighbor which together with the router_interface, determines the
// packet's dst_mac.
//
// Note that routing_resolution does not rewrite any header field directly,
// but only records rewrites in `local_metadata.packet_rewrites`, from where
// they will be read and applied in the egress stage (dependeding on whether
// the rewrites are disabled by the nexthop or not).
// The following action is shared between routing_lookup and routing_resolution
// control blocks and hence is defined in the outer scope.
//
// When called from a route, sets SAI_ROUTE_ENTRY_ATTR_PACKET_ACTION to
// SAI_PACKET_ACTION_FORWARD, and SAI_ROUTE_ENTRY_ATTR_NEXT_HOP_ID to a
// SAI_OBJECT_TYPE_NEXT_HOP.
//
// When called from a group, sets SAI_NEXT_HOP_GROUP_MEMBER_ATTR_NEXT_HOP_ID.
// When called from a group, sets SAI_NEXT_HOP_GROUP_MEMBER_ATTR_WEIGHT.
//
// This action can only refer to `nexthop_id`s that are programmed in the
// `nexthop_table`.
@id(ROUTING_SET_NEXTHOP_ID_ACTION_ID)
action set_nexthop_id(inout local_metadata_t local_metadata,
                      @id(1) @refers_to(nexthop_table, nexthop_id)
                      nexthop_id_t nexthop_id) {
  local_metadata.nexthop_id_valid = true;
  local_metadata.nexthop_id_value = nexthop_id;
}

control routing_lookup(in headers_t headers,
                       inout local_metadata_t local_metadata,
                       inout standard_metadata_t standard_metadata) {
  // Programming this table does not affect packet forwarding directly -- the
  // table performs no actions -- but results in the creation/deletion of VRFs.
  // This is a prerequisite to using these VRFs, e.g. in the `ipv4_table` and
  // `ipv6_table` below, as is indicated by the `@refers_to(vrf_table, vrf_id)`
  // annotations.
  // TODO: Currently we don't expose any `sai_virtual_router_attr_t`
  // attributes here, but we may explore that in the future.
  @entry_restriction("
    // The VRF ID 0 (or '' in P4Runtime) encodes the default VRF, which cannot
    // be read or written via this table, but is always present implicitly.
    // TODO: This constraint should read `vrf_id != ''` (since
    // constraints are a control plane (P4Runtime) concept), but
    // p4-constraints does not currently support strings.
    vrf_id != 0;
  ")
  @p4runtime_role(P4RUNTIME_ROLE_ROUTING)
  @id(ROUTING_VRF_TABLE_ID)
  table vrf_table {
    key = {
      local_metadata.vrf_id : exact @id(1) @name("vrf_id");
    }
    actions = {
      // TODO: Add support for CamlCase actions to the PD generator
      // so we can use `NoAction` instead of `no_action`.
      @proto_id(1) no_action;
    }
    const default_action = no_action;
    size = ROUTING_VRF_TABLE_MINIMUM_GUARANTEED_SIZE;
  }
  // Sets SAI_ROUTE_ENTRY_ATTR_PACKET_ACTION to SAI_PACKET_ACTION_DROP.
  @id(ROUTING_DROP_ACTION_ID)
  action drop() {
    mark_to_drop(standard_metadata);
  }
  // Sets SAI_ROUTE_ENTRY_ATTR_PACKET_ACTION to SAI_PACKET_ACTION_FORWARD, and
  // SAI_ROUTE_ENTRY_ATTR_NEXT_HOP_ID to a SAI_OBJECT_TYPE_NEXT_HOP_GROUP.
  //
  // This action can only refer to `wcmp_group_id`s that are programmed in the
  // `wcmp_group_table`.
  @id(ROUTING_SET_WCMP_GROUP_ID_ACTION_ID)
  action set_wcmp_group_id(@id(1) @refers_to(wcmp_group_table, wcmp_group_id)
                           wcmp_group_id_t wcmp_group_id) {
    local_metadata.wcmp_group_id_valid = true;
    local_metadata.wcmp_group_id_value = wcmp_group_id;
  }
  // Sets SAI_ROUTE_ENTRY_ATTR_PACKET_ACTION to SAI_PACKET_ACTION_FORWARD, and
  // SAI_ROUTE_ENTRY_ATTR_NEXT_HOP_ID to a SAI_OBJECT_TYPE_NEXT_HOP_GROUP.
  //
  // This action can only refer to `wcmp_group_id`s that are programmed in the
  // `wcmp_group_table`.
  //
  // Also sets the route metadata available for Ingress ACL lookup.
  @id(ROUTING_SET_WCMP_GROUP_ID_AND_METADATA_ACTION_ID)
  action set_wcmp_group_id_and_metadata(@id(1)
                                        @refers_to(wcmp_group_table,
                                        wcmp_group_id)
                                        wcmp_group_id_t wcmp_group_id,
                                        route_metadata_t route_metadata) {
    set_wcmp_group_id(wcmp_group_id);
    local_metadata.route_metadata = route_metadata;
  }
  // Set the metadata of the packet and mark the packet to drop at the end of
  // the ingress pipeline.
  @id(ROUTING_SET_METADATA_AND_DROP_ACTION_ID)
  action set_metadata_and_drop(@id(1) route_metadata_t route_metadata) {
    local_metadata.route_metadata = route_metadata;
    mark_to_drop(standard_metadata);
  }

  // Can only be called form a route. Sets SAI_ROUTE_ENTRY_ATTR_PACKET_ACTION to
  // SAI_PACKET_ACTION_FORWARD, and SAI_ROUTE_ENTRY_ATTR_NEXT_HOP_ID to a
  // SAI_OBJECT_TYPE_NEXT_HOP.
  // Also sets SAI_ROUTE_ENTRY_ATTR_META_DATA.
  //
  // This action can only refer to `nexthop_id`s that are programmed in the
  // `nexthop_table`.
  @id(ROUTING_SET_NEXTHOP_ID_AND_METADATA_ACTION_ID)
  action set_nexthop_id_and_metadata(@id(1)
                                     @refers_to(nexthop_table, nexthop_id)
                                     nexthop_id_t nexthop_id,
                                     route_metadata_t route_metadata) {
    local_metadata.nexthop_id_valid = true;
    local_metadata.nexthop_id_value = nexthop_id;
    local_metadata.route_metadata = route_metadata;
  }

  // Sets the multicast group ID (SAI_IPMC_ENTRY_ATTR_OUTPUT_GROUP_ID).
  // The ID will be looked up in the multicast group table after ingress
  // processing. The group table will then make 0 or more copies of the packet
  // and pass them to the egress pipeline.
  //
  // Calling this action will override unicast, and can itself be overriden by
  // `mark_to_drop`.
  //
  @id(ROUTING_SET_MULTICAST_GROUP_ID_ACTION_ID)
  @action_restriction("
    // Disallow 0 since it encodes 'no multicast' in V1Model.
    multicast_group_id != 0;
  ")
  action set_multicast_group_id(
      @id(1)
      @refers_to(builtin::multicast_group_table, multicast_group_id)
      multicast_group_id_t multicast_group_id) {
    standard_metadata.mcast_grp = multicast_group_id;
  }
  @p4runtime_role(P4RUNTIME_ROLE_ROUTING)
  @id(ROUTING_IPV4_TABLE_ID)
  table ipv4_table {
    key = {
      // Sets `vr_id` in `sai_route_entry_t`.
      local_metadata.vrf_id : exact
        @id(1) @name("vrf_id") @refers_to(vrf_table, vrf_id);
      // Sets `destination` in `sai_route_entry_t` to an IPv4 prefix.
      headers.ipv4.dst_addr : lpm
        @id(2) @name("ipv4_dst") @format(IPV4_ADDRESS);
    }
    actions = {
      @proto_id(1) drop;
      @proto_id(2) set_nexthop_id(local_metadata);
      @proto_id(3) set_wcmp_group_id;
      @proto_id(5) set_nexthop_id_and_metadata;
      @proto_id(6) set_wcmp_group_id_and_metadata;
      @proto_id(7) set_metadata_and_drop;
    }
    const default_action = drop;
    size = ROUTING_IPV4_TABLE_MINIMUM_GUARANTEED_SIZE;
  }
  @p4runtime_role(P4RUNTIME_ROLE_ROUTING)
  @id(ROUTING_IPV6_TABLE_ID)
  table ipv6_table {
    key = {
      // Sets `vr_id` in `sai_route_entry_t`.
      local_metadata.vrf_id : exact
        @id(1) @name("vrf_id") @refers_to(vrf_table, vrf_id);
      // Sets `destination` in `sai_route_entry_t` to an IPv6 prefix.
      headers.ipv6.dst_addr : lpm
        @id(2)  @name("ipv6_dst") @format(IPV6_ADDRESS);
    }
    actions = {
      @proto_id(1) drop;
      @proto_id(2) set_nexthop_id(local_metadata);
      @proto_id(3) set_wcmp_group_id;
      @proto_id(5) set_nexthop_id_and_metadata;
      @proto_id(6) set_wcmp_group_id_and_metadata;
      @proto_id(7) set_metadata_and_drop;
    }
    const default_action = drop;
    size = ROUTING_IPV6_TABLE_MINIMUM_GUARANTEED_SIZE;
  }

  @entry_restriction("
    // TODO: Use IPv4 address notation once it is supported.
    // Only IPv4s in the multicast range 224.0.0.0/4 are supported.
    ipv4_dst::value >= 0xe0000000;
    ipv4_dst::value <= 0xefffffff;
  ")
  // Models SAI IPMC entries of type (*,G) whose destination is an IPv4 address.
  @p4runtime_role(P4RUNTIME_ROLE_ROUTING)
  @id(ROUTING_IPV4_MULTICAST_TABLE_ID)
  table ipv4_multicast_table {
    key = {
      // Sets `vr_id` in `sai_ipmc_entry_t`.
      local_metadata.vrf_id : exact
        @id(1) @name("vrf_id") @refers_to(vrf_table, vrf_id);
      // Sets `destination` in `sai_ipmc_entry_t` to an IPv4 adress.
      headers.ipv4.dst_addr : exact
        @id(2) @name("ipv4_dst") @format(IPV4_ADDRESS);
    }
    actions = {
      @proto_id(1) set_multicast_group_id;
    }
    size = ROUTING_IPV4_MULTICAST_TABLE_MINIMUM_GUARANTEED_SIZE;
  }

  @entry_restriction("
    // TODO: Use IPv4 address notation once it is supported.
    // Only IPv6s in the multicast range ff00::/8 are supported.
    ipv6_dst::value >= 0xff000000000000000000000000000000;
    ipv6_dst::value <= 0xffffffffffffffffffffffffffffffff;
  ")
  // Models SAI IPMC entries of type (*,G) whose destination is an IPv6 address.
  @p4runtime_role(P4RUNTIME_ROLE_ROUTING)
  @id(ROUTING_IPV6_MULTICAST_TABLE_ID)
  table ipv6_multicast_table {
    key = {
      // Sets `vr_id` in `sai_ipmc_entry_t`.
      local_metadata.vrf_id : exact
        @id(1) @name("vrf_id") @refers_to(vrf_table, vrf_id);
      // Sets `destination` in `sai_ipmc_entry_t` to an IPv6 adress.
      headers.ipv6.dst_addr : exact
        @id(2) @name("ipv6_dst") @format(IPV6_ADDRESS);
    }
    actions = {
      @proto_id(1) set_multicast_group_id;
    }
    size = ROUTING_IPV6_MULTICAST_TABLE_MINIMUM_GUARANTEED_SIZE;
  }

  apply {
    mark_to_drop(standard_metadata);
    vrf_table.apply();

    if (headers.ipv4.isValid()) {
      if (IS_MULTICAST_IPV4(headers.ipv4.dst_addr)) {
        if (IS_IPV4_MULTICAST_MAC(headers.ethernet.dst_addr)) {
          ipv4_multicast_table.apply();
          local_metadata.ipmc_table_hit = standard_metadata.mcast_grp != 0;
          // TODO: Use commented out code instead, once p4-symbolic
          // supports it.
          // local_metadata.ipmc_table_hit = ipv4_multicast_table.apply().hit()
        }
      } else { // IPv4 unicast.
        if (IS_UNICAST_MAC(headers.ethernet.dst_addr) &&
            local_metadata.admit_to_l3) {
          ipv4_table.apply();
        }
      }
    } else if (headers.ipv6.isValid()) {
      if (IS_MULTICAST_IPV6(headers.ipv6.dst_addr)) {
        if (IS_IPV6_MULTICAST_MAC(headers.ethernet.dst_addr)) {
          ipv6_multicast_table.apply();
          local_metadata.ipmc_table_hit = standard_metadata.mcast_grp != 0;
          // TODO: Use commented out code instead, once p4-symbolic
          // supports it.
          // local_metadata.ipmc_table_hit = ipv6_multicast_table.apply().hit()
        }
      } else { // IPv6 unicast.
        if (IS_UNICAST_MAC(headers.ethernet.dst_addr) &&
            local_metadata.admit_to_l3) {
          ipv6_table.apply();
        }
      }
    }
  }
}  // control routing_lookup
control routing_resolution(in headers_t headers,
                           inout local_metadata_t local_metadata,
                           inout standard_metadata_t standard_metadata) {

  // Tunnel id, only valid if `tunnel_id_valid` is true.
  bool tunnel_id_valid = false;
  tunnel_id_t tunnel_id_value;

  // Router interface id, only valid if `router_interface_id_valid` is true.
  bool router_interface_id_valid = false;
  router_interface_id_t router_interface_id_value;

  // Neighbor id, only valid if `neighbor_id_valid` is true.
  bool neighbor_id_valid = false;
  ipv6_addr_t neighbor_id_value;

  // Sets SAI_NEIGHBOR_ENTRY_ATTR_DST_MAC_ADDRESS.
  @id(ROUTING_SET_DST_MAC_ACTION_ID)
  action set_dst_mac(@id(1) @format(MAC_ADDRESS) ethernet_addr_t dst_mac) {
    local_metadata.packet_rewrites.dst_mac = dst_mac;
  }

  @p4runtime_role(P4RUNTIME_ROLE_ROUTING)
  @id(ROUTING_NEIGHBOR_TABLE_ID)
  table neighbor_table {
    key = {
      // Sets rif_id in sai_neighbor_entry_t. Can only refer to values that are
      // already programmed in the `router_interface_table`.
      router_interface_id_value : exact @id(1) @name("router_interface_id")
          @refers_to(router_interface_table, router_interface_id);
      // Sets ip_address in sai_neighbor_entry_t.
      neighbor_id_value : exact @id(2) @format(IPV6_ADDRESS)
          @name("neighbor_id");
    }
    actions = {
      @proto_id(1) set_dst_mac;
      @defaultonly NoAction;
    }
    const default_action = NoAction;
    size = NEIGHBOR_TABLE_MINIMUM_GUARANTEED_SIZE;
  }

  // Sets SAI_ROUTER_INTERFACE_ATTR_TYPE to SAI_ROUTER_INTERFACE_TYPE_SUB_PORT, and
  // SAI_ROUTER_INTERFACE_ATTR_PORT_ID, and
  // SAI_ROUTER_INTERFACE_ATTR_SRC_MAC_ADDRESS, and
  // SAI_ROUTER_INTERFACE_ATTR_OUTER_VLAN_ID.
  @id(ROUTING_SET_PORT_AND_SRC_MAC_AND_VLAN_ID_ACTION_ID)
  // TODO: Remove @unsupported when the switch supports this
  // action.
  @unsupported
  @action_restriction("
    // Disallow reserved VLAN IDs with implementation-defined semantics.
    vlan_id != 0 && vlan_id != 4095"
  )
  action set_port_and_src_mac_and_vlan_id(@id(1) port_id_t port,
                                          @id(2) @format(MAC_ADDRESS)
                                          ethernet_addr_t src_mac,
                                          @id(3) vlan_id_t vlan_id) {
    // Cast is necessary, because v1model does not define port using `type`.
    standard_metadata.egress_spec = (bit<PORT_BITWIDTH>)port;
    local_metadata.packet_rewrites.src_mac = src_mac;
    local_metadata.packet_rewrites.vlan_id = vlan_id;
  }

  // Sets SAI_ROUTER_INTERFACE_ATTR_TYPE to SAI_ROUTER_INTERFACE_TYPE_PORT, and
  // SAI_ROUTER_INTERFACE_ATTR_PORT_ID, and
  // SAI_ROUTER_INTERFACE_ATTR_SRC_MAC_ADDRESS.
  @id(ROUTING_SET_PORT_AND_SRC_MAC_ACTION_ID)
  action set_port_and_src_mac(@id(1) port_id_t port,
                              @id(2) @format(MAC_ADDRESS)
                              ethernet_addr_t src_mac) {
    set_port_and_src_mac_and_vlan_id(port, src_mac, INTERNAL_VLAN_ID);
  }

  @p4runtime_role(P4RUNTIME_ROLE_ROUTING)
  @id(ROUTING_ROUTER_INTERFACE_TABLE_ID)
  table router_interface_table {
    key = {
      router_interface_id_value : exact @id(1)
                                        @name("router_interface_id");
    }
    actions = {
      @proto_id(1) set_port_and_src_mac;
      @proto_id(2) set_port_and_src_mac_and_vlan_id;
      @defaultonly NoAction;
    }
    const default_action = NoAction;
    size = ROUTER_INTERFACE_TABLE_MINIMUM_GUARANTEED_SIZE;
  }

  // Sets SAI_NEXT_HOP_ATTR_TYPE to SAI_NEXT_HOP_TYPE_IP. Also sets
  // SAI_NEXT_HOP_ATTR_ROUTER_INTERFACE_ID, SAI_NEXT_HOP_ATTR_IP,
  // SAI_NEXT_HOP_ATTR_DISABLE_SRC_MAC_REWRITE,
  // SAI_NEXT_HOP_ATTR_DISABLE_DST_MAC_REWRITE,
  // SAI_NEXT_HOP_ATTR_DISABLE_DECREMENT_TTL and
  // SAI_NEXT_HOP_ATTR_DISABLE_VLAN_REWRITE based on action parameters.
  @id(ROUTING_SET_IP_NEXTHOP_AND_DISABLE_REWRITES_ACTION_ID)
  action set_ip_nexthop_and_disable_rewrites(
      @id(1)
      @refers_to(router_interface_table, router_interface_id)
      @refers_to(neighbor_table, router_interface_id)
      router_interface_id_t router_interface_id,
      @id(2) @format(IPV6_ADDRESS)
      @refers_to(neighbor_table, neighbor_id)
      ipv6_addr_t neighbor_id,
      // TODO: Use @format(BOOL) once PDPI
      // supports it.
      @id(3) bit<1> disable_decrement_ttl,
      @id(4) bit<1> disable_src_mac_rewrite,
      @id(5) bit<1> disable_dst_mac_rewrite,
      @id(6) bit<1> disable_vlan_rewrite) {
    router_interface_id_valid = true;
    router_interface_id_value = router_interface_id;
    neighbor_id_valid = true;
    neighbor_id_value = neighbor_id;
    local_metadata.enable_decrement_ttl = !(bool) disable_decrement_ttl;
    local_metadata.enable_src_mac_rewrite = !(bool) disable_src_mac_rewrite;
    local_metadata.enable_dst_mac_rewrite = !(bool) disable_dst_mac_rewrite;
    local_metadata.enable_vlan_rewrite = !(bool) disable_vlan_rewrite;
  }

  // Sets SAI_NEXT_HOP_ATTR_TYPE to SAI_NEXT_HOP_TYPE_IP, and
  // SAI_NEXT_HOP_ATTR_ROUTER_INTERFACE_ID, and SAI_NEXT_HOP_ATTR_IP.
  //
  // This action can only refer to `router_interface_id`s and `neighbor_id`s,
  // if `router_interface_id` is a key in the `router_interface_table`, and
  // the `(router_interface_id, neighbor_id)` pair is a key in the
  // `neighbor_table`.
  //
  // Note that the @refers_to annotation could be more precise if it allowed
  // specifying that the pair (router_interface_id, neighbor_id) refers to the
  // two match fields in neighbor_table. This is still correct, but less
  // precise.
  @id(ROUTING_SET_IP_NEXTHOP_ACTION_ID)
  action set_ip_nexthop(
      @id(1)
      @refers_to(router_interface_table, router_interface_id)
      @refers_to(neighbor_table, router_interface_id)
      router_interface_id_t router_interface_id,
      @id(2) @format(IPV6_ADDRESS)
      @refers_to(neighbor_table, neighbor_id)
      ipv6_addr_t neighbor_id) {
    set_ip_nexthop_and_disable_rewrites(router_interface_id, neighbor_id,
      /*disable_decrement_ttl*/0x0, /*disable_src_mac_rewrite*/0x0,
      /*disable_dst_mac_rewrite*/0x0, /*disable_vlan_rewrite*/0x0);
  }

  // Sets SAI_NEXT_HOP_ATTR_TYPE to SAI_NEXT_HOP_TYPE_TUNNEL_ENCAP, and
  // SAI_NEXT_HOP_ATTR_TUNNEL_ID and SAI_NEXT_HOP_ATTR_IP.
  //
  // This action encodes a SAI_NEXT_HOP_TYPE_TUNNEL_ENCAP, which also has a
  // SAI_NEXT_HOP_ATTR_IP, but does not take it as a parameter.
  // Because we are using P2P tunnels, this information is stored in the tunnel
  // referred to by the tunnel id, so we omit it here to avoid redundancy in our
  // specification.
  @id(ROUTING_SET_P2P_TUNNEL_ENCAP_NEXTHOP_ACTION_ID)
  action set_p2p_tunnel_encap_nexthop(@id(1) @refers_to(tunnel_table, tunnel_id)
                            tunnel_id_t tunnel_id) {
    tunnel_id_valid = true;
    tunnel_id_value = tunnel_id;
  }

  @p4runtime_role(P4RUNTIME_ROLE_ROUTING)
  @id(ROUTING_NEXTHOP_TABLE_ID)
  table nexthop_table {
    key = {
      local_metadata.nexthop_id_value : exact @id(1) @name("nexthop_id");
    }
    actions = {
      @proto_id(1) set_ip_nexthop;
      @proto_id(2) set_p2p_tunnel_encap_nexthop;
      @proto_id(3) set_ip_nexthop_and_disable_rewrites;
      @defaultonly NoAction;
    }
    const default_action = NoAction;
    size = NEXTHOP_TABLE_MINIMUM_GUARANTEED_SIZE;
  }

  // Sets SAI_TUNNEL_ATTR_TYPE to SAI_TUNNEL_TYPE_IPINIP_GRE,
  // SAI_TUNNEL_PEER_MODE to SAI_TUNNEL_PEER_MODE_P2P and
  // also sets SAI_TUNNEL_ATTR_ENCAP_SRC_IP, SAI_TUNNEL_ATTR_ENCAP_DST_IP
  // and SAI_TUNNEL_ATTR_UNDERLAY_INTERFACE.
  //
  // Because we are using P2P tunnels, this action requires an `encap_dst_ip`,
  // which will also be the `neighbor_id` of an associated `neighbor_table`
  // entry.
  @id(ROUTING_MARK_FOR_P2P_TUNNEL_ENCAP_ACTION_ID)
  action mark_for_p2p_tunnel_encap(
      @id(1) @format(IPV6_ADDRESS)
      ipv6_addr_t encap_src_ip,
      @id(2) @format(IPV6_ADDRESS)
      @refers_to(neighbor_table, neighbor_id)
      ipv6_addr_t encap_dst_ip,
      @id(3) @refers_to(neighbor_table, router_interface_id)
      @refers_to(router_interface_table, router_interface_id)
      router_interface_id_t router_interface_id) {
    local_metadata.tunnel_encap_src_ipv6 = encap_src_ip;
    local_metadata.tunnel_encap_dst_ipv6 = encap_dst_ip;
    local_metadata.apply_tunnel_encap_at_egress = true;
    set_ip_nexthop(router_interface_id, encap_dst_ip);
  }

  @p4runtime_role(P4RUNTIME_ROLE_ROUTING)
  @id(ROUTING_TUNNEL_TABLE_ID)
  table tunnel_table {
    key = {
      tunnel_id_value : exact @id(1)
                              @name("tunnel_id");
    }
    actions = {
      @proto_id(1) mark_for_p2p_tunnel_encap;
      @defaultonly NoAction;
    }
    const default_action = NoAction;
    size = ROUTING_TUNNEL_TABLE_MINIMUM_GUARANTEED_SIZE;
  }

  // TODO: When the P4RT compiler supports the size selector
  // annotation, this should be used to specify the semantics.
  // #if defined(SAI_INSTANTIATION_TOR)
  // @selector_size_semantics(WCMP_GROUP_SELECTOR_SIZE_SEMANTICS_TOR)
  // #else
  // @selector_size_semantics(WCMP_GROUP_SELECTOR_SIZE_SEMANTICS)
  // #endif
  // TODO: Uncomment when supported by the P4RT compiler.
  // @max_member_weight(WCMP_GROUP_SELECTOR_MAX_MEMBER_WEIGHT)
#if defined(SAI_INSTANTIATION_TOR)
  @max_group_size(WCMP_GROUP_SELECTOR_MAX_GROUP_SIZE_TOR)
#else
  @max_group_size(WCMP_GROUP_SELECTOR_MAX_GROUP_SIZE)
#endif
  @id(ROUTING_WCMP_GROUP_SELECTOR_ACTION_PROFILE_ID)
  action_selector(HashAlgorithm.identity,
#if defined(SAI_INSTANTIATION_TOR)
 WCMP_GROUP_SELECTOR_SIZE_TOR,
#else
 WCMP_GROUP_SELECTOR_SIZE,
#endif
                  WCMP_SELECTOR_INPUT_BITWIDTH)
      wcmp_group_selector;

  @p4runtime_role(P4RUNTIME_ROLE_ROUTING)
  @id(ROUTING_WCMP_GROUP_TABLE_ID)
  @oneshot()
  table wcmp_group_table {
    key = {
      local_metadata.wcmp_group_id_value : exact @id(1) @name("wcmp_group_id");
      local_metadata.wcmp_selector_input : selector;
    }
    actions = {
      @proto_id(1) set_nexthop_id(local_metadata);
      @defaultonly NoAction;
    }
    const default_action = NoAction;
        implementation = wcmp_group_selector;
#if defined(SAI_INSTANTIATION_TOR)
    size = WCMP_GROUP_TABLE_MINIMUM_GUARANTEED_SIZE_TOR;
#else
    size = WCMP_GROUP_TABLE_MINIMUM_GUARANTEED_SIZE;
#endif
  }

  apply {
    // TODO: Properly model the effect of admit_to_l3 on redirect
    // in acl_ingress according to SAI.
    if (local_metadata.admit_to_l3) {

      // The lpm tables may not set a valid `wcmp_group_id`, e.g. they may drop.
      if (local_metadata.wcmp_group_id_valid) {
        wcmp_group_table.apply();
      }

      // The lpm tables may not set a valid `nexthop_id`, e.g. they may drop.
      // The `wcmp_group_table` should always set a valid `nexthop_id`.
      if (local_metadata.nexthop_id_valid) {
        nexthop_table.apply();

        if (tunnel_id_valid) {
          tunnel_table.apply();
        }

        // The `nexthop_table` should always set a valid
        // `router_interface_id` and `neighbor_id`.
        if (router_interface_id_valid && neighbor_id_valid) {
          router_interface_table.apply();
          neighbor_table.apply();
        }
      }
    }
    // Add metadata that is relevant for punted packets.
    local_metadata.packet_in_target_egress_port = standard_metadata.egress_spec;
    local_metadata.packet_in_ingress_port = standard_metadata.ingress_port;
    // Act on ACL drop after routing resolution.
    if (local_metadata.acl_drop) {
      mark_to_drop(standard_metadata);
    }
  }
} // control routing_resolution.

#endif  // SAI_ROUTING_P4_
