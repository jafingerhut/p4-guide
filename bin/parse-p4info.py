#! /usr/bin/env python

import argparse
import sys

import google.protobuf.text_format as text_format
import google.protobuf.pyext as pyext
import p4.config.v1.p4info_pb2 as p4info_pb2

def read_p4info_text_format_from_file(fname):
    p4info = p4info_pb2.P4Info()
    f = argparse.FileType('r')(fname)
    text = f.read()
    text_format.Merge(text, p4info)
    return p4info

def is_field_descriptor(x):
    return (type(x) is pyext._message.FieldDescriptor)

def name_in_preamble(x):
    return getattr(getattr(x, 'preamble'), 'name')

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

#fname='/home/jafinger/p4-guide/p4runtime/expected-p4info-files/psa-example-digest-bmv2.psa.p4info.txt'
fname=sys.argv[1]
p4info = read_p4info_text_format_from_file(fname)

#verbose = False
verbose = True

# TBD: Is there a way to get a list of all second parameter values p
# for which getattr(p4info, p) will return something useful?
# ('tables' in dir(p4info)) is False, for example, so dir() does not help there.

object_counts = {}
object_names = {}
type_info_counts = {}
type_info_names = {}

p4info_fields = list(p4info.ListFields())
for i1 in range(len(p4info_fields)):
    m1 = p4info_fields[i1]
    assert is_field_descriptor_and_value(m1)
    field_name = getattr(m1[0], 'name')
    if not is_p4info_field_name(field_name):
        print("field_name=%s type %s failed assertion"
              "" % (field_name, type(field_name)))
    assert is_p4info_field_name(field_name)
    if is_composite_container(m1[1]):
        object_counts[field_name] = len(m1[1])
        object_names[field_name] = sorted(list(map(name_in_preamble, m1[1])))
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
        type_info_list = list(m1[1].ListFields())
        for i2 in range(len(type_info_list)):
            t1 = type_info_list[i2]
            assert is_field_descriptor_and_value(t1)
            name = getattr(t1[0], 'name')
            type_info_counts[name] = len(t1[1])
            type_info_names[name] = sorted(t1[1].keys())


#    for i2 in range(len(m1)):
#        if is_field_descriptor(m1[i2]):
#            assert hasattr(m1[i2], 'name')
#            assert hasattr(m1[i2], 'full_name')
#            if verbose:
#                print('    i2 %d type field name %s full_name %s'
#                      '' % (i2,
#                            getattr(m1[i2], 'name', '(none)'),
#                            getattr(m1[i2], 'full_name', '(none)')))
#        elif is_composite_container(m1[i2]):
#            if verbose:
#                print('    i2 %d type container' % (i2))
#            assert hasattr(m1[i2], 'name') == False
#            assert hasattr(m1[i2], 'full_name') == False
#            for i3 in range(len(m1[i2])):
#                m2 = m1[i2][i3]
#                if verbose:
#                    print('        i3 %d type %s name %s full_name %s'
#                          '' % (i3, type(m2),
#                                getattr(m2, 'name', '(none)'),
#                                getattr(m2, 'full_name', '(none)')))
#        else:
#            if verbose:
#                print('    i2 %d type %s name %s full_name %s'
#                      '' % (i2, type(m1[i2]),
#                            getattr(m1[i2], 'name', '(none)'),
#                            getattr(m1[i2], 'full_name', '(none)')))

for name in sorted(object_counts.keys()):
    assert object_counts[name] == len(object_names[name])
    print("%d %s - %s"
          "" % (len(object_names[name]), name,
                ' '.join(object_names[name])))
if len(type_info_counts) != 0:
    print("type_info details:")
    for name in sorted(type_info_names.keys()):
        assert type_info_counts[name] == len(type_info_names[name])
        print("    %d %s - %s"
              "" % (len(type_info_names[name]),
                    name,
                    ' '.join(type_info_names[name])))
