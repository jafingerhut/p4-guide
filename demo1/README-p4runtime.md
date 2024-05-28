# Introduction

See [README-using-bmv2.md](../README-using-bmv2.md) for some things
that are common across different P4 programs executed using bmv2.

This article describes how to:

+ compile a simple demo P4 program using the `p4c` P4 compiler
+ execute the compiled program using the `simple_switch_grpc` software
  switch
+ add table entries to the running P4 program using the P4Runtime API
  message protocol, using a small library of Python code to help you.
+ send packets to the running P4 program using `scapy`.

If you are interested in an example automated test for the
`demo1.p4_16.p4` program that uses the PTF library, see
[README-ptf.md](README-ptf.md).


# Compiling

To compile the P4_16 version of the code, in file `demo1.p4_16.p4`:

    p4c --target bmv2 --arch v1model --p4runtime-files demo1.p4_16.p4info.txtpb demo1.p4_16.p4

Running that command will create these files:

    demo1.p4_16.p4i - the output of running only the preprocessor on
        the P4 source program.
    demo1.p4_16.json - the JSON file format expected by BMv2
        behavioral model `simple_switch_grpc`.
    demo1.p4_16.p4info.txtpb - the text format of the file that describes
        the P4Runtime API of the program.

Only the last two files are needed to run your P4 program.  You can
ignore the file with suffix `.p4i` unless you suspect that the
preprocessor is doing something unexpected with your program.

The P4Runtime API is targeted for use with P4_16.  I do not know of
any plans to make it work with P4_14 programs.

The .dot and .png files in the subdirectory 'graphs' were created with
the p4c-graphs program, which is also installed when you build and
install p4c:

     p4c-graphs -I $HOME/p4c/p4include demo1.p4_16.p4

The `-I` option is only necessary if you did _not_ install the P4
compiler in your system-wide /usr/local/bin directory.


# Running simple_switch_grpc

To run the behavioral model with 8 ports numbered 0 through 7:

    sudo simple_switch_grpc --log-console --dump-packet-data 10000 -i 0@veth0 -i 1@veth2 -i 2@veth4 -i 3@veth6 -i 4@veth8 -i 5@veth10 -i 6@veth12 -i 7@veth14 --no-p4

To get the log to go to a file instead of the console:

    sudo simple_switch_grpc --log-file ss-log --log-flush --dump-packet-data 10000 -i 0@veth0 -i 1@veth2 -i 2@veth4 -i 3@veth6 -i 4@veth8 -i 5@veth10 -i 6@veth12 -i 7@veth14 --no-p4

