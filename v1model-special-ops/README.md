# Introduction

The program `v1model-special-ops.p4` demonstrates the use of resubmit,
recirculate, clone, and multicast replication operations in the BMv2
simple_switch's implementation of P4_16's v1model architecture.  It
does not do anything fancy with these features, but at least it shows
how to distinguish whether a packet being processed in the ingress
control block is the result of a resubmit or recirculate operation,
vs. a new packet received from an ingress port.  Similarly whether a
packet being processed in the egress control block is the result of a
clone operation.

It also demonstrates "debug tables".  When you use the `--log-console`
or `--log-file` command line options to the `simple_switch` command,
then whenever _any_ tables are applied, the log output shows:

+ the values of all fields in the key of those tables, with the name
  of each field next to its value,
+ whether there was a match found or not, and
+ if there was a match found, the name of the action and the values of
  its action parameters (the names of the action parameters are not
  shown, but the action parameter values are given in the same order
  they appear in your P4 source code).

"Debug tables" are simply my name for a table that has `NoAction` as
its only action, so there is never any reason to add entries to it,
they can never modify the packet or its metadata, and its only reason
for being in the program is to show in the log the values of the
fields in the key when the table is applied.  They are effectively
"debug print" commands.

Note that such debug tables are likely to be useless when compiling to
a hardware target.  Worse than useless, they might cause the program
to be larger or more complex in ways that it will not "fit" into the
target when the debug table(s) are present, even though the program
does fit when they are left out.  If you find them useful for
developing P4 programs, consider surrounding them with C preprocessor
`#ifdef` directives so that they can easily be included or left out
with a one line change (or perhaps a compiler command line option).

I tested this program with a few table entries and test packets
described below, and the resulting log output from `simple_switch` for
several test packets are also described there.

I used these versions of the p4lang/behavioral-model and p4lang/p4c
repositories in my testing:

+ p4lang/behavioral-model - git commit
  13370aaf9329fcb369a3ea3989722eb5f61c07f3 dated Aug 16 2018
+ p4lang/p4c - git commit c534c585f8faba3e10af5776d5538c8a4374b8a6
  dated Aug 31 2018

The program demonstrates passing a list of fields to the
`recirculate()`, `resubmit()`, and `clone3()` primitive operations,
which causes the values of those fields to be preserved with the
resubmitted/recirculated/cloned packet.

*WARNING*: See the section "Caveat emptor" below for issues that may
cause programs you write using `recirculate`, `resubmit`, or `clone3`
to _not_ preserve the metadata fields you specify.


# Compiling

See [README-using-bmv2.md](../README-using-bmv2.md) for some things
that are common across different P4 programs executed using bmv2.

To compile the P4_16 version of the code (which is the only version):

    p4c --target bmv2 --arch v1model v1model-special-ops.p4
                                     ^^^^^^^^^^^^^^^^^^^^^^ source code

Running that command will create these files:

    v1model-special-ops.p4i - the output of running only the preprocessor on
        the P4 source program.
    v1model-special-ops.json - the JSON file format expected by BMv2
        behavioral model `simple_switch`.

Only the file with the `.json` suffix is needed to run your P4 program
using the `simple_switch` command.  You can ignore the file with
suffix `.p4i` unless you suspect that the preprocessor is doing
something unexpected with your program.

I have not attempted to create a corresponding P4_14 version of this
program.


# Running

To run the behavioral model with 8 ports numbered 0 through 7:

    sudo simple_switch --log-console -i 0@veth2 -i 1@veth4 -i 2@veth6 -i 3@veth8 -i 4@veth10 -i 5@veth12 -i 6@veth14 -i 7@veth16 v1model-special-ops.json

To get the log to go to a file instead of the console:

    sudo simple_switch --log-file ss-log --log-flush -i 0@veth2 -i 1@veth4 -i 2@veth6 -i 3@veth8 -i 4@veth10 -i 5@veth12 -i 6@veth14 -i 7@veth16 v1model-special-ops.json

CHECK THIS: If you see "Add port operation failed" messages in the
output of the simple_switch command, it means that one or more of the
virtual Ethernet interfaces veth2, veth4, etc. have not been created
on your system.  Search for "veth" in the file
[README-using-bmv2.md](../README-using-bmv2.md) for a command to
create them.

To run CLI for controlling and examining simple_switch's table
contents:

    simple_switch_CLI

General syntax for table_add commands at simple_switch_CLI prompt:

    RuntimeCmd: help table_add
    Add entry to a match table: table_add <table name> <action name> <match fields> => <action parameters> [priority]

