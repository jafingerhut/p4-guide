## Guide to the included demo programs

### `demo1`

A very simple program that only does these things:

* on ingress:
  * parse Ethernet and IPv4 headers (ignoring IP options)
  * perform a longest prefix match on the IPv4 DA, resulting in an
    'l2ptr' value
  * l2ptr is an exact match index into a mac_da table, resulting in
    output BD (bridge domain), a new destination MAC address, and the
    output port.
  * decrement the IPv4 TTL field
* on egress:
  * look up the output port number to get a new source MAC address
  * calculate a new IPv4 header checksum

See the instructions in the file [`README.md`](demo1/README.md) if you
want to use `simple_switch` using the Thrift API for communicating
from a simple CLI "controller" process.

Use the alternate instructions in
[`README-p4runtime.md`](demo1/README-p4runtime.md) if you want to use
`simple_switch_grpc`.  You may still use the Thrift API, but
`simple_switch_grpc` was created with the intent of using the newer
P4Runtime API for communicating from a controller process (in the
example run, it is an interactive Python session acting as the
controller).

If you are interested in an example automated test for the
`demo1.p4_16.p4` program that uses the PTF library, see
[README-ptf.md](demo1/README-ptf.md).


### `demo2`

The same as demo1, except add a per-prefix match count.


### `demo3`

The same as demo2, except add calculation of an ECMP hash, and add
ECMP group and path tables that can use the ECMP hash to pick one of
several paths for a packet that matches a single prefix in the longest
prefix match table.

Note that most P4 programs use 'action profiles' to implement ECMP.
demo3 does not use those.  There is no strong reason why not -- demo3
simply demonstrates another way to do ECMP that doesn't require P4
action profiles, yet still achieves sharing of ECMP table entries
among many IP prefixes.


### `demo6`

The same as demo2, except adds a very simple use of P4 registers.


### `v1model-special-ops`

For P4_16 with the `v1model` architecture implemented in the open
source `p4c` compiler and BMv2 `simple_switch` software switch, the
program `v1model-special-ops.p4` demonstrates how to use the resubmit,
recirculate, clone, and multicast operations.

This directory includes not only the P4 program, but also table
entries and other configuration commands that can be issued from the
`simple_switch_CLI` program, plus test packets to send in, that
demonstrate the operations occurring for those packets.

See the [`README.md`](v1model-special-ops/README.md) for details.


### `rewrite-examples`

The program `rewrite-examples.p4` was created as a demo of two
different ways of adding tunnel encapsulation headers onto packets.
See the [`README.md`](rewrite-examples/README.md) file in there for
how it was created.


### `variable-length-header`

This directory contains a
[`README.md`](variable-length-header/README.md) explaining the
operations that P4_16 supports on variable-length headers, and
demonstrates an alternate way to process variable-length headers using
one of several fixed-length headers.


### `tcp-options-parser`

The program `tcp-options-parser.p4` contains an example of a variable
with the type `header_union`, a type added to the P4_16 language that
does not exist in P4_14.  It also demonstrates a "sub-parser" (i.e. a
parser that calls another parser) that may be nearly correct for
parsing TCP options in a TCP header (see comments in the program for
caveats).


### `action-profile-and-selector`

There is a short but complete P4_16 program showing how to use an
`action_selector` table in P4_16 plus the `v1model` architecture.

+ [action-selector.p4](action-profile-and-selector/action-selector.p4)

There are also documents with P4_16 code excerpts showing:

+ [How to implement implement an action
  profile](action-profile-and-selector/README-action-profile.md) using
  ordinary P4 tables, even if action profiles were not built into the
  language.
+ Several variations of how to implement an action selector using
  ordinary P4 tables, and a hash function, even if action selectors
  were not built into the language.
  + [variant
    3](action-profile-and-selector/README-action-selector-variant3.md)
    - uses 3 tables where each has a data dependency on the previous
    one.  This variant does not have the scalability flaw of variant 1.
    It reduces the number of dependent table lookups vs. variant 2
    by requiring that the ids of group members in table
    `T_member_id_to_action` must be consecutive integers.  This
    introduces a requirement in the control software to manage each
    group as a contiguous block of member ids.  Thus the space of
    possible member ids may become fragmentated, unless the control
    software avoids such fragmentation by implementing techniques
    similar to a compacting garbage collector.  This one is most like
    what I have most often seen in several switch ASIC designs before.
  + [variant
    1](action-profile-and-selector/README-action-selector-variant1.md)
    - uses 3 tables, where each has a data dependency upon the
    previous table lookup completing, before the next can begin.  It
    has a scalability flaw, in that if you have M table entries
    pointing at the same group, and you want to change the number of
    members in the group, you must update all M table entries.  This
    is slow for those kinds of updates if M is large.
  + [variant
    2](action-profile-and-selector/README-action-selector-variant2.md)
    - uses 4 tables where each has a data dependency on the previous
    one.  This implementation does not have the scalability flaw of
    variant 1, and it is a bit more flexible than variant 3, in that
    the members of a group need not be consecutive in table
    `T_group_to_member_id`.  However, that flexibility comes with the
    cost of an extra dependent table lookup, which can increase the
    latency of processing packets.


### `traffic-management`

The programs in this directory are experimental prototypes as of
November 2018, written to investigate how a few packet dropping
techniques might be implemented in the future in P4 programs.
