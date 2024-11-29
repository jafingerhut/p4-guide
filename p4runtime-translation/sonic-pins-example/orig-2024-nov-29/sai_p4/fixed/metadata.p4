#ifndef SAI_METADATA_P4_
#define SAI_METADATA_P4_

#include "ids.h"
#include "headers.p4"
#include "bitwidths.p4"

// -- Preserved Field Lists ----------------------------------------------------

// The field list numbers used in @field_list annotations to identify the fields
// that need to be preserved during clone/recirculation/etc. operations.
enum bit<8> PreservedFieldList {
  MIRROR_AND_PACKET_IN_COPY = 8w1
};

// -- Translated Types ---------------------------------------------------------

// BMv2 does not support @p4runtime_translation.

#ifndef PLATFORM_BMV2
@p4runtime_translation("", string)
#endif
type bit<NEXTHOP_ID_BITWIDTH> nexthop_id_t;

#ifndef PLATFORM_BMV2
@p4runtime_translation("", string)
#endif
type bit<TUNNEL_ID_BITWIDTH> tunnel_id_t;

#ifndef PLATFORM_BMV2
@p4runtime_translation("", string)
#endif
type bit<WCMP_GROUP_ID_BITWIDTH> wcmp_group_id_t;


#ifndef PLATFORM_BMV2
@p4runtime_translation("", string)
// TODO: The following annotation is not yet standard, and not yet
// understood by p4-symbolic. Work with the P4Runtime WG to standardize the
// annotation (or a similar annotation), and teach it to p4-symbolic.
@p4runtime_translation_mappings({
  // The "default VRF", 0, corresponds to the empty string, "", in P4Runtime.
  {"", 0},
})
#endif
type bit<VRF_BITWIDTH> vrf_id_t;

const vrf_id_t kDefaultVrf = 0;

#ifndef PLATFORM_BMV2
@p4runtime_translation("", string)
#endif
type bit<ROUTER_INTERFACE_ID_BITWIDTH> router_interface_id_t;

#ifndef PLATFORM_BMV2
@p4runtime_translation("", string)
#endif
type bit<PORT_BITWIDTH> port_id_t;

#ifndef PLATFORM_BMV2
@p4runtime_translation("", string)
#endif
type bit<MIRROR_SESSION_ID_BITWIDTH> mirror_session_id_t;

#ifndef PLATFORM_BMV2
@p4runtime_translation("", string)
#endif
type bit<QOS_QUEUE_BITWIDTH> qos_queue_t;

// -- Untranslated Types -------------------------------------------------------

typedef bit<ROUTE_METADATA_BITWIDTH> route_metadata_t;
typedef bit<ACL_METADATA_BITWIDTH> acl_metadata_t;
typedef bit<MULTICAST_GROUP_ID_BITWIDTH> multicast_group_id_t;
typedef bit<REPLICA_INSTANCE_BITWIDTH> replica_instance_t;

// -- Meters -------------------------------------------------------------------

enum bit<2> MeterColor_t {
  GREEN = 0,
  YELLOW = 1,
  RED = 2
};

// -- Packet IO headers --------------------------------------------------------

@controller_header("packet_in")
header packet_in_header_t {
  // The port the packet ingressed on.
  @id(PACKET_IN_INGRESS_PORT_ID)
  port_id_t ingress_port;
  // The initial intended egress port decided for the packet by the pipeline.
  @id(PACKET_IN_TARGET_EGRESS_PORT_ID)
  port_id_t target_egress_port;
  // Padding field to align the header to 8-bit multiple, as required by BMv2.
  // Carries no information.
  //
  // Contrary to the corresponding field in the `packet_out` header, we include
  // this field only on BMv2, as clients will generally ignore this field anyhow
  // and thus not observe this minor API deviation.
  // TODO: Handle packet-in uniformly for all platforms.
#if defined(PLATFORM_BMV2) || defined(PLATFORM_P4SYMBOLIC)
  @id(PACKET_IN_UNUSED_PAD_ID)
  @padding
  bit<6> unused_pad;
#endif
}

@controller_header("packet_out")
header packet_out_header_t {
  // The port this packet should egress out of when `submit_to_ingress == 0`.
  // Meaningless when `submit_to_ingress == 1`.
  @id(PACKET_OUT_EGRESS_PORT_ID)
  port_id_t egress_port;
  // Indicates if the packet should go through the ingress pipeline like a
  // dataplane packet, or be sent straight out of the given `egress_port`.
  @id(PACKET_OUT_SUBMIT_TO_INGRESS_ID)
  bit<1> submit_to_ingress;
  // Padding field to align the header to 8-bit multiple, as required by BMv2.
  // Carries no information.
  //
  // Technically this makes sense only for BMv2, but we include it on all
  // platforms so clients don't have to make a distinction in packet-out
  // requests.
  @id(PACKET_OUT_UNUSED_PAD_ID)
  @padding
  bit<6> unused_pad;
}

