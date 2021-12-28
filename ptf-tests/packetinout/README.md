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

By running this command in this directory:

```bash
$ ./runptf.sh
```

that script does all of these things for you:

+ Compiles the P4 program packetinout.p4, generating the necessary
  P4Info file and compiled BMv2 JSON file
+ Starts running simple_switch_grpc as root, with logging output being
  written to a file name `ss-log.txt`, and a CPU port with port number
  510
+ Runs the PTF test in file packetinout.py
+ Kills the simple_switch_grpc process

You must still create the necessary virtual Ethernet interfaces before
running `runptf.sh`.  See
[README-using-bmv2.md](../../README-using-bmv2.md) for how to do so.
