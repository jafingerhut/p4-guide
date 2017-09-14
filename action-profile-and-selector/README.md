# Motivation

action-profile.p4 was written simply to experiment with action
profiles in P4_16, to learn about their behavior using the open source
p4c-bm2-ss and simple_switch.


# Compiling

See README-using-bmv2.txt for some things that are common across
different P4 programs executed using bmv2.

To compile the P4_16 version of the code:

    p4c-bm2-ss action-profile.p4 -o action-profile.json


# Running

    sudo simple_switch --log-console -i 0@veth2 action-profile.json

See the difference between action-profile.json and
action-profile-without-implementation.json.  The latter was created by
compiling after commenting out the `implementation` line in table t1's
definition.

action-profile-without-implementation.json has the following attribute
and value for defining table t1:

    "type" : "simple",

action-profile.json has the following attributes instead:

    "type" : "indirect",
    "action_profile" : "action_profile_0",

action-profile.json also has this action profile defined in the
ingress pipeline, where action-profile-without-implementation.json has
an empty list for the value of "action_profile".

    "action_profiles" : [
      {
        "name" : "action_profile_0",
        "id" : 0,
        "max_size" : 4
      }
    ],

action-profile.json has the attributes below for table t2, that the
following implementation in the P4 source code:

        @mode("fair") implementation =
            action_selector(HashAlgorithm.identity, 16, 4);

Here are its attributes:

          "type" : "indirect_ws",
          "action_profile" : "action_profile_1",

and later in the JSON file, the attribute of action_profile_1 are:

        {
          "name" : "action_profile_1",
          "id" : 1,
          "selector" : {
            "algo" : "identity",
            "input" : [
              {
                "type" : "field",
                "value" : ["scalars", "metadata.hash1"]
              }
            ]
          },
          "max_size" : 16
        }

The second parameter value to the action_selector (16 in the example
above) appears to become the value of the "max_size" attribute of the
action profile in the JSON file.  I verified this guess by modifying
only the 16 value in the P4 source code, recompiling, and checking
that "max_size" changed to match.  When translated from a P4_14
program to P4_16, this second parameter of the action_selector() comes
from the `size` attribute of the action_profile.

The third parameter value to the action_selector (4 in the example
above) appears not to be put anywhere in the JSON file.  I changed
only the 4 value, and the JSON file produced by the compiler was
exactly the same as before I made the change.  What is that parameter
value supposed to be?  When translated from a P4_14 program to a P4_16
program, this third parameter of the action_selector() comes from the
`output_width` attribute of the field_list_calculation that is named
by the `selection_key` attribute of the `action_selector`, which in
turn is named by the `dynamic_action_selection` attribute of the
`action_profile`.


# simple_switch_CLI commands to manipulate tables with implementation `action_profile`

Try adding a table entry to t1 like a normal table, i.e. like a table
that did not have `implementation = action_profile(4);` as a table
attribute.

    % simple_switch_CLI

    RuntimeCmd: table_add t1 foo1 0xdead => 0xbeef
    Invalid table operation (WRONG_TABLE_TYPE)

After that, `table_dump t1` confirmed that the table was still empty,
as it was initially.

It seems that the only way to find out the name "action_profile_0" for
a P4_16 program is by looking inside the compiled JSON file, but once
you do know that name, you can use it with the "act_prof_dump" command
in `simple_switch_CLI`, like so:

    RuntimeCmd: act_prof_dump action_profile_0
    ==========
    MEMBERS
    RuntimeCmd: act_prof_dump action_profile_1
    Error: Invalid action profile name (action_profile_1)

