# Some articles on P4

The target audience for these two articles is someone implementing the
P4 action profile and action selector externs on a new target, but
they might be of interest to a P4 developer who is curious how a
target device might be working "under the hood":

+ [Implementing P4 action profiles using two P4
  tables](/action-profile-and-selector/README-action-profile.md)
+ [Implementing P4 action selectors using P4 tables and a hash
  function](/action-profile-and-selector/README-action-selector-variant-comparison.md)

[Generating P4 code for fun and profit](/code-generation/README.md) -
Using code generation to avoid drudgery in writing programs with
repetitive code.

[Some alternatives for handling variable length headers in
P4](/variable-length-header/README.md) - Describes the fairly strict
limitations that the P4 language has for operating upon header fields
with type `varbit`, and alternatives for parsing variable-length
headers without using any fields of type `varbit` at all.

[Why doesn't P4 have floating point
types?](floating-point-operations.md), and what you can do about it.

[How much does on-chip memory cost vs. commodity
DRAM?](cost-of-high-speed-storage.md) - Why do switch ASIC designers
seem to be so stingy with the size of tables?

[Building "effectively atomic" updates from non-atomic
updates](indirection-helps-with-atomicity.md) - I wrote this early in
2018 while the P4 API working group was deciding what kinds of
atomicity to require of a P4Runtime implementation, and what to make
optional.  The basic idea of the article is that if you have a P4
programmable switch, you can build up atomic control plane operations
out of non-atomic operations, if you have at least one extra table to
help.

[P4 hit index feature and how it affects control plane
software](p4-hit-index-and-p4runtime.md) - Some switch ASICs have a
'hardware hit index' number that can be returned as part of a table
search operation, in addition to P4 action parameters, which can be
used in later table lookup operations.  This article shows that there
is a potential cost of extra complexity of control plane software in
using such an approach.

[Size property of P4 tables and parser value
sets](p4-table-and-parser-value-set-sizes.md) - This article explains
why it is common for some hardware switches to have a capacity, in
number of entries, that is not easy to predict.

[P4 table behaviors](p4-table-behaviors.md) - This article is likely
only of interest to people designing or writing detailed verification
tests for a P4 device.  It explains what I believe are all possible
behaviors of a P4 table, depending upon how it is defined in the P4
program.

[Implementing range matching using multiple ternary entries in a
TCAM](../match-range-using-tcam/README.md) - This article is of
interest to anyone wanting to implement the `range` match kind using a
normal TCAM (ternary CAM).
