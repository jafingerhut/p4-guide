# Introduction

See [README-using-bmv2.md](../README-using-bmv2.md) for some things
that are common across different P4 programs executed using bmv2.

This article describes how to:

+ Run `p4testgen` to automatically generate test cases for a P4
  program, created in the form of a PTF test.
+ Run the generated PTF test.


To generate a collection of at most 10 test cases:

```bash
p4testgen --target bmv2 --arch v1model --max-tests 10 --out-dir out-p4testgen --test-backend ptf demo1.p4_16.p4
```

To run the generated PTF tests:

```bash
./p4testgen-runptf.sh
```