Here are all of the `simple_switch_CLI` commands whose names begin
with "act_prof", and their "help" output:

    act_prof_add_member_to_group     <- table_indirect_add_member_to_group
    act_prof_create_group            <- table_indirect_create_group
    act_prof_create_member           <- table_indirect_create_member
    act_prof_delete_group            <- table_indirect_delete_group
    act_prof_delete_member           <- table_indirect_delete_member
    act_prof_dump
    act_prof_dump_group              <- table_dump_group
    act_prof_dump_member             <- table_dump_member
    act_prof_modify_member           <- table_indirect_modify_member
    act_prof_remove_member_from_group <- table_indirect_remove_member_from_group

    RuntimeCmd: help act_prof_add_member_to_group
    Add member to group in an action profile: act_prof_add_member_to_group <action profile name> <member handle> <group handle>
    RuntimeCmd: help act_prof_create_group
    Add a group to an action pofile: act_prof_create_group <action profile name>
    RuntimeCmd: help act_prof_create_member
    Add a member to an action profile: act_prof_create_member <action profile name> <action_name> [action parameters]
    RuntimeCmd: help act_prof_delete_group
    Delete a group from an action profile: act_prof_delete_group <action profile name> <group handle>
    RuntimeCmd: help act_prof_delete_member
    Delete a member in an action profile: act_prof_delete_member <action profile name> <member handle>
    RuntimeCmd: help act_prof_dump
    Display entries in an action profile: act_prof_dump <action profile name>
    RuntimeCmd: help act_prof_dump_group
    Display some information about a group: table_dump_group <action profile name> <group handle>
    RuntimeCmd: help act_prof_dump_member
    Display some information about a member: act_prof_dump_member <action profile name> <member handle>
    RuntimeCmd: help act_prof_modify_member
    Modify member in an action profile: act_prof_modify_member <action profile name> <action_name> <member_handle> [action parameters]
    RuntimeCmd: help act_prof_remove_member_from_group
    Remove member from group in action profile: act_prof_remove_member_from_group <action profile name> <member handle> <group handle>

It appears that `simple_switch_CLI` and `simple_switch` combine to
detect an attempt to add a member to an action profile with an action
name that is in the P4 program, but not in the list of actions allowed
for the table that owns the action profile.  Good.

    RuntimeCmd: act_prof_create_member action_profile_0 foo3 5
    Error: Action profile 'action_profile_0' has no action 'foo3'

Here is a successful attempt to create a member of an action profile:

    RuntimeCmd: act_prof_create_member action_profile_0 foo2 5
    Member has been created with handle 0
    RuntimeCmd: table_dump t1
    ==========
    TABLE ENTRIES
    ==========
    MEMBERS
    **********
    Dumping member 0
    Action entry: foo2 - 05
    ==========
    Dumping default entry
    EMPTY
    ==========
    RuntimeCmd: act_prof_dump action_profile_0
    ==========
    MEMBERS
    **********
    Dumping member 0
    Action entry: foo2 - 05
    RuntimeCmd: help act_prof_dump_member
    Display some information about a member: act_prof_dump_member <action profile name> <member handle>
    RuntimeCmd: act_prof_dump_member action_profile_0 0
    Dumping member 0
    Action entry: foo2 - 05

I think I need to use the `table_indirect_add` command to create an
actual table entry that 'points to' this member of the action profile.
Try it out, and then send a packet that should match the table entry
to verify:

    RuntimeCmd: table_indirect_add t1 443 => 0
    Adding entry to indirect match table t1
    Entry has been added with handle 0
    RuntimeCmd: table_dump t1
    ==========
    TABLE ENTRIES
    **********
    Dumping entry 0x0
    Match key:
    * tcp.dstPort         : EXACT     01bb
    Index: member(0)
    ==========
    MEMBERS
    **********
    Dumping member 0
    Action entry: foo2 - 05
    ==========
    Dumping default entry
    EMPTY
    ==========

In Scapy:

    >>> pkt1=Ether() / IP(dst='10.1.0.1') / TCP(sport=5793, dport=443)
    >>> sendp(pkt1, iface='veth2')

In console log of simple_switch, I saw the packet search table t1 with
key 0x1bb=443 decimal, get a match, and perform the action foo2 with
action parameter 5, all as it seems it should.

