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
even milliions, depending upon the relative speed of the data and
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

This can generalized in a straightforward manner to any number of
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
priority order, as new entries are added.

There are also commonly used kinds of hash tables in hardware where
multiple hash functions are calculated on the same key, and each hash
function is used as a hardware address in different "sub tables",
getting a match if any of the sub tables has a match.  This can
significantly improve the utilization possible in such hash tables.

    https://en.wikipedia.org/wiki/2-choice_hashing

It can improve utilization in dynamic add/delete situations if
previously-added entries can be moved between sub-tables.


If the hit index is used in the data plane as a linking field, then
moving a table entry will change its hit index.  In the simplest case,
this could affect only one table entry in a later table, but in
general it could affect many later table entries.  One way to allow
changing these values would be to have a way for the agent to send a
message to the controller indicating "table entry X currently has
hit_index A, but I would like to change it to B.  Please do whatever
other table add/delete/modify operations you want to make this
acceptable, then let me know when I can proceed."  The agent would not
be allowed to change the hit index until the controller later sent an
explicit message indicating it could proceed.

The agent must always be prepared not to get such a message from the
controller for a long time, or instead to be told by the controller
"sorry, give up trying to move that entry, because I could not change
the keys of later tables to accomodate it."

Note that one reason an agent might want to move an entry is in order
to make it possible to successfully add a new table entry requested by
the controller.  One can easily imagine cases where the agent could
say "yes" to such a new table entry request if it could move other
table entries around, but otherwise must say "no".  How to design the
possible interactions between controller and agent in such a situation
could get tricky.  For example, does this mean that a controller must
be able to respond to such "desire to move table entry X from hit
index A to B" messages while waiting for responses to any
controller-to-agent message requesting to add a new table entry?  Even
if those requests to add a new table entry were performed because the
controller was trying to accomodate an earlier such message?


If the hit index is not used in the data plane for any reason (the way
it is not in P4 as specified today), then the agent is free to modify
the hit indexes for any reason, at any time, without affecting the
data plane behavior, and without informing the higher levels of the
control plane software.
