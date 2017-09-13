# action_profile

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

    act_prof_create_member <action_profile_name> <action_name> [action parameters]
      => table_add T_member_id_to_action <action_name> <idx> => [action parameters]
         where <idx> is an arbitrary integer in the range [0, N-1]
         that is not already a key that has been added to table
         T_member_id_to_action.

    act_prof_delete_member <action_profile_name> <member handle>
      => table_delete T_member_id_to_action <entry handle>
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

    table_indirect_add T <match fields> => <member handle> [priority]
      => table_add T_key_to_member_id T_set_member_id <match fields> => <idx> [priority]
         where <idx> is the desired value of <idx> for the action
         profile member created via the previous command, when adding
         a table entry to table T_member_id_to_action.

    table_indirect_delete T <entry handle>
      => table_delete T_key_to_member_id <entry handle>
         where <entry handle> is the value assigned by simple_switch
         to the table T_key_to_member_id entry when it was
         added.

    act_prof_dump <action_profile_name>
      => table_dump T_member_id_to_action


# action_selector

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
