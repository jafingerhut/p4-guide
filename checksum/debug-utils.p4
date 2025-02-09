// Copyright 2018 Andy Fingerhut
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

// Because open source P4 tools do not support using a value of type
// `error` as a field in a table's search key as of 2018-Sep-21, work
// around that limitation by converting parser_error to an unsigned
// integer.  We will use _that_ converted value for debug table
// purposes.

// It is easy to add more possible `error` type values to this
// conversion if you wish, but there is no way in P4_16 to
// automatically iterate over all additional possible values that a
// user program might have defined for type `error`.

control convert_error_to_bitvector(out bit<8> error_as_int,
                                   in error e)
{
    apply {
        if (e == error.NoError) {
            error_as_int = 0;
        } else if (e == error.PacketTooShort) {
            error_as_int = 1;
        } else if (e == error.NoMatch) {
            error_as_int = 2;
        } else if (e == error.StackOutOfBounds) {
            error_as_int = 3;
        } else if (e == error.HeaderTooShort) {
            error_as_int = 4;
        } else if (e == error.ParserTimeout) {
            error_as_int = 5;
        } else {
            // Unknown value
            error_as_int = 0xff;
        }
    }
}

control debug_std_meta(in standard_metadata_t standard_metadata)
{
    bit<8> parser_error_as_int;
    convert_error_to_bitvector() convert_err;
    table dbg_table {
        key = {
            // This is a complete list of fields inside of the struct
            // standard_metadata_t as of the 2018-Sep-01 version of
            // p4c in the file p4c/p4include/v1model.p4.

            // parser_error is commented out because the p4c back end
            // for bmv2 as of that date gives an error if you include
            // a field of type 'error' in a table key.

            // drop and recirculate_port are commented out because
            // they are not used by BMv2 simple_switch, and we may
            // want to delete them from v1model.p4 in the future.
            standard_metadata.ingress_port : exact;
            standard_metadata.egress_spec : exact;
            standard_metadata.egress_port : exact;
            standard_metadata.clone_spec : exact;
            standard_metadata.instance_type : exact;
            //standard_metadata.drop : exact;
            //standard_metadata.recirculate_port : exact;
            standard_metadata.packet_length : exact;
            standard_metadata.enq_timestamp : exact;
            standard_metadata.enq_qdepth : exact;
            standard_metadata.deq_timedelta : exact;
            standard_metadata.deq_qdepth : exact;
            standard_metadata.ingress_global_timestamp : exact;
            standard_metadata.egress_global_timestamp : exact;
            standard_metadata.lf_field_list : exact;
            standard_metadata.mcast_grp : exact;
            standard_metadata.resubmit_flag : exact;
            standard_metadata.egress_rid : exact;
            standard_metadata.checksum_error : exact;
            standard_metadata.recirculate_flag : exact;
            //standard_metadata.parser_error : exact;
            parser_error_as_int : exact;
        }
        actions = { NoAction; }
        const default_action = NoAction();
    }
    apply {
        convert_err.apply(parser_error_as_int, standard_metadata.parser_error);
        dbg_table.apply();
    }
}
