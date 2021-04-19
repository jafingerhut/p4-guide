# Introduction

This article describes some asepcts of how sequence numbers are used
in several data plane network protocols, and what kinds of guarantees
of behavior they help provide.


## Definitions

In all cases that I can think of where sequence numbers are used in
data plane network protocols (as opposed to control plane protocols,
e.g. routing protocols), there are the following two "places" in the
network that are significant:

+ encap point: the place where sequence numbers are added to messages
+ decap point: the place where sequence numbers are removed from
  messages

As one example, for the typical use of TCP where a client program on
computer A connects to a server program on computer B, for the
messages sent from client to server the encap point is the TCP
implementation in the operating system of computer A, and the decap
point is the TCP implementation in the operating system of computer B.


## Guarantees on behavior provided by protocols

Different network protocols use sequence numbers to provide different
kinds of guarantees.

Under the assumption of a network that either drops or delivers
messages in a timely-enough fashion, below are at least some kinds of
guarantees that protocols with sequence numbers can be used to
provide:

+ in-order, reliable, at-most-once delivery: Every message is
  delivered out of the decap point at most once, in the same relative
  order that they entered the encap point.  In exceptional
  circumstances (e.g. partial or complete network failures that
  prevent messages from being delivered to the decap point for too
  long), the connection is broken and only a prefix of the messages
  entering the encap point are delivered out of the decap point.  In
  the common situation that the connection is not broken, all messages
  are delivered out of the decap point exactly once, in the order they
  are sent to the encap point.  Examples include TCP and Reliable
  Connection (RC) mode RDMA.

+ in-order, unreliable, at-most-once delivery: Messages sent into the
  encap point are delivered out of the decap point at most once,
  i.e. either exactly once, or they are lost.  All not-lost messages
  are delivered out of the decap point in the same relative order that
  they were sent to the encap point.  There can be "gaps" in the
  middle of the sequence of messages out of the decap point.  Examples
  include L2TPv3 and GRE tunnels with the option to enable sequence
  numbers enabled.

+ possibly out-of-order, unreliable, at-most-once delivery: Messages
  sent into the encap point are delivered out of the decap point at
  most once.  Non-lost messages might be delivered out of the decap
  point in a different relative order than they were sent to the encap
  point.  Examples include IPsec with its rules for detecting replay
  attacks, which explicitly allow the decap point to deliver messages
  in a different relative order than they entered the encap point.


### These guarantees are conditional

When I say "guarantees", such guarantees are conditional.  Such a
guarantee can be provided if a message in flight from the encap point
to the decap point with sequence number S is either:

+ delivered to the decap point before the encap point has sent over
  half of the sequence number space after S, or
+ it is dropped in the network, i.e. never delivered to the decap point.

Messages delivered to the decap point with a longer latency than this
can cause aliasing, i.e. the inability of the decap point to
distinguish old messages from new messages.  Such high-latency network
behavior makes it impossible for the decap point to provide any of the
guarantees described below.

In some cases, the protocol implementation at the encap point tries to
avoid sending new sequence numbers that might be aliased at the decap
point, e.g. TCP and RDMA Reliable Connection (RC) mode do this.
However, even these attempts cannot prevent the decap point from being
confused by sequence number aliasing if the network takes arbitrarily
long to deliver messages.



# References

IPsec ESP use of sequence numbers in anti-replay attack detection.
One interesting difference between IPsec sequence numbers and most
other network protocols is that no sequence number can ever be
repeated by the encap point for an IPsec ESP security association.
The sender must establish a new security association rather than
continuing to use an existing one that has exhausted all of its
sequence numbers, and never wrap around.

+ "IP Encapsulating Security Payload (ESP)", 2005,
  https://tools.ietf.org/html/rfc4303 - Especially sections 2.2,
  3.3.3, and 3.4.3

+ "IPsec Anti-Replay Algorithm without Bit Shifting", 2012,
  https://tools.ietf.org/html/rfc6479

+ "Analysis and improvement on IPSec anti-replay window protocol",
  2003, https://ieeexplore.ieee.org/document/1284223 - I have not read
  this paper yet, so do not know how useful its contents are.  It
  appears not to be any kind of IETF standard.



# Material that may be incorporated later


and perhaps the messages are processed
and/or forwarded on from that removal point.

+ IPsec tunnels - the tunnel encapsulation point inserts incrementing
  sequence numbers into encapsulated packets, and the tunnel
  decapsulation point is required to do anti-replay attack detection,
  defined in the IETF RFCs, to ensure that at most one packet with
  each sequence number is forwarded onwards.  It must also support a
  limited amount of packet reordering in the network between
  encapsulation and decapsulation point.

+ TCP sequence numbers - I may not discuss these in much detail here,
  as I doubt that P4-programmable devices will be good for TCP
  termination purposes any time soon.  I am happy to be proven wrong
  on that point, but TCP termination is a much more complex stateful
  task than the other packet processing behavior described here.
