# Introduction

This directory contains some test P4 programs that test edge cases for
P4 tables that have one or more actions that can invoke the `exit`
statement.

When combined with calls to `t1.apply().hit` and/or `t1.apply().miss`
on tables with such actions, the P4 language spec provides (I believe)
precise rules to indicate exactly which sub-expressions are evaluated,
vs. which are not.

To compile and generate test cases with p4testgen, but _not_ run them:
```bash
# To compile all test programs
make all

# To compile only one:
make exit-1-bmv2.p4i
make exit-2-bmv2.p4i
```

To compile, generate test cases with p4testgen, and run them on BMv2:
```bash
./p4testgen-runptf.sh exit-1-bmv2.p4
./p4testgen-runptf.sh exit-2-bmv2.p4
```
