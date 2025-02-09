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

#ifndef SAI_BITWIDTHS_P4_
#define SAI_BITWIDTHS_P4_

#ifndef PORT_BITWIDTH
#define PORT_BITWIDTH 16
#endif

#ifndef VRF_BITWIDTH
#define VRF_BITWIDTH 16
#endif

#ifndef NEXTHOP_ID_BITWIDTH
#define NEXTHOP_ID_BITWIDTH 16
#endif

#ifndef ROUTER_INTERFACE_ID_BITWIDTH
#define ROUTER_INTERFACE_ID_BITWIDTH 16
#endif

#ifndef WCMP_GROUP_ID_BITWIDTH
#define WCMP_GROUP_ID_BITWIDTH 16
#endif

#ifndef MIRROR_SESSION_ID_BITWIDTH
#define MIRROR_SESSION_ID_BITWIDTH 16
#endif

#ifndef QOS_QUEUE_BITWIDTH
#define QOS_QUEUE_BITWIDTH 16
#endif

#ifndef WCMP_SELECTOR_INPUT_BITWIDTH
#define WCMP_SELECTOR_INPUT_BITWIDTH 16
#endif

#ifndef ROUTE_METADATA_BITWIDTH
#define ROUTE_METADATA_BITWIDTH 6
#endif

#ifndef ACL_METADATA_BITWIDTH
#define ACL_METADATA_BITWIDTH 8
#endif

#ifndef TUNNEL_ID_BITWIDTH
#define TUNNEL_ID_BITWIDTH 16
#endif

// Inherited from v1model, see `standard_metadata_t.mcast_grp`.
#define MULTICAST_GROUP_ID_BITWIDTH 16

// Inherited from v1model, see `standard_metadata_t.egress_rid`.
#define REPLICA_INSTANCE_BITWIDTH 16

#endif  // SAI_BITWIDTHS_P4_
