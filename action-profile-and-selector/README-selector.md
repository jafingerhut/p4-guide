Is it intentional to be able to add to a table with an implemention of
action_selector (table t2 in this example) an entry with that points
at a member directly, without going through a group?

    RuntimeCmd: act_prof_create_group action_profile_0
    Group has been created with handle 0
    
    RuntimeCmd: act_prof_create_member action_profile_0 foo2 17
    Member has been created with handle 0
    
    RuntimeCmd: act_prof_add_member_to_group action_profile_0 0 0
    
    RuntimeCmd: table_indirect_add_with_group t2 443 => 0
    Adding entry to indirect match table t2
    Entry has been added with handle 0
    
    RuntimeCmd: act_prof_create_member action_profile_0 foo1 88
    Member has been created with handle 1
    
    RuntimeCmd: table_indirect_add t2 501 => 1
    Adding entry to indirect match table t2
    Entry has been added with handle 1
    
    RuntimeCmd: table_dump t2
    ==========
    TABLE ENTRIES
    **********
    Dumping entry 0x0
    Match key:
    * tcp.srcPort         : EXACT     01bb
    Index: group(0)
    **********
    Dumping entry 0x1
    Match key:
    * tcp.srcPort         : EXACT     01f5
    Index: member(1)
    ==========
    MEMBERS
    **********
    Dumping member 0
    Action entry: foo2 - 11
    **********
    Dumping member 1
    Action entry: foo1 - 58
    ==========
    GROUPS
    **********
    Dumping group 0
    Members: [0]
    ==========
    Dumping default entry
    EMPTY
    ==========
