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

#ifndef _DASH_TUNNEL_P4_
#define _DASH_TUNNEL_P4_

#include "dash_headers.p4"

#ifdef TARGET_BMV2_V1MODEL
#define PUSH_VXLAN_TUNNEL_DEF(underlay_id, overlay_id) \
action push_vxlan_tunnel_ ## underlay_id ## (inout headers_t hdr, \
                                       in EthernetAddress overlay_dmac, \
                                       in EthernetAddress underlay_dmac, \
                                       in EthernetAddress underlay_smac, \
                                       in IPv4Address underlay_dip, \
                                       in IPv4Address underlay_sip, \
                                       in bit<24> tunnel_key) { \
    hdr. ## overlay_id ## _ethernet.dst_addr = overlay_dmac; \
    hdr. ## underlay_id ## _ethernet.setValid(); \
    hdr. ## underlay_id ## _ethernet.dst_addr = underlay_dmac; \
    hdr. ## underlay_id ## _ethernet.src_addr = underlay_smac; \
    hdr. ## underlay_id ## _ethernet.ether_type = IPV4_ETHTYPE; \
    \
    hdr. ## underlay_id ## _ipv4.setValid(); \
    hdr. ## underlay_id ## _ipv4.total_len = hdr. ## overlay_id ## _ipv4.total_len*(bit<16>)(bit<1>)hdr.  ## overlay_id ## _ipv4.isValid() + \
                         hdr. ## overlay_id ## _ipv6.payload_length*(bit<16>)(bit<1>)hdr. ## overlay_id ## _ipv6.isValid() + \
                         IPV6_HDR_SIZE*(bit<16>)(bit<1>)hdr. ## overlay_id ## _ipv6.isValid() + \
                         ETHER_HDR_SIZE + \
                         IPV4_HDR_SIZE + \
                         UDP_HDR_SIZE + \
                         VXLAN_HDR_SIZE; \
    hdr. ## underlay_id ## _ipv4.version = 4; \
    hdr. ## underlay_id ## _ipv4.ihl = 5; \
    hdr. ## underlay_id ## _ipv4.diffserv = 0; \
    hdr. ## underlay_id ## _ipv4.identification = 1; \
    hdr. ## underlay_id ## _ipv4.flags = 0; \
    hdr. ## underlay_id ## _ipv4.frag_offset = 0; \
    hdr. ## underlay_id ## _ipv4.ttl = 64; \
    hdr. ## underlay_id ## _ipv4.protocol = UDP_PROTO; \
    hdr. ## underlay_id ## _ipv4.dst_addr = underlay_dip; \
    hdr. ## underlay_id ## _ipv4.src_addr = underlay_sip; \
    hdr. ## underlay_id ## _ipv4.hdr_checksum = 0; \
    \
    hdr. ## underlay_id ## _udp.setValid(); \
    hdr. ## underlay_id ## _udp.src_port = 0; \
    hdr. ## underlay_id ## _udp.dst_port = UDP_PORT_VXLAN; \
    hdr. ## underlay_id ## _udp.length = hdr. ## overlay_id ## _ipv4.total_len*(bit<16>)(bit<1>)hdr. ## overlay_id ## _ipv4.isValid() + \
                     hdr. ## overlay_id ## _ipv6.payload_length*(bit<16>)(bit<1>)hdr. ## overlay_id ## _ipv6.isValid() + \
                     IPV6_HDR_SIZE*(bit<16>)(bit<1>)hdr. ## overlay_id ## _ipv6.isValid() + \
                     UDP_HDR_SIZE + \
                     VXLAN_HDR_SIZE + \
                     ETHER_HDR_SIZE; \
    hdr. ## underlay_id ## _udp.checksum = 0; \
    \
    hdr. ## underlay_id ## _vxlan.setValid(); \
    hdr. ## underlay_id ## _vxlan.reserved = 0; \
    hdr. ## underlay_id ## _vxlan.reserved_2 = 0; \
    hdr. ## underlay_id ## _vxlan.flags = 0; \
    hdr. ## underlay_id ## _vxlan.vni = tunnel_key; \
}
#endif

