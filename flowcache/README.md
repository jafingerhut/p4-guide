# Introduction

The P4 program `flowcache.p4` is a very simple "toy" P4 program to
demonstrate how a P4 program can "punt" packets to a P4Runtime
controller using the PacketIn mechanism, and the controller can
respond to receiving such packets by adding entries to a table.

There are many useful things that this demonstration does _not_ do,
e.g. it does not keep statistics of forwarded packets, or number of
table entries added.  It does not use the idle timeout mechanism to
detect when entries added to the table `flow_cache` have been
unmatched for a long time, and notify the controller to delete those
stale entries.


# Instructions for use

Set up some environment variables needed for the commands below to
succeed.  This needs to be done in each terminal window you create:

```bash
export P4GUIDE="$HOME/p4-guide"
export PYPKG_TESTLIB="$P4GUIDE/testlib"
```

Replace the example file path above in the first line with the path to
the directory `p4-guide` that is your copy of the `p4-guide`
repository, if it is different than the example.

Compile the P4 program with the command:

```bash
make compile
```

Start the BMv2 software switch with:

```bash
sudo $P4GUIDE/bin/veth_setup.sh
make runswitch
```

Leave the switch running in the terminal where you started it, and use
separate terminal windows for the commands below.

Load the compiled P4 program into the switch with:

```bash
make loadp4prog
```

Run the controller:

```bash
make runcontroller
```

Leave the controller running in the terminal where you started it, and
use separate terminal windows for the commands below.

The P4 program and controller are up and running now.

All instructions below are completely optional, simply shown as _one
way_ to exercise the system.

Send a packet from an interactive Python session using the Scapy
library:

```bash
$ sudo PATH=$PATH VIRTUAL_ENV=$VIRTUAL_ENV python3
Python 3.8.10 (default, Nov 22 2023, 10:22:35) 
[GCC 9.4.0] on linux
Type "help", "copyright", "credits" or "license" for more information.
>>> 
```

Inside that interactive Python session:

```python
from scapy.all import *
pkt1=Ether()/IP()
pkt2=Ether()/IP(src='10.0.1.1',dst='10.0.2.2')/TCP()
sendp(pkt1,iface='veth2')
```

Within 5 seconds you should see a message like this in the terminal
where the controller is running, indicating that the controller got a
PacketIn message from the switch, and reacted by adding a table entry
to the P4 table named `flow_cache`:

```
2024-03-11 16:54:01,948 - root - INFO - For flow (SA=127.0.0.1, DA=127.0.0.1, proto=0) added table entry to send packets to port 1 with new DSCP 5
```

After that, any packet sent with the same IPv4 source address,
destination address, and protocol should match that table entry, and
be forwarded to the port number given in the controller message.

To try with a packet with a different value for those 3 fields:

```python
sendp(pkt2,iface='veth4')
```

You can use Ctrl-C in the terminal where the controller is running to
quit it.  You may need to type Ctrl-C twice to actually terminate it.
Similarly for the terminal where the switch is running.
