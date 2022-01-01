# Introduction

This P4 program written using the v1model architecture has one table
with the property `support_timeout` with a value of `true`, which
means that after a table entry is added, the switch should maintain a
per-entry timer value of how long it has been since the last time it
was matched, and if it has ever been more than a configurable amount
of time since the entry was added or last matched (whichever is
later), the switch will generate an idle timeout notification message
to the controller.

For details regarding the specified behavior of idle timeouts for the
P4Runtime API controller-to-switch protocol, see the [section named
"Idle-timeout"](https://p4.org/p4-spec/p4runtime/v1.3.0/P4Runtime-Spec.html#sec-idle-timeout)
in the P4Runtime specification.


# Commands

By running this command in this directory:

```bash
$ ./runptf.sh
```

that script does all of these things for you:

+ Compiles the P4 program idletimeout.p4, generating the necessary
  P4Info file and compiled BMv2 JSON file
+ Starts running simple_switch_grpc as root, with logging output being
  written to a file name `ss-log.txt`
+ Runs the PTF test in file idletimeout.py
+ Kills the simple_switch_grpc process

You must still create the necessary virtual Ethernet interfaces before
running `runptf.sh`.  See
[README-using-bmv2.md](../../README-using-bmv2.md) for how to do so.
