# Introduction


## Normal packet classification problem

An instance of a "normal" packet classification problem consists of:

+ a set of packet _fields_ F, where field f can be represented as a
  W_f-bit unsigned integer.
+ a match kind for each field, and
+ a set of _rules_ R for matching the fields against.

Each match kind is one of:

+ ternary - the match criteria is a value V and a mask M.  A
  field value f matches if (f & M) == V.
+ range - the match criteria is a minimum value N and a maximum value
  X.  A field value f matches if (N <= f) && (f <= X).
+ prefix - the match criteria is a value V and a prefix length P in
  the range [0,W], where the field is W bits.  A field matches as if
  the match kind were ternary with the same value V and a mask M=(((1
  << W) - 1) >> (W-P)) << (W-P).  This is a "prefix mask", such that
  the value must equal the field in the most significant P bits.
+ optional - like ternary, except the mask is restricted to be either
  0 for completely don't care value, or ((1 << W) - 1) for exact
  value.

Each rule consists of:

+ a priority, which is a positive integer
+ For every field f, a match criteria appropriate for the match kind
  of the field.

A set of fields f matches a rule r iff for every field f, the value of
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

A match critera of * means that it matches any value for the field.
This corresponds to a mask of 0 for ternary or optional, a prefix
length of 0 for prefix, or a range including all possible values of
the field for range.

Rules:

+ priority 100, SA 10.1.1.0/24, DA 192.168.1.0/24, proto 6, SP *, DP 80
+ priority 90, SA 10.1.1.0/24, DA 192.168.1.0/24, proto 6, SP *, DP 443
+ priority 80, SA 10.0.0.0/8, DA 192.168.0.0/16, proto 1, SP *, DP *
+ priority 70, SA *, DA *, proto 6, SP *, DP 53
+ priority 60, SA *, DA *, proto 17, SP *, DP 53
+ priority 50, SA 10.1.1.0/24, DA 192.168.1.0/24, proto 6, SP *, DP 80


## Group-based packet classification problem

This is a generalization of the normal packet classification problem.
The fields and match kinds are the same as before.

The difference is that in a rule, each field can have a set of one or
more match criteria.  A field matches the set of match criteria if it
matches _any_ of the match criteria.

As very small example, the group-based rules below are based on the
same set of fields and match kinds as given in the previous example.

+ priority 100, SA {10.1.1.0/24, 10.2.0.0/16}, DA {192.168.1.0/24, 192.168.2.38/32}, proto {6}, SP {*}, DP {80}
+ priority 90, SA {10.1.1.0/24}, DA {10.3.0.0/16, 192.168.0.0/16}, proto 17, SP *, DP {53, 90-99}

The group-based rules above are equivalent in matching behavior to the
following normal rules.  We have simply performed a "cross product"
among the sets for each individual field.

+ priority 100, SA 10.1.1.0/24, DA 192.168.1.0/24, proto 6, SP *, DP 80
+ priority 100, SA 10.1.1.0/24, DA 192.168.2.38/32, proto 6, SP *, DP 80
+ priority 100, SA 10.2.0.0/16, DA 192.168.1.0/24, proto 6, SP *, DP 80
+ priority 100, SA 10.2.0.0/16, DA 192.168.2.38/32, proto 6, SP *, DP 80
+ priority 90, SA 10.1.1.0/24, DA 10.3.0.0/16, proto 17, SP *, DP 53
+ priority 90, SA 10.1.1.0/24, DA 10.3.0.0/16, proto 17, SP *, DP 90-99
+ priority 90, SA 10.1.1.0/24, DA 192.168.0.0/16, proto 17, SP *, DP 53
+ priority 90, SA 10.1.1.0/24, DA 192.168.0.0/16, proto 17, SP *, DP 90-99

This example shows one correct way to implement a group-based packet
classification problem: translate it to a normal packet classification
problem after performing the cross product of each individual rule.

The disadvantage of this solution is that each rule with N1 SAs, N2
DAs, N3 protos, N4 SPs, and N5 DPs will become `N1*N2*N3*N4*N5` rules
in a normal packet classification problem.  We would prefer a more
efficient solution than that.
