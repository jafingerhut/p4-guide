# action_profile tables

Having a table `T` with `implementation = action_profile(N)` in a
P4_16 program, like this:

```
    table T {
        key = { <table T keyElementList> }
        actions = { <table T actionList> }
        <other tableProperties of table T here>
        implementation = action_profile(N);
    }

    // to apply the table:
    T.apply();
```

is functionally equivalent to the code below with two tables:


```
    // X is the smallest integer such that 2^X >= N, so that a bit<X>
    // value is just large enough to represent an index into a table
    // with N entries.
    bit<X> T_member_id;

    action T_set_member_id (bit<X> member_id) {
        T_member_id = member_id;
    }
    table T_key_to_member_id {
        key = { <table T keyElementList> }
        actions = { T_set_member_id; }
        <other tableProperties of table T here>
    }
    table T_member_id_to_action {
        key = { T_member_id : exact; }
        actions = { <table T actionList> }
        size = N;
    }

    // to apply the table:
    T_key_to_member_id.apply();
    T_member_id_to_action.apply();
```

In simple_switch_CLI, the following special commands for dealing with
tables that have an action profile implementation are implemented as
described.

    Original simple_switch_CLI command:
    act_prof_create_member <action_profile_name> <action_name> [action parameters]
    Implemented as:
    table_add T_member_id_to_action <action_name> <idx> => [action parameters]
         where <idx> is an arbitrary integer in the range [0, N-1]
         that is not currently a key that has been added to table
         T_member_id_to_action.

    Original simple_switch_CLI command:
    act_prof_delete_member <action_profile_name> <member handle>

    Implemented as:
    table_delete T_member_id_to_action <entry handle>
         where <entry handle> is the value assigned by simple_switch
         to the table T_member_id_to_action entry when it was
         added.

         It is an error to attempt to do this when there are one or
         more entries in table T_key_to_member_id that set this
         entry's member_id.

    Original simple_switch_CLI command:
    act_prof_modify_member <action profile name> <action_name> <member_handle> [action parameters]

    Implemented as:
    table_modify T_member_id_to_action <action name> <entry handle> [action parameters]
         where <entry handle> is the value assigned by simple_switch
         to the table T_member_id_to_action entry when it was
         added.

simple_switch and simple_switch_CLI already contain a consistency
check that gives an error, and does not remove an action profile
member, if there is still at least one table entry that uses it.  If
implemented as 2 separate tables, it would be good to have a similar
consistency check in the control software to prevent removing an entry
from T_member_id_to_action if its `<idx>` value is still one of the
possible values set by an entry of T_key_to_member_id.

Similarly it would be good to disallow adding an entry to
T_key_to_member_id that uses a particular value of `<idx>`, unless
T_member_id_to_action currently has an entry for key `<idx>`.
simple_switch gives error INVALID_MBR_HANDLE if you attempt to do
this.

    Original simple_switch_CLI command:
    table_indirect_add T <match fields> => <member handle> [priority]

    Implemented as:
    table_add T_key_to_member_id T_set_member_id <match fields> => <idx> [priority]
         where <idx> is the desired value of <idx> for the action
         profile member created via the "table_add
         T_member_id_to_action ..." command above.

         It is an error to attempt this command for an <idx> value
         that does not correspond to any current member.

    Original simple_switch_CLI command:
    table_indirect_delete T <entry handle>

    Implemented as:
    table_delete T_key_to_member_id <entry handle>
         where <entry handle> is the value assigned by simple_switch
         for the entry added to the table T_key_to_member_id.

    Original simple_switch_CLI command:
    act_prof_dump <action_profile_name>

    Implemented as:
    table_dump T_member_id_to_action


# action_selector tables

Having a table `T` with `implementation =
action_selector(HashAlgorithm.H, N, W)` in a P4_16 program, like this:

```
    table T {
        key = {
            // <table T selectorKeyElementList> contains all fields of
            // the table key that have a match_kind 'selector', and
            // the next line contains all the rest of the fields.
            <table T nonSelectorKeyElementList>;
            <table T selectorKeyElementList>;
        }
        actions = { <table T actionList> }
        <other tableProperties of table T here>
        implementation = action_selector(HashAlgorithm.H, N, W);
    }

    // to apply the table:
    T.apply();
```

is functionally equivalent to the code below with three tables:

