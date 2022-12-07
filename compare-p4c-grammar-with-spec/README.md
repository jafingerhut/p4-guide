# Introduction

It is a somewhat laborious manual process to compare the P4_16 grammar
in the file
[`grammar.mdk`](https://github.com/p4lang/p4-spec/blob/main/p4-16/spec/grammar.mdk)
of the [p4-spec repository](https://github.com/p4lang/p4-spec) to the
file
[`p4parser.ypp`](https://github.com/p4lang/p4c/blob/main/frontends/parsers/p4/p4parser.ypp)
of the [p4c repository](https://github.com/p4lang/p4c).

What if we could make it easier?

One way is to modify `grammar.mdk` so that it becomes closer to
`p4parser.ypp`, and then write a simple program that removes the C++
code in braces in the file `p4parser.ypp`.  Then the resulting files
become much more similar, and easy to compare with tools like tkdiff
or emacs ediff.


## Changes to `grammar.mdk` file

This directory shows several variations of the file `grammar.mdk` in a
step-by-step transformation.


### The original `grammar.mdk` file

The file `grammmar.orig.mdk` is from this commit of the p4-spec
repository, unchanged:

```
commit afbaae184a5293d3b1352ff70d1f93edf144799f
Merge: cb30110 531bbef
Author: Mihai Budiu <mbudiu@vmware.com>
```


### Reorder some definitions

The file `grammar.step1.mdk` is the same as the original, except
some of the non-terminals are defined in a different order, and some
of the alternatives in the definitions of some non-terminals are
given in a different order.  None of these change the meaning of the
grammar, though.


### Replace all single quotes with double quotes

The file `grammar.step2.mdk` was produced by simply globally replacing
all single quote characters in `grammar.step1.mdk` with double quote
characters, since double quote characters are used consistently in the
`p4parser.ypp` version.


### Replace several other miscellaneous differences

The file `grammar.step3.mdk` file was created from `grammar.step2.mdk`
by making these small changes:

+ Replace `UNKNOWN_TOKEN` with `UNEXPECTED_TOKEN` (1 ooccurrence)
+ Replace `MASK` with `"&&&"` (1 occurrence)
+ Replace `RANGE` with `".."` (1 occurrence)
+ Replace `DONTCARE` with `"_"` (5 occurrences)
+ Add an alternative `THIS` to the definition of the non-terminal
  symbol `annotationToken`.
+ Change a couple of one-line comments to be the same as in
  `p4parser.ypp`.


### Add definition of `optCONST` non-terminal and use it

This change is very small, and probably best explained with the output
of the diff between the step3 and step4 files:

```bash
$ diff grammar.step3.mdk grammar.step4.mdk
44a45,49
> optCONST
>     : /* empty */
>     | CONST
>     ;
> 
648,650c653,654
<     | optAnnotations CONST ENTRIES "=" "{" entriesList "}" /* immutable entries */
<     | optAnnotations CONST nonTableKwName "=" initializer ";"
<     | optAnnotations nonTableKwName "=" initializer ";"
---
>     | optAnnotations optCONST ENTRIES "=" "{" entriesList "}" /* immutable entries */
>     | optAnnotations optCONST nonTableKwName "=" initializer ";"
```


## Changes to `p4parser.ypp` file


### The original `p4parser.ypp` file

The file `p4parser.orig.ypp` is from this commit of the p4c
repository, unchanged:

```
commit 0b2a555f856370362e63d8e7ea187cc56a037489
Author: Fabian Ruffy <fabian.ruffy@intel.com>
Date:   Wed Dec 7 20:33:49 2022 +0100
```


### Remove C++ code from Bison grammar

The file `p4parser.trimmed.ypp` was produced from a simple Python
program as follows:

```bash
./trim-p4c-p4parser-file.py p4parser.orig.ypp > p4parser.trimmed.ypp
```
