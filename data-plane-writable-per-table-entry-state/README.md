Related links:

+ "Design syntax and semantics to indicate persistent storage of
  per-table-entry data across packets, modifiable in data plane"
  https://github.com/p4lang/p4-spec/issues/1177
+ Notes from some 2023-Mar meetings focused on this issue:
  https://docs.google.com/presentation/d/15vZJETWr0Cyht-dcQFnat28A3c9FoY7Z


The discussion of how to enable this feature in P4 programs has two
primary proposals:

+ Use a P4 extern definition, perhaps named `DirectRegister`
  + Short example programs:
    [`prog2.p4`](p2-multiple-directregisters-per-table/prog2.p4) and
    [`prog3.p4`](p3-local-directregisters-per-action/prog3.p4)
  + Advantages:
    + This requires no changes to the P4 language spec.  This is one
      of many examples of how externs are intended to be used.
  + Disadvantages:
    + The syntax is a little bit more verbose, e.g. per action, a call
      to `regname.read()` once near the beginning of the action body,
      and a call to `regname.write()` once near the end of the action
      body, for each regname that you want to access in that action.
    + Minor: There is not yet a proposed way to combine this with
      PNA's add-on-miss `add_entry()` extern function, but I suspect
      this is doable without a lot of trouble.
+ Modify the language spec, enabling some kinds of action parameters
  to be assigned values in action bodies.
  + Short example programs:
    [`prog1.p4`](p1-assignable-action-params/prog1.p4)
  + Two minor variations proposed:
    + Introduce a keyword before the action parameter such as `rmw` to
      explicitly indicate that it is writable in the action body.
    + No new keyword.  Simply allow P4 developers to assign values to
      action parameters that have no direction keyword, and that
      implies they are writable parameters.
  + Advantages:
    + More concise, and fairly natural-looking syntax for modifying
      these values: simply assign to them and they will be modified.
  + Disadvantages:
    + What if in the next year or two we discover significant
      drawbacks to this approach?  e.g. the control plane API issues
      we have not yet thought through in detail lead us to wish for
      further changes to the language definition?  Or different target
      vendors decide they would like to tweak the design because of
      implementation issues discovered one year from now?  Do we
      remove the feature?  Make significant and probably
      backwards-incompatible changes in its definition?  See also Note
      1 below.


Note 1: The best known response to this concern is: do not change the
language spec now, but instead one or more p4c developers create an
experimental implementation of the feature soon, and multiple vendors
use that to develop their full implementations of this feature,
including control plane APIs.  When there is some significant
implementation and field use experience with this feature by multiple
vendors, those vendors come back to the P4 language design work group
and propose to change the language spec at that time.


# prog1.p4

A "directionless action parameter" is a parameter of an action that
has no direction keyword before it, e.g. "in", "out", or "inout".

prog1.p4 uses an approach where a directionless action parameter can
represent one of two things:

+ Its currently defined in the P4 language spec, which is: the
  parameter value is read only in the data plane, and writable only
  by the control plane.
  + If a directionless action parameter is only "read" (i.e. used in
    expressions, such as `if` conditions or expressions on the right
    hand side of assignment statements), then this is the case.
+ The new proposed meaning of "writable in the data plane", with the
  parameter's new value stored in the table entry and accessible by
  the next packet to match that entry.
  + If a directionless action parameter is every assigned a value, or
    modified in any way (e.g. passed as a parameter to a
    function/extern-function/sub-action in a parameter that is `out`
    or `inout`), then this is the case.  Note: If you attempt to do
    this with the latest version of open source p4c as of today, you
    get a compile time error that you are not allowed to modify the
    value of the action parameter.

prog1.p4 does not use the `rmw` or any other keyword on writable
action parameters, nor any annotation.  It simply distinguishes
between the two cases above by whether there is an assignment to the
action parameter in the action's definition, or not.

Aside: If people strongly prefer that there be a distinctive keyword
like `rmw` on writable action parameters, that is understandable.  One
advantage of such a keyword is that it makes it explicitly declared by
the P4 developer that they _want_ the action parameter to be writable.
Also, someone reading the code can very quickly read this intent in
the parameter list of the action definition, without having to read
the entire action definition.  Note: Action definitions in
programmable NIC applications are likely to be longer, and contain
multiple cases using `if` statements, than many earlier P4 actions
commonly written.

Proposed control plane API extension:

+ When adding a new entry, the control plane must specify an initial
  value for all writable action parameters, just as it does for all
  action parameters that are read-only in the data plane.
+ When adding a new entry using PNA add_entry() extern function, the
  list of action parameter values provided should also include initial
  values for the writable action parameters.

In terms of read-write symmetry, obviously the writable action
parameters would be "data plane volatile", and thus need not preserve
their values last written by the control plane when they are next read
by the control plane.

I can imagine that some targets might provide, and some P4 developers
might wish for, a capability to write the value of a subset of the
read-only and/or writable action parameters, but not all of them.

Example: Maybe one writable action parameter is like a counter, and
the control plane sometimes wants to reset its value, but without
changing the value of some other writable action parameters in the
same table entry.  A different solution would be to write explicit P4
code so that specially marked packets injected by the control plane
can do different kinds of updates to the writable action parameters as
compared to normal data packets.


# prog2.p4

prog2.p4 uses the approach of defining a DirectRegister extern with
read and write method calls.  Unlike Tofino's implementation of a
similar DirectRegister extern, the example proposes that a single
table can be associated with multiple instances of this DirectRegister
extern, explicitly given in a table property for a table whose actions
access these externs.

This makes it fairly straightforward to enable the P4 developer to
access only one, or a few, of the DirectRegister instances associated
with the table.  For any instances associated with the table that it
does _not_ access, the back end need not allocate any storage in
entries using that action for those instances.

TODO: It would be good to propose a reasonable syntax for how a PNA
add_entry() call can provide the initial values for an entry that it
creates in the data plane.


# prog3.p4

prog3.p4 is nearly the same as prog2.p4.  The only difference is that
it uses a very minor proposed language extension of enabling instances
of extern objects to be declared locally within bodies of actions,
rather than at the top level within a control.

Mihai Budiu created a PR on open source p4c on 2023-Mar-24 that would
enable this here: https://github.com/p4lang/p4c/pull/3938

Like prog1.p4, this makes it easier for a P4 developer to quickly see
which modifiable data can be accessed by each action.  It also avoids
the need to declare a table property like `registers` in prog2.p4 that
declares which DirectRegister externs can be accessed by a table.  In
prog3.p4, it is implied by the action definitions themselves.
