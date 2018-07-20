# Terminology

I will use the term "agent" to mean a software component that is
device-dependent, and implement the P4Runtime API from the server
side.  It is called a server in the P4Runtime specification.  I will
use "controller" to mean the software that makes calls to the
agent/server in order to request changes to the configuration of the
device, e.g. adding and removing table entries.  It is called a client
in the P4Runtime specification.

The controller/agent interaction issues mentioned here are somewhat
tailored for the P4Runtime v1.0 specification, but the issues of how
they might deal with hit indexes should be more general, regardless of
the API used.


# Introduction

The idea of having a 'hit index' available for use in a P4 program has
come up before multiple times, e.g. on the p4-design email list:

http://lists.p4.org/pipermail/p4-design_lists.p4.org/2017-March/000825.html

This article is intended to demonstrate how having such an option will
affect writing control plane software, vs. the current state of the
the P4_14 and P4_16 languages and the P4Runtime API, which does not
make a hit index available in the data plane.


# Linking fields between tables

The P4_14 and P4_16 languages include the ability to add entries to
tables, and for each such table entry to choose which action is
performed when that table entry is matched.  Actions can be defined
with 0 or more parameters, and the control plane specifies values for
those action parameters when adding an entry to a table.

Such action parameter values are often copied into 'metadata',
i.e. variables local to the processing of one particular packet.  The
values can be used for many purposes, but one common use I will call a
"linking field".  By this I mean that the value will be used as part
(or all) of a search key of a table later in the packet processing.

The partial P4 program below illustrates this.  The action parameter
`l2ptr` of table T1's action `set_l2ptr` is saved in `meta.l2ptr`, and
later used as the entire search key for table T2.

```
struct metadata {
    bit<20> l2ptr;
}

control ingress(inout headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata)
{
    action set_l2ptr(bit<20> l2ptr) {
        meta.l2ptr = l2ptr;
    }
    table T1 {
        key = {
            hdr.ipv4.dstAddr: lpm;
        }
        actions = {
            set_l2ptr;
            my_drop;
        }
        default_action = my_drop;
    }

    action set_bd_dmac_intf() {
        // ... omitting code that would normally be here, since it is
        // not relevant to the example ...
    }
    table T2 {
        key = {
            meta.l2ptr: exact;
        }
        actions = {
            set_bd_dmac_intf;
            my_drop;
        }
        default_action = my_drop;
    }

    apply {
        T1.apply();
        T2.apply();
    }
}
```

Suppose the control plane wishes to create a new entry in both tables
T1 and T2, where the result of T1 causes the new entry of table T2 to
be used.

This could be done in the order:

    write new entry to table T1
    write new entry to table T2

If this is done, then potentially many packets could be processed by
the data plane after the new entry is written to T1, before the new
entry is written to table T2.  "Many" could be hundreds, thousands, or
even millions, depending upon the relative speed of the data and
control plane processing.  Switch ASIC data plane implementations can
often process billions of packets per second, and control planes are
not necessarily "slow", but even the smallest time between consecutive
writes could be many nanoseconds apart.

Any packet processed between the two writes will get a miss when
searching table T2.  Depending upon the desired system behavior, this
might be perfectly acceptable, but in many cases we wish to prevent
this.

A common technique used in network ASIC control plane software is to
add new table entries with linking fields between them "back to
front", i.e. first write new entries in later tables, and only when
that is complete begin writing new entries in earlier tables.  This
avoids the transient time interval where packets get misses in the
later tables.

Aside: Conversely, when removing entries in multiple tables, where
there are linking fields between them, they are removed "front to
back".  Again, this avoids transient time intervals where packets get
misses in the later tables.


There are several consequences of linking fields being explicit action
parameters:

+ the control plane always selects values for them
+ they require explicit storage in the data plane

This makes the job of the control plane easier when writing new
entries back to front, as we will see below.  It also has an
additional cost in the data plane.

Typically the control plane will maintain a table of all linking field
values currently in use.  It allocates a new value currently not in
use (e.g. from a free list).  Then it can write the new table entries
in T2, using the selected linking field values in the search key(s),
followed by writing the new table entries in T1.

    allocate new linking field value(s)
    write new table entries to T2 (back)
    write new table entries to T1 (to front)

This can be generalized in a straightforward manner to any number of
linking fields, spanning across any number of tables.  It can also be
generalized to allocating a "batch" of N new linking field values at
once, then writing N new entries to table T2, followed by writing N
new entries to table T1.  Such batching is often used to improve
control plane performance of writing to the data plane.


# hit indexes, and their cost savings in the data plane

