# Introduction

This directory contains a P4 program and controller programs written
in Python intended to test a longest-prefix match table implementation
for correctness.

The goal here is not to focus on any one particular implementation of
a longest-prefix match table, of which there are many that have been
invented.  Instead, it is to test scenarios where many table entries
are installed, and we verify by packet tests that among all installed
entries that are _possible_ to match, _are correctly matched_.

Note: Why do we say "among all installed entries that are possible to
match" above?  Because in a longest-prefix match table, it is easy to
install sets of table entries such that some entries are impossible to
match.  One of the simplest examples of such a set of entries is:

## Example 1

This assumes an lpm (longest-prefix match) table with a 16-bit lookup key:
+ entry #1: prefix 0x0100/8
+ entry #2: prefix 0x0180/9
+ entry #3: prefix 0x0100/9

where entries are specified by a 16-bit value in hex, a slash
separator character, followed by a decimal prefix length in units of
bits.

Given the set of entries in Example 1, for all possible 16-bit lookup
keys, they fall into one of these categories:

+ It matches none of the entries, e.g. lookup key 0x8000.  In this
  case a P4 table apply() should get a miss, and execute the default
  action.
+ It matches entry #1 and entry #2, of which the longest is entry #2,
  e.g. lookup key 0x01ff.  In this case a P4 table apply() should
  match entry #2, and execute its associated action.
+ It matches entry #1 and entry #3, of which the longest is entry #3,
  e.g. lookup key 0x017f.  In this case a P4 table apply() should
  match entry #3, and execute its associated action.

Note that there are _no_ lookup keys that match entry #1 only, and
execute its associated action.

In this case, entry #1 is unmatchable, and you can always get
equivalent behavior by not installing entry #1.  However, if entry #2
or entry #3 are ever later removed, then it is important to install
entry #1 to get the correct matching behavior.


## Example 2

This assumes an lpm (longest-prefix match) table with a 16-bit lookup key:
+ entry #1: prefix 0x0100/8
+ entry #2: prefix 0x0180/9
+ entry #3: prefix 0x0140/10
+ entry #4: prefix 0x0120/11
+ entry #5: prefix 0x0110/12
+ entry #6: prefix 0x0108/13
+ entry #7: prefix 0x0100/13

It takes a little more thinking about this situation, but it is
similar to Example 1 in the following way: If a lookup key matches
entry #1, then it also matches a longer prefix.  Thus entry #1 is
never the longest-matching prefix, and its associated action will
never be executed.
