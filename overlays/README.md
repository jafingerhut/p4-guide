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

Here is a more fleshed out block of code:

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


## "Stacking" overlays, and determining whether an overlay alias can be an L-value

If overlays can "stack" on top of each other, that seems to make it
more subtle for a human to determine whether the overlay makes
multiple aliases of "original storage bits", and thus whether the
alias can be used as an L-value or not.  It appears to me that it
should be straightforward for the compiler to determine this.

```
// code block (A)
T1 x = myOverlayFunction(param1, param2, ...);
```

Terminology:

`x` is an "alias".  It does not have its own separate storage.  It is
another name for storage bits that were already allocated before the
statement above occurred.

`myOverlayFunction` is an overlay "function", or OF for short.

`param1` and `param2` are OF parameters.  In the simplest case where
there is no stacking, they are always names of storage bits,
i.e. ordinary P4 variables.

So now all names are either names of ordinary variables, i.e. storage
bits, or they are aliases.

A non-stacked alias can be represented as a graph, with one node for
each bit of the alias, and another node for each storage bit.

Every alias node has one out-edge that leads to the storage bit for
which it is an alias.

The out-degree of every alias node is always 1.

The in-degree of a storage bit can be 0 if the overlay does not refer
to it at all, 1 if it is aliased by only one alias bit, or more than
one if it is aliased by multiple alias bits.

According to the current overlay proposal, the in-degree of storage
bits can be more than one, but if this is true for an OF, then the
aliases created using that OF cannot be used as L-values.

Reason: If different values were assigned to different aliases of the
same original storage bit, we would need to define some rule for which
of several bit values would be written to the storage bit.  Or, we
could say that the final value of the storage bit was unspecified
after such an assignment.  Either way, it seems confusing to allow
such an alias as an L-value.

If for a single OF the in-degree of all storage bits is at most one,
then aliases created by that OF can be used as L-values.  It is
well-defined what should be written into each storage bit when a value
is assigned to the alias.

Now, suppose we also allow the seemingly reasonable flexibility that
the same OF, or multiple different OFs, can be called on the same
original storage bits, and each creates its own alias.  Thus a storage
bit can have an in-degree more than one not because a single OF causes
it, but because across multiple aliases, the storage bit has multiple
aliases.  Disallowing this would seem to prevent the
multiple-field-lists-chosen-by-hash-extern proposal of Calin and
Antonin.  See the heading "2. Overlays" in [this Github
comment](https://github.com/p4lang/p4-spec/issues/744#issuecomment-473160745).

Even so, as long as OFs cannot stack on top of each other, we can look
at the definition of a single OF and know whether aliases created by
it can be L-values or not.

Now suppose we generalize things a bit more, and allow OFs to take
_alias names_ as parameters.

Now the aliasing graphs can have alias bit nodes that have out-edges
leading to other alias bit nodes.  For each alias bit node, there is a
unique path following out-edges only that eventually leads to a single
storage bit node.  The path lengths are always exactly one without
stacking, but can be length two or more if stacking is allowed.

Furthermore, even if no individual OF causes in-degree larger than one
to a storage bit node, a stack could.

Example:

```
// code block (B)

struct T1_t {
    bit<1> a;
    bit<1> b;
    bit<1> c;
}

struct T2_t {
    bit<1> p;
    bit<1> q;
}

struct T3_t {
    bit<1> i;
    bit<1> j;
    bit<1> k;
    bit<1> l;
}

T2_t MyOF1 (T1_t p1) {
    p = p1.a;
    q = p1.b;
}

T2_t MyOF2 (T1_t p1) {
    p = p1.b;
    q = p1.c;
}

T3_t MyOF3 (T2_t p1, T2_t p2) {
    i = p1.p;
    j = p1.q;
    k = p2.p;
    l = p2.q;
}

T1_t storage1;
T2_t alias1 = MyOF1(storage1);
T2_t alias2 = MyOF2(storage1);
T3_t alias3 = MyOF3(alias1, alias2);
```

The alias graph looks like this:

```
    alias3.i ----> alias1.p ----> storage1.a

    alias3.j ----> alias1.q ----> storage1.b
                              /
    alias3.k ----> alias2.p --

    alias3.l ----> alias2.q ----> storage1.c
```

Each individual OF by itself cannot create multiple aliases for the
same storage bit.  But in combination, with stacking allowed, they
can.


## 
