// Copyright 2020 Google LLC
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

#ifndef PINS_SAI_RESOURCE_GUARANTEES_P4_
#define PINS_SAI_RESOURCE_GUARANTEES_P4_

// This file documents the resource guarantees that each table provides.
// These guarantees are not based on the hardware limits of particular targets,
// but instead model the requirements that we believe we need for our
// operations. Specifically, we try to give a a conservative upper bound of our
// current requirements to support current usage and be better prepared for
// future changes.
//
// For some targets and some tables, these numbers are read by the switch and
// used to allocate tables accordingly. For other targets/tables these numbers
// are ignored by the switch. In either case, we can use p4-fuzzer to ensure
// that the given guarantees are actually upheld by the switch.
//
// See go/gpins-resource-guarantees for details on how a variety of these
// numbers arose and to what extent they are truly guarantees.

// -- Fixed Table sizes --------------------------------------------------------

#define IPV6_TUNNEL_TERMINATION_TABLE_MINIMUM_GUARANTEED_SIZE 126

#define NEXTHOP_TABLE_MINIMUM_GUARANTEED_SIZE 1024

#define NEIGHBOR_TABLE_MINIMUM_GUARANTEED_SIZE 1024

#define MIRROR_SESSION_TABLE_MINIMUM_GUARANTEED_SIZE 4

#define ROUTING_VRF_TABLE_MINIMUM_GUARANTEED_SIZE 64

#define ROUTING_IPV4_TABLE_MINIMUM_GUARANTEED_SIZE 131072
#define ROUTING_IPV6_TABLE_MINIMUM_GUARANTEED_SIZE 17000

#define ROUTING_TUNNEL_TABLE_MINIMUM_GUARANTEED_SIZE 2048

#define ROUTER_INTERFACE_TABLE_MINIMUM_GUARANTEED_SIZE 200
#define ROUTING_MULTICAST_SOURCE_MAC_TABLE_MINIMUM_GUARANTEED_SIZE 128
#define L3_ADMIT_TABLE_MINIMUM_GUARANTEED_SIZE 64
#define ROUTING_MULTICAST_ROUTER_INTERFACE_TABLE_MINIMUM_GUARANTEED_SIZE 128

#define ROUTING_IPV4_MULTICAST_TABLE_MINIMUM_GUARANTEED_SIZE 1600
#define ROUTING_IPV6_MULTICAST_TABLE_MINIMUM_GUARANTEED_SIZE 1600

// The maximum number of wcmp groups.
#define WCMP_GROUP_TABLE_MINIMUM_GUARANTEED_SIZE 3968
#define WCMP_GROUP_TABLE_MINIMUM_GUARANTEED_SIZE_TOR 960

// The size semantics for WCMP group selectors.
#define WCMP_GROUP_SELECTOR_SIZE_SEMANTICS "SUM_OF_WEIGHTS"
#define WCMP_GROUP_SELECTOR_SIZE_SEMANTICS_TOR "SUM_OF_WEIGHTS"

// The maximum sum of members across all wcmp groups.
#define WCMP_GROUP_SELECTOR_SIZE 49152 // 48k
#define WCMP_GROUP_SELECTOR_SIZE_TOR 31296  // 31K

// The maximum sum of weights for each wcmp group.
#define WCMP_GROUP_SELECTOR_MAX_GROUP_SIZE 512
#define WCMP_GROUP_SELECTOR_MAX_GROUP_SIZE_TOR 256

// The max weight of an individual member when using the SUM_OF_MEMBERS size 
// semantics.
#define WCMP_GROUP_SELECTOR_MAX_MEMBER_WEIGHT 4096

// -- ACL Table sizes ----------------------------------------------------------

#define ACL_INGRESS_TABLE_MINIMUM_GUARANTEED_SIZE 256

// Some switches allocate table sizes in powers of 2. Since GPINs (Orchagent)
// allocates 1 extra table entry for the loopback IP, we pick the size as
// 2^8 - 1 to avoid allocation of 2^9 entries on such switches.

#define ACL_DEFAULT_PRE_INGRESS_TABLE_MINIMUM_GUARANTEED_SIZE 254

#define ACL_TOR_PRE_INGRESS_TABLE_MINIMUM_GUARANTEED_SIZE 127

#define ACL_INGRESS_QOS_TABLE_MINIMUM_GUARANTEED_SIZE 255

#define ACL_INGRESS_COUNTING_TABLE_MINIMUM_GUARANTEED_SIZE 255

#ifdef SAI_INSTANTIATION_TOR
#define ACL_INGRESS_MIRROR_AND_REDIRECT_TABLE_MINIMUM_GUARANTEED_SIZE 511
#else
#define ACL_INGRESS_MIRROR_AND_REDIRECT_TABLE_MINIMUM_GUARANTEED_SIZE 255
#endif

#define ACL_EGRESS_TABLE_MINIMUM_GUARANTEED_SIZE 127

// 1 entry for LLDP, 1 entry for ND, and 6 entries for traceroute: TTL 0,1,2 for
// IPv4 and IPv6
#define ACL_WBB_INGRESS_TABLE_MINIMUM_GUARANTEED_SIZE 8

#endif  // PINS_SAI_RESOURCE_GUARANTEES_P4_
