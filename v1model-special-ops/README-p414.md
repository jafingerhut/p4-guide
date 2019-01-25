# Introduction

The program `p414-special-ops.p4` demonstrates the use of resubmit,
recirculate, and clone egress-to-egress operations in BMv2
simple_switch.

It does not do anything terribly fancy with those operations, but it
does show how they can be invoked.

Like the P4_16 program in this same directory, it also demonstrates
"debug tables".  See the description of them [README.md](README.md)
for more details.

This program has been written so that it can do what is expected of it
even without adding any table entries.  It does require configuring
one clone session in order for the clone operation to produce another
copy of the packet and work as described later.  Below is a detailed
description of what happens while packets are processed with this
program, as well as links to log output from `simple_switch` while it
processes selected packets.

I used these versions of the p4lang/behavioral-model and p4lang/p4c
repositories in my testing:

+ p4lang/behavioral-model - git commit
  20d37301040e6e1b2f6f50f4f66671448946b898 dated Dec 18 2018
+ p4lang/p4c - git commit d21be8847d900d715a2533e122f33ac8c3bcebdf
  dated Nov 26 2018

*WARNING*: Compiling this program with version of the open source
`p4c` compiler from 2018-Nov-26 or somewhat earlier leads to a working
result in simple_switch, but as of Jan 2019, later versions of `p4c`
do not produce compiler output that works correctly using BMv2
simple_switch -- the recirculate, resubmit, and clone operations
simply do not occur at all, as they should while processing packets.
See the following issue on Github for status of whether this problem
becomes fixed: https://github.com/p4lang/p4c/issues/1694

*WARNING*: See the section "Caveat emptor" in the file
 [README.md](README.md) for issues that may cause programs you write
 using `recirculate`, `resubmit`, `clone_ingress_pkt_to_egress`, or
 `clone_egress_pkt_to_egress` operations to _not_ preserve the
 metadata fields you specify.


# Compiling

See [README-using-bmv2.md](../README-using-bmv2.md) for some things
that are common across different P4 programs executed using bmv2.

```bash
p4c --std p4-14 --target bmv2 p414-special-ops.p4
```

Running that command will create these files:

    p414-special-ops.p4i - the output of running only the preprocessor on
        the P4 source program.
    p414-special-ops.json - the JSON file format expected by BMv2
        behavioral model `simple_switch`.

Only the file with the `.json` suffix is needed to run your P4 program
using the `simple_switch` command.  You can ignore the file with
suffix `.p4i` unless you suspect that the preprocessor is doing
something unexpected with your program.


# Running

To run the behavioral model with 8 ports numbered 0 through 7:

```bash
sudo simple_switch --log-console -i 0@veth2 -i 1@veth4 -i 2@veth6 -i 3@veth8 -i 4@veth10 -i 5@veth12 -i 6@veth14 -i 7@veth16 p414-special-ops.json
```

To get the log to go to a file instead of the console:

```bash
sudo simple_switch --log-file ss-log --log-flush -i 0@veth2 -i 1@veth4 -i 2@veth6 -i 3@veth8 -i 4@veth10 -i 5@veth12 -i 6@veth14 -i 7@veth16 p414-special-ops.json
```

CHECK THIS: If you see "Add port operation failed" messages in the
output of the simple_switch command, it means that one or more of the
virtual Ethernet interfaces veth2, veth4, etc. have not been created
on your system.  Search for "veth" in the file
[README-using-bmv2.md](../README-using-bmv2.md) for a command to
create them.

To run CLI for controlling and examining simple_switch's table
contents:

```bash
simple_switch_CLI
```

The only configuration command needed for this program to work as
desired is to configure clone session with id 1, so that packets
cloned there will go to output port 5.

```
mirroring_add 1 5
```

Scapy commands to send 3 packets, each of which exercises different
parts of the program:

```python
sudo scapy

resub_pkt=Ether(src='00:00:00:00:00:00', dst='00:00:00:00:00:01', type=0xdead)
recirc_pkt=Ether(src='00:00:00:00:00:00', dst='00:00:00:00:00:02', type=0xdead)
e2e_clone_pkt=Ether(src='00:00:00:00:00:00', dst='00:00:00:00:00:03', type=0xdead)

# Send packet at layer2, specifying interface
sendp(resub_pkt, iface="veth2")
sendp(recirc_pkt, iface="veth2")
sendp(e2e_clone_pkt, iface="veth2")
```


