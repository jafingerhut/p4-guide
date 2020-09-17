These are a few notes on ideas for formal verification of P4_16
programs.


# Reading fields of a header

Example programs with perhaps surprising possible behaviors, according
to the language specification.

```
    hdr.ethernet.setValid();
    hdr.ethernet.dstAddress = 1;
    if (hdr.tcp.srcPort == hdr.tcp.srcPort) {
        hdr.ethernet.dstAddress = 2;
    }
```

If `hdr.tcp.isValid()` is true before executing the code above, then
there is only one possible final value for `hdr.ethernet.dstAddress`,
which is 2.

If `hdr.tcp.isValid()` is false before executing the code above, then
there are two possible final values for `hdr.ethernet.dstAddress`: 1
or 2.

Why is 1 possible, you might reasonably ask?  Because according to the
language specification, every separate read of a field in an invalid
header evaluates to an unspecified value of the appropriate type, and
that value can change from one evaluation of the field to the next.
Thus it is possible that the two separate reads might return different
values of type `bit<16>`, and the `if` condition would then evaluate
to false.  The two reads might also just happen to return the same
value, and then the condition would evaluate to true.

I believe that the following transformations of a P4_16 program are
correct.  I would not necessarily recommend these for use in a P4_16
compiler, but they may be useful for a P4 verification tool.

All reads of a header field with type `bit<16>`,
e.g. `hdr.tcp.srcPort` which is type `bit<16>`, can be replaced with
the following expression without changing the possible set of
behaviors of the program:

```
(hdr.tcp.isValid() ? hdr.tcp.srcPort : fresh_input_bit_16_value_number_1)
```

where `fresh_input_bit_16_value_number_1` is a type `bit<16>` value
that one can consider as an input to the P4 control or parser where
`hdr.tcp.srcPort` is read in an expression.  This new input value has
some unknown value that is completely independent of the contents of
the packet.

Every read of the same field `hdr.tcp.srcPort` can be replaced with an
expression like the above, each read with its own
`fresh_input_bit_16_value_number_<NNN>` input value, each of them with
a value that is independent of the others.  The values can be equal to
each other, or different.

Thus this code:
```
    hdr.ethernet.setValid();
    hdr.tcp.setInvalid();
    hdr.ethernet.dstAddress = 1;
    if (hdr.tcp.srcPort == hdr.tcp.srcPort) {
        hdr.ethernet.dstAddress = 2;
    }
```

can be transformed to this code, which should have the same set of
possible behaviors:

```
    hdr.ethernet.setValid();
    hdr.tcp.setInvalid();
    hdr.ethernet.dstAddress = 1;
    if ((hdr.tcp.isValid() ? hdr.tcp.srcPort : fresh_input_bit_16_1) ==
        (hdr.tcp.isValid() ? hdr.tcp.srcPort : fresh_input_bit_16_2))
    {
        hdr.ethernet.dstAddress = 2;
    }
```

Since we know that `hdr.tcp` is invalid throughout the code above, we
can simplify it to this equivalent code snippet:

```
    hdr.ethernet.setValid();
    hdr.tcp.setInvalid();
    hdr.ethernet.dstAddress = 1;
    if (fresh_input_bit_16_1 == fresh_input_bit_16_2) {
        hdr.ethernet.dstAddress = 2;
    }
```

In that last code snippet, if `fresh_input_bit_16_1` and
`fresh_input_bit_16_2` are inputs to the control or parser, with
arbitrary values of type `bit<16>` that are independent of the
contents of the received packet, it is straightforward to see that the
condition might evaluate to true, or to false.

Given this substitution, it is possible to write P4 programs where the
set of output packet(s) that result from processing one received
packet, and/or the sequence of side effects (e.g. counter, meter,
and/or register updates), either:

(a) in some cases does depend upon the value of a `fresh_input_*`
    input value

(b) all outputs and side effects have absolutely no dependence upon
    the value of any `fresh_input_*` input values.