Summary of all table entries to create:

    table_add ipv4_da_lpm do_resubmit 10.1.0.101/32 => 10.1.0.1
    table_add ipv4_da_lpm set_l2ptr 10.1.0.201/32 => 0xcafe
    table_add ipv4_da_lpm do_clone_i2e 10.3.0.55/32 => 0xd00d
    table_add ipv4_da_lpm set_l2ptr 10.47.1.1/32 => 0xbeef
    table_add ipv4_da_lpm set_mcast_grp 225.1.2.3/32 => 1113
    table_add mac_da set_bd_dmac_intf 0xe50b => 9 02:13:57:0b:e5:ff 2
    table_add mac_da set_bd_dmac_intf 0xcafe => 14 02:13:57:fe:ca:ff 3
    table_add mac_da set_bd_dmac_intf 0xec1c => 9 02:13:57:1c:ec:ff 2
    table_add mac_da set_bd_dmac_intf 0xd00d => 9 02:13:57:0d:d0:ff 1
    table_add mac_da set_bd_dmac_intf 0xbeef => 26 02:13:57:ef:be:ff 0
    table_add send_frame rewrite_mac 9 => 00:11:22:33:44:55
    table_add send_frame do_recirculate 14 => 10.1.0.2
    table_add send_frame do_clone_e2e 26 => 00:11:22:33:55:44
    table_add send_frame rewrite_mac 10 => 00:11:22:33:0a:55
    table_add send_frame rewrite_mac 11 => 00:11:22:33:0b:55
    table_add send_frame rewrite_mac 12 => 00:11:22:33:0c:55
    table_add get_multicast_copy_out_bd set_out_bd 1113 400 => 10
    table_add get_multicast_copy_out_bd set_out_bd 1113 401 => 11
    table_add get_multicast_copy_out_bd set_out_bd 1113 402 => 12
    mirroring_add 5 4
    mirroring_add 11 5
    mc_mgrp_create 1113
    mc_node_create 400 0
    mc_node_create 401 1
    mc_node_create 402 2
    mc_node_associate 1113 0
    mc_node_associate 1113 1
    mc_node_associate 1113 2

Note: The control plane operation "mirroring_add 5 1" causes a packet
that is cloned to clone session id 5 (aka "mirror session id") to be
sent to output port 1.

Details of which input packets should match which sequence of table
entries are given below.  All of this can be seen in the log file
output produced using the `--log-console` option to simple_switch,
which I have saved in a separate file for each input packet.

A note on the log files:

Most lines have a time, and several other common parts to it, like
this example output line:

    [09:25:02.955] [bmv2] [D] [thread 4822] [1.0] [cxt 0] Cloning packet at ingress

Note the part `[1.0]`.  It means roughly "for original input packet
#1, this line contains info about copy #0 made of that packet".  For
packets that are not cloned or multicast replicated, this label should
remain the same for all messages about the packet.

For cloned packets, after the clone operation occurs, you will see a
mingling of some log lines with "[1.0]" and others with "[1.1]".  The
"[1.0]" lines are for the original packet, not the clone.  The "[1.1]"
lines are for the cloned packet.  simple_switch apparently processes
these two packets either via two parallel threads, or in some other
similar fashion, that causes the log lines for these two packets to be
intermingled with each other.  Try to focus on only one set of lines
if you want to follow the sequential thread of execution for one of
those two copies.

A similar thing occurs when packets are multicast replicated.  The
number before the dot is the number of the input packet, and the
number after the dot is the "copy number" for packets creatd from that
original input packet.

Resubmitted packet, log in file: `resub-pkt-log.txt`:

    Summary: ingress, resubmit, ingress, egress, out
    Distinctive log message in log file to look for: "Resubmitting packet"

    resub_pkt=Ether() / IP(dst='10.1.0.101') / TCP(sport=5793, dport=80)
    packet in: ipv4.dstAddr = 10.1.0.101
    ingress
    table_add ipv4_da_lpm do_resubmit 10.1.0.101/32 => 10.1.0.1
    resubmit, packet same as before except instance_type
    ingress
    assign ipv4.srcAddr a vlaue of 10.252.129.2, l2ptr=RESUBMITTED_PKT_L2PTR=0xe50b
    table_add mac_da set_bd_dmac_intf 0xe50b => 9 02:13:57:0b:e5:ff 2
    egress
    table_add send_frame rewrite_mac 9 => 00:11:22:33:44:55
    packet out port 2

