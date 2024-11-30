#ifndef SAI_INGRESS_CLONING_P4_
#define SAI_INGRESS_CLONING_P4_

#include <v1model.p4>
#include "headers.p4"
#include "metadata.p4"
#include "ids.h"
#include "roles.h"
#include "minimum_guaranteed_sizes.p4"

control ingress_cloning(inout headers_t headers,
                        inout local_metadata_t local_metadata,
                        inout standard_metadata_t standard_metadata) {

  @id(CLONING_INGRESS_CLONE_ACTION_ID)
  action ingress_clone(@id(1) bit<32> clone_session) {
    clone_preserving_field_list(CloneType.I2E, clone_session,
      PreservedFieldList.MIRROR_AND_PACKET_IN_COPY);
  }

// Logical table that calls the clone extern with an appropriate
// `clone_session` to aggregate the effect of punt and mirror actions in the
// ACL ingress stage.
// On SAI targets (e.g. SONIC/PINS), this table does not exist and the logic it
// performs is built in.
// On V1Model targets (e.g. BMv2/P4TestGen) and P4-Symbolic, this table must be
// populated with the following entries:
  // ===========================================================================
  // | type       | match fields             | action           | entry count  |
  // ---------------------------------------------------------------------------
  // | punt-only  | marked_to_copy: true     | ingress_clone(   | one          |
  // |            | marked_to_mirror: false  |  punt_only_clone |              |
  // |            |                          |  session)        |              |
  // ---------------------------------------------------------------------------
  // | mirror-only| marked_to_copy: false    | ingress_clone(   | one for each |
  // |            | marked_to_mirror: true   |  mirror_only_    | port on the  |
  // |            | mirror_egress_port: port |  clone_session)  | target       |
  // ---------------------------------------------------------------------------
  // | mirror-and | marked_to_copy: true     | ingress_clone(   | one for each |
  // | -punt      | marked_to_mirror: true   |  punt_and_mirror_| port on the  |
  // |            | mirror_egress_port: port |  clone_session)  | target       |
  // ---------------------------------------------------------------------------
  // The user also needs to install p4::v1::CloneSessionEntry for
  // each `clone_session` and its p4::v1::Replicas need to reflect the action.
  // For example, an entry to mirror_and_punt out of port `p`, its action must
  // refer to a p4::v1::CloneSessionEntry with 2 Replicas, one for punting, one
  // for mirroring out of port `p`.
  // TODO: Remove @unsupported once we can ignore this table
  // in P4Info verification.
  @unsupported
  @p4runtime_role(P4RUNTIME_ROLE_PACKET_REPLICATION_ENGINE)
  @id(INGRESS_CLONE_TABLE_ID)
  @entry_restriction("
    // mirror_egress_port is present iff marked_to_mirror is true.
    // Exact match indicating presence of mirror_egress_port.
    marked_to_mirror == 1 -> mirror_egress_port::mask == -1;
    // Wildcard match indicating abscence of mirror_egress_port.
    marked_to_mirror == 0 -> mirror_egress_port::mask == 0;
  ")
  table ingress_clone_table {
    key = {
      local_metadata.marked_to_copy : exact
        @id(1) @name("marked_to_copy");
      local_metadata.marked_to_mirror : exact
        @id(2) @name("marked_to_mirror");
      local_metadata.mirror_egress_port : optional
        @id(3) @name("mirror_egress_port");
    }
    actions = {
      @proto_id(1) ingress_clone;
    }
  }

  apply {
    ingress_clone_table.apply();
  }

}  // control ingress_cloning

#endif  // SAI_INGRESS_CLONING_P4_