Now add a second entry to the table, pointing at the same profile
member with handle 0:

    RuntimeCmd: table_indirect_add t1 17 => 0
    Adding entry to indirect match table t1
    Entry has been added with handle 1
    RuntimeCmd: table_dump t1
    ==========
    TABLE ENTRIES
    **********
    Dumping entry 0x0
    Match key:
    * tcp.dstPort         : EXACT     01bb
    Index: member(0)
    **********
    Dumping entry 0x1
    Match key:
    * tcp.dstPort         : EXACT     0011
    Index: member(0)
    ==========
    MEMBERS
    **********
    Dumping member 0
    Action entry: foo2 - 05
    ==========
    Dumping default entry
    EMPTY
    ==========

Now try modifying the one action profile member with handle 0 to have
a different action and action parameter than it had before, and see
whether both table entries still refer to this modified action profile
member.

    RuntimeCmd: act_prof_modify_member action_profile_0 foo1 0 88
    RuntimeCmd: table_dump t1
    ==========
    TABLE ENTRIES
    **********
    Dumping entry 0x0
    Match key:
    * tcp.dstPort         : EXACT     01bb
    Index: member(0)
    **********
    Dumping entry 0x1
    Match key:
    * tcp.dstPort         : EXACT     0011
    Index: member(0)
    ==========
    MEMBERS
    **********
    Dumping member 0
    Action entry: foo1 - 58
    ==========
    Dumping default entry
    EMPTY
    ==========
    RuntimeCmd: act_prof_dump action_profile_0
    ==========
    MEMBERS
    **********
    Dumping member 0
    Action entry: foo1 - 58

Looks like it should.  Send same packet as before to see that it
behaves differently now.

I tried it, and the output packet was different this time, and
simple_switch's console log showed action foo1 being executed for
table t1, instead of action foo2 as it did the first time.

Now try repeatedly adding members to the action profile, to see when
it fails.  I specified a size of 4 in action-profile.p4, so would
expect adding 4 members to succeed, but the fifth and later ones to
fail.  From the transcript below, though, you can see that it allows
many more than 4 members to be added to the action profile.

    RuntimeCmd: act_prof_create_member action_profile_0 foo2 7
    Member has been created with handle 1
    RuntimeCmd: act_prof_dump action_profile_0
    ==========
    MEMBERS
    **********
    Dumping member 0
    Action entry: foo1 - 58
    **********
    Dumping member 1
    Action entry: foo2 - 07
    RuntimeCmd: act_prof_create_member action_profile_0 foo1 10.11.12.13
    Member has been created with handle 2
    RuntimeCmd: act_prof_create_member action_profile_0 foo1 128.252.169.2
    Member has been created with handle 3
    RuntimeCmd: act_prof_create_member action_profile_0 foo2 192.168.0.1
    Member has been created with handle 4
    RuntimeCmd: act_prof_dump action_profile_0
    ==========
    MEMBERS
    **********
    Dumping member 0
    Action entry: foo1 - 58
    **********
    Dumping member 1
    Action entry: foo2 - 07
    **********
    Dumping member 2
    Action entry: foo1 - 0a0b0c0d
    **********
    Dumping member 3
    Action entry: foo1 - 80fca902
    **********
    Dumping member 4
    Action entry: foo2 - c0a80001
    RuntimeCmd: act_prof_create_member action_profile_0 foo1 5
    Member has been created with handle 5
    RuntimeCmd: act_prof_create_member action_profile_0 foo1 6
    Member has been created with handle 6
    RuntimeCmd: act_prof_create_member action_profile_0 foo1 7
    Member has been created with handle 7
    RuntimeCmd: act_prof_create_member action_profile_0 foo1 8
    Member has been created with handle 8
    RuntimeCmd: act_prof_create_member action_profile_0 foo1 9
    Member has been created with handle 9
    RuntimeCmd: act_prof_create_member action_profile_0 foo1 10
    Member has been created with handle 10
    RuntimeCmd: act_prof_create_member action_profile_0 foo1 11
    Member has been created with handle 11
    RuntimeCmd: act_prof_create_member action_profile_0 foo1 112
    Member has been created with handle 12
    RuntimeCmd: act_prof_dump action_profile_0
    ==========
    MEMBERS
    **********
    Dumping member 0
    Action entry: foo1 - 58
    **********
    Dumping member 1
    Action entry: foo2 - 07
    **********
    Dumping member 2
    Action entry: foo1 - 0a0b0c0d
    **********
    Dumping member 3
    Action entry: foo1 - 80fca902
    **********
    Dumping member 4
    Action entry: foo2 - c0a80001
    **********
    Dumping member 5
    Action entry: foo1 - 05
    **********
    Dumping member 6
    Action entry: foo1 - 06
    **********
    Dumping member 7
    Action entry: foo1 - 07
    **********
    Dumping member 8
    Action entry: foo1 - 08
    **********
    Dumping member 9
    Action entry: foo1 - 09
    **********
    Dumping member 10
    Action entry: foo1 - 0a
    **********
    Dumping member 11
    Action entry: foo1 - 0b
    **********
    Dumping member 12
    Action entry: foo1 - 70

