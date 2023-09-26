# Introduction

The group-based packet classification problem arises in many
operational network scenarios.

It is used to perform security for several cloud-based VM/container
deployment services, such as Kubernetes, and there are several cloud
service providers such as AWS, Microsoft Azure, and Google Cloud
Platform that allow their tenants to create group-based security rules
for which packets to allow to be forwarded between the tenant's
deployed VMs/containers, vs. which should be dropped.


## Normal packet classification problem

An instance of a "normal" packet classification problem consists of:

+ a set of packet _fields_ F, where field f can be represented as a
  `W_f`-bit unsigned integer.
+ a match kind for each field, and
+ a set of _rules_ R for matching the fields against.

Each match kind is one of:

+ ternary - the match criteria is a value V and a mask M.  A field
  value f matches if `(f & M) == V`.  The bit positions of M that are
  0 are don't care bit positions where the field value can be any bit,
  and the bit positions of M that are 1 are exact match bit positions
  where the field value must be the same as the corresponding bit
  position of V.
+ range - the match criteria is a minimum value MIN and a maximum
  value MAX.  A field value f matches if `(MIN <= f) && (f <= MAX)`.
+ prefix - the match criteria is a value V and a prefix length P in
  the range [0,W], where the field is W bits.  A field matches the
  same as a ternary field with the same value V and a mask
  `M=(((1 << W) - 1) >> (W-P)) << (W-P)`.
  This is a "prefix mask", such that the value must equal the field in
  the most significant P bits.
  + Example: a 32-bit field's prefix match criteria could be value
    V=0x0a010100 with prefix length P=24, which matches the the same
    as a ternary field with the same value V and a mask M=0xffffff00.
+ optional - like ternary, except the mask is restricted to be either
  0 for a completely don't care value, or `((1 << W) - 1)` for exact
  value.

Each rule consists of:

+ a priority, which is a positive integer
+ For every field f, a match criteria appropriate for the match kind
  of the field.

A set of fields F matches a rule r iff for every field f, the value of
field f matches the match criteria given in the rule R.

The packet classification problem is: Given a set of rules R and a set
of fields f, among all rules r in R such that f matches r, find one
that has the maximum priority.  If no rules in R match, return "none".


### Example of the normal packet classification problem

Fields and their match kinds:

+ IPv4 source address (abbreviated SA), prefix
+ IPv4 destination address (abbreviated DA), prefix
+ IPv4 protocol (abbreviated proto), optional
+ L4 source port (abbreviated SP), range
+ L4 destination port (abbreviated DP), range

The L4 source and destination port come from the packet if the packet
has the appropriate protocol value, or they are 0 for packets with
other protocol values.

A match criteria of * means that it matches any value for the field.
This corresponds to a mask of 0 for ternary or optional, a prefix
length of 0 for prefix, or a range including all possible values of
the field for range.

Rules:

| priority | SA | DA | proto | SP | DP |
| -------- | -- | -- | ----- | -- | -- |
| 100 | 10.1.1.0/24 | 192.168.1.0/24 | 6 | * | 80 |
|  90 | 10.1.1.0/24 | 192.168.1.0/24 | 6 | * | 443 |
|  80 | 10.0.0.0/8 | 192.168.0.0/16 | 1 | * | * |
|  70 | * | * | 6 | * | 53 |
|  60 | * | * | 17 | * | 53 |
|  50 | 10.1.0.0/16 | * | 6 | * | * |
|  40 | * | * | * | * | * |


## Group-based packet classification problem

This is a generalization of the normal packet classification problem.
The fields and match kinds are the same as before.

The difference is that in a rule, each field can have a set of one or
more match criteria.  A field matches the set of match criteria if it
matches _any_ of the match criteria.


### Example of the group-based packet classification problem

As very small example, the group-based rules below are based on the
same set of fields and match kinds as given in the previous example.

| priority | SA | DA | proto | SP | DP |
| -------- | -- | -- | ----- | -- | -- |
| 100 | {10.1.1.0/24, 10.2.0.0/16} | {192.168.1.0/24, 192.168.2.38/32} | {6} | {*} | {80} |
| 90 | {10.1.1.0/24} | {10.3.0.0/16, 192.168.0.0/16} | {17} | {*} | {53, 90-99} |

The group-based rules above are equivalent in matching behavior to the
following normal rules.  We have simply performed a "cross product"
among the sets for each individual field.

