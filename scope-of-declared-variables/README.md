# Introduction

This article was written while thinking about discussions that have
been had about this issue in P4 Language Design Work Group meetings in
late 2025 and 2026:

+ https://github.com/p4lang/p4-spec/issues/1373 'What is the meaning
  of statements like "X a = a"?'


# Terminology used in this article, with example

Consider this snippet of P4 code for the definition of a control:

```
// Program snippet #1, from file prog1p4.p4
control ingressImpl(inout headers_t hdr,
                    inout metadata_t meta,
                    inout standard_metadata_t stdmeta)
{
    bit<8> out1;
    bit<8> out2;
    bit<8> out3;
    bit<8> i;                                 // line 1
    apply {
        bit<8> in1 = hdr.eth.srcAddr[7:0];
        bit<8> in2 = hdr.eth.srcAddr[15:8];
        i = in1;                              // line 2
        {
            bit<8> j = i + 1;                 // line 3
            bit<8> i = in2;                   // line 4
            out2 = i;                         // line 5
            out3 = j;                         // line 6
        }
        out1 = i;                             // line 7
        log_msg("out1={} out2={} out3={} in1={} in2={} i={}",
            {out1, out2, out3, in1, in2, i});
        hdr.eth.dstAddr[ 7: 0] = out1;
        hdr.eth.dstAddr[15: 8] = out2;
        hdr.eth.dstAddr[23:16] = out3;
    }
}
```

Note that all declarations of `i` have the same type, intentionally.
This should avoid any possibility that the compiler might be using the
type of an occurrence of `i`, or the "type expected by the context
where it is used", to distinguish which declaration of `i` it refers
to.

The rules of scoping for P4_16 seem to state pretty clearly that the
symbol `i` on the right-hand side of the line 7 assignment should
refer to the declaration from line 1, and its current value should be
the one assigned by line 2.

They also seem to state pretty clearly that the symbol `i` on the
right-hand side of the line 5 assignment should refer to the
declaration from line 4, and its current value should be the one
assigned by line 4.

There may be some controversy among P4 language designers over whether
the symbol `i` in the assignment of line 3 should refer to the one
declared in line 1 or line 4.  It does seem very odd to me personally
if it refers to the one from line 4, and especially so if `i`'s value
assigned to `j` in line 3 is the one assigned to `i` in line 4, since
line 4 is after line 3.

There is even more controversy over whether Program snippet #3 should
be considered legal, and if so, what its behavior is.  Program snippet
#3 is identical to Program snippet #1, except for line 4.