Because of the extra data plane storage cost of explicit action
parameters, it is very common in switch ASICs to use an 'index hit'
property of earlier table searches as linking fields, i.e. if table T1
gets a hit, then get the "hardware address" of the matching entry and
save it in a metadata field, and use that value as all or part of a
search key of a later table.

Examples of such a hardware address would be:

+ in a TCAM, the hardware index of the highest priority matching entry
+ in a hash table, the hardware index of the matching entry

The main motivation for doing this is that the hit index _does not
require explicit storage_ in the data plane.  The hit index is always
determined by the hardware every time a search is performed that
results in a match.  I cannot think of a way to implement a search of
such a table that would not require determining the hit index as some
intermediate step.  The hit index can be discarded, of course, and
often it is.

So one consequence of making a hit index available for use in a P4
program is that in some cases it could reduce the data plane storage
required.


# The cost of hit indexes in the control plane

The other main consequence hit indexes have is on the control plane
software, in the following expected common case:

+ the hit index is used as a linking field between tables, and
+ one wants to avoid the transient misses involved in writing new
  table entries, by writing them back to front.

I believe that the primary motivation of a hit index in the data plane
is as a linking field between tables.  It is typically not of any
interest to include such a value in an outgoing packet header, for
example.

Below is a partial P4 program, slightly modified from the one above by
using the made-up syntax "T1.hit_index()" as the hit index of table T1
in action set_l2ptr.  The rest of the program remains unchanged.

```
    action set_l2ptr() {
        meta.l2ptr = T1.hit_index();
    }
```

Assume further that at the controller, we do not want to know the
details of each P4 data plane implementation and how it stores table
entries in hardware tables.  The controller wants data-plane-specific
agent software to choose and manage these values.


Now consider the sequence that the controller must go through in order
to write one new table entry to both T1 and T2, where the new T1
entry's hit index is used in the key for the new T2 table entry.

(1) send a message to the agent, describing the key it wants to add to
    table T1, but instructing the agent _not_ to add the new entry
    yet, but merely to return the hit index where it will go, if the
    controller decides to add it later.

(2) The agent returns a response containing the new hit index.

(3) The controller sends a message to the agent to write a new entry
    into table T2, which includes the hit index returned above.

(4) If the write to T2 succeeded, send a message to the agent
    indicating that it should now write the new entry in table T1 that
    was asked about in step (1).  The controller must not attempt to
    change the key, or anything else about the entry described in step
    (1) that would change the hardware index.

At step (4), if the write to T2 failed (e.g. T2 ran out of capacity
for new entries), then the controller should instead inform the agent
that it can "forget" the entry described in step (1), thus allowing
the hit index to be used for new entries added to T1 in the future.

Basically, the agent must "reserve" the hit index (or in general, many
hit indexes, for an arbitrary number of tables), without writing table
entries in those places, until the controller decides whether it wants
to actually write those entries, or not.


This can also be generalized to any number of linking fields, spanning
across any number of tables.

I _believe_ that it is enough if the P4Runtime API would have a way to
say "don't write this new table entry yet, but remember the hit index
where you would write it, and don't allow any other new table entries
to use that hit index, until I tell you later whether to write that
new entry, or instead forget it and free up the hit index".  Perhaps
"reserve" is a good brief name for such an operation.


# Other consequences of hit indexes

Another consequence is that the agent must not change the hit index of
such table entries where the hit index is used as a linking field.

Why would it want to, you may wonder?

There are commonly used techniques in TCAMs to move table entries
around in hardware, in order to preserve them in a specified relative
priority order, as new entries are added.  See the section "P4Runtime
API v1.0 for ternary/range tables" below for more details.

There are also commonly used kinds of hash tables in hardware where
multiple hash functions are calculated on the same key, and each hash
function is used as a hardware address in different "sub tables",
getting a match if any of the sub tables has a match.  This can
significantly improve the utilization possible in such hash tables.

    https://en.wikipedia.org/wiki/2-choice_hashing

It can improve utilization in dynamic add/delete situations if
previously-added entries can be moved between sub-tables.

Moving a table entry changes its hit index.  In the simplest case,
this could affect only one table entry in a later table, but in
general it could affect many later table entries.

One way to allow changing hit index(es) would be to have a way for the
agent to send a message to the controller indicating "table entry X
currently has hit_index A, but I would like to change it to B.  Please
do whatever other table add/delete/modify operations you want to make
this acceptable, then let me know when I can proceed."  The agent
would not be allowed to change the hit index until the controller
later sent an explicit message indicating it could proceed.

The agent must always be prepared not to get such a message from the
controller for a long time, or instead to be told by the controller
"sorry, give up trying to move that entry, because I could not change
the keys of later tables to accommodate it."

