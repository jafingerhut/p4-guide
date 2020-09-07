# Implementing generalized P4_16 switch statements

Version 1.2.1 and earlier of the P4_16 language specification
restricts switch statements to have a switch expression of the form
`table_name.apply().action_run`.

This short article is intended to demonstrate a way that P4 compiler
writers can implement a generalized P4_16 switch statement in a way
that is as efficient as any techniques they have for implementing the
previously existing restricted P4_16 switch statements.

Consider the generalized switch statement in Partial Program 1, where
the switch expression has type `bit<16>`.

----------------------------------------------------------------------
Partial Program 1
----------------------------------------------------------------------
```
bit<16> x;

switch (x) {
   1: { /* body 1 here */ }
   2:
   3: { /* body 23 here */ }
   4: { /* body 4 here */ }
   default: { /* body D here */ }
}
```

Each of the switch case bodies in Partial Program 1 can be arbitrary
P4_16 code that can appear within a control, e.g. if-then-else's,
applying tables, nested switch statements, etc.

It is certainly possible for a target to implement Partial Program 1
in the same way that it would implement Partial Program 2.

----------------------------------------------------------------------
Partial Program 2
----------------------------------------------------------------------
```
if (x == 1) {
    /* body 1 here */
} else if ((x == 2) || (x == 3)) {
    /* body 23 here */
} else if (x == 4) {
    /* body 4 here */
} else {
    /* body D here */
}
```

However, some P4 compilers may be able to implement Partial Program 1
more efficiently by compiling it the same way they would compile
Partial Program 3.

Note that the table `switch1_table` is completely constant in all
ways, both in its table entries and in its default action.  It does
not have any need to be visible from the control plane software, and
would probably only confuse control plane software developers if it
did, since the table was not created by a human developer.  The
`@hidden` annotation in the P4_16 specification is used to indicate
this.

----------------------------------------------------------------------
Partial Program 3
----------------------------------------------------------------------
```
bit<16> x;

@hidden action switch1_case_1 () {
    // no statements here, by design
}
@hidden action switch1_case_23 () {
    // no statements here, by design
}
@hidden action switch1_case_4 () {
    // no statements here, by design
}
@hidden action switch1_case_default () {
    // no statements here, by design
}

@hidden table switch1_table {
    key = {
        x : exact;
    }
    actions = {
        switch1_case_1;
        switch1_case_23;
        switch1_case_4;
        switch1_case_default;
    }
    const entries = {
        1 : switch1_case_1;
        2 : switch1_case_23;
        3 : switch1_case_23;
        4 : switch1_case_4;
    }
    const default_action = switch1_case_default;
}

// later in the control's apply block, where the original switch
// statement appeared:

switch (switch1_table.apply().action_run) {
switch1_case_1:       { /* body 1 here */ }
switch1_case_23:      { /* body 23 here */ }
switch1_case_4:       { /* body 4 here */ }
switch1_case_default: { /* body D here */ }
}
```
----------------------------------------------------------------------

Some properties of the transformation:

+ It is very mechanical, with no complex decisions to make.
+ Exactly one new table is introduced per switch statement, and it
  only needs as many newly created actions as there are different
  branches in the original switch statement.  Every newly created
  action is a no-op action, i.e. no assignments or other code to run
  inside of it at all.
+ If Partial Program 3 can be compiled efficiently to a target, then
  the original switch statement in Partial Program 1 can be, too.