# How packets should be processed by this program

Below are detailed descriptions for how each of several types of
packets should be processed by this program.


## Resubmitted packet

If you send in a packet constructed via Scapy with these header field
values:

```python
resub_pkt=Ether(src='00:00:00:00:00:00', dst='00:00:00:00:00:01', type=0xdead)
sendp(resub_pkt, iface="veth2")
```

then here are the processing steps that the packet should go through.
If you want to understand this in detail, I recommend that you have
open a copy of the source code in the file `p414-special-ops.p4` and
follow along with the execution flow.

In ingress, the condition `ethernet.dstAddr == MAC_DA_DO_RESUBMIT`
will be true.

The first time the packet arrives and is processed by ingress,
simple_switch initializes the values of all metadata fields to 0,
including `mymeta.resubmit_count`, so the condition
`mymeta.resubmit_count < MAX_RESUBMIT_COUNT` will also be true.
`MAX_RESUBMIT_COUNT` is defined to be 3.

The table `t_do_resubmit` will be applied, causing its default action
`do_resubmit` to be executed.  That action is defined as:

```
action do_resubmit() {
    subtract_from_field(ethernet.srcAddr, 17);
    add_to_field(mymeta.f1, 17);
    add_to_field(mymeta.resubmit_count, 1);
    resubmit(resubmit_FL);
}
```

So 17 will be subtracted from the packet's Ethernet source address, 17
will be added to `mymeta.f1`, and 1 will be added to
`mymeta.resubmit_count`.

Then the packet will be requested to be resubmitted when ingress
processing is complete, preserving the values of the fields in the
field_list `resubmit_FL`, which includes only these:

```
field_list resubmit_FL {
    mymeta.resubmit_count;
    mymeta.f1;
}
```

Then the table `t_save_ing_instance_type` will be applied, causing its
default action to be executed, which copies the value of
`standard_metadata.instance_type` to `mymeta.last_ing_instance_type`.

