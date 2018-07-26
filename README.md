# Introduction

This repository contains a variety of potentially useful information
for those wanting to work with the [P4 programming
language](http://p4.org).

Contents:

* An overview of the [p4lang organization Github
  repositories](README-p4lang-repos.md)
  * includes a small [shell script](bin/install-p4dev.sh) that
    installs both `p4c` and `behavioral-model` projects and their
    dependencies on an Ubuntu 16.04 Linux machine.
  * A figure with the [dependencies](dependencies.pdf) between
    these repositories.

* A collection of small [demo P4 programs](README-demos.md), some of
  them with equivalent versions written in both P4_14 and P4_16
  versions of the language.
  * includes a [heavily commented P4_16
    program](demo1/demo1-heavily-commented.p4_16.p4), which by reading
    carefully one may learn some things about the P4_16 language.
  * Each of the demo directories includes its own README.md file with
    instructions for compiling the program and running it with the
    `simple_switch` emulator from the `behavior_model` repository,
    including interactively adding table entries to the tables, and
    send packets using Scapy that will be processed by the emulator.

* [Instructions](README-editor-support.md) for setting up several text
  editing programs for color highlighting P4 programs, and quickly
  finding definitions for named things like control blocks and tables.

* 'Cheat sheet' of where P4_16 language constructs are allowed to be
  used within a program.
  * [figure](p4-16-allowed-constructs.pdf)
  * [text](p4-16-allowed-constructs.txt)

* A very brief overview of P4 (in about 500 words), to get a flavor
  for what it is like:
  * Start with C.
  * Remove loops, recursive calls, pointers, malloc, and free.  When
    your mind recovers from reeling over these drastic limitations,
    you will clearly realize that P4 is _not_ a general purpose
    programming language.  It was not designed to be.
    * Without loops or recursive calls, the work done per packet can
      be bounded at compilation time, which helps when targeting the
      highest performance P4-programmable devices.  Without pointers,
      malloc, and free, general purpose data structures like linked
      lists, trees, etc. having arbitrary size is not possible.
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
      are done processing it.  You can modify fields however you like.
  * Add special constructs called _tables_, where for each one you
    define a search key consisting of a number of packet header fields
    and/or values of variables in your P4 program.  Each table can
    also have one or more _actions_ defined for them.
    * A P4 program represents only a small fraction of a complete
      working system.  Control plane software that would typically be
      running on a general purpose CPU, written in one or more general
      purpose programmling languages like C, C++, Java, Python, etc.,
      is responsible for adding and removing entries to these tables,
      selecting for each entry the search key to be matched against,
      and the action to be executed if, while processing a packet,
      that table entry is matched.
  * A P4_16 "architecture" like the Portable Switch Architecture (PSA)
    also defines a library of other constructs, such as packet/byte
    counters, meters for enforcing average packet and/or bit rates on
    forwarded traffic, registers for some limited kinds of stateful
    packet processing, and methods for recirculating a packet,
    multicasting it to multiple destinations, etc.
  * Fields and variables can be integers of arbitrary bit width (up to
    some maximum size allowed by a particular implementation), with
    results of arithmetic operations well defined for all operations.
    P4 implementations need not implement floating point arithmetic,
    and I expect most would not because such things are not needed for
    the majority of packet processing applications.  P4
    implementations also need not implement multiplication, division,
    or modulo operations, again given that such operations are often
    not needed for most packet processing applications.

* Some advantages of P4_16 over P4_14:
  * You can write assignments that look like C/C++/Java, rather than
    modify_field(dst, src); all over the place, and you can have
    arithmetic expressions on the right-hand side instead of
    add_to_field/subtract_from_field/etc.  This is not additional
    power in the language, but it is a nice convenience for those
    familiar with those other languages.
  * Controls could call other controls in P4_14, but there were no
    parameters or return values.  All side effects had to be done via
    access to global variables.  In P4_16, there are no global
    variables -- you may pass parameters with directionality in, out,
    inout.
  * Tables must be, and externs may be, defined within the scope of a
    control, and are then accessible only from that control, which can
    be useful for keeping the code that accesses those objects closer
    to it, and knowing where they can be accessed from.  Extern are
    used for things like counters, meters, and registers that were
    part of the base P4_14 language, but in P4_16 are defined as
    extern add-ons in the Portable Switch Architecture specification).
* Disadvantages of P4_16 vs P4_14:
  * Tool and vendor support it not as good for P4_16 as of Jan 2018,
    but this is gradually changing.
