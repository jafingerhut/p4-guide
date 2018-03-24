# Size property of P4 tables and parser value sets

It would be convenient for users of P4 programmable devices if objects
such as tables and parser value sets could behave in a way where their
capacity automatically adjusted to match the number of entries added
by the control plane software.  (Everywhere later in this document
where we say "tables", the same also applies for "parser value sets").

For some P4 implementations, this flexibility can be difficult or
impossible to implement in a way that causes no disruption in packet
processing.  It should be straightforward to adjust table sizes in any
P4 programmable device by loading a new P4 program into the device,
but loading a new P4 program typically involves at least a brief
period of time where no packets are processed, e.g. typically tens or
hundreds of milliseconds, depending upon the device and the kinds of
P4 program changes made.  A disruption of this length of time is often
noticeable by applications, and network operators often wish to know
in advance what kinds of operations will cause such packet processing
disruptions.

For the highest performance ASIC, FPGA, and NPU implementations of P4
programmable devices, it is thus often necessary to give to the P4
compiler some indication of the desired size of tables, so that the
appropriate hardware resources can be dedicated for that table.

When it is necessary to specify a size for a table, it would be very
convenient if one could simply say "I want this table to be able to
hold 1024 entries" (or some other desired number), and the resulting
table would be able to hold any arbitrary set of 1024 entries that you
attempted to add via the P4Runtime API, never failing.

This is possible in some situations, but there are practical
implementation issues that often make this an unrealistic goal.

The highest performance implementations often use TCAM and hash tables
to implement P4 tables -- TCAM for P4 tables with `ternary`, `range`,
and/or `lpm` match fields, and hash tables for P4 tables with only
`exact` match fields.  These are not the only implementations possible
for such tables, but it is challenging to improve on their lookup rate
performance versus power and ASIC die area, which is why they are
commonly used for these purposes.

For these highest performance P4 implementations, here is a summary of
what is possible.


## Cases where capacity is predictable and 1-to-1

The following cases are typically easy to provide a predictable 1-to-1
correspondence between table entries added from the control plane, and
the number of physical entries consumed in the data plane:

+ A P4 table where all fields have a `match_kind` that is one of
  `ternary`, `lpm`, or `exact`, where the P4 compiler selects a TCAM
  as its data plane implementation.

+ A P4 table where all fields have a `match_kind` that is `exact`,
  where the P4 compiler selects a (binary) CAM as its data plane
  implementation.

+ A P4 table where all fields have `match_kind` `exact`, the total
  width in bits of all search key fields is W bits, you request a
  table with 2^W entries, and the P4 compiler selects a normal memory
  such as an SRAM as its data plane implementation, and uses the W
  bits of the search key fields as the address to read in this memory.
  (Example: the search key fields total 10 bits, you ask for 1024
  table entries, and the P4 compiler chooses to implement this with a
  1024-entry SRAM, using the 10 bits as a read address into this
  1024-entry SRAM, with no hashing done at all).

In these cases, if you request a size of N for a table, it should be
straightforward to guarantee that attempting to add a table entry
always succeeds, as long as the table currently has less than N
entries installed.  It would always fail to add a new entry if the
table already contained N entries.

Note that there is no way in P4 to specify what kind of implementation
a P4 compiler will choose for a table.  Individual P4 compilers may
implement ways to do so, but they are expected to be target-specific.


## Cases where capacity is predictable, but 1-to-many

The following case provides predictable capacity, as long as you know
precisely how the implementation converts fields with the `range`
`match_kind` into TCAM entries, which can be 1-to-1, but in general
can be 1 control plane entry to many physical table entries:

+ A P4 table where all fields have a `match_kind` that is one of
  `range`, `ternary`, `lpm`, or `exact`, where the P4 compiler selects
  a normal TCAM as its data plane implementation.

In this case, as long as you understand how many physical table
entries are consumed for each control plane entry, the table capacity
is as predictable as described in the previous section.  The table's
capacity is predictable in the number of physical table entries
supported, but how many entries are supported as counted by the
control plane software is dependent on the particular ranges used.
 

## Cases where capacity is not predictable with 100% certainty

There is only one remaining case.  Not that the majority of the tables
in the example open source program `switch.p4` are likely to fall into
this case in a practical implementation.  While it is _possible_ for
an implementation to use table implementations with predictable
capacity like TCAM or CAM as described above, those hardware
implementations are significantly more expensive in power and are per
bit of storage, and thus impractical for large tables.

+ A P4 table where all fields have `match_kind` `exact`, the total
  width in bits of all search key fields is W bits, you request a
  table with less than 2^W entries, and the P4 compiler selects one of
  the hash table implementations described in the "Background details"
  section below.