That looks like a bug in simple_switch, perhaps?  I have filed a
Github issue on p4lang/behavioral-model repository about this
behavior, in case it is a bug deemed worthy of fixing:

    https://github.com/p4lang/behavioral-model/issues/435

Now try adding more than 8 table entries to see if that causes an
error.

    RuntimeCmd: table_indirect_add t1 17 => 0
    <etc. with unique keys>

I did get a TABLE_FULL error on attempting to add a 9th table entry to
table t1, which matches my expectations, since the P4_16 program has
'size = 8' for table t1.


# simple_switch_CLI commands to manipulate tables with implementation `action_selector`

One quick difference is the output format from the `table_dump`
command for tables t1 and t2.  The output for t2 mentions GROUPS in
addition to TABLE ENTRIES and MEMBERS:

    RuntimeCmd: table_dump t1
    ==========
    TABLE ENTRIES
    ==========
    MEMBERS
    ==========
    Dumping default entry
    EMPTY
    ==========
    
    RuntimeCmd: table_dump t2
    ==========
    TABLE ENTRIES
    ==========
    MEMBERS
    ==========
    GROUPS
    ==========
    Dumping default entry
    EMPTY
    ==========


Try adding a group to table t2, and then a member to that group, to
see if that works:

    RuntimeCmd: help act_prof_create_group
    Add a group to an action pofile: act_prof_create_group <action profile name>
    
    RuntimeCmd: act_prof_create_group action_profile_1
    Group has been created with handle 0
    
    RuntimeCmd: table_dump t2
    ==========
    TABLE ENTRIES
    ==========
    MEMBERS
    ==========
    GROUPS
    **********
    Dumping group 0
    Members: []
    ==========
    Dumping default entry
    EMPTY
    ==========

Now create a table entry that uses the just created group 0:

    RuntimeCmd: table_indirect_add t2 443 => 0
    Adding entry to indirect match table t2
    Invalid table operation (INVALID_MBR_HANDLE)

Add a member to action_profile_1, dump table t2, then add that member
number 0 to group 0, then dump table t2 again.

    RuntimeCmd: act_prof_create_member action_profile_1 foo2 17
    Member has been created with handle 0
    
    RuntimeCmd: table_dump t2
    ==========
    TABLE ENTRIES
    ==========
    MEMBERS
    **********
    Dumping member 0
    Action entry: foo2 - 11
    ==========
    GROUPS
    **********
    Dumping group 0
    Members: []
    ==========
    Dumping default entry
    EMPTY
    ==========
    
    RuntimeCmd: act_prof_add_member_to_group action_profile_1 0 0
    
    RuntimeCmd: table_dump t2
    ==========
    TABLE ENTRIES
    ==========
    MEMBERS
    **********
    Dumping member 0
    Action entry: foo2 - 11
    ==========
    GROUPS
    **********
    Dumping group 0
    Members: [0]
    ==========
    Dumping default entry
    EMPTY
    ==========

