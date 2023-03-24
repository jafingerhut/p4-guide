Related Github issues:

+ "Design syntax and semantics to indicate persistent storage of
  per-table-entry data across packets, modifiable in data plane"
  https://github.com/p4lang/p4-spec/issues/1177


prog1.p4 and prog2.p4 are two programs intended to be functionally
identical in their behavior, written with two different styles of
data-plane-modifiable per-table-entry data.


# prog1.p4

prog1.p4 uses the approach of a directionless action parameter can
represent one of two things:

+ its currently defined meaning as read only in the data plane,
  modifiable only by the control plane, if its value is only "read" in
  the body of the action.
+ the new proposed meaning of writable in the data plane, with its new
  value stored in the table entry, and accessible by the next packet
  to match that entry.

prog1.p4 does not use the 'rmw' or any other keyword on modifiable
action parameters, nor any annotation.  It simply distinguishes
between the two cases above by whether there is an assignment to the
action parameter in the action's definition, or not.

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
