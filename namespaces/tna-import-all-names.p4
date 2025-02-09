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

// https://github.com/barefootnetworks/Open-Tofino/blob/master/share/p4c/p4include/tna.p4
// That file includes this one, at least for Tofino1:
// https://github.com/barefootnetworks/Open-Tofino/blob/master/share/p4c/p4include/tofino1arch.p4
// and that file in turn includes the following one:
// https://github.com/barefootnetworks/Open-Tofino/blob/master/share/p4c/p4include/tofino.p4

// The import statement below contains all of the top level names
// defined in all 3 of the files above, as of 2021-Dec-23.

// In addition to those define in core.p4, TNA defines match kinds:
// range, selector, atcam_partition_index

// TNA defines 6 error names, but the type 'error' is not used, so
// this doesn't seem useful.  The constants whose names begin with
// "PARSER_ERROR_" are the true parser error definitions in TNA.

// There are a total of 86 top level names as of 2021-Dec-22.

from tna import
    // typedefs
    PortId_t,
    MulticastGroupId_t,
    QueueId_t,
    MirrorType_t,
    MirrorId_t,
    ResubmitType_t,
    DigestType_t,
    ReplicationId_t,
    ParserError_t,

    // const
    PORT_METADATA_SIZE,
    PARSER_ERROR_OK,
    PARSER_ERROR_NO_MATCH,
    PARSER_ERROR_PARTIAL_HDR,
    PARSER_ERROR_CTR_RANGE,
    PARSER_ERROR_TIMEOUT_USER,
    PARSER_ERROR_TIMEOUT_HW,
    PARSER_ERROR_SRC_EXT,
    PARSER_ERROR_DST_CONT,
    PARSER_ERROR_PHV_OWNER,
    PARSER_ERROR_MULTIWRITE,
    PARSER_ERROR_ARAM_MBE,
    PARSER_ERROR_FCS,

    // enum
    MeterType_t,
    MeterColor_t,
    CounterType_t,
    SelectorMode_t,
    HashAlgorithm_t,

    // header and structs
    ingress_intrinsic_metadata_t,
    ingress_intrinsic_metadata_for_tm_t,
    ingress_intrinsic_metadata_from_parser_t,
    ingress_intrinsic_metadata_for_deparser_t,
    egress_intrinsic_metadata_t,
    egress_intrinsic_metadata_from_parser_t,
    egress_intrinsic_metadata_for_deparser_t,
    egress_intrinsic_metadata_for_output_port_t,
    pktgen_timer_header_t,
    pktgen_port_down_header_t,
    pktgen_recirc_header_t,
    ptp_metadata_t,

    // extern functions
    max,
    min,
    invalidate,
    invalidate,
    port_metadata_unpack,
    sizeInBits,
    sizeInBytes,

    // extern objects
    Checksum,
    ParserCounter,
    ParserPriority,
    CRCPolynomial,
    Hash,
    Random,
    Counter,
    DirectCounter,
    Meter,
    DirectMeter,
    Lpf,
    DirectLpf,
    Wred,
    DirectWred,
    Register,
    DirectRegister,
    RegisterParam,
    MathOp_t,  // this one is an enum for MathUnit extern object
    MathUnit,
    RegisterAction,
    DirectRegisterAction,
    ActionProfile,
    ActionSelector,
    SelectorAction,
    Mirror,
    Resubmit,
    Digest,
    Atcam,
    Alpm,

    // parsers
    IngressParserT,
    EgressParserT,

    // controls
    IngressT,
    EgressT,
    IngressDeparserT,
    EgressDeparserT,

    // packages
    Pipeline,
    Switch,
    EgressParsers,
    MultiParserPipeline,
    MultiParserSwitch;