It looks like perhaps the command to add a group to a table with an
action_selector is `table_indirect_add_with_group`:

    RuntimeCmd: help table_indirect_add_with_group
    Add entry to an indirect match table: table_indirect_add <table name> <match fields> => <group handle> [priority]

Out of curiosity, first check whether simple_switch allows
table_indirect_add with a group in table t2:

    RuntimeCmd: table_indirect_add t2 443 => 0
    Adding entry to indirect match table t2
    Entry has been added with handle 0
    
    RuntimeCmd: table_dump t2
    ==========
    TABLE ENTRIES
    **********
    Dumping entry 0x0
    Match key:
    * tcp.srcPort         : EXACT     01bb
    Index: member(0)
    ==========
    MEMBERS
    **********
    Dumping member 0
    Action entry: foo2 - 11
    ==========
    GROUPS
    **********
    Dumping group 0
    Members: [0]
    ==========
    Dumping default entry
    EMPTY
    ==========

It looks like it does.  I am a little surprised.  I would have thought
that only groups could be added as the result of table entries in t2.

Remove member 0 from group 0, then create new members 1 and 2 that are
different than member 0, add them both to group 0, and use
`table_indirect_add_with_group` command to add a table entry that uses
group 0 as its action:

    RuntimeCmd: act_prof_remove_member_from_group action_profile_1 0 0
    
    RuntimeCmd: act_prof_create_member action_profile_1 foo1 201
    Member has been created with handle 1
    RuntimeCmd: act_prof_create_member action_profile_1 foo2 202
    Member has been created with handle 2
    
    RuntimeCmd: act_prof_add_member_to_group action_profile_1 1 0
    RuntimeCmd: act_prof_add_member_to_group action_profile_1 2 0
    
    RuntimeCmd: table_indirect_add_with_group t2 444 => 0
    Adding entry to indirect match table t2
    Entry has been added with handle 1

    RuntimeCmd: table_dump t2
    ==========
    TABLE ENTRIES
    **********
    Dumping entry 0x0
    Match key:
    * tcp.srcPort         : EXACT     01bb
    Index: member(0)
    **********
    Dumping entry 0x1
    Match key:
    * tcp.srcPort         : EXACT     01bc
    Index: group(0)
    ==========
    MEMBERS
    **********
    Dumping member 0
    Action entry: foo2 - 11
    **********
    Dumping member 1
    Action entry: foo1 - c9
    **********
    Dumping member 2
    Action entry: foo2 - ca
    ==========
    GROUPS
    **********
    Dumping group 0
    Members: [1, 2]
    ==========
    Dumping default entry
    EMPTY
    ==========

Now try sending some packets that match t2 entry 0 with tcp.srcPort
443 to see what happens:

    [ in Scapy session ]
    >>> pkt1=Ether() / IP(dst='10.1.0.1') / TCP(sport=5793, dport=443)
    >>> sendp(pkt1, iface='veth2')

From looking at the console log messages, the packet matched t2 entry
0, and performed action foo2 with parameter 11 (hex).  The only change
from input packet to output packet was assigning 0.0.0.17 to the IPv4
srcAddr, which is what action foo2 with parameter 0x11 should do.

Now try sending a packet that matches t2 entry 1 with tcp.srcPort 444:

    [ in Scapy session ]
    >>> pkt2=Ether() / IP(dst='10.1.0.1') / TCP(sport=444, dport=5793)
    >>> sendp(pkt2, iface='veth2')