Note that one reason an agent might want to move an entry is in order
to make it possible to successfully add a new table entry requested by
the controller.  One can easily imagine cases where the agent could
say "yes" to such a new table entry add request if it could move other
table entries around, but otherwise it must say "no".

How to design the possible interactions between controller and agent
in such a situation could get tricky.  For example, does this mean
that a controller must be able to respond to such "desire to move
table entry X from hit index A to B" messages while waiting for
responses to controller-to-agent "add table entry" messages?

Even if those requests to add a new table entry were performed because
the controller was trying to accommodate an earlier such message?

How deeply "nested" should such interactions be allowed to go?

Control plane software that handles hit indexes as linking fields
between tables has been implemented many times before, and it will be
again, for network switch ASICs, because of the data plane storage
savings.  I suspect that the "controller" and "agent" are often
written by the same software team.  That is, it is probably usually
developed with more tight coupling between them, at least partly
because of the hit index management involved.


If the hit index is not used in the data plane for any reason (the way
it is not in P4 as specified today), then the agent is free to modify
the hit indexes for any reason, at any time, without affecting the
data plane behavior, and without informing the higher levels of the
control plane software.


# P4Runtime API v1.0 for ternary/range tables

One can certainly suggest the idea "allow hit indexes to be used in
arbitrary ways in data plane programs, but don't create any mechanism
for an agent to change hit indexes of table entries after they are
added."

However, given the current P4Runtime API for ternary/range tables,
this seems like a very limiting approach.  The current P4Runtime API
v1.0 specification allows a controller to specify a 32-bit numeric
priority value.  Among all entries installed in a table that match a
search key, one with a highest priority value should be the one to
match and its corresponding action executed.

Consider a device that has a "traditional hardware TCAM" to implement
the matching behavior for such a table.  In such a TCAM, entries are
numbered from 0 up to N-1, where N is the number of entries.  Each
entry has a valid bit (invalid entries cannot match search keys).
When a search is performed, then among all TCAM entries whose
value/mask matches the search key, the one with the smallest numerical
hardware address is the one whose action should be performed.  This
hardware address is the 'hit index', and typically it is used as the
read address of a hardware SRAM to get data associated with the
matching entry, which for a P4-programmable device would typically
contain some encoding of the action to be performed, and the values of
the action parameters.

In such a TCAM, the entries must always be installed while maintaining
this "priority invariant":

    When hardware TCAM entries are sorted from smallest hardware
    address to largest, they are in descending order of P4Runtime API
    priority.

Agent software must maintain this invariant for an arbitrary sequence
of table add/delete operations.  Depending upon the priority values
used by controller software over time, this could _require_ moving
entries between different hardware addresses in order to allow the
full capacity of the TCAM to be used.

For example, consider this sequence of controller table add/delete
operations, where every table entry requires exactly 1 slot in the
hardware TCAM (i.e. we are ignoring cases where a single P4Runtime
table entry requires multiple hardware entries).

(1) Add entries with priorities ranging from 1 to 16K.

A reasonable final state is for these to be installed in the hardware
like so:

```
hardware  P4Runtime
address   priority
--------  ---------
     0     16384
     1     16383
     2     16382
   ...      ...
 16382         2
 16383         1
```

(2) Delete entries with priorities ranging from 1 to 8K.

There is no need to move any entries around.  The deleted entries can
simply be made invalid.

(3) Add entries with priorities ranging from 16K+1 to 24K.

In order to maintain the priority invariant, we must either reject
these table add commands (undesirable, since there is plenty of
available space in the TCAM), or move the existing entries from their
original positions to new positions like this:

```
hardware  P4Runtime
address   priority
--------  ---------
     0     <invalid>
   ...      ...
  8191     <invalid>
  8192     16384
  8193     16383
  8194     16382
   ...      ...

 16382      8194
 16383      8193
```

Now it is straightforward to add the new entries with priority values
16K+1 to 24K in the hardware address range 0 through 8191, resulting
in a final state like so:

```
hardware  P4Runtime
address   priority
--------  ---------
     0     24576
   ...      ...
  8191     16385
  8192     16384
  8193     16383
  8194     16382
   ...      ...

 16382      8194
 16383      8193
```

In general, an entry added could need to be moved multiple times
during its "lifetime" of being installed in the table.

Note that I am _not_ saying there is anything wrong with the P4Runtime
v1.0 API.  I think it is a reasonable way to specify the desired
matching behavior of a collection of ternary/range table entries.
There are other variants of TCAM hardware than the one described
above, and algorithmic TCAM approaches, and some of those _might_
exist that make it easy to avoid the need to change hit indexes while
adding/removing table entries.  That said, traditional TCAMs seem
likely to remain a common approach for the highest performance switch
ASICs, so are an important case to keep in mind.

