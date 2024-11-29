#ifndef SAI_PACKET_IO_P4_
#define SAI_PACKET_IO_P4_

#include <v1model.p4>
#include "headers.p4"
#include "metadata.p4"
#include "ids.h"
#include "bmv2_intrinsics.h"

// TODO: Clean up once we have better solution to handle packet-in
// across platforms.
control packet_in_encap(inout headers_t headers,
                        inout local_metadata_t local_metadata,
                        inout standard_metadata_t standard_metadata) {
  apply {
#if defined(PLATFORM_BMV2) || defined(PLATFORM_P4SYMBOLIC)
    if (IS_PACKET_IN_COPY(standard_metadata)){
      headers.packet_out_header.setInvalid();
      headers.packet_in_header = {
        ingress_port = (port_id_t) local_metadata.packet_in_ingress_port,
        target_egress_port =
          (port_id_t) local_metadata.packet_in_target_egress_port,
        unused_pad = 0
      };
    }
#endif
  }
}  // control populate_packet_in_header

control packet_out_decap(inout headers_t headers,
                         inout local_metadata_t local_metadata,
                         inout standard_metadata_t standard_metadata){
  apply {
    if (headers.packet_out_header.isValid() &&
        headers.packet_out_header.submit_to_ingress == 0) {
      // Cast is necessary, because v1model does not define port using `type`.
      standard_metadata.egress_spec =
          (bit<PORT_BITWIDTH>) headers.packet_out_header.egress_port;
      // Skip the rest of the ingress pipeline.
      local_metadata.bypass_ingress = true;
    }
    // Set invalid as we don't need the packet out header in the output header.
    headers.packet_out_header.setInvalid();
  }
}  // control packet_out_processing_ingress

#endif  // SAI_PACKET_IO_P4_
