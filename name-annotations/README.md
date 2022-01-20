# Introduction

There have been some subtle issues and/or bugs related to:

+ P4 actions with the same name, but different signatures,
  e.g. different number of parameters
+ P4 actions with different names, but having `@name` and/or `@id`
  annotations with the same values as each other.
+ Intermediate stages of the open source p4c compiler that sometimes
  take a single action in the original user's P4 program, and create
  multiple copies of this action, one for each table it can be an
  action of.  Motivation: Enable the P4 compiler to optimize each of
  these copies independently of the other, since they are typically
  executed at different times and with different contexts from each
  other.

The purpose of the files in this directory is to attempt to collect a
few interesting small sample P4 programs that are correct at least
according to their syntax, but may be questionable in whether they
have meaningful semantics, and even if they do have meaningful
semantics, what that meaning is, both from the perspective of data
plane behavior, and what control plane API should be auto-generated
from the program.

I (Andy Fingerhut) will give my opinion on whether each of these
programs is meaningful or not, and what the meaning is if it is
meaningful, but I don't claim that my opinions will match those of
other P4 language experts.  I could also be easily missing some
subtleties in my evaluations of these programs, and am happy to be
corrected on anything I have missed.

Since the P4Runtime API has an open source implementation in the p4c
compiler, that is the one mentioned in these examples, but TDI is
another that should be evaluated in its current implementation, to see
if its implementation differs from p4c+P4Runtime API's.


# Things in common between all sample P4 programs here

None of these programs are intended to be functionally useful to run
in a production network.  They are intended to demonstrate potential
corner cases in the naming of actions in the P4 program, and in the
auto-generated control plane API.

All of them are written for the v1model architecture, but I want to
make it straightforward to compile them for other P4 architectures,
too, such as TNA, PSA, and/or PNA.  The only differences between these
programs is in a few table and/or action definitions that are all
within the same control, which for sake of example are all in the
ingress control for the switch architectures that have ingress and
egress, and all in the main control for PNA.


# References

+ All p4c issues with the label `control_plane_api`:
  https://github.com/p4lang/p4c/issues?q=is%3Aopen+is%3Aissue+label%3Acontrol_plane_api

As of 2022-Jan-19, that list includes:

+ https://github.com/p4lang/p4c/issues/1936 Odd behavior with same-named actions
+ https://github.com/p4lang/p4c/issues/2716 Is this the intended effect of @name annotations when generating P4Info files?
+ https://github.com/p4lang/p4c/issues/2749 Control-plane name clash introduced by LocalizeAllActions and RemoveActionParameters
+ https://github.com/p4lang/p4c/issues/2755 Incorrect P4Info generation when different actions have same name annotation

No, it is not a coincidence that I wrote this article, and created 3
out of 4 of these issues :-)



# Brief notes on some of the P4 programs

See the README files in the sub-directories for more details.

actions-1-same-name.p4 has only cosmetic changes from the program
actions-same-name1.p4 in the ZIP file issue1936.zip attached to [p4c
issue 1936](https://github.com/p4lang/p4c/issues/1936).

Similarly, actions-2-same-name.p4 has only cosmetic changes from the
program actions-same-name2.p4 in that same ZIP file.

actions-5-same-name-annot.p4 has only cosmetic changes from the
program actions-same-name5.p4 in the ZIP file attached to [p4c issue
2755](https://github.com/p4lang/p4c/issues/2755).

Similarly, actions-6-same-name-annot.p4 has only cosmetic changes from
the program actions-same-name6.p4 in that same ZIP file.

actions-5-no-annot.p4 is identical to actions-5-same-name-annot.p4,
except the `@name` annotations have been deleted.

Similarly for the relationship between actions-6-no-annot.p4 and
actions-6-same-name-annot.p4.