If one wanted to specify a lower level API, closer to TCAM hardware,
one could specify hardware addresses, which would very likely be equal
to P4 hit indexes, directly for all table entries when adding them.
Then any changes in hit index would be explicitly visible to, and
controllable by, the controller software.

However, that might be too low level of an API versus what many people
would wish to have for a P4 program.  For example, it would then make
explicit 'above the API layer' that if you want a TCP port range
matching behavior, and the device only has a traditional value/match
TCAM in hardware, the controller must now break up individual range
matching entries into one or multiple hardware TCAM entries.  This is
good if the controller wishes to have detailed knowledge of the use of
table capacity in the hardware, but bad if they are now exposed to
different variations of hardware that might have custom optimizations
for range matching capabilities.



Other possibilities:

(a)

Disallow the use of hit indexes in P4 programs for tables with
ternary/range match_kind field, but allow it for other kinds of
tables.  This enables the agent to move hit indexes of ternary/range
tables around without affecting any other behavior of the P4 program.

(b)

Allow the use of hit indexes in P4 programs for tables with
ternary/range match_kind fields, but restrict their use in some way so
that no controller/agent interaction is needed when the hit indexes
are changed.

For example, perhaps restrict the hit indexes to be used as the _only_
field of any table in which it is used, and only for direct-addressed
SRAMs, so that no table add operation failures are possible (the way
it would be possible for a hash table).  The agent would be
responsible for moving the entries of these later tables around
whenever it moved the TCAM table entries around.

This restriction is so drastic, however, that it doesn't enable you to
do anything with the ternary table hit index that you could not
already write in a P4 program by having actions on the ternary table
with more action parameters, and no hit index at all.

(c)

Allow the use of hit indexes for tables with ternary/range match_kind
fields, and design the controller/agent interaction protocol to enable
this to work for arbitrary use of the hit index value in a P4 program.

(d)

Instead of a control plane API that uses relative priority values as
P4Runtime API v1.0 does, instead require the control plane to specify
hardware indices in a TCAM where table entries are installed, e.g. in
the range `[0, size-1]`, where `size` is the size of the ternary table
in number of TCAM entries.

This approach has properties that one could consider an advantage or a
disadvantage, depending upon your purposes.

+ One the positive side, it makes it clear what the relative priority
  of entries are, and how much space they consume in the hardware.
  That is, if a new entry does not fit in the table's capacity, it is
  clear exactly why.  It is also easy to predict whether an entire new
  collection of table entries will fit, and how much capacity they
  will require, as long as you know how many TCAM value/masks it
  requires to represent the matching rules.

+ Perhaps considered a disadvantage by most people, if you wanted to
  implement range matching on some fields using a normal TCAM, the
  control plane must explicitly create multiple TCAM value/masks for
  any ranges of a field value that are not "power of 2 aligned"
  ranges.

+ If some hardware implementations have special techniques for
  implementation range matching, either the control plane cannot take
  advantage of those, or it must be explicitly aware of how the
  hardware works in detail, making it more time consuming to write
  control software for a variety of hardware implementations.

+ If some hardware has some kind of "algorithmic TCAM" implementation,
  these have even more varieties and differences between them, and the
  notion of a hardware index in the range `[0, size-1]` is likely
  meaningless for those implementations.


# hit indexes, and using TCAMs to implement range matching

There are well known techniques for implementing range matching fields
using TCAMs, but they require for most ranges to implement a single
table entry added via the control plane API as multiple separate
hardware TCAM entries.  For example, the range [0, 5] of a 16-bit
field could be implemented as the union of two separate ranges [0, 3]
and [4, 5], where these are "power of 2 aligned ranges" that can be
represented with a single TCAM entry each.  In general this can be
done for an arbitrary range of a single W-bit field using at most 2W-2
TCAM entries, the worst case being achieved when implementing the
range [1, 2^W-2].

If a P4 device used this technique, note that a single entry added via
the control plane API becomes multiple TCAM entries, _and they each
have their own separate hit index_.  In order to use the hit index as
a linking field, any later table entry using the hit index as a field
in its search key must in general now become _multiple_ table entries.
If two such hit indices are both used as fields in the search key of a
single table, the cross product of both sets of hit indices must be
added as table entries, etc.

You might be thinking: Ah!  I know how to avoid this problem.  I can
have a table just after the ternary table, that maps the ternary table
hit index to another software-selected value, and I will write control
plane code that takes all of those multiple hit indexes that resulted
from the one original rule, and maps them all to a common value.

Good idea.  But that is _exactly_ the extra storage required to get a
software-controllable linking field value, when no hit indexes are
used in a P4 program at all.  Using this remapping technique nullifies
the only advantage that the hit indexes can provide.
