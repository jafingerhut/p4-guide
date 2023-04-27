# Introduction

A P4 parser lets you precisely specify how a packet header parser
behaves.

TODO: The P4-16 language spec does not fully specify the control plane
API of parser value sets, but does give English prose specifying the
data plane behavior.

A P4 control lets you precisely specify how a part of a packet
processing device behaves that typically contains one or more P4
tables, and invocations of some xtern functions or methods.



# Capabilities needed in a language for specifying architectures

Note: P4 parsers and controls can assign values to metadata and/or
call extern functions that indicate that a packet should be dropped
later, but parsers and controls are fundamentally "one packet plus
metadata in, one packet plus metadata out" kinds of entites in the
P4-16 language specification (TODO: link to public Github issue with
discussion on this topic).  Thus all actual dropping or replicating of
a packet happens _outside_ of parsers and controls.  If these
operations are desired, they must be done in the architecture.

Opinion: Packet contents should be represented by a sequence of bytes,
from some minimum length up to some maximum length specified by the
architecture.  Architectures should be able to modify these packets in
pretty much arbitrary ways, if they wish, e.g. to implement features
like encryption, decryption, compression, etc.

Packets will typically have metadata associated with them.  In an
architecture definition, it is likely that there will be
architecture-defined metadata fields associated with a packet that are
not visible to the P4 developer.


## C1

Receive packets from "outside the device", labeled with metadata
indicating where the packet came from, and optionally additional
metadata.

## C2

Send packets to "outside the device", labeled with metadata indicating
where the packet should go to, and optional additional metadata.

## C3

Drop a packet.

# C4

Make a clone of a packet, both the packet contents and its associated
metadata.
  
You might wonder: Why not provide fancier operations than merely
cloning a packet, e.g. a packet replication engine primitive.  My
answer is: because we want to be able to _defin_ how a packet
replication engine primitive works, out of simpler primitive
operations.  There are many possible ways to define the capabilities
of a packet replication engine (e.g. Tofino ASICs have more features
and options in their packet replication engines than defined in PSA).
Making exactly one clone of a packet, then modifying the clone and
directing where it goes, within a looping construct, is about the
simplest set of primitive operations I can think of that would enable
defining the behavior of any packet replication engine, and it also
enables defining packet mirroring/cloning operations, too.

## C5

Create a new packet with specified contents and metadata.

This is useful for defining the behavior of things like TNA's packet
generators.


## C6

Parsers must output the offset of the first bit/byte of a packet that
they did not parse.

This is necessary in order for the architecture to pass this value on
to the part of the device that deparses the packet, and optionally
appends the unparsed portion of the packet to the end of the deparsed
headers.


## What we should be able to specify with C1 through C6

Operations that should be specifiable using the primitives above:

+ resubmit
+ recirculate
+ multicast
+ unicast
+ drop
+ mirror/clone


Now let us go through some PSA externs and see what primitives we
might need in specifying their behavior:


## C7

Array data structures containing elements of identical type, which
could be scalars, structs, and perhaps safe unions might be
convenient.

Using this, we should be able to specify the behavior of Register and
Counter externs.

## C8

Get the current time.

## C9

Define background tasks that run periodically.

Meter externs require at least one of C8 or C9.

C8 enables a specification/implementation of Meter externs that
explicilty store for each index the last time that the Meter was
updated, and use this stored value to add new tokens to its buckets
the next time it is updated.

C9 enables a specification/implementation of Meter externs that does
not need to store the last time that the Meter was updated.  Instead,
a periodic background task iterates over all indexes of the Meter,
adding tokens to its bucket(s).

With neither C8 nor C9, I do not see any way to specify the behavior
of Meter externs.  C8 is also needed for providing metadata to P4
developers like traffic manager enqueue time, dequeue time, length of
time a packet spent in a queue, etc.

C9 seems to be necessary in order to specify the behavior of TNA
packet generators.


## C10

Define tasks that run when a port down or port up event occurs.

C10 is needed for implementing one of the options in the TNA packet
generator.


## C11

Define a way to send messages to the "local runtime software".

C11 is needed for implementing the Digest extern.



TODO: Other externs that look easy, in the sense that they are pure
functions of their current state and data plane method input
parameters.

+ Hash
+ Checksum
+ InternetChecksum
+ Random

TODO: Other architecture features that will need a bit more thought to
figure out how to specify.

DirectCounter/Meter - like Counter and Meter, but need a way to
specify that their state is one-to-one with entries of a table, and
such state is added and deleted when the corresponding table entries
are added and deleted.

idle timeout, both PSA version and PNA more general version - like
DirectCounter and DirectMeter in that they have per-table-entry state
required.  This also requires a way to run periodic background tasks,
e.g. to determine if it is time to send an idle timeout notification
to the controller.

new match kinds - this seems like it will require some kind of in-code
definition of how the existing match kinds behave.

ActionProfile - This modifies how one gets from a matching entry to
the action plus action-parameters that should be invoked.

ActionSelector - This modifies how one gets from a matching entry to
the action plus action-parameters that should be invoked, in a more
complex way than the ActionProfile extern does.  I suspect all of
these implementations are at least slightly different from each other:

+ BMv2 + v1model
+ DPDK + PSA
+ TNA

and any of those that implement the P4Runtime API watch port feature
seem to require a way for an architecture definition to respond to
link down events.
