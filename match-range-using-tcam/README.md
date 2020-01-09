It is well known, at least among people who have worked on packet
classification for ACLs (Access Control Lists), that one can match an
arbitrary [min, max] range of a W-bit wide field using at most 2W-2
TCAM entries, for a single field.

There are mentions of this in published research papers, without
explicitly giving the construction, since approximately the year 2000,
I am nearly certain that the technique described here was first
published in the 1990s, but do not have a citation (please send me one
if you know so I can add that here).

The basic idea is to partition the set of values in the range [min,
max] into one or more disjoint ranges whose union contains exactly the
same set of values as the original range.

Also, each of these ranges can be represented with a single prefix
value/mask, where by a prefix value/mask I mean one where the mask is
exact match on 0 or more consecutive most significant bits of the
field, and don't-care or wildcard on the remaining least significant
bits.

A prefix value/mask always matches a set of values in an "aligned
power of 2 range".  That is, the range will be of the form `[a,
a+size-1]` where `X` is the number of wildcard bit positions,
`size=2^X`, and `a` is an integer multiple of `size`.

For a given desired range `[min, max]`, and some prefix value/mask
that matches exactly the field values in range `[a, b]` that we are
considering, there are three possibilities:

+ Case 1: `[a, b]` lies completely within `[min, max]`, i.e. `min <= a
  <= b <= max`.  `[a, b]` is OK to use as part of the implementation.

+ Case 2: `[a, b]` lies completely outside of the range `[min, max]`.
  That is, either `b < min`, or `max < a`.  We should discard such a
  range `[a, b]` entirely.

+ Case 3: `[a, b]` contains some value within `[min, max]`, but also
  some values outside of `[min, max]`.  This is if it is neither of
  the cases above.  We should split the prefix range into two prefix
  ranges, where one contains the first half of the values in `[a, b]`,
  and the other contains the last half.  Then consider each of those
  two ranges independently, to determine which of these 3 cases is
  true for them.

Thus one algorithm is to start with the prefix value/mask that is
wildcard in all W bit positions, which matches the range `[0, 2^W-1]`.
Determine which of the 3 cases above is true for it.  If it is case 1,
we are done with that one prefix value/mask.  If it is case 3, we
recurse on the two new prefix value/mask ranges.

Example:

A field with width W=4 bits, for which we want to match the range with
`min=1` and `max=5` decimal.  The `min` and `max` values written in
binary are:

```
min   0001   (1 decimal)
max   0101   (5 decimal)
      ^  ^ bit position 0
     bit
     position
      3
```

In the examples, we will represent a value/mask as a string that
contains x for wildcard bit positions, or a 0 or 1 for an exact match
bit position.

```
Reminder of input range values:
0001   min = 1 decimal
0101   max = 5 decimal

The initial prefix to consider is:

xxxx   prefix is range [0, 15].  Case 3.  Split into ranges (0) and (1) below.

(0)
0xxx   prefix is range [0, 7].  Case 3.  Split into ranges (00) and (01) below.

(00)
00xx   prefix is range [0, 3].  Case 3.  Split into ranges (000) and (001) below.

(000)
000x   prefix is range [0, 1].  Case 3.  Split into ranges (0000) and (0001) below.

(0000)
0000   prefix is range [0, 0].  Case 2.  Discard.

(0001)
0001   prefix is range [1, 1].  Case 1.  Keep.

(001)
001x   prefix is range [2, 3].  Case 1.  Keep.

(01)
01xx   prefix is range [4, 7].  Case 3.  Split into ranges (010) and (011) below.

(010)
010x   prefix is range [4, 5].  Case 1.  Keep.

(011)
011x   prefix is range [6, 7].  Case 2.  Discard.

