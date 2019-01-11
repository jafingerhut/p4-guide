# Introduction

I am writing this in preparation for adding test cases, and correcting
any bugs I find, in the tool `p4pktgen`
(https://github.com/p4pktgen/p4pktgen), which is intended to correctly
model all possible behaviors of a P4 program, including when applying
tables.

The intent is to document cases that one might not think of at first
when considering all such possible behaviors, or even after thinking
about it a second or third time.  Please send questions or comments to
the author if you find anything missing, wrong, or confusing about
this.


## Versions

The P4_16 language specification quoted here is version 1.1.0,
published November, 2018.

The P4Runtime Specification version is 1.0.0-rc4, dated 2018-Nov-30.

The versions of the open source tools are the latest ones published to
Github as of 2019-Jan-09, which are these commits:

+ Version of https://github.com/p4lang/p4c

```
commit cfcdd7288c1a95f73eb1cdd9699b31681269465f
Author: Hemant Singh <32817427+hesingh@users.noreply.github.com>
Date:   Wed Jan 9 18:03:42 2019 -0500
```

+ Version of https://github.com/p4lang/behavioral-model

```
commit 20d37301040e6e1b2f6f50f4f66671448946b898
Author: Antonin Bas <antonin@barefootnetworks.com>
Date:   Tue Dec 18 11:47:36 2018 -0800
```


## Glossary

Several terms are introduced in this document and collected here for
reference.  Most are not used in any of the P4 specifications.  The
exception is "keyless table", which is present in the P4Runtime
Specification.

+ const default action table: A table whose definition includes a
  `const default_action = <action_spec>;` table property.
+ const entries table: A table whose definition includes a `const
  entries = ...` table property.
+ hit-only table: A table where an apply operation will always match
  an entry, and never experience a miss.
+ keyless table: A table with no `key` table property.  This term is
  actually used in the P4Runtime Specification.
+ miss-only table: A table where an apply operation will never match
  an entry, and always experience a miss.


## Behavior when a table is applied

As a brief reminder of the behavior of a P4 table when it is applied,
it is roughly as follows.  For simplicity, we restrict our attention
here to "direct tables", i.e. ones that do not have an action profile
or action selector implementation.

First, determine the set of table entries that match:

+ If the table is a keyless table (i.e. there is no `key` table
  property in the definition of the table), then there is no search
  key, there are never any entries installed in the table (see below),
  and the result is always a miss.  See below for "no matching
  entries" behavior.

+ If the table has a key, then compare the value of that key against
  all entries in the table, and determine which, if any, of those
  entries match.  This is a description of the resulting behavior --
  in many cases an implementation need not examine every table entry
  installed.  In general, there could be 0, 1, or multiple entries
  that match the key.

Next, based on the set of matching table entries, determine which
action to execute:

+ If there are no matching entries, then the table apply operation
  results in a miss.  Execute the default action currently configured
  for the table.  See below for further details.
+ If there are multiple matching entries (this is possible if there
  are key fields with a `match_kind` of `lpm`, `ternary`, or `range`),
  determine the one that has the highest priority among all matching
  entries.
  + If there are multiple matching entries with the same priority, the
    P4 specifications explicitly state that which entry is considered
    the "winner" is not mandated, i.e. it could differ from one
    implementation to another, or even from one table apply to another
    on the same implementation.  See the P4Runtime Specification,
    Section 9.1 "TableEntry".
+ The apply operation results in a hit.  Execute the action associated
  with the only, or highest priority, matching entry.

In Section 9.1 "TableEntry" of the P4Runtime Specification, it says:

    "In the case of a keyless table (the table has an empty match
    key), the server must reject all attempts to INSERT a match entry
    and return an INVALID_ARGUMENT error."

If in the P4_16 program, the table was applied in this way:

```
    if (table_name.apply().hit) {
        // code here to execute if table experienced a hit
    } else {
        // code here to execute if table experienced a miss
    }
```

then the _only_ thing that affects which branch is executed is whether
the table experienced a hit or a miss.  Which action was executed does
not affect that branch decision at all.  There can be a table where
the same action is executed for some or all of the table entries, as
for the default action executed on a miss.