Recirculated packet, log in file: `recirc-pkt-log.txt`:

    Summary: ingress, egress, recirculate, ingress, egress, out
    Distinctive log message in log file to look for: "Recirculating packet"

    recirc_pkt=Ether() / IP(dst='10.1.0.201') / TCP(sport=5793, dport=80)
    packet in: ipv4.dstAddr = 10.1.0.201
    table_add ipv4_da_lpm set_l2ptr 10.1.0.201/32 => 0xcafe
    table_add mac_da set_bd_dmac_intf 0xcafe => 14 02:13:57:fe:ca:ff 3
    egress
    table_add send_frame do_recirculate 14 => 10.1.0.2
        assign ipv4.dstAddr=10.1.0.2
    recirculate
    ingress
    assign ipv4.srcAddr a value of 10.199.86.99, l2ptr=RECIRCULATED_PKT_L2PTR=0xec1c
    table_add mac_da set_bd_dmac_intf 0xec1c => 9 02:13:57:1c:ec:ff 2
    egress
    table_add send_frame rewrite_mac 9 => 00:11:22:33:44:55
    packet out port 2

Packet cloned from ingress to egress, log in file: `clone-i2e-pkt-log.txt`:

    Summary: ingress, clone
    original packet -> egress, out
    cloned packet -> egress, out

    Distinctive log message in log file to look for: "Cloning packet at ingress"

    i2e_clone_pkt=Ether() / IP(dst='10.3.0.55') / TCP(sport=5793, dport=80)
    packet in: ipv4.dstAddr = 10.3.0.55
    ingress
    table_add ipv4_da_lpm do_clone_i2e 10.3.0.55/32 => 0xd00d
    clone3 to I2E_CLONE_SESSION_ID=5, configured to go out port 4 with this table entry:
    mirroring_add 5 4
    table_add mac_da set_bd_dmac_intf 0xd00d => 9 02:13:57:0d:d0:ff 1

    original packet:
    egress
    table_add send_frame rewrite_mac 9 => 00:11:22:33:44:55
    packet out port 1

    cloned packet:
    egress
    execute code for clone_i2e case that adds switch_to_cpu header
    packet out port 4

Packet cloned from egress to egress, log in file: `clone-e2e-pkt-log.txt`:

    Summary: ingress, egress, clone
    original packet -> out
    cloned packet -> egress, out

    Distinctive log message in log file to look for: "Cloning packet at egress"

    e2e_clone_pkt=Ether() / IP(dst='10.47.1.1') / TCP(sport=5793, dport=80)
    packet in: ipv4.dstAddr = 10.47.1.1
    ingress
    table_add ipv4_da_lpm set_l2ptr 10.47.1.1/32 => 0xbeef
    table_add mac_da set_bd_dmac_intf 0xbeef => 26 02:13:57:ef:be:ff 0

    original packet:
    egress
    table_add send_frame do_clone_e2e 26 => 00:11:22:33:55:44
        do clone3 action to E2E_CLONE_SESSION_ID=11, configured to go
        out port 5 with this table entry:
    mirroring_add 11 5
    packet out port 0

    cloned packet:
    egress
    execute code for clone_e2e case that adds switch_to_cpu header
    packet out port 5

Packet using multicast replication, log in file: `mcast-pkt-log.txt`:

    Summary: ingress, multicast
    Each of the 3 copies independently then does: egress, out

    Distinctive log message in log file to look for: "Multicast requested for packet"

    mcast_pkt=Ether() / IP(dst='225.1.2.3') / TCP(sport=5793, dport=80)
    packet in: ipv4.dstAddr = 225.1.2.3
    ingress
    table_add ipv4_da_lpm set_mcast_grp 225.1.2.3/32 => 1113

    at end of ingress, 3 copies made because of this configuration of mcast_grp 1113:
    mc_mgrp_create 1113
    mc_node_create 400 0
    mc_node_create 401 1
    mc_node_create 402 2
    # Note: The 0, 1, and 2 below should be the "handles" created when
    # the mc_node_create commands above were performed.  If they were
    # the only such commands performed, and they were done in that
    # order, they should have been assigned handles 0, 1, and 2.
    mc_node_associate 1113 0
    mc_node_associate 1113 1
    mc_node_associate 1113 2

    copy with egress_port=0, egress_rid=400:
    egress
    table_add get_multicast_copy_out_bd set_out_bd 1113 400 => 10
    table_add send_frame rewrite_mac 10 => 00:11:22:33:0a:55
    packet out port 0

    copy with egress_port=1, egress_rid=401:
    egress
    table_add get_multicast_copy_out_bd set_out_bd 1113 401 => 11
    table_add send_frame rewrite_mac 11 => 00:11:22:33:0b:55
    packet out port 1

    copy with egress_port=2, egress_rid=402:
    egress
    table_add get_multicast_copy_out_bd set_out_bd 1113 402 => 12
    table_add send_frame rewrite_mac 12 => 00:11:22:33:0c:55
    packet out port 2


