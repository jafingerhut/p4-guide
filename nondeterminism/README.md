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
