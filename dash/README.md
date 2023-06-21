# Introduction

Author: Andy Fingerhut

Disclaimer: I may have errors or omissions in this article.
Corrections and enhancements are welcome.  Create an issue here with
"DASH" in the description somewhere:
https://github.com/jafingerhut/p4-guide/issues

The purpose of this article is to summarize how the DASH (see [1])
group-based ACL feature can be implemented in a reference model as a
P4 program running on a software switch.


# Executive summary

As of 2023-Jun-21:

None of the existing P4 software switches listed below can support the
DASH P4 reference code as written today.  All of these software
switches have gaps, either missing features and/or bugs, in their
current implementation that prevent them from being fully ready to
function as a DASH reference model.

For gory details, read the rest of the article.


# General reminder about open source projects

All of this software is open source, so it is possible to enhance them
by people with the required knowledge, skill, time, and effort.  It
does not have to be the original code developer.

In my experience, the https://github.com/p4lang projects are often
enhanced by such people, but the set of people who do so is quite
small (less than 10 in any given calendar year).  There is no person
who sits around waiting to fix bugs and make enhancements to these
projects, or who are paid full time to do so.

For DASH in particular, there is a bit of a
wait-and-see-if-someone-else-will-do-it going on, I suspect.  The
reference code is free and open source, and so any effort put into it
is a gift to the world that does not help sell a product.  Everyone
hopes that someone else will make the required enhancements, because
they are busy working on their own proprietary production
implementation.  Note: This is only my guess, and of course the
situation can change on any day that someone decides they will do the
work and give it away.


# Open source P4 software switches

Existing open source P4-programmable software switches covered here
include:

+ BMv2, also known as behavioral-model
  + Software switch code: [3]
  + Open source P4 compiler back end for BMv2 is called `p4c-bm2-ss`
    and is available here: [2]
+ P4-DPDK
  + Software switch code: TODO which repo?  I think it is [4].  The
    only way I have installed and used it before is via the steps
    described at [5].
  + Open source P4 compiler back end for P4-DPDK is called `p4c-dpdk`
    and is available here: [2]

There are others, e.g. compiling P4 to EBPF, available in open source,
but I have no experience using them.  I believe they have their own
unique restrictions, but cannot comment on what those restrictions are
based on what I know now.


# Gaps in current P4 software switches

No software switches 


## Summary

TODO - make a table summarizing the gaps?


## Gaps in all open source P4 implementations

The DASH P4 reference code uses custom `match_kind` values called
`list` and `list_port` that do not exist in any open source P4
implementation, with the possible exception of Nvidia's forked
implementation.  My understanding is that this forked implementation
is only a partial implementation of these match kinds, and cannot
populate table entries and then process packets with tables using
those match kinds.

There is a fairly straightforward workaround for this:

Instead of using `list` and `list_port` match kinds, use `ternary` for
source/dest IP addresses, and `range` for L4 source/dest ports.

Then in some layer of software between the DASH northbound API and the
P4 software switch, do a "cross-producting" of DASH ACL rules that use
tags.

This is fine as long as the size of the cross-producted rule sets is
small enough that one is willing to wait for all of those rules to be
created and added into the P4 data plane.  For BMv2 or DPDK, I have
not tested, but it should be able to handle tens of thousands if not
millions of rules, on an x86_64 system with enough RAM.

It is probably NOT sufficient to handle the largest scale ACLs desired
for DASH, but perhaps the reference model need not support those?


## Gaps in BMv2

BMv2 does not implement the add-on-miss feature defined in the PNA
specification: [7].


## Gaps in P4-DPDK

P4-DPDK already implements the PNA add-on-miss tables, which are
useful in DASH P4 reference code for maintaining connection tracking
tables.  For an example toy use case demonstrating that this works
today, see [6].

I have attempted to compile a version of the DASH P4 reference code
using `p4c-dpdk` and load it into the DPDK software switch.

There were no compile-time errors, but according to developers of
P4-DPDK, the compiler output fails to load into the DPDK software
switch because the compiler output is incorrect.  The most likely
explanation is that there are one or more bugs in the `p4c-dpdk` back
end code.  Bugs have been filed here:

+ https://github.com/p4lang/p4c/issues/3965

+ https://github.com/p4lang/p4c/issues/3966

The engineers at Intel who have developed P4-DPDK have been notified
of these issues, but as of 2021-Jun-21 these issues are not a high
priority item for them to fix.

Reminder: Re-read the "General reminder about open source projects"
section.


# References

[1] https://github.com/sonic-net/DASH

[2] https://github.com/p4lang/p4c

[3] https://github.com/p4lang/behavioral-model

[4] https://github.com/p4lang/p4-dpdk-target

[5] https://github.com/jafingerhut/p4-guide/blob/master/ipdk/23.01/README-install-ipdk-networking-container-ubuntu-20.04-and-test.md

[6] https://github.com/jafingerhut/p4-guide/blob/master/ipdk/23.01/README-install-ipdk-networking-container-ubuntu-20.04-and-test.md#testing-a-p4-program-for-the-pna-architecture-using-add-on-miss

[7] https://p4.org/p4-spec/docs/PNA-v0.7.html#sec-add-on-miss

TODO: Is Nvidia's fork of [3] publicly available?  If so, add a link
here.

