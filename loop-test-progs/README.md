# Introduction

On 2024-May-17, Chris Dodd added an implementation of for loops to
p4c.

This directory contains some P4 programs intended to test the
properties of this implementation.

Here are some short names used in this article for specific versions
of the p4c source code:

+ v1 - p4c git SHA d5df09b77201b87ad9356c45ae2ffdb1c67b35d1 dated 2024-Jun-04
+ v2 - p4c git SHA 32e73964a43941ae10ef5ac1e0dbd3a9d7975ed3 dated 2024-Jun-21
+ v3 - p4c git SHA fd23e565cb4eae51e72a07b04bd9963d4e45c5b2 dated 2024-Aug-03


## Non-error cases


### Is it allowed to modify a loop variable in the loop body?

#### v1, v2, v3

Yes.

```bash
$ mkdir -p tmp
$ p4test --dump tmp --top4 FrontEndLast,FrontEndDump,MidEndLast loop-var-modifiable-in-body1.p4
[ no errors or warnings.  See output file tmp/loop-var-modifiable-in-body1-0003-MidEnd_47_MidEndLast.p4 ]
```

In v1, v2, the output files for `FrontEndLast` and `MidEndLast` appear
incorrect, as they do not update the loop variable `i`.  This was a
bug in the compiler that Chris Dodd fixed via the following PR, before
v3.

+ https://github.com/p4lang/p4c/pull/4783


### Is a loop variable declared before loop in scope after loop body?

#### v1, v2, v3

Yes.  Good!

```bash
$ p4test --dump tmp --top4 FrontEndLast,FrontEndDump,MidEndLast loop-var-can-be-declared-before-loop1.p4
[ no errors or warnings.  See output file tmp/loop-var-can-be-declared-before-loop1-0003-MidEnd_47_MidEndLast.p4 ]
```

The `MidEndLast` file looks correct to me, but not as optimized as it
could be, e.g. it contains dead assignments to `n_0` overwritten by
immediately-following assignments, and lots of constant folding
undone.


### Compiler supports initialization and expressions with non-constant values

#### v1, v2, v3

Yes.  Good!

```bash
$ mkdir -p tmp
$ p4test --dump tmp --top4 FrontEndLast,FrontEndDump,MidEndLast loop-var-exprs-not-constant1.p4
[ no errors or warnings, and MidEnd output file looks correct. ]
```


### Compiler supports multiple initializations in a 3-clause for loop

#### v1, v2, v3

Yes.  Good!

```bash
$ mkdir -p tmp
$ p4test --dump tmp --top4 FrontEndLast,FrontEndDump,MidEndLast loop-vars-multiple-in-initializer1.p4
[ no errors or warnings, and MidEnd output file looks correct. ]
```


## Error cases


### Can const identifiers be used as slice indexes?

#### v3

```bash
$ mkdir -p tmp
$ p4test --dump tmp --top4 FrontEndLast,FrontEndDump,MidEndLast err-const-is-not-compile-time-known-value1.p4
err-const-is-not-compile-time-known-value1.p4(57): [--Werror=type-error] error: i: slice bit index values must be constants
            n[i:i] = 1;
              ^
```

I will ask the P4 language design work group if this is a program that
_should_ compile.  It seems to me like it should.


### Can loop variables be used as slice indexes?

#### v1, v2, v3

No.

```bash
$ mkdir -p tmp
$ p4test --dump tmp --top4 FrontEndLast,FrontEndDump,MidEndLast err-loop-var-cannot-be-used-in-slice1.p4
err-loop-var-cannot-be-used-in-slice1.p4(50): [--Werror=type-error] error: i: slice bit index values must be constants
            hdr.ethernet.srcAddr[i:i] = i[0:0];
                                 ^
```


### Can variables be used as slice indexes, at all?

#### v3

```bash
$ mkdir -p tmp
$ p4test --dump tmp --top4 FrontEndLast,FrontEndDump,MidEndLast err-var-is-not-compile-time-known-value1.p4
err-var-is-not-compile-time-known-value1.p4(75): [--Werror=type-error] error: i: slice bit index values must be constants
            n[i:i] = 1;
              ^
```

This issue asks whether variables should ever be considered
compile-time known values.  I would guess the answer will remain "no":

+ https://github.com/p4lang/p4-spec/issues/1291


### Is a loop variable with type declared in initialization clause in scope after loop body?

#### v1, v2, v3

No.  Good!

```bash
$ mkdir -p tmp
$ p4test --dump tmp --top4 FrontEndLast,FrontEndDump,MidEndLast err-loop-var-not-in-scope-outside-of-loop1.p4
err-loop-var-not-in-scope-outside-of-loop1.p4(53): [--Werror=not-found] error: i: declaration not found
        hdr.ethernet.srcAddr[7:0] = i;
                                    ^
```


### Is it allowed to have a for-in-range loop without a type declaration on the loop variable?

#### v3

No.  This was permitted in v1 and v2 implementations, but at 2024-Jul LDWG
meeting it was recommended that this be a compile-time error, and during
2024-Jul Chris Dodd modified p4c implementation so it is an error now.

There is an open issue for p4c as of 2024-Aug-03 to improve the compiler error message
for such programs:

+ https://github.com/p4lang/p4c/issues/4813

```bash
$ mkdir -p tmp
$ p4test --dump tmp --top4 FrontEndLast,FrontEndDump,MidEndLast err-loop-var-in-range-no-typeref1.p4
err-loop-var-in-range-no-typeref1.p4(51):syntax error, unexpected IN
        for (i in
               ^^
```
