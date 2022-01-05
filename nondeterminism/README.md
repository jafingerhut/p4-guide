# Introduction

In most cases, the P4_16 language specifies the possible results of
executing programs very precisely.  Unlike the language C, for
example, P4_16 defines the precise bit level behavior of all supported
arithmetic operations on both unsigned and signed integer types, and
requires that signed integers are represented using two's complement
representation.

However, one area where nondeterministic results are explicitly
allowed by the language specification is in expressions containing
uninitialized variables.

For example, if a variable `x` of type `bit<8>` has not been
initialized before a place where its value is used in an expression,
the language specification explicitly allows that "read" of `x`'s
value to evaluate to any value of type `bit<8>`.  More frustratingly,
it explicitly allows multiple uses of `x`'s value to evaluate to a
_different_ value of type `bit<8>`.


# TODO: section title

See this Github issue, for example, and the section of the P4_16
language specification that it links to:
https://github.com/p4lang/p4-spec/issues/988


# Why does the specification define this behavior?

The motivation for this is to enable a P4 compiler to optimize the
storage space of variables.  An uninitialized variable is allowed to
be assigned a location in hardware storage that is the same as some
other currently-initialized variable.  If that currently-initialized
variable changes its value, a read of `x` before that change can in
general return a different value than a read of `x` after that change.


# Why not simply require that every variable be initialized as soon as it can be referenced?

For example, Java requires that every field of every object must have
an initial value, and mandates particular initial values for every
type of value, if the Java program does not explicitly assign an
initial value, e.g. 0 for all integer types, and null for all object
references.

Requiring initialization of all variables can have a definite hardware
cost.  For example, in a PISA hardware architecture, it can lead to an
extra stages of processing to execute a P4 program, to perform the
initializations.  When you have on the order to 10 to 20 stages of
processing, saving even one can be the critical difference between a
program compiling, vs. not compiling, in the target device.


# What do other programming languages that allow uninitialized variables specify?

I believe that the language C treats any use of uninitialized
variables as undefined behavior.  A conforming C compiler is allowed
to produce an executable that does absolutely nothing, or anything,
including trashing the state of your entire system.

+ John Regehr, "A Guide to Undefined Behavior in C and C++, Part 1",
  https://blog.regehr.org/archives/213

I suspect that one reason for this is that defining reads of
uninitialized variables in the way that P4_16 does, makes it difficult
to prove that certain kinds of compiler optimizations are correct.  If
something is defined as undefined behavior, it means that aggressive
compiler optimizations can be correct if the variables used are
initialized, and do pretty much anything if the variables are
uninitialized.


# Are there practical P4 programs that are safe, despite using ininitialized variables in expressions?

TODO: Write a short example.

Typical example I have seen is to have a table lookup where a key is
one or more VLAN tags, where the VLAN tag fields are uninitialized if
those headers did not occur in the packet, and thus were never parsed.
In P4_16, reading a field in a currently invalid header is treated the
same as reading an uninitialized variable: it can evaluate to any
value allowed for the type of the field.

However, if you know this, you can qualify the table entries with a separate valid bit in a different key field of the table.  If the table key fields are all ternary, and the control plane has these restrictions on adding entries:

+ If the valid bit of a header can be 0, then the mask of all fields
  of that header must be completely wildcarded in the entry.


# Can a compiler determine precisely whether every reference to a variable is using its value uninitialized?

TODO: I am not sure of the correct answer here.  Help welcome.

Suppose for the moment that the answer is "yes" when no assumptions
are made about the contents of table entries created by the control
plane.

It is relatively common that when co-developing a P4 program and its
control plane software, the combination of those two things can lead
to provable restrictions on the entries that can appear in a table.
If these restrictions are known, then one can in some cases prove that
a read of a variable can be made at a time when it is uninitialiezd
without these restrictions,

TODO: Create a simple P4 program where no restrictions on table entry
contents lead to using an uninitialized variable value, but realistic
restrictions on table entry contents enables one to prove that no
uninitialized value can possibly affect the observable packet
processing behavior.


# Demonstration of LocalCopyPropagation increasing nondeterminism of input program

Note: The following example is not of a practical useful P4 program.
However, the fact that it exists at least raises the question of
whether the LocalCopyPropagation pass might cause undesirable effects
when compiling useful program.