----------------------------------------------------------------------
scapy session for sending packets
----------------------------------------------------------------------
Any process that you want to have permission to send and receive
packets on Ethernet interfaces (such as the veth virtual interfaces)
must run as the super-user root, hence the use of `sudo`:

```python
sudo scapy

resub_pkt=Ether() / IP(dst='10.1.0.101') / TCP(sport=5793, dport=80)
recirc_pkt=Ether() / IP(dst='10.1.0.201') / TCP(sport=5793, dport=80)
i2e_clone_pkt=Ether() / IP(dst='10.3.0.55') / TCP(sport=5793, dport=80)
e2e_clone_pkt=Ether() / IP(dst='10.47.1.1') / TCP(sport=5793, dport=80)
mcast_pkt=Ether() / IP(dst='225.1.2.3') / TCP(sport=5793, dport=80)

# Send packet at layer2, specifying interface
sendp(resub_pkt, iface="veth6")
sendp(recirc_pkt, iface="veth6")
sendp(i2e_clone_pkt, iface="veth6")
sendp(e2e_clone_pkt, iface="veth6")
sendp(mcast_pkt, iface="veth6")
```

----------------------------------------


# Standard metadata for P4_16 + v1model architecture in p4c and behavioral-model

These notes may be specific to not only p4c and behavioral-model open
source repository implementations, but perhaps even to the specific
versions below that I have tested some of this with.

+ p4lang/behavioral-model - git commit
  13370aaf9329fcb369a3ea3989722eb5f61c07f3 dated Aug 16 2018
+ p4lang/p4c - git commit c534c585f8faba3e10af5776d5538c8a4374b8a6
  dated Aug 31 2018