If in the P4_16 program, the table was applied in this way:

```
    switch (table_name.apply().action_run) {
        action_name1: {
            // code here to execute if table executed action_name1
        }
        action_name2: {
            // code here to execute if table executed action_name2
        }
        default: {
            // Code here to execute if table executed any of the
            // actions not explicitly mentioned in other cases.
        }
    }
```

then the _only_ thing that affects which branch is executed is which
action name the table caused to execute, regardless of whether it
experienced a hit or a miss.  In particular, the label `default` has
_nothing_ to do with whether the default action was executed.  The
`default` label in the `switch` statement simply means "execute this
switch branch if any action was executed by the table that is not
explicitly named by other branches of the switch statement".


## Control plane modifications of table behaviors at run time

There are two kinds of modifications that control plane software can
make to the contents of a table at run time:

+ Add, remove, or modify table entries, each entry with its own key,
  action name, and action parameters.
+ Modify the action name and action parameters that are the default
  action of the table.

For a table like `t1` below, both of these kinds of run time
modifications are possible:

```
    table t1 {
        key = {
            hdr.ethernet.srcAddr : ternary;
        }
        actions = {
            a1;
            a2;
        }
	size = 16;
        default_action = a2();
    }
```

It is possible to define tables where one or both kinds of
modifications _cannot_ be made to a table at run time.


### When the default action of a table can be modified

If the `default_action` is defined with a `const` modifier, as for
table `t1_const_default_action` below, then the control plane is _not_
permitted to make any change to the default action of the table.  We
will call this a "const default action table".

```
    table t1_const_default_action {
        key = {
            hdr.ethernet.srcAddr : ternary;
        }
        actions = {
            a1;
            a2;
        }
	size = 16;
        const default_action = a2();
    }
```

