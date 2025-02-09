#! /usr/bin/env python3
# Copyright 2020 Andy Fingerhut
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# SPDX-License-Identifier: Apache-2.0


import argparse

parser = argparse.ArgumentParser(description="""
Text describing what this program does and how to use it.""")
parser.add_argument('--num-fields', dest='num_fields', type=int, required=True,
                    help="""The number of fields in my_custom_hdr to
                    generate.""")
args = parser.parse_known_args()[0]

with open('generated_my_custom_hdr_fields.p4', 'w') as f:
    for i in range(args.num_fields):
        print('    bit<8> f%d;' % (i), file=f)


with open('generated_read_write_custom_header_at_index.p4', 'w') as f:
    rd_action_definitions = []
    rd_action_list = []
    rd_const_entries = []
    for i in range(args.num_fields - 1):
        action_name = "read_offset_%d" % (i)
        rd_action_definitions.append("""
    action %s () {
        result = my_custom_hdr.f%d ++ my_custom_hdr.f%d;
    }"""
                                  "" % (action_name, i, i+1))
        rd_action_list.append("            %s;" % (action_name))
        rd_const_entries.append("            %d : %s();" % (i, action_name))

    wr_action_definitions = []
    wr_action_list = []
    wr_const_entries = []
    for i in range(args.num_fields - 1):
        action_name = "write_offset_%d" % (i)
        wr_action_definitions.append("""
    action %s () {
        my_custom_hdr.f%d = write_val[15:8];
        my_custom_hdr.f%d = write_val[7:0];
    }"""
                                  "" % (action_name, i, i+1))
        wr_action_list.append("            %s;" % (action_name))
        wr_const_entries.append("            %d : %s();" % (i, action_name))

    print("""
control read_custom_header_at_index (in my_custom_hdr_t my_custom_hdr,
                                     in bit<8> index,
				     out bit<16> result,
                                     out bool index_in_range)
{
%s

    action index_out_of_range () {
        index_in_range = false;
        result = 0;
    }

    table read_from_index {
        key = {
            index : exact;
        }
        actions = {
%s
            @defaultonly index_out_of_range;
        }
        const entries = {
%s
        }
        const default_action = index_out_of_range;
    }

    apply {
        index_in_range = true;
        read_from_index.apply();
    }
}"""
          "" % ('\n'.join(rd_action_definitions),
                '\n'.join(rd_action_list),
                '\n'.join(rd_const_entries)),
          file=f)

    print("""
control write_custom_header_at_index (inout my_custom_hdr_t my_custom_hdr,
                                      in bit<8> index,
				      in bit<16> write_val,
                                      out bool index_in_range)
{
%s

    action index_out_of_range () {
        index_in_range = false;
    }

    table write_to_index {
        key = {
            index : exact;
        }
        actions = {
%s
            @defaultonly index_out_of_range;
        }
        const entries = {
%s
        }
        const default_action = index_out_of_range;
    }

    apply {
        index_in_range = true;
        write_to_index.apply();
    }
}"""
          "" % ('\n'.join(wr_action_definitions),
                '\n'.join(wr_action_list),
                '\n'.join(wr_const_entries)),
          file=f)
