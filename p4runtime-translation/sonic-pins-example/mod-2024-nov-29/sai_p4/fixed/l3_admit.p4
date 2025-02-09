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

#ifndef SAI_L3_ADMIT_P4_
#define SAI_L3_ADMIT_P4_

#include <v1model.p4>
#include "headers.p4"
#include "metadata.p4"
#include "ids.h"
#include "roles.h"
#include "minimum_guaranteed_sizes.p4"

control l3_admit(in headers_t headers,
                 inout local_metadata_t local_metadata,
                 in standard_metadata_t standard_metadata) {
  @id(L3_ADMIT_ACTION_ID)
  action admit_to_l3() {
    local_metadata.admit_to_l3 = true;
  }

  @p4runtime_role(P4RUNTIME_ROLE_ROUTING)
  @id(L3_ADMIT_TABLE_ID)
  table l3_admit_table {
    key = {
      headers.ethernet.dst_addr : ternary @name("dst_mac") @id(1)
                                          @format(MAC_ADDRESS);
      local_metadata.ingress_port : optional @name("in_port") @id(2);
    }
    actions = {
      @proto_id(1) admit_to_l3;
      @defaultonly NoAction;
    }
    const default_action = NoAction;
    size = L3_ADMIT_TABLE_MINIMUM_GUARANTEED_SIZE;
  }

  apply {
   // TODO: Properly model the behavior for VIDs 0x001 and 0xFFF
   // when Packet-IO is properly modeled (see go/gpins-vlan).
   // TODO: Consider moving vlan check logic to drop_martians.
   if (local_metadata.enable_vlan_checks &&
       !IS_RESERVED_VLAN_ID(local_metadata.vlan_id)) {
     // Explicitly reject VLAN packets from L3 routing to cancel override
     // in other parts of the code (e.g. admit_google_system_mac).
     local_metadata.admit_to_l3 = false;
   } else {
     l3_admit_table.apply();
   }
  }
}  // control l3_admit

#endif  // SAI_L3_ADMIT_P4_
