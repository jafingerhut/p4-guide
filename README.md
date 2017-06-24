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
