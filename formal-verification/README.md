These are a few notes on ideas for formal verification of P4_16
programs.

It has some example programs that demonstrate an aspect of the P4_16
language specification that seems like it may have unusual
consequences for formal verification tools, and correct P4_16
compilers.


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


# Restrictions on legal transformation a P4_16 compiler can make

See this issue for the origin of the examples in this section, and
thoughts from other P4 experts:
https://github.com/p4lang/p4-spec/issues/891

Fabian Ruffy asked about Program Undef1, and asked "What other P4_16
programs is it legal for a P4 compiler to transform this into?"

Program Undef1:
```
control ingress(inout Headers hdr, ...) {
    apply {
        bit<8> undef;
        if (undef == 1) {
            hdr.eth_hdr.src_addr = 1;
        } else {
            hdr.eth_hdr.src_addr = 2;
        }
    }
}
```

Nate Foster mentions later the idea that a compiler should preserve
the semantics of the input program, or to be more precise, refine the
input program.

I believe one way to think of the idea of refinement in an operational
way is that for a given P4 program, combined with a particular
run-time configuration of tables and externs, and a particular input
packet, there are a set of possible "effects" that could result from
processing that received packet.

By "effects" I mean: the sequence of output packets that eventually
result, which output ports they appear on, and what side effects are
made to stateful objects like P4 counter, meter, and register externs.

In some cases, that set of possible behaviors contains only one
possible behavior.

When more than one behavior is possible, there can be multiple reasons
why, e.g. a packet buffer might drop a packet destined for a
particular output port in one state where the packet buffer is full,
or it might successfully store and later output the packet to that
output port if the packet buffer has sufficient space available.  This
kind of reason is not the focus of this article, but I wanted to
briefly mention it.  This category of reasons for different possible
behaviors is often not under the direct control of the P4 program, and
thus outside the realm of P4 language semantics.  It is more properly
in the category of behavior that depends upon the architecture of the
P4 target device.

The primary reason for multiple behaviors we will consider here are
those resulting from the semantics of the P4 language itself, and most
especially the ones resulting from the part of the P4 specifiation
pointed out in the "Reading fields of a header" section above: if an
uninitialized variable or header field is read, each of its uses can
result in a differnt value being used.

Aside: You might wonder why such behavior is mentioned in the P4
language specification.  My understanding is that the primary reason
to explicitly allow this is that some targets have very limited
capacity per packet for storing such variables and header fields.  A
technique to mitigate this is that if a header is invalid, it is
effectively "not allocated", i.e. the name of the header field can be
read and written, but it might be allocated by the compiler to the
same storage location(s) as some other header field within a header
that is currently valid.  Thus modifications to the field in the valid
header could have the effect of also modifying the value of the field
currently in the invalid header.  Such a technique could also apply to
variables that are not header fields, based upon a liveness analysis
of where the variable is expected to be first initialized, and last
read.

As a concrete example, consider programs Undef2 and Undef3 below.

Program Undef2:
```
control ingressImpl(inout headers_t hdr,
                    inout metadata_t meta,
                    inout standard_metadata_t stdmeta)
{
    bit<8> undef;
    bit<8> x;
    apply {
        x = undef;
        // x is now initialized, but to some value that the spec does
        // not guarantee what it is, other than it is some value of
        // type bit<8>, i.e. in the range 0 to 255.

        // The perhaps subtle point is that because x is initialized,
        // the two occurrences of x below must evaluate to the same
        // value each time.
        if (x == 1) {                    // condition #1
            hdr.ethernet.srcAddr = 1;    // assignment #1
        }
        if (x != 1) {                    // condition #2
            hdr.ethernet.etherType = 2;  // assignment #2
        }
    }
}
```

