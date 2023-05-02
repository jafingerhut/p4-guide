# Introduction

This document discusses the kinds of things that can vary from one
implementation of the Portable Switch Architecture (PSA) to another.

One way to handle at least some such differences between PSA
implementations in a precise specification is to have a parameterized
specification, i.e. one that after you specify some values for a set
of parameters, the specification uses those values to affect its
behavior.


# Parameters defining a PSA implementation

Different PSA implementations may differ in the following things (and
perhaps in other things not listed here):

+ Specific bit widths for these types defined in the
  customized-for-the-implementation psa.p4 include file, in place of
  the words `unspecified`:

```
typedef bit<unspecified> PortIdUint_t;
typedef bit<unspecified> MulticastGroupUint_t;
typedef bit<unspecified> CloneSessionIdUint_t;
typedef bit<unspecified> ClassOfServiceUint_t;
typedef bit<unspecified> PacketLengthUint_t;
typedef bit<unspecified> EgressInstanceUint_t;
typedef bit<unspecified> TimestampUint_t;
```

+ `PortIdSet` - Non-empty set of non-negative integers, each a port id
  of the PSA implementation.  Each must be a value of type
  `PortIdUint_t`.  It must contain at least the values `PSA_PORT_CPU`
  and `PSA_PORT_RECIRCULATE`, and it really only makes sense to call
  an implementation a switch if it contains multiple other port ids
  used to identify front panel ports.  TODO: Is 0 allowed in this set?

+ `PSA_PORT_CPU` - A positive integer that is in `PortIdSet`.

+ `PSA_PORT_RECIRCULATE` - A positive integer that is in `PortIdSet`,
  and is not equal to `PSA_PORT_CPU`.

+ `MulticastGroupIdSet` - Non-empty set of non-negative integers, each
  a multicast group id value supported by the implementation.  Each
  must be a value of type `MulticastGroupUint_t`.  TODO: Is 0 allowed
  in this set?

+ `CloneSessionIdSet` - Non-empty set of non-negative integers, each a
  clone session id value supported by the implementation.  Each must
  be a value of type `CloneSessionIdUint_t`.  TODO: Is 0 allowed in
  this set?

+ `PSA_CLONE_SESSION_TO_CPU` - An integer in the set
  `CloneSessionIdSet`.  It is called out separately simply because it
  is a name that P4 developers writing code for PSA devices can rely
  on the fact that this value exists and is stable, even though the
  numeric value might differ from one PSA implementation to another.

+ `ClassOfServiceIdSet` - Non-empty set of non-negative integers, each
  a class of service value supported by the implementation.  Each must
  be a value of type `ClassOfServiceUint_t`.  The value 0 must be in
  this set.

+ `MinPacketLength`, `MaxPacketLength` - In units of bytes.
  `MinPacketLength` >= 1 byte.  `MaxPacketLength` >=
  `MinPacketLength`.  Both of these values must be of type
  `PacketLengthUint_t`.  Example: An implementation supporting Jumbo
  Ethernet frames might support packet lengths in the range
  `MinPacketLength`=64 bytes up to and including
  `MaxPacketLength`=9216 bytes.  See the Wikipedia page on Jumbo
  frames and some of the links to other articles it contains.  It
  appears there is no one single standard value for the longest Jumbo
  Frame supported across all devices.

+ `EgressInstanceSet` - Non-empty set of non-negative integers, each a
  alue of type `EgressInstance_t` that is supported by the
  implementation.  Each must be a value of type
  `EgressInstanceUint_t`.

Note: PSA explicitly warns that PSA implementations may have "gaps" in
the set `PortIdSet`.  For example, `PortIdSet` might contain all even
integers from 2 through 100, but no odd integers.

The PSA specification does not explicitly say this about the other
sets mentioned above.  It seems likely to me that most implementations
would not have gaps in the other sets.


# Parameters when loading a particular P4 program in the PSA architecture

There are several types, usually defined as P4 structs, that a P4
developer writing a program for PNA creates.  In an implementation,
values of several of these types need to be "carried along" with
packets, e.g. the user-defined metadata struct that is output by the
IngressParser, input to Ingress control, typically modified by Ingress
control code, then output to the IngressDeparser.  This struct type is
called `IH` in the `psa.p4` include file, excerpted below.

```
package PSA_Switch<IH, IM, EH, EM, NM, CI2EM, CE2EM, RESUBM, RECIRCM> (
    IngressPipeline<IH, IM, NM, CI2EM, RESUBM, RECIRCM> ingress,
    PacketReplicationEngine pre,
    EgressPipeline<EH, EM, NM, CI2EM, CE2EM, RECIRCM> egress,
    BufferingQueueingEngine bqe);
```

I will use the types `IH`, `IM`, etc. that are type parameters to the
package `PSA_Switch` in the specification `psa-try1.p4` whenever it is
convenient.  The architecture definition never "looks inside" values
of these types -- it simply carries values of these types with packets
at appropriate parts of the packet flow.


# Details that the PSA specification is vague about


## What is included in the packet as given to the parser, and expected out of the deparser?

For Ethernet ports, the PSA specification does not say exactly what
the packet given to the P4 parser includes.

Referring to these details about the Ethernet frame format:

+ https://en.wikipedia.org/wiki/Ethernet_frame
+ https://en.wikipedia.org/wiki/Interpacket_gap

Does the packet sent into a P4 parser include these things?

+ Preamble
+ Start frame delimiter
+ Ethernet FCS (Frame Check Sequence, aka CRC)
+ Ethernet Interpacket gap

I do not know of any P4 implementations that include the Ethernet
preamble, start frame delimiter, or interpacket gap in the packet as
given to the P4 parser.  I do know of some P4 implementations that
include the FCS in the packet given to the P4 parser (I believe that
Tofino behaves this way), and some that do not include the FCS (I
believe the v1model implementation in BMv2 `simple_switch` behaves
this way).

Similar questions exist for what the implementation expects as the
packet output by the deparser.  It would be less confusing if an
implementation was consistent in what parts of the packet must be
included for both the packet given as input to the P4 parser, and the
packet expected as output of the deparser.


## What packet length is used when updating Counter and Meter externs that use packet length?

This is not specified in PSA.


## What happens if a packet output by a deparser is outside of supported range of lengths?

A deparsed packet could be shorter than `MinPacketLength`, e.g. if one
or more headers are removed and the payload is short, or could be
longer than `MaxPacketLength`, e.g. if one or more headers are added
and the payload is long.

PSA does not specify what happens for such packets.
