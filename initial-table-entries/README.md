# Introduction

This directory contains a simple test case to illustrate that the
"initial table entries" feature is not completely implemented in the
BMv2 software switch `simple_switch_grpc`.

Prerequisites: You must first run this command before any of the other
comamnds mentioned below:

```bash
sudo ../bin/veth_setup.sh
```


## `const enries` is implemented properly

The program `const-entries-bmv2.p4` has a single table `t1` that
defines two entries using the `const entries` table property.  This
has worked for several years now in open source P4 development tools,
including `simple_switch_grpc`.

If you run:

```bash
./const-entries-runptf.sh
```

It will compile the program, and run a simple PTF test that sends no
packets, but simply reads all entries from table `t1` and shows them
on the terminal.  This shows the 2 entries, as it should.


## `enries` without `const` is not implemented properly

The program `init-entries-bmv2.p4` is identical to
`const-entries-bmv2.p4`, except it has `entries`, without `const`
before it.  The table entries defined in this way should be installed
in the table when the P4 program is loaded, but the control plane
should be able to modify or delete them afer the program is loaded.

If you run:

```bash
./init-entries-runptf.sh
```

It will compile the program, and run a simple PTF test that sends no
packets, but simply reads all entries from table `t1` and shows them
on the terminal.  This gives an error when trying to read the entries,
which is a bug in the implementation.
