#! /usr/bin/env python

# Copyright 2019 Cisco Systems, Inc.
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

from __future__ import print_function
import argparse
import sys

# Note for future hackers: Here are a couple of other example Python
# programs that also extract data out of P4Info files.  They may
# contain useful code snippets that can be adapted for use in this
# program.

# https://github.com/p4lang/PI/blob/master/proto/p4info/xform/xform_anno.py
# https://github.com/p4lang/tutorials/blob/master/utils/p4runtime_lib/helper.py
# https://github.com/p4lang/tutorials/blob/master/utils/p4runtime_lib/simple_controller.py

try:
    import google.protobuf.text_format as text_format
    import google.protobuf.pyext as pyext
    import p4.config.v1.p4info_pb2 as p4info_pb2
except Exception as e:
    print(e)
    print("""
Missing one or more Python packages required by this program.
One way to install them on an Ubuntu 16.04 or 18.04 Linux system is to
follow the instructions here for running the installation script
called 'install-p4dev-p4runtime.sh':

https://github.com/jafingerhut/p4-guide/blob/master/bin/README-install-troubleshooting.md

There are likely smaller sets of software packages one can install to
enable this script to work, too, but I do not know what the smallest
set is.
""")
    sys.exit(1)


def read_p4info_text_format_from_file(fname):
    p4info = p4info_pb2.P4Info()
    f = argparse.FileType('r')(fname)
    text = f.read()
    # TBD: Better to close file f here?
    text_format.Merge(text, p4info)
    return p4info

def is_field_descriptor(x):
    return (type(x) is pyext._message.FieldDescriptor)

def name_in_preamble(x):
    return x.preamble.name

def is_field_descriptor_and_value(x):
    if not (type(x) is tuple):
        return False
    if not (len(x) == 2):
        return False
    if not (is_field_descriptor(x[0])):
        return False
    if not (hasattr(x[0], 'name')):
        return False
    if not (hasattr(x[0], 'full_name')):
        return False
    return True

def is_composite_container(x):
    return (type(x) is pyext._message.RepeatedCompositeContainer)

def is_scalar_container(x):
    return (type(x) is pyext._message.RepeatedScalarContainer)

def is_table(x):
    return (type(x) is p4.config.v1.p4info_pb2.Table)

def is_action(x):
    return (type(x) is p4.config.v1.p4info_pb2.Action)

def is_p4info_field_name(x):
    if type(x) is not str:
        return False
    # This is the list of field names allowed directly inside of a
    # P4Info message, from the 'message P4Info' definition in file
    # p4info.proto
    if x not in ['pkg_info', 'tables', 'actions', 'action_profiles',
                 'counters', 'direct_counters', 'meters', 'direct_meters',
                 'controller_packet_metadata', 'value_sets', 'registers',
                 'digests', 'externs', 'type_info']:
        return False
    return True

def is_p4info_repeated_field_name(x):
    if type(x) is not str:
        return False
    # This is the list of field names defined in a P4Info message as
    # 'repeated' in file p4info.proto
    if x not in ['tables', 'actions', 'action_profiles',
                 'counters', 'direct_counters', 'meters', 'direct_meters',
                 'controller_packet_metadata', 'value_sets', 'registers',
                 'digests', 'externs']:
        return False
    return True

######################################################################
# Parse command line arguments

parser = argparse.ArgumentParser(description="""
Read and perform some sanity checks, and summarize some of the contents
of a P4Runtime P4Info file.
""")
parser.add_argument(
    '-d',
    '--debug',
    dest='debug',
    action='store_true',
    default=False,
    help='Print debug information')
parser.add_argument(
    dest='input_file', type=str, help='The P4Info input file')

args = parser.parse_args()
fname=args.input_file

######################################################################
# Try reading the input file

# Note that this will do a fair amount of checking the syntax and the
# 'schema' of the input file, e.g. that the P4Info message names are
# correct, nested in the way that they should be, and that the types
# of the values are integer/string/etc. as they should be.

######################################################################
# Here are some things that read_p4info_text_format_from_file _does_
# raise an exception for, if it detects it while reading a text format
# P4Info file:

# Any field name present that is not one of those defined in the
# .proto file, e.g. 'tales' instead of 'tables' at the top level, or
# 'preable' instead of 'preamble' inside of any message that has a
# 'preamble' field.  Also 'preamble' correctly spelled at the top
# level, since a P4Info message has no such field.

