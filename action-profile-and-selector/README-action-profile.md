Having a table `T` with `implementation = action_profile(N)` in a
P4_16 program, like this:

```
    table T {
        key = { <keyElementList> }
        actions = { <actionList> }
        <other tableProperties here>
        implementation = action_profile(N);
    }

    // to apply the table:

    T.apply();
```

is functionally equivalent to having the following two tables.


```
    // X is the smallest integer such that 2^X >= N, so that it is
    // just large enough to represent an index into a table with N
    // entries.
    bit<X> T_profile_member_id;

    action T_set_profile_member_id (bit<X> profile_member_id) {
        T_profile_member_id = profile_member_id;
    }
    table T_key_to_profile_member_id {
        key = { <keyElementList> }
        actions = { T_set_profile_member_id; }
        <other tableProperties here>
    }
    table T_profile_member_id_to_action {
        key = {
	    T_profile_member_id : exact;
	}
        actions = { <actionList> }
        size = N;
    }

    // to apply the table:

    T_key_to_profile_member_id.apply();
    T_profile_member_id_to_action.apply();
```

In simple_switch_CLI, the following special commands for dealing with
tables that have an action profile implementation are implemented as
described.

    act_prof_create_member <action_profile_name> <action_name> [action parameters]
      => table_add T_profile_member_id_to_action <action_name> <idx> => [action parameters]
         where <idx> is an arbitrary integer in the range [0, N-1]
         that is not already a key that has been added to table
         T_profile_member_id_to_action.

    table_indirect_add T <match fields> => <member handle> [priority]
      => table_add T_key_to_profile_member_id T_set_profile_member_id <match fields> => <idx> [priority]
         where <idx> is the desired value of <idx> for the action
         profile member created via the previous command, when adding
         a table entry to table T_profile_member_id_to_action.

    act_prof_dump <action_profile_name>
      => table_dump T_profile_member_id_to_action
