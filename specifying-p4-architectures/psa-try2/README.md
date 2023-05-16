# Introduction

psa-try2.p4 is very similar to psa-try1.p4.

The main difference is that psa-try2.p4 eliminates the use of the
`list` type for representing replication lists for multicast groups
and clone sessions.  Instead, there is a table that contains one entry
for each "replication list entry", implementing a linked list using
the table index id values as "next pointers".

The specification code explicitly walks through this linked list
representation when replicating packets, creating exactly one packet
copy per execution of the new process named `replicate_one_copy`.

This also eliminates the only use of a `for` loop that existed in
psa-try1.p4.


# Parameters defining a PSA implementation

Same as psa-try1.p4


# Details that the PSA specification is vague about

Same as psa-try1.p4


# State that is "global" in the architecture

The top level structure of processes is the same as psa-try1.p4,
except for the additional process named `replicate_one_copy` that
creates one copy of a packet to be replicated, and then re-enqueues
the packet with some metadata in a new queue named `replicateq` that
contains packets waiting to have one or more copy made of them.  The
metadata includes fields describing what copy to make next.

There is no figure yet that captures all of the queues and processes
of psa-try2.p4.  The closest is the figure for psa-try1.p4, which does
not include the process `replicate_one_copy`, nor the queue
`replicateq`.


## Traffic manager configuration state

Nearly identical to psa-try1.p4.  The only difference is the way that
packet replication lists are reprsented as a linked list of entries
within the ExactMap instance named `replication_entries`.


## Traffic manager dynamic state

Same as psa-try1.p4


## Ingress dynamic state

Same as psa-try1.p4
