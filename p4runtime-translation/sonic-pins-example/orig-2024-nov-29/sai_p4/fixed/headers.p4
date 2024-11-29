#ifndef SAI_HEADERS_P4_
#define SAI_HEADERS_P4_

#define ETHERTYPE_IPV4  0x0800
#define ETHERTYPE_IPV6  0x86dd
#define ETHERTYPE_ARP   0x0806
#define ETHERTYPE_LLDP  0x88cc
#define ETHERTYPE_8021Q 0x8100

#define IP_PROTOCOL_IPV4   0x04
#define IP_PROTOCOL_TCP    0x06
#define IP_PROTOCOL_UDP    0x11
#define IP_PROTOCOL_ICMP   0x01
#define IP_PROTOCOL_ICMPV6 0x3a
#define IP_PROTOCOL_IPV6   0x29
#define IP_PROTOCOLS_GRE   0x2f

typedef bit<48> ethernet_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<128> ipv6_addr_t;
typedef bit<12> vlan_id_t;
typedef bit<16> ether_type_t;

// "The VID value 0xFFF is reserved for implementation use; it must not be
// configured or transmitted." (https://en.wikipedia.org/wiki/IEEE_802.1Q).
const vlan_id_t INTERNAL_VLAN_ID = 0xfff;
// "The reserved value 0x000 indicates that the frame does not carry a VLAN ID;
// in this case, the 802.1Q tag specifies only a priority"
// (https://en.wikipedia.org/wiki/IEEE_802.1Q).
const vlan_id_t NO_VLAN_ID = 0x000;

#define IS_RESERVED_VLAN_ID(vlan_id) \
    (vlan_id == NO_VLAN_ID || vlan_id == INTERNAL_VLAN_ID)

// -- Protocol headers ---------------------------------------------------------

#define ETHERNET_HEADER_BYTES 14

header ethernet_t {
  ethernet_addr_t dst_addr;
  ethernet_addr_t src_addr;
  ether_type_t ether_type;
}

header vlan_t {
  // Note: Tag Protocol Identifier (TPID) will be parsed as the ether_type of
  // the ethernet header. It is technically a part of the vlan header but is
  // modeled like this to facilitate parsing and deparsing.
  bit<3> priority_code_point;      // PCP
  bit<1> drop_eligible_indicator;  // DEI
  vlan_id_t vlan_id;               // VID
  // Note: The next ether_type will be parsed as part of the vlan
  // header. It is technically a part of the ethernet header but is modeled like
  // this to facilitate parsing and deparsing.
  ether_type_t ether_type;
}

#define IPV4_HEADER_BYTES 20

header ipv4_t {
  bit<4> version;
  bit<4> ihl;
  bit<6> dscp;  // The 6 most significant bits of the diff_serv field.
  bit<2> ecn;   // The 2 least significant bits of the diff_serv field.
  bit<16> total_len;
  bit<16> identification;
  bit<1> reserved;
  bit<1> do_not_fragment;
  bit<1> more_fragments;
  bit<13> frag_offset;
  bit<8> ttl;
  bit<8> protocol;
  bit<16> header_checksum;
  ipv4_addr_t src_addr;
  ipv4_addr_t dst_addr;
}

#define IPV6_HEADER_BYTES 40

header ipv6_t {
  bit<4> version;
  bit<6> dscp;  // The 6 most significant bits of the traffic_class field.
  bit<2> ecn;   // The 2 least significant bits of the traffic_class field.
  bit<20> flow_label;
  bit<16> payload_length;
  bit<8> next_header;
  bit<8> hop_limit;
  ipv6_addr_t src_addr;
  ipv6_addr_t dst_addr;
}

#define UDP_HEADER_BYTES 8

header udp_t {
  bit<16> src_port;
  bit<16> dst_port;
  bit<16> hdr_length;
  bit<16> checksum;
}

header tcp_t {
  bit<16> src_port;
  bit<16> dst_port;
  bit<32> seq_no;
  bit<32> ack_no;
  bit<4> data_offset;
  bit<4> res;
  bit<8> flags;
  bit<16> window;
  bit<16> checksum;
  bit<16> urgent_ptr;
}

header icmp_t {
  bit<8> type;
  bit<8> code;
  bit<16> checksum;
  bit<32> rest_of_header;
}

header arp_t {
  bit<16> hw_type;
  bit<16> proto_type;
  bit<8> hw_addr_len;
  bit<8> proto_addr_len;
  bit<16> opcode;
  bit<48> sender_hw_addr;
  bit<32> sender_proto_addr;
  bit<48> target_hw_addr;
  bit<32> target_proto_addr;
}

#define GRE_HEADER_BYTES 4

header gre_t {
  bit<1> checksum_present;
  bit<1> routing_present;
  bit<1> key_present;
  bit<1> sequence_present;
  bit<1> strict_source_route;
  bit<3> recursion_control;
  bit<1> acknowledgement_present;
  bit<4> flags;
  bit<3> version;
  bit<16> protocol;
}

#define IPFIX_HEADER_BYTES 16

// IP Flow Information Export (IPFIX) header, pursuant to RFC 7011 section 3.1.
header ipfix_t {
  // Version of IPFIX to which this Message conforms.
  bit<16> version_number;
  // Total length of the IPFIX Message, measured in octets, including
  // Message Header and Set(s).
  bit<16> length;
  // Time at which the IPFIX Message Header leaves the Exporter,
  // expressed in seconds since the UNIX epoch.
  bit<32> export_time;
  // Incremental sequence counter modulo 2^32 of all IPFIX Data Records
  // sent in the current stream.
  bit<32> sequence_number;
  // An identifier of the Observation Domain that is locally
  // unique to the Exporting Process.
  bit<32> observation_domain_id;
}

#define PSAMP_EXTENDED_BYTES 28
// PSAMP extended header, pursuant to RFC5476.
header psamp_extended_t {
  bit<16> template_id;
  bit<16> length;
  // Ingress timestamp in nanoseconds.
  bit<64> observation_time;
  bit<16> flowset;
  bit<16> next_hop_index;
  bit<16> epoch;
  bit<16> ingress_port;
  bit<16> egress_port;
  bit<16> user_meta_field;
  bit<8> dlb_id;
  bit<8> variable_length;
  bit<16> packet_sampled_length;
}


#endif  // SAI_HEADERS_P4_
