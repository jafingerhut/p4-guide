# Introduction

This article describes features that would be desirable in a currently
hypothetical language for precisely describing P4 architectures.


# Glossary

+ PSA - Portable Switch Architecture https://p4.org/specs
+ PNA - Portable NIC Architecture https://p4.org/specs
  https://github.com/p4lang/pna
+ TNA - Tofino Native Architecture
  https://github.com/barefootnetworks/Open-Tofino
+ TNA packet generators - See Section 9 "Packet Generation" of
  https://github.com/barefootnetworks/Open-Tofino/blob/master/PUBLIC_Tofino-Native-Arch.pdf
  for details.
  + Given that P4 is fundamentally a language for processing packets,
    it is often very useful in a P4-programmable network device to
    have a feature that enables certain kinds of events to cause
    packets to be created and injected into the packet processing
    pipeline of the device.  This effectively generalizes a user's P4
    code from only processing packets, to processing a mix of packets
    and events.
+ v1model - The v1model architecture as implemented in the BMv2
  software switch https://github.com/p4lang/behavioral-model
  and at least partially documented here
  https://github.com/p4lang/behavioral-model/blob/main/docs/simple_switch.md
+ DPDK - Data Plane Development Kit https://www.dpdk.org
  https://github.com/p4lang/p4c/tree/main/backends/dpdk


# Background

A P4 parser lets you precisely specify how a packet header parser
behaves.

A P4 control lets you precisely specify how a part of a packet
processing device behaves that typically contains one or more P4
tables, and invocations of some extern functions or methods.  P4
controls are also used to define the behavior of deparsers.

While P4 parsers and controls might be used within a network device to
specify most of how the device processes packets, there is always
additional behavior of the device that is _not_ specified in a P4
parser or control [see Note 1].

This additional behavior is specified in a P4 architecture, where
prominent examples of these include:

+ PSA
+ PNA
+ TNA

A P4 developer must know something about a device's P4 architecture in
order to successfully write P4 code for the device, e.g. in order to
know what code they must write in order to drop a packet, send a
packet to a single port, replicate a packet, etc. [see Note 2].

Note 1: Except perhaps in toy example P4 architectures.

Note 2: Some may find it surprising that there is no standard way
across all P4 architectures to drop a packet, nor to send a packet to
a single output port.  In fact, the means of doing these things is
slightly different in all of the example architectures mentioned in
this document.


# How P4 architectures are specified today

The ways of describing a P4 architecture that are common today include:

+ A combination of P4 include files, English text, and pseudocode used
  to define PSA, PNA, and TNA.  The P4 include files define the inputs
  and outputs of P4 parsers and controls in the architecture, and
  extern functions, objects, and methods, but the behavior of these
  things is _not_ defined in the P4 include files, only the data plane
  API.