| priority | SA | DA | proto | SP | DP |
| -------- | -- | -- | ----- | -- | -- |
| 100 | 10.1.1.0/24 | 192.168.1.0/24 | 6 | * | 80 |
| 100 | 10.1.1.0/24 | 192.168.2.38/32 | 6 | * | 80 |
| 100 | 10.2.0.0/16 | 192.168.1.0/24 | 6 | * | 80 |
| 100 | 10.2.0.0/16 | 192.168.2.38/32 | 6 | * | 80 |
| 90 | 10.1.1.0/24 | 10.3.0.0/16 | 17 | * | 53 |
| 90 | 10.1.1.0/24 | 10.3.0.0/16 | 17 | * | 90-99 |
| 90 | 10.1.1.0/24 | 192.168.0.0/16 | 17 | * | 53 |
| 90 | 10.1.1.0/24 | 192.168.0.0/16 | 17 | * | 90-99 |

This example shows one correct way to implement a group-based packet
classification problem: translate it to a normal packet classification
problem after performing the cross product of each individual rule.

The disadvantage of this solution is that each rule with N1 SAs, N2
DAs, N3 protos, N4 SPs, and N5 DPs will become `N1*N2*N3*N4*N5` rules
in a normal packet classification problem.  For example, a group-based
rule with 100 SA prefixes, 80 DA prefixes, and 7 DP ranges would
become `100*80*7 = 56,000` normal rules.  We would prefer a more
efficient solution than that.


# Algorithms for the packet classification problem

There are many algorithms in the published literature for the normal
packet classification problem.  See the references section.


## Evaluating a subset of field match criteria

If we take the first example of the normal packet classification
problem above, with the following rules:

| priority | SA | DA | proto | SP | DP |
| -------- | -- | -- | ----- | -- | -- |
| 100 | 10.1.1.0/24 | 192.168.1.0/24 | 6 | * | 80 |
|  90 | 10.1.1.0/24 | 192.168.1.0/24 | 6 | * | 443 |
|  80 | 10.0.0.0/8 | 192.168.0.0/16 | 1 | * | * |
|  70 | * | * | 6 | * | 53 |
|  60 | * | * | 17 | * | 53 |
|  50 | 10.1.0.0/16 | * | 6 | * | * |
|  40 | * | * | * | * | * |

and we consider the following set of packet fields:

+ SA=10.1.1.3
+ DA=192.168.1.0
+ proto=6
+ SP=5987
+ DP=443

then a general approach to solving the classification problem is to
evaluate an appropriate subset of the field match criteria, and then
use those results to find the highest priority matching rule.

The results of the field match criteria are shown in the table below,
where if a field value matches the criteria, the table entry contains
a 1, otherwise a 0.

| priority | SA | DA | proto | SP | DP | all field criteria match? |
| -------- | -- | -- | ----- | -- | -- | ------------------------- |
| 100 | 1 | 1 | 1 | 1 | 0 | no  |
|  90 | 1 | 1 | 1 | 1 | 1 | yes |
|  80 | 1 | 1 | 0 | 1 | 1 | no  |
|  70 | 1 | 1 | 1 | 1 | 0 | no  |
|  60 | 1 | 1 | 0 | 1 | 0 | no  |
|  50 | 1 | 1 | 1 | 1 | 1 | yes |
|  40 | 1 | 1 | 1 | 1 | 1 | yes |

Among the rules where all field criteria are a match, the highest
priority matching rule is the one with priority 90.

In the explanations below, N is the number of rules.


### Sequential evaluation

This algorithm is a straightforward one often implemented in software
on a general purpose CPU, sometimes used for production purposes where
a more sophisticated algorithm is too much complexity or effort, or
also for comparing the result against the result of a fancier
algorithm that one is testing.

Simply evaluate the 0/1 field match criteria result in the table above
in each row, in order from the highest priority matching rule to the
lowest.

If a rule is evaluated where all fields match, then you can stop, as
it does not matter if any rules with lower priority match.

This simple algorithm works for both the normal and group-based packet
classification problems.  Its main disadvantage is that its worst-case
running time is slow.


### Parallel evaluation

This is also a straightforward algorithm, and is what hardware TCAM
implementation use, at least for the case where all match kinds can be
represented as a value/mask, which includes ternary, prefix, and
optional.

A hardware TCAM stores the value/mask for all fields of a rule in a
"row" or "entry" of the TCAM.  The "search key" containing the value
of all fields to match against the rules is broadcast to all TCAM
rows, which evaluate all field match criteria in parallel.