// -- Per Packet State ---------------------------------------------------------

struct headers_t {
// TODO: Clean up once we have better solution to handle packet-in
// across platforms.
#if defined(PLATFORM_BMV2) || defined(PLATFORM_P4SYMBOLIC)
  // Never extracted during parsing, but serialized during deparsing for packets
  // punted to the controller.
  packet_in_header_t packet_in_header;
#endif

  // PacketOut header; extracted only for packets received from the controller.
  packet_out_header_t packet_out_header;

  // -- mirroring encap headers ------------------------------------------------
  ethernet_t mirror_encap_ethernet;
  vlan_t mirror_encap_vlan;
  ipv6_t mirror_encap_ipv6;
  udp_t mirror_encap_udp;
  ipfix_t ipfix;
  psamp_extended_t psamp_extended;
  // -- end of mirroring encap headers -----------------------------------------

  ethernet_t ethernet;
  vlan_t vlan;

  // Not extracted during parsing.
  ipv6_t tunnel_encap_ipv6;
  gre_t tunnel_encap_gre;

  ipv4_t ipv4;
  ipv6_t ipv6;

  // Inner IP-in-IP headers.
  ipv4_t inner_ipv4;
  ipv6_t inner_ipv6;

  icmp_t icmp;
  tcp_t tcp;
  udp_t udp;
  arp_t arp;
}

// Header fields rewritten by the ingress pipeline. Rewrites are computed and
// stored in this struct, but actual rewriting is dealyed until the egress
// pipeline so that the original values aren't overridden and can be matched on.
struct packet_rewrites_t {
  ethernet_addr_t src_mac;
  ethernet_addr_t dst_mac;
  vlan_id_t vlan_id;
}

// Local metadata for each packet being processed.
struct local_metadata_t {
  // If true, ingress packets with ingress VID and egress packets with
  // egress VID besides the reserved ones (0, 4095) get dropped.
  // This field is preserved after replication since VLAN checks should be
  // applied regardless of instance type of a packet.
  @field_list(PreservedFieldList.MIRROR_AND_PACKET_IN_COPY)
  bool enable_vlan_checks;

  // The VLAN ID used for the packet throughout the pipeline. If the input
  // packet has a VLAN tag, the VID from the outer VLAN tag is used
  // (and the VLAN header gets invalidated at the beginning of the ingress
  // pipeline). Otherwise, the ports' native VLAN ID (4095) is used.
  // The pre-ingress stage can modify this value. The value is rewritten in
  // router_interface table (unless VLAN rewrite is disabled). In that case,
  // the actual rewrite takes place in the egress pipeline. This value is also
  // used at the end of the egress pipeline to determine whether or not the
  // packet should be VLAN tagged (if not dropped).
  vlan_id_t vlan_id;

  bool admit_to_l3;
  vrf_id_t vrf_id;

  // Rewrite related fields.
  bool enable_decrement_ttl;
  bool enable_src_mac_rewrite;
  bool enable_dst_mac_rewrite;
  bool enable_vlan_rewrite;
  packet_rewrites_t packet_rewrites;

  bit<16> l4_src_port;
  bit<16> l4_dst_port;
  bit<WCMP_SELECTOR_INPUT_BITWIDTH> wcmp_selector_input;

  // Tunnel related fields.
  bool apply_tunnel_decap_at_end_of_pre_ingress;
  bool apply_tunnel_encap_at_egress;
  ipv6_addr_t tunnel_encap_src_ipv6;
  ipv6_addr_t tunnel_encap_dst_ipv6;

  // If true, the packet needs to be copied to the CPU at the end of the ingress
  // pipeline.
  bool marked_to_copy;

