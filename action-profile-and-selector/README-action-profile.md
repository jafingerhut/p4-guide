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
possible values set by an entry of T_key_to_member_id.  One way to
implement this is to maintain a reference count for each member.

Similarly one should disallow adding an entry to T_key_to_member_id
that uses a particular value of `<idx>`, unless T_member_id_to_action
currently has an entry for key `<idx>`.  simple_switch gives error
INVALID_MBR_HANDLE if you attempt to do this.  If this is done, then
no miss will ever occur on searches of table T_member_id_to_action,
and no default action is needed.

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