Programs with property (b) are more predictable and portable across P4
implementations.  It would be very reasonable, and perhaps desirable,
for a P4 compiler with full warnings enabled, or a P4 "lint" type
tool, to warn about any occurrences of (a) in a developer's P4
program.

Even in case (a), it is possible that there are _intermediate_
variable values in a program that depend upon the value of a
`fresh_input_*` input value, but the "final visible outputs", e.g. the
packets going out, and any side effects made to counters, meters,
registers, or other similar stateful objects, does _not_ depend upon
the `fresh_input_*` values, because those intermediate values are
later ignored or masked out.

It seems desirable in such cases to let a P4 developer using a
lint/warning tool to choose whether to see that, or disable
notifications of those, because they might make the program easier to
write, or in fact it might not be reasonable to write the program in
such a way that 0 intermediate variable values depend upon these
`fresh_input_*` values.


# Writing fields of a header

Assume the following context for the code snippets in this section:
```
    // Before this, hdr.ethernet is declared as a header where its
    // dstAddress field is type bit<48>.

    bit<48> expr1;
```

An assignment like this:
```
    hdr.ethernet.dstAddress = expr1;
```

can be replaced with this equivalent code:
```
    if (hdr.ethernet.isValid()) {
        hdr.ethernet.dstAddress = expr1;
    }
```

because the P4_16 language specification says that if `hdr.ethernet`
is invalid, any assignment to one of its fields should not modify any
state that is currently defined.


# Expression evaluations that might execute an exit statement

As of 2020-Jun-08, this P4_16 specification issue is still open:
https://github.com/p4lang/p4-spec/issues/856

One possible way to resolve it is to explicitly specify that
expressions can have sub-expressions (or perhaps the entire
expression) that causes an exit statement to be executed within an
action, and this should 'interrupt' the evaluation of the expression,
and further cause any code that would be executed sequentially
afterwards to not be executed, either.  Some details of how the
specification might make this explicit are in this pull request:
https://github.com/p4lang/p4-spec/pull/860

The rest of this section assumes that this pull request is accepted by
the P4 language design work group.

Suppose we have three tables:

+ `t_never_exits` has one or more actions it may execute, none of
  which contain any `exit` statements

+ `t_always_exits` has one or more actions it may execute, and all of
  those actions execute an `exit` statement every time they are called.

+ `t_sometimes_exits` either has actions that conditionally execute an
  `exit` statement, or it has some actions that never execute an
  `exit` statement, and some actions that may execute an `exit`
  statement.

Then the following code:
```
    hdr.ipv4.setValid();
    hdr.ipv4.totalLen = 40;
    if (t_never_exits.apply().hit) {
        hdr.ipv4.totalLen = 50;
    } else {
        hdr.ipv4.totalLen = 60;
    }
```

leaves the system in a state where `hdr.ipv4.totalLen` is either 50 or
60, but can never be any other value, because exactly one of the
`then` and `else` branch of the `if` statement is always executed.

The following code:
```
    hdr.ipv4.setValid();
    hdr.ipv4.totalLen = 40;
    if (t_always_exits.apply().hit) {
        hdr.ipv4.totalLen = 50;
    } else {
        hdr.ipv4.totalLen = 60;
    }
```

leaves the system in a state where `hdr.ipv4.totalLen` is guaranteed
to be 40, always, because neither the 'then' nor 'else' branch of the
`if` statement is ever executed.

The following code:
```
    hdr.ipv4.setValid();
    hdr.ipv4.totalLen = 40;
    if (t_sometimes_exits.apply().hit) {
        hdr.ipv4.totalLen = 50;
    } else {
        hdr.ipv4.totalLen = 60;
    }
```

leaves the system in a state where `hdr.ipv4.totalLen` is guaranteed
to be one of 40, 50, or 60, but none of them can be ruled out without
additional knowledge or constraints.  If `t_sometimes_exits.apply()`
causes an `exit` statement to be executed, the final value of
`hdr.ipv4.totalLen` will always be 40.  If `t_sometimes_exits.apply()`
does not cause an `exit` statement to be executed, the final value of
`hdr.ipv4.totalLen` will always be either 50 or 60.
