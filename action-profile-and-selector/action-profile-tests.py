#!/usr/bin/env python2

'''Test cases for P4 program action-profile.p4'''

from __future__ import print_function
import collections

from scapy.all import *
# The following line isn't really necessary given the previous import
# line, but it does help avoid many 'undefined variable' pylint
# warnings
from scapy.all import TCP, Ether, IP
import runtime_CLI
import sstf_lib as sstf
import bm_runtime.standard.ttypes as ttypes


def table_entries(hdl, table_info):

    # Verify that simple_switch disallows adding a 'normal' table
    # entry to a table with implementation action_profile() or
    # action_selector().
    for table_name in table_info.keys():
        t = table_info[table_name]
        if 'act_prof_name' in t:
            exc_expected = True
        else:
            # Adding a normal table entry to a table with no action
            # profile should succeed.
            exc_expected = False
        exc_raised = False
        try:
            entry_hdl = hdl.do_table_add(table_name + " foo1 0xdead => 0xbeef")
        except ttypes.InvalidTableOperation:
            exc_raised = True
        if exc_expected:
            assert exc_raised
            print("Expected: exception InvalidTableOperation was raised")
        else:
            assert not exc_raised
            print("Expected: no exception InvalidTableOperation was raised")
            # Remove the entry that was added
            hdl.do_table_delete(table_name + " " + str(entry_hdl))

    # Verify that it is an error to try to create groups for tables
    # with implementation action_profile().  They have type 'indirect'
    # in compiled JSON files.
    for table_name in table_info.keys():
        t = table_info[table_name]
        if t['type'] != 'indirect':
            continue
        exc_expected = True
        exc_raised = False
        try:
            grp_handle = hdl.do_act_prof_create_group(t['act_prof_name'])
        except runtime_CLI.UIn_Error:
            exc_raised = True
        assert exc_raised
        print("Expected: exception runtime_CLI.UIn_Error was raised")

    print('')
    print('== table_indirect_add should fail for a normal table')
    for table_name in table_info.keys():
        t = table_info[table_name]
        member_hdl = None
        if 'act_prof_name' in t:
            exc_type_expected = None
            member_hdl = hdl.do_act_prof_create_member(t['act_prof_name'] +
                                                       " foo1 0xdead")
            # The commented-out code below confirmed that after doing
            # act_prof_create_member on a table's action profile, but
            # before doing table_indirect_add on the table, its
            # num_entries was 0.
            #num_entries = hdl.do_table_num_entries(table_name)
            #print("Table %s num_entries = %d" % (table_name, num_entries))
            #print("")
            #hdl.do_table_dump(table_name)
            #print("----------")
        else:
            exc_type_expected = runtime_CLI.UIn_Error
        exc_raised = None
        try:
            entry_hdl = hdl.do_table_indirect_add(table_name + " 0xdead => 0")
        except Exception as e:
            exc_raised = e
            print('Exception type %s raised' % (str(type(e))))
        print('')
        print('table %s exc_type_expected %s type(exc_raised) %s'
              '' % (table_name, exc_type_expected, type(exc_raised)))
        if exc_type_expected is None:
            assert exc_raised is None
            print("Expected: no exception was raised")
            assert hdl.do_table_num_entries(table_name) == 1
            print("Table %s has expected 1 entry" % (table_name))

            # Verify that trying to remove the member, while it still
            # has a table entry referring to it, causes an error.
            exc2_type_expected = ttypes.InvalidTableOperation
            exc2_raised = None
            try:
                hdl.do_act_prof_delete_member(t['act_prof_name'] + " " +
                                              str(member_hdl))
            except Exception as e:
                exc2_raised = e
            assert isinstance(exc2_raised, exc2_type_expected)
            print("Expected: While attempting act_prof_delete_member"
                  " on a member still referred to by an entry of table %s,"
                  " exception of type %s was raised"
                  "" % (table_name, exc2_type_expected))

            # Remove the entry that was added
            hdl.do_table_indirect_delete(table_name + " " + str(entry_hdl))
            # Remove the member that was added
            hdl.do_act_prof_delete_member(t['act_prof_name'] + " " +
                                          str(member_hdl))
            assert hdl.do_table_num_entries(table_name) == 0
            print("Table %s has expected 0 entries" % (table_name))
        else:
            assert isinstance(exc_raised, exc_type_expected)
            print("Expected: exception of type %s was raised"
                  "" % (exc_type_expected))
        print("----------------------------------------")


def main():
    # port_int_map represents the desired correspondence between P4
    # program port numbers and Linux interfaces.  The data structure
    # returned by port_intf_mapping() is used in multiple places
    # throughout the code.
    port_int_map = sstf.port_intf_mapping({0: 'veth2',
                                           1: 'veth4',
                                           2: 'veth6',
                                           3: 'veth8',
                                           4: 'veth10',
                                           5: 'veth12',
                                           6: 'veth14'})
    args = sstf.get_args()
    ss_process_obj = sstf.start_simple_switch(args, port_int_map)
    hdl = runtime_CLI.test_init(args)

    # This info I obtained from manually inspecting the contents of
    # the file action-profile.json compiled from action-profile.p4.
    # Is there is a way to use annotations in the P4_16 source code to
    # force the names of the action profiles?
    table_info = collections.OrderedDict()
    table_info['t0'] = {'type': 'simple'}
    table_info['t1'] = {
        'type': 'indirect',
        'act_prof_name': 'action_profile_0'
    }
    table_info['t2'] = {
        'type': 'indirect_ws',
        'act_prof_name': 'action_profile_1'
    }
    
    table_entries(hdl, table_info)

    ss_process_obj.kill()


if __name__ == '__main__':
    main()