Because the capacity of a hash table is dependent upon the hash
function(s) used, the keys installed, and in some cases even on the
order of operations performed that led to the current state, there is
no way to _guarantee_ that these kinds of hash tables will be able to
hold a large number of entries.  In practice, one can often make
statements such as "with 99.9% probability, this table will be able to
hold at least N entries".

What should a P4 compiler do if a P4 program requests a size of N
entries for a table where it selects one of these data plane
implementations?

One straightforward way would be to select a hash table implementation
where if you were very fortunate, and were able to achieve 100%
utilization of every entry of the hash table, it holds exactly N
entries.  However, this seems unlikely to be what someone would want
to happen when they request a table size of N entries.

Less straightforward would be to choose a raw capacity for the hash
table, and perhaps also an overflow TCAM paired with it, such that it
is _very likely_ that any given set of N keys would be successfully
added.  During operation, it is possible, but unlikely, that
attempting to add a new entry could fail, when there are currently
less than N entries installed.

In such a case, it would be easy to implement the P4Runtime
server/agent software of that target to automatically fail any attempt
to add strictly more than N entries, even if the hash table
implementation chosen could support it.  Alternately, it would be easy
to implement that software to always allow the table addition if room
can be found, even if that would lead to more than N entries installed
at one time.  This is a design choice for the software, and what
choice is preferable in a given system may be dependent on other goals
of the overall system design.


## Cases not examined here

This document does not attempt to categorize how tables with the
action profile or action selector implementations behave, as it seems
there are multiple different implementations that various P4
implementers have in mind for precisely how these work in the data
plane, and it is not yet clear to this author how much variety this
includes.



## Background details on some fast P4 table implementations

Here by "fast" I mean: capable of a search rate of 1 to 2 billion
searches per second per 'pipeline', with deterministic search rate,
without having to use multiple parallel copies of tables, using ASIC
technology available in 2018.

We will evaluate several methods of implementing tables in terms of
these factors:

+ lookup performance - O(1), or O(f(N)) where N is the number of table
  entries, and f is some function of N that typically grows with N.
  O(1) means that a constant number of hardware operations are
  required for each table search.  O(log N) means that a number of
  hardware operations that grows with the logarithm of N is required
  for each table search operation.

+ correspondence - Or more fully, the correspondence of control plane
  table entries to physical table entries.  Often there is a 1-to-1
  relationship here, but there are cases where adding a single table
  entry from the control plane requires adding multiple physical table
  entries.

+ capacity predictability - Whether the number of physical table
  entries that can be added is deterministic, regardless of the
  contents of the table entries, or whether the number is dependent on
  the contents of the table entries, and/or the order the table
  operations are performed.


### TCAM

Every entry of the TCAM contains a W-bit value and a W-bit mask.
Every time a search is done with a W-bit key, every entry of the TCAM
determines in parallel, independently, whether it matches the search
key by calculating:

    (value & mask) == (search_key & mask)

Then some priority-encoding logic determines the first among all
entries that match, and constructs its index.

Such a device is capable of implementing the `ternary` `match_kind` in
P4.  It can also implement `lpm` and `exact` `match_kind`s by use of
appropriate masks stored within the entry.

This is among the most general kinds of devices for implementing a
table, and also the largest per entry bit in area (every bit of TCAM
requires storing both a value and a mask bit, and requires a little
bit of comparison logic), and consumes the most power.

+ lookup performance: O(1)
+ correspondence: 1-to-1 for exact, lpm, and ternary entries.
  1-to-many for range entries.
+ capacity predictability: deterministic; a TCAM with N entries can
  always hold exactly N physical table entries before it is full.


### TCAM with enhancement for range matching

Same as TCAM, except that correspondence should be 1-to-1 for range
entries, as long as the hardware has support for the range fields of
the P4 table.


### TCAM with mask restrictions

Same as TCAM, except capacity predictability is significantly
diminished.  The number of physical entries that can fit into the TCAM
depend upon the variety of masks in the set of physical entries.  If
there are too many such masks, the set of entries will not fit.


### CAM (or BCAM)

A CAM is like a TCAM, except every entry has only a value, and every
entry can only do exact matches against the search key, because when a
search is performed every entry calculates whether it matches by
doing:

    value == search_key

It is lower in area and power than a TCAM, but is still more expensive
in area and power than an SRAM with the same size in bits, due to the
parallel comparison logic.  It can only implement the `exact`
`match_kind`.

+ lookup performance: O(1)
+ correspondence: 1-to-1 for exact entries.  Cannot implement lpm,
  ternary, or range matching.
+ capacity predictability: deterministic; a CAM with N entries can
  always hold exactly N physical table entries before it is full.


### hash table with 1 hash function

