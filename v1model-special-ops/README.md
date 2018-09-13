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


    table_set_default ipv4_da_lpm my_drop
    table_set_default mac_da my_drop
    table_set_default send_frame my_drop
    table_add ipv4_da_lpm do_resubmit 10.1.0.101/32 => 10.1.0.1
    table_add ipv4_da_lpm do_recirculate 10.1.0.201/32 => 10.1.0.1
    table_add ipv4_da_lpm do_clone_i2e 10.3.0.55/32 => 10.5.0.99
    table_add ipv4_da_lpm set_l2ptr 10.1.0.1/32 => 58
    table_add mac_da set_bd_dmac_intf 58 => 9 02:13:57:ab:cd:ef 2
    table_add send_frame rewrite_mac 9 => 00:11:22:33:44:55
    mirroring_add 5 1

Note: The control plane operation "mirroring_add 5 1" causes a packet
that is cloned to clone session id 5 (aka "mirror session id") to be
sent to output port 1.

----------------------------------------------------------------------
scapy session for sending packets
----------------------------------------------------------------------
Any process that you want to have permission to send and receive
packets on Ethernet interfaces (such as the veth virtual interfaces)
must run as the super-user root, hence the use of `sudo`:

```python
sudo scapy

fwd_pkt1=Ether() / IP(dst='10.1.0.1') / TCP(sport=5793, dport=80)
drop_pkt1=Ether() / IP(dst='10.1.0.34') / TCP(sport=5793, dport=80)
resub_pkt=Ether() / IP(dst='10.1.0.101') / TCP(sport=5793, dport=80)
recirc_pkt=Ether() / IP(dst='10.1.0.201') / TCP(sport=5793, dport=80)
clone_i2e_pkt=Ether() / IP(dst='10.3.0.55') / TCP(sport=5793, dport=80)

# Send packet at layer2, specifying interface
sendp(fwd_pkt1, iface="veth6")
sendp(drop_pkt1, iface="veth6")
sendp(resub_pkt, iface="veth6")
sendp(recirc_pkt, iface="veth6")
sendp(clone_i2e_pkt, iface="veth6")
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

Many of these "built in" metadata fields are completely different in
P4_16 plus the Portable Switch Architecture (PSA).  See the [PSA
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

```
if (clone_spec != 0) {
    // This condition will be true if your code called the `clone` or
    // `clone3` operation during ingress processing.
    Make a clone of the packet destined for the egress_port configured
    in the clone / mirror session id number that was given when the
    last clone or clone3 primitive operation was called.

    If it was a clone3 operation, also preserve the values of the
    metadata fields specified in the field list argument.
    // fall through to code below
}
if (lf_field_list != 0) {
    // This condition will be true if your code called the
    // `generate_digest` operation during ingress processing.
    Send a digest message to the control plane that contains the
    values of the fields in the specified field list.
    // fall through to code below
}
if (resubmit_flag != 0) {
    // This condition will be true if your code called the `resubmit`
    // operation during ingress processing.
    Start ingress over again for this packet, with its original
    unmodified packet contents and metadata values, except preserve
    the current values of any fields specified in the field list given
    as an argument to the last resubmit() primitive operation called.
    Also the instance_type will indicate the packet was resubmitted.
} else if (mcast_grp != 0) {
    // This condition will be true if your code made an assignment to
    // standard_metadtaa.mcast_grp during ingress processing.  There
    // are no primitive operations built in to simple_switch for you
    // to call to do this -- just use a normal P4_16 assignment
    // statement.
    Make 0 or more copies of the packet based upon the list of
    (egress_port, egress_rid) values configured by the control plane
    for the mcast_grp value.  Enqueue each one in the appropriate
    packet buffer queue.
} else if (egress_spec == 511) {
    // This condition will be true if your code called the
    // `mark_to_drop` operation during ingress processing.
    Drop packet.
} else {
    Enqueue one copy of the packet destined for egress_port equal to
    egress_spec.
}
```

The next fields below are not mentioned in the behavioral-model
[`simple_switch`
documentation](https://github.com/p4lang/behavioral-model/blob/master/docs/simple_switch.md).

+ `ingress_port` - For new packets, ingress port number on which the
  packet arrived to the device.  TBD whether it is ever a good idea to
  assign a value to this.  Probably best to treat it as read only.

+ `egress_spec` - Can be assigned a value in ingress control block to
  control which output port a packet will go to.  The primitive action
  `mark_to_drop` has the side effect of assigning an implementation
  specific value to this field (511 decimal), such that if it has that
  value at the end of ingress processing, the packet will be dropped
  and not stored in the packet buffer, nor sent to egress processing.
  See pseudocode above for relative priority of this vs. other
  possible packet operations at end of ingress.

+ `egress_port` - 0 in ingress.  In egress processing, equal to the
  output port this packet is destined to.  Should be treated as read
  only.

+ `clone_spec` - Like `resubmit_flag` and `recirculate_flag` fields
  described below, the `clone` or `clone3` primitive operations assign
  a non-0 value to this field indicating that the packet should be
  cloned.  Your code should probably never explicitly assign a value
  to this field.  Reading it may be helpful for debugging, and perhaps
  for knowing whether a `clone` operation was called for this packet
  earlier in its processing.

+ `instance_type` - Contains a value that can be read by your P4 code.
  In ingress processing, the value can be used to distinguish whether
  the packet is newly arrived from a port (`NORMAL`), it was the
  result of a resubmit operation (`RESUBMIT`), or it was the result of
  a recirculate operation (`RECIRC`).  In egress processing, can be
  used to determine whether the packet was produced as the result of
  an ingress-to-egress clone operation (`INGRESS_CLONE`),
  egress-to-egress clone operation (`EGRESS_CLONE`), multicast
  replication specified during ingress processing (`REPLICATION`), or
  none of those, so a normal unicast packet from ingress (`NORMAL`).
  See the constants near the beginning of `v1model-special-ops.p4`
  with names containing `BMV2_V1MODEL_INSTANCE_TYPE` for the numeric
  values.  Note: The `PktInstanceType` `COALESCED` is defined in the
  behavioral-model code, but not used anywhere.  I do not know what it
  might have been intended for.

+ `drop` - TBD I think this is unused.  At least, it is not mentioned
  in the source file
  [`simple_switch.cpp`](https://github.com/p4lang/behavioral-model/blob/master/targets/simple_switch/simple_switch.cpp).
  It was added as part of the initial addition of the file
  `v1model.p4` to the p4lang/p4c repository in Apr 2016, so perhaps it
  is a historical vestige?

+ `recirculate_port` - TBD There is no mention of this field anywhere
  in the behavioral-model source code.  Similar to the `drop` field,
  it was added to `v1model.p4` in the p4lang/p4c repository in Apr
  2016, so also perhaps a historical vestige.

+ `packet_length` - At least for new packets from a port, or
  recirculated packets, the length of the packet in bytes.  Must be
  included in a list of fields to preserve for a resubmit operation if
  you want it to be non-0.

The next fields below are inside of what is called the
`queueing_metadata` header in the behavioral-model [`simple_switch`
documentation](https://github.com/p4lang/behavioral-model/blob/master/docs/simple_switch.md).
See there for details about their values.

+ `enq_timestamp`
+ `enq_qdepth`
+ `deq_timedelta`
+ `deq_qdepth`

The next fields below are inside of what is called the
`intrinsic_metadata` header in the behavioral-model [`simple_switch`
documentation](https://github.com/p4lang/behavioral-model/blob/master/docs/simple_switch.md).
See there for details about their values.

+ `ingress_global_timestamp`
+ `egress_global_timestamp`
+ `lf_field_list`

+ `mcast_grp` - Like `egress_spec`, intended to be assigned a value by
  your P4 code during ingress processing.  If it is 0 at the end of
  ingress processing, no multicast replication occurs.  If it is
  non-0, the packet is replicated once for each of the configured
  `(egress_port, egress_rid)` value pairs configured for that
  multicast group number by the control plane software.  See
  pseudocode above for relative priority of this vs. other possible
  packet operations at end of ingress.

+ `egress_rid` - Should not be accessed during ingress processing.
  Only intended to be read, never written, during egress processing.
  0 for unicast packets.  May be non-0 in egress processing for
  packets that were multicast-replicated.  In that case, its value
  comes from a value configured for the multicast group used to
  replicate this packet, configured on a per-packet-copy basis.

+ `resubmit_flag` - The `resubmit` primitive operation assigns a non-0
  value to this field indicating that the packet should be
  resubmitted.  Your code should not access it directly.  Reading it
  may be helpful for debugging, and perhaps for knowing whether a
  `resubmit` operation was called for this packet earlier in its
  processing.  See pseudocode above for relative priority of this
  vs. other possible packet operations at end of ingress.

+ `recirculate_flag` - The `recirculate` primitive operation assigns a
  non-0 value to this field indicating that the packet should be
  recirculated.  Your code should not access it directly.  Reading it
  may be helpful for debugging, and perhaps for knowing whether a
  `recirculate` operation was called for this packet earlier in its
  processing.


The next fields below are not mentioned in the behavioral-model
[`simple_switch`
documentation](https://github.com/p4lang/behavioral-model/blob/master/docs/simple_switch.md).

+ `checksum_error` - TBD: Probably intended to contain 1 if a checksum
  error was discovered during the "verify checksum" control block
  execution, 0 if no error was found.  In the v1model architecture,
  this control block is executed after parsing a packet's headers,
  before executing the ingress control block.

+ `parser_error` - TBD: Probably intended to contain the value of any
  error encountered while parsing a packet's headers, either one of
  the standard errors defined in the P4_16 language spec that can
  occur during parsing like `error.PacketTooShort`, or one that the
  user wrote a `verify` statement for and its condition evaluated to
  `false`.
