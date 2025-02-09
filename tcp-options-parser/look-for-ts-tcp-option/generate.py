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
TBD some description of what this program does goes here.""")
parser.add_argument('--num-parse-iterations',
                    dest='num_parse_iterations', type=int,
                    required=True,
                    help="""The maximum number of iterations to do
                    TCP options parsing.""")
args = parser.parse_known_args()[0]

# Represent any number of TCP options from 0 up to 40 bytes, in
# multiples of 4 bytes (a restriction of the TCP header format), using
# 10 P4 headers with names of the form 'tcp_options_part<n>_t', where
# n ranges from 0 up to 9.
options_hdrs = []
for i in range(10):
    field_names = ['f%d' % (4*i + 0),
                   'f%d' % (4*i + 1),
                   'f%d' % (4*i + 2),
                   'f%d' % (4*i + 3)]
    tmp = {'type_name': ('tcp_options_part%d_t' % (i)),
           'hdr_name': ('tcp_options_part%d' % (i)),
           'field_names' : field_names}
    options_hdrs.append(tmp)

with open('define_tcp_options_headers.p4', 'w') as f:
    for options_hdr in options_hdrs:
        print("header %s {" % (options_hdr['type_name']), file=f)
        for field_name in options_hdr['field_names']:
            print("    bit<8> %s;" % (field_name), file=f)
        print("}", file=f)

with open('tcp_options_headers_inside_headers_t_definition.p4', 'w') as f:
    for options_hdr in options_hdrs:
        print("    %s %s;" % (options_hdr['type_name'],
                              options_hdr['hdr_name']),
              file=f)

with open('parse_tcp_select_dataOffset_transitions.p4', 'w') as f:
    for i in range(10):
        dataOffset_value = i + 5
        if i == 0:
            # No options
            print("            %d: accept;" % (dataOffset_value), file=f)
        else:
            print("            %d: parse_tcp_options_length_%d_bytes;"
                  "" % (dataOffset_value, 4*i),
                  file=f)

with open('tcp_options_parser_states.p4', 'w') as f:
    for i in range(1, 10):
        print("    state parse_tcp_options_length_%d_bytes {"
              "" % (4*i),
              file=f)
        for j in range(i):
            print("        packet.extract(hdr.%s);"
                  "" % (options_hdrs[j]['hdr_name']),
                  file=f)
        print("        transition accept;", file=f)
        print("    }", file=f)

with open('emit_tcp_options_headers.p4', 'w') as f:
    for options_hdr in options_hdrs:
        print("        packet.emit(hdr.%s);"
              "" % (options_hdr['hdr_name']),
              file=f)

with open('get_tcp_options_byte.p4', 'w') as f:
    action_names = []
    field_names = []
    for i in range(40):
        action_names.append("get_offset_%d" % (i))
        field_names.append("hdr.tcp_options_part%d.f%d" % (int(i/4), i))
    
    for i in range(40):
        print("""    action %s() {
        val = %s;
    }""" % (action_names[i], field_names[i]),
              file=f)
    print("""    table t_get_tcp_options_byte {
        key = {
            offset : exact;
        }
        actions = {""", file=f)
    for action_name in action_names:
        print("            %s;" % (action_name), file=f)
    print("""        }
        const entries = {""", file=f)
    for i in range(40):
        print("            %d: %s();" % (i, action_names[i]), file=f)
    print("""        }
    }
    apply {
        t_get_tcp_options_byte.apply();
    }""", file=f)

with open('get_tcp_options_bit32.p4', 'w') as f:
    num_fields = 40
    # The number of offsets to the beginning of 4-byte words is 3 less
    # than the number of bytes, because the last 3 offsets would run
    # off the end of the sequence of bytes.
    num_offsets = num_fields - 3

    action_names = []
    field_names = []
    for i in range(num_fields):
        if i < num_offsets:
            action_names.append("get_offset_%d" % (i))
        field_names.append("hdr.tcp_options_part%d.f%d" % (int(i/4), i))
    
    for i in range(num_offsets):
        print("""    action %s() {
        val = %s ++ %s ++ %s ++ %s;
    }""" % (action_names[i],
            field_names[i+0],
            field_names[i+1],
            field_names[i+2],
            field_names[i+3]),
              file=f)
    print("""    table t_get_tcp_options_byte {
        key = {
            offset : exact;
        }
        actions = {""", file=f)
    for action_name in action_names:
        print("            %s;" % (action_name), file=f)
    print("""        }
        const entries = {""", file=f)
    for i in range(num_offsets):
        print("            %d: %s();" % (i, action_names[i]), file=f)
    print("""        }
    }
    apply {
        t_get_tcp_options_byte.apply();
    }""", file=f)

with open('instantiate_controls.p4', 'w') as f:
    for i in range(args.num_parse_iterations):
        print("    parse_one_tcp_option() parse_one_tcp_option_inst%d;"
              "" % (i+1),
              file=f)

with open('tcp_parse_iterations_1_through_n.p4', 'w') as f:
    for i in range(1, args.num_parse_iterations):
        print("""
            if (!executed_break && (offset < options_length)) {
                // Loop iteration #%d
                iteration_count = iteration_count + 1;
                parse_one_tcp_option_inst%d.apply(hdr, options_length, offset, offset,
                    found_ts_option, executed_break);
            }"""
              "" % (i+1, i+1),
              file=f)
