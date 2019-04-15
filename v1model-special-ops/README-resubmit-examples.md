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
operations can, because in P4_14 the value of metadata fields
preserved are those that they have at the end of executing the ingress
control, not the value those fields have at the time of the call to
`resubmit`.

[`v1model-multiple-resubmit-reasons-hand-edited.p4`](v1model-multiple-resubmit-reasons-hand-edited.p4) -
A slightly hand-edited version of the previous program, just to make
it slightly closer to something I might write by hand in P4_16.


## PARAMS - Preserve metadata via extra parser/control parameters

[`v1model-multiple-resubmit-reasons-params.p4`](v1model-multiple-resubmit-reasons-params.p4) (abbreviation: PARAMS)

An edited version of the `-hand-edited.p4` program above, which
imagines how one might write a P4_16+modified_v1model program, one
that behaves the same as the original P4_14 program does.  Search for
comments containing "NEW" for the differences between this program and
the previous one.

Advantages of PARAMS:

+ While the extra code for copying data to the new ingress out
  parameter and from the new parser in parameter is a bit tedious, it
  is very explicit in how it behaves.  There is no "magic" in the
  implementation to explain as there is for RESUBMIT_ANNOT or
  FIELD_LIST_ANNOT.

+ This solution supports preservation of arbitrary data, whether it is
  from user-defined metadata fields, standard_metadata fields, or
  packet header fields.  Also, it is possible to "restore" it after
  resubmit into a different place than it was copied from originally,
  if there is any advantage to you in doing so.

Disadvantages of RESUBMIT_ANNOT:

+ The explicit code for copying values into the new output parameter
  at the end of the ingress control, and to copy them from the new
  parser input parameter into the desired places at the beginning of
  the parser, is somewhat long and tedious to write.


## RESUBMIT_ANNOT - Preserve metadata via `@resubmit` annotation on user-defined metadata fields

[`v1model-multiple-resubmit-reasons-resubmit-annot.p4`](v1model-multiple-resubmit-reasons-resubmit-annot.p4) (abbreviation: RESUBMIT_ANNOT)

An edited version of the `-hand-edited.p4` program above, which
imagines how one might write a P4_16+modified_v1model program, one
that behaves the same as the original P4_14 program does.  Search for
comments containing "NEW" for the differences between this program and
the `-hand-edited.p4` one.

Advantages of RESUBMIT_ANNOT:

+ code is more concise than PARAMS, close to same length as FIELD_LIST_ANNOT

Disadvantages of RESUBMIT_ANNOT:

+ No way to preserve standard metadata fields.  Workaround: copy
  desired standard metadata fields to user-defined metadata fields and
  then preserve those instead.
+ Preserving user-defined metadata fields that are inside of nested
  structs can cause all instances of that field to be preserved, even
  if the developer only wants some of them to be preserved.  See
  example on this [Github
  comment](https://github.com/p4lang/p4c/pull/1698#issuecomment-457787709).
  I believe that this is not an issue for programs auto-translated
  from P4_14 to P4_16+v1model, since P4_14 programs cannot have
  structs nested inside of other structs.

Neither advantage nor disadvantage of RESUBMIT_ANNOT:

+ Not intended to preserve fields inside of headers.  This is not
  allowed for resubmit, recirculate, or clone operations in P4_14 (see
  the description of these operations in the P4_14 language
  specification, version 1.0.5), so no need to add support for it in
  P4_16+v1model.


## FIELD_LIST_ANNOT - Preserve metadata via `@field_list` annotation on user-defined metadata fields

[`v1model-multiple-resubmit-reasons-field-list-annot.p4`](v1model-multiple-resubmit-reasons-field-list-annot.p4) (abbreviation: FIELD_LIST_ANNOT)

Very similar to the previous program, except that it uses names
instead of integers to "mark" fields to be preserved.  This allows the
annotation to change from `@resubmit` to something more generic like
`@field_list`, which seems to be about as close as we could get in
P4_16 to having P4_14 field lists, without actually adding them to the
language, at least for the purposes of specifying user-defined
metadata fields to be preserved for resubmit, recirculate, and clone
operations.

Advantages of FIELD_LIST_ANNOT:

+ A single new annotation @field_list is enough to cover all of
  resubmit, recirculate, and clone operations.  Names can be used
  instead of integers for sets of fields to preserve, similar to
  P4_14, and unlike RESUBMIT_ANNOT.
+ Otherwise, same as idea RESUBMIT_ANNOT

Disadvantages of FIELD_LIST_ANNOT:

+ Same as idea RESUBMIT_ANNOT

Neither advantage nor disadvantage of RESUBMIT_ANNOT:

+ Same as idea RESUBMIT_ANNOT


## Which standard metadata fields would it make sense to allow preserving?

A quick answer is "none of them", but let us examine each field in
`standard_metadata` of the v1model.p4 include file as of 2019-Apr-14,
to see if it does make sense to preserve any of them.

I am leaving out `drop` and `recirculate_port`, since `simple_switch`
has never implemented those.

I am also leaving out the following fields, since they are being
considered for removal from v1model.p4's `standard_metadata` struct,
and instead becoming "hidden v1model architecture per-packet metadata"
that is not visible from a developer's P4 program:

+ `clone_spec`
+ `lf_field_list`
+ `resubmit_flag`
+ `recirculate_flag`

Below are some fields where it does not seem to make sense to me to
preserve the values, ever, and if a P4 program attempted to do so, it
seems like it should be an error:

+ `instance_type` - If you tried to preserve this field for a packet
  resubmitted for the first time, there would be one less way to
  distinguish a new packet from a resubmitted packet.  Similarly for
  recirculated packets.  The _intent_ of this field is to indicate
  which "packet path" the packet has recently traversed, so a user's
  program can do different things for each such path, if they wish.

+ `checksum_error` and `parser_error` - These are effectively
  "outputs" of the parser and verifyChecksum programmable blocks.  It
  seems very odd to me to want to preserve these values for
  recirculated or resubmitted packets.  Maybe it would be useful for
  an ingress-to-egress cloned packet.

+ `packet_length` - This is a property of the packet.  Preserving it
  would seem only to lead to possible mismatches between the actual
  packet length, and this field value.

+ `ingress_port` - v1model does not currently define what the value of
  this field will be except for new packets arriving to the parser and
  ingress controls.  Should it have a defined value for resubmitted or
  recirculated packets?  Should it be reasonable to preserve this
  field for resubmitted packets, if it is not always defined for
  resubmitted packets?  Should it also be defined for packets starting
  the egress control processing?

+ `egress_port` - v1model defines the value of this for packets
  beginning egress control processing.  Should it be considered a
  compiler error to access this field during parsing or ingress?
  Should it be considered a compiler error to modify this field?

+ `egress_rid` - Similar comments and questions as for `egress_port`.

For the fields below, it seems like there might be a use for
preserving in some cases:

+ `egress_spec`
+ `mcast_grp`

+ `ingress_global_timestamp` - Perhaps one wishes to remember the time
  when the packet first arrived, and not have this field overwritten
  when it is resubmitted or recirculated?

+ `egress_global_timestamp` - As for the previous field, perhaps one
  wishes to remember the time when the packet began egress processing
  the first time, even for recirculated or egress-to-egress cloned
  packets?

Similar comments and questions for all of the fields below as for
field `egress_port`:

+ `enq_timestamp`
+ `enq_qdepth`
+ `deq_timedelta`
+ `deq_qdepth`
