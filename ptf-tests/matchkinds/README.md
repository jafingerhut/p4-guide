# Introduction

By running this command in this directory:

```bash
$ ./runptf.sh
```

that script does all of these things for you:

+ Compiles the P4 program matchkinds.p4, generating the necessary
  P4Info file and compiled BMv2 JSON file
+ Starts running simple_switch_grpc as root, with logging output being
  written to a file name `ss-log.txt`
+ Runs the PTF test in file matchkinds.py
+ Kills the simple_switch_grpc process

You must still create the necessary virtual Ethernet interfaces before
running `runptf.sh`.  See
[README-using-bmv2.md](../../README-using-bmv2.md) for how to do so.
