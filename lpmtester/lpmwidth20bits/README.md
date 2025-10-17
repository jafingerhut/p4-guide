# Introduction

This directory contains a slightly modified version of the LPM tester
code in the parent directory.

It is focused on testing an LPM key field that has a bit width that is
20 bits wide.  This width was chosen specifically as one that is not a
multiple of 8 bits wide.  There was an issue created in the
p4runtime-shell repository recently [1], and I wanted to find out
whether BMv2 handled insertion of entries into, and matching of
entries within, such LPM tables.

[1] https://github.com/p4lang/p4runtime-shell/pull/148

My initial results appear to indicate that it does not handle
insertions correctly when using the latest versions of the code in the
PI and p4runtime-shell repositories.

When I use the change proposed in [1] to p4runtime-shell, I get an
error on some attempted insertions of a new LPM entry during
BasicTest2.  A few more details can be found in this comment to [1]:

[2] https://github.com/p4lang/p4runtime-shell/pull/148#issuecomment-3398111597

I should try a modification to the PI repository code that changes
that check of input values, combined with the changes in [1], and see
if I can get all of these tests to pass with those versions of the
code.

If so, create a PR for the PI repository with that correction.