(1)
1xxx   prefix is range [8, 15].  Case 2.  Discard.
```

The "case 1. keep" cases above are for the following ranges, which is
the result of the range expansion of [1, 5] for W=4 bits:

```
0001   prefix is range [1, 1].  Case 1.  Keep.
001x   prefix is range [2, 3].  Case 1.  Keep.
010x   prefix is range [4, 5].  Case 1.  Keep.
```

Two programs are included in this directory:

+ Python program `range-to-tcam-entries.py`
+ C program `range-to-tcam-entries.c`

They do not use exactly the algorithm above, but they produce the same
result.  They use mask values with bit position of 1 to indicate an
exact match bit position, 0 to indicate a wildcard/don't-care bit
position.

```
$ ./range-to-tcam-entries.py --bit-width 4 --min 1 --max 5
idx      value      mask   range_min range_max
         (hex)      (hex)  (decimal) (decimal)
 0          1          f          1          1
 1          2          e          2          3
 2          4          e          4          5

$ gcc range-to-tcam-entries.c -o range-to-tcam-entries

$ ./range-to-tcam-entries 4 1 5
value 0x0000000000000001 mask 0x000000000000000f min 1 max 1
value 0x0000000000000002 mask 0x000000000000000e min 2 max 3
value 0x0000000000000004 mask 0x000000000000000e min 4 max 5
```

In general, the range `[1, 2^W-2]` causes the largest number of
value/masks to be produced, `2W - 2` of them.  Here is sample output
for `W=16`:

```
 ./range-to-tcam-entries.py --bit-width 16 --min 1 --max 65534
idx      value      mask   range_min range_max
         (hex)      (hex)  (decimal) (decimal)
 0          1       ffff          1          1
 1          2       fffe          2          3
 2          4       fffc          4          7
 3          8       fff8          8         15
 4         10       fff0         16         31
 5         20       ffe0         32         63
 6         40       ffc0         64        127
 7         80       ff80        128        255
 8        100       ff00        256        511
 9        200       fe00        512       1023
10        400       fc00       1024       2047
11        800       f800       2048       4095
12       1000       f000       4096       8191
13       2000       e000       8192      16383
14       4000       c000      16384      32767
15       8000       c000      32768      49151
16       c000       e000      49152      57343
17       e000       f000      57344      61439
18       f000       f800      61440      63487
19       f800       fc00      63488      64511
20       fc00       fe00      64512      65023
21       fe00       ff00      65024      65279
22       ff00       ff80      65280      65407
23       ff80       ffc0      65408      65471
24       ffc0       ffe0      65472      65503
25       ffe0       fff0      65504      65519
26       fff0       fff8      65520      65527
27       fff8       fffc      65528      65531
28       fffc       fffe      65532      65533
29       fffe       ffff      65534      65534
```

The Python program also provides a `--test` option (the C program
implements this by providing _any_ command line argument after the max
value), which causes the program to exhaustively try _all_ ranges with
the given width in bits, approximately `2^(2*W)` of them, so testing
with `W > 10` can require significant patience.

For each of those ranges, it will call the Python/C function
`range_to_tcam_entries` to compute the list prefix value/masks for the
range.  The Python version then calls `check_tcam_entries` to verify
that they are prefix masks, that each covers a disjoint range, and
that together they cover the entire input range.  It will raise an
exception if any incorrect list of prefix value/masks is found.  The C
version will exit with Unix error status 1 and print a message to
stderr if it finds a mistake in the result.

I have run the exhaustive test for all bit widths from 1 up to 11 and
it found no errors, so I have very high confidence that the code for
calculating lists of prefix value/masks is correct.


Extensions:

If one wanted to then match on two independent fields simultaneously
using [min, max] ranges, e.g. a layer 4 16-bit source port and 16-bit
destination port, as used in UDP and TCP packets, you can perform the
"range to TCAM-entry expansion" described here independently for each
of the two fields, yielding a set S1 of TCAM value/masks for field F1,
and a set S2 for field F2.  Then perform the cross product of the sets
S1 and S2.


Note that the set of TCAM entries produced are such that at most one
of them can match any individual field.  This is not a critical
property when populating the entries in a TCAM, where it is acceptable
for many entries to match, and the highest priority will "win", but
there may be contexts in which this property is important, e.g. some
algorithmic TCAM approaches.
