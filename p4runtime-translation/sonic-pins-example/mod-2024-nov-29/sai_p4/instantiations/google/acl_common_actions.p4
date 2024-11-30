#ifndef SAI_ACL_COMMON_ACTIONS_P4_
#define SAI_ACL_COMMON_ACTIONS_P4_

#include <v1model.p4>
#include "ids.h"

// This file lists ACL actions that may be used in multiple control blocks.

// Drop the packet at the end of the current pipeline (ingress or egress). See
// "mark_to_drop" in google3/third_party/p4lang_p4c/p4include/v1model.p4 for
// more information.
@id(ACL_DROP_ACTION_ID)
@sai_action(SAI_PACKET_ACTION_DROP)
action acl_drop(inout local_metadata_t local_metadata) {
  // It is necessary (and enough) to set acl_drop metadata at this point. The
  // actual call to mark_to_drop (that affects standard_metadata) happens at the
  // end of the current pipeline.
  // This is done this way because we want to call mark_to_drop after
  // determining the target_egress_port through the value assigned to
  // standard_metadata.egress_spec (which happens in routing_resolution *after*
  // ACL ingress) for punted packets.
  local_metadata.acl_drop = true;
}

#endif  // SAI_ACL_COMMON_ACTIONS_P4_
