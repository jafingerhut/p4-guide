# Introduction

Note that in order for PacketIn and PacketOut messages from the
controller from/to the switch to work with `simple_switch_grpc`, you
must start it with the `--cpu-port` command line option.  The
`packetinout.py` PTF test has been written assuming that the CPU port
is number 510.  Here is a sample `simple_switch_grpc` command that you
can use:

```bash
# compile P4 program, generating P4Info file and compiled program
$ p4c --target bmv2 --arch v1model --p4runtime-files packetinout.p4info.txt packetinout.p4

# Start simple_switch_grpc with CPU port equal to 510
$ sudo simple_switch_grpc --log-console -i 0@veth0 -i 1@veth2 -i 2@veth4 -i 3@veth6 -i 4@veth8 -i 5@veth10 -i 6@veth12 -i 7@veth14 --no-p4 --dump-packet-data 10000 -- --cpu-port 510
```

After that, the following command should give a successful PTF test run:

```bash
$ sudo ./runptf.sh
```
