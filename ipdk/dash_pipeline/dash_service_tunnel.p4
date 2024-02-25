#ifndef _SIRIUS_SERVICE_TUNNEL_P4_
#define _SIRIUS_SERVICE_TUNNEL_P4_

#include "dash_headers.p4"

/* Encodes V4 in V6 */
action service_tunnel_encode(inout headers_t hdr,
                             in IPv6Address st_dst,
                             in IPv6Address st_dst_mask,
                             in IPv6Address st_src,
                             in IPv6Address st_src_mask) {
    hdr.u0_ipv6.setValid();
    hdr.u0_ipv6.version = 6;
    hdr.u0_ipv6.traffic_class = 0;
    hdr.u0_ipv6.flow_label = 0;
    hdr.u0_ipv6.payload_length = hdr.u0_ipv4.total_len - IPV4_HDR_SIZE;
    hdr.u0_ipv6.next_header = hdr.u0_ipv4.protocol;
    hdr.u0_ipv6.hop_limit = hdr.u0_ipv4.ttl;
#ifndef DISABLE_128BIT_ARITHMETIC
    // As of 2024-Feb-09, p4c-dpdk does not yet support arithmetic on
    // 128-bit operands.
    hdr.u0_ipv6.dst_addr = ((IPv6Address)hdr.u0_ipv4.dst_addr & ~st_dst_mask) | (st_dst & st_dst_mask);
    hdr.u0_ipv6.src_addr = ((IPv6Address)hdr.u0_ipv4.src_addr & ~st_src_mask) | (st_src & st_src_mask);
#endif
    
    hdr.u0_ipv4.setInvalid();
    hdr.u0_ethernet.ether_type = IPV6_ETHTYPE;
}

/* Decodes V4 from V6 */
action service_tunnel_decode(inout headers_t hdr,
                             in IPv4Address src,
                             in IPv4Address dst) {
    hdr.u0_ipv4.setValid();
    hdr.u0_ipv4.version = 4;
    hdr.u0_ipv4.ihl = 5;
    hdr.u0_ipv4.diffserv = 0;
    hdr.u0_ipv4.total_len = hdr.u0_ipv6.payload_length + IPV4_HDR_SIZE;
    hdr.u0_ipv4.identification = 1;
    hdr.u0_ipv4.flags = 0;
    hdr.u0_ipv4.frag_offset = 0;
    hdr.u0_ipv4.protocol = hdr.u0_ipv6.next_header;
    hdr.u0_ipv4.ttl = hdr.u0_ipv6.hop_limit;
    hdr.u0_ipv4.hdr_checksum = 0;
    hdr.u0_ipv4.dst_addr = dst;
    hdr.u0_ipv4.src_addr = src;

    hdr.u0_ipv6.setInvalid();
    hdr.u0_ethernet.ether_type = IPV4_ETHTYPE;
}

#endif /* _SIRIUS_SERVICE_TUNNEL_P4_ */
