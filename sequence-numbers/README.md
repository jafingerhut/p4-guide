# Introduction

There are multiple uses for sequence numbers in packets, providing
different kinds of guarantees.

In all cases that I can think of where sequence numbers are used in
data plane network protocols (as opposed to control plane protocols,
e.g. routing protocols), there are the following two "places" in the
network that are significant:

+ encap: the place where sequence numbers are added to messages
+ decap: the place where sequence numbers are removed from messages

For the typical use of TCP where a client program connects to a server
program on different physical machine and sends data to the server,
the encap point is the TCP implementation in the operating system of
the client host, and the decap point is the TCP implementation in the
operating system of the server host.

Different network protocols use sequence numbers to provide different
kinds of guarantees.

Aside: When I say "guarantees", such guarantees are conditional.  They
can be provided if messages in flight from the encap point to the
decap point are either delivered before the sender has sent over half
of the sequence number space after the in-flight message, or they are
dropped in the network.  Messages delivered by the network to the
decap point with a longer latency than this can cause aliasing,
i.e. the inability of the decap point to distinguish old messages from
new messages, and make it impossible to provide these guarantees.

In some cases, the protocol implementation at the encap point tries to
avoid sending new sequence numbers that might be aliased at the decap
point, if the bandwidth-delay product is high (e.g. TCP and RDMA RC
mode do this).  However, even these attempts cannot prevent the decap
point from being confused by sequence number aliasing if the network
takes arbitrarily long to deliver messages.

Under the assumption of a network that either drops or delivers
messages in a timely enough fashion, below are at least some kinds of
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



# References

IPsec ESP use of sequence numbers in anti-replay attack detection.
One interesting difference between IPsec sequence numbers and most
other network protocols is that no sequence number can ever be
repeated by the encap point for an IPsec ESP security association.
The sender must establish a new security association rather than
continuing to use an existing one that has exhausted all of its
sequence numbers, and never wrap around.

+ "IP Encapsulating Security Payload (ESP)", 2005,
  https://tools.ietf.org/html/rfc4303

+ "IPsec Anti-Replay Algorithm without Bit Shifting", 2012,
  https://tools.ietf.org/html/rfc6479

+ "Analysis and improvement on IPSec anti-replay window protocol",
  2003, https://ieeexplore.ieee.org/document/1284223 - I have not read
  this paper yet, so do not know how useful its contents are.  It
  appears not to be any kind of IETF standard.




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
