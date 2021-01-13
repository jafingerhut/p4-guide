# Comparison of variants for implementating action selectors

There are 3 slightly different implementations of action selectors
given in these documents:

+ variant 1 [here](README-action-selector-variant1.md)
+ variant 2 [here](README-action-selector-variant2.md)
+ variant 3 [here](README-action-selector-variant3.md)

Here we summarize the advantages and disadvantages of each.

Note: I am certain someone can devise additional variants that have
different advantages and disadvantages as compared to one of these
three.  These examples are not intended to include all possibilities.
The intent is to show that there are some implementation choices, each
choice providing the same packet processing behavior, but with some
consequences when implementing the device driver software that handles
control plane API operations.

+ Variant 1
  + critical path: 3 dependent table lookups plus 1 integer modulo
    calculation (hash calculation can be done in parallel with first
    table lookup)
  + Disadvantages:
    + Can require large number of table updates to change the size of a
      group (see article on variant 1 for some details).
  + Advantages:
    + Critical path is only 3 dependent table lookups
+ Variant 2
  + critical path: 4 dependent table lookups plus 1 integer modulo
    calculation (hash calculation can be done in parallel with first
    and second table lookups)
  + Disadvantages:
    + Critical path is 4 dependent table lookups
  + Advantages:
    + Changing the number of members in a group requires at most O(1)
      table add/delete/modify operations.
+ Variant 3
  + critical path: 3 dependent table lookups plus 1 modulo calculation
    and 1 integer addition (hash calculation can be done in parallel
    with first and second table lookups)
  + Advantages:
    + Critical path is only 3 dependent table lookups
    + Changing the number of members in a group often requires at most
      O(1) table add/delete/modify operations, but in some cases
      requires more.  When it requires more, the number of operations
      should be possible to keep as low as the size of the group being
      modified, or some low multiple of that.
  + Disadvantages:
    + Driver software must implement some memory management techniques
      for maintaining all group members in contiguous entries of the
      member table.

Having a short critical path is better for achieving a low latency
implementation.  Dependent table lookups cannot begin the later table
lookup until the earlier table's action is complete.  Parallelism in
an implementation (whether hardware or software) can enable
independent calculations (such as the hash calculation) to be done in
parallel with other operations, but cannot reduce start-to-finish
latency of this critical path for an individual packet.


# What if my target device cannot do integer modulo operations?

Some target devices do not have a capability to calculate an integer
modulo operation with an arbitrary divisor.  For example, several
switch ASICs implement integer modulo for selecting one among several
equal cost paths (ECMP) up for any number of members from 1 up to 32,
but not for larger groups, because of the cost in silicon die area of
implementing the integer modulo operation.  Some very small and cheap
CPU cores do not implement integer multiply and divide instructions.

The main purpose of the integer modulo operation shown in the action
selector implementation is to select one member of a group of size N,
with each member selected as often as any other.

For example, if the input values we select for a hash function are
evenly distributed, and we use a hash function with 16 bits of result,
such that all values in the range [0, 65535] are evenly distributed,
then integer modulo gives exactly evenly distributed member selection
for group sizes that are a power of 2, and for others gives very close
to equal distribution of members.

For example, for a group with 6 members, here are the number of values
in the range [0, 65535] that give each of the results 0 through 5 when
you divide them by 6 and take the remainder:

+ remainder 0: 10923 hash values
+ remainder 1: 10923 hash values
+ remainder 2: 10923 hash values
+ remainder 3: 10922 hash values
+ remainder 4: 10922 hash values
+ remainder 5: 10922 hash values

This is so close to an equal distribution that it is unlikely to
concern anyone.  It is significantly more likely that the set of
packet flows passing through a device near the same time have unequal
packet or bit rates, or that there are few enough of them, that the
resulting distribution is unequal for those reasons, than that the
modulo operation is introducing problems.

So what can one do in a restricted computing situation where one
cannot do an integer modulo operation for arbitrary divisors, but let
us suppose that you _can_ still do integer modulo by any power of 2.
Those restricted modulo are all equivalent to selecting the least
significant K bits of a value (e.g. modulo 256 is the same as a
bitwise AND operation with 0xff), and is typically available even when
general integer modulo is not.

The technique described below allows one to make a tradeoff between:

+ larger table sizes and more even distribution selecting group members
+ smaller table sizes and less even distribution selecting group members

It can be used in combination with any of the three variants of action
selectors linked above.

The basic idea is that whenever the control plane API requests a group
with N members, we implement it using a larger group with a number of
members that is a power of 2.

To make a reasonably small example, let us suppose that we consider it
acceptable if some members are selected 5/4 times more often than
other members, but we do not want any unevenness larger than that.

If we want a group of 1 or 2 members, those are small special cases
where we can perform the modulo by 1 or 2 exactly, since those are
powers of 2, and it seems reasonable to make those special cases, and
not increase the number of members.

For 3 members, though, that will not work.  If we make a table of
members with at least 3*4 = 12 members, rounding that up to the next
power of 2, which is 16, we can fill in a table of 16 slots with
multiple copies of the 3 members, such that each member occurs at
least 4 times, but none more than 5 times.  For example:

| Remainder | member action to use |
| --------- | -------------------- |
|  0 | 1 |
|  1 | 2 |
|  2 | 3 |
|  3 | 1 |
|  4 | 2 |
|  5 | 3 |
|  6 | 1 |
|  7 | 2 |
|  8 | 3 |
|  9 | 1 |
| 10 | 2 |
| 11 | 3 |
| 12 | 1 |
| 13 | 2 |
| 14 | 3 |
| 15 | 1 |

Member 1 occurs 5 times, and members 2 and 3 occur 4 times each.  If
calculating the hash value modulo 16 results in the values 0 through
15 with equal frequency, then member 1 will be selected 5/4 times more
than members 2 or 3.

More generally, for N members, if you want a ratio of at most 5/4
between the most frequently used member and the least frequently used
member, you should increase the number of members-with-duplicates to
4*N, then rounded up to the next power of 2.

| desired # of members N | actual # of members after duplication |
| ---------------------- | ------------------------------------- |
|          1 |   1 |
|          2 |   2 |
|  3 ...   4 |  16 |
|  5 ...   8 |  32 |
|  9 ...  16 |  64 |
| 17 ...  32 | 128 |
| 33 ...  64 | 256 |
| 65 ... 128 | 512 |

If you want a ratio of at most (K+1)/K between the most frequently
used member and the least frequently used member, you should increase
the number of members-with-duplicates to K*N, then rounded up to the
next power of 2.
