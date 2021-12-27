# Introduction

The program `v1model-special-ops.p4` in this directory is written
using the data plane API defined by the v1model architecture before it
was changed on 2021-Dec-06.  This method is now deprecated.

See the parent directory of this one for the currently-supported way
to do this.


# _Caveat emptor_

(_Caveat emptor_ is Latin for, roughly: "Let the buyer beware!")

If you do all of these things at the same time:

+ You use the open source tools `p4c` and `behavioral-model` as of
  December 5, 2021 or earlier
+ You write a program in the P4_16 variant of P4, with the v1model
  architecture, or you write a program in the P4_14 variant of P4.
+ You use any of the `recirculate`, `resubmit`, or clone operations
  (called `clone3` in P4_16, or `clone_ingress_pkt_to_egress` or
  `clone_egress_pkt_to_egress` in P4_14), with a non-empty list of
  metadata fields whose values you want to preserve with the
  recirculated, resubmitted, or cloned packet.

Then you may find that the metadata field values are _not_ preserved.
The current implementation for preserving such metadata field values
is very fragile, and effectively it sometimes works by accident, not
by design.

When it does not work, the symptom is that one or more of the metadata
field values you expect to be preserved instead have their default
initial value when the post-recirculated/resubmitted/cloned packet is
next processed.  The default initial value for such metadata fields is
most often 0 in `simple_switch`.

Aside: It is possible to investigate the BMv2 JSON file created by the
`p4c` compiler manually (it is just a specially formatted text file),
in particular the value of the `"field_lists"` key, to see whether the
compiler has generated them in a way that will cause this undesired
behavior.  One sure sign of a problem is that one or more of the
fields have constant values in the field list in that file, rather
than a named field.  Another sign of a problem is if the compiler has
generated a temporary variable, copied the value of your field into
it, and used that temporary variable in the field list.  All of these
problems can be checked for using the program
[`bmv2-json-check.py`](https://github.com/p4pktgen/p4pktgen/blob/master/tools/bmv2-json-check.py).
The check is perhaps not 100% reliable for the last problem mentioned,
but seems to work.

Even when the metadata field values are preserved, they will be the
values that those fields have when the current ingress or egress
control block is finished executing.  If any later code in that
control block modifies the values of the metadata fields after the
recirculate/resubmit/clone call, the modified value will be preserved.
That is the behavior specified in the P4_14 language specification for
these operations.  For P4_16, it violates language semantics for calls
to extern functions and methods, which should only have access to the
values of parameters at the time the call occurs.

One or both of the issues linked below will likely be updated, or link
to further issues or code changes, when these problems are resolved:

+ https://github.com/p4lang/p4c/issues/1514
+ https://github.com/p4lang/p4c/issues/1669


## The root causes of the issue

The first implementation of these operations was for the P4_14 variant
of the language.  In P4_14, the recirculate, resubmit, and clone
operations take a "field list" as a parameter.  A field list is a
named list of metadata field names.

The behavior in `simple_switch` is that when you invoke a recirculate,
resubmit, or clone operation, it does _not_ immediately make a copy of
the value of those fields.  Instead it remembers a numeric id that the
compiler generates to identify the named field list (see the
description of `recirculate_flag` `resubmit_flag` and `clone_spec`
standard metadata fields
[here](https://github.com/p4lang/behavioral-model/blob/master/docs/simple_switch.md)
if you want more details).

When the packet completes the current ingress or egress processing
control block, then _at that time_ `simple_switch` copies the values
of the metadata fields into some location associated with that packet.
When the resulting recirculated or resubmitted packet begins its next
ingress processing pass, or the resulting cloned packet begins its
next egress processing pass, those field values are restored from that
location and become the initial values of those metadata fields.

There are two aspects of this that cannot be represented in the P4_16
language: delayed effects, and references by name.

First, the time during packet processing when the values of the
packet's metadata fields are copied and saved, can be much later in
the sequential flow of program execution than the place where the
recirculate, resubmit, or clone operation occurs.  It is a delayed
effect.  The P4_16 language specification does not specify any
mechanisms by which one can write a statement A in a program, and then
after other statements B, C, D, etc. are executed, the effect of the
statement A occurs.  Certainly an optimizing P4_16 compiler can
reorder the execution, but the effect must be the same as if the
program were executed sequentially.  A P4_14 recirculate operation can
cause values to be saved for metadata fields that are assigned later
in the P4_14 program.

Second, a field list gives _names_ of fields, and those are used both
for where to copy their current values from, and where to copy those
saved values into, later.  This is similar to "call by name" in other
programming languages, and P4_16 provides no such mechanism.  P4_16
defines copy in and copy out semantics for all existing methods of
calling a control, function, or extern function or method.  Even
extern methods and functions are not allowed to keep references or
pointers, only values copied from the caller.

It is definitely possible in a P4_16 program to use a technique
similar to the `ssimple_switch` implementation, e.g. record a numeric
id in a well-known metadata field that identifies a list of fields one
wants to preserve for the packet, and then at some later part of the
program use the value of that metadata field to make copies of the
desired fields.  Such a technique seems likely to become part of the
solution of these issues for P4_16 programs, perhaps written
explicitly by the P4 programmer, rather than auto-generated by the
compiler as occurs now for P4_14 programs.
