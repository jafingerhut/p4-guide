#ifndef _SIRIUS_PARSER_P4_
#define _SIRIUS_PARSER_P4_

#include "dash_headers.p4"

error {
    IPv4IncorrectVersion,
    IPv4OptionsNotSupported,
    InvalidIPv4Header
}

#define UDP_PORT_VXLAN 4789
#define UDP_PROTO 17
#define TCP_PROTO 6
#define IPV4_ETHTYPE 0x0800
#define IPV6_ETHTYPE 0x86dd

parser dash_parser(
    packet_in packet
    , out headers_t hd
    , inout metadata_t meta
#ifdef TARGET_BMV2_V1MODEL
    , inout standard_metadata_t standard_meta
#endif // TARGET_BMV2_V1MODEL
#ifdef TARGET_DPDK_PNA
    , in pna_main_parser_input_metadata_t istd
#endif // TARGET_DPDK_PNA
    )
{
    state start {
        packet.extract(hd.ethernet);
        transition select(hd.ethernet.ether_type) {
            IPV4_ETHTYPE:  parse_ipv4;
            IPV6_ETHTYPE:  parse_ipv6;
            default: accept;
        }
    }

    state parse_ipv4 {
        packet.extract(hd.ipv4);
        verify(hd.ipv4.version == 4w4, error.IPv4IncorrectVersion);
        verify(hd.ipv4.ihl >= 5, error.InvalidIPv4Header);
        transition select (hd.ipv4.ihl) {
                5: dispatch_on_protocol;
                default: parse_ipv4options;
        }
    }

    state parse_ipv4options {
        packet.extract(hd.ipv4options,
                    (bit<32>)(((bit<16>)hd.ipv4.ihl - 5) * 32));
        transition dispatch_on_protocol;
    }

    state dispatch_on_protocol {
        transition select(hd.ipv4.protocol) {
            UDP_PROTO: parse_udp;
            TCP_PROTO: parse_tcp;
            default: accept;
        }
    }

    state parse_ipv6 {
        packet.extract(hd.ipv6);
        transition select(hd.ipv6.next_header) {
            UDP_PROTO: parse_udp;
            TCP_PROTO: parse_tcp;
            default: accept;
        }
    }

    state parse_udp {
        packet.extract(hd.udp);
        transition select(hd.udp.dst_port) {
            UDP_PORT_VXLAN: parse_vxlan;
            default: accept;
         }
    }

    state parse_tcp {
        packet.extract(hd.tcp);
        transition accept;
    }

    state parse_vxlan {
        packet.extract(hd.vxlan);
        transition parse_inner_ethernet;
    }

    state parse_inner_ethernet {
        packet.extract(hd.inner_ethernet);
        transition select(hd.inner_ethernet.ether_type) {
            IPV4_ETHTYPE: parse_inner_ipv4;
            IPV6_ETHTYPE: parse_inner_ipv6;
            default: accept;
        }
    }

    state parse_inner_ipv4 {
        packet.extract(hd.inner_ipv4);
        verify(hd.inner_ipv4.version == 4w4, error.IPv4IncorrectVersion);
        verify(hd.inner_ipv4.ihl == 4w5, error.IPv4OptionsNotSupported);
        transition select(hd.inner_ipv4.protocol) {
            UDP_PROTO: parse_inner_udp;
            TCP_PROTO: parse_inner_tcp;
            default: accept;
        }
    }

    state parse_inner_ipv6 {
        packet.extract(hd.inner_ipv6);
        transition select(hd.inner_ipv6.next_header) {
            UDP_PROTO: parse_inner_udp;
            TCP_PROTO: parse_inner_tcp;
            default: accept;
        }
    }

    state parse_inner_tcp {
        packet.extract(hd.inner_tcp);
        transition accept;
    }

    state parse_inner_udp {
        packet.extract(hd.inner_udp);
        transition accept;
    }
}

control dash_deparser(
      packet_out packet
    , in headers_t hdr
#ifdef TARGET_DPDK_PNA
    , in metadata_t meta
    , in pna_main_output_metadata_t ostd
#endif // TARGET_DPDK_PNA
    )
{
    apply {
	packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.ipv4options);
        packet.emit(hdr.ipv6);
        packet.emit(hdr.udp);
        packet.emit(hdr.tcp);
        packet.emit(hdr.vxlan);
        packet.emit(hdr.inner_ethernet);
        packet.emit(hdr.inner_ipv4);
        packet.emit(hdr.inner_ipv6);
        packet.emit(hdr.inner_tcp);
        packet.emit(hdr.inner_udp);
    }
}

#endif /* _SIRIUS_PARSER_P4_ */
