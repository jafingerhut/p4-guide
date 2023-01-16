# Introduction

See [README-using-bmv2.md](../README-using-bmv2.md) for some things
that are common across different P4 programs executed using bmv2.

This article describes how to run an automated test of a P4 program
using a Python library called [`ptf`](https://github.com/p4lang/ptf)
for "Packet Test Framework"

As of 2022-Dec-01, this has been tested to work on any system with P4
software installed on it following the instructions on [this
page](../bin/README-install-troubleshooting.md).


# Compiling the P4 program, and running simple_switch_grpc

These can be done using the same commands described in the [demo1
P4Runtime README](README-p4runtime.md).  The script `runptf.sh` in
this directory will run `p4c` and `simple_switch_grpc` with
appropriate command line arguments for you, so you need not run them
yourself.


# Running the PTF test and understanding the output

The script `runptf.sh` also starts the `ptf` command with a mapping
between switch port numbers and Linux interface names that is similar
to, but not identical with, the mapping given when starting the
`simple_switch_grpc` process.  It assumes that `veth0` and `veth1` are
a linked pair of virtual Ethernet interfaces, such that sending a
packet to one will always be transmitted to the other one of the pair,
and also `veth2` and `veth3` are a linked pair, etc. exactly as the
`veth_setup.sh` script in this repository creates them.

To run the automated tests:
```bash
./runptf.sh
```

If successful, you will see output in the terminal similar to this:
```
$ ./runptf.sh

Started simple_switch_grpc.  Waiting 2 seconds before starting PTF test ...
Calling target program-options parser
Adding interface veth0 as port 0
Adding interface veth2 as port 1
Adding interface veth4 as port 2
Adding interface veth6 as port 3
Adding interface veth8 as port 4
Adding interface veth10 as port 5
Adding interface veth12 as port 6
Adding interface veth14 as port 7
/usr/local/lib/python3.8/dist-packages/ptf-0.9.3-py3.8.egg/EGG-INFO/scripts/ptf:19: DeprecationWarning: the imp module is deprecated in favour of importlib; see the module's documentation for alternative uses
  import imp
2023-01-09 21:56:37,569 - root - INFO - Importing platform: eth
2023-01-09 21:56:37,569 - root - INFO - port map: {(0, 0): 'veth1', (0, 1): 'veth3', (0, 2): 'veth5', (0, 3): 'veth7', (0, 4): 'veth9', (0, 5): 'veth11', (0, 6): 'veth13', (0, 7): 'veth15'}
2023-01-09 21:56:37,569 - root - INFO - Autogen random seed: 41683488
2023-01-09 21:56:37,570 - root - INFO - *** TEST RUN START: Mon Jan  9 21:56:37 2023
demo1.FwdTest ... ok

----------------------------------------------------------------------
Ran 1 test in 0.954s

OK
demo1.PrefixLen0Test ... ok

----------------------------------------------------------------------
Ran 1 test in 2.484s

OK
demo1.DupEntryTest ... ok

----------------------------------------------------------------------
Ran 1 test in 0.030s

OK
Using packet manipulation module: ptf.packet_scapy
field_id: 1
lpm {
  value: "\n\001\000\001"
  prefix_len: 32
}

param_id: 1
value: ":"

field_id: 1
exact {
  value: ":"
}

param_id: 1
value: "\t"

param_id: 2
value: "\002\023W\253\315\357"

param_id: 3
value: "\002"

field_id: 1
exact {
  value: "\t"
}

param_id: 1
value: "\021\"3DU"

field_id: 1
lpm {
  value: "\n\001\000\001"
  prefix_len: 32
}

param_id: 1
value: ":"

field_id: 1
exact {
  value: ":"
}

param_id: 1
value: "\t"

param_id: 2
value: "\002\023W\253\315\357"

param_id: 3
value: "\002"

field_id: 1
exact {
  value: "\t"
}

param_id: 1
value: "\021\"3DU"

field_id: 1
lpm {
  value: "\n\001\000\000"
  prefix_len: 16
}

param_id: 1
value: ";"

field_id: 1
exact {
  value: ";"
}

param_id: 1
value: "\n"

param_id: 2
value: "\002\023W\253\315\360"

param_id: 3
value: "\003"

field_id: 1
exact {
  value: "\n"
}

param_id: 1
value: "\021\"3DV"

param_id: 1
value: "<"

field_id: 1
exact {
  value: "<"
}

param_id: 1
value: "\013"

param_id: 2
value: "\002\023W\253\315\361"

param_id: 3
value: "\004"

field_id: 1
exact {
  value: "\013"
}

param_id: 1
value: "\021\"3DW"

field_id: 1
lpm {
  value: "\n\000\000\001"
  prefix_len: 32
}

param_id: 1
value: ":"

field_id: 1
lpm {
  value: "\n\000\000\001"
  prefix_len: 32
}

param_id: 1
value: ":"

Exception ignored in: <function EventDescriptor.__del__ at 0x7f061b71c790>
Traceback (most recent call last):
  File "/usr/local/lib/python3.8/dist-packages/ptf-0.9.3-py3.8.egg/ptf/ptfutils.py", line 56, in __del__
AttributeError: 'NoneType' object has no attribute 'close'

PTF test finished.  Waiting 2 seconds before killing simple_switch_grpc ...

Verifying that there are no simple_switch_grpc processes running any longer in 4 seconds ...
./runptf.sh: line 69: 35459 Killed                  sudo simple_switch_grpc --log-file ss-log --log-flush --dump-packet-data 10000 -i 0@veth0 -i 1@veth2 -i 2@veth4 -i 3@veth6 -i 4@veth8 -i 5@veth10 -i 6@veth12 -i 7@veth14 --no-p4
andy       35517  0.0  0.0  17672   648 pts/3    S+   21:56   0:00 grep simple_switch
```

The line `demo1.FwdTest ... ok` indicates that a test named `FwdTest`
was run, and it passed, i.e. no failures that it checks for were
detected, and similarly the line `demo1.PrefixLen0Test ... ok`
indicates that a test named `PrefixLen0Test` passed, and similarly for
`demo1.DupEntryTest`.

You can see the Python code for what these automated tests do in the
file [`ptf/demo1.py`](ptf/demo1.py).  Some comments there may be
useful in finding documentation for many of the functions and methods
used in that test program.

Besides the few log messages that appear on the terminal, and the file
`ss-log.txt` where `simple_switch_grpc` writes its detailed log
messages from executing the P4 code, running the tests also causes the
following files to be written:

+ `ptf.log` - Log messages generated by some functions in the `ptf`
  library, mingled with showing when each test case starts and ends.
  This can be very handy when developing new test scripts, to see what
  is going on in more detail.  Adding your own `print` and
  `logging.debug` calls to the Python test program is also useful for
  this.
+ `ptf.pcap` - A pcap file that can be read like any other.  There is
  a header _before_ the Ethernet header recorded in this pcap file
  that records the port number that the packets were recorded passing
  over.  Packets sent and received on all switch ports are recorded in
  this same file, mingled together.