```
// Program snippet #3, from file prog3p4.p4
control ingressImpl(inout headers_t hdr,
                    inout metadata_t meta,
                    inout standard_metadata_t stdmeta)
{
    bit<8> out1;
    bit<8> out2;
    bit<8> out3;
    bit<8> i;                                 // line 1
    apply {
        bit<8> in1 = hdr.eth.srcAddr[7:0];
        bit<8> in2 = hdr.eth.srcAddr[15:8];
        i = in1;                              // line 2
        {
            bit<8> j = i + 1;                 // line 3
            bit<8> i = i + 2;                 // line 4
            out2 = i;                         // line 5
            out3 = j;                         // line 6
        }
        out1 = i;                             // line 7
        log_msg("out1={} out2={} out3={} in1={} in2={} i={}",
            {out1, out2, out3, in1, in2, i});
        hdr.eth.dstAddr[ 7: 0] = out1;
        hdr.eth.dstAddr[15: 8] = out2;
        hdr.eth.dstAddr[23:16] = out3;
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

As of the version of p4c source code described below, p4c implements
the first interpretation.

```
commit 55fe8f2775842125fec9f6261cfa10bf5a7031e6 (HEAD, origin/main, origin/HEAD, main)
Author: Abhishek Agarwal <agab0323@gmail.com>
Date:   Tue Sep 1 00:19:12 2026 +0000
```


# Scoping rules used by several programming languages

## Summary table

Executive summary: P4_16 in its implementation today, and for several
years, behaves similarly to Rust in its handling of scopes, and also
in how it handles references to names in initialization expressions of
variable declarations, meaning: in initialization expressions, a
reference to a name can only refer to an earlier declaration of the
name, not to the one currently being declared.

Consider a program like the ones in the snippets above where `i` is
declared in an outer scope, and also in an inner scope.

The entries of the table below indicate whether a mention of a
variable name in the part of the program described in the first column
will refer to the variable declared in the outer scope, or the
variable declared in the inner scope.

For example, with all of the programming languages listed (except
Java), if there is a variable name in the inner scope, _before_ the
inner declaration that shadows the outer definition, that name refers
to the variable declared in the outer scope.

| Location in program source code of the mention of the variable | P4_16 (p4c source 2026-Apr-01) | Rust (rustc 1.94.1) | C (GCC 13.3.0 on Ubuntu Linux 24.04) | C++ (GCC 13.3.0 on Ubuntu Linux 24.04) | Java (JDK 23) |
| ------------------------------- | ------------------------------ | ------------------------------ | -------------------------------- | ------------------- | ------------- |
| outer scope | outer | outer | outer | outer | It is compile-time error for inner scopes to declare local variables that shadow variables in outer scopes. |
| inner scope before declaration of shadowing variable | outer | outer | outer | outer | N/A |
| inner scope in right-hand side expression that initializes shadowing variable | outer | outer | inner [Note 1] | inner [Note 1] | N/A |
| inner scope after declaration of shadowing variable | inner | inner | inner | inner | N/A |

Note 1: In this case, the value of the variable is uninitialized, so
its value is unpredictable.  If you take the address of it, that
storage location is well defined and predictable.

Note: Rust also allows a variable to be declared multiple times in the
_same_ scope.  Later ones shadow earlier ones.

Below are the results for test programs in each language that attempt
to refer to a name in the initialization expression of the declaration
of that same name (e.g. `int i = i;`), when there is _no_ earlier
symbol defined with that name.  These are in the test programs with
"4" in their names.

+ P4_16 - compile-time error.  Error message `<name>: declaration not
  found`.
+ Rust - compile-time error.  Error message `not found in this scope`
  at reference to symbol in initialization expression.
+ C - legal.  Value of symbol is uninitialized.
+ C++ - legal.  Value of symbol is uninitialized.
+ Java - compile-time error.  Error message `variable <name> might not
  have been initialized`.

Below are the results for test programs in each language that define a
function (or for P4, a `control`) with a parameter named `i`, and then
declare local variables with the same name `i`.

+ P4_16 - Legal.  The later declarations with the same name shadow the
  parameter.
+ Rust - Same as P4_16.
+ C - compile-time error.  Error message "`i` redeclared as different
  kind of symbol".
+ C++ - compile-time error.  Error message "declaration of ‘int i’
  shadows a parameter".
+ Java - compile-time error.  Error message "variable i is already
  defined in method foo(int,int[])"


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

File prog4p4.p4 is similar to prog2p4.p4, but it eliminates the `i`
declared in the outer scope.


## What does C do?

I tested with GCC version 13.3.0 on Ubuntu Linux.

See files: prog1c.c prog2c.c prog3c.c prog4c.c

From the behavior of the compiler and the test programs, the scope of
outer variable `i` includes:

+ all of the outer scope after `i` is declared,
+ all of the inner scope before the inner declaration of `i`, and
+ _not_ the initialization expression for the declaration of inner `i`.

The initialization expression for the declaration of inner `i` is in
scope for the inner `i`, but its value is uninitialized.


## What does C++ do?

I tested with GCC version 13.3.0 on Ubuntu Linux.

See files: prog1cpp.cpp prog2cpp.cpp prog3cpp.cpp prog4cpp.cpp

The behavior is the same as for C.


## What does Rust do?

I tested with rustc version 1.94.1.

See files: prog1rs.rs prog2rs.rs prog3rs.rs prog4rs.rs

From the behavior of the compiler and the test programs, the scope of
outer variable `i` includes:

+ all of the outer scope after `i` is declared,
+ all of the inner scope before the inner declaration of `i`, and
+ it _does_ include the initialization expression for the declaration of inner `i`.

The initialization expression for the declaration of inner `i` is in
scope for the outer `i`, and its value is whatever the current value
of the outer `i` is at the time of the initialization.


## What does Java do?

See file: prog1.java prog4.java

It is a compile-time error to attempt to declare a local variable in
an inner scope with the same name as a local variable in an outer
scope.


# Some details of p4c compiler passes that provide supporting evidence for its behavior

On a Linux system with `p4c` installed, you can run the script
`build.sh` to compile all of the example P4, C, C++, and Java programs
in this directory.

While compiling the P4 programs, it generates P4 source code for the
intermediate representation of the P4 program in the compiler's memory
after every one of its frontend and midend passes.  Then the script
removes all of those, except the ones that differ from the version of
the previous pass, to emphasize only those versions of the IR that
changed from the previous pass.

The snippets of code below were generated using `p4c` built from this
version of the source code of the repository
https://github.com/p4lang/p4c:
```
commit 55fe8f2775842125fec9f6261cfa10bf5a7031e6 (HEAD, origin/main, origin/HEAD, main)
Author: Abhishek Agarwal <agab0323@gmail.com>
Date:   Tue Sep 1 00:19:12 2026 +0000
```

First, a repeat of the original source code snippet #1 from program
`prog1p4.p4`, the same as appeared earlier in this article:

```
// Program snippet #1, from file prog1p4.p4
control ingressImpl(inout headers_t hdr,
                    inout metadata_t meta,
                    inout standard_metadata_t stdmeta)
{
    bit<8> out1;
    bit<8> out2;
    bit<8> out3;
    bit<8> i;                                 // line 1
    apply {
        bit<8> in1 = hdr.eth.srcAddr[7:0];
        bit<8> in2 = hdr.eth.srcAddr[15:8];
        i = in1;                              // line 2
        {
            bit<8> j = i + 1;                 // line 3
            bit<8> i = in2;                   // line 4
            out2 = i;                         // line 5
            out3 = j;                         // line 6
        }
        out1 = i;                             // line 7
        log_msg("out1={} out2={} out3={} in1={} in2={} i={}",
            {out1, out2, out3, in1, in2, i});
        hdr.eth.dstAddr[ 7: 0] = out1;
        hdr.eth.dstAddr[15: 8] = out2;
        hdr.eth.dstAddr[23:16] = out3;
    }
}
```

Below is an excerpt from the compiler output file named
`prog1p4-0033-FrontEnd_32_UniqueNames.p4`, the most relevant pass here
because that pass renames most or all occurrences of variable names to
be unique.  This demonstrates very clearly which input symbols that
p4c considers refer to which declaration.

The actual compiler output file contains no comments.  I have added in
comments to make it easier to correspond lines below with lines in the
previous excerpt.

```
control ingressImpl(inout headers_t hdr, inout metadata_t meta, inout standard_metadata_t stdmeta) {
    @name("out1") bit<8> out1_0;
    @name("out2") bit<8> out2_0;
    @name("out3") bit<8> out3_0;
    @name("i") bit<8> i_0;                       // line 1
    apply {
        @name("in1") bit<8> in1_0 = hdr.eth.srcAddr[7:0];
        @name("in2") bit<8> in2_0 = hdr.eth.srcAddr[15:8];
        i_0 = in1_0;                             // line 2
        {
            @name("j") bit<8> j_0 = i_0 + 8w1;   // line 3
            @name("i") bit<8> i_1 = in2_0;       // line 4
            out2_0 = i_1;                        // line 5
            out3_0 = j_0;                        // line 6
        }
        out1_0 = i_0;                            // line 7
        log_msg<tuple<bit<8>, bit<8>, bit<8>, bit<8>, bit<8>, bit<8>>>("out1={} out2={} out3={} in1={} in2={} i={}", { out1_0, out2_0, out3_0, in1_0, in2_0, i_0 });
        hdr.eth.dstAddr[7:0] = out1_0;
        hdr.eth.dstAddr[15:8] = out2_0;
        hdr.eth.dstAddr[23:16] = out3_0;
    }
}
```

The occurrences of `i_0` on lines 1, 2, 3, and 7, but not anywhere
else, make it clear that those are all of the occurrences of `i` in
the original program that correspond to the declaration on line 1, and
only those.  Similarly for the occurrences of `i_1` on lines 4 and 5.

Below is a repeat of snippet #3 from earlier in this article:

```
// Program snippet #3, from file prog3p4.p4
control ingressImpl(inout headers_t hdr,
                    inout metadata_t meta,
                    inout standard_metadata_t stdmeta)
{
    bit<8> out1;
    bit<8> out2;
    bit<8> out3;
    bit<8> i;                                 // line 1
    apply {
        bit<8> in1 = hdr.eth.srcAddr[7:0];
        bit<8> in2 = hdr.eth.srcAddr[15:8];
        i = in1;                              // line 2
        {
            bit<8> j = i + 1;                 // line 3
            bit<8> i = i + 2;                 // line 4
            out2 = i;                         // line 5
            out3 = j;                         // line 6
        }
        out1 = i;                             // line 7
        log_msg("out1={} out2={} out3={} in1={} in2={} i={}",
            {out1, out2, out3, in1, in2, i});
        hdr.eth.dstAddr[ 7: 0] = out1;
        hdr.eth.dstAddr[15: 8] = out2;
        hdr.eth.dstAddr[23:16] = out3;
    }
}
```

and below is the corresponding excerpt from the `p4c` output file
`prog3p4-0033-FrontEnd_32_UniqueNames.p4`, with comments added:

```
control ingressImpl(inout headers_t hdr, inout metadata_t meta, inout standard_metadata_t stdmeta) {
    @name("out1") bit<8> out1_0;
    @name("out2") bit<8> out2_0;
    @name("out3") bit<8> out3_0;
    @name("i") bit<8> i_0;                          // line 1
    apply {
        @name("in1") bit<8> in1_0 = hdr.eth.srcAddr[7:0];
        @name("in2") bit<8> in2_0 = hdr.eth.srcAddr[15:8];
        i_0 = in1_0;                                // line 2
        {
            @name("j") bit<8> j_0 = i_0 + 8w1;      // line 3
            @name("i") bit<8> i_1 = i_0 + 8w2;      // line 4
            out2_0 = i_1;                           // line 5
            out3_0 = j_0;                           // line 6
        }
        out1_0 = i_0;                               // line 7
        log_msg<tuple<bit<8>, bit<8>, bit<8>, bit<8>, bit<8>, bit<8>>>("out1={} out2={} out3={} in1={} in2={} i={}", { out1_0, out2_0, out3_0, in1_0, in2_0, i_0 });
        hdr.eth.dstAddr[7:0] = out1_0;
        hdr.eth.dstAddr[15:8] = out2_0;
        hdr.eth.dstAddr[23:16] = out3_0;
    }
}
```

The only difference between this and the `p4c` output file for the
previous snippet is on line 4, where it is clear that in the
initialization expression on the right hand side it refers to `i_0`,
declared on line 1, not to `i_1`, declared on line 4.


Below is an exerpt of program `prog5p4.p4` which has a control `foo`
with parameter named `i`, and two local declarations of a variable `i`
as well, to test which occurrences refer to which definition.

```
control foo (inout bit<8> i, out bit<8> out1, out bit<8> out2, out bit<8> out3) {
    bit<8> i = i + 1;            // line 1
    apply {
        out1 = i;                // line 2
        {
            bit<8> i = i + 1;    // line 3
            out2 = i;            // line 4
        }
        out3 = i;                // line 5
    }
}
```

Below is an excerpt of the intermediate p4c output file named
`prog5p4-0033-FrontEnd_32_UniqueNames.p4`, with comments added to show
the correspondence of lines in the excerpt above with the lines below.

```
control foo(inout bit<8> i, out bit<8> out1, out bit<8> out2, out bit<8> out3) {
    @name("i") bit<8> i_0 = i + 8w1;             // line 1
    apply {
        out1 = i_0;                              // line 2
        {
            @name("i") bit<8> i_1 = i_0 + 8w1;   // line 3
            out2 = i_1;                          // line 4
        }
        out3 = i_0;                              // line 5
    }
}
```

Almost all of the occurrences of `i` in the input program refer to the
one defined on line 1.  The one on line 4 refers to the definition
from line 3.  None of the original occurrences of `i` refer to the
parameter, except for the first one on line 1 in the initialization
expression.
