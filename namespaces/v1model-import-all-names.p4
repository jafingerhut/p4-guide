// Copyright 2021 Andy Fingerhut
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

// The following is all of the top level names in the v1model
// architecture as of 2021-Dec-14, as defined in this file:

// https://github.com/p4lang/p4c/blob/main/p4include/v1model.p4

// match_kind list was originally range, selector on 2016-Apr-04.
// optional was added to v1model on 2020-Feb-04.

// A struct type named standard_metadata_t has always been part of
// v1model.p4 since the beginning.  What fields it contains has
// changed over the years.  Those changes are not described here.

//       28 top level names at end of 2016
// +5 -> 33 top level names at end of 2017
// No change to this count in 2018
// +3 -> 36 top level names at end of 2019
// +2 -> 38 top level names at end of 2020
// +3 -> 41 top level names at end of 2021

// There are a total of 41 top level names as of 2021-Dec-14.

from v1model import
    ////////////////////////////////////////////////////////////
    // Until the next comment, the first group of names were added 2016-Apr-04
    ////////////////////////////////////////////////////////////
    standard_metadata_t,
    CounterType,
    HashAlgorithm,
    CloneType,
    random,
    digest,
    mark_to_drop,  // 2 signatures, 0-arg signature deprecated 2019-Apr-18
    hash,
    Checksum16,
    clone,
    Parser,
    VerifyChecksum,
    Ingress,
    Egress,
    ComputeChecksum,
    Deparser,
    V1Switch,
    resubmit,    // deprecated 2021-Dec-06: see resubmit_preserving_field_list
    recirculate, // deprecated 2021-Dec-06: see recirculate_preserving_field_list
    clone3,      // deprecated 2021-Dec-06: see clone_preserving_field_list

    ////////////////////////////////////////////////////////////
    // The next group were originally named CapitalizedStyle, renamed
    // 2016-May-31
    ////////////////////////////////////////////////////////////
    counter,         // originally Counter
    direct_counter,  // originally DirectCounter
    meter,           // originally Meter
    direct_meter,    // originally DirectMeter
    register,        // originally Register
    action_profile,  // originally ActionProfile
    action_selector, // originally ActionSelector

    truncate,        // added 2016-Dec-02

    MeterType,       // added 2017-Mar-29
    verify_checksum,               // added 2017-Aug-23
    update_checksum,               // added 2017-Aug-23
    verify_checksum_with_payload,  // added 2017-Dec-12
    update_checksum_with_payload,  // added 2017-Dec-12

    assert,    // added 2019-Jun-18
    assume,    // added 2019-Jun-18
    log_msg,   // 2 signatures, added 2019-Oct-01

    __v1model_version,   // added 2020-Apr-13
    PortId_t,            // added 2020-Apr-13

    // the next group were added on 2021-Dec-06
    resubmit_preserving_field_list,
    recirculate_preserving_field_list,
    clone_preserving_field_list;
