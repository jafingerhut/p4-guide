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

#ifndef SAI_IPV4_CHECKSUM_H_
#define SAI_IPV4_CHECKSUM_H_

#include "headers.p4"
#include "metadata.p4"

// IPv6 does not have a checksum, so this code is only for IPv4.

control verify_ipv4_checksum(inout headers_t headers,
                             inout local_metadata_t local_metadata) {
  apply {
    verify_checksum(headers.ipv4.isValid(), {
      headers.ipv4.version,
      headers.ipv4.ihl,
      headers.ipv4.dscp,
      headers.ipv4.ecn,
      headers.ipv4.total_len,
      headers.ipv4.identification,
      headers.ipv4.reserved,
      headers.ipv4.do_not_fragment,
      headers.ipv4.more_fragments,
      headers.ipv4.frag_offset,
      headers.ipv4.ttl,
      headers.ipv4.protocol,
      headers.ipv4.src_addr,
      headers.ipv4.dst_addr
    }, headers.ipv4.header_checksum, HashAlgorithm.csum16);
  }
}  // control verify_ipv4_checksum

control compute_ipv4_checksum(inout headers_t headers,
                              inout local_metadata_t local_metadata) {
  apply {
    update_checksum(headers.ipv4.isValid(), {
        headers.ipv4.version,
        headers.ipv4.ihl,
        headers.ipv4.dscp,
        headers.ipv4.ecn,
        headers.ipv4.total_len,
        headers.ipv4.identification,
        headers.ipv4.reserved,
        headers.ipv4.do_not_fragment,
        headers.ipv4.more_fragments,
        headers.ipv4.frag_offset,
        headers.ipv4.ttl,
        headers.ipv4.protocol,
        headers.ipv4.src_addr,
        headers.ipv4.dst_addr
      }, headers.ipv4.header_checksum, HashAlgorithm.csum16);
  }
}  // control compute_ipv4_checksum

#endif  // SAI_IPV4_CHECKSUM_H_