CHECK THIS: If you see "Add port operation failed" messages in the
output of the `simple_switch_grpc` command, it means that one or more
of the virtual Ethernet interfaces veth0, veth2, etc. have not been
created on your system.  Search for "veth" in the file
[`README-using-bmv2.md`](../README-using-bmv2.md`) (top level
directory of this repository) for a command to create them.

See the file
[`README-troubleshooting.md`](../README-troubleshooting.md) in case
you run into troubles.  It describes symptoms of some problems, and
things you can do to resolve them.


# Using a Python interactive session as a controller

To start an interactive Python session that can be used to load the
compiled P4 program into the running `simple_switch_grpc` process, and
install table entries:

```bash
cd p4-guide/demo1
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
# simple_switch_grpc process is listening for incoming TCP connections,
# over which a client program can send P4Runtime API messages to
# simple_switch_grpc.

my_dev1_addr='localhost:9559'
my_dev1_id=0
p4info_txt_fname='demo1.p4_16.p4info.txtpb'
p4prog_binary_fname='demo1.p4_16.json'
import p4runtime_sh.shell as sh

sh.setup(device_id=my_dev1_id,
         grpc_addr=my_dev1_addr,
         election_id=(0, 1), # (high_32bits, lo_32bits)
         config=sh.FwdPipeConfig(p4info_txt_fname, p4prog_binary_fname))
```

Advanced note #1 (i.e. you can skip on first reading and follow
everything below perfectly well): The `sh.setup` call shown above does
not use SSL authentication or encryption on the connection.  `setup`
can take an optional `ssl_options` parameter that lets the caller
supply the necessary cryptographic keys and certificates.  See TODO
for an example.

Advanced note #2: The `sh.setup` call will attempt to load a compiled
P4 program into the device if you provide the optional `config`
parameter as shown in the example above.  If you do not supply that
parameter, `sh.setup` will attempt to connect to the device and leave
whatever P4 program is loaded into it as it currently it (if there is
one).  Whether `sh.setup` loads a compiled P4 program into the device
or not, if it succeeds in connecting, the object `sh.context` is
initialized to contain information about the P4 objects such as
tables, actions, counters, meters, etc. that are part of the P4
program currently loaded in the device.  For example, evaluating
`list(sh.context.get_tables())` returns a Python list of one tuple per
P4 table in the currently loaded P4 program.  See TODO for more
examples.

Note: Unless the `simple_switch_grpc` process crashes, or you kill it
yourself, you can continue to use the same running process, loading
different compiled P4 programs into it over time.  Just do
`sh.tearDown()` to terminate the current P4Runtime API connection to
the device, and then perform `sh.setup` with the desired parameters to
connect again and load the desired compiled P4 program.

----------------------------------------------------------------------
demo1.p4_16.p4
----------------------------------------------------------------------

The full names of the tables and actions begin with 'ingress.' or
'egress.', but p4runtime-shell adds these prefixes for you, as long as
the table/action name is unique after that point.

Assign default actions for tables using an empty key, represented by
None in Python.

```python
te = sh.TableEntry('ipv4_da_lpm')(action='ingressImpl.my_drop', is_default=True)
te.modify()
te = sh.TableEntry('mac_da')(action='ingressImpl.my_drop', is_default=True)
te.modify()
te = sh.TableEntry('send_frame')(action='egressImpl.my_drop', is_default=True)
te.modify()
```

Define a few small helper functions that help add entries to tables
using Python API techniques provided by p4runtime-shell:

```python
def add_ipv4_da_lpm_entry_action_set_l2ptr(ipv4_addr_str, prefix_len_int, l2ptr_int):
    te = sh.TableEntry('ipv4_da_lpm')(action='set_l2ptr')
    # Note: p4runtime-shell raises an exception if you attempt to
    # explicitly assign to te.match['dstAddr'] a prefix with length 0.
    # Just skip assigning to te.match['dstAddr'] completely, and then
    # inserting the entry will give a wildcard match for that field,
    # as defined in the P4Runtime API spec.
    if prefix_len_int != 0:
        te.match['dstAddr'] = '%s/%d' % (ipv4_addr_str, prefix_len_int)
    te.action['l2ptr'] = '%d' % (l2ptr_int)
    te.insert()

def add_mac_da_entry_action_set_bd_dmac_intf(l2ptr_int, bd_int, dmac_str, intf_int):
    te = sh.TableEntry('mac_da')(action='set_bd_dmac_intf')
    te.match['l2ptr'] = '%d' % (l2ptr_int)
    te.action['bd'] = '%d' % (bd_int)
    te.action['dmac'] = dmac_str
    te.action['intf'] = '%d' % (intf_int)
    te.insert()

def add_send_frame_entry_action_rewrite_mac(out_bd_int, smac_str):
    te = sh.TableEntry('send_frame')(action='rewrite_mac')
    te.match['out_bd'] = '%d' % (out_bd_int)
    te.action['smac'] = smac_str
    te.insert()

add_ipv4_da_lpm_entry_action_set_l2ptr('10.1.0.1', 32, 58)
add_mac_da_entry_action_set_bd_dmac_intf(58, 9, '02:13:57:ab:cd:ef', 2)
add_send_frame_entry_action_rewrite_mac(9, '00:11:22:33:44:55')
```

Another set of table entries to forward packets to a different output
interface:

```python
add_ipv4_da_lpm_entry_action_set_l2ptr('10.1.0.200', 32, 81)
add_mac_da_entry_action_set_bd_dmac_intf(81, 15, '08:de:ad:be:ef:00', 4)
add_send_frame_entry_action_rewrite_mac(15, 'ca:fe:ba:be:d0:0d')
```

One way to read the entries of a table using `p4runtime-shell` is
shown below.  It will show the messages in a way similar to the text
format of Protobuf messages, but with extra string annotations on
fields such as `field_id` and `action_id` that show the names of these
things, for easier understanding by people.

```
te = sh.TableEntry('ipv4_da_lpm')
for x in te.read():
	print(x)
```

You can also examine the existing entries in a table using the
`simple_switch_CLI` command (best from a separate terminal window)
with the 'table_dump' command:

```bash
simple_switch_CLI
```

```
table_dump ipv4_da_lpm
==========
TABLE ENTRIES
**********
Dumping entry 0x0
Match key:
* ipv4.dstAddr        : LPM       0a010001/32
Action entry: set_l2ptr - 3a
**********
Dumping entry 0x1
Match key:
* ipv4.dstAddr        : LPM       0a0100c8/32
Action entry: set_l2ptr - 51
==========
Dumping default entry
Action entry: my_drop - 
==========
```

WARNING: Nothing in these programs will stop you from modifying the
table entries, or other switch state, from the `simple_switch_CLI`
program, but if you do so, you will likely cause state maintained by
the P4Runtime API to become stale with respect to what is in the
switch.  Don't do this unless you like causing yourself confusion.


----------------------------------------------------------------------
scapy session for sending packets
----------------------------------------------------------------------
Any process that you want to have permission to send and receive
packets on Ethernet interfaces (such as the veth virtual interfaces)
must run as the super-user root, hence the use of `sudo`:

```bash
$ sudo scapy
```

```python
fwd_pkt1=Ether() / IP(dst='10.1.0.1') / TCP(sport=5793, dport=80)
drop_pkt1=Ether() / IP(dst='10.1.0.34') / TCP(sport=5793, dport=80)

# Send packet at layer2, specifying interface
sendp(fwd_pkt1, iface="veth0")
sendp(drop_pkt1, iface="veth0")

fwd_pkt2=Ether() / IP(dst='10.1.0.1') / TCP(sport=5793, dport=80) / Raw('The quick brown fox jumped over the lazy dog.')
sendp(fwd_pkt2, iface="veth0")

# This packet will only be forwarded if you created the 'second set'
# of example table entries above (or your own, which this packet can
# match).
fwd_pkt3=Ether() / IP(dst='10.1.0.200') / TCP(sport=5793, dport=80)
sendp(fwd_pkt3, iface="veth0")
```

----------------------------------------


# Patterns

The example table entries and sample packet given above can be
generalized to the following pattern.

If you send an input packet like this, specified as Python code when
using the Scapy library:

    input port: anything
    Ether() / IP(dst=<hdr.ipv4.dstAddr>, ttl=<ttl>)

and you create the following table entries:

    table_add ipv4_da_lpm set_l2ptr <hdr.ipv4.dstAddr>/32 => <l2ptr>
    table_add mac_da set_bd_dmac_intf <l2ptr> => <out_bd> <dmac> <out_intf>
    table_add send_frame rewrite_mac <out_bd> => <smac>

then the P4 program should produce an output packet like the one
below, matching the input packet in every way except, except for the
fields explicitly mentioned:

    output port: <out_intf>
    Ether(src=<smac>, dst=<dmac>) / IP(dst=<hdr.ipv4.dstAddr>, ttl=<ttl>-1)


# Last successfully tested with these software versions

For https://github.com/p4lang/p4c

```
$ git log -n 1 | head -n 3
commit fcfb044b0070d78ee3a09bed0e26f3f785598f02
Author: Radostin Stoyanov <rstoyanov@fedoraproject.org>
Date:   Tue Dec 20 16:08:09 2022 +0000
```

For https://github.com/p4lang/behavioral-model

```
$ git log -n 1 | head -n 3
commit e97b6a8b4aec6da9f148326f7677f5e46b09e5ee
Author: Radostin Stoyanov <rstoyanov@fedoraproject.org>
Date:   Mon Dec 12 21:05:06 2022 +0000
```

For https://github.com/p4lang/PI

```
$ git log -n 1 | head -n 3
commit 21592d61b314ba0c44a7409a733dbf9e46da6556
Author: Antonin Bas <antonin.bas@gmail.com>
Date:   Tue Dec 20 12:45:36 2022 -0800
```
