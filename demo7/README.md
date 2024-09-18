# Introduction

See [README-using-bmv2.md](../README-using-bmv2.md) for some things
that are common across different P4 programs executed using bmv2.

This example program and instructions below demonstrate how to
configure multicast groups from the P4Runtime API, and process packets
that are multicast replicated in the traffic manager before egress
processing is done independently for each packet copy created.


# Compiling

To compile the P4_16 version of the code:

    p4c --target bmv2 --arch v1model --p4runtime-files demo7.p4info.txtpb demo7.p4
                                                                        ^^^^^^^^ source code

If you see an error message about `mark_to_drop: Passing 1 arguments
when 0 expected`, then see
[`README-troubleshooting.md`](../README-troubleshooting.md#compiler-gives-error-message-about-mark_to_drop)
for what to do.

Running that command will create these files:

    demo7.p4i - the output of running only the preprocessor on the P4
        source program.
    demo7.json - the JSON file format expected by BMv2 behavioral
        model `simple_switch_grpc`.
    demo7.p4info.txtpb - the text format of the file that describes
        the P4Runtime API of the program.

Only the last two files are needed to run your P4 program.  You can
ignore the file with suffix `.p4i` unless you suspect that the
preprocessor is doing something unexpected with your program.

There is no P4_14 version of this program.  There is no particular
reason why not, other than lack of interest on my part in writing one.
It should be straightfoward to write one if you have seen how the
P4_14 and P4_16 versions of other demo programs like demo1 and demo2
are related to each other.


# Running simple_switch_grpc

See the section with this name in
[`../demo1/README-p4runtime.md`](../demo1/README-p4runtime.md).


# Running automated test using PTF

See the [demo1 PTF README](../demo1/README-ptf.md) for which systems
on which this has been tested as working.

By running this command in this directory:

```bash
$ ./runptf.sh
```

that script does all of these things for you:

+ Compiles the P4 program demo7.p4, generating the necessary
  P4Info file and compiled BMv2 JSON file
+ Starts running simple_switch_grpc as root, with logging output being
  written to a file name `ss-log.txt`
+ Runs the PTF test in file ptf/demo7.py
+ Kills the simple_switch_grpc process

You must still create the necessary virtual Ethernet interfaces before
running `runptf.sh`.  See
[README-using-bmv2.md](../../README-using-bmv2.md) for how to do so.

See the "Running the PTF test ..." section
[here](../demo1/README-ptf.md) for some description of what the output
of a successful PTF test run looks like.


# Using a Python interactive session as a controller

To start an interactive Python session that can be used to load the
compiled P4 program into the running `simple_switch_grpc` process, and
install table entries:

```bash
cd p4-guide/demo7
export PYTHONPATH="`realpath ../testlib`:$PYTHONPATH"
python3
```

NOTE: For most interactive Python sessions, typing Ctrl-D or the
command `quit()` is enough to quit Python and go back to the shell.
For this Python session, one or more of the commands below cause this
interactive session to 'hang' if you try that.  In the most commonly
used Linux/OSX shells you can type Ctrl-Z to put the Python process in
the background and return to the shell prompt.  You may want to kill
the process, e.g. using `kill -9 %1` in bash.

Enter these commands at the `>>> ` prompt of the Python session:

```python
# Note: 9559 is the default TCP port number on which the
# simple_switch_grpc process is listening for P4Runtime API control
# connections.

my_dev1_addr='localhost:9559'
my_dev1_id=0
p4info_txt_fname='demo7.p4info.txtpb'
p4prog_binary_fname='demo7.json'
import p4runtime_sh.shell as sh

sh.setup(device_id=my_dev1_id,
         grpc_addr=my_dev1_addr,
         election_id=(0, 1), # (high_32bits, lo_32bits)
         config=sh.FwdPipeConfig(p4info_txt_fname, p4prog_binary_fname))
```

Note: Unless the `simple_switch_grpc` process crashes, or you kill it
yourself, you can continue to use the same running process, loading
different compiled P4 programs into it over time.  Just do
`sh.tearDown()` to terminate the current P4Runtime API connection to
the device, and then perform `sh.setup` with the desired parameters to
connect again and load the desired compiled P4 program.

The full names of the tables and actions begin with 'ingress.' or
'egress.', but `p4runtime-shell` adds these prefixes for you, as long
as the table/action name is unique after that point.

The tables all have `const default_action = <action_name>` in the
P4_16 program, so the control plane is not allowed to change them.  Do
not try.  I have, and you get an appropriate error message if you try.

Define a few small helper functions that help add entries to tables
using Python API techniques provided by p4runtime-shell:

```python
def add_ipv4_mc_route_lookup_entry_action_set_mcast_grp(ipv4_addr_str,
                                                        prefix_len_int,
                                                        mcast_grp_int):
    te = sh.TableEntry('ipv4_mc_route_lookup')(action='set_mcast_grp')
    # Note: p4runtime-shell raises an exception if you attempt to
    # explicitly assign to te.match['dstAddr'] a prefix with length 0.
    # Just skip assigning to te.match['dstAddr'] completely, and then
    # inserting the entry will give a wildcard match for that field,
    # as defined in the P4Runtime API spec.
    if prefix_len_int != 0:
        te.match['dstAddr'] = '%s/%d' % (ipv4_addr_str, prefix_len_int)
    te.action['mcast_grp'] = '%d' % (mcast_grp_int)
    te.insert()

def add_ipv4_da_lpm_entry_action_set_l2ptr(ipv4_addr_str, prefix_len_int,
                                           l2ptr_int):
    te = sh.TableEntry('ipv4_da_lpm')(action='set_l2ptr')
    if prefix_len_int != 0:
        te.match['dstAddr'] = '%s/%d' % (ipv4_addr_str, prefix_len_int)
    te.action['l2ptr'] = '%d' % (l2ptr_int)
    te.insert()

def add_mac_da_entry_action_set_dmac_intf(l2ptr_int, dmac_str, intf_int):
    te = sh.TableEntry('mac_da')(action='set_dmac_intf')
    te.match['l2ptr'] = '%d' % (l2ptr_int)
    te.action['dmac'] = dmac_str
    te.action['intf'] = '%d' % (intf_int)
    te.insert()

def add_send_frame_entry_action_rewrite_mac(eg_port_int, smac_str):
    te = sh.TableEntry('send_frame')(action='rewrite_mac')
    te.match['egress_port'] = '%d' % (eg_port_int)
    te.action['smac'] = smac_str
    te.insert()

add_ipv4_mc_route_lookup_entry_action_set_mcast_grp('224.3.3.3', 32, 91)

add_ipv4_da_lpm_entry_action_set_l2ptr('10.1.0.1', 32, 58)
add_mac_da_entry_action_set_dmac_intf(58, '02:13:57:ab:cd:ef', 2)

add_send_frame_entry_action_rewrite_mac(0, '00:de:ad:00:00:ff')
add_send_frame_entry_action_rewrite_mac(1, '00:de:ad:11:11:ff')
add_send_frame_entry_action_rewrite_mac(2, '00:de:ad:22:22:ff')
add_send_frame_entry_action_rewrite_mac(3, '00:de:ad:33:33:ff')
add_send_frame_entry_action_rewrite_mac(4, '00:de:ad:44:44:ff')
add_send_frame_entry_action_rewrite_mac(5, '00:de:ad:55:55:ff')
```

When a packet is sent from ingress to the packet buffer with
mcast_grp=91, configure the (egress_port, instance) places to which
the packet will be copied.

In the list of 2-tuples below, the first element of each tuple is the
egress port to which the copy should be sent, and the second is the
"replication id", also called `egress_rid` in the P4_16 v1model
architecture `standard_metadata_t` struct, or `instance` in the P4_16
PSA architecture `psa_egress_input_metadata_t` struct, and also called
`instance` in the P4Runtime API `Replica` message.  This value can be
useful if you want to send multiple copies of the same packet out of
the same output port, but want each one to be processed differently
during egress processing.  If you want that, put multiple pairs with
the same egress port in the replication list, but each with a
different value of "replication id".

```python
mcg = sh.MulticastGroupEntry(91)
for x in [(2, 5), (5, 75), (1, 111)]:
    mcg.add(x[0], x[1])

mcg.insert()
```

The following Python code can be used to read a multicast group entry
from the switch using P4Runtime API, and to select and print values of
individual parts of the response:

```python
mcgroups = sh.MulticastGroupEntry(91)
group_lst = []
for mcgroup in mcgroups.read():
    group_lst.append(mcgroup)

print(group_lst)

for group in group_lst:
    print("group_id: %d" % (group.group_id))
    for replica in group.replicas:
        print("    egress_port: %d  instance: %d"
              "" % (replica.egress_port, replica.instance))

```

You may also use the following `simple_switch_CLI` commands in a
separate terminal window to read table entries and/or the multicast
configuration state.

```bash
simple_switch_CLI
```

At the `simple_switch_CLI` prompt `RuntimeCmd: `, type the command
`mc_dump` to see output like this:

```
RuntimeCmd: mc_dump
==========
MC ENTRIES
**********
mgrp(91)
  -> (L1h=0, rid=111) -> (ports=[1], lags=[])
  -> (L1h=1, rid=75) -> (ports=[5], lags=[])
  -> (L1h=2, rid=5) -> (ports=[2], lags=[])
==========
LAGS
==========
```

The `mgrp(91)` shows the `mcast_grp` value of 91 configured above.
Each of the next 3 lines of output below that show a list of ports,
one line for each replication id value.  I do not know precisely what
the `L1h` values represent.  Likely they are unique id values selected
inside of `simple_switch_grpc` controller interface code for
identifying parts of the multicast group configuration.  I believe
they are invisible to the P4Runtime API, and a P4Runtime controller
need not concern itself with them.


# Scapy session for sending packets

```bash
$ sudo PATH=$PATH VIRTUAL_ENV=$VIRTUAL_ENV python3
```

The packet below should match the example table entry created above in
the `ipv4_mc_route_lookup` table, finish its ingress processing with
`standard_metadata.mcast_grp` equal to 91, and be replicated to the 3
configured output ports.

```python
from scapy.all import *
pkt1=Ether(src='00:00:c0:01:d0:0d', dst='ff:ff:ff:ff:ff:ff') / IP(src='10.2.3.5', dst='224.3.3.3') / UDP()
sendp(pkt1, iface='veth0')
```


# Last successfully tested with these software versions

For https://github.com/p4lang/p4c

```
$ git log -n 1 | head -n 3
commit b90f777a8f77fea209f61a964fd9e1c180df644e
Author: Anton Korobeynikov <anton@korobeynikov.info>
Date:   Mon Sep 16 01:26:59 2024 -0700
```

For https://github.com/p4lang/behavioral-model

```
$ git log -n 1 | head -n 3
commit 199af48e04ea8747f8296bdc51c2ce16bb96cb04
Author: Jiwon Kim <kim1685@purdue.edu>
Date:   Wed Sep 11 12:05:33 2024 -0400
```

For https://github.com/p4lang/PI

```
$ git log -n 1 | head -n 3
commit 5eae9c84d7a55f9554775e498b9146f67eac7bd4
Author: Davide Scano <d.scano89@gmail.com>
Date:   Mon Aug 26 16:47:51 2024 -0500
```