Only 1 hash function used by the entire table.

The keys are stored in a memory, which is an array of 'buckets', where
each bucket holds a constant number of keys B.  Every time a search is
performed, one entire bucket worth of B keys is read, and all are
compared in parallel to the search key.

+ lookup performance: O(1); every search requires reading 1 memory
  entry containing exactly B entries.
+ correspondence: 1-to-1 for exact entries.  Does not support ternary,
  lpm, or range fields.
+ capacity predictability: Can guarantee that at least B entries can
  be added, but any entry one attempts to add after that point might
  fail, even if there are many empty slots in other hash buckets.

Aside: A degenerate case of a hash table with 1 hash function contains
only 1 entry, with B buckets.  This is identical to a CAM.

Using values of B much smaller than the number of entries in the hash
table is typical, e.g. some number in the range of 2 to 8.  B larger
than 1 allows a limited number of collisions to occur before adding a
new key to a bucket fails.


### hash table with H hash functions

There are H different hash functions, all of which are calculated for
every search key.  There are H separate memories, each an array of
buckets with B entries each.  Every time a search is performed,
exactly H buckets worth of entries are read, one from each memory, and
all H*B entries are compared in parallel to the search key.

Properties are nearly identical to a hash table with 1 hash function,
except we can now guarantee H*B entries can be added before failures
become possible.

+ lookup performance: O(1); every search requires reading H memory
  entries, each containing exactly B entries.
+ correspondence: 1-to-1 for exact entries.  Does not support ternary,
  lpm, or range fields.
+ capacity predictability: Can guarantee that at least H*B entries can
  be added, but any entry one attempts to add after that point might
  fail, even if there are many empty slots in other hash buckets.

Increasing H above 1 is more expensive than H=1, but H=2 or H=4 is
often found to improve the utilization of the hash table entries
enough to justify the extra hardware cost.  (TBD: citation).


#### Dependence on order of table operations

There is a subtle of hash tables with H > 1 hash functions, in which
it differs from the kinds of tables described earlier.  When adding
new entries, there are now H different choices of where to install the
new entry (unless some of those H buckets become full -- then there
are fewer choices).

The choices made by the algorithm that installs new entries could be
different depending upon the sequence of operations done that led to
the current state.  Thus it is common that there are two different
sequences of add/remove operations that end with the same _set_ of
installed keys, but the state is different.

It is possible that attempting to add a new key K might succeed in one
of those states, but fail in the other.

The success or failure of attempting to add a new entry is now
dependent on the _order_ of operations done to reach the current
state.

That is not the case for a hash table with 1 hash function.  An
algorithm for adding new entries has no choices, so the occupancy of
each bucket is always the same, given the same set of installed keys,
no matter what sequence of operations led to that set of keys being
installed.

The usable capacity of TCAMs also does not depend on the order of
add/remove operations.  The number of write operations required to the
hardware _can_ depend on the order of adding/removing entries, since
maintaining entries in a specified priority ordering may require more
"entry moves" when adding entries in one sequence versus adding them
in a different sequence.  However, that does not change the fact that
as long as one is willing to perform the needed entry moves, the
usable capacity is still deterministic.



### hash table with 1 hash function and overflow TCAM

This is the same as a hash table with 1 hash function as described
above, except now there is also an "overflow TCAM".  When a search is
performed, the same operations as described earlier are performed for
the hash table, and in parallel the TCAM is also searched for the same
key.  A match occurs if either of these searches finds a match.

A relatively small overflow TCAM size can increase the expected
utilization of a hash table significantly.  (TBD: Citation).

Such a design can be made independent of the order of table operations
performed, or not, depending on the algorithm chosen for adding and
deleting table entries.


### hash table with H hash functions and overflow TCAM

The same as the hash table with H hash functions, plus an overflow
TCAM that is searched in parallel, as described in the previous
section.


### hash table using perfect hashing

Hash tables using perfect hashing have been extensively studied.  To
my knowledge, they are excellent for a set of keys known in advance
that rarely or never changes.  They require a large amount of
computation to determine whether a new set of keys can be supported,
compared to any of the hash table techniques described above.  I have
never seen such a thing used in a switch ASIC before.


### algorithmic TCAM

There are many research papers and commercial implementations of doing
TCAM-like searches but without using TCAM hardware, i.e. using mostly
SRAM and/or DRAM.  All techniques I am aware of here either cannot go
"fast" as defined above, or have capacity that is dependent upon the
contents of the table entries.


### Longest-prefix match tries

Again, there are many research papers and commercial implementation of
implementing longest-prefix match behavior using trie data structures
in software, and in hardware.  They typically have search rate and
table capacity that is dependent upon the table entries installed.
