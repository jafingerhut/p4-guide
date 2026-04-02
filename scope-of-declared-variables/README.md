# Introduction

This article was written while thinking about discussions that have
been had about this issue in P4 Language Design Work Group meetings in
late 2025 and 2026:

+ https://github.com/p4lang/p4-spec/issues/1373 'What is the meaning
  of statements like "X a = a"?'


# Terminology used in this article, with example

Consider this snippet of P4 code for the definition of a control:

```
// Program snippet #1
control ingressImpl(inout headers_t hdr,
                    inout metadata_t meta,
                    inout standard_metadata_t stdmeta)
{
    bit<8> i;                                 // line 1
    apply {
        i = hdr.eth.srcAddr[7:0];             // line 2
        {
            bit<4> j = i[3:0];                // line 3
            bit<8> i = hdr.eth.srcAddr[15:8]; // line 4
            hdr.eth.dstAddr[15:8] = i;        // line 5
            hdr.eth.dstAddr[19:16] = j;       // line 6
        }
        hdr.eth.dstAddr[7:0] = i;             // line 7
    }
}
```

The rules of scoping for P4_16 seem to state pretty clearly that the
symbol `i` on the right-hand side of the line 7 assignment should
refer to the declaration from line 1, and its current value should be
the one assigned by line 2.

They also seem to state pretty clearly that the symbol `i` on the
right-hand side of the line 5 assignment should refer to the
declaration from line 4, and its current value should be the one
assigned by line 4.

There seems to be some controversy among P4 language designers over
whether the symbol `i` in the assignment of line 3 should refer to the
one declared in line 1 or line 4.  It does seem very odd to me
personally if refers to the one from line 4, and especially so if
`i`'s value assigned to `j` in line 3 is the one assigned to `i` in
line 4, since line 4 is after line 3.

There is even more controversy over whether Program snippet #3 should
be considered legal, and if so, what its behavior is.  Program shippet
#3 is identical to Program snippet #1, except for line 4.

```
// Program snippet #3
control ingressImpl(inout headers_t hdr,
                    inout metadata_t meta,
                    inout standard_metadata_t stdmeta)
{
    bit<8> i;                                 // line 1
    apply {
        i = hdr.eth.srcAddr[7:0];             // line 2
        {
            bit<4> j = i[3:0];                // line 3
            bit<8> i = i + 2;                 // line 4
            hdr.eth.dstAddr[15:8] = i;        // line 5
            hdr.eth.dstAddr[19:16] = j;       // line 6
        }
        hdr.eth.dstAddr[7:0] = i;             // line 7
    }
}
```

One possible interpretation is that the symbol `i` on the right-hand
side of the initialization assignment of line 4 refers to the
declaration from line 1, and its current value is the one from line 2.

Another possible interpretation is that the symbol `i` on the
right-hand side of line 4 refers to the declaration from line 4, and
its current value is uninitialized and thus not determined by the
language specification, i.e. an implementatino is free to implement
any value of type `bit<8>` there, and even for that value to differ
from one execution of the control to another.


# Scoping rules used by several programming languages

## Summary table

| Location in program source code | P4_16 (p4c source 2026-Apr-01) | C (GCC 3.13.0 on Ubuntu Linux) | C++ (GCC 3.13.0 on Ubuntu Linux) | Rust (rustc 1.94.1) | Java (JDK 23) |
| ------------------------------- | ------------------------------ | ------------------------------ | -------------------------------- | ------------------- | ------------- |
| outer scope | outer | outer | outer | outer | It is compile-time error for inner scopes to declare local variables that shadow variables in outer scopes. |
| inner scope before declaration of shadowing variable | outer | outer | outer | outer | N/A |
| inner scope in right-hand side expression that initializes shadowing variable | outer | inner [Note 1] | inner [Note 1] | outer | N/A |
| inner scope after declaration of shadowing variable | inner | inner | inner | inner | N/A |


## Behavior of p4c as of 2026-Apr-01

File prog1p4.p4 corresponds to Program snippet #1.

+ The line 3 occurrence of `i` refers to the declaration in line 1,
  and value assigned in line 2.
+ The line 5 occurrence of `i` refers to the declaration, and value
  assigned in, line 4.

File prog2p4.p4 corresponds to Program snippet #1, but with lines 3
and 4 swapped in order.  I won't comment on the details here, but they
are not surprising.

File prog3p4.p4 corresponds to Program snippet #3.

The only difference with the notes for Program snippet #1 is:

+ The occurrence of `i` on the right-hand side of the assignment in
  line 4 refers to the declaration in line 1, and value assigned in
  line 2.


## What does C do?

I tested with GCC version 13.3.0 on Ubuntu Linux.

See files: prog1c.c prog2c.c prog3c.c

From the behavior of the compiler and the test programs, the scope of
outer variable `i` includes:

+ all of the outer scope after `i` is declared,
+ all of the inner scope before the inner declaration of `i`, and
+ _not_ the initialization expression for the declaration of inner `i`.

The initialization expression for the declaration of inner `i` is in
scope for the inner `i`, but its value is uninitialized.


## What does C++ do?

I tested with GCC version 13.3.0 on Ubuntu Linux.

See files: prog1cpp.cpp prog2cpp.cpp prog3cpp.cpp

The behavior is the same as for C.


## What does Rust do?

I tested with rustc version 1.94.1.

See files: prog1rs.rs prog2rs.rs prog3rs.rs

From the behavior of the compiler and the test programs, the scope of
outer variable `i` includes:

+ all of the outer scope after `i` is declared,
+ all of the inner scope before the inner declaration of `i`, and
+ it _does_ include the initialization expression for the declaration of inner `i`.

The initialization expression for the declaration of inner `i` is in
scope for the outer `i`, and its value is whatever the current value
of the outer `i` is at the time of the initialization.


## What does Java do?

See file: prog1.java

It is a compile-time error to attempt to declare a local variable in
an inner scope with the same name as a local variable in an outer
scope.
