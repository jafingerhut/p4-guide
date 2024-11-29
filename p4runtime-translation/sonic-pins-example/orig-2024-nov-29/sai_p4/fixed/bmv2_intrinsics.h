#ifndef PINS_SAI_P4_FIXED_BMV2_INTRINSICS_H_
#define PINS_SAI_P4_FIXED_BMV2_INTRINSICS_H_

// Possible values of the v1model `standard_metadata_t` field `instance_type` in
// BMv2. The semantics of these values is explained here:
// https://github.com/p4lang/behavioral-model/blob/main/docs/simple_switch.md
#define PKT_INSTANCE_TYPE_NORMAL 0
#define PKT_INSTANCE_TYPE_INGRESS_CLONE 1
#define PKT_INSTANCE_TYPE_EGRESS_CLONE 2
#define PKT_INSTANCE_TYPE_COALESCED 3
#define PKT_INSTANCE_TYPE_RECIRC 4
#define PKT_INSTANCE_TYPE_REPLICATION 5
#define PKT_INSTANCE_TYPE_RESUBMIT 6

#endif  // PINS_SAI_P4_FIXED_BMV2_INTRINSICS_H_
