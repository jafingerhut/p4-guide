# Introduction

The files in this directory were created to ask and hopefully answer
these questions:

Does the current P4Runtime API as of 2023-May-24 require that a
P4Runtime server return an error if you attempt to insert an entry in
a table whose key is equal to a key that is already in the table?


# If duplicate keys are allowed

If duplicate keys are allowed, what does that mean, precisely?  For
example, if you can install multiple identical keys in a table where
its key fields are all match kind `exact`, which of the two entries
should be matched by the data plane when a lookup key equal to both of
those installed entries is searched for?

Most significantly, P4Runtime API has no way to identify a table entry
_except_ the key, i.e. it has no notion of an "entry id" or "entry
handle".  Thus it would be very strange if it allowed duplicate keys.


# If duplicate keys are not allowed

If duplicate keys are not allowed:

Is this described in the current P4Runtime API specification?  It
seems like it should be documented somewhere.

What is the exact condition to determine if a newly inserted key is a
duplicate of an already-installed key?

For example, does it include the priority field of the TableEntry in
the equality comparison?  Or should it ignore the priority field?

I think when comparing keys, all `FieldMatch` sub-messages of the
`TableEntry` message should be compard to see if they are equal, and
two entries should only be considered equal if _all_ of their
corresponding `FieldMatch` sub-messages are equal.  Here by
"corresponding" I mean "have numerically equal `field_id` values in
the `FieldMatch` message.

In the below, the default value of all fields is assumed to be 0 if
the field is not present in the protobuf message.

[1] P4Runtime API specification, Section 9.1.1 "Match Format"

+ If exact, then the `value` fields are numerically equal.
+ If ternary, then either:
  + both `FieldMatch` messages contain a `Ternary` message for the
    field, and the `mask` and `value` fields are numerically equal
    between them.  Note the P4Runtime API spec requires `value & mask
    == 0` (see [1]).
  + both `FieldMatch` messages contain _no_ `Ternary` message for the
    field, in which case they are both complete wildcard match
    specifications, and are equal to each other.
+ If lpm, then either:
  + both `FieldMatch` messages contain a `LPM` message for the field,
    and the `prefix_len` and `value` fields are numerically equal.
    Note that P4Runtime API spec requires that any bits in the value
    after the `prefix_len` most significant bits must be 0 (see [1]).
  + both `FieldMatch` messages contain _no_ `LPM` message for the
    field, in which case they are both complete wildcard match
    specifications (i.e. prefix length 0), and are equal to each
    other.
+ If range, then either:
  + both `FieldMatch` messages contain a `Range` message for the
    field, and the `low` and `high` fields are numerically equal.
  + both `FieldMatch` messages contain _no_ `Range` message for the
    field, in which case they are both complete wildcard match
    specifications, and are equal to each other.
+ If optional, then either:
  + both `FieldMatch` messages contain an `Optional` message for the
    field, and the `value` fields are numerically equal.
  + both `FieldMatch` messages contain _no_ `Optional` message for the
    field, in which case they are both complete wildcard match
    specifications, and are equal to each other.
