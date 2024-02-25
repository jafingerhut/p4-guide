#ifndef _DASH_NVGRE_P4_
#define _DASH_NVGRE_P4_

#include "dash_headers.p4"

action nvgre_encap(inout headers_t hdr,
                   in EthernetAddress underlay_dmac,
                   in EthernetAddress underlay_smac,
                   in IPv4Address underlay_dip,
                   in IPv4Address underlay_sip,
                   in EthernetAddress overlay_dmac, 
                   in bit<24> vsid) {
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
                         NVGRE_HDR_SIZE;
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
        NVGRE_HDR_SIZE + inner_ip_len);
#endif // TARGET_DPDK_PNA
    hdr.ipv4.identification = 1;
    hdr.ipv4.flags = 0;
    hdr.ipv4.frag_offset = 0;
    hdr.ipv4.ttl = 64;
    hdr.ipv4.protocol = NVGRE_PROTO;
    hdr.ipv4.dst_addr = underlay_dip;
    hdr.ipv4.src_addr = underlay_sip;
    hdr.ipv4.hdr_checksum = 0;
    
    hdr.nvgre.setValid();
    hdr.nvgre.flags = 4;
    hdr.nvgre.reserved = 0;
    hdr.nvgre.version = 0;
    hdr.nvgre.protocol_type = 0x6558;
    hdr.nvgre.vsid = vsid;
    hdr.nvgre.flow_id = 0;

}

#endif /* _DASH_NVGRE_P4_ */