This list of standard_metadata fields comes from that version of p4c,
in the file:
[p4c/p4include/v1model.p4](https://github.com/p4lang/p4c/blob/master/p4include/v1model.p4)

Some of these "intrinsic" or "standard" metadata fields are different
in P4_16 plus the Portable Switch Architecture (PSA).  See the [PSA
specification](https://p4.org/specs/) for the metadata that PSA has
and how its values are used.

Unless stated otherwise, assume that these values will be 0 for
recirculated or resubmitted packets at the beginning of ingress
processing, or for cloned packets at the beginning of egress
processing, _unless_ you include the field explicitly in the list of
metadata fields whose values should be preserved, as a parameter to
the `resubmit`, `recirculate`, or `clone3` primitive operation.

At the end of ingress processing, there are multiple of these fields
that are used to determine what happens to the packet next.  You can
read the details in the method `ingress_thread` of the
p4lang/behavioral-model source file
[`targets/simple_switch/simple_switch.cpp`](https://github.com/p4lang/behavioral-model/blob/master/targets/simple_switch/simple_switch.cpp),
but the pseudocode given in [this simple_switch
documentation](https://github.com/p4lang/behavioral-model/blob/master/docs/simple_switch.md)
gives a good description of the behavior, as well as similar
pseudocode for what happens to the packet next at the end of egress
processing.

The `qid` field is in `queueing_metadata` defined on that page:

+ `qid` - This is in the simple_switch documentation about
  `queueing_metadata`, but is not in `v1model.p4`.  TBD: Should it be
  added to v1model.p4?

The fields below are not mentioned in the behavioral-model
[`simple_switch`
documentation](https://github.com/p4lang/behavioral-model/blob/master/docs/simple_switch.md),
and there is a comment in the
[v1model.p4](https://github.com/p4lang/p4c/blob/master/p4include/v1model.p4)
include file explaining that they are deprecated.  Both were added to
the p4lang/p4c repository as part of the initial commit in Apr 2016,
so perhaps they are historical vestiges of some older ideas of how
v1model should work.

+ `recirculate_port` - There is no mention of this field anywhere in
  the behavioral-model source code.
+ `drop` - This field appears to be unused in simple_switch.  It is
  not mentioned in the source file
  [`simple_switch.cpp`](https://github.com/p4lang/behavioral-model/blob/master/targets/simple_switch/simple_switch.cpp).


# _Caveat emptor_

(_Caveat emptor_ is Latin for, roughly: "Let the buyer beware!")

If you do all of these things at the same time:

+ You use the open source tools `p4c` and `behavioral-model` as of
  January 2019 or earlier, and probably for a while longer until these
  issues are addressed (see below for where to find out up to date
  info).
+ You write a program in the P4_16 variant of P4, with the v1model
  architecture, or you write a program in the P4_14 variant of P4.
+ You use any of the `recirculate`, `resubmit`, or clone operations
  (called `clone3` in P4_16, or `clone_ingress_pkt_to_egress` or
  `clone_egress_pkt_to_egress` in P4_14), with a non-empty list of
  metadata fields whose values you want to preserve with the
  recirculated, resubmitted, or cloned packet.

Then you may find that the metadata field values are _not_ preserved.
The current implementation for preserving such metadata field values
is very fragile, and effectively it sometimes works by accident, not
by design.

When it does not work, the symptom is that one or more of the metadata
field values you expect to be preserved instead have their default
initial value when the post-recirculated/resubmitted/cloned packet is
next processed.  The default initial value for such metadata fields is
most often 0 in `simple_switch`.

Aside: It is possible to investigate the BMv2 JSON file created by the
`p4c` compiler manually (it is just a specially formatted text file),
in particular the value of the `"field_lists"` key, to see whether the
compiler has generated them in a way that will cause this undesired
behavior.  One sure sign of a problem is that one or more of the
fields have constant values in the field list in that file, rather
than a named field.  Another sign of a problem is if the compiler has
generated a temporary variable, copied the value of your field into
it, and used that temporary variable in the field list.  All of these
problems can be checked for using the program
[`bmv2-json-check.py`](https://github.com/p4pktgen/p4pktgen/blob/master/tools/bmv2-json-check.py).
The check is perhaps not 100% reliable for the last problem mentioned,
but seems to work.

Even when the metadata field values are preserved, they will be the
values that those fields have when the current ingress or egress
control block is finished executing.  If any later code in that
control block modifies the values of the metadata fields after the
recirculate/resubmit/clone call, the modified value will be preserved.
That is the behavior specified in the P4_14 language specification for
these operations.  For P4_16, it violates language semantics for calls
to extern functions and methods, which should only have access to the
values of parameters at the time the call occurs.

One or both of the issues linked below will likely be updated, or link
to further issues or code changes, when these problems are resolved:

+ https://github.com/p4lang/p4c/issues/1514
+ https://github.com/p4lang/p4c/issues/1669


## The root causes of the issue

The first implementation of these operations was for the P4_14 variant
of the language.  In P4_14, the recirculate, resubmit, and clone
operations take a "field list" as a parameter.  A field list is a
named list of metadata field names.

The behavior in `simple_switch` is that when you invoke a recirculate,
resubmit, or clone operation, it does _not_ immediately make a copy of
the value of those fields.  Instead it remembers a numeric id that the
compiler generates to identify the named field list (see the
description of `recirculate_flag` `resubmit_flag` and `clone_spec`
standard metadata fields
[here](https://github.com/p4lang/behavioral-model/blob/master/docs/simple_switch.md)
if you want more details).

When the packet completes the current ingress or egress processing
control block, then _at that time_ `simple_switch` copies the values
of the metadata fields into some location associated with that packet.
When the resulting recirculated or resubmitted packet begins its next
ingress processing pass, or the resulting cloned packet begins its
next egress processing pass, those field values are restored from that
location and become the initial values of those metadata fields.

There are two aspects of this that cannot be represented in the P4_16
language: delayed effects, and references by name.

First, the time during packet processing when the values of the
packet's metadata fields are copied and saved, can be much later in
the sequential flow of program execution than the place where the
recirculate, resubmit, or clone operation occurs.  It is a delayed
effect.  The P4_16 language specification does not specify any
mechanisms by which one can write a statement A in a program, and then
after other statements B, C, D, etc. are executed, the effect of the
statement A occurs.  Certainly an optimizing P4_16 compiler can
reorder the execution, but the effect must be the same as if the
program were executed sequentially.  A P4_14 recirculate operation can
cause values to be saved for metadata fields that are assigned later
in the P4_14 program.

Second, a field list gives _names_ of fields, and those are used both
for where to copy their current values from, and where to copy those
saved values into, later.  This is similar to "call by name" in other
programming languages, and P4_16 provides no such mechanism.  P4_16
defines copy in and copy out semantics for all existing methods of
calling a control, function, or extern function or method.  Even
extern methods and functions are not allowed to keep references or
pointers, only values copied from the caller.

It is definitely possible in a P4_16 program to use a technique
similar to the `ssimple_switch` implementation, e.g. record a numeric
id in a well-known metadata field that identifies a list of fields one
wants to preserve for the packet, and then at some later part of the
program use the value of that metadata field to make copies of the
desired fields.  Such a technique seems likely to become part of the
solution of these issues for P4_16 programs, perhaps written
explicitly by the P4 programmer, rather than auto-generated by the
compiler as occurs now for P4_14 programs.