#ifdef TARGET_DPDK_PNA
#define PUSH_VXLAN_TUNNEL_DEF(underlay_id, overlay_id) \
action push_vxlan_tunnel_ ## underlay_id ## (inout headers_t hdr, \
                                       in EthernetAddress overlay_dmac, \
                                       in EthernetAddress underlay_dmac, \
                                       in EthernetAddress underlay_smac, \
                                       in IPv4Address underlay_dip, \
                                       in IPv4Address underlay_sip, \
                                       in bit<24> tunnel_key) { \
    hdr. ## overlay_id ## _ethernet.dst_addr = overlay_dmac; \
    hdr. ## underlay_id ## _ethernet.setValid(); \
    hdr. ## underlay_id ## _ethernet.dst_addr = underlay_dmac; \
    hdr. ## underlay_id ## _ethernet.src_addr = underlay_smac; \
    hdr. ## underlay_id ## _ethernet.ether_type = IPV4_ETHTYPE; \
    \
    hdr. ## underlay_id ## _ipv4.setValid(); \
    bit<16> ## overlay_id ## _ip_len = 0; \
    if (hdr. ## overlay_id ## _ipv4.isValid()) { \
        ## overlay_id ## _ip_len = ## overlay_id ## _ip_len + hdr. ## overlay_id ## _ipv4.total_len; \
    } \
    if (hdr. ## overlay_id ## _ipv6.isValid()) { \
        ## overlay_id ## _ip_len = ( ## overlay_id ## _ip_len + IPV6_HDR_SIZE + \
            hdr. ## overlay_id ## _ipv6.payload_length); \
    } \
    hdr. ## underlay_id ## _ipv4.total_len = (ETHER_HDR_SIZE + IPV4_HDR_SIZE + UDP_HDR_SIZE + \
        VXLAN_HDR_SIZE + ## overlay_id ## _ip_len); \
    hdr. ## underlay_id ## _ipv4.version = 4; \
    hdr. ## underlay_id ## _ipv4.ihl = 5; \
    hdr. ## underlay_id ## _ipv4.diffserv = 0; \
    hdr. ## underlay_id ## _ipv4.identification = 1; \
    hdr. ## underlay_id ## _ipv4.flags = 0; \
    hdr. ## underlay_id ## _ipv4.frag_offset = 0; \
    hdr. ## underlay_id ## _ipv4.ttl = 64; \
    hdr. ## underlay_id ## _ipv4.protocol = UDP_PROTO; \
    hdr. ## underlay_id ## _ipv4.dst_addr = underlay_dip; \
    hdr. ## underlay_id ## _ipv4.src_addr = underlay_sip; \
    hdr. ## underlay_id ## _ipv4.hdr_checksum = 0; \
    \
    hdr. ## underlay_id ## _udp.setValid(); \
    hdr. ## underlay_id ## _udp.src_port = 0; \
    hdr. ## underlay_id ## _udp.dst_port = UDP_PORT_VXLAN; \
    hdr. ## underlay_id ## _udp.length = (UDP_HDR_SIZE + VXLAN_HDR_SIZE + ETHER_HDR_SIZE + \
        ## overlay_id ## _ip_len); \
    hdr. ## underlay_id ## _udp.checksum = 0; \
    \
    hdr. ## underlay_id ## _vxlan.setValid(); \
    hdr. ## underlay_id ## _vxlan.reserved = 0; \
    hdr. ## underlay_id ## _vxlan.reserved_2 = 0; \
    hdr. ## underlay_id ## _vxlan.flags = 0; \
    hdr. ## underlay_id ## _vxlan.vni = tunnel_key; \
}
#endif