Here are some relevant lines of console output from simple_switch for
table t2 matching:

    [05:18:10.187] [bmv2] [T] [thread 18675] [3.0] [cxt 0] Applying table 't2'
    [05:18:10.187] [bmv2] [D] [thread 18675] [3.0] [cxt 0] Looking up key:
    * tcp.srcPort         : 01bc
    
    [05:18:10.187] [bmv2] [D] [thread 18675] [3.0] [cxt 0] Choosing member 2 from group 0
    [05:18:10.187] [bmv2] [D] [thread 18675] [3.0] [cxt 0] Table 't2': hit with handle 1
    [05:18:10.187] [bmv2] [D] [thread 18675] [3.0] [cxt 0] Dumping entry 1
    Match key:
    * tcp.srcPort         : EXACT     01bc
    Index: group(0)
    Group members:
      mbr 1: foo1 - c9,
      mbr 2: foo2 - ca,
    
    [05:18:10.187] [bmv2] [D] [thread 18675] [3.0] [cxt 0] Action entry is foo2 - ca,

The IPv4 srcAddr changed to 0x000000ca as action foo2 should have done.

Now try changing the input packet IPv4 dstAddr to be 1 more than
before, to see if it will pick the other member of the group.

    [ in Scapy session ]
    >>> pkt3=Ether() / IP(dst='10.1.0.2') / TCP(sport=444, dport=5793)
    >>> sendp(pkt3, iface='veth2')

Here are some relevant lines of console output from simple_switch for
table t2 matching:

    [05:20:53.445] [bmv2] [T] [thread 18675] [4.0] [cxt 0] Applying table 't2'
    [05:20:53.445] [bmv2] [D] [thread 18675] [4.0] [cxt 0] Looking up key:
    * tcp.srcPort         : 01bc
    
    [05:20:53.445] [bmv2] [D] [thread 18675] [4.0] [cxt 0] Choosing member 1 from group 0
    [05:20:53.445] [bmv2] [D] [thread 18675] [4.0] [cxt 0] Table 't2': hit with handle 1
    [05:20:53.445] [bmv2] [D] [thread 18675] [4.0] [cxt 0] Dumping entry 1
    Match key:
    * tcp.srcPort         : EXACT     01bc
    Index: group(0)
    Group members:
      mbr 1: foo1 - c9,
      mbr 2: foo2 - ca,
    
    [05:20:53.445] [bmv2] [D] [thread 18675] [4.0] [cxt 0] Action entry is foo1 - c9,

For this packet it selected member 1 from group 0, which is action
foo1 with parameter 0xc9.

The only change from input packet to output packet was to change the
IPv4 dstAddr to 0.0.0.201, which is what action foo1 with parameter
0xc9 should do.

Now try adding a third member to group 0, and send in packets with
varying values of the 'selector' field `meta.hash1 =
hdr.ipv4.dstAddr[15:0]`, to see which values of the selector cause
which members of the 3-element group to be selected.

    RuntimeCmd: act_prof_create_member action_profile_1 foo1 109
    Member has been created with handle 3

    RuntimeCmd: act_prof_add_member_to_group action_profile_1 3 0

    RuntimeCmd: table_dump t2
    ==========
    TABLE ENTRIES
    **********
    Dumping entry 0x0
    Match key:
    * tcp.srcPort         : EXACT     01bb
    Index: member(0)
    **********
    Dumping entry 0x1
    Match key:
    * tcp.srcPort         : EXACT     01bc
    Index: group(0)
    ==========
    MEMBERS
    **********
    Dumping member 0
    Action entry: foo2 - 11
    **********
    Dumping member 1
    Action entry: foo1 - c9
    **********
    Dumping member 2
    Action entry: foo2 - ca
    **********
    Dumping member 3
    Action entry: foo1 - 6d
    ==========
    GROUPS
    **********
    Dumping group 0
    Members: [1, 2, 3]
    ==========
    Dumping default entry
    EMPTY
    ==========