It is possible that even given that the LocalCopyPropagation pass has
this undesirable property, it might be that this is mitigated by one
or more of the following factors:

+ Perhaps there are no practical programs where this is an issue.
+ Even if there are practical programs where the LocalCopyPropagation
  pass can increase the set of possible behaviors, perhaps it is only
  when the compiler can detect and warn "a may be uninitialized" as it
  does for the program `a1.p4`.

However, note that either of those possible factors, even if they are
true, sound difficult to prove.

Below is the entire body of the ingress control of program `a1.p4`,
which you can find the complete source code for in this directory:

```
    apply {
        bit<9> a;
        bit<9> b;
        // b becomes initialized, even though a is still uninitialized
        b = a + 5;
        stdmeta.egress_spec = b ^ (b ^ 1);
    }
```

According to the P4_16 language specification, when the assignment `b
= a + 5` is performed, since `a` is uninitialized, `a` can take on any
of the 512 possible values of `bit<9>`.  Thus `b` can be assigned any
of those 512 possible values, too.

However, after that assignment, `b` is now initialized.  We do not
know what value it will have, but on any single execution of that
code, `b` will become a single, initialized, deterministic value.

When the value of the expression `b ^ (b ^ 1)` is calculated, `b` must
have the same value for both times it occurs.  The value of that
expression is equal to `(b ^ b) ^ 1`, equal to `0 ^ 1`, or always 1.

When running this version of `p4c-bm2-ss` on this program, at least:
```
Version 1.2.2 (SHA: 448f019de BUILD: DEBUG)
```

there are many compiler passes before the one called
LocalCopyPropagation.  The last pass before LocalCopyPropagation has
transformed this part of the program to:

```
    @name("ingressImpl.a") bit<9> a_0;
    @name("ingressImpl.b") bit<9> b_0;
    apply {
        b_0 = a_0 + 9w5;
        stdmeta.egress_spec = b_0 ^ (b_0 ^ 9w1);
    }
```

This code has exactly the same set of possible behaviors as the input
program.

The output of the LocalCopyPropagation pass is this:

```
    @name("ingressImpl.a") bit<9> a_0;
    apply {
        stdmeta.egress_spec = a_0 + 9w5 ^ (a_0 + 9w5 ^ 9w1);
    }
```

Note: In P4_16, the precedence of the `+` operator is higher than the
`^` operator, and the P4 compiler does not print unnecessary
parentheses.  Thus the above assignment is equivalent to the one
below:

```
        stdmeta.egress_spec = (a_0 + 9w5) ^ ((a_0 + 9w5) ^ 9w1);
```

Now, if `a_0` was initialized when this assignment was performed, its
set of possible results would be the same as the input program,
i.e. the result of calculating the formula would always be 1.

However, `a_0` is uninitialized at the time of this assignment.  Thus
the first occurrence of `a_0` could evaluate to any of the 512
possible `bit<9>` values, and the second occurrence of `a_0` could
evaluate to any of the 512 possible values.  A little bit of thinking
should convince you that thus the value assigned to `egress_spec`
could be any of the 512 possible `bit<9>` values.

You can run the following command to run the P4 compiler on a v1model
architecture P4 program, and see the difference between the compiler's
intermediate result from just before the LocalCopyPropagation pass, to
just after that pass:

```bash
./show-localcopypropagation-change.sh a1.p4 
```

One might be tempted to ask: So if we improve the P4 compiler so that
it can reason that `b ^ (b ^ 1)` is always 1, and makes that
replacement itself, we can avoid this issue that way, right?

I do not think that is a fruitful approach.  This is a very simple
example where a calculation has a single possible correct output.
There are an _unlimited_ set of such formulas, and in general while
the restrictions on the P4 language might make these cases decidable
computational problems, rather than undecidable ones, that does not
mean they are computable in a reasonable amount of time that you want
to implement in a compiler.

For example, consider the case where we have the MD5 sum of a 40-byte
packet header calculated in two different ways in a P4 program,
assigned to variables `m1` and `m2`, and then we calculate `m1 ^ m2`.
If those two different calculations both always produce the same value
for all inputs, then a smart enough compiler could replace `m1 ^ m2`
with 0.  However, even one tiny subtle bug anywhere in there and you
could not do that.  Existing SMT solver type of approaches would
likely not finish this problem in our lifetimes.
