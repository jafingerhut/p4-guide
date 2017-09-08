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

----------------------------------------------------------------------
scapy session for sending packets
----------------------------------------------------------------------

    sudo scapy

    pkt1=Ether() / IP(dst='10.1.0.1') / TCP(sport=5793, dport=80)
    pkt2=Ether() / IP(dst='192.168.3.4') / TCP(sport=5501, dport=80)

    # Send packet at layer2, specifying interface
    sendp(pkt1, iface="veth2")
    sendp(pkt2, iface="veth2")


# Behavior seen during simple_switch run with pkt1 and pkt2

Sending in pkt1 should cause control mod_headers1 to be called.

It will run its apply body.  Because its parameters are in the order
`inout headers hdr` first, followed by `inout ipv4_t ipv4`, the
copy-out of the parameter values will be done in that order.  Thus any
changes made to `hdr.ipv4.*` fields will be overwritten in the caller
when the `ipv4` parameter is copied out.

    Header field   pkt1       packet out
    ipv4.ttl       64         62           as expected from ipv4.ttl assignment
    ipv4.dstAddr   10.1.0.1   10.1.0.5     as expected from ipv4.dstAddr assignment
    tcp.srcPort    5793       5794         as expected from hdr.tcp.srcPort assignment


Sending in pkt2 should cause control mod_headers2 to be called.

It will run its apply body.  Because its parameters are in the order
`inout ipv4_t ipv4` first, followed by `inout headers hdr`, the
copy-out of the parameter values will be done in that order.  Thus any
changes made to `ipv4.*` fields will be overwritten in the caller when
the `hdr` parameter is copied out.

    Header field  pkt1        packet out
    ipv4.ttl      64          63           as expected from hdr.ipv4.ttl assignment
    ipv4.dstAddr  192.168.3.4 192.168.3.4  as expected, ipv4.dstAddr change in mod_headers2 was undone by copy-out of hdr.ipv4
    tcp.srcPort   5501        5502         as expected from hdr.tcp.srcPort assignment, which was not overwritten by copy-out of hdr.ipv4
