# Introduction

The program `registeraccess.p4` and the PTF tests in
`registeraccess.py` demonstrate perhaps an unusual way to access a P4
register array from the controller, which is to use `PacketOut`
messages to inject packets from the controller into the data plane,
which are then processed by the P4 program.  The P4 program is written
so that at least some such injected packets from the controller
perform read or write operations on a P4 register array, and send a
packet back to the controller.

The response packet is merely an acknowledgement message if the
injected packet performs a write to the P4 register array.  If the
packet performs a read operation from the P4 register array, the
response packet contains the value read.

Why do this?

One unfortunate reason is that at least in the open source P4
development tools, read and write operations to P4 register arrays
from the control plane are not yet fully implemented:
https://github.com/p4lang/PI/issues/376

A more interesting reason to use this method is if you want to perform
multiple operations on multiple P4 register arrays, or other P4
externs, in such a way that they happen "between" processing other
received data packets, effectively atomically, and/or you want to do
an operation other than merely reading or writing a value.

See
[here](../packetinout/README.md#notes-on-the-cpu-port-packetin-and-packetout-messages-and-controller-metadata)
for notes on the CPU port, `PacketIn` and `PacketOut` messages, and
controller metadata.


# Commands

In order for `PacketIn` and `PacketOut` messages from the controller
from/to the switch to work with `simple_switch_grpc`, you must start
it with the `--cpu-port` command line option.  The `registeraccess.py`
PTF test has been written assuming that the CPU port is number 510.

By running this command in this directory:

```bash
$ ./runptf.sh
```

that script does all of these things for you:

+ Compiles the P4 program registeraccess.p4, generating the necessary
  P4Info file and compiled BMv2 JSON file
+ Starts running simple_switch_grpc as root, with logging output being
  written to a file name `ss-log.txt`, and a CPU port with port number
  510
+ Runs the PTF test in file registeraccess.py
+ Kills the simple_switch_grpc process

You must still create the necessary virtual Ethernet interfaces before
running `runptf.sh`.  See
[README-using-bmv2.md](../../README-using-bmv2.md) for how to do so.
