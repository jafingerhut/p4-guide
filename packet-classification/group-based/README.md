# Introduction

The group-based packet classification problem arises in many
operational network scenarios.

It is used to perform security for several cloud-based VM/container
deployment services, such as Kubernetes, and there are several cloud
service providers such as AWS, Microsoft Azure, and Google Cloud
Platform that allow their tenants to create group-based security rules
for which packets to allow to be forwarded between the tenant's
deployed VMs/containers, vs. which should be dropped.

See [this
section](#systems-that-use-something-similar-to-group-based-classification)
for systems that use something that is at least similar to the
group-based classification problem.


## Normal classification problem

An instance of a "normal" classification problem consists of:

+ a set of _fields_ F, where field f can be represented as an unsigned
  integer with `W(f) bits.
+ a match kind for each field (see below), and
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
    V=0x0a010100 with prefix length P=24, which matches the same as a
    ternary field with the same value V and a mask M=0xffffff00.
+ optional - like ternary, except the mask is restricted to be either
  0 for a completely don't care value, or `((1 << W) - 1)` for exact
  value.

Aside: `optional` is a restriction on `prefix`, which in turn is a
restriction on `ternary`.  `prefix` is also a restriction on `range`.
Neither of `range` and `ternary` is a restriction of the other.  A
single exact value can be represented using any of these, e.g. a
ternary, prefix, or optional field with a mask of `M=(1 << W) - 1` for
a W-bit field, or a range with MIN and MAX both equal to the one exact
value to be matched.

Each rule consists of:

+ a priority, which is a positive integer
+ For every field f, a match criteria appropriate for the match kind
  of the field.

A set of fields F matches a rule r if and only if for every field f,
the value of field f matches the match criteria given in the rule R.

The classification problem has these inputs:

+ a set of rules R
+ a set of field values f

and this output:

+ Among all rules r in R such that f matches r, find one that has the
  maximum priority.  If no rules in R match, return "none".

Detail: In this definition of the problem, we will explicitly allow
sets of rules where more than one are allowed to have the same
priority value.  In such a case, an algorithm can find _any_ matching
rule that has the maximum priority, if there is more than one such
rule with the same maximum priority value.

Note that typically, the set of rules R will change only rarely,
compared to how often we receive a new set of field values f.

For example, a network device may process hundreds of millions of
packets per second, each with their own independent field values to be
classified, whereas the set of rules R might change on average once
per hour, or once every 10 minutes.

Thus there are many solutions to this problem that execute fairly
complex algorithms when a new set of rules R is given, which create
data structures that can be very efficiently used to classify many
sets of fields against the same set of rules.


### Example of the normal classification problem

Fields and their match kinds:

+ IPv4 source address (abbreviated SA), prefix
+ IPv4 destination address (abbreviated DA), prefix
+ IPv4 protocol (abbreviated proto), optional
+ L4 source port (abbreviated SP), range
+ L4 destination port (abbreviated DP), range

The L4 source and destination port come from a packet if the packet
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


## Group-based classification problem

This is a generalization of the normal classification problem.  The
fields and match kinds are the same as before.

The difference is that in a rule, each field can have a set of one or
more match criteria.  A field matches the set of match criteria if it
matches _any_ of the match criteria.


### Example of the group-based classification problem

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

This example shows one correct way to implement a group-based
classification problem: translate it to a normal classification
problem by calculating the cross product of each individual rule.

The disadvantage of this solution is that each rule with N1 SAs, N2
DAs, N3 protos, N4 SPs, and N5 DPs will become `N1*N2*N3*N4*N5` rules
in a normal classification problem.  For example, a group-based rule
with 100 SA prefixes, 80 DA prefixes, and 7 DP ranges would become
`100*80*7 = 56,000` normal rules.  We would prefer a more efficient
solution than that.


# Algorithms for the classification problem

There are many algorithms in the published literature for the normal
classification problem.  See the references section.


## Evaluating a subset of field match criteria

If we take the first example of the normal classification problem
above, with the following rules:

| priority | SA | DA | proto | SP | DP |
| -------- | -- | -- | ----- | -- | -- |
| 100 | 10.1.1.0/24 | 192.168.1.0/24 | 6 | * | 80 |
|  90 | 10.1.1.0/24 | 192.168.1.0/24 | 6 | * | 443 |
|  80 | 10.0.0.0/8 | 192.168.0.0/16 | 1 | * | * |
|  70 | * | * | 6 | * | 53 |
|  60 | * | * | 17 | * | 53 |
|  50 | 10.1.0.0/16 | * | 6 | * | * |
|  40 | * | * | * | * | * |

and we consider the following set of fields:

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

This simple algorithm works for both the normal and group-based
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
rows, which evaluate all field match criteria for that search key in
parallel.

Each TCAM entry in parallel calculates the logical AND of the
individual field match criteria within, producing a final 0/1 "entry
match bit" indicating whether all fields of the entry match.

The result is a bit vector containing 1 bit per entry.  A [priority
encoder](https://en.wikipedia.org/wiki/Priority_encoder) hardware
block finds the first 1 in O(log N) logic gate delays.

A common hardware design is to number the TCAM hardware entries from 0
up to `size-1`, and for the priority encoder logic to treat the entry
match bit for entry 0 as the first bit in the priority encoder, and
the entry match bit for entry `size-1` as the last bit.  In such a
hardware design, the TCAM should be initialized to have the higher
priority rules in hardware entries with smaller indexes than lower
priority rules.

The output of the priority encoder is the index of the first entry
where all fields match, or a special "miss" signal indicates if there
was no matching entry.

This parallel evaluation is why TCAMs often use so much power relative
to non-TCAM hardware such as SRAM or DRAM, because so many of the
wires between logic gates can change from 0 to 1 or 1 to 0 during this
parallel evaluation process.


### Field-wise evaluation

Note: The algorithm described here appears to be identical to the one
in Section 4.1 of [LS1998].  As far as I can tell, their algorithm
covers all match kinds that can be represented as [min,max] ranges,
which includes prefix, range, and optional, but not ternary.  Section
4.2 of that paper has some ideas on reducing the storage and perhaps
also memory accesses required to create the N-bit bitmap for a single
field, which are not described in this article.

In this evaluation order, we devise a method where given a single
lookup field of the packet, we calculate one column of the match
results in the table above, with the result being an N-bit vector (see
below for examples of such methods).

After the N-bit vector for each column has been calculated, perform a
bitwise AND of all of them, resulting in the same N-bit vector of
entry match bits that a hardware TCAM calculates.

Then find the first 1 bit, and output its bit position, or a miss
result if the N-bit vector is all 0.  This is the same function that a
TCAM's priority encoder hardware calculates, but of course it can also
be implemented in software.

The main disadvantage of this approach is that for large N, the
intermediate N-bit vectors are large.  This can be mitigated somewhat
by first finding the first M < N bits of each N-bit vector, and
bit-wise ANDing those.  If the result is entirely 0, then read the
next M bits of each N-bit vector and repeat.  The number of fetches is
then linear in (N/M) times the number of fields.

An advantage of this algorithm is that for the match kinds where it is
applicable, it generalizes fairly easily from the normal to the
group-based classification problem, _without_ incurring any cost for a
"cross product" as the algorithm described in [an earlier
section](#example-of-the-group-based-classification-problem).


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

The longest-prefix match table for field SA would contain the prefixes
and associated 7-bit vectors shown in the table below, where the bits
in the bit vector have the bit for rule with priority 100 first, and
the bit for the rule with priority 40 last.

| prefix | 7-bit vector |
| ------ | ------------ |
| *           | `0001101` |
| 10.0.0.0/8  | `0011101` |
| 10.1.0.0/16 | `0011111` |
| 10.1.1.0/24 | `1111111` |

Note that while this example is for a normal classification problem,
this technique for constructing a longest-prefix match tree for a
single field also works for the group-based classification problem,
too.


#### Field has match kind optional

For every match criteria that is exact match in a rule, add the value
to a hash table.  The N-bit vector that is the result of the entry
with key X has the value 1 for bit positions corresponding to all
rules that match value X, or that have a completely don't-care value
because its mask is 0.

This approach for optional match kind fields works equally well for
both the normal and group-based classification problems.


#### Field has match kind range

For fields with a small number of bits W, the technique for match kind
ternary (described below) also course works here.

For arbitrary size fields, it is possible to construct a binary or
multi-way search tree that compares the lookup field value against
values stored in the tree, and each leaf corresponds to a range of
values.

TODO: Give a small example of this.


#### Field has match kind ternary

There is actually no simple general way to calculate the value of the
N-bit column vector for a ternary match field, when the masks can be
arbitrary.  This is just as difficult as the normal classification
problem, even though it is for only one field.

If the field is very small, e.g. W=4 bits, you can create a lookup
table for all possible field values in the range [0, 2^W-1] where the
result contains the N-bit vector.  This is prohibitively expensive for
large values of W.

For wide fields, e.g. 128 bits, one could break it up into smaller
sub-fields, e.g. each k=8 bits wide, and create a 2^k-entry lookup
table for each sub-field.  Then bitwise AND the N-bit results with
each other.  This is significantly less memory than a 2^128 entry
table!


# Specializing rules when implemented in a distributed way

In some data center environments, instead of performing packet
classification in switches or routers, it can instead be done in the
hosts in a distributed manner, with every host classifying packets
before transmitting them to the network.  For example, the host could
classify the packets in a layer of host CPU software beneath all
VMs/containers, such as a hypervisor, or it could be performed in the
host's NIC.

Suppose you wish to classify packets based on a set of normal or
group-based rules that is "globally configured across the network" by
the network owner.  Each rule contains both source and destination IP
addresses and/or prefixes, plus any other fields of interest
(typically at least IP protocol and L4 source and destination port
values, but perhaps other fields, too).

A host might have many VMs or containers running on it.  Consider a
single VM or container, H.  Starting with the full set of
classification rules R, create a set of rules R(H) that is specialized
for packets sent by H, by assuming that the source IP address of every
packet is equal to H's IP address A.  In practice, many of the rules
will never match for packets with source address A, and they can be
eliminated from R(H).  For all remaining rules that might match when
the packet's source address is A, we can eliminate the source IP
address field from every rule.

When a packet is sent by H, the hypervisor or NIC implementing
classification can begin the classification by looking up the packet's
source address A in a small hash table, with the result pointing at
the set of rules R(H).  The smaller R(H) will typically be
significantly easier to classify than R.


# Systems that use something similar to group-based classification


## Cisco object groups

One source of documentation for [Cisco object
groups](https://www.cisco.com/en/US/docs/ios-xml/ios/sec_data_acl/configuration/15-2mt/sec-object-group-acl.html).

These are a generalization of Cisco extended access lists, where
instead of a single value/mask for a source or destination IP address,
you can give an object group name, which is configured as a set of IP
address prefixes.  Similarly, you can specify either a single source
or destination port, or an object group name configured as a set of L4
port values.


## Cisco ACI contracts

Documentation of a [Cisco ACI
contract](https://www.cisco.com/c/en/us/solutions/collateral/data-center-virtualization/application-centric-infrastructure/white-paper-c11-743951.html)

An ACI contract is at least similar to the group-based classification
problem described here.

I am not certain, but it may be the case that an ACI contract imposes
an additional constraint on a set of rules: that every value of a
source or destination address field must be in at most one endpoint
group (EPG in ACI terminology), which corresponds in the group-based
classification problem defined below to a set of IP prefixes.


## Kubernetes Network Policy

Documentation for [Kubernetes Network
Policy](https://kubernetes.io/docs/concepts/services-networking/network-policies/).

Note: I do not know enough of Kubernetes network policy to say whether
such a policy can be transformed into a group-based classification
problem as defined below.  I would welcome any examples that can be,
or cannot be.


## SONiC DASH project ACL

Documentation and code related to the [SONiC DASH
project](https://github.com/sonic-net/DASH/).

In particular, see [this table
definition](https://github.com/sonic-net/DASH/blob/main/dash-pipeline/bmv2/dash_acl.p4#L37-L55)
within the P4 program proposed as a reference model for how a DASH
device should process packets.

The `LIST_MATCH` match kind mentioned there is a C preprocessor macro
for one of several possible definitions, one of which is `list`.
Match kind `list` is a custom type used in the DASH P4 code, but not
defined by the P4 language specification.  It is intended to represent
a set of prefixes.  The order of the prefixes in such a "list" has no
effect on the classification result.

The `RANGE_LIST_MATCH` match kind mentioned there is a C preprocessor
macro for one of several possible definitions, one of which is
`range_list`.  Again, this is a custom type created for the purpose of
the DASH project.  It represents a set of ranges.


# Open questions

Some of these questions only make sense with just the right context.
My apologies if they do not make sense.

Note: Section 5.2, Table 3 of EffiCuts paper is a nice way of
evaluating a hardware implementation of their algorithm against
HyperCuts and TCAM, for a hardware implementation, and seems to me to
take into account the most crucial factors that a hardware designer
would consider when comparing solutions.  Might want to consider
something like that for a model similar to CRAM model, but focused on
designing new hardware, rather than taking advantage of existing RMT
or dRMT chip.

Can the techniques of the HEXA paper be used to reduce the pointer
space required for an algorithm like HiCuts, HyperCuts, and/or
EffiCuts?  It seems like yes.  If yes, how much?  From the memory
savings of EffiCuts vs. HyperCuts described in the EffiCuts paper, I
suspect the savings for anything except EffiCuts would not be nearly
as big as the savings provided by using EffiCuts, but perhaps it might
be noticeable savings for EffiCuts?

Can using TCAM for multi-way branching decisions in a search tree for
EffiCuts help improve the algorithm at all?  The trick would be to use
a small amount of TCAM to reduce the SRAM by more than 3X that number
of TCAM bits used.


# References

I am keeping these at least close to the order of most recent
publications first.  This is not in any way implying that the most
recent ones are the most important.

+ [LXLSRXLW2022] Yuxi Liu, Yao Xin, Wenjun Li, Haoyu Song, Ori
  Rottenstreich, Gaogang Xie, Weichao Li, Yi Wang, "HybridTSS: A
  Recursive Scheme Combining Coarse- and Fine-Grained Tuples for
  Packet Classification", 2022, http://wenjunli.com/HybridTSS/
+ [XLJLXLTZ2021] Yao Xin, Wenjun Li, Chengjun Jia, Xianfeng Li, Yang
  Xu, Bin Liu, Zhihong Tian, Weizhe Zhang, "Extended Journal Paper:
  Recursive Multi-Tree Construction with Efficient Rule Sifting for
  Packet Classification on FPGA (Under Review)", 2021,
  http://www.wenjunli.com/KickTree/
+ [AFR2020] Mahdi Abbasi, Saeideh Vesaghati Fazel, Milad Rafiee,
  "MBitCuts: optimal bit-level cutting in geometric space packet
  classification" The Journal of Supercomputing volume 76, pages
  3105–3128 (2020)
  https://link.springer.com/article/10.1007/s11227-019-03090-3
+ [LSZGL2017] Zhi Liu, Shijie Sun, Hang Zhu, Jiaqi Gao, Jun Li,
  "BitCuts: A fast packet classification algorithm using bit-level
  cutting", 2017, https://doi.org/10.1016/j.comcom.2017.05.001
  + Short public paper that might be a subset or earlier version of
    the full paper above: SIGCOMM 2015,
    https://conferences.sigcomm.org/sigcomm/2015/pdf/papers/p339.pdf
+ [YFJXL2014] B. Yang, J. Fong, W. Jiang, Y. Xue, J. Li, "Practical
  Multituple Packet Classification Using Dynamic Discrete Bit
  Selection," in IEEE Transactions on Computers, vol. 63, no. 2,
  pp. 424-434, Feb. 2014, https://doi.org/10.1109/TC.2012.191
+ [KNRCE2014] Kirill Kogan, Sergey Nikolenko, Ori Rottenstreich,
  William Culhane, Patrick Eugster, "SAX-PAC (Scalable And eXpressive
  PAcket Classification)", SIGCOMM 2014,
  http://dx.doi.org/10.1145/2619239.2626294
+ [LL2013] Wenjun Li, Xianfeng Li, "HybridCuts: A Scheme Combining
  Decomposition and Cutting for Packet Classification", 2013,
  https://doi.org/10.1109/HOTI.2013.12
+ [VVV2010] Balajee Vamanan, Gwendolyn Voskuilen, T. N. Vijaykumar,
  "EffiCuts: optimizing packet classification for memory and
  throughput", ACM SIGCOMM Computer Communication Review, Volume 40,
  Issue 4, October 2010, pp 207–218,
  https://doi.org/10.1145/1851275.1851208
  + See the compressedcut Github repository mentioned below for a
    possible EffiCuts implementation.
+ [QXYXL2009] Y. Qi, L. Xu, B. Yang, Y. Xue, J. Li, "Packet
  Classification Algorithms: From Theory to Practice," IEEE INFOCOM
  2009, Rio de Janeiro, Brazil, 2009, pp. 648-656,
  https://doi.org/10.1109/INFCOM.2009.5061972
+ [TT2005] David E. Taylor, Jonathan S. Turner, "ClassBench: A Packet
  Classification Benchmark", 2005,
  https://www.arl.wustl.edu/~jon.turner/pubs/2005/infocom05classBench.pdf
  + Technical report version,
    https://openscholarship.wustl.edu/cse_research/1001/
  + See also mentions of classbench under "Implementations" heading.
+ [SBVW2003] Sumeet Singh, Florin Baboescu, George Varghese, Jia Wang,
  "Packet classification using multidimensional cutting", SIGCOMM
  2003, https://doi.org/10.1145/863955.863980
+ [LS1998] T. V. Lakshman and D. Stiliadis, "High-Speed Policy-based
  Packet Forwarding Using Efficient Multi-dimensional Range Matching",
  1998, https://dl.acm.org/doi/10.1145/285237.285283


## Implementations

+ https://github.com/wenjunpaper has several projects that appear to
  have implementations of several kinds of cutting tree packet
  classification algorithms.
+ This claims to be an implementation of EffiCuts written by the
  paper's authors, and modified by another person after that:
  https://github.com/kun2012/compressedcut
+ Original ClassBench code released from Washington University, last
  updated in 2004, https://www.arl.wustl.edu/classbench/
+ classbench-ng, based upon Taylor and Turner's original project that
  is no longer maintained, https://github.com/lucansky/classbench-ng


## Patents

Patented technology related to packet classification problem:

+ Two patents filed by Madian Somasundaram as part of startup company
  Spanslogic:
  + filed 2004, granted 2007,
    https://patents.google.com/patent/US7162572B2/en?q=(spanslogic)&inventor=somasundaram&oq=spanslogic+somasundaram
  + filed 2006,
    https://patents.google.com/patent/US7321952B2/en?inventor=Madian+Somasundaram
