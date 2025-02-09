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

#ifndef _SIRIUS_VXLAN_P4_
#define _SIRIUS_VXLAN_P4_

#include "dash_headers.p4"

action vxlan_encap(inout headers_t hdr,
                   in EthernetAddress underlay_dmac,
                   in EthernetAddress underlay_smac,
                   in IPv4Address underlay_dip,
                   in IPv4Address underlay_sip,
                   in EthernetAddress overlay_dmac, 
                   in bit<24> vni) {
    hdr.inner_ethernet = hdr.ethernet;
    hdr.inner_ethernet.dst_addr = overlay_dmac;
    hdr.ethernet.setInvalid();

    hdr.inner_ipv4 = hdr.ipv4;
    hdr.ipv4.setInvalid();
    hdr.inner_ipv6 = hdr.ipv6;
    hdr.ipv6.setInvalid();
    hdr.inner_tcp = hdr.tcp;
    hdr.tcp.setInvalid();
    hdr.inner_udp = hdr.udp;
    hdr.udp.setInvalid();

    hdr.ethernet.setValid();
    hdr.ethernet.dst_addr = underlay_dmac;
    hdr.ethernet.src_addr = underlay_smac;
    hdr.ethernet.ether_type = IPV4_ETHTYPE;

    hdr.ipv4.setValid();
    hdr.ipv4.version = 4;
    hdr.ipv4.ihl = 5;
    hdr.ipv4.diffserv = 0;
#ifdef TARGET_BMV2_V1MODEL
    hdr.ipv4.total_len = hdr.inner_ipv4.total_len*(bit<16>)(bit<1>)hdr.inner_ipv4.isValid() + \
                         hdr.inner_ipv6.payload_length*(bit<16>)(bit<1>)hdr.inner_ipv6.isValid() + \
                         IPV6_HDR_SIZE*(bit<16>)(bit<1>)hdr.inner_ipv6.isValid() + \
                         ETHER_HDR_SIZE + \
                         IPV4_HDR_SIZE + \
                         UDP_HDR_SIZE + \
                         VXLAN_HDR_SIZE;
#endif // TARGET_BMV2_V1MODEL
#ifdef TARGET_DPDK_PNA
    // p4c-dpdk as of 2023-Jan-26 does not support multplication of
    // run-time variable values.  It does support 'if' statements
    // inside of P4 action bodies.
    bit<16> inner_ip_len = 0;
    if (hdr.inner_ipv4.isValid()) {
        inner_ip_len = inner_ip_len + hdr.inner_ipv4.total_len;
    }
    if (hdr.inner_ipv6.isValid()) {
        inner_ip_len = (inner_ip_len + IPV6_HDR_SIZE +
            hdr.inner_ipv6.payload_length);
    }
    hdr.ipv4.total_len = (ETHER_HDR_SIZE + IPV4_HDR_SIZE + UDP_HDR_SIZE +
        VXLAN_HDR_SIZE + inner_ip_len);
#endif // TARGET_DPDK_PNA
    hdr.ipv4.identification = 1;
    hdr.ipv4.flags = 0;
    hdr.ipv4.frag_offset = 0;
    hdr.ipv4.ttl = 64;
    hdr.ipv4.protocol = UDP_PROTO;
    hdr.ipv4.dst_addr = underlay_dip;
    hdr.ipv4.src_addr = underlay_sip;
    hdr.ipv4.hdr_checksum = 0;
    
    hdr.udp.setValid();
    hdr.udp.src_port = 0;
    hdr.udp.dst_port = UDP_PORT_VXLAN;
#ifdef TARGET_BMV2_V1MODEL
    hdr.udp.length = hdr.inner_ipv4.total_len*(bit<16>)(bit<1>)hdr.inner_ipv4.isValid() + \
                     hdr.inner_ipv6.payload_length*(bit<16>)(bit<1>)hdr.inner_ipv6.isValid() + \
                     IPV6_HDR_SIZE*(bit<16>)(bit<1>)hdr.inner_ipv6.isValid() + \
                     UDP_HDR_SIZE + \
                     VXLAN_HDR_SIZE + \
                     ETHER_HDR_SIZE;
#endif // TARGET_BMV2_V1MODEL
#ifdef TARGET_DPDK_PNA
    hdr.udp.length = (UDP_HDR_SIZE + VXLAN_HDR_SIZE + ETHER_HDR_SIZE +
        inner_ip_len);
#endif // TARGET_DPDK_PNA
    hdr.udp.checksum = 0;
    
    hdr.vxlan.setValid();
    hdr.vxlan.reserved = 0;
    hdr.vxlan.reserved_2 = 0;
    hdr.vxlan.flags = 0;
    hdr.vxlan.vni = vni;

}

action vxlan_decap(inout headers_t hdr) {
    hdr.ethernet = hdr.inner_ethernet;
    hdr.inner_ethernet.setInvalid();

    hdr.ipv4 = hdr.inner_ipv4;
    hdr.inner_ipv4.setInvalid();

    hdr.ipv6 = hdr.inner_ipv6;
    hdr.inner_ipv6.setInvalid();

    hdr.vxlan.setInvalid();
    hdr.udp.setInvalid();

    hdr.tcp = hdr.inner_tcp;
    hdr.inner_tcp.setInvalid();

    hdr.udp = hdr.inner_udp;
    hdr.inner_udp.setInvalid();
}

#endif /* _SIRIUS_VXLAN_P4_ */
