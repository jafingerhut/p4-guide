# Support for if statements in P4_16

I have written this article to record some details about support for
`if` statements on some open source P4 targets, for reference to the
P4 community.


# Versions

All references to the P4_16 language specification in this article are
for version 1.2.4, published in May 2023.

Version of `p4c` source code from repository
https://github.com/p4lang/p4c

```
commit 6cec6b45997e22ef55753dbc7ee2dcab587d46bb (HEAD -> main, origin/main, origin/HEAD)
Author: vbnogueira <105989644+vbnogueira@users.noreply.github.com>
Date:   Wed Feb 7 04:31:58 2024 -0300
```


# `if` statements in the P4_16 language specification

What does the P4_16 language specification have to say on where `if`
statements are allowed?

+ In the body of a control, i.e. inside the braces of `apply { ... }`.
+ In the body of an `action` definition, 
  + [Section 14.1
    "Actions"](https://staging.p4.org/p4-spec/docs/P4-16-v1.2.4.html?_ga=2.249461122.469016943.1708037003-1897260381.1705352543&_gl=1*1eqib7i*_ga*MTg5NzI2MDM4MS4xNzA1MzUyNTQz*_ga_FW0Q4274RH*MTcwODAzNzAwMi4xNS4xLjE3MDgwMzcwMDMuMC4wLjA.*_ga_VXXZD2250K*MTcwODAzNzAwMi4xNS4xLjE3MDgwMzcwMDMuMC4wLjA.#sec-actions)
    says the following about this: "Some targets may impose additional
    restrictions on action bodies—e.g., only allowing straight-line
    code, with no conditional statements or expressions."  That
    statement does _not_ prohibit P4 implementations from supporting
    `if` statements inside of actions.  The statement is there
    primarily to warn P4 developers that some implementations might
    not support conditional statements there.
+ In the body of a parser's `state` definition ([Section 13.4 "Parser
  states"](https://staging.p4.org/p4-spec/docs/P4-16-v1.2.4.html?_ga=2.249461122.469016943.1708037003-1897260381.1705352543&_gl=1*1eqib7i*_ga*MTg5NzI2MDM4MS4xNzA1MzUyNTQz*_ga_FW0Q4274RH*MTcwODAzNzAwMi4xNS4xLjE3MDgwMzcwMDMuMC4wLjA.*_ga_VXXZD2250K*MTcwODAzNzAwMi4xNS4xLjE3MDgwMzcwMDMuMC4wLjA.#sec-parser-state-stmt))
+ In the body of a function definition.


# `if` statements in P4_16 implementations

I only know details for the BMv2 and DPDK back ends.  If someone else
knows details about ebpf or ubpf back ends in p4c, please feel free to
let me know (andy.fingerhut@gmail.com).

Note that simply because a software switch like BMv2 or DPDK has
support for a large variety of `if` statements, does not necessarily
mean that any other P4 target will.  BMv2 and DPDK target general
purpose CPUs, so have available the full power of general purpose CPUs
to do way more than `if` conditions.  I hear crazy stories that
general purpose CPUs can implement loops, too :-)


## BMv2

`p4c-bm2-ss` compiles P4 source code to BMv2 "binaries", where a
"binary" here is really a text file with JSON syntax and a schema that
is specific to BMv2, which I will call "BMv2-JSON".

The BMv2-JSON format has supported conditional jumps since 2017.  See
this commit:

https://github.com/p4lang/behavioral-model/commit/207d2e23db195b51325736334c92827320bb3243

As of 2024-Nov-08, after the PR linked below was merged into the `p4c`
compiler, `p4c-bm2-ss` now supports general `if` conditions within P4
actions!

+ https://github.com/p4lang/p4c/pull/4999

Thus `p4c-bm2-ss` combined with BMv2 has the following support for
`if` statements:

+ Yes in the body of a control.
+ Yes in the body of a parser's `state` definition.
+ Yes in the body of a function definition, if that function is only
  called within the places listed above.
+ Yes in the body of an `action` definition.


## DPDK

`p4c-dpdk` compiles P4 source code to "spec" files, which are text
files that look about half-way between a subset of the P4 language and
a custom-made assembly language.  You can see many examples in the
repository https://github.com/p4lang/p4c in the
`testdata/p4_16_samples_outputs` directory -- look for file names
ending with `.spec`.

In particular, this file shows the output of `p4c-dpdk` compiling the
PNA TCP connection tracking example source program.  It uses
conditional jumps within its "spec" file format for actions to support
general if statements within P4 actions:
https://github.com/p4lang/p4c/blob/main/testdata/p4_16_samples_outputs/pna-example-tcp-connection-tracking.p4.spec#L80-L87

Here is the P4 source file that produced the `spec` file linked
above:
https://github.com/p4lang/p4c/blob/main/testdata/p4_16_samples/pna-example-tcp-connection-tracking.p4#L206-L226
(note that the preprocessor symbol `AVOID_IF_INSIDE_ACTION` was NOT
#define'd on the `p4c-dpdk` compile run that generated the `spec` file
linked above)

See these example P4 programs for examples of supported `if`
statements for the DPDK target.

+ [`demo-if-stmts2.p4`](../demo-if-stmts/demo-if-stmts2.p4)
+ [`demo-if-stmts3.p4`](../demo-if-stmts/demo-if-stmts3.p4)