# If a value is expected of any one of the following types, but a
# different one is found, then an exception is raised:
# + a string, which in the text file has double quotes around it
# + an integer, which must not have quotes around it
# + an 'enum' value, e.g. EXACT, LPM, which must not have quotes around it

######################################################################
# Here are some things that read_p4info_text_format_from_file _does
# not_ raise an exception for:

# If a valid field name is repeated, the last value is kept, and the
# earlier ones are silently ignored.

# If you read a text format P4Info file with the text below for its
# 'type_info' message, it will have two entries in the 'new_types'
# map:

# type_info {
#   new_types {
#     key: "PortId_t"
#     value {
#       translated_type {
#         uri: "p4.org/psa/v1/PortId_t"
#         sdn_bitwidth: 32
#       }
#     }
#   }
#   new_types {
#     key: "ClassOfService_t"
#     value {
#       translated_type {
#         uri: "p4.org/psa/v1/ClassOfService_t"
#         sdn_bitwidth: 8
#       }
#     }
#   }
# }

# However, if you delete the second 'new_types {' line and the one
# right above that, the file will be read with no errors, but the map
# will only contain the key "ClassOfService_t", not "PortId_t".  This
# is probably just a special case of the previous not about repeated
# field names causing only the last occurrence to be preserved, and
# earlier ones silently ignored.

# If an action_refs field of a table has an id with a number X, but X
# appears nowhere else in the file, no exception is raised, even
# though a correct P4Info message should have an 'actions' message
# elsewhere in the file with a 'preamble' field, containing an 'id'
# field with that number X.

# The above is merely one example of such a 'reference' relationship
# of id values that is not checked by
# read_p4info_text_format_from_file.  It is likely that no such
# constraints are checked by that function.

p4info = read_p4info_text_format_from_file(fname)


######################################################################
# Do some minimal sanity checks.  All of them are very fast to
# perform.  Although some are likely redundant given the checks done
# by read_p4info_text_format_from_file above, writing them helped me
# learn the form of the Python data structures used to represent the
# data.

# TBD: Is there a way to get a list of all second parameter values p
# for which getattr(p4info, p) will return something useful?
# ('tables' in dir(p4info)) is False, for example, so dir() does not help there.

for m1 in p4info.ListFields():
    assert is_field_descriptor_and_value(m1)
    field_name = m1[0].name
    if not is_p4info_field_name(field_name):
        print("field_name=%s type %s failed assertion"
              "" % (field_name, type(field_name)))
    assert is_p4info_field_name(field_name)
    if is_composite_container(m1[1]):
        pass
    else:
        # All fields of a P4Info message are declared 'repeated'
        # except pkg_info and type_info.  It appears that in the
        # Python objects created from reading a legal P4Info message,
        # fields declared as 'repeated' might always be of the class
        # of object for which is_composite_container() returns True.
        if is_p4info_repeated_field_name(field_name):
            print("field_name=%s does not have a composite container as its value"
                  "" % (field_name))
        assert is_p4info_repeated_field_name(field_name) == False

    if field_name == 'type_info':
        for t1 in m1[1].ListFields():
            assert is_field_descriptor_and_value(t1)


######################################################################
# Extract and print some summary information about the contents of the
# P4Info file.

object_names = {}
type_info_names = {}

for m1 in p4info.ListFields():
    field_name = m1[0].name
    if is_composite_container(m1[1]):
        object_names[field_name] = sorted(list(map(name_in_preamble, m1[1])))
    if field_name == 'type_info':
        for t1 in m1[1].ListFields():
            name = t1[0].name
            if name == 'error':
                # The 'error' field inside of the 'type_info' message
                # has a different type than the others.
                for e1 in t1[1].ListFields():
                    type_info_names[name] = list(e1[1])
            else:
                type_info_names[name] = sorted(t1[1].keys())

for name in sorted(object_names.keys()):
    print("%d %s - %s" % (len(object_names[name]), name,
                          ' '.join(object_names[name])))
if len(type_info_names) != 0:
    print("type_info details:")
    for name in sorted(type_info_names.keys()):
        print("    %d %s - %s" % (len(type_info_names[name]), name,
                                  ' '.join(type_info_names[name])))
