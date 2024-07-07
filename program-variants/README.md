# Introduction

This article discusses ways of maintaining a collection of very
similar, but not identical P4 programs.

Some of what is discussed here is relevant to such collections of
programs in other programming languages besides P4.


# Background

In production networks, it is often desired that network devices at
different places within the network process packets somewhat
differently from each other.

For example, in a data center network with a Clos, aka fat tree,
topology, if there are 2 levels of switches, they are often connected
as follows:

+ Every host is attached to exactly one leaf switch (aka top-of-rack
  switch).
+ Every leaf switch is attached to many hosts, and to many spine
  switches.
+ Every spine switch is attached to many leaf switches.
+ Leaf switches have _no_ direct links to any other leaf switch.
+ Spine switches have _no_ direct links to any other spine switches.
+ Every leaf is attached to every spine, and every spine is attached
  to every leaf.

In such a network, packets from a host #1 attached to leaf switch A
destined to a host #2 attached to a different leaf switch B typically
go through 3 switch hops:

+ host #1
+ leaf switch A
+ spine switch S
+ leaf switch B
+ host #2

It is common for the packet processing to be different in leaf switch
A, spine switch S, and leaf switch B.

If the switches are P4-programmable, this difference in packet
processing can be due to the following two reasons, at least (and
perhaps others):

+ The same P4 program is loaded into all switches, but their run-time
  configuration from the control plane causes different paths to be
  executed through the P4 program.
+ Different P4 programs are loaded into leaf switches than those
  loaded into spine switches.

In this article, we will be focusing on the second option.

Call the leaf switch program L and the spine program S.

When L and S are different, it is often the case that L and S have
much more in common with each other than they have differences,
e.g. something like 80% to 90% of the code is identical, but there are
a few lines differing between them.

For example, L and S might both have a table named `ipv4_route`, but
in L it has extra actions for encapsulating a packet in a VXLAN tunnel
header, or decapsulating a packet with a VXLAN tunnel header, but S
has no such actions.

Another example could be that L and S both have a table with the same
name, but one has one or two key fields that the other program does
not.


# Brief description of published example P4 program collection

One published example of this can be found here:

+ https://github.com/sonic-net/sonic-pins/tree/main/sai_p4/instantiations/google

In that directory, the 4 files listed below are the "top level" files
of 4 program variants, each using `#define` of C preprocessor symbols,
and `#include` of some common files that contain `#if`, `#ifdef`, and
`#ifndef` preprocessor conditionals based upon the values of those
preprocessor symbols, which include or omit certain lines of code.

+ `fabric_border_router.p4`
  + `fabric_border_router.p4` is the only source file that defines
    this preprocessor symbol: `#define SAI_INSTANTIATION_FABRIC_BORDER_ROUTER`
+ `middleblock.p4`
  + `middleblock.p4` is the only source file that defines this
    preprocessor symbol: `#define SAI_INSTANTIATION_MIDDLEBLOCK`
+ `tor.p4`
  + `tor.p4` is the only source file that defines this
    preprocessor symbol: `#define SAI_INSTANTIATION_TOR`
+ `wbb.p4`
  + `wbb.p4` is the only source file that defines this
    preprocessor symbol: `#define SAI_INSTANTIATION_WBB`


# Ways to generate one of the variant programs, with preprocessor conditionals resolved

Here is how to generate a `middleblock.p4i` file.  `.p4i` is a file
name suffix used by the open source `p4c` compiler to name generated
files that contain the output of the C preprocessor:

```bash
# Creates files middleblock.p4i and middleblock.json
p4c --target bmv2 --arch v1model middleblock.p4
```

Here is how to generate a pretty-printed version of the intermediate
representation of the `p4c` compiler front end, soon after the C
preprocessor, but before most of the front-end or mid-end processing
of `p4c` has occurred.  `.p4pp` is not a standard suffix -- it is
simply one I have chosen to name files that contain pretty-printed
output from the compiler:

```bash
p4test middleblock.p4 --pp middleblock.p4pp
```

Hopefully in the near future we can try out the `p4fmt` code formatter
tool being developed as a GSoC project, and see whether it might be
useful in preserving comments while letting one generate the code for
only one program variant.

+ https://github.com/p4lang/p4c/pull/4778

Here is a summary of differences between the `.p4i` and `.p4pp` files:

| Kinds of contents | Included in `.p4i` files | Included in `.p4pp` files |
| ----------------- | ------------------------ | ------------------------- |
| Comments | yes | no, except inside of strings like those in `@entry_restriction` annotations |
| C preprocessor `# <linenumber> <filename> <some-number>` output lines | yes | no |
| Contents of standard include files like `core.p4` and `v1model.p4` | yes, but should be easy to write a simple program that removes these using the `#` line contents | no |

Even now, I suspect it would not require many days of hacking for
someone to take the contents of the `.p4i` files, paying special
attention to the C preprocessor output lines beginning with `#`, to
enhance an editor/IDE like Emacs or VScode so that it can display
lines of code differently to indicate whether they are active or
inactive for a particular one of the code variants.


# Using VScode Intellisense to show code in different color if it is #ifdef'd away

For C and C++ code, VScode has a feature that lets you specify a set
of `#define` directives in a configuration file, and it uses those
values to show code that would be removed by the C preprocessor in a
different color.

See [../vscode-preproc-highlighting/README.md](here) for detailed
steps on how to do this for a tiny C program, and then how to do it
for a set of P4 source files, although by a hacky way that requires
renaming the source files first.
