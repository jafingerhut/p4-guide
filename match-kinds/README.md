# P4 match kinds

The P4_16 language specification documents the existence of these
match kinds:

* `exact`
* `lpm`
* `ternary`

The open source v1model architecture adds these:

* `range`
* `selector` - used only for 

This documentation for simple_switch gives some details about these
match kinds, including restriction on `lpm` fields supported by
simple_switch, and how one can write table entries for them in a P4_16
program using `const entries`:
https://github.com/p4lang/behavioral-model/blob/master/docs/simple_switch.md#table-match-kinds-supported

This article documents the syntax to use for adding table entries
using the `simple_switch_CLI` program:
https://github.com/p4lang/behavioral-model/blob/master/docs/runtime_CLI.md#table_add

In late 2019, some P4 developers have proposed adding the following
new match kinds:

* `optional` - similar to `ternary`, but with a restriction that the
  mask is either completely wildcard in every bit position, or
  completely exact match in ever bit position.
* `set` - This is strictly more general than all other match kinds, in
  that it could be used to implement any of them.  The control plane
  specifies a set of all individual values that they want to allow to
  match for the field in a search key, for a single table entry as
  specified by the P4Runtime API.  An implementation might turn that
  into multiple hardware entries, but this can be viewed as an
  implementation detail, albeit an important one for those concerned
  with resource usage of table entries in the target device.

After some discussion in the P4 Language Design working group it was
suggested that open source implementations be created in these
repositories for the v1model architecture, in order to demonstrate how
they can be implemented, and prove their usefulness:

* https://github.com/p4lang/p4c
* https://github.com/p4lang/behavioral-model
* https://github.com/p4lang/p4runtime
* https://github.com/p4lang/PI

As of February 2020, there are pull requests with proposed changes
available to implement the addition of the `optional` match kind.
Below is a list of them for reference, showing at least most of the
places that would also require changes if someone wants to add the
`set` match kind.

I have attempted to put them in order of dependency between them, with
later ones depending upon earlier commits happening first.  The PR for
documentation changes does not have any code dependencies with the
others, but it seems best to wait to publish the new documentation
until after most or all of the implementation is ready.

* Changes to https://github.com/p4lang/p4runtime
  * https://github.com/p4lang/p4runtime/pull/259 (done)
* Changes to https://github.com/p4lang/p4c
  * https://github.com/p4lang/p4c/pull/2184 (done)
* Changes to https://github.com/p4lang/PI
  * https://github.com/p4lang/PI/pull/504 (done)
* Changes to https://github.com/p4lang/behavioral-model
  * simple_switch_grpc https://github.com/p4lang/behavioral-model/pull/861 (waiting on PI #504 to merge first)
  * Documentation https://github.com/p4lang/behavioral-model/pull/847 (done)


In order to reduce the development effort required, the approach taken
for `optional` was to reuse the existing `ternary` match kind for such
fields in the BMv2 JSON files used as the output from the p4c
compiler, and input to the behavioral-model simple_switch /
simple_switch_grpc software switch.  This savings of effort is not
possible for the `set` match kind, so implementing `set` will thus
require more changes to behavioral-model than the implementation of
`optional` did.

For example, the BMv2 JSON file format had 0 changes made to it to
support `optional`, because the simplifying choice was made to reuse
`ternary` in the BMv2 JSON file whenever `optional` was used in the P4
source code.  That is not possible for `set`, which requires a new
match kind in the BMv2 JSON file, and code in behavioral-model to read
that new match kind from the BMv2 JSON file, store it in the
appropriate new in-memory data structures, and match on it when tables
are searched.

There also needs to be new code in behavioral-model for the `set`
match kind to handle adding and modifying table entries that have one
or more fields with match kind `set` as a field in the search key.
