#! /usr/bin/env python3

import argparse

parser = argparse.ArgumentParser(description="""
TBD some description of what this program does goes here.""")
#parser.add_argument('--num-fields', dest='num_fields', type=int, required=True,
#                    help="""The number of fields in my_custom_hdr to
#                    generate.""")
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
