# Introduction

On 2024-May-17, Chris Dodd added an implementation of for loops to
p4c.

This directory contains some P4 programs intended to test the
properties of this implementation.

Here are some short names used in this article for specific versions
of the p4c source code:

+ v1 - p4c git SHA d5df09b77201b87ad9356c45ae2ffdb1c67b35d1 dated 2024-Jun-04


## Can loop variables be used as slice indexes?

### v1

No.

```bash
$ p4c --target bmv2 --arch v1model loop-var-can-be-used-in-slice1.p4 
loop-var-can-be-used-in-slice1.p4(50): [--Werror=type-error] error: i: slice bit index values must be constants
            hdr.ethernet.srcAddr[i:i] = i[0:0];
                                 ^
```


## Is it allowed to modify a loop variable in the loop body?

### v1

Yes.

```bash
$ mkdir -p tmp
$ p4test --dump tmp --top4 FrontEndLast,FrontEndDump,MidEndLast loop-var-modifiable-in-body1.p4
[ no errors or warnings.  See output file tmp/loop-var-modifiable-in-body1-0003-MidEnd_47_MidEndLast.p4 ]
```

TODO: The output files for `FrontEndLast` and `MidEndLast` appear
incorrect, as they do not update the loop variable `i`.  Compiler bug?


## Is a loop variable with type declared in initialization clause in scope after loop body?

### v1

No.  Good!

```bash
$ mkdir -p tmp
$ p4test --dump tmp --top4 FrontEndLast,FrontEndDump,MidEndLast loop-var-in-scope-outside-of-loop1.p4
loop-var-in-scope-outside-of-loop1.p4(53): [--Werror=not-found] error: i: declaration not found
        hdr.ethernet.srcAddr[7:0] = i;
                                    ^
```


## Is a loop variable declared before loop in scope after loop body?

### v1

Yes.  Good!

```bash
$ p4test --dump tmp --top4 FrontEndLast,FrontEndDump,MidEndLast loop-var-can-be-declared-before-loop1.p4
[ no errors or warnings.  See output file tmp/loop-var-can-be-declared-before-loop1-0003-MidEnd_47_MidEndLast.p4 ]
```

The `MidEndLast` file looks correct to me, but not as optimized as it
could be, e.g. it contains dead assignments to `n_0` overwritten by
immediately-following assignments, and lots of constant folding
undone.
