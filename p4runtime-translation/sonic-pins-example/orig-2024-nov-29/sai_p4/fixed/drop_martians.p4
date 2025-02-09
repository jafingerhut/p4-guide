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

#ifndef SAI_DROP_MARTIANS_P4_
#define SAI_DROP_MARTIANS_P4_

// Drop certain special-use (aka martian) addresses.

const ipv6_addr_t IPV6_MULTICAST_MASK =
  0xff00_0000_0000_0000_0000_0000_0000_0000;
const ipv6_addr_t IPV6_MULTICAST_VALUE =
  0xff00_0000_0000_0000_0000_0000_0000_0000;

// ::1/128
const ipv6_addr_t IPV6_LOOPBACK_MASK =
  0xffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff;
const ipv6_addr_t IPV6_LOOPBACK_VALUE =
  0x0000_0000_0000_0000_0000_0000_0000_0001;

const ipv4_addr_t IPV4_MULTICAST_MASK = 0xf0_00_00_00;
const ipv4_addr_t IPV4_MULTICAST_VALUE = 0xe0_00_00_00;

const ipv4_addr_t IPV4_BROADCAST_VALUE = 0xff_ff_ff_ff;

// 127.0.0.0/8
const ipv4_addr_t IPV4_LOOPBACK_MASK = 0xff_00_00_00;
const ipv4_addr_t IPV4_LOOPBACK_VALUE = 0x7f_00_00_00;

#define IS_MULTICAST_IPV6(address) \
  (address & IPV6_MULTICAST_MASK == IPV6_MULTICAST_VALUE)

#define IS_LOOPBACK_IPV6(address) \
  (address & IPV6_LOOPBACK_MASK == IPV6_LOOPBACK_VALUE)

#define IS_MULTICAST_IPV4(address) \
  (address & IPV4_MULTICAST_MASK == IPV4_MULTICAST_VALUE)

#define IS_BROADCAST_IPV4(address) \
  (address == IPV4_BROADCAST_VALUE)

#define IS_LOOPBACK_IPV4(address) \
  (address & IPV4_LOOPBACK_MASK == IPV4_LOOPBACK_VALUE)

// I/G bit = 1 means multicast.
#define IS_UNICAST_MAC(address) \
  (address[40:40] == 0)

#define IS_IPV4_MULTICAST_MAC(address) \
  (address[47:24] == 0x01005E && address[23:23] == 0)

#define IS_IPV6_MULTICAST_MAC(address) \
  (address[47:32] == 0x3333)

control drop_martians(in headers_t headers,
                      inout local_metadata_t local_metadata,
                      inout standard_metadata_t standard_metadata) {
  apply {
    // Drop the packet if:
    // - Src IPv6 address is in multicast range; or
    // - Src IPv4 address is in multicast or broadcast range; or
    // - Src/Dst IPv4/IPv6 address is a loopback address.
    // Rationale:
    // Src IP multicast drop: https://www.rfc-editor.org/rfc/rfc1812#section-5.3.7
    // Src/Dst IP loopback drop: https://en.wikipedia.org/wiki/Localhost#Packet_processing
    //    "Packets received on a non-loopback interface with a loopback source
    //     or destination address must be dropped."
    if ((headers.ipv6.isValid() &&
            (IS_MULTICAST_IPV6(headers.ipv6.src_addr) ||
             IS_LOOPBACK_IPV6(headers.ipv6.src_addr) ||
             IS_LOOPBACK_IPV6(headers.ipv6.dst_addr))) ||
        (headers.ipv4.isValid() &&
            (IS_MULTICAST_IPV4(headers.ipv4.src_addr) ||
             IS_BROADCAST_IPV4(headers.ipv4.src_addr) ||
             IS_BROADCAST_IPV4(headers.ipv4.dst_addr) ||
             IS_LOOPBACK_IPV4(headers.ipv4.src_addr) ||
             IS_LOOPBACK_IPV4(headers.ipv4.dst_addr)))
       ) {
        mark_to_drop(standard_metadata);
    }

    // TODO: Drop the rest of martian packets.
  }
}  // control drop_martians


#endif  // SAI_DROP_MARTIANS_P4_
