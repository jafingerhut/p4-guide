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
