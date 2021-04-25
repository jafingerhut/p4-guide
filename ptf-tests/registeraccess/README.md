# Introduction

The program `registeraccess.p4` and the PTF tests in
`registeraccess.py` demonstrate perhaps an unusual way to access a P4
register array from the controller: use `PacketOut` messages to inject
packets from the controller into the data plane, which are then
processed by the P4 program.  The P4 program is written so that at
least some such injected packets from the controller perform read or
write operations on a P4 register array, and send a packet back to the
controller.

The response packet is merely an acknowledgement message if the
injected packet performed a write on the P4 register array.  If a read
operation was performed on the P4 register array, the response packet
contains the value read from the P4 register array.

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


# Commands

In order for `PacketIn` and `PacketOut` messages from the controller
from/to the switch to work with `simple_switch_grpc`, you must start
it with the `--cpu-port` command line option.  The `registeraccess.py`
PTF test has been written assuming that the CPU port is number 510.
Here is a sample `simple_switch_grpc` command that you can use:

```bash
# compile P4 program, generating P4Info file and compiled program
$ p4c --target bmv2 --arch v1model --p4runtime-files registeraccess.p4info.txt registeraccess.p4

# Start simple_switch_grpc with CPU port equal to 510
$ sudo simple_switch_grpc --log-console -i 0@veth0 -i 1@veth2 -i 2@veth4 -i 3@veth6 -i 4@veth8 -i 5@veth10 -i 6@veth12 -i 7@veth14 --no-p4 --dump-packet-data 10000 -- --cpu-port 510
```

After that, the following command should give a successful PTF test run:

```bash
$ sudo ./runptf.sh
```
