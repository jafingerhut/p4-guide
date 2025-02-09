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

#define SAI_INSTANTIATION_WBB

#include <v1model.p4>

// These headers have to come first, to override their fixed counterparts.
#include "roles.h"
#include "versions.h"
#include "bitwidths.p4"
#include "minimum_guaranteed_sizes.p4"

#include "../../fixed/headers.p4"
#include "../../fixed/metadata.p4"
#include "../../fixed/roles.h"
#include "acl_wbb_ingress.p4"

control ingress(inout headers_t headers,
                inout local_metadata_t local_metadata,
                inout standard_metadata_t standard_metadata) {
  apply {
    acl_wbb_ingress.apply(headers, local_metadata, standard_metadata);
  }
}

control egress(inout headers_t headers,
               inout local_metadata_t local_metadata,
               inout standard_metadata_t standard_metadata) {
  apply {}
}

parser packet_parser(packet_in packet, out headers_t headers,
                     inout local_metadata_t local_metadata,
                     inout standard_metadata_t standard_metadata) {
  state start {
    transition accept;
  }
}

control packet_deparser(packet_out packet, in headers_t headers) {
  apply {}
}

control verify_ipv4_checksum(inout headers_t headers,
                             inout local_metadata_t local_metadata) {
  apply {}
}

control compute_ipv4_checksum(inout headers_t headers,
                              inout local_metadata_t local_metadata) {
  apply {}
}

#ifndef PKG_INFO_NAME
#define PKG_INFO_NAME "wbb.p4"
#endif

@pkginfo(
  name = PKG_INFO_NAME,
  organization = "Google",
  version = SAI_P4_PKGINFO_VERSION_LATEST
)
V1Switch(packet_parser(), verify_ipv4_checksum(), ingress(), egress(),
         compute_ipv4_checksum(), packet_deparser()) main;
