# Introduction

This directory contains some documents exploring P4_16 language design
questions regarding the idea of adding "overlays" to the language, as
introduced in [this pull
request](https://github.com/p4lang/p4-spec/pull/656).


## Overlay Syntax

At the time of writing this section (2019-Mar-31), the proposed syntax
for creating an overlay is of this form:

```
<type_specifier> <alias_name> = <call_to_overlay_function> (<parameters>);
```

Here is a more fleshed out code snippet:

```
// code block (A)

struct T1_t {
    bit<4> a;
}

T1_t reverseBitsOF (T1_t p1) {
    a[3:3] = p1.a[0:0];
    a[2:2] = p1.a[1:1];
    a[1:1] = p1.a[2:2];
    a[0:0] = p1.a[3:3];
}

T1_t storage1;
T1_t alias1 = reverseBitsOF(storage1);
```

My main point here is that this syntax looks very much like similar
existing constructs in the P4_16 language, _but it introduces a
completely different semantics for them_.

I believe that everywhere in the P4_16 language before the overlay
proposal, the syntax `lhs = expression;` meant "calculate the value of
the expression on the right hand side, then write that value into the
place named on the left hand side".

In these two lines of code:

```
// code block (B)
bit<10> foo
foo = 10;
```

The first line means "make a new place where values of type `bit<10>`
can be stored, and give it the name `foo`".  That same meaning applies
if you replace the type `bit<10>` with any other P4_16 type.

The second line means "calculate the value of the expression `10`,
then write its value into the place named `foo`".

The following line of code can be considered as an abbreviation of the
two above:

```
// code block (C)
bit<10> foo = 10;
```

The meaning is the same as the meaning of the two lines of code above,
as well.

Now let us go back to the proposed syntax for creating an overlay:

```
// code block (D)
T1_t alias1 = reverseBitsOF(storage1);
```

According to the latest proposal, that line _does not_ mean the same
thing as the two lines below, because the second of the two lines
below is not allowed by the proposal:

```
// code block (E)
// Note: Not syntacitcally legal code, according to the proposal.
T1_t alias1;
alias1 = reverseBitsOF(storage1);
```

Also, the meaning of the definition of `alias1` in code block (D) is
_not_ "make a new place where values of type `T1_t` can be stored, and
give it the name `alias`".  It does not even include that as part of
its meaning.  That line of code _does not make a new place_ at all.
It makes a new name for an _already existing_ collection of places.

The meaning of `=` in that line is _not_ evaluate the value of the
expression on the right hand side, and write its value into the place
named by the left hand side.  Basically the entire line has one
meaning that cannot be divided up into two steps the way that `bit<10>
foo = 10;` can.

I would describe the meaning of the line in code block (D) as "take
the collection of places implied by the expression
`reverseBitsOF(storage1)` and give them a new name `alias1`".

If that is the correct meaning, then this overlay proposal is
currently giving an entirely new and different meaning for `=` that
does not exist in the P4_16 language today.  It seems to me that it
would be better to avoid creating such a new meaning for `=`.

If we want to avoid creating a new meaning for `=`, one way would be
to change the proposed syntax for creating an overlay.  Here are some
possibilities:

```
// Current proposed syntax:
struct T1_t {
    bit<4> a;
}

T1_t reverseBitsOF (T1_t p1) {
    a[3:3] = p1.a[0:0];
    a[2:2] = p1.a[1:1];
    a[1:1] = p1.a[2:2];
    a[0:0] = p1.a[3:3];
}

T1_t alias1 = reverseBitsOF(storage1);

// Alternate syntax 1: Introduces a new reserved word "overlays" into
// the language.
T1_t reverseBitsOF (T1_t p1) {
    a[3:3] overlays p1.a[0:0];
    a[2:2] overlays p1.a[1:1];
    a[1:1] overlays p1.a[2:2];
    a[0:0] overlays p1.a[3:3];
}
T1_t alias1 overlays reverseBitsOF(storage1);
```

I would not be surprised if there are other ideas for syntax that may
be even better.

Why do I think it could be a bad idea to use the current proposed
syntax?

In slide 3 of [this set of
slides](https://github.com/p4lang/p4c/files/2928911/recirculate.pdf)
discussing why the v1model architecture `recirculate` primitive does
not work, and what might be done to fix it, it points out that this
code:

```
// code block (F)
recirculate(a);
```

is equivalent to:

```
// code block (G)
b = a;
recirculate(b);
```

I agree that code block (G) is equivalent to (F) if the parameter to
`recirculate` has direction `in`.  However, if the parameter is
direction `out` or `inout`, then I am nearly certain that it is _not_
equivalent in general, because (G) does not make changes to `a` that
(F) does.  See any follow up discussion on [this Github
comment](https://github.com/p4lang/p4c/pull/1698#issuecomment-478326980)
for confirmation.


## Maybe surprising thing that overlays can do

Consider this code, using the current proposed syntax to define an
overlay:

```
// code block (A)

struct T1_t {
    bit<4> a;
}

T1_t reverseBitsOF (T1_t p1) {
    a[3:3] = p1.a[0:0];
    a[2:2] = p1.a[1:1];
    a[1:1] = p1.a[2:2];
    a[0:0] = p1.a[3:3];
}

T1_t storage1;
T1_t alias1 = reverseBitsOF(storage1);
```

Given that setup in the code, if the program now performs this
assignment:

```
// code block (B)
alias1 = storage1;
```

it would have the effect of reversing the four bits of `storage1`.  Is
that correct?

If so, note that overlays in general would allow you to define an
arbitrary permutation of the bits of one or more `bit<W>` values.  I
am not claiming that this would necessarily be efficiently
implementable on all targets, merely that it could be done using this
kind of overlay.  Even without using an overlay, it could be done
using an appropriate `control` or function definition.

If my belief is correct on the effect of that code above, note that it
would be incorrect for the compiler to make this transformation of the
code:

```
// transforming this:
// code block (C)
alias1 = storage1;

// into this would be incorrect, because the effect is different:
// code block (D)
storage1.a[3:3] = storage1.a[0:0];
storage1.a[2:2] = storage1.a[1:1];
storage1.a[1:1] = storage1.a[2:2];
storage1.a[0:0] = storage1.a[3:3];

// It would be correct to have a transformation with an intermediate
// compiler-generated temporary value of type T1_t, like this:
// code block (E)
T1_t compiler_tmp1 = storage1;
storage1.a[3:3] = compiler_tmp1.a[0:0];
storage1.a[2:2] = compiler_tmp1.a[1:1];
storage1.a[1:1] = compiler_tmp1.a[2:2];
storage1.a[0:0] = compiler_tmp1.a[3:3];
```

Also note that the following assignment would have the same effect as
code block (B) above:

```
// code block (F)
storage1 = alias1;
```