+ Implementations of P4 architectures are described in voluminous
  detail in their implementations.  Examples include:
  + The C++ code in https://github.com/p4lang/behavioral-model that
    implements the v1model architecture.  The implementation is spread
    over many files, but as an example of part of the C++ code that
    may be of particular interest, see the methods
    [`ingress_thread`](https://github.com/p4lang/behavioral-model/blob/6ec3ef834fb5e2eb6da39f79d31fee9c0d7594f9/targets/simple_switch/simple_switch.cpp#L478)
    and
    [`egress_thread`](https://github.com/p4lang/behavioral-model/blob/6ec3ef834fb5e2eb6da39f79d31fee9c0d7594f9/targets/simple_switch/simple_switch.cpp#L644)
  + The C and/or C++ code in the P4 DPDK implementation of PSA and PNA.
  + Many tens of thousands of lines of Verilog/VHDL implementing an
    ASIC like Tofino, specifying the behavior down to the precise bit
    level and what happens in every flip-flop, logic gate, SRAM word,
    and TCAM entry of the ASIC on every clock cycle.

It is not possible today to feed English text and pseudocode into
formal analysis tools.  It might be possible to do so with C, C++,
Verilog, or VHDL implementations, but for many purposes we would
prefer a much shorter human-readable precise specification instead of
these more detailed specifications.


# Goals of a new language for specifying P4 architectures

The goals of such a specification language include:

+ Precisely describe the behavior of a P4 architecture, in enough
  detail for at least the following purposes:
  + Consume this language in formal analysis tools such as P4testgen
    (https://github.com/p4lang/p4c/tree/main/backends/p4tools/modules/testgen),
    using this description to predict the expected possible behaviors
    of the device.
  + Consume this language in a behavioral model such as the BMv2
    software switch `simple_switch`, or some other software switch
    such as P4 DPDK or P4 EBPF, and simulate a device with that P4
    architecture.  It would be nice if it could also be consumed by P4
    implementations for FPGAs that support users creating their own
    custom P4 architectures, but that likely requires more work.
+ Be concise enough that at least the essentials of a P4 architecture
  like the PSA can be written in a few hundred lines.  Human readers
  are a primary "target" for specifications written in this language.

In summary, we want to enable writing specifications that are precise
and "executable", with little effort required to use a single
specification for both of these purposes.

Non-goals of such a specification language are:

+ Precisely describe the behavior of a P4 architecture down to the
  level of detail of doing performance simulations
  + For example, the proposed language would not be targeted at
    defining how a packet scheduling algorithm in a traffic manager
    works.  At most one might use the language to describe that there
    are multiple FIFO packet queues in a traffic manager, and a packet
    scheduling algorithm non-deterministically selects among the
    non-empty packet queues to choose the next packet to transmit.
+ Achieving the highest performance implementation on any particular
  target device, whether a general purpose CPU or otherwise.
  + We are not trying to _prevent_ high performance implementations in
    this language, but such concerns should be lower priority than the
    goals described above.
+ Describe the behavior of an implementation in rare scenarios like
  single-event upsets
  (https://en.wikipedia.org/wiki/Single-event_upset).  We are not
  trying to prevent this from being possible, but also not expending
  any effort to ensure that this is possible.


# Capabilities needed in a language for specifying architectures

Note: P4 parsers and controls can assign values to metadata and/or
call extern functions that indicate that a packet should be dropped
later, but parsers and controls are fundamentally "one packet plus
metadata in, one packet plus metadata out" kinds of entites in the
P4-16 language specification:

+ Some discussion of this topic among P4 language designers can be
  found here: https://github.com/p4lang/p4-spec/issues/893

Thus all actual dropping or replicating of a packet happens _outside_
of parsers and controls.  If these operations are desired, they must
be done in the architecture.

Opinion: Packet contents should be represented by a sequence of bytes,
from some minimum length up to some maximum length specified by the
architecture.  Architectures should be able to modify these packets in
pretty much arbitrary ways, if they wish, e.g. to implement features
like encryption, decryption, compression, etc.

Packets will typically have metadata associated with them.  In an
architecture definition, it is likely that there will be
architecture-defined metadata fields associated with a packet that are
not visible to the P4 developer.

Capabilities are given names of the form `C<number>` below.


## C1

Receive packets from "outside the device", labeled with metadata
indicating where the packet came from, and optionally additional
metadata.


## C2

Send packets to "outside the device", labeled with metadata indicating
where the packet should go to, and optional metadata associated with
the packet.


## C3

Drop a packet.


## C4

Make a clone of a packet, both the packet contents and its associated
metadata.
  
You might wonder: Why not provide fancier operations than merely
cloning a packet?  For example, why not provide a a packet replication
engine as a primitive?

Answer: Because we want to be able to _define_ how a packet
replication engine works, out of simpler primitive operations.  There
are many possible ways to define the capabilities of a packet
replication engine (e.g. TNA has many more features and options in its
packet replication engine than defined in PSA).  Making exactly one
clone of a packet, then modifying the clone and directing where it
goes, within a loop, is about the simplest set of primitive operations
I can think of that would enable defining the behavior of any packet
replication engine.

It also enables defining packet mirroring/cloning operations, too.


## C5

Create a new packet with specified contents and metadata.

This is useful for defining the behavior of things like TNA's packet
generators, which can create new packets that did not come from
outside of the device, but can be created based on various internal
triggers, e.g. a configurable length of time has passed (see the link
in the glossary for more details).


## C6

Parsers must output the offset of the first bit/byte of a packet that
they did not parse.

This is necessary in order for the architecture to carry this value
with the packet to the part of the device that deparses the packet,
and optionally appends the unparsed portion of the packet to the end
of the deparsed headers.


## What we should be able to specify with C1 through C6

P4 architecture features that we should be able to specify using the
capabilities C1 through C6:

+ resubmit
+ recirculate
+ multicast replication
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

Define background processes that run periodically.

Meter externs require at least one of C8 or C9.

C8 enables a specification/implementation of Meter externs that
explicilty store for each index the last time that the Meter was
updated, `last_update_time`.  Every time an index of the Meter is
updated, the implementation reads `last_update_time`value, determines
how much time has elapsed since then, and calculates the number of new
tokens that should be added to the Meter's bucket(s) from that elapsed
time and the control plane configuration of the Meter index.

C9 enables a specification/implementation of Meter externs that does
not need to store the last time that the Meter was updated.  Instead,
a periodic background process iterates over all indexes of the Meter,
adding tokens to its bucket(s).

With neither C8 nor C9, I do not see any way to specify the behavior
of Meter externs.

C8 is also needed in defining P4 architectures that provide metadata
to P4 developers like traffic manager enqueue time, dequeue time,
length of time a packet spent in a queue, etc.

C9 seems to be necessary in order to specify the behavior of TNA
packet generators.


## C10

Define processes that run when a port down or port up event occurs.

C10 is needed for implementing the "Port down trigger" option of TNA
packet generators (see glossary for link to details).


## C11

Define a way to send messages to the "local runtime software".

C11 is needed for implementing the Digest extern, and for sending idle
timeout notification messages for tables with the idle timeout option
enabled.


## C12

There should be a looping construct.  See discussion of C4 on packet
replication engines for one example architecture feature that is
definitely desired in order to fully specify a P4 architecture.

For the purposes of formally reasoning about a P4 architecture, it is
probably desirable to limit such loops to be bounded to a finite
number of iterations.

One approach would be to limit all looping features to a constant
maximum number of iterations, where the constant is known at "compile
time".  This might be sufficient.  For example, a parameter of an
architecture specification could be "K is the longest packet
replication list supported for any multicast group", and thus for
example K=10,000 would be a compile-time known limit on the maximum
number of iterations of the loop specifying the behavior of the packet
replication engine.  In practice, all implementations of P4
architectures have such finite size limits.

Another approach would be a little more vague, where the looping
construct was allowed to iterate over elements of a list/array data
structure in the specification language, with the understanding that
all such list/arrays at run time have a finite length, even if the
maximum length is not known at compile time.

I am sure that better experts than I on formal analysis tools can
provide input on whether the distinction above is significant, and
what the tradeoffs are.


## C13

Be able to do arithmetic and evaluate conditions on variables of P4-16
data types, especially `bit<W>`, but in general all P4-16 types.

This strongly suggests that this specification language should be a
superset of P4-16, including as a subset all P4-16 data types and
operations on them.

Interestingly (to me), the recent addition of the `list` data type to
the P4-16 language spec could be quite useful in using P4-16 as an
architecture specification language, especially by introducing some
operations that enable such lists to be modified at run time.


## Other straightforward-looking features

TODO: Other externs that look easy, in the sense that their behavior
is either:

+ output is pure function of inputs, with no internal state

or the slightly more complicated, but still easy to specify and
formally reason about:

+ There is internal state that can be updated either via control plane
  API, or during packet processing.
  + The return value(s) are a pure function of the input parameters
    and current internal state.
  + The next internal state is also a pure function of the input
    parameters and the current internal state.

+ Hash
+ Checksum
+ InternetChecksum
+ Random


## Other features that might need a bit more thought

TODO: Other architecture features that will need a bit more thought to
figure out a syntax and semantics for specifying them:


### Features with per-table-entry state modified in data plane

DirectCounter/Meter - like Counter and Meter, but need a way to
specify that their state is one-to-one with entries of a table, and
such state is added and deleted when the corresponding table entries
are added and deleted.

idle timeout, both PSA version and PNA more general version - like
DirectCounter and DirectMeter in that they have per-table-entry state
required.  This also requires a way to run periodic background
processes, e.g. to determine if it is time to send an idle timeout
notification to the controller.


### Features that modify the behavior of match-action tables

For all of the architecture features in this section, it seems like
writing precise specifications for them would be best done if we first
define the existing behavior of normal P4 tables in a concise manner,
e.g. model them in the specification language as a set of (key, value)
pairs, with a specification language primitive for "execute the action
specified by this value".

new match kinds - Given the kind of specification of existing
match-action tables described above, which should include the behavior
of standard match kinds like exact, lpm, ternary, defining new match
kinds should become a modification of the part of that specification
describing how search keys are compared against table entry keys, and
whether they match.

add-on-miss feature of PNA - Given the above, a definition of
add-on-miss would become a simple enhancement to that specification:
on a miss, add a new (key, value) pair in the data plane if the extern
function `add_entry` is called.

ActionProfile - This modifies how one gets from a matching table entry
to the "action plus action-parameters that should be invoked".

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


# Control plane APIs

It seems reasonable to consider including in such a specification
language a way to specify the effects of control plane API operations.

One way that might simplify this is to adopt the TDI "philosophy"
which I would describe as follows:

+ For every extern object or fixed function block, define one or a few
  P4 tables that represent its configuration state.
+ All control plane API operations on this object are invokable from
  control plane software as an add/delete/modify operation on one of
  those P4 tables.
