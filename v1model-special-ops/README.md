# Introduction

The program `v1model-special-ops.p4` demonstrates the use of resubmit,
recirculate, and clone operations in the BMV2 simple_switch's
implementation of P4_16's v1model architecture.  It does not do
anything fancy with these features, but at least it shows how to
distinguish whether a packet being processed in the ingress control
block is the result of a resubmit or recirculate operation, vs. a new
packet received from an ingress port.  Similarly whether a packet
being processed in the egress control block is the result of a clone
operation.

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
a packet that was resubmitted is in the file `resub-pkt-log.txt`, and
for a recirculated packet in `recirc-pkt-log.txt`.

I used these versions of the p4lang/behavioral-model and p4lang/p4c
repositories in my testing:

+ p4lang/behavioral-model - git commit
  13370aaf9329fcb369a3ea3989722eb5f61c07f3 dated Aug 16 2018
+ p4lang/p4c - git commit c534c585f8faba3e10af5776d5538c8a4374b8a6
  dated Aug 31 2018

The program also demonstrates passing a list of fields to the
`recirculate()`, `resubmit()`, and `clone3()` primitive operations,
which causes the values of those fields to be preserved with the
resubmitted/recirculated/cloned packet.


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

A similar thing occurs when packets are multicast replicated.

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
    egress    Distinctive log message in log file to look for: "Resubmitting packet"

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

    at end of ingress, 3 copies made because of this configuration of
    mcast_grp 0x1113:
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

Many of these "intrinsic" or "standard" metadata fields are different
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
but it should be the same as the pseudocode below:

After-ingress pseudocode - for determining what happens to a packet
after ingress processing is complete:

```
if (clone_spec != 0) {
    // This condition will be true if your code called the clone or
    // clone3 primitive action during ingress processing.
    Make a clone of the packet destined for the egress_port configured
    in the clone (aka mirror) session id number that was given when the
    last clone or clone3 primitive action was called.

    If it was a clone3 action, also preserve the final ingress values
    of the metadata fields specified in the field list argument,
    except assign clone_spec a value of 0 always, and instance_type a
    value of PKT_INSTANCE_TYPE_INGRESS_CLONE.
    // fall through to code below
}
if (lf_field_list != 0) {
    // This condition will be true if your code called the
    // generate_digest primitive action during ingress processing.
    Send a digest message to the control plane that contains the
    values of the fields in the specified field list.
    // fall through to code below
}
if (resubmit_flag != 0) {
    // This condition will be true if your code called the resubmit
    // primitive action during ingress processing.
    Start ingress over again for this packet, with its original
    unmodified packet contents and metadata values.  Preserve the
    final ingress values of any fields specified in the field list
    given as an argument to the last resubmit() primitive operation
    called, except assign resubmit_flag a value of 0 always, and
    instance_type a value of PKT_INSTANCE_TYPE_RESUBMIT.
} else if (mcast_grp != 0) {
    // This condition will be true if your code made an assignment to
    // standard_metadata.mcast_grp during ingress processing.  There
    // are no special primitive actions built in to simple_switch for
    // you to call to do this -- use a normal P4_16 assignment
    // statement, or P4_14 modify_field() primitive action.
    Make 0 or more copies of the packet based upon the list of
    (egress_port, egress_rid) values configured by the control plane
    for the mcast_grp value.  Enqueue each one in the appropriate
    packet buffer queue.  The instance_type of each will be
    PKT_INSTANCE_TYPE_REPLICATION.
} else if (egress_spec == 511) {
    // This condition will be true if your code called the
    // mark_to_drop (P4_16) or drop (P4_14) primitive action during
    // ingress processing.
    Drop packet.
} else {
    Enqueue one copy of the packet destined for egress_port equal to
    egress_spec.
}
```

List of annotations about each of the field names below:

+ sm14 - the field is defined in v1.0.4 of the P4_14 language
  specification, Section 6 titled "Standard Intrinsic Metadata".

