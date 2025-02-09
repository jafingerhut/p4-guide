/*
 * Copyright 2024 Andy Fingerhut
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#ifndef PINS_SAI_IDS_H_
#define PINS_SAI_IDS_H_

#include "../../fixed/ids.h"

// All declarations (tables, actions, action profiles, meters, counters) have a
// stable ID. This list will evolve as new declarations are added. IDs cannot be
// reused. If a declaration is removed, its ID macro is kept and marked reserved
// to avoid the ID being reused.
//
// The IDs are classified using the 8 most significant bits to be compatible
// with "6.3. ID Allocation for P4Info Objects" in the P4Runtime specification.

// --- Tables ------------------------------------------------------------------

// IDs of ACL tables (8 most significant bits = 0x02).
// Since these IDs are user defined, they need to be separate from the fixed SAI
// table ID space. We achieve this by starting the IDs at 0x100.
#define ACL_INGRESS_TABLE_ID 0x02000100                      // 33554688
#define ACL_INGRESS_QOS_TABLE_ID 0x02000107                  // 33554695
#define ACL_INGRESS_COUNTING_TABLE_ID 0x02000109             // 33554697
#define ACL_INGRESS_SECURITY_TABLE_ID 0x0200010A             // 33554698
#define ACL_INGRESS_MIRROR_AND_REDIRECT_TABLE_ID 0x0200010B  // 33554699
#define ACL_PRE_INGRESS_TABLE_ID 0x02000101                  // 33554689
#define ACL_PRE_INGRESS_VLAN_TABLE_ID 0x02000105             // 33554693
#define ACL_PRE_INGRESS_METADATA_TABLE_ID 0x02000106         // 33554694
#define ACL_WBB_INGRESS_TABLE_ID 0x02000103                  // 33554691
#define ACL_EGRESS_TABLE_ID 0x02000104                       // 33554692
#define ACL_EGRESS_DHCP_TO_HOST_TABLE_ID 0x02000108          // 33554696
// Next available table id: 0x0200010C (33554700)

// --- Actions -----------------------------------------------------------------
// NOLINTBEGIN (to disable macro names of size > 80 cols)

// IDs of ACL actions (8 most significant bits = 0x01).
// Since these IDs are user defined, they need to be separate from the fixed SAI
// actions ID space. We achieve this by starting the IDs at 0x100.
#define ACL_PRE_INGRESS_SET_VRF_ACTION_ID 0x01000100           // 16777472
#define ACL_PRE_INGRESS_SET_OUTER_VLAN_ACTION_ID 0x0100010A    // 16777482
#define ACL_PRE_INGRESS_SET_ACL_METADATA_ACTION_ID 0x0100010B  // 16777483
#define ACL_INGRESS_COPY_ACTION_ID 0x01000101                  // 16777473
#define ACL_INGRESS_TRAP_ACTION_ID 0x01000102                  // 16777474
#define ACL_INGRESS_EXPERIMENTAL_TRAP_ACTION_ID 0x01000199     // 16777625
#define ACL_INGRESS_FORWARD_ACTION_ID 0x01000103               // 16777475
#define ACL_INGRESS_MIRROR_ACTION_ID 0x01000104                // 16777476
#define ACL_INGRESS_COUNT_ACTION_ID 0x01000105                 // 16777477
#define ACL_INGRESS_SET_QOS_QUEUE_AND_CANCEL_COPY_ABOVE_RATE_LIMIT_ACTION_ID \
  0x0100010C  // 16777484
#define ACL_INGRESS_SET_CPU_QUEUE_AND_DENY_ABOVE_RATE_LIMIT_ACTION_ID \
  0x0100010E                                            // 16777486
#define ACL_INGRESS_SET_CPU_QUEUE_ACTION_ID 0x01000110  // 16777488
#define ACL_INGRESS_SET_CPU_AND_MULTICAST_QUEUES_AND_DENY_ABOVE_RATE_LIMIT_ACTION_ID \
  0x01000111                                                     // 16777489
#define ACL_INGRESS_DENY_ACTION_ID 0x0100010F                    // 16777487
#define ACL_INGRESS_REDIRECT_TO_NEXTHOP_ACTION_ID 0x01000112     // 16777490
#define ACL_INGRESS_REDIRECT_TO_IPMC_GROUP_ACTION_ID 0x01000113  // 16777491
#define ACL_EGRESS_FORWARD_ACTION_ID 0x0100010D                  // 16777485
#define ACL_WBB_INGRESS_COPY_ACTION_ID 0x01000107                // 16777479
#define ACL_WBB_INGRESS_TRAP_ACTION_ID 0x01000108                // 16777480
#define ACL_DROP_ACTION_ID 0x01000109                            // 16777481
// Next available action id: 0x01000113 (16777492)


// NOLINTEND
// --- Meters ------------------------------------------------------------------
#define ACL_INGRESS_METER_ID 0x15000100      // 352321792
#define ACL_INGRESS_QOS_METER_ID 0x15000102  // 352321794
#define ACL_WBB_INGRESS_METER_ID 0x15000101  // 352321793

// --- Counters ----------------------------------------------------------------
#define ACL_PRE_INGRESS_COUNTER_ID 0x13000101           // 318767361
#define ACL_PRE_INGRESS_METADATA_COUNTER_ID 0x13000105  // 318767365
#define ACL_PRE_INGRESS_VLAN_COUNTER_ID 0x13000106      // 318767366
#define ACL_INGRESS_COUNTER_ID 0x13000102               // 318767362
#define ACL_INGRESS_QOS_COUNTER_ID 0x13000107           // 318767367
#define ACL_INGRESS_COUNTING_COUNTER_ID 0x13000109      // 318767369
#define ACL_INGRESS_SECURITY_COUNTER_ID 0x1300010A      // 318767370
#define ACL_WBB_INGRESS_COUNTER_ID 0x13000103           // 318767363
#define ACL_EGRESS_COUNTER_ID 0x13000104                // 318767364
#define ACL_EGRESS_DHCP_TO_HOST_COUNTER_ID 0x13000108   // 318767368

#endif  // PINS_SAI_IDS_H_
