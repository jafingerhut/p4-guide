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
#define NVGRE_PROTO 0x2f
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
        packet.extract(hd.u0_ethernet);
        transition select(hd.u0_ethernet.ether_type) {
            IPV4_ETHTYPE:  parse_u0_ipv4;
            IPV6_ETHTYPE:  parse_u0_ipv6;
            default: accept;
        }
    }

    state parse_u0_ipv4 {
        packet.extract(hd.u0_ipv4);
        verify(hd.u0_ipv4.version == 4w4, error.IPv4IncorrectVersion);
        verify(hd.u0_ipv4.ihl >= 5, error.InvalidIPv4Header);
        transition select (hd.u0_ipv4.ihl) {
                5: dispatch_on_u0_protocol;
                default: parse_u0_ipv4options;
        }
    }

    state parse_u0_ipv4options {
        packet.extract(hd.u0_ipv4options,
                    (bit<32>)(((bit<16>)hd.u0_ipv4.ihl - 5) * 32));
        transition dispatch_on_u0_protocol;
    }

    state dispatch_on_u0_protocol {
        transition select(hd.u0_ipv4.protocol) {
            UDP_PROTO: parse_u0_udp;
            TCP_PROTO: parse_u0_tcp;
            default: accept;
        }
    }

    state parse_u0_ipv6 {
        packet.extract(hd.u0_ipv6);
        transition select(hd.u0_ipv6.next_header) {
            UDP_PROTO: parse_u0_udp;
            TCP_PROTO: parse_u0_tcp;
            default: accept;
        }
    }

    state parse_u0_udp {
        packet.extract(hd.u0_udp);
        transition select(hd.u0_udp.dst_port) {
            UDP_PORT_VXLAN: parse_u0_vxlan;
            default: accept;
         }
    }

    state parse_u0_tcp {
        packet.extract(hd.u0_tcp);
        transition accept;
    }

    state parse_u0_vxlan {
        packet.extract(hd.u0_vxlan);
        transition parse_customer_ethernet;
    }

    state parse_customer_ethernet {
        packet.extract(hd.customer_ethernet);
        transition select(hd.customer_ethernet.ether_type) {
            IPV4_ETHTYPE: parse_customer_ipv4;
            IPV6_ETHTYPE: parse_customer_ipv6;
            default: accept;
        }
    }

    state parse_customer_ipv4 {
        packet.extract(hd.customer_ipv4);
        verify(hd.customer_ipv4.version == 4w4, error.IPv4IncorrectVersion);
        verify(hd.customer_ipv4.ihl == 4w5, error.IPv4OptionsNotSupported);
        transition select(hd.customer_ipv4.protocol) {
            UDP_PROTO: parse_customer_udp;
            TCP_PROTO: parse_customer_tcp;
            default: accept;
        }
    }

    state parse_customer_ipv6 {
        packet.extract(hd.customer_ipv6);
        transition select(hd.customer_ipv6.next_header) {
            UDP_PROTO: parse_customer_udp;
            TCP_PROTO: parse_customer_tcp;
            default: accept;
        }
    }

    state parse_customer_tcp {
        packet.extract(hd.customer_tcp);
        transition accept;
    }

    state parse_customer_udp {
        packet.extract(hd.customer_udp);
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
	packet.emit(hdr.u0_ethernet);
        packet.emit(hdr.u0_ipv4);
        packet.emit(hdr.u0_ipv4options);
        packet.emit(hdr.u0_ipv6);
        packet.emit(hdr.u0_udp);
        packet.emit(hdr.u0_tcp);
        packet.emit(hdr.u0_vxlan);
        packet.emit(hdr.u0_nvgre);
        packet.emit(hdr.customer_ethernet);
        packet.emit(hdr.customer_ipv4);
        packet.emit(hdr.customer_ipv6);
        packet.emit(hdr.customer_tcp);
        packet.emit(hdr.customer_udp);
    }
}

#endif /* _SIRIUS_PARSER_P4_ */