As I send in packets that differ only in the IPv4 destination address,
with the least significant bits ranging from 0 up to 11, the member
number chosen in group 0 goes from 1, then 2, then 3, then repeats in
that pattern.  This is consistent with the member chosen being
something like `(hash % number_of_members_in_group)`.

    >>> sendp(Ether() / IP(dst='10.1.0.0') / TCP(sport=444,dport=5793), iface='veth2')
    [06:59:04.537] [bmv2] [D] [thread 18675] [5.0] [cxt 0] Choosing member 1 from group 0
    >>> sendp(Ether() / IP(dst='10.1.0.1') / TCP(sport=444,dport=5793), iface='veth2')
    [06:59:51.257] [bmv2] [D] [thread 18675] [6.0] [cxt 0] Choosing member 2 from group 0
    >>> sendp(Ether() / IP(dst='10.1.0.2') / TCP(sport=444,dport=5793), iface='veth2')
    [07:00:14.728] [bmv2] [D] [thread 18675] [7.0] [cxt 0] Choosing member 3 from group 0
    >>> sendp(Ether() / IP(dst='10.1.0.3') / TCP(sport=444,dport=5793), iface='veth2')
    [07:00:47.096] [bmv2] [D] [thread 18675] [8.0] [cxt 0] Choosing member 1 from group 0
    >>> sendp(Ether() / IP(dst='10.1.0.4') / TCP(sport=444,dport=5793), iface='veth2')
    [07:01:04.837] [bmv2] [D] [thread 18675] [9.0] [cxt 0] Choosing member 2 from group 0
    >>> sendp(Ether() / IP(dst='10.1.0.5') / TCP(sport=444,dport=5793), iface='veth2')
    [07:01:24.601] [bmv2] [D] [thread 18675] [10.0] [cxt 0] Choosing member 3 from group 0
    >>> sendp(Ether() / IP(dst='10.1.0.6') / TCP(sport=444,dport=5793), iface='veth2')
    [07:01:43.996] [bmv2] [D] [thread 18675] [11.0] [cxt 0] Choosing member 1 from group 0
    >>> sendp(Ether() / IP(dst='10.1.0.7') / TCP(sport=444,dport=5793), iface='veth2')
    [07:02:04.077] [bmv2] [D] [thread 18675] [12.0] [cxt 0] Choosing member 2 from group 0
    >>> sendp(Ether() / IP(dst='10.1.0.8') / TCP(sport=444,dport=5793), iface='veth2')
    [07:02:22.921] [bmv2] [D] [thread 18675] [13.0] [cxt 0] Choosing member 3 from group 0
    >>> sendp(Ether() / IP(dst='10.1.0.9') / TCP(sport=444,dport=5793), iface='veth2')
    [07:02:38.740] [bmv2] [D] [thread 18675] [14.0] [cxt 0] Choosing member 1 from group 0
    >>> sendp(Ether() / IP(dst='10.1.0.10') / TCP(sport=444,dport=5793), iface='veth2')
    [07:02:55.405] [bmv2] [D] [thread 18675] [15.0] [cxt 0] Choosing member 2 from group 0
    >>> sendp(Ether() / IP(dst='10.1.0.11') / TCP(sport=444,dport=5793), iface='veth2')
    [07:03:15.038] [bmv2] [D] [thread 18675] [16.0] [cxt 0] Choosing member 3 from group 0

Below is output from the test named
`test_action_selector_traffic_distribution` in the test script
`action-profile-tests.py`.  It tests sending the same sequence of 15
IPv4 packets, with IPv4 dest addresses ranging from 192.168.0.0 to
192.168.0.14, varying only in the least significant bits, to the
program `action-profile.p4` after setting up one matching table entry
that points at a group of members.  The only difference between the 4
sets of results below is which actions are currently in that group.

Below the raw data is a table that formats the results in a more
readable way.