+ v1m - the field is defined in the `p4include/v1model.p4` include
  file of the [p4c](https://github.com/p4lang/p4c) repository, intended
  to be included in P4_16 programs compiled for the v1model
  architecture.


The next fields below are not mentioned in the behavioral-model
[`simple_switch`
documentation](https://github.com/p4lang/behavioral-model/blob/master/docs/simple_switch.md).

+ `ingress_port` (sm14, v1m) - For new packets, the number of the
  ingress port which the packet arrived to the device.  Intended only
  to be read.
+ `packet_length` (sm14, v1m) - For new packets from a port, or
  recirculated packets, the length of the packet in bytes.  Must be
  included in a list of fields to preserve for a resubmit operation if
  you want it to be non-0.
+ `egress_spec` (sm14, v1m) - Can be assigned a value in ingress
  control block to control which output port a packet will go to.  The
  v1model primitive action `mark_to_drop` has the side effect of
  assigning an implementation specific value to this field (511
  decimal), such that if `egress_spec` has that value at the end of
  ingress processing, the packet will be dropped and not stored in the
  packet buffer, nor sent to egress processing.  See the
  "after-ingress pseudocode" for relative priority of this vs. other
  possible packet operations at end of ingress.
+ `egress_port` (sm14, v1m) - Only intended to be accessed during
  egress processing, and there, read only.  The output port this
  packet is destined to.
+ `egress_instance` (sm14) - See `egress_rid` below.
+ `instance_type` (sm14, v1m) - Contains a value that can be read by
  your P4 code.  In ingress processing, the value can be used to
  distinguish whether the packet is newly arrived from a port
  (`NORMAL`), it was the result of a resubmit operation (`RESUBMIT`),
  or it was the result of a recirculate operation (`RECIRC`).  In
  egress processing, can be used to determine whether the packet was
  produced as the result of an ingress-to-egress clone operation
  (`INGRESS_CLONE`), egress-to-egress clone operation
  (`EGRESS_CLONE`), multicast replication specified during ingress
  processing (`REPLICATION`), or none of those, so a normal unicast
  packet from ingress (`NORMAL`).  See the constants near the
  beginning of the program `v1model-special-ops.p4` with names
  containing `BMV2_V1MODEL_INSTANCE_TYPE` for the numeric values.
  Note: The `PktInstanceType` `COALESCED` is defined in the
  behavioral-model code, but not used anywhere.
+ `parser_status` (sm14) or `parser_error` (v1m) - `parser_status` is
  the name in the P4_14 language specification.  It has been renamed
  to `parser_error` in v1model.  0 (sm14) or error.NoError (P4_16 +
  v1model) means no error.  Otherwise, the value indicates what error
  occurred during parsing.
+ `parser_error_location` (sm14) - Not present in v1model.p4, and not
  implemented in simple_switch.

The next fields below are inside of what is called the
`queueing_metadata` header in the behavioral-model [`simple_switch`
documentation](https://github.com/p4lang/behavioral-model/blob/master/docs/simple_switch.md).
See there for details about their values.

+ `enq_timestamp` (v1m)
+ `enq_qdepth` (v1m)
+ `deq_timedelta` (v1m)
+ `deq_qdepth` (v1m)
+ `qid` - This is in the simple_switch documentation about
  queueing_metadata, but is not in v1model.p4.  TBD: Should it be
  added to v1model.p4?

The next fields below are inside of what is called the
`intrinsic_metadata` header in the behavioral-model [`simple_switch`
documentation](https://github.com/p4lang/behavioral-model/blob/master/docs/simple_switch.md).
See there for details about their values.

+ `ingress_global_timestamp` (v1m)
+ `egress_global_timestamp` (v1m)
+ `mcast_grp` (v1m) - Like `egress_spec`, intended to be assigned a
  value by your P4 code during ingress processing.  If it is 0 at the
  end of ingress processing, no multicast replication occurs.  If it
  is non-0, the packet is replicated once for each of the configured
  `(egress_port, egress_rid)` value pairs configured for that
  multicast group number by the control plane software.  See the
  "after-ingress pseudocode" for relative priority of this vs. other
  possible packet operations at end of ingress.
+ `egress_instance` (sm14) or `egress_rid` (v1m) - `egress_instance`
  is the name in the P4_14 language specification.  It has been
  renamed to `egress_rid` in v1model and to `instance` in PSA.  Should
  only be accessed during egress processing, read only.  0 for unicast
  packets.  May be non-0 for packets that were multicast-replicated.
  In that case, its value comes from a value configured for the
  multicast group used to replicate this packet, configured by the
  control plane software on a per-packet-copy basis.
+ `resubmit_flag` (v1m) - This field is one of several "simple_switch
  internal implementation detail fields", assigned a value as a side
  effect of executing the v1model `resubmit` primitive operation.  See
  below for additional notes.  See the "after-ingress pseudocode" for
  relative priority of this vs. other possible packet operations at
  end of ingress.
+ `recirculate_flag` (v1m) - This field is one of several
  "simple_switch internal implementation detail fields", assigned a
  value as a side effect of executing the v1model `recirculate`
  primitive operation.  See below for additional notes.
+ `clone_spec` (v1m) - This field is one of several "simple_switch
  internal implementation detail fields", assigned a value as a side
  effect of executing the v1model `clone` or `clone3` primitive
  operations.  See below for additional notes.  TBD: Should this field
  be documented as a field of the `intrinsic_metadata` header?  It is
  very similar to the `resubmit_flag` and `recirculate_flag` fields
  that are part of `intrinsic_metadata`, so perhaps this one should
  be, too?
+ `lf_field_list` (v1m) - This field is one of several "simple_switch
  internal implementation detail fields", assigned a value as a side
  effect of executing the v1model `generate_digest` primitive
  operation.  See below for additional notes.

The "simple_switch internal implementation detail" fields above have
the following things in common:

+ They are initialized to 0, and are assigned a compiler-chosen non-0
  value when the corresponding primitive operation is called.
+ Your P4 program should never assign them a value directly.
+ Reading the values may be helpful for debugging.
+ Reading them may also be useful for knowing whether the
  corresponding primitive operation was called earlier in the
  execution of the P4 program, but if you want to know whether such a
  use is portable to P4 implementations other than simple_switch, you
  will have to check the documentation for that other implementation.

The next fields below are not mentioned in the behavioral-model
[`simple_switch`
documentation](https://github.com/p4lang/behavioral-model/blob/master/docs/simple_switch.md).
Perhaps the only reason to do so would be to deprecate them.

+ `checksum_error` - Contains 1 if a checksum error was discovered
  during the v1model `verify checksum` control block execution, 0 if
  no error was found.  In the v1model architecture, this control block
  is executed after parsing a packet's headers, before executing the
  ingress control block.  Comments in v1model.p4 indicate this field
  is deprecated.  Use `parser_error` instead.
+ `recirculate_port` - TBD There is no mention of this field anywhere
  in the behavioral-model source code.  Similar to the `drop` field,
  it was added to `v1model.p4` in the p4lang/p4c repository in Apr
  2016, so also perhaps this field is a historical vestige and could
  be removed.
+ `drop` - TBD This field appears to be unused in simple_switch.  It
  is not mentioned in the source file
  [`simple_switch.cpp`](https://github.com/p4lang/behavioral-model/blob/master/targets/simple_switch/simple_switch.cpp).
  It was added as part of the initial addition of the file
  `v1model.p4` to the p4lang/p4c repository in Apr 2016, so perhaps it
  is a historical vestige and could be removed.