If no explicit `default_action` is defined for a table, then it is as
if `default_action = NoAction;` was specified (see the section "Table
hit and miss" below for more details), and the control plane is
allowed to change the default action at run time.

The control plane is only allowed to modify the default action of a
table to become action `A` if:

+ action `A` is in the `actions` list specified for the table, and
+ action `A` does _not_ have the annotation `@tableonly` in that
  table's `actions` list.

Actions with a `@tableonly` annotation are only allowed to be used as
the action of a table entry for that table.


### When the entries of a table can be modified

There are at least two cases where the entries of a table cannot be
modified by the control plane software.

+ When the table has constant entries specified via `const entries = {
  ... }`.  We will call this a "const entries table".
+ When the table has no `key` specified.  We will call this a "keyless
  table".

TBD: It is not clear to me whether it is intended to have a table that
does not have either of the above properties, but has `size = 0;`, and
thus cannot have any table entries added.

In one sense, a keyless table _is_ a const entries table, because the
control plane is not allowed to add any entries to such a table, so it
always has the empty set of entries (i.e. always 0 entries).  In this
document we will consider keyless tables as one kind of const entries
table.  However, `p4c` considers it a syntax error if you write `const
entries = { }` for any table, whether it is keyless, or it has a
non-empty key.

The control plane is only allowed to associate an action `A` with an
entry in a table if:

+ action `A` is in the `actions` list specified for the table, and
+ action `A` does _not_ have the annotation `@defaultonly` in that
  table's `actions` list.

Actions with a `@defaultonly` annotation are only allowed to be used
as the default action of a table.


## Table hit and miss

Most P4 tables can either experience a hit or a miss when they are
applied.

For example, if either or both of tables `t1` and `t2` below are part
of a P4 program that is loaded into a P4-programmable device, they
should initially have 0 table entries installed.  In that state, any
apply operation on those tables, with any value for the search key,
will result in a miss.  When a miss occurs, the default action will be
executed.

For table `t1`, the source code specifies that at least initially when
the P4 program is loaded into the device, the default action should be
`a2`. The control plane software can later send a configuration
command to change the default action of `t1` to something else,
e.g. action `a1`.

```
    table t1 {
        key = {
            hdr.ethernet.srcAddr : ternary;
        }
        actions = {
            a1;
            a2;
        }
	size = 16;
        default_action = a2();
    }
```

For table `t2`, the source code does not explicitly specify what the
initial default action should be.  For such tables, the P4_16 language
specification says:

    If a table does not specify the `default_action` property and no
    entry matches a given packet, then the table does not affect the
    packet and processing continues according to the imperative
    control flow of the program. [Section 13.2.1.3 "Default action"]

The mechanism by which the `p4c` compiler implements this behavior is
as follows:

+ If the `actions` list contains the no-op action `NoAction`, then
  `NoAction` is kept in the `actions` list as specified, including any
  user-specified annotations, and the table is compiled as if it
  contained `default_action = NoAction;`.
+ If the `actions` list does not contain `NoAction`, then `NoAction`
  is added to the user-specified `actions` list with the annotation
  `@defaultonly`, and the table is compiled as if it contained that
  addition, plus `default_action = NoAction;`.

In either case, the control plane software is allowed to change the
default action of the table later (to any action in the user-specified
`actions` list that does not have a `@tableonly` annotation).

```
    table t2 {
        key = {
            hdr.ethernet.srcAddr : ternary;
        }
        actions = {
            a1;
        }
	size = 16;
    }
```


## Some observations

All keyless tables are effectively also const entries tables.  The
`p4c` compiler gives a syntax error if you attempt to write `const
entries = { }` with an empty list of entries, but that is effectively
what a keyless table is -- a table with const entries, and an empty
list of entries.

All keyless tables are miss-only tables.  They cannot have any entries
added to them, so they cannot ever experience a hit.

Some tables can be statically determined at compile time to be
hit-only, miss-only, or neither (i.e. sometimes hit, sometimes miss).

+ A keyless table is the only kind of table that can be statically
  determined to always be miss-only, because `p4c` does not allow
  `const entries = { }` with an empty list of entries.

+ A const entries table with a non-empty key must have at least one
  table entry, and every table entry must be able to match at least
  one value of the search key.  Thus they cannot be miss-only tables.
  Depending upon the contents of their const entries, it is possible
  to create a const entries table that is hit-only, if the union of
  all table entries matches all possible search key values.

In P4, whether a table has const entries, or a const default action,
are completely independent properties of the table.  All of these
kinds of tables can be created:

+ const entries and const default action
+ const entries and run-time configurable default action
+ run-time configurable entries, and const default action
+ run-time configurable entries, and run-time configurable default action

For a table with run-time configurable entries, for each specific set
of entries installed into it, it will either be hit-only, miss-only,
or neither.  Which of those cases it falls into could potentially
change over time.  All tables with run-time configurable entries are
miss-only when the P4 program is first loaded, since there are no
entries configured.  For some tables, it is not possible to add
entries such that they are hit-only, e.g. a table with an exact match
key with 48 bits, and only a maximum of 1024 entries at a time, cannot
possibly match on all 2^48 possible values of the search key at one
time.


## Possibly useful warnings about odd P4 program table definitions

+ A const default action table with more than one action in its action
  list with a `@defaultonly` annotation would be suspicious, since the
  control plane is not allowed to change the default action at run
  time to anything other than the default action specified in the
  source code.

Always printing an informational note that a table was found
statically, at compile time, to be hit-only or miss-only, would in
some cases be useful to a P4 developer in discovering bugs in their
code.  Perhaps such informational notes should _not_ be given for
keyless tables, since those being miss-only is perhaps more commonly
understood.

+ A hit-only table with _any_ actions annotated as `@defaultonly`
  would be somewhat odd, since such an action could never be executed
  when applying that table.

+ Conversely, a miss-only table with _any_ actions annotated as
  `@tableonly` would be odd, since such an action could never be
  executed when applying that table.  In particular, a keyless table
  is a miss-only table, ans should be warned about if it has actions
  annotated `@tableonly`.

Any table invoked as `if (table_name.apply().hit) ...` that was
hit-only or miss-only would imply a code path that was dead,
i.e. could never be executed.  That would be worth warning the
developer about.

Similarly, any table invoked as `switch
(table_name.apply().action_run) ...` where a case of the `switch`
statement was found to be impossible to execute would be worth warning
about.


## How these table properties are represented in various files

One quick note: the `@defaultonly` and `@tableonly` annotations are
not represented at all in the BMv2 JSON files produced by `p4c`, and
used by `simple_switch`.  They _are_ represented in the P4Info files
created by a `p4c` command with options like the following:


```bash
% p4c --p4runtime-format text --p4runtime-file foo.p4info.txt foo.p4
```

or for the JSON format:

```bash
% p4c --p4runtime-format json --p4runtime-file foo.p4info.json foo.p4
```

See the key "scope", which can have one of the values "DEFAULT_ONLY",
"TABLE_ONLY", or "TABLE_AND_DEFAULT".  If the key is not present, its
default value is "TABLE_AND_DEFAULT", meaning that the action can be
used for an entry, and it is also allowed to be configured as a
default action.

The BMv2 JSON file contains sufficient information for all of the
other table properties discussed here:

+ const default action tables have a "default_entry" key whose value
  is a nested JSON object with keys "action_const" and
  "action_entry_const" that both have the value `true`.  If the
  default action is not declared `const` in the P4_16 source code, the
  value of those two keys is `false`.
+ const entries tables have a key "entries" containing the list of
  entries for the table.
+ All key fields are represented explicitly, and the list of keys is
  empty for keyless tables.  Note that despite my observation that
  keyless tables are effectively const entries tables, keyless tables
  do not have an "entries" key in the BMv2 JSON file.

Whether a table is hit-only or miss-only can be derived from this
information in the BMv2 JSON file, but is not already determined and
recorded there.


## p4pktgen notes

### Tables that use `.hit` attribute

Consider a table like in the P4_16 code below, where there is later
code that executes conditionally, based on whether the table apply
operation experienced a hit or a miss.

```
    if (table_name.apply().hit) {
        // code here to execute if table experienced a hit
    } else {
        // code here to execute if table experienced a miss
    }
```

For tables that do not have const entries, I think that `p4pktgen`
should try to generate test cases that exercise all of these cases:

(a) table hit, once for each of the table actions that does not have a
    `@defaultonly` annotation.
(b) table miss, once for each of the table actions that does not have
    a `@tableonly` annotation.  If the table has a const default
    action, then only that one default action will be exercised.

While it is true that if there is more than one action that is
applicable for (a), that all of them would take the "then" branch of
the "if" statement, they would still exercise different cases in the
code because each action could have unique code that only it executes.
Similarly if there are multiple actions that are applicable for (b).

For tables that do have const entries, replace (a) with:

(c) table hit, once for each of the entries specified in the source
    program.  Each must be qualified with matching the specified
    entry, and _not_ matching any higher priority entries.  TBD: Are
    entries always specified from highest matching priority to lowest
    with 'const entries'?

For (b), every table miss case must be qualified with the condition
"does not match _any_ of the const entries of the table".


### Tables applied in P4 `switch` statement

Consider a table like in the P4_16 code below, where there is later
code that executes conditionally, based on which action was executed
by the table.

```
    switch (table_name.apply().action_run) {
        action_name1: {
            // code here to execute if table executed action_name1
        }
        action_name2: {
            // code here to execute if table executed action_name2
        }
        default: {
            // Code here to execute if table executed any of the
            // actions not explicitly mentioned in other cases.
        }
    }
```

I think that having `p4pktgen` exercise the same cases as mentioned in
the previous section is a good idea for such tables.  It is true that
this approach could cause some of the cases of the `switch` statement
to be executed once for a table hit, and again for a table miss, and
some people may be consider this to be redundant and unnecessary.  For
such people, perhaps there could be some options to prefer exercising
only hit cases, or only miss cases, if both are allowed by the
`@defaultonly` and `@tableonly` annotations on the table actions.
Another more fine-grained option, if it meets the requirements of the
P4 developer, is to add more `@defaultonly` and/or `@tableonly`
annotations on the table's actions, to reduce the number of test cases
generated to those actually expected to be used in the actual system.


### Other tables

If a table is applied without using the `hit` attribute, and not in a
`switch` statement, then it seems to make good sense to apply the same
approach as for the previous section: create test cases that exercise
all permitted actions on the hit path, and for all permitted actions
on the miss path.
