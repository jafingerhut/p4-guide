# Introduction

Note that in order for PacketIn and PacketOut messages from the
controller from/to the switch to work with `simple_switch_grpc`, you
must start it with the `--cpu-port` command line option.  The
`packetinout.py` PTF test has been written assuming that the CPU port
is number 510.  Here is a copy of the `simple_switch_grpc` command
line options used by the script `runptf.sh` (you need not enter this
command yourself if you run `runptf.sh`):

```bash
# Start simple_switch_grpc with CPU port equal to 510
$ sudo simple_switch_grpc --log-console -i 0@veth0 -i 1@veth2 -i 2@veth4 -i 3@veth6 -i 4@veth8 -i 5@veth10 -i 6@veth12 -i 7@veth14 --no-p4 --dump-packet-data 10000 -- --cpu-port 510
```


# Notes on the CPU port, PacketIn and PacketOut messages, and controller metadata

You _MUST NOT_ associate the CPU port number with an interface,
i.e. it would cause problems if you added a command line option
`-i 510@veth16` to the example command line above.  The CPU port is
special in that effectively one end is connected to the BMv2 switch
on the CPU port, and the other end is always connected to the
P4Runtime API server code that runs within the `simple_switch_grpc`
process.

All packets sent by your P4 code to the CPU port go to this P4Runtime
API server, are sent via a `PacketIn` message from the server to your
controller (which is a P4Runtime API client) over the P4Runtime API
gRPC connection, and become `PacketIn` messages to your controller
program.  The controller metadata header, if you have one, must be the
_first_ header when the packet is sent to the CPU port by your P4
program.

All `PacketOut` messages from your controller program go over the
P4Runtime API grPC connection to the P4Runtime API server code running
inside of the `simple_switch_grpc` process, and are then sent into the
CPU port for your P4 program to process.  The controller metadata
header, if any, will always be the _first_ header of the packet as
seen by your P4 parser.


# Commands

By running this command in this directory:

```bash
$ ./runptf.sh
```

that script does all of these things for you:

+ Compiles the P4 program `packetinout.p4`, generating the necessary
  P4Info file and compiled BMv2 JSON file
+ Starts running `simple_switch_grpc` as root, with logging output
  being written to a file name `ss-log.txt`, and a CPU port with port
  number 510
+ Runs the PTF test in file `packetinout.py`
+ Kills the `simple_switch_grpc` process

You must still create the necessary virtual Ethernet interfaces before
running `runptf.sh`.  See
[README-using-bmv2.md](../../README-using-bmv2.md) for how to do so.
