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
|  50 | 10.1.1.0/24 | 192.168.1.0/24 | 6 | * | 80 |


## Group-based packet classification problem

This is a generalization of the normal packet classification problem.
The fields and match kinds are the same as before.

The difference is that in a rule, each field can have a set of one or
more match criteria.  A field matches the set of match criteria if it
matches _any_ of the match criteria.

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
become 100*80*7 = 56,000 normal rules.  We would prefer a more
efficient solution than that.