  // -- Mirroring related fields -----------------------------------------------
  // We can't group them into a struct as BMv2 doesn't support passing structs
  // into clone3.
  // If true, the packet needs to be mirrored at the end of the ingress
  // pipeline.
  bool marked_to_mirror;
  // Mirror session to mirror the packet.
  // Valid iff marked_to_mirror is true.
  mirror_session_id_t mirror_session_id;
  port_id_t mirror_egress_port;
  @field_list(PreservedFieldList.MIRROR_AND_PACKET_IN_COPY)
  ethernet_addr_t mirror_encap_src_mac;
  @field_list(PreservedFieldList.MIRROR_AND_PACKET_IN_COPY)
  ethernet_addr_t mirror_encap_dst_mac;
  @field_list(PreservedFieldList.MIRROR_AND_PACKET_IN_COPY)
  vlan_id_t mirror_encap_vlan_id;
  @field_list(PreservedFieldList.MIRROR_AND_PACKET_IN_COPY)
  ipv6_addr_t mirror_encap_src_ip;
  @field_list(PreservedFieldList.MIRROR_AND_PACKET_IN_COPY)
  ipv6_addr_t mirror_encap_dst_ip;
  @field_list(PreservedFieldList.MIRROR_AND_PACKET_IN_COPY)
  bit<16> mirror_encap_udp_src_port;
  @field_list(PreservedFieldList.MIRROR_AND_PACKET_IN_COPY)
  bit<16> mirror_encap_udp_dst_port;
  // -- end of mirroring related fields ----------------------------------------

  // Packet-in related fields, which we can't group into a struct, because BMv2
  // doesn't support passing structs in clone3.
  // We model packet-in in SAI P4 by using the replication engine to make a
  // clone of the punted packet and then send the clone to the controller. But
  // the standard metadata of the packet clone will be empty, that's a problem
  // because the controller needs to know the ingress port and expected egress
  // port of the punted packet. To solve this problem, we save the targeted
  // egress port and ingress port of the punted packet in local metadata and use
  // clone_preserving_field_list to preserve these local metadata fields when
  // cloning the punted packet.
  // The value to be copied into the `ingress_port` field of packet_in_header on
  // punted packets.
  @field_list(PreservedFieldList.MIRROR_AND_PACKET_IN_COPY)
  bit<PORT_BITWIDTH> packet_in_ingress_port;
  // The value to be copied into the `target_egress_port` field of
  // packet_in_header on punted packets.
  @field_list(PreservedFieldList.MIRROR_AND_PACKET_IN_COPY)
  bit<PORT_BITWIDTH> packet_in_target_egress_port;

  MeterColor_t color;
  // We consistently use local_metadata.ingress_port instead of
  // standard_metadata.ingress_port in the P4 tables to ensure that the P4Info
  // has port_id_t as the type for all fields that match on ports. This allows
  // tools to treat ports specially (e.g. a fuzzer).
  port_id_t ingress_port;
  // The following field corresponds to SAI_ROUTE_ENTRY_ATTR_META_DATA/
  // SAI_ACL_TABLE_ATTR_FIELD_ROUTE_DST_USER_META.
  route_metadata_t route_metadata;
  // ACL metadata can be set with SAI_ACL_ACTION_TYPE_SET_ACL_META_DATA, and
  // read from SAI_ACL_TABLE_ATTR_FIELD_ACL_USER_META.
  acl_metadata_t acl_metadata;
  // When controller sends a packet-out packet, the packet will be submitted to
  // the ingress pipleine by default. But sometimes we want to skip the ingress
  // pipeline for packet-out, and we cannot skip using the 'exit' statement as
  // it is not supported in p4-symbolic yet: b/184062335. So we use this field
  // as a workaround.
  // TODO: Clean up this workaround after 'exit' is supported in
  // p4-symbolic.
  bool bypass_ingress;

  // Metadata shared between routing, acl_ingress, and routing_resolution
  // control blocks.
  bool wcmp_group_id_valid;
  // Wcmp group id, only valid if `wcmp_group_id_valid` is true.
  wcmp_group_id_t wcmp_group_id_value;
  bool nexthop_id_valid;
  // Nexthop id, only valid if `nexthop_id_valid` is true.
  nexthop_id_t nexthop_id_value;
  // After execution of the `routing_lookup` stage, Indicates if an entry in
  // the `ipv4_multicast` or `ipv6_multicast` table was hit.
  bool ipmc_table_hit;

  // Determines if packet was dropped in ACL ingress/egress stage. If true, the
  // actual call to mark_to_drop (that affects standard_metadata) takes place at
  // the end of the respective pipeline.
  // This is done this way because we want to call mark_to_drop after
  // determining the target_egress_port through the value assigned to
  // standard_metadata.egress_spec (which happens in routing_resolution *after*
  // ACL ingress) for punted packets.
  bool acl_drop;
}

#endif  // SAI_METADATA_P4_
