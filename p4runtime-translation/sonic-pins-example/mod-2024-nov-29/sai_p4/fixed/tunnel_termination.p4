// Tunnel termination aka decap, modeled after `saitunnel.h`,

// Copyright 2024 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#ifndef SAI_TUNNEL_TERMINATION_P4_
#define SAI_TUNNEL_TERMINATION_P4_

#include <v1model.p4>
#include "headers.p4"
#include "metadata.p4"
#include "ids.h"
#include "minimum_guaranteed_sizes.p4"

// Should be applied at the end of the pre-ingress stage.
control tunnel_termination(inout headers_t headers,
                                  inout local_metadata_t local_metadata) {
  bool marked_for_ip_in_ipv6_decap = false;

  @id(TUNNEL_DECAP_ACTION_ID)
  action tunnel_decap() {
    // Bmv2 does not support if statements in actions, so control metadata is
    // set and decapping is performed post-action.
    marked_for_ip_in_ipv6_decap = true;
  }

  // Models SAI_TUNNEL_TERM_TABLE.
  // Currently, we only model IPv6 decap of IP-in-IP packets
  @p4runtime_role(P4RUNTIME_ROLE_ROUTING)
  @id(IPV6_TUNNEL_TERMINATION_TABLE_ID)
  table ipv6_tunnel_termination_table {
    key = {
      // Sets `SAI_TUNNEL_TERM_TABLE_ENTRY_ATTR_DST_IP[_MASK]`.
      headers.ipv6.dst_addr : ternary
        @id(1) @name("dst_ipv6") @format(IPV6_ADDRESS);
      // Sets `SAI_TUNNEL_TERM_TABLE_ENTRY_ATTR_SRC_IP[_MASK]`.
      headers.ipv6.src_addr : ternary
        @id(2) @name("src_ipv6") @format(IPV6_ADDRESS);
    }
    actions = {
      @proto_id(1) tunnel_decap;
    }
    size = IPV6_TUNNEL_TERMINATION_TABLE_MINIMUM_GUARANTEED_SIZE;
  }

  apply {
    // Currently, we only model decap of IP-in-IPv6 packets
    // (SAI_TUNNEL_TYPE_IPINIP).
    if (headers.ipv6.isValid()) {
      // IP-in-IP encapsulation: 4in6 or 6in6.
      if (headers.ipv6.next_header == IP_PROTOCOL_IPV4 ||
          headers.ipv6.next_header == IP_PROTOCOL_IPV6) {
        ipv6_tunnel_termination_table.apply();
      }
    }

    if (marked_for_ip_in_ipv6_decap) {
      // Currently, this should only ever be set for IP-in-IPv6 packets.
      // TODO: Remove guard once p4-symbolic suports assertions.
#ifndef PLATFORM_P4SYMBOLIC
      assert(headers.ipv6.isValid());
      assert((headers.inner_ipv4.isValid() && !headers.inner_ipv6.isValid()) ||
             (!headers.inner_ipv4.isValid() && headers.inner_ipv6.isValid()));
#endif

      // Decap: strip outer header and replace with inner header.
      headers.ipv6.setInvalid();
      if (headers.inner_ipv4.isValid()) {
        headers.ethernet.ether_type = ETHERTYPE_IPV4;
        // TODO: Support header assignment in
        // p4-symbolic and remove this guard.
#ifndef PLATFORM_P4SYMBOLIC
        headers.ipv4 = headers.inner_ipv4;
#endif
        headers.inner_ipv4.setInvalid();
      }
      if (headers.inner_ipv6.isValid()) {
        headers.ethernet.ether_type = ETHERTYPE_IPV6;
        // TODO: Support header assignment in
        // p4-symbolic and remove this guard.
#ifndef PLATFORM_P4SYMBOLIC
        headers.ipv6 = headers.inner_ipv6;
#endif
        headers.inner_ipv6.setInvalid();
      }
    }
  }
}

#endif  // SAI_TUNNEL_TERMINATION_P4_
