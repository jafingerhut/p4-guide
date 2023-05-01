# Introduction

This directory contains a first attempt at specifying the PSA
(Portable Switch Architecture) using a language that I will be
experimenting with as I go.

The structure of this specification is a set of tasks with guard
conditions on each task.  Any task whose guard condition is true can
be executed, and the choice between them is arbitrary.  Logically one
event is processed at a time in the system.  Of course a real
implementation would often perform many of these tasks in parallel,
but for simplicity of writing and understanding the specification, the
code is written in a way that assumes that at most one task is
executed at a time.

Because of this, a real implementation might allow behavior that is
visible to "the outside" that is impossible according to this
specification.

TODO: I cannot think of an example of this at the moment, but have
marked this with TODO to remind me to think of it more later, after
the specification is written.


# Parameters defining a PSA implementation

Refer to [this article](../psa-notes.md) on parameters that affect the
behavior of a PSA implementation.

Below I will give choices for some of those options mentioned in that
article, to be used in writing this specification.


# Details that the PSA specification is vague about


## What is included in the packet as given to the parser, and expected out of the deparser?

This example specification requires that the packet given to the
parser, and expected out of the deparser, includes none of these parts
of the Ethernet frame:

+ Preamble
+ Start frame delimiter
+ Ethernet FCS (Frame Check Sequence, aka CRC)
+ Ethernet Interpacket gap


## What packet length is used when updating Counter and Meter externs that use packet length?

This example specification uses the length of the packet as received
by the P4 parser most recently before the counter or meter extern
method is called, which is the PSA ingress parser for counter and
meter operations invoked during ingress, and the PSA egress parser for
counter and meter operations invoked during egress.


## What happens if a packet output by a deparser is outside of supported range of lengths?

This example specification will drop packets output by a deparser that
are shorter than `MinPacketLength`, or longer than `MaxPacketLength`.


## Useful operations / primitives for a P4 architecture specification language

Operations / notation that seems generally useful for specifying many
architectures, not only this one:

##

Convert a header to/from a bit vector - useful for specifying behavior
of emit() and extract().


# State that is "global" in the architecture

## Traffic manager configuration state

This state changes only when the control plane makes explicit API
calls to change it.  Processing packets never causes it to change,
except perhaps for any packet/byte counters that might be included.

## Traffic manager dynamic state

This state can change as packets are processed, perhaps even for most
or all packets processed.

+ `tmq[port][class]` - A queue of packets with class `class` destined
  for port `port`, ready to do egress processing

I will consider the set of ports and classes to be unchanging for now.
Some implementations may enable ports to be enabled or disabled at run
time (e.g. reconfiguring a 100 Gbps Ethernet port to operate instead
as 4 separate 25 Gbps Ethernet ports), or to add or remove classes to
a port at run time.


## Ingress dynamic state

Separate queues for packets from these places:

+ `newq` - New packets from the outside, ready to do ingress processing
+ `resubq` - Resubmitted packets, ready to do ingress processing
+ `recircq` - Recirculated packets, ready to do ingress processing

Note: An implementation might have multiple recirculation queues,
e.g. one per some kind of traffic class value.  Similarly it might
have a separate `newq` per (input port, traffic class) pair.


## Egress dynamic state


# Top level "parameters" when instantiating a particular P4 program in the PSA architecture

The types `IH`, `IM`, etc. that are type parameters to the package
`PSA_Switch` in the psa.p4 include file, exercpted below:

```
package PSA_Switch<IH, IM, EH, EM, NM, CI2EM, CE2EM, RESUBM, RECIRCM> (
    IngressPipeline<IH, IM, NM, CI2EM, RESUBM, RECIRCM> ingress,
    PacketReplicationEngine pre,
    EgressPipeline<EH, EM, NM, CI2EM, CE2EM, RECIRCM> egress,
    BufferingQueueingEngine bqe);
```