```
{0: {'dst_addr_to_member': OrderedDict([('192.168.0.0', 0), ('192.168.0.1', 1), ('192.168.0.2', 2), ('192.168.0.3', 0), ('192.168.0.4', 1), ('192.168.0.5', 2), ('192.168.0.6', 0), ('192.168.0.7', 1), ('192.168.0.8', 2), ('192.168.0.9', 0), ('192.168.0.10', 1), ('192.168.0.11', 2), ('192.168.0.12', 0), ('192.168.0.13', 1), ('192.168.0.14', 2)]),
     'member_list': [0, 1, 2]},
 1: {'dst_addr_to_member': OrderedDict([('192.168.0.0', 0), ('192.168.0.1', 1), ('192.168.0.2', 2), ('192.168.0.3', 3), ('192.168.0.4', 0), ('192.168.0.5', 1), ('192.168.0.6', 2), ('192.168.0.7', 3), ('192.168.0.8', 0), ('192.168.0.9', 1), ('192.168.0.10', 2), ('192.168.0.11', 3), ('192.168.0.12', 0), ('192.168.0.13', 1), ('192.168.0.14', 2)]),
     'member_list': [0, 1, 2, 3]},
 2: {'dst_addr_to_member': OrderedDict([('192.168.0.0', 0), ('192.168.0.1', 1), ('192.168.0.2', 2), ('192.168.0.3', 3), ('192.168.0.4', 4), ('192.168.0.5', 0), ('192.168.0.6', 1), ('192.168.0.7', 2), ('192.168.0.8', 3), ('192.168.0.9', 4), ('192.168.0.10', 0), ('192.168.0.11', 1), ('192.168.0.12', 2), ('192.168.0.13', 3), ('192.168.0.14', 4)]),
     'member_list': [0, 1, 2, 3, 4]},
 3: {'dst_addr_to_member': OrderedDict([('192.168.0.0', 0), ('192.168.0.1', 2), ('192.168.0.2', 4), ('192.168.0.3', 0), ('192.168.0.4', 2), ('192.168.0.5', 4), ('192.168.0.6', 0), ('192.168.0.7', 2), ('192.168.0.8', 4), ('192.168.0.9', 0), ('192.168.0.10', 2), ('192.168.0.11', 4), ('192.168.0.12', 0), ('192.168.0.13', 2), ('192.168.0.14', 4)]),
     'member_list': [0, 2, 4]}}
```

Here are the 4 different lists of members in the group that were
configured before sending the 15 packets:

| group number | list of group members |
| ------------ | --------------------- |
| 1            | 0, 1, 2               |
| 2            | 0, 1, 2, 3            |
| 3            | 0, 1, 2, 3, 4         |
| 4            | 0, 2, 4               |

The table below shows, for each (group config, input packet
destination IPv4 address) combination, which of the group members was
selected while executing `t2.apply()`.  This was straightforward to
determine from the output packet, because each member action had a
different action parameter value, and the action wrote that action
parameter value into the IPv4 source address of the output packet.

| Dest IPv4    | group | group | group | group |
| address      | 1     | 2     | 3     | 4     |
| ------------ | ----- | ----- | ----- | ----- |
| 192.168.0.0  | 0     | 0     | 0     | 0     |
| 192.168.0.1  | 1     | 1     | 1     | 2     |
| 192.168.0.2  | 2     | 2     | 2     | 4     |
| 192.168.0.3  | 0     | 3     | 3     | 0     |
| 192.168.0.4  | 1     | 0     | 4     | 2     |
| 192.168.0.5  | 2     | 1     | 0     | 4     |
| 192.168.0.6  | 0     | 2     | 1     | 0     |
| 192.168.0.7  | 1     | 3     | 2     | 2     |
| 192.168.0.8  | 2     | 0     | 3     | 4     |
| 192.168.0.9  | 0     | 1     | 4     | 0     |
| 192.168.0.10 | 1     | 2     | 0     | 2     |
| 192.168.0.11 | 2     | 3     | 1     | 4     |
| 192.168.0.12 | 0     | 0     | 2     | 0     |
| 192.168.0.13 | 1     | 1     | 3     | 2     |
| 192.168.0.14 | 2     | 2     | 4     | 4     |