Program Undef3:
```
control ingressImpl(inout headers_t hdr,
                    inout metadata_t meta,
                    inout standard_metadata_t stdmeta)
{
    bit<8> undef;
    apply {
        // Because undef is not initialized, the two occurrences of
        // undef below might evaluate to different values each time.
        if (undef == 1) {                // condition #1
            hdr.ethernet.srcAddr = 1;    // assignment #1
        }
        if (undef != 1) {                // condition #2
            hdr.ethernet.etherType = 2;  // assignment #2
        }
    }
}
```

Because in Undef2 there is an explicit assignment to variable `x`, an
implementation of Undef2 should do exactly one of these two things:

(behavior #1) evaluate condition #1 as true, and condition #2 as false
(behavior #2) evaluate condition #1 as false, and condition #2 as true

Program Undef3 looks like it should be equivalent.  After all, it is
simply eliminating what appears to be a redundant and unnecessary
local variable `x`, and using `undef` instead, which seems like it
should have the same value.

The difference is that `x` was initialized, but `undef` is not, and
thus multiple occurrences of `undef` might result in different values
of type `bit<8>` being used.  Thus there are now 4 possible behaviors,
which include the two behaviors above, plus the following:

(behavior #3) evaluate condition #1 as true, and condition #2 as true
(behavior #4) evaluate condition #1 as false, and condition #2 as false

Going back to the term "refine", I believe a correct definition is:

refine: We say that "program B refines program A" if the set of
    possible behaviors of B is a subset of the possible behaviors of A
    (perhaps the same set, perhaps a proper subset).  Alternately we
    may say "program B is a refinment of program A".

So program Undef2 is a refinement of Undef3, but program Undef3 is
_not_ a refinement of Undef2.

The open source `p4c` compiler has many front-end and mid-end passes
that transform the original input program into other P4_16 programs,
and the intent is that the P4_16 program output by the last mid-end
pass should be a refinement of the input program.

[It might also be the intent that the output of pass X is a refinement
of the input of pass X, for all passes.]

Note: As of the version of `p4c` shown in file
`README-compile-steps.md` in the part with commands for program
`v1model-undef2.p4`, it _does_ transform the program Undef2 into
Undef3.  The elimination of the variable `x` occurs in the
LocalCopyPropagation pass.  It also warns that the variable `undef`
may be uninitialized on the line for the assignment `x = undef;`,
which is good.

Question: If we wish `p4c` not to make such a transformation, perhaps
one way is to only enable some kinds of transformations when the
compiler can guarantee that some of the relevant variables involved
are initialized?  When no such guarantee can be made, then some
transformation steps would be skipped.

An example that looks similar, but involves a different kind of
transformation that is perfectly correct when the relevant variables
are initialized, is shown in program Undef4 below.

Program Undef4:
```
control ingressImpl(inout headers_t hdr,
                    inout metadata_t meta,
                    inout standard_metadata_t stdmeta)
{
    bit<8> undef;
    apply {
        if (undef == 1) {                // condition #1
            hdr.ethernet.srcAddr = 1;    // assignment #1
        } else {
            hdr.ethernet.etherType = 2;  // assignment #2
        }
    }
}
```

If `undef` were initialized, then programs Undef4 and Undef3 would
have the same set of possible behaviors.

However, because `undef` is not initialized, Undef3's set of possible
behaviors is a strict superset of Undef4's behaviors.

Thus it would be legal for a compiler to transform Undef3 into Undef4,
but not vice versa.

The root issue here is that if one attempted to transform Undef4 into
Undef3, it is creating multiple occurrences of the uninitialized
variable `undef`, where originally there was only one.

Note: As of the version of `p4c` shown in file
`README-compile-steps.md` in the part with commands for program
`v1model-undef4.p4`, it does _not_ transform the program Undef4 into
Undef3.  It keeps the if-then-else code as it was in the input
program.  This example is mentioned because the transformation `if
(condition_expr) body1 else body2;` to `if (condition_expr) body1; if
(! condition_expr) body2;` was brought up as transformation that p4c
might make, at least in some situations.  I do not know what
situations those are.  Perhaps within action bodies?

