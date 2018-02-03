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
