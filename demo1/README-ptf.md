# Introduction

See [README-using-bmv2.md](../README-using-bmv2.md) for some things
that are common across different P4 programs executed using bmv2.

This article describes how to run an automated test of a P4 program
using a Python library called [`ptf`](https://github.com/p4lang/ptf)
for "Packet Test Framework"

As of 2021-Apr-05, this has only been tested to work on the following systems:

+ The Ubuntu 20.04 Desktop Linux VM available for download at [this
  link](https://drive.google.com/file/d/13SwWBEnApknu84fG9otwbL5NC78tut-d/view?usp=sharing),
  built from versions of the open source P4 development tools as of
  2021-Apr-05.
+ An Ubuntu 20.04 Desktop Linux system where all open source P4
  development tools have been installed using the script named
  [`install-p4dev-v4.sh` in this
  repository](../bin/README-install-troubleshooting.md), which
  installs all Python libraries for Python3, not Python2.


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
Server listening on 0.0.0.0:9559
/usr/local/lib/python3.8/dist-packages/ptf-0.9.1-py3.8.egg/EGG-INFO/scripts/ptf:19: DeprecationWarning: the imp module is deprecated in favour of importlib; see the module's documentation for alternative uses
  import imp
2021-12-31 14:10:28,701 - root - INFO - Importing platform: eth
2021-12-31 14:10:28,701 - root - DEBUG - Configuration: {'list': False, 'list_test_names': False, 'allow_user': False, 'test_spec': '', 'test_file': None, 'test_dir': 'ptf', 'test_order': 'default', 'test_order_seed': 2746, 'platform': 'eth', 'platform_args': None, 'platform_dir': '/usr/local/lib/python3.8/dist-packages/ptf-0.9.1-py3.8.egg/ptf/platforms', 'interfaces': [(0, 0, 'veth1'), (0, 1, 'veth3'), (0, 2, 'veth5'), (0, 3, 'veth7'), (0, 4, 'veth9'), (0, 5, 'veth11'), (0, 6, 'veth13'), (0, 7, 'veth15')], 'device_sockets': [], 'log_file': 'ptf.log', 'log_dir': None, 'debug': 'verbose', 'profile': False, 'profile_file': 'profile.out', 'xunit': False, 'xunit_dir': 'xunit', 'relax': False, 'test_params': "grpcaddr='localhost:9559';p4info='demo1.p4_16.p4rt.txt';config='demo1.p4_16.json'", 'failfast': False, 'fail_skipped': False, 'default_timeout': 2.0, 'default_negative_timeout': 0.1, 'minsize': 0, 'random_seed': None, 'disable_ipv6': False, 'disable_vxlan': False, 'disable_erspan': False, 'disable_geneve': False, 'disable_mpls': False, 'disable_nvgre': False, 'disable_igmp': False, 'disable_rocev2': False, 'qlen': 100, 'test_case_timeout': None, 'socket_recv_size': 4096, 'port_map': {(0, 0): 'veth1', (0, 1): 'veth3', (0, 2): 'veth5', (0, 3): 'veth7', (0, 4): 'veth9', (0, 5): 'veth11', (0, 6): 'veth13', (0, 7): 'veth15'}}
2021-12-31 14:10:28,703 - root - INFO - port map: {(0, 0): 'veth1', (0, 1): 'veth3', (0, 2): 'veth5', (0, 3): 'veth7', (0, 4): 'veth9', (0, 5): 'veth11', (0, 6): 'veth13', (0, 7): 'veth15'}
2021-12-31 14:10:28,703 - root - INFO - Autogen random seed: 94376873
2021-12-31 14:10:28,711 - root - INFO - *** TEST RUN START: Fri Dec 31 14:10:28 2021
demo1.FwdTest ... ok

----------------------------------------------------------------------
Ran 1 test in 1.089s

OK
demo1.PrefixLen0Test ... ok

----------------------------------------------------------------------
Ran 1 test in 2.593s

OK
demo1.DupEntryTest ... ok

----------------------------------------------------------------------
Ran 1 test in 0.044s

OK

PTF test finished.  Waiting 2 seconds before killing simple_switch_grpc ...

Verifying that there are no simple_switch_grpc processes running any longer in 4 seconds ...
./runptf.sh: line 69: 11317 Killed                  sudo simple_switch_grpc --log-file ss-log --log-flush --dump-packet-data 10000 -i 0@veth0 -i 1@veth2 -i 2@veth4 -i 3@veth6 -i 4@veth8 -i 5@veth10 -i 6@veth12 -i 7@veth14 --no-p4
andy       11370  0.0  0.0   9040   660 pts/0    S+   14:10   0:00 grep simple_switch

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
