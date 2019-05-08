# Operations on header stacks in P4_14, P4_16, and bmv2

Versions of things referred to in this document:

+ P4_14 is the P4_14 v1.0.4 specification.
+ P4_16 is the P4_16 v1.0.0 specification.
+ bmv2 is the version of the simple_switch executable created from
  following the build instructions for the Github repository
  https://github.com/p4lang/behavioral-model as of 2017-Sep-18.

Definition of some terms used here:

`size` is the compile-time constant number of elements that a header
stack is defined with.  This is called `size` in the bmv2 code and the
P4_16 spec.

`nextIndex` is the run-time value that is initialized to 0 for each
header stack instance when a packet begins parsing.  It is incremented
when the parser extracts into the "next" element of the header stack.
This is called `next` in the bmv2 code, and `nextIndex` in the P4_16
spec.

I will use "top" or "front" to refer to the minimum index in a header
stack, i.e. index 0.

I will use "bottom" or "end" to refer to the point just after the
maximum index in a header stack that contains a valid header.


## Resolution of the issues

This section was written on 2019-May-07, at least a year after all of
the issues have been discussed in the P4 language design working
group, and resolved.  I wanted to record those decisions here.
You can also find a summary of changes made in [this Github
comment](https://github.com/p4lang/p4-spec/issues/284#issuecomment-364785580).

The P4_14 language specification, version 1.0.5, contains several
small changes from version 1.0.4 regarding the behavior of operations
on header stacks.

The working group decided to go with the "P4_16 v1.0.0 is right"
approach described below.  `push` operations in P4_14 still create
valid headers at the smallest index(es) of the header stack array, for
backwards compatibility with existing P4_14 programs that expected
this behavior, whereas in P4_16 it creates invalid headers at the
smallest index(es) of the array.

The bmv2 implementation was also updated to shift the entire header
stack array for `push` and `pop` operations for both P4_14 and P4_16
programs, not only the ones in indices from 0 up through
`[nextIndex-1]`.

`add_header` and `remove_header` in P4_14 v1.0.5 do not cause any
"shifting" of other header stack elements at all, just as they do not
in P4_16.


## Related Github issues

+ https://github.com/p4lang/behavioral-model/issues/111
+ https://github.com/p4lang/p4-spec/issues/284
+ https://github.com/p4lang/p4-spec/issues/431


## Are holes allowed in header stacks?

By a "hole" I mean an invalid element in a header stack, where there
is at least one valid element with a larger index.

The P4_16 spec says this is supported in Section 8.15 "Operations on
header stacks": "The valid elements of a header stack need not be
contiguous."

I do not know whether the P4_14 spec has anything to say about this
topic.

The bmv2 implementation definitely allows sequences of operations that
can create holes.  Examples:

+ `extract(header_stack_instance[1])` done in the parser, without
  first extracting into element 0.
+ Even if the parser ends without holes in a header stack, one can be
  created by doing `remove_header(header_stack_instance[j])` on a
  header stack when a larger-numbered element is valid, or
  `add_header(header_stack_instance[j])` on a header stack when a
  smaller-numbered element is invalid.


## extract to next element in header stack

    P4_14 extract(<header_stack>[next]);
    P4_16 <packet_in>.extract(<header_stack>.next);

In P4_16 this is defined to increment the value of
`<header_stack>.nextIndex`.


## Accessing the last extracted element in a header stack during parsing

    P4_14 latest.<field_name>
    P4_16 <header_stack>.last.<field_name>


## extract to arbitrary specified element in header stack

    P4_14 extract(<header_stack>[1]);
    P4_16 extract(<header_stack>[1]);

TBD: Is this ever mentioned as supported in P4_14 or P4_16 specs?
bmv2 seems to support them, at least in a way that does not cause
`nextIndex` to be read or modified, and that can create holes, or
elements to be valid that are at indices greater than or equal to
`nextIndex`.


## push and pop on header stacks

    P4_14 push(<header_stack>, <count>)
    P4_16 <header_stack>.push_front(<count>)

Both of the above are compiled by p4c-bm2-ss to the bmv2 JSON
primitive called `push`.

    P4_14 pop(<header_stack>, <count>)
    P4_16 <header_stack>.pop_front(<count>)

Both of the above are compiled by p4c-bm2-ss to the bmv2 JSON
primitive called `pop`.

bmv2 JSON primitive `push` is implemented as method
`push::operator()`, and `pop` as method `pop::operator()`.

```C++
// Excerpt from source file in https://github.com/p4lang/behavioral-model
// src/bm_sim/core/primitives.cpp

void
push::operator ()(StackIface &stack, const Data &num) {
  stack.push_front(num.get<size_t>());
}

void
pop::operator ()(StackIface &stack, const Data &num) {
  stack.pop_front(num.get<size_t>());
}
```

The implementations of `stack.push_front()` and `stack.pop_front()`
are the ones in the file below, confirmed by adding my own debug print
statements to the methods below, running a sample P4_14 program that
used `push` and `pop` primitives, and observing my debug print
statements executing.

```C++
// Excerpts from source file in https://github.com/p4lang/behavioral-model
// src/bm_sim/stacks.cpp

template <typename T>
size_t
Stack<T>::push_front(size_t num) {
  if (num == 0) return 0;
  next = std::min(elements.size(), next + num);
  for (size_t i = next - 1; i > num - 1; i--) {
    elements[i].get().swap_values(&elements[i - num].get());
  }
  size_t pushed = std::min(elements.size(), num);
  for (size_t i = 0; i < pushed; i++) {
    elements[i].get().mark_valid();
  }
  return pushed;
}

// earlier in the same source file ...

template <typename T>
size_t
Stack<T>::pop_front(size_t num) {
  if (num == 0) return 0;
  size_t popped = std::min(next, num);
  next -= popped;
  for (size_t i = 0; i < next; i++) {
    elements[i].get().swap_values(&elements[i + num].get());
  }
  for (size_t i = next; i < next + popped; i++) {
    elements[i].get().mark_invalid();
  }
  return popped;
}
```

In P4_16, both `push_front` and `pop_front` are defined explicitly as
modifying the entire header stack from elements 0 through size-1,
inclusive, and modifying the value of nextIndex in all but edge cases.

The bmv2 implementation of `push` differs from the P4_16 spec
`push_front` in at least the following ways:

(1) The bmv2 implementation only 'shifts' the elements in the range
    [0, nextIndex-1] later in the array.  The P4_16 spec says that all
    elements are shifted later, regardless of the value of nextIndex.
    It is not clear to me whether the P4_14 spec is explicit about
    which of these was intended, if either of them were.  It simply
    says "Existing elements will be shifted by `count`."

(2) The P4_16 spec says that the new elements in range [0, count-1]
    will be made invalid.  bmv2 makes them valid.  This matches what
    the P4_14 spec says for the `push` primitive.  In P4_16, it would
    not be well defined to make them valid if the elements of the
    header stack are a `header_union` type, because one must pick a
    particular member of a union to make valid.

The bmv2 implementation of `pop` differs from the P4_16 spec
`pop_front` similarly to number (1) above.  Again, it isn't extremely
clear in the P4_14 description of `pop` what is intended here.


## add_header and remove_header on header stacks

    P4_14 add_header(<header_instance>)
    P4_16 <header_instance>.setValid()

Both of the above are compiled by p4c-bm2-ss to the bmv2 JSON
primitive called `add_header`.

    P4_14 remove_header(<header_instance>)
    P4_16 <header_instance>.setInvalid()

Both of the above are compiled by p4c-bm2-ss to the bmv2 JSON
primitive called `remove_header`.

bmv2 JSON primitive `add_header` is implemented as method
`add_header::operator()`, and `remove_header` as method
`remove_header::operator()`.

```C++
// Excerpts from source file in https://github.com/p4lang/behavioral-model
// targets/simple_switch/primitives.cpp

class add_header : public ActionPrimitive<Header &> {
  void operator ()(Header &hdr) {
    // TODO(antonin): reset header to 0?
    if (!hdr.is_valid()) {
      hdr.reset();
      hdr.mark_valid();
      // updated the length packet register (register 0)
      auto &packet = get_packet();
      packet.set_register(0, packet.get_register(0) + hdr.get_nbytes_packet());
    }
  }
};

class remove_header : public ActionPrimitive<Header &> {
  void operator ()(Header &hdr) {
    if (hdr.is_valid()) {
      // updated the length packet register (register 0)
      auto &packet = get_packet();
      packet.set_register(0, packet.get_register(0) - hdr.get_nbytes_packet());
      hdr.mark_invalid();
    }
  }
};
```

Here is an excerpt from the P4_14 spec for the behavior of the
`add_header` primitive, when applied to an element in a header stack:

    "If `header_instance` is an element in a header stack, the effect
    is to push a new header into the stack at the indicated location.
    Any existing valid instances from the given index or higher are
    copied to the next higher index.  The given instance is set to
    valid.  If the array is fully populated when this operation is
    executed, then no change is made to the Parsed Representation."

And here is the corresponding P4_14 spec excerpt describing the
behavior of the `remove_header` primitive when applied to an element
in a header stack:

    "If the `header_instance` is an element in a header stack, the
    effect is to pop the indicated element from the stack.  Any valid
    instances in the stack at higher indices are copied to the next
    lower index."

bmv2 does _not_ implement the P4_14 spec behavior in these cases.

bmv2 `add_header` makes the specified element of the header stack
valid, but does not shift any other header stack elements around.
Similarly bmv2 `remove_header` makes the specified element of the
header stack invalid, with no changes made to other header stack
elements.

For test cases to verify this, see: TBD Andy's VPP_P4
ipv4-hdr-stack.p4_14.p4


## copy_header on entire header stacks

    P4_14 copy_header(<dest_header_stack>, <src_header_stack>)
    P4_16 assignment statement: dest_header_stack = src_header_stack

TBD: Both of the above are compiled by p4c-bm2-ss to the bmv2 JSON
primitive called `copy_header`.

TBD: The P4_14 spec does not seem to explicitly allow `copy_header`
arguments that are entire header stack instances.

P4_16 spec says yes in Section 8.15 "Operations on header stacks":
"assignment from a header stack `hs` into another stack requires the
stacks to have the same types and sizes.  All components of `hs` are
copied, including its elements and their validity bits, as well as
`nextIndex`."

TBD: I am assuming by "its elements" it means all elements in the
range 0 through size-1, inclusive, regardless of the value of
nextIndex.  That could be made slightly more explicit that it _does
not_ mean only elements 0 through nextIndex-1, inclusive.

bmv2 JSON primitive copy_header is implemented in:
    behavioral-model/targets/simple_switch/primitives.cpp
    class copy_header operator ()

Basically it just calls bm::core::assign_header:
```C++
class copy_header : public ActionPrimitive<Header &, const Header &> {
  void operator ()(Header &dst, const Header &src) {
    bm::core::assign_header()(dst, src);
  }
};
```


## emit on header stacks

TBD: I haven't yet tracked down the code that implements emit on
header stacks in bmv2, but from some experiments it appears to do
this:

```
for (i = 0; i < header_stack_instance.size; i++) {
    emit(header_stack_instance[i]);
}
```

That is, regardless of the value of `nextIndex`, and whether holes
exist or not, emit all valid headers in elements 0 through size-1,
inclusive.

If this is the intended behavior of the P4_16 spec, it would be best
to edit the P4_16 spec to explicitly state so, to avoid someone
mistakenly implementing it only over the range 0 through
`nextIndex-1`.


## Intended use of header stacks

These are guesses made by me, Andy Fingerhut, after reading the
relevant parts of the specs and looking at the bmv2 implementation
code.

One reasonable way to use a header stack is to maintain the
"no-holes" invariant:

    No-holes invariant: indices 0 through nextIndex-1 are all valid,
    and the indices nextIndex through size-1 are all invalid.

In P4_14, it appears that perhaps it may have been intended that the
no-holes invariant holds for all header stacks, at all times.  This
invariant can be maintained if a P4_14 program restricts itself to the
following operations on header stacks:

During parsing, only do `extract(<header_stack>[next])` operations for
modification, never `extract(<header_stack>[3])` (or any other
constant value in place of the 3 in that example).

It is also allowed to read the last-extracted header via the
expression `latest`, but this never modifies any state.

During ingress/egress control blocks, only do the operations:

+ `push(<header_stack>, <count>)`
+ `pop(<header_stack>, <count>)`

In P4_14, the push operation is specified to make the first new
`<count>` headers pushed onto the top of the stack valid, with all
fields other than the valid bit initialized to 0.  Thus it maintains
the no-holes invariant.

As additional evidence that at least some P4 developers consider the
no-holes invariant to be important in P4_14, the bmv2 implementation
of push and pop only "shift" entries that are originally in the range
0 through nextIndex-1, apparently assuming that all entries in the
range nextIndex through size-1 were invalid before the operation (and
if that was true before the operation, the same will always be true
after the operation completes, for the new value of nextIndex, as
updated by the operation).

The following operations on a header stack are allowed by the
p4lang/p4c P4_14 compiler, without errors or warnings, and are
implemented as described in bmv2.  One can easily violate the no-holes
invariant using these operations, and it is not clear whether they are
considered to be fully supported in P4_14, or not.

During parsing, do extract on a particular index,
e.g. `extract(<header_stack>[3])`.  bmv2 implements this by making the
specified element of the header stack valid, and copying data from the
input packet into that header.  It does not access nextIndex, neither
to read it nor modify it.

During ingress/egress control blocks, do
`add_header(<header_stack>[3])` or `remove_header(<header_stack>[3])`.
bmv2 implements this by making the specified element of the header
stack valid for `add_header`, or invalid for `remove_header`, without
accessing `nextIndex`, neither reading `nextIndex` nor modifying it.
bmv2 does _not_ implement the behavior for these operations in the
P4_14 spec, which says that later elements of the header stack should
be shifted 1 index higher for `add_header`, or shifted 1 index lower for
`remove_header`.

Those P4_14 specified behaviors for `add_header` and `remove_header`
are additional evidence that suggest the intent was to maintain the
no-holes invariant, although the P4_14 spec does not specify what
should happen if `add_header` or `remove_header` are performed with an
index larger than the current value of `nextIndex`.


## Possible approaches to harmonizing header stack operations

It is strongly desired to support automatic translation of P4_14
programs to P4_16 programs with equivalent behavior.


### P4_16 v1.0.0 is right

One approach to this would be to declare P4_16 v1.0.0's "holes are
explicitly supported" approach as common to both P4_14 and P4_16,
creating an edited P4_14 v1.0.5 spec that made this explicit, and
updating the few cases where bmv2 does not match the P4_16 v1.0.0
spec.

I believe the only update needed to bmv2 would be in the `push` and
`pop` behavior, making them shift all elements in the header stack
regardless of the original value of `nextIndex`, and for `push`,
making the new pushed-in elements be invalid rather than valid.

A new P4_14 v1.0.5 spec should explicitly state that holes are
allowed, and the behavior of the primitive operations `push` `pop`
`add_header` and `remove_header` would need to be updated.

It would be good to explicitly call out a few sequences of operations
that can create holes in both P4_14 and P4_16 specs, an explain what
the resulting behavior should be.


### bmv2 is right

This would require changing the P4_16 spec's definition of
`push_front` and `pop_front`, to only shift the portion of the header
stack up to the original index of `nextIndex-1`.

It would also require updating P4_14's definition of `add_header` and
`remove_header` to eliminate the push/pop part of their behavior.



### P4_14 v1.0.4 is right

I am not advocating this -- just mentioning it as a possibility.  If
people have grown accustomed to the bmv2 behavior and expect it is
right, then they probably don't want to make this choice.


### Something else

Not sure what exactly might be of interest here, but one possibility
would be to say bmv2 is right for P4_14, but that for P4_16, the
v1.0.0 spec is right.  This would require changing how P4_14 `push`
operations are auto-translated to P4_16 source code, e.g. by
explicitly adding P4_16 `setValid()` calls for the newly pushed header
stack elements.