```
    // X is the smallest integer such that 2^X >= N, so that a bit<X>
    // value is just large enough to represent an index into a table
    // with N entries.
    bit<X> T_group_id;
    bit<X> T_group_size;    // See Note 1 below
    bit<X> T_member_id;
    bit<W> T_member_of_group;

    action T_set_group_id_and_size (bit<X> group_id,
                                    bit<X> group_size)
    {
        T_group_id = group_id;
        T_group_size = group_size;
    }
    action T_set_member_id (bit<X> member_id) {
        T_member_id = member_id;
    }
    table T_key_to_group_or_member_id {
        key = { <table T nonSelectorKeyElementList> }
        actions = {
            T_set_group_id_and_size;
            T_set_member_id;    // See Note 2 below
        }
        <other tableProperties of table T here>
    }
    table T_group_to_member_id {
        key = {
            T_group_id        : exact;
            T_member_of_group : exact;
        }
        actions = { T_set_member_id; }
        size = N;    // See Note 3 below
    }
    table T_member_id_to_action {
        key = { T_member_id : exact; }
        actions = { <table T actionList> }
        size = N;
    }

    // to apply the table:
    switch (T_key_to_group_or_member_id.apply().action_run) {
        T_set_group_id_and_size: {
            // See Notes 4 and 5 below
            bit<W> T_selector_hash;
            T_selector_hash = (least significant W bits of the output
               of HashAlgorithm.H, when given the fields in
               <table T selectorKeyElementList> as input);
            T_member_of_group = T_selector_hash % T_group_size;
            T_group_to_member_id.apply();
        }
    }
    T_member_id_to_action.apply();
```

Note 1: TBD: Should T_group_size be X bits wide?  It needs to be able
to represent any integer value in the range [1, M], where M is the
maximum number of elements allowed in a group.  The minimum value of 1
assumes that the control plane does not permit making a table entry
'point at' a group id unless that group id contains at least 1 member,
and that while the group id is 'pointed at' by at least one table
entry, the control plane will not be allowed to remove its last
member.  If the plan is that M can be as large as N, one way to always
represent a value S in the range [1, N] is to store the value (S-1),
adding 1 to the value before using it elsewhere.

Note 2: With the current p4c and behavioral-model code as of
2017-Sep-01, P4_14 action profiles with dynamic selectors, and P4_16
tables with implementation action_selector(), are both allowed to have
a table entry 'point at' a member directly, without going through a
group.  This is by design.  See this issue for an example and
discussion: https://github.com/p4lang/behavioral-model/issues/438

Note 3: TBD: What should the size of table T_group_to_member_id be?
The same value N as for table T_member_id_to_action?

Note 4: TBD: Does the code below correctly represent how
HashAlgorithm.H and W are intended to be used?

Note 5: TBD: Are there any other ways intended to be implemented for
calculating 'T_member_of_group' other than as a deterministic function
of values of the fields of T's key with match_kind 'selector'?


# simple_switch_CLI commands specific to action_profile and action_selector tables

Below is a list of all simple_switch_CLI commands that have behavior
specific to tables with implementation `action_profile()` or
`action_selector()`:

```
act_prof_add_member_to_group
act_prof_create_group
act_prof_create_member
act_prof_delete_group
act_prof_delete_member
act_prof_dump
act_prof_dump_group
act_prof_dump_member
act_prof_modify_member
act_prof_remove_member_from_group
table_dump_group (deprecated - use act_prof_dump_group)
table_dump_member (deprecated - use act_prof_dump_member)
table_indirect_add
table_indirect_add_member_to_group (deprecated - use act_prof_add_member_to_group)
table_indirect_add_with_group
table_indirect_create_group (deprecated - use act_prof_create_group)
table_indirect_create_member (deprecated - use act_prof_create_member)
table_indirect_delete
table_indirect_delete_group (deprecated - use act_prof_delete_group)
table_indirect_delete_member (deprecated - use act_prof_delete_member)
table_indirect_modify_member (deprecated - use act_prof_modify_member)
table_indirect_remove_member_from_group (deprecated - use act_prof_remove_member_from_group)
table_indirect_set_default
table_indirect_set_default_with_group
```

Below is the same list of commands, with the deprecated ones removed,
and arranged in groups with related effects.

The commands marked "S" are only applicable for a table with
implementation `action_selector()`.  The others are applicable for
both `action_profile()` and `action_selector()` tables.

```
  # Commands to manipulate entries in the 'main table', i.e. the one
  # that maps the user-specified search key fields to a member, or to
  # a group.  It appears that perhaps simple_switch_CLI does not
  # support any method of modifying an existing main table entry,
  # i.e. there is no analog to the 'table_modify' command that exists
  # for normal/simple tables.
  table_indirect_add
S table_indirect_add_with_group
  table_indirect_delete
  table_indirect_set_default
S table_indirect_set_default_with_group

  # Commands to create and delete groups.  Groups always have 0
  # members when first created.
S act_prof_create_group
S act_prof_delete_group

  # Commands to add members to, or remove members from, an existing
  # group.  These are the only supported ways to modify a group.
S act_prof_add_member_to_group
S act_prof_remove_member_from_group

  # Commands to create, delete, and modify members.  Each member has
  # its own independent action and action parameter values, which can
  # be chosen from the user-defined `actions` list of the table.
  act_prof_create_member
  act_prof_delete_member
  act_prof_modify_member

  # Show/dump commands for debugging.  They have no effect on the
  # state of the system.
S act_prof_dump_group
  act_prof_dump_member
  act_prof_dump
```
