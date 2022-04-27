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

+ https://github.com/p4lang/p4c/issues/1936 Odd behavior with same-named actions (I have since closed this issue, but included its test programs in this directory.  It appears to me this issue is fixed now.)
+ https://github.com/p4lang/p4c/issues/1949 Compiler silently allows duplicate name annotations
+ https://github.com/p4lang/p4c/issues/2716 Is this the intended effect of @name annotations when generating P4Info files?
+ https://github.com/p4lang/p4c/issues/2749 Control-plane name clash introduced by LocalizeAllActions and RemoveActionParameters
+ https://github.com/p4lang/p4c/issues/2755 Incorrect P4Info generation when different actions have same name annotation

No, it is not a coincidence that I wrote this article, and created
most of these issues.  It is something that has bothered me for a
while, off and on over time. :-)


# Brief notes on some of the P4 programs

See the README files in the sub-directories for more details.

actions-1-same-name.p4 has only cosmetic changes from the program
actions-same-name1.p4 in the ZIP file issue1936.zip attached to [p4c
issue 1936](https://github.com/p4lang/p4c/issues/1936).

Similarly, actions-2-same-name.p4 has only cosmetic changes from the
program actions-same-name2.p4 in that same ZIP file.

issue-1949.p4 has only cosmetic changes from the program
issue1949.p4.txt attached to a comment on [p4c issue
1949](https://github.com/p4lang/p4c/issues/1949).

actions-5-same-name-annot.p4 has only cosmetic changes from the
program actions-same-name5.p4 in the ZIP file attached to [p4c issue
2755](https://github.com/p4lang/p4c/issues/2755).

Similarly, actions-6-same-name-annot.p4 has only cosmetic changes from
the program actions-same-name6.p4 in that same ZIP file.

actions-5-no-annot.p4 is identical to actions-5-same-name-annot.p4,
except the `@name` annotations have been deleted.

Similarly for the relationship between actions-6-no-annot.p4 and
actions-6-same-name-annot.p4.

actions-7-annot-same-as-action-name.p4 is a minor variation of
actions-5-same-name-annot.p4 that I wrote on 2022-Jan-19, and to my
knowledge is not attached to any p4c Github issue.


# Behavior with at least some current P4 compilers

So far I have only detailed the behavior of this code with one version
of p4c when compiling with p4test, and/or for the BMv2 target with
v1model architecture.  See [this README](v1model/README.md) for
detailed analysis of the results.


# One potential way to fix the root cause of some of these issues

As of 2022-Jan-19 and before, p4c can, before the step where the
P4Info file is generated, take one action in the P4 source code and
duplicate it into two or more, both with the same string on their
`@name` annotation.  I personally think that this is the root cause of
the problem, and what we should change in p4c in order to fix most or
all of these issues.

For example, if the compiler had these steps in this order, I think
most or all of these issues should be corrected:

+ NO pass of the compiler before control plane API generation is
  allowed to create new tables or actions from existing ones, except
  via the compile-time instantiation rules in the P4 language
  specification.  Nor is any such pass allowed to add `@name`
  annotations that the user did not write in their original code.
+ There should be some code in the compiler, either just before the
  control plane API generation step, or it could be long before, that
  gives an error if more than one action has the same `@name`
  annotation (or the same table, or in general any two things that
  need different names to identify them separately).
  + Because of the previous bullet item, all of these checks will be
    done using `@name` annotations written by the developer, not ones
    created by the compiler.
+ Only _after_ control plane API generation is complete, the compiler
  is allowed to create duplicate actions from actions in the original
  program, e.g. if the desire is to optimize them separately.  Back
  end compiler code that generates target-specific files or code for
  implementing the control plane API must in such a case be able to
  map a single action name in the P4Info file to the correct one of
  these duplicates.  It is an exercise for the target-specific control
  plane software to ensure this is done correctly.
  + Making such distinctions MIGHT be easier, and/or barely possible,
    only if such a compiler pass somehow puts some kind of unique
    identifier on each copy it makes of such actions.

Nothing in p4c should assume that the control plane API will use
(table name, action name) pairs to disambiguate action names.  A
control plane API implementer might choose to do that, but p4c should
not require it.

Rationale: The P4Runtime API in all of its released versions requires
all action names in the control plane API to be unique, regardless of
which table can invoke those actions.  For example, if an action named
`foo` is possible to be the action of an entry in table `t1`, and also
in table `t2`, action `foo` will only be represented by a single
object in the P4Info file.
