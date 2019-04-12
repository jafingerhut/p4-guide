# Introduction

[`p414-multiple-resubmit-reasons.p4`](p414-multiple-resubmit-reasons.p4)
is a toy P4_14 program that has resubmit operations with four
different field lists, each intended to represent a different reason
to resubmit the packet and do more processing on it.  This program
uses resubmit as an example of this, but one could just as easily
write a P4_14 program with multiple recirculate or clone calls, each
with different field lists.

The point of the example is that while there can be some fields we
want to preserve in common for multiple cases of resubmitting the
packet, there is also likely to be unique metadata we want to preserve
in each of those cases.  While we could just preserve all metadata for
every resubmitted packet, that could be prohibitively expensive, and
preserve far more bits of data per resubmitted packet than is
necessary for correct operation.


[`v1model-multiple-resubmit-reasons-auto-xlated.p4`](v1model-multiple-resubmit-reasons-auto-xlated.p4) -
P4_16 + v1model program generated via the `p4test` command in the
script [`compile-cmd.sh`](compile-cmd.sh).  It uses `resubmit` calls
with lists of fields, that according to P4_16 language semantics
cannot behave in the same way as the original P4_14 program resubmit
oeprations can, because in P4_14 the value of metadata fields
preserved are those that they have at the end of executing the ingress
control, not the value those fields have at the time of the call to
`resubmit`.

[`v1model-multiple-resubmit-reasons-hand-edited.p4`](v1model-multiple-resubmit-reasons-hand-edited.p4) -
A slightly hand-edited version of the previous program, just to make
it slightly closer to something I might write by hand in P4_16.


[`v1model-multiple-resubmit-reasons-imagined.p4`](v1model-multiple-resubmit-reasons-imagined.p4) -
An edited version of the previous program, which imagines how one
might write a P4_16+modified_v1model program, one that behaves the
same as the original P4_14 program does.  Search for comments
containing "NEW" for the differences between this program and the
previous one.

[`v1model-multiple-resubmit-reasons-imagined-annotations.p4`](v1model-multiple-resubmit-reasons-imagined-annotations.p4)
- An edited version of the `-hand-edited.p4` program above, which
imagines how one might write a P4_16+modified_v1model program, one
that behaves the same as the original P4_14 program does.  Search for
comments containing "NEW" for the differences between this program and
the `-hand-edited.p4` one.