That is the end of ingress processing.  When the packet is finished
with ingress processing, the detailed version of what happens next is
described in pseudocode form at the simple_switch documentation
[here](https://github.com/p4lang/behavioral-model/blob/master/docs/simple_switch.md#pseudocode-for-what-happens-at-the-end-of-ingress-and-egress-processing).

In this case, no clone or generate_digest operations have been
invoked, so those parts of the pseudocode do nothing.  There has been
a resubmit operation invoked, so the packet will be resubmitted.  Any
changes made to the packet will be "forgotten", and the original
packet will start ingress processing again.  The only difference
should be that the values of the two fields in the field_list
`resubmit_FL`, at the _end_ of ingress processing, will be saved and
will become the initial values of those fields for the resubmitted
packet.  Another difference is that the field
`standard_metadata.instance_type`, which was
`PKT_INSTANCE_TYPE_NORMAL` (0) for the original packet, should instead
be `PKT_INSTANCE_TYPE_RESUBMIT` (6) for the resubmitted packet.  This
P4 program does not use the value of `standard_metadata.instance_type`
to affect its processing, though.

See the definition of `enum PktInstanceType` in the file
[`simple_switch.h`](https://github.com/p4lang/behavioral-model/blob/master/targets/simple_switch/simple_switch.h)
of the `simple_switch` implementation for the definitions of
`PKT_INSTANCE_TYPE_*` values.

The resubmitted packet will go through the same steps as above.
`mymeta.resubmit_count` starts as 1, but is incremented to 2 before
the packet is resubmitted again.  That packet will also change
`mymeta.f1` from 17 to 34.

That resubmitted packet again goes through the same steps,
incrementing `mymeta.resubmit_count` from 2 to 3, and updating
`mymeta.f1` from 34 to 51.

When _that_ resubmitted packet starts its ingress processing, it will
be processed differently, because the condition `mymeta.resubmit_count
< MAX_RESUBMIT_COUNT` will be `3 < 3`, which is false.  Thus the table
`t_mark_max_resubmit_packet` will be applied, and its default action
`mark_max_resubmit_packet` will be executed, assigning a value of
`ETHERTYPE_MAX_RESUBMIT` to the `etherType` field of the Ethernet
header.  The packet will again apply table `t_save_ing_instance_type`,
which copies the value of `standard_metadata.instance_type`, which is
6 for a resubmitted packet, into `mymeta.last_ing_instance_type`.

When that packet is finished with ingress processing, the detailed
version of what happens next is described in pseudocode form at the
simple_switch documentation
[here](https://github.com/p4lang/behavioral-model/blob/master/docs/simple_switch.md#pseudocode-for-what-happens-at-the-end-of-ingress-and-egress-processing).
This time no resubmit operation has been done, and none of the `if`
conditions are true, so the packet will go to the packet buffer,
destined for the egress port that is the current value of
`standard_metadata.egress_spec`.  Since its initial value was 0, and
no assignment has been made to it, the packet is destined to port 0.

When egress processing beings, since simple_switch by default
preserves all user-defined metadata field values for P4_14 programs,
all of them will have the value they did, e.g. `mymeta.f1` is 51,
`mymeta.resubmit_count` is 3, and `mymeta.last_ing_instance_type` is
6.

During egress processing the condition `ethernet.dstAddr ==
MAC_DA_DO_RESUBMIT` is true, so the table `t_egr_mark_resubmit_packet`
is applied, and its default action `mark_egr_resubmit_packet` will be
executed.  This in turn executes action
`put_debug_vals_in_eth_dstaddr`, which does many modifications to the
packet's Ethernet `dstAddr` field.  It is simply saving copies of
multiple 8-bit wide user-defined metadata fields into different 8-bit
parts of the 48-bit Ethernet `dstAddr`, so that they can be observed
in the output packet, and the automated `p4c` test infrastructure can
observe the output packet header, and check that they match the
expected values.

```
    modify_field(ethernet.dstAddr, 0);
    shift_left(temporaries.temp1, mymeta.resubmit_count, 40);
    bit_or(ethernet.dstAddr, ethernet.dstAddr, temporaries.temp1);
    shift_left(temporaries.temp1, mymeta.recirculate_count, 32);
    bit_or(ethernet.dstAddr, ethernet.dstAddr, temporaries.temp1);
    shift_left(temporaries.temp1, mymeta.clone_e2e_count, 24);
    bit_or(ethernet.dstAddr, ethernet.dstAddr, temporaries.temp1);
    shift_left(temporaries.temp1, mymeta.f1, 16);
    bit_or(ethernet.dstAddr, ethernet.dstAddr, temporaries.temp1);
    shift_left(temporaries.temp1, mymeta.last_ing_instance_type, 8);
    bit_or(ethernet.dstAddr, ethernet.dstAddr, temporaries.temp1);
```

The values of the fields should be these:

```
mymeta.resubmit_count = 3
mymeta.recirculate_count = 0
mymeta.clone_e2e_count = 0
mymeta.f1 = 51 (decimal) = 0x33 (hex)
mymeta.last_ing_instance_type = 6
```

Thus the value of `ethernet.dstAddr` should become:

```
ethernet.dstAddr = 0x030000330600
```

No more tables are applied during egress processing for the packet, so
it should go out of port 0 with the following Ethernet header field
values:

```
ethernet.dstAddr = 0x030000330600
ethernet.srcAddr = <whatever value the packet arrived with>
ethernet.etherType = ETHERTYPE_MAX_RESUBMIT = 0xe50b
```

Recall that the value of `etherType` was modified during the last
ingress processing step above, when executing action
`mark_max_resubmit_packet`.  The modified value was saved in the
packet buffer after ingress processing was complete.


## Recirculated packet

If you send in a packet constructed via Scapy with these header field
values:

```python
recirc_pkt=Ether(src='00:00:00:00:00:00', dst='00:00:00:00:00:02', type=0xdead)
sendp(recirc_pkt, iface="veth2")
```

then here are the processing steps that the packet should go through.

In ingress, the condition `ethernet.dstAddr == MAC_DA_DO_RESUBMIT`
will be false.  The table `t_ing_mac_da` will be applied, causing its
default action `set_port_to_mac_da_lsbs` to be executed.

```
action set_port_to_mac_da_lsbs() {
    bit_and(standard_metadata.egress_spec, ethernet.dstAddr, 0xf);
}
```

This action is a bit peculiar.  It ANDs the packet's Ethernet
`dstAddr` with 0xf and puts the result in
`standard_metadata.egress_spec`.  I would not expect a typical switch
to do such a thing.  I did it in this program primarily so that
different packets would go to different output ports, making it easier
to write an automated test for `p4c` that checks the output packets,
and get predictable orders of those output packets appearing on each
output port.

In this case, it assigns the value 2 to
`standard_metadata.egress_spec`, so that if it is not changed again,
and the packet is sent via unicast to egress, it will go out of port
2.

Then the table `t_save_ing_instance_type` will be applied, causing its
default action to be executed, which copies the value of
`standard_metadata.instance_type` to `mymeta.last_ing_instance_type`.
For new packets, this is the numeric value 0, indicating a `NORMAL`
packet, i.e. not resubmitted or recirculated, but a new one arriving
from a port of the switch.

That is the end of ingress processing.  When the packet is finished
with ingress processing, the detailed version of what happens next is
described in pseudocode form at the simple_switch documentation
[here](https://github.com/p4lang/behavioral-model/blob/master/docs/simple_switch.md#pseudocode-for-what-happens-at-the-end-of-ingress-and-egress-processing).
None of the `if` conditions are true, so the packet will go to the
packet buffer, destined for the egress port that is the current value
of `standard_metadata.egress_spec`.  Since its initial value was 0,
and no assignment has been made to it, the packet is destined to port
0.

When egress processing begins, since simple_switch by default
preserves all user-defined metadata field values for P4_14 programs,
all of them will have the value they did, e.g. `mymeta.f1` is 0, etc.

The condition `ethernet.dstAddr == MAC_DA_DO_RESUBMIT` is false, but
`ethernet.dstAddr == MAC_DA_DO_RECIRCULATE` is true.  The condition
`mymeta.recirculate_count < MAX_RECIRCULATE_COUNT` is the same same as
`0 < 5`, which is true.

We apply the table `t_do_recirculate`, which executes its default
action `do_recirculate`:

```
action do_recirculate () {
    subtract_from_field(ethernet.srcAddr, 19);
    add_to_field(mymeta.f1, 19);
    add_to_field(mymeta.recirculate_count, 1);
    recirculate(recirculate_FL);
}
```

So 19 will be subtracted from the packet's Ethernet source address, 19
will be added to `mymeta.f1`, and 1 will be added to
`mymeta.recirculate_count`.

Then the packet will be requested to be recirculated when egress
processing is complete, preserving the values of the fields in the
field_list `recirculate_FL`, which includes only these:

```
field_list recirculate_FL {
    mymeta.recirculate_count;
    mymeta.f1;
}
```

That is the end of ingress processing.  When the packet is finished
with egress processing, the detailed version of what happens next is
described in pseudocode form at the simple_switch documentation
[here](https://github.com/p4lang/behavioral-model/blob/master/docs/simple_switch.md#pseudocode-for-what-happens-at-the-end-of-ingress-and-egress-processing).
The first `if` condition in the after-egress pseudocode to evaluate as
true is `recirculate_flag != 0`, which is true because the effect of
invoking a `recirculate` operation is to assign a non-0 value to that
field.

The packet is then recirculated, meaning that it goes through the
deparser, with any modifications to header fields that were made
during ingress and egress processing (the only such change made so far
is to subtract 19 from the Ethernet `srcAddr` field), and preserve the
metadata field values in the field_list `recirculate_FL`, so the
resubmitted packet begins ingress processing with
`mymeta.recirculate_count` equal to 1, and `mymeta.f1` equal to 19.
simple_switch also causes the recirculated packet to begin ingress
processing with `standard_metadata.instance_type` equal to
`PKT_INSTANCE_TYPE_RECIRC`, which is the number 4.

The recirculated packet in ingress goes through exactly the same steps
as the original packet did, with the minor difference that the value
of `mymeta.last_ing_instance_type` is assigned a value of 4, because
that is what the value of `standard_metadata.instance_type` began as
for the recirculated packet.

That packet is sent to the packet buffer destined for port 2, and
egress processing is done for it.  It goes through exactly the same
steps as described above, except for these changes:

```
selected field values of recirculated packet #1 when egress
processing begins:

ethernet.srcAddr = original received value - 19
mymeta.f1 = 19
mymeta.recirculate_count = 1

final values of those fields when egress processing is complete:

ethernet.srcAddr = original received value - 38
mymeta.f1 = 38
mymeta.recirculate_count = 2
```

Thus this packet is also recirculated when egress processing is
complete.

This loop continues to repeat until some condition evaluates
differently.  The first time this happens is the 6th time egress
processing begins, when the values of selected fields are as shown
below:

```
ethernet.srcAddr = original received value - 114 decimal
mymeta.f1 = 5*19 = 95 decimal = 0x5f hex
mymeta.recirculate_count = 5
```

This time, the condition `mymeta.recirculate_count <
MAX_RECIRCULATE_COUNT` is `5 < 5`, which is false.  The table
`t_mark_max_recirculate_packet` is applied, which executes its default
action `mark_max_recirculate_packet`.

```
action mark_max_recirculate_packet () {
    put_debug_vals_in_eth_dstaddr();
    modify_field(ethernet.etherType, ETHERTYPE_MAX_RECIRCULATE);
}
```

The action `put_debug_vals_in_eth_dstaddr` is described in the
resubmit packet example above.  In this case the values of the fields
that affect the new value assigned to the Ethernet `dstAddr` field
are these:

```
mymeta.resubmit_count = 0
mymeta.recirculate_count = 5
mymeta.clone_e2e_count = 0
mymeta.f1 = 5*19 = 95 decimal = 0x5f hex
mymeta.last_ing_instance_type = 4
```

Thus the value of `ethernet.dstAddr` should become:

```
ethernet.dstAddr = 0x0005005f0400
```

No more tables are applied during egress processing for the packet, so
it should go out of port 2 with the following Ethernet header field
values:

```
ethernet.dstAddr = 0x0005005f0400
ethernet.srcAddr = <whatever value the packet arrived with> - 5*19
ethernet.etherType = ETHERTYPE_MAX_RECIRCULATE = 0xec14
```

For example, if the input value of `ethernet.srcAddr` was 0, then
because P4 arithmetic of unsigned bit vectors is modulo `(2 to the
power <width of bit vector>)`, the output value can be calculated with
the help of a simple interactive Python session:

```python
>>> print('%12x' % (2**48 - 5*19))
ffffffffffa1
```


## Egress-to-egress cloned packet

If you send in a packet constructed via Scapy with these header field
values:

```python
e2e_clone_pkt=Ether(src='00:00:00:00:00:00', dst='00:00:00:00:00:03', type=0xdead)
sendp(e2e_clone_pkt, iface="veth2")
```

then here are the processing steps that the packet should go through.

The first time through ingress processing will have the same behavior
as described for a recirculated packet above, and the first time the
packet goes through ingress processing it will begin the same way.
One small difference is that `standard_metadata.egress_spec` will be
assigned a value of 3, since that is what is in the least significant
4 bits of the Ethernet `dstAddr` field of this packet.  Thus the
packet is destined toward output port 3.

When egress processing beings, since simple_switch by default
preserves all user-defined metadata field values for P4_14 programs,
all of them will have the value they did, e.g. `mymeta.f1` is 0, etc.

The condition `ethernet.dstAddr == MAC_DA_DO_RESUBMIT` is false, and
so is `ethernet.dstAddr == MAC_DA_DO_RECIRCULATE`, but
`ethernet.dstAddr == MAC_DA_DO_CLONE_E2E` is true.

The `mymeta.clone_e2e_count < MAX_CLONE_E2E_COUNT` is the same as `0 <
4`, which is true.

We apply the table `t_do_clone_e2e`, which executes its default action
`do_clone_e2e`:

```
action do_clone_e2e () {
    subtract_from_field(ethernet.srcAddr, 23);
    add_to_field(mymeta.f1, 23);
    add_to_field(mymeta.clone_e2e_count, 1);
    clone_egress_pkt_to_egress(1, clone_e2e_FL);
}
```

So 23 will be subtracted from the packet's Ethernet source address, 23
will be added to `mymeta.f1`, and 1 will be added to
`mymeta.clone_e2e_count`.

Then the packet will be requested to be cloned when egress
processing is complete, preserving the values of the fields in the
field_list `clone_e2e_FL`, which includes only these:

```
field_list clone_e2e_FL {
    mymeta.clone_e2e_count;
    mymeta.f1;
}
```

That is the end of ingress processing.  When the packet is finished
with egress processing, the detailed version of what happens next is
described in pseudocode form at the simple_switch documentation
[here](https://github.com/p4lang/behavioral-model/blob/master/docs/simple_switch.md#pseudocode-for-what-happens-at-the-end-of-ingress-and-egress-processing).

The first `if` condition `clone_spec != 0` in that pseudocode is true,
because a side effect of executing the `clone_egress_pkt_to_egress` is
to assign a non-0 value to the `clone_spec` metadata field.  The
pseudocode says that thus a clone of the packet is created, and sent
toward the output port configured in the "clone session".  A device
can have multiple clone sessions, and if so, the clone session to be
used is determined by the first argument to the
`clone_egress_pkt_to_egress` operation call, which is 1 in this
program's execution.

In simple_switch, all clone sessions have an initial configuration
that causes them to drop any packet that is cloned.  I will assume
here that before we sent in the packet, we configured the clone
session with id 1 to send packets toward output port 5.  This can be
done by running the command `simple_switch_CLI` after starting the
`simple_switch` process, and entering this command at the
`simple_switch_CLI` `RuntimeCmd: ` prompt:

```
mirroring_add 1 5
```

In this case, the cloned packet will have `egress_port` equal to 5,
and its contents will contain packet headers as modified during
ingress and egress processing, then deparsed.  The packet header field
values at the end of ingress processing are:

```
ethernet.dstAddr = 0x000000000003 (as received, not modified)
ethernet.srcAddr = <whatever value the packet arrived with> - 23
ethernet.etherType = 0xdead (as received, not modified)
```

In the case of the received packet having `srcAddr` equal to 0, the
cloned packet should have the following value for `srcAddr`:

```python
>>> print('%12x' % (2**48 - 23))
ffffffffffe9
```

The cloned packet does not immediately go out of port 5.  It starts
egress processing from the beginning, with the modified values for
metadata fields that were explicitly requested to be preserved in the
field_list `clone_e2e_FL`, and the modified contents of the packet
header fields.  See below for how this cloned packet is processed
further.

The simple_switch after-egress pseudocode does not stop after creating
the clone.  There are additional statements in the pseudocode to
execute.  None of the other `if` conditions are true, so a packet is
sent to the current `standard_metadata.egress_port` of 3, which was
copied from the end-of-ingress-processing value of
`standard_metadata.egress_spec` for this packet.  This packet will
have the same packet header field values as described above for the
clone.

Now let us see how the cloned packet is processed.

It starts egress processing with the modified packet header values
described above, and the following modified metadata field values that
were preserved by the clone operation's field_list:

```
mymeta.clone_e2e_count = 1
mymeta.f1 = 23 decimal
```

It will also begin with a value of `standard_metadata.instance_type =
2`, which is the value named `PKT_INSTANCE_TYPE_EGRESS_CLONE` in the
simple_switch source code.  This value can be used by your P4 programs
to distinguish egress-to-egress cloned packets during egress
processing, versus packets that were ingress-to-egress cloned,
multicast replicated from ingress, or sent via unicast from ingress.
This value of `standard_metadata.instance_type` is filled in
automatically by simple_switch.  This P4 program does not use the
value of this field to affect its processing.

The flow of control for the cloned packet through egress processing
will be the same as described above for the original packet going
through egress processing, except for the few fields that have
different initial values.

```
selected field values of cloned packet #1 when egress processing
begins:

ethernet.srcAddr = original received value - 23
mymeta.clone_e2e_count = 1
mymeta.f1 = 23 decimal

final values of those fields when egress processing is complete:

ethernet.srcAddr = original received value - 46
mymeta.clone_e2e_count = 2
mymeta.f1 = 46 decimal
```

Thus this packet will also be cloned when egress processing is
complete.

This time the not-cloned packet will go out port 5, because that is
the value of `standard_metadata.egress_port` when egress processing
began, which came from the clone session configuration.  The only
other difference between the packet sent out port 3 described above is
that the Ethernet `srcAddr` will be 23 less.

If we call the first time egress processing occurred "the original
packet", and the first cloned packet that went through egress
processing "clone #1", and the second "clone #2", etc. then here is a
complete list of ingress and egress processing done as a result of one
packet being received, and all packets that should go out.

+ the original packet ingress

+ the original packet egress
  + It starts egress processing with these metadata field values:
    + `standard_metadata.instance_type` = 0 (`PKT_INSTANCE_TYPE_NORMAL`)
    + `standard_metadata.egress_port` = 3 (copied from standard_metadata.egress_pec value of 3, the value it had at end of ingress)
    + `ethernet.srcAddr` = original srcAddr
    + `mymeta.clone_e2e_count` = 0
    + `mymeta.f1` = 0
  + It results in the creation of clone #1 and the following packet sent out:
    + port=3
    + Ethernet `dstAddr` = 0x000000000003,
    + Ethernet `srcAddr` = original srcAddr - 23
    + Ethernet `etherType` = 0xdead

+ clone #1 egress
  + It starts egress processing with these metadata field values:
    + `standard_metadata.instance_type` = 2 (`PKT_INSTANCE_TYPE_EGRESS_CLONE`)
    + `standard_metadata.egress_port` = 5 (from config of clone session 1)
    + `ethernet.srcAddr` = original srcAddr - 23
    + `mymeta.clone_e2e_count` = 1
    + `mymeta.f1` = 23
  + It results in the creation of clone #2 and the following packet sent out:
    + port=5
    + Ethernet `dstAddr` = 0x000000000003,
    + Ethernet `srcAddr` = original srcAddr - 46
    + Ethernet `etherType` = 0xdead

+ clone #2 egress
  + It starts egress processing with these metadata field values:
    + `standard_metadata.instance_type` = 2 (`PKT_INSTANCE_TYPE_EGRESS_CLONE`)
    + `standard_metadata.egress_port` = 5 (from config of clone session 1)
    + `ethernet.srcAddr` = original srcAddr - 46
    + `mymeta.clone_e2e_count` = 2
    + `mymeta.f1` = 46
  + It results in the creation of clone #3 and the following packet sent out:
    + port=5
    + Ethernet `dstAddr` = 0x000000000003,
    + Ethernet `srcAddr` = original srcAddr - 69
    + Ethernet `etherType` = 0xdead

+ clone #3 egress
  + It starts egress processing with these metadata field values:
    + `standard_metadata.instance_type` = 2 (`PKT_INSTANCE_TYPE_EGRESS_CLONE`)
    + `standard_metadata.egress_port` = 5 (from config of clone session 1)
    + `ethernet.srcAddr` = original srcAddr - 69
    + `mymeta.clone_e2e_count` = 3
    + `mymeta.f1` = 69
  + It results in the creation of clone #4 and the following packet sent out:
    + port=5
    + Ethernet `dstAddr` = 0x000000000003,
    + Ethernet `srcAddr` = original srcAddr - 92
    + Ethernet `etherType` = 0xdead

+ clone #4 egress
  + It starts egress processing with these metadata field values:
    + `standard_metadata.instance_type` = 2 (`PKT_INSTANCE_TYPE_EGRESS_CLONE`)
    + `standard_metadata.egress_port` = 5 (from config of clone session 1)
    + `ethernet.srcAddr` = original srcAddr - 92
    + `mymeta.clone_e2e_count` = 4
    + `mymeta.f1` = 92
  + See below for the resulting packets

Clone #4 is processed differently than clones 1 through 3 during its
egress processing, because the condition `mymeta.clone_e2e_count <
MAX_CLONE_E2E_COUNT` is now the same as `4 < 4`, which is false.  So
for this packet, we apply the table `t_mark_max_clone_e2e_packet`,
which causes its default action `mark_max_clone_e2e_packet` to be
executed:

```
action mark_max_clone_e2e_packet () {
    put_debug_vals_in_eth_dstaddr();
    modify_field(ethernet.etherType, ETHERTYPE_MAX_CLONE_E2E);
}
```

The action `put_debug_vals_in_eth_dstaddr` is described in the
resubmit packet example above.  In this case the values of the fields
that affect the new value assigned to the Ethernet `dstAddr` field
are these:

```
mymeta.resubmit_count = 0
mymeta.recirculate_count = 0
mymeta.clone_e2e_count = 4
mymeta.f1 = 4*23 = 92 decimal = 0x5c hex
mymeta.last_ing_instance_type = 0
```

Thus the value of `ethernet.dstAddr` should become:

```
ethernet.dstAddr = 0x0000045c0000
```

No more tables are applied during egress processing for the packet, so
it should go out of port 5 with the following Ethernet header field
values:

```
ethernet.dstAddr = 0x0000045c0000
ethernet.srcAddr = <whatever value the packet arrived with> - 92
ethernet.etherType = ETHERTYPE_MAX_CLONE_E2E = 0xce2e
```

For example, if the input value of `ethernet.srcAddr` was 0, then
because P4 arithmetic of unsigned bit vectors is modulo `(2 to the
power <width of bit vector>)`, the output value can be calculated with
the help of a simple interactive Python session:

```python
>>> print('%12x' % (2**48 - 4*23))
ffffffffffa4
```


# Some details on why some versions of p4c lead to resubmit/recirculate/clone doing nothing

I filed this p4c issue on Github about resubmit not working:
https://github.com/p4lang/p4c/issues/1694

In the mean time, keep testing and developing the program
p414-special-ops.p4 using the 2018-11-26 version of p4c, which seems
to produce a working BMv2 JSON file.

+ p4c-2018-09-01 resubmit works
+ p4c-2018-11-01 resubmit works
+ p4c-2018-11-14 resubmit works
+ p4c-2018-11-28a (commit 22a5a13ee347dd40e6b7b6472e00ea2205db5358) resubmit does not work
+ p4c-2018-12-01 resubmit does not work

For the cases where resubmit works, the BMv2 JSON file contains a
header_type like this in the header_types section:

```
    {
      "name" : "intrinsic_metadata_t",
      "id" : 3,
      "fields" : [
        ["ingress_global_timestamp", 48, false],
        ["egress_global_timestamp", 48, false],
        ["lf_field_list", 8, false],
        ["mcast_grp", 16, false],
        ["egress_rid", 16, false],
        ["resubmit_flag", 8, false],
        ["recirculate_flag", 8, false]
      ]
    },
```

For the cases where resubmit does not work, the intrinsic_metadata
fields show up inside of a header_type with user-defined metadata
fields, like in the examaple below from p4c-2018-12-01:

```
    {
      "name" : "scalars_0",
      "id" : 0,
      "fields" : [
        ["metadata._intrinsic_metadata_ingress_global_timestamp0", 48, false],
        ["metadata._intrinsic_metadata_egress_global_timestamp1", 48, false],
        ["metadata._intrinsic_metadata_lf_field_list2", 8, false],
        ["metadata._intrinsic_metadata_mcast_grp3", 16, false],
        ["metadata._intrinsic_metadata_egress_rid4", 16, false],
        ["metadata._intrinsic_metadata_resubmit_flag5", 8, false],
        ["metadata._intrinsic_metadata_recirculate_flag6", 8, false],
        ["metadata._mymeta_resubmit_count7", 8, false],
        ["metadata._mymeta_recirculate_count8", 8, false],
        ["metadata._mymeta_clone_e2e_count9", 8, false],
        ["metadata._mymeta_f110", 8, false],
        ["metadata._temporaries_temp111", 48, false],
        ["metadata._temporaries_temp212", 48, false],
        ["metadata._temporaries_temp313", 48, false],
        ["metadata._temporaries_temp414", 48, false]
      ]
    },
```
