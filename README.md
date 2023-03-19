# Introduction

This repository contains a variety of potentially useful information
for those wanting to work with the [P4 programming
language](http://p4.org).


## Installing open source P4 development tools

There are install scripts in this repository that can assist you
in building and installing the `p4c` and `behavioral-model` projects
and their dependencies on Ubuntu Linux systems with these versions:

+ 18.04, 20.04, or 22.04

See [these instructions and trouble-shooting
tips](bin/README-install-troubleshooting.md) for using these scripts.

There are also some [newer instructions
here](ipdk/23.01/README-install-ipdk-networking-container-ubuntu-20.04-and-test.md),
perhaps a little less beginner-friendly, for installing IPDK 23.01 on
an Ubuntu 20.04 Linux, and using the DPDK software switch to load and
run P4 programs.


## Articles on various P4 topics

See [this page](docs/README.md) for a list of articles included in
this repository.


## Overview of public P4.org documentation and code repositories

* An overview of the [p4lang organization Github
  repositories](README-p4lang-repos.md)
* A figure with the [dependencies](dependencies.pdf) between these
  repositories (last updated June 2017 so may be slightly out of
  date).


## Small demo P4 programs

A collection of small [demo P4 programs](README-demos.md), some of
them with equivalent versions written in both P4_14 and P4_16 versions
of the language.

* includes a [heavily commented P4_16
  program](demo1/demo1-heavily-commented.p4_16.p4), which by reading
  carefully one may learn some things about the P4_16 language.
* Each of the demo directories includes its own README.md file with
  instructions for compiling the program and running it with the
  `simple_switch` software switch from the `behavioral-model`
  repository, including interactively adding table entries to the
  tables, and send packets using Scapy that will be processed by the
  software switch.


## Related development tools and tips

* [Instructions for setting up several text editing
  programs](README-editor-support.md) for color highlighting P4
  programs, and quickly finding definitions for named things like
  control blocks and tables.

* 'Cheat sheet' of where P4_16 language constructs are allowed to be
  used within a program.
  * [figure](p4-16-allowed-constructs.pdf)
  * [text](p4-16-allowed-constructs.txt)
  * NOTE: This describes where language constructs are allowed by the
    P4_16 language specification (version 1.1.0).  P4_16
    implementations may restrict your program to less than what is
    shown here, or enable extensions not described here.  Ask the
    creator of the implementation you are using to learn more.

* Another useful ['cheat sheet'](https://github.com/p4lang/tutorials/blob/master/p4-cheat-sheet.pdf)
  with example snippets of code is in the p4lang/tutorials repository.

* Some [notes on using the Scapy library](README-scapy.md) for
  creating, editing, and decoding packets, useful when creating test
  packets to send to a P4 program being tested, especially within the
  control of a general purpose programming language (i.e. Python).


## Brief overview of P4

This is just enough to give you a 'flavor' of what P4 is like, in
about 500 words.  It assumes you are familiar with the programming
language C or something very similar to it, e.g. C++ or Java.

* Start with C.
* Remove loops, recursive calls, pointers, malloc, and free.  When
  your mind recovers from reeling over these drastic limitations,
  you will clearly realize that P4 is _not_ a general purpose
  programming language.  It was not designed to be.
  * Without loops or recursive calls, the work done per packet can
    be bounded at compilation time, which helps when targeting the
    highest performance P4-programmable devices.
  * Without pointers, malloc, and free, general purpose data
    structures like linked lists, trees, etc. having arbitrary size
    is not possible.  You _can_ implement trees with fixed depth,
    e.g. a depth 3 tree could be implemented via a sequence of 3 P4
    tables.
* Add special constructs called _parsers_, focused on the capabilities
  most needed when parsing the contents of a received packet into a
  sequence of _headers_.
  * Parsers are defined as finite state machines, with states that
    you must name and define what the possible transitions are
    between them.  It is actually allowed to have loops in the
    parser finite state machine, but the highest performance targets
    will typically restrict you to loops that can be unrolled to a
    compile-time known maximum number of iterations, e.g. for
    parsing a sequence of MPLS headers at most 5 headers long (where
    5, or some other value, is a number you pick in your source
    code).
  * P4 is focused on packet header processing.  Whatever part of a
    packet you do not parse into some header is, for that P4
    program, considered the "payload" of the packet, which is
    typically carried along, unmodified, with the packet when you
    are done processing it.  You can modify header fields however
    you like.
* Add special constructs called _tables_, where for each one you
  define a search key consisting of a number of packet header fields
  and/or values of variables in your P4 program.  Each table can
  also have one or more _actions_ defined for them.
  * A P4 program represents only a small fraction of a complete
    working system.  Control plane software that would typically be
    running on a general purpose CPU, written in one or more general
    purpose programming languages like C, C++, Java, Python, etc.,
    is responsible for adding and removing entries to these tables,
    selecting for each entry the search key to be matched against,
    and the action to be executed if, while processing a packet,
    that table entry is matched.
* A P4_16 "architecture" like the [Portable Switch
  Architecture](https://p4.org/specs/) (PSA) also defines a library of
  other constructs, such as packet/byte counters, meters for enforcing
  average packet and/or bit rates on forwarded traffic, registers for
  some limited kinds of stateful packet processing, and methods for
  recirculating a packet, multicasting it to multiple destinations,
  etc.
* Fields and variables can be integers of arbitrary bit width (up to
  some maximum size allowed by a particular implementation), with
  results of arithmetic operations well defined for all operations.
  P4 implementations need not implement floating point arithmetic, and
  I expect most would not because such things are not needed for the
  majority of packet processing applications.  P4 implementations also
  need not implement multiplication, division, or modulo operations,
  again given that such operations are often not needed for most
  packet processing applications.
* Note that [integer arithmetic is sufficient for implementing fixed
  point operations](docs/floating-point-operations.md), because fixed
  point add/subtract/shift can be viewed as the corresponding
  operations on integers that are in smaller units, e.g. an integer
  could be used to represent time in multiples of 0.8 nanoseconds, as
  opposed to in units of nanoseconds, which would be convenient if an
  implementation had a clock speed of 1.25 GHz and measured time in
  integer number of clock cycles (1 cycle / 0.8 nanosec = 1.25 GHz).


## Very brief comparison of P4_14 and P4_16 languages

Some advantages of P4_16 over P4_14:

* You can write assignments that look like C/C++/Java, rather than
  `modify_field(dst, src);` all over the place, and you can have
  arithmetic expressions on the right-hand side instead of
  `add_to_field`/`subtract_from_field`/etc.  This is not additional
  power in the language, but it is a nice convenience for those
  familiar with those other languages.
* You may call controls from other controls in P4_14, but there are
  no parameters or return values.  All side effects must be done via
  access to global variables.  In P4_16, there are no global
  variables -- you may pass parameters with directionality `in`,
  `out`, `inout`.
* Tables must be, and externs may be, defined within the scope of a
  control, and are then accessible only from that control, which can
  be useful for keeping the code that accesses those objects closer
  to it, and knowing where they can be accessed from.  Externs are
  used for things like counters, meters, and registers that were
  part of the base P4_14 language, but in P4_16 are defined as
  extern add-ons in the Portable Switch Architecture specification).

Disadvantages of P4_16 vs P4_14:

* Tool and vendor support may not have been as good for P4_16 in 2018
  as it was for P4_14, but as of 2021, P4_16 is supported for most
  P4-programmable target devices.
