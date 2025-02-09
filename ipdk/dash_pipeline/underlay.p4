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

#include <core.p4>
#include "dash_headers.p4"
#include "dash_metadata.p4"

// The values in this context have been sourced from the 'saiswitch.h' file and 
// have been manually designated to maintain alignment with enum values specified in the SAI commit <d8d40b4>.
#define SAI_PACKET_ACTION_DROP 0
#define SAI_PACKET_ACTION_FORWARD 1

control underlay(
      inout headers_t hdr
    , inout metadata_t meta
#ifdef TARGET_BMV2_V1MODEL
    , inout standard_metadata_t standard_metadata
#endif // TARGET_BMV2_V1MODEL
#ifdef TARGET_DPDK_PNA
    , in    pna_main_input_metadata_t  istd
#endif // TARGET_DPDK_PNA  
    ) 
{
    action set_nhop(bit<9> next_hop_id) {
#ifdef TARGET_BMV2_V1MODEL
        standard_metadata.egress_spec = next_hop_id;
#endif // TARGET_BMV2_V1MODEL

#ifdef TARGET_DPDK_PNA
#ifdef DPDK_PNA_SEND_TO_PORT_FIX_MERGED
        // As of 2023-Jan-26, the version of the pna.p4 header file
        // included with p4c defines send_to_port with a parameter
        // that has no 'in' direction.  The following commit in the
        // public pna repo fixes this, but this fix has not yet been
        // copied into the p4c repo.
        // https://github.com/p4lang/pna/commit/b9fdfb888e5385472c34ff773914c72b78b63058
        // Until p4c is updated with this fix, the following line will
        // give a compile-time error.
        send_to_port(next_hop_id);
#endif  // DPDK_PNA_SEND_TO_PORT_FIX_MERGED
#endif // TARGET_DPDK_PNA  
    }

    action pkt_act(bit<9> packet_action, bit<9> next_hop_id) {
        if(packet_action == SAI_PACKET_ACTION_DROP) {
            /* Drops the packet */
            meta.dropped = true;
        } else if (packet_action == SAI_PACKET_ACTION_FORWARD) {
            /* Forwards the packet on different/same port it arrived based on routing */
            set_nhop(next_hop_id);
        }
    }

    action def_act() {
#ifdef TARGET_BMV2_V1MODEL
        standard_metadata.egress_spec = standard_metadata.ingress_port;
#endif // TARGET_BMV2_V1MODEL

#ifdef TARGET_DPDK_PNA
#ifdef DPDK_PNA_SEND_TO_PORT_FIX_MERGED
        // As of 2023-Jan-26, the version of the pna.p4 header file
        // included with p4c defines send_to_port with a parameter
        // that has no 'in' direction.  The following commit in the
        // public pna repo fixes this, but this fix has not yet been
        // copied into the p4c repo.
        // https://github.com/p4lang/pna/commit/b9fdfb888e5385472c34ff773914c72b78b63058
        // Until p4c is updated with this fix, the following line will
        // give a compile-time error.
        send_to_port(istd.input_port);
#endif  // DPDK_PNA_SEND_TO_PORT_FIX_MERGED
#endif // TARGET_DPDK_PNA
    }

    @SaiTable[name = "route", api = "route", api_type="underlay"]
    table underlay_routing {
        key = {
            meta.dst_ip_addr : lpm @SaiVal[name = "destination"];
        }

        actions = {
            // Processes a packet based on the specified packet action.
            // Depending on the packet action, it either drops the packet or forwards it to the specified next-hop. 
            pkt_act;

            /* Send packet on same port it arrived (echo) by default */
            @defaultonly def_act;
        }
    }

    apply {
        underlay_routing.apply();
    }
}