#ifdef TARGET_BMV2_V1MODEL
#define PUSH_NVGRE_TUNNEL_DEF(underlay_id, overlay_id) \
action push_nvgre_tunnel_ ## underlay_id ## (inout headers_t hdr, \
                                       in EthernetAddress overlay_dmac, \
                                       in EthernetAddress underlay_dmac, \
                                       in EthernetAddress underlay_smac, \
                                       in IPv4Address underlay_dip, \
                                       in IPv4Address underlay_sip, \
                                       in bit<24> tunnel_key) { \
    hdr. ## overlay_id ## _ethernet.dst_addr = overlay_dmac; \
    hdr. ## underlay_id ## _ethernet.setValid(); \
    hdr. ## underlay_id ## _ethernet.dst_addr = underlay_dmac; \
    hdr. ## underlay_id ## _ethernet.src_addr = underlay_smac; \
    hdr. ## underlay_id ## _ethernet.ether_type = IPV4_ETHTYPE; \
    \
    hdr. ## underlay_id ## _ipv4.setValid(); \
    hdr. ## underlay_id ## _ipv4.total_len = hdr. ## overlay_id ## _ipv4.total_len*(bit<16>)(bit<1>)hdr. ## overlay_id ## _ipv4.isValid() + \
                         hdr. ## overlay_id ## _ipv6.payload_length*(bit<16>)(bit<1>)hdr. ## overlay_id ## _ipv6.isValid() + \
                         IPV6_HDR_SIZE*(bit<16>)(bit<1>)hdr. ## overlay_id ## _ipv6.isValid() + \
                         ETHER_HDR_SIZE + \
                         IPV4_HDR_SIZE + \
                         NVGRE_HDR_SIZE; \
    hdr. ## underlay_id ## _ipv4.total_len = (ETHER_HDR_SIZE + IPV4_HDR_SIZE + \
            NVGRE_HDR_SIZE + hdr. ## underlay_id ## _ipv4.total_len); \
    hdr. ## underlay_id ## _ipv4.version = 4; \
    hdr. ## underlay_id ## _ipv4.ihl = 5; \
    hdr. ## underlay_id ## _ipv4.diffserv = 0; \
    hdr. ## underlay_id ## _ipv4.identification = 1; \
    hdr. ## underlay_id ## _ipv4.flags = 0; \
    hdr. ## underlay_id ## _ipv4.frag_offset = 0; \
    hdr. ## underlay_id ## _ipv4.ttl = 64; \
    hdr. ## underlay_id ## _ipv4.protocol = NVGRE_PROTO; \
    hdr. ## underlay_id ## _ipv4.dst_addr = underlay_dip; \
    hdr. ## underlay_id ## _ipv4.src_addr = underlay_sip; \
    hdr. ## underlay_id ## _ipv4.hdr_checksum = 0; \
    \
    hdr. ## underlay_id ## _nvgre.setValid(); \
    hdr. ## underlay_id ## _nvgre.flags = 4; \
    hdr. ## underlay_id ## _nvgre.reserved = 0; \
    hdr. ## underlay_id ## _nvgre.version = 0; \
    hdr. ## underlay_id ## _nvgre.protocol_type = 0x6558; \
    hdr. ## underlay_id ## _nvgre.vsid = tunnel_key; \
    hdr. ## underlay_id ## _nvgre.flow_id = 0; \
}
#endif

#ifdef TARGET_DPDK_PNA
#define PUSH_NVGRE_TUNNEL_DEF(underlay_id, overlay_id) \
action push_nvgre_tunnel_ ## underlay_id ## (inout headers_t hdr, \
                                       in EthernetAddress overlay_dmac, \
                                       in EthernetAddress underlay_dmac, \
                                       in EthernetAddress underlay_smac, \
                                       in IPv4Address underlay_dip, \
                                       in IPv4Address underlay_sip, \
                                       in bit<24> tunnel_key) { \
    hdr. ## overlay_id ## _ethernet.dst_addr = overlay_dmac; \
    hdr. ## underlay_id ## _ethernet.setValid(); \
    hdr. ## underlay_id ## _ethernet.dst_addr = underlay_dmac; \
    hdr. ## underlay_id ## _ethernet.src_addr = underlay_smac; \
    hdr. ## underlay_id ## _ethernet.ether_type = IPV4_ETHTYPE; \
    \
    hdr. ## underlay_id ## _ipv4.setValid(); \
    bit<16>  ## overlay_id ## _ip_len = 0; \
    if (hdr. ## overlay_id ## _ipv4.isValid()) { \
        ## overlay_id ## _ip_len = ## overlay_id ## _ip_len + hdr. ## overlay_id ## _ipv4.total_len; \
    } \
    if (hdr. ## overlay_id ## _ipv6.isValid()) { \
        ## overlay_id ## _ip_len = (## overlay_id ## _ip_len + IPV6_HDR_SIZE + \
            hdr. ## overlay_id ## _ipv6.payload_length); \
    } \
    hdr. ## underlay_id ## _ipv4.total_len = (ETHER_HDR_SIZE + IPV4_HDR_SIZE + UDP_HDR_SIZE + \
        NVGRE_HDR_SIZE + ## overlay_id ## _ip_len); \
    hdr. ## underlay_id ## _ipv4.total_len = (ETHER_HDR_SIZE + IPV4_HDR_SIZE + \
            NVGRE_HDR_SIZE + hdr. ## underlay_id ## _ipv4.total_len); \
    hdr. ## underlay_id ## _ipv4.version = 4; \
    hdr. ## underlay_id ## _ipv4.ihl = 5; \
    hdr. ## underlay_id ## _ipv4.diffserv = 0; \
    hdr. ## underlay_id ## _ipv4.identification = 1; \
    hdr. ## underlay_id ## _ipv4.flags = 0; \
    hdr. ## underlay_id ## _ipv4.frag_offset = 0; \
    hdr. ## underlay_id ## _ipv4.ttl = 64; \
    hdr. ## underlay_id ## _ipv4.protocol = NVGRE_PROTO; \
    hdr. ## underlay_id ## _ipv4.dst_addr = underlay_dip; \
    hdr. ## underlay_id ## _ipv4.src_addr = underlay_sip; \
    hdr. ## underlay_id ## _ipv4.hdr_checksum = 0; \
    \
    hdr. ## underlay_id ## _nvgre.setValid(); \
    hdr. ## underlay_id ## _nvgre.flags = 4; \
    hdr. ## underlay_id ## _nvgre.reserved = 0; \
    hdr. ## underlay_id ## _nvgre.version = 0; \
    hdr. ## underlay_id ## _nvgre.protocol_type = 0x6558; \
    hdr. ## underlay_id ## _nvgre.vsid = tunnel_key; \
    hdr. ## underlay_id ## _nvgre.flow_id = 0; \
}
#endif

