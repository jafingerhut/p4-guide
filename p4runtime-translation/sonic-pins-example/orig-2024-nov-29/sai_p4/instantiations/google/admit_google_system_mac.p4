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

#ifndef SAI_ADMIT_GOOGLE_SYSTEM_MAC_P4_
#define SAI_ADMIT_GOOGLE_SYSTEM_MAC_P4_

// The System MAC is installed by the inband manager running locally on the
// switch. It is needed to allow simple communication with a controller before
// the P4Info is pushed.
control admit_google_system_mac(in headers_t headers,
                                inout local_metadata_t local_metadata) {
  apply {
     local_metadata.admit_to_l3 =
      (headers.ethernet.dst_addr & 0x01_00_00_00_00_00) == 0;
  }
}  // control system_mac_admit

#endif  // SAI_ADMIT_GOOGLE_SYSTEM_MAC_P4_