Each TCAM entry in parallel calculates the logical AND of the
individual field match criteria within, producing a final 0/1
indicating whether all fields of the entry match.

The result is a bit vector containing 1 bit per entry.  A "priority
encoder" hardware block finds the first 1 in O(log N) logic gate
delays.  Because it finds the first 1 set, the rules must be placed
into TCAM entries in the same relative order that the find-first-1
logic works, so that the first 1 found corresponds to the highest
matching rule.  The output of the priority encoder is the index of the
first row where all fields match, or a special "miss" signal indicates
if there were no matching entries.

This parallel evaluation is why TCAMs can use so much power relative
to non-TCAM hardware such as SRAM or DRAM, because so many of the
wires between logic gates can change from 0 to 1 or 1 to 0 during this
evaluation process.


### Field-wise evaluation

In this evaluation order, we devise a method where given a single
lookup field of the packet, we calculate one column of the match
results in the table, with the result being an N-bit vector (see below
for examples of this).

After the N-bit vector for each column has been calculated, perform a
bitwise AND of all of them, resulting in the same N-bit vector that a
hardware TCAM calculates.  Then find the first 1 bit, and output its
bit position, or a miss result if the N-bit vector is all 0.


#### Field has match kind prefix

For a field with match kind prefix, we can construct a longest-prefix
match tree containing all prefixes for the field, across all rules.
Each prefix is associated with an N-bit vector that is the correct
result for the N-bit vector, precalculated by control plane software
and stored as the result of the longest-prefix match lookup.

For the example set of rules:

| priority | SA | DA | proto | SP | DP |
| -------- | -- | -- | ----- | -- | -- |
| 100 | 10.1.1.0/24 | 192.168.1.0/24 | 6 | * | 80 |
|  90 | 10.1.1.0/24 | 192.168.1.0/24 | 6 | * | 443 |
|  80 | 10.0.0.0/8 | 192.168.0.0/16 | 1 | * | * |
|  70 | * | * | 6 | * | 53 |
|  60 | * | * | 17 | * | 53 |
|  50 | 10.1.0.0/16 | * | 6 | * | * |
|  40 | * | * | * | * | * |

The longest-prefix match table for field SA would contain these
prefixes and associated 7-bit vectors, where the bits in the bit
vector have the bit for rule with priority 100 first, and the bit for
the rule with priority 40 last.

| prefix | 7-bit vector |
| ------ | ------------ |
| *           | 0001101 |
| 10.0.0.0/8  | 0011101 |
| 10.1.0.0/16 | 0011111 |
| 10.1.1.0/24 | 1111111 |

Note that while this example is for a normal packet classification
problem, this technique for constructing a longest-prefix match tree
for a single field also works for the group-based packet
classification problem, too.


#### Field has match kind optional

For every value that is exact match in the set of rules, add them to a
hash table.  The N-bit vector that is the result of the entry with key
X has the value 1 for bit positions corresponding to all rules that
match value X, or that have a completely don't-care value because its
mask is 0.

This approach for optional match kind fields work equally well for the
normal and group-based classification problems.


#### Field has match kind range

For fields with a small number of bits W, the technique for match kind
ternary of course works here.

For arbitrary size fields, it is possible to construct a binary or
multi-way search tree that compares the lookup field value against
values stored in the tree, and each leaf corresponds to a range of
values.

TODO: Give a small example of this.


#### Field has match kind ternary

There is actually no simple general way to calculate the value of the
N-bit column vector for a ternary match field, when the masks can be
arbitrary.  This is just as difficult as the normal packet
classification problem, albeit for only one field.

If the field is very small, e.g. W=4 bits, you can create a lookup
table for all possible field values in the range [0, 2^W-1] where each
contains the N-bit vector, but this is likely to be prohibitively
expensive for larger values of W.

For wide fields, e.g. 128 bits, one could break it up into smaller
sub-fields, e.g. each k=8 bits wide, and create a 2^k-entry lookup
table for each sub-field.  Then bitwise AND the N-bit results with
each other.  This is significantly less memory than a 2^128 entry
table!


# References


TODO: Add many of the references from the EffiCuts paper to the list
below, too.

+ Balajee Vamanan, Gwendolyn Voskuilen, T. N. Vijaykumar, "EffiCuts:
  optimizing packet classification for memory and throughput", ACM
  SIGCOMM Computer Communication Review, Volume 40, Issue 4, October
  2010, pp 207–218, https://doi.org/10.1145/1851275.1851208