PUSH_VXLAN_TUNNEL_DEF(u0, customer)
PUSH_VXLAN_TUNNEL_DEF(u1, u0)
PUSH_NVGRE_TUNNEL_DEF(u0, customer)
PUSH_NVGRE_TUNNEL_DEF(u1, u0)

#define tunnel_encap(hdr, \
                    meta, \
                    overlay_dmac, \
                    underlay_dmac, \
                    underlay_smac, \
                    underlay_dip, \
                    underlay_sip, \
                    dash_encapsulation, \
                    tunnel_key) { \
    if (dash_encapsulation == dash_encapsulation_t.VXLAN) { \
        if (meta.tunnel_pointer == 0) { \
            push_vxlan_tunnel_u0(hdr, \
                           overlay_dmac, \
                           underlay_dmac, \
                           underlay_smac, \
                           underlay_dip, \
                           underlay_sip, \
                           tunnel_key); \
        } else if (meta.tunnel_pointer == 1) { \
            push_vxlan_tunnel_u1(hdr, \
                           overlay_dmac, \
                           underlay_dmac, \
                           underlay_smac, \
                           underlay_dip, \
                           underlay_sip, \
                           tunnel_key); \
        } \
    } else if (dash_encapsulation == dash_encapsulation_t.NVGRE) { \
        if (meta.tunnel_pointer == 0) { \
            push_vxlan_tunnel_u0(hdr, \
                           overlay_dmac, \
                           underlay_dmac, \
                           underlay_smac, \
                           underlay_dip, \
                           underlay_sip, \
                           tunnel_key); \
        } else if (meta.tunnel_pointer == 1) { \
            push_vxlan_tunnel_u1(hdr, \
                           overlay_dmac, \
                           underlay_dmac, \
                           underlay_smac, \
                           underlay_dip, \
                           underlay_sip, \
                           tunnel_key); \
        } \
    } \
    \
    meta.tunnel_pointer = meta.tunnel_pointer + 1; \
}

/* Tunnel decap can only pop u0 because that's what was parsed.
   If the packet has more than one tunnel on ingress, BM will
   reparse it.
   It is also assumed, that if DASH pushes more than one tunnel,
   they won't need to pop them */
action tunnel_decap(inout headers_t hdr, inout metadata_t meta) {
    hdr.u0_ethernet.setInvalid();
    hdr.u0_ipv4.setInvalid();
    hdr.u0_ipv6.setInvalid();
    hdr.u0_nvgre.setInvalid();
    hdr.u0_vxlan.setInvalid();
    hdr.u0_udp.setInvalid();

    meta.tunnel_pointer = 0;
}

#endif /* _DASH_TUNNEL_P4_ */
