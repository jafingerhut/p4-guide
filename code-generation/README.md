# Generating P4 code for fun and profit


## Introduction and background

Often when developing
[P4](https://en.wikipedia.org/wiki/P4_(programming_language))
programs, and programs in other programming languages, it is desirable
to write code that can be done with the current definition of the
language, but only via fairly repetitive code, or code with a regular
but detailed structure that is possible to get right when a human
types it, but can be very error prone when developed that way.

It is sometimes possible to work around the limitations of the
language, and to use a program written in some other programming
language (we will give an example of a small
[Python](https://en.wikipedia.org/wiki/Python_(programming_language))
program for that here) to _generate_ P4 code for you, then `#include`
those generated files into a hand-written P4 program.

This article describes a couple of examples of this, where the
examples are motivated by questions people have asked on the [p4-dev
email
list](https://lists.p4.org/mailman/listinfo/p4-dev_lists.p4.org).

Is this new or distinctive to the P4 programming language?  Definitely
not.  You can do this with _any_ programming language.  Just write a
program `GEN` that prints out the text of part (or all) of another
program `T`.  `GEN` need not be written in the same programming
language as `T`.


## Example 1 - accessing bytes of a header selected by a run-time index

Goal: We want to have a header in a packet consisting of 32
consecutive bytes, call them `b[0]` through `b[31]`.  Based upon some
values that can vary at run time from packet to packet, we want to
calculate one or more indexes in the range [0, 30], and use each index
`i` to either read 2 bytes `b[i]` and `b[i+1]`, or to write those 2
bytes.

If you are familiar with general purpose programming languages that
have arrays, your first reaction would be that this is very
straightforward: Declare an array, calculate an index value in `i`,
and then access array elements `b[i]` and `b[i+1]`, reading them or
storing values into them whenever you wish using assignment
statements.  Easy.

What makes this difficult in at least some P4 implementations (perhaps
most as of February 2020) is that, while you can declare a header
stack, which is an array of headers, you may only access elements of
such an array using an index that is a compile time constant, e.g. 17
or (3-1+4), not a run-time variable value like `i`.  See the "Aside"
section below for some possible reasons why this restriction exists.

Given this restriction in a P4 implementation that one wishes to use,
is it _impossible_ to achieve this goal?

Hardly.  We can do it without even using a header stack in the
program, if we do not want to, and the sample code here does not use a
header stack.

Here is the relevant part of the P4_16 code that can be used to read 2
bytes at an index specified in `i`, abbreviated a bit:

```
header my_custom_hdr_t {
    bit<8> f0;
    bit<8> f1;
    // ... f2 through f30 omitted for brevity
    bit<8> f31;
}

struct headers_t {
    // other headers omitted here
    my_custom_hdr_t my_custom_hdr;
}

control read_custom_header_at_index (in my_custom_hdr_t my_custom_hdr,
                                     in bit<8> index,
				     out bit<16> result,
                                     out bool index_in_range)
{
    action read_offset_0 () {
        // The P4_16 operator ++ concatenates a bit<W1> operand and
        // bit<W2> operand to product a bit<W1+W2> result.
        result = my_custom_hdr.f0 ++ my_custom_hdr.f1;
    }
    action read_offset_1 () {
        result = my_custom_hdr.f1 ++ my_custom_hdr.f2;
    }

    // ... actions read_offset_2 through read_offset_29 omitted

    action read_offset_30 () {
        result = my_custom_hdr.f30 ++ my_custom_hdr.f31;
    }
    action index_out_of_range () {
        index_in_range = false;
        result = 0;
    }

    table read_from_index {
        keys = {
	    index : exact;
        }
        actions = {
	    read_offset_0;
	    read_offset_1;
            // ... actions read_offset_2 through read_offset_29 omitted
	    read_offset_30;
            @defaultonly index_out_of_range;
        }
	const entries = {
            0 : read_offset_0();
            1 : read_offset_1();
            // ... entries for actions read_offset_2 through
            // read_offset_29 omitted
            30 : read_offset_30();
	}
        const default_action = index_out_of_range;
    }

    apply {
        index_in_range = true;
        read_from_index.apply();
    }
}

control ingress (inout headers_t hdr,
                 inout metadata_t meta,
                 inout standard_metadata_t stdmeta)
{
    read_custom_header_at_index() read_inst1;
    bit<8> i;
    bit<16> result;
    bool result_valid;

    apply {
        // Code that calculates a value for index i would go here.
        read_inst1.apply(hdr.my_custom_hdr, i, result, result_valid);
        // Code that uses values of result and result_valid would go here.
    }
}
```

Several parts of this P4 code are quite repetitive, and it would be
tedious and error prone to type them in manually, but they can easily
be printed out by a program.

See [README-example-1.md](README-example-1.md) for details on a
complete example that generates the code for a program like the sample
above, plus another control that can be called to write a 16-bit value
into 2 consecutive bytes of the custom header at a run-time index
value.

Note: This approach generalizes to any correspondence you wish between
the run-time values you calculate, and which subset of fields of the
header are accessed.  It doesn't have to be like an array.


### Aside - why the compile time constant index restriction in some P4 implementations?

Why do some P4 implementations restrict the index of a header stack
access to compile time constant index values, one may very reasonably
ask?  As a rough analogy, some P4 implementations store the headers
and user-defined variables of your program in something similar to
general purpose CPU registers.  Most general purpose CPUs have
addressing modes enabling them to access data in RAM using offsets
stored in a register, e.g. base address 0xfff78e000 plus the value
stored in register `r5`, but I have not seen one that lets you select
among its general purpose registers based on the value stored in a
register, e.g. access register `r(4+(contents of r7))`, where if `r7`
contained 2, that expression would access register `r(4+2)`,
i.e. `r6`.

Another reason is that in networking protocols like VLAN tags and
stack of MPLS headers, which were the motivating use cases in
networking for having header stacks in the P4 language, it is often
enough to access elements at a compile time constant index.  If there
are multiple cases, there are usually only 2 or 3 of them, and one can
write 3 different actions of a table to handle the different cases,
manually, where code generation techniques as described here would be
overkill.


## Example 2 - executing loops with a compile-time maximum number of iterations

Goal: We want to execute a loop that in a C-like language we would
write similarly to one of these examples:

```
    // Loop 1
    for (i = 0; i < 10; i++) {
        hdr.result[i] = hdr.array1[i] + hdr.array2[i];
    }
```

```
    // Loop 2
    // Note: assume that we know, for reasons not shown in this code,
    // that n must be in the range [0, 12].
    found_big_index = false;
    for (i = 0; i < n; i++) {
        if (hdr.array1[i] >= 10) {
            first_big_index = i;
            found_big_index = true;
            break;
	}
    }
```

There is a technique used in many compilers called [loop
unrolling](https://en.wikipedia.org/wiki/Loop_unrolling), which is a
kind of optimization to produce faster machine code as output from the
compiler.  What I describe here is not exactly the same, in that we
will _completely_ unroll the loops, leaving no loops in the resulting
code, and we are doing it not to speed up the resulting code, but to
make it possible to compile at all in P4, versus not compile at all.

The idea is very straightforward -- for a loop with a maximum number
of iterations K that we can determine at compile time, we can replace
it with code that repeats the body K times, sequentially, with each
body varying in the value of the loop variable(s).

Loop 1 becomes this:
```
    // Loop 1 original code
//    for (i = 0; i < 10; i++) {
//        hdr.result[i] = hdr.array1[i] + hdr.array2[i];
//    }

    // Loop 1 completely unrolled version
    hdr.result[0] = hdr.array1[0] + hdr.array2[0];
    hdr.result[1] = hdr.array1[1] + hdr.array2[1];
    hdr.result[2] = hdr.array1[2] + hdr.array2[2];
    hdr.result[3] = hdr.array1[3] + hdr.array2[3];
    hdr.result[4] = hdr.array1[4] + hdr.array2[4];
    hdr.result[5] = hdr.array1[5] + hdr.array2[5];
    hdr.result[6] = hdr.array1[6] + hdr.array2[6];
    hdr.result[7] = hdr.array1[7] + hdr.array2[7];
    hdr.result[8] = hdr.array1[8] + hdr.array2[8];
    hdr.result[9] = hdr.array1[9] + hdr.array2[9];
```

Loop 2 is a little more involved, and I will introduce a boolean
variable `executed_break` to track whether the original code would
have executed the 'break' statement by that time, or not.

```
    // Loop 2 original code
    // Note: assume that we know, for reasons not shown in this code,
    // that n must be in the range [0, 12].
//    found_big_index = false;
//    for (i = 0; i < n; i++) {
//        if (hdr.array1[i] >= 10) {
//            first_big_index = i;
//            found_big_index = true;
//            break;
//	}
//    }

    // Loop 2 completely unrolled version (only the first few
    // iterations, not all 12)

    executed_break = false;
    found_big_index = false;
    
    // reminder: we know that n is in the range [0, 12].

    // first iteration, when i=0
    if (0 < n) {
        if (hdr.array1[0] >= 10) {
            first_big_index = 0;
            found_big_index = true;
            executed_break = true;
        }
    }

    // second iteration, when i=1, only performed if n > 1 and
    // executed_break is false
    if (!executed_break && (1 < n)) {
        if (hdr.array1[1] >= 10) {
            first_big_index = 1;
            found_big_index = true;
            executed_break = true;
        }
    }

    // third iteration, when i=2, only performed if n > 2 and
    // executed_break is false
    if (!executed_break && (2 < n)) {
        if (hdr.array1[2] >= 10) {
            first_big_index = 2;
            found_big_index = true;
            executed_break = true;
        }
    }
    
    // 4th through 12th iterations look just like the previous 2,
    // changing the three occurrences of '2' to step through the
    // values that i takes on.
```

I have not written any Python code to show you for this example.
Hopefully the sample code from the first example, and the pattern of
the P4 code above, is enough to make it clear what you would need to
do.

Aside: A P4 compiler could also be written to completely unroll loops
in this way, too, for a target that could not perform loops any other
way.  That does not guarantee that the unrolled code would "fit" into
the capabilities of any given P4 target device, especially for loops
with many iterations, but it could make some code with short loops
more convenient to write.


## Possible relevance to the P4 language design work group

Some members of the P4 language design work group have expressed that
they consider examples like these as demonstrating shortcomings of the
P4 language, and the language would be better if it had capabilities
that made these techniques obsolete.

That may be true.  My reaction on hearing this is: look at Example 1
-- it has repetitive code that is generated and included into several
places in the program:

+ the definition of multiple actions, within a control (i.e. not at
  the top level of the P4 program).  These actions vary not only in
  their names, but in the names of fields they access within their
  bodies.
+ in the list of actions given in the `actions` table property of a P4
  table.
+ in the list of table entries in the `const entries` table property
  of a P4 table.
 
It seems challenging to design P4 language constructs that would
implement those same capabilities, in all of those contexts.  For
example, would you want to create some kind of `repeated_code`
construct that works inside of a P4 `control` block to create `action`
definitions, and can also work inside of the list assigned to the
`actions` table property, and also inside of the `const entries` list
of table entries?  Or create separate P4 language constructs, one for
each of those contexts, and perhaps a dozen other contexts,
e.g. parameter lists, definitions of table key fields, definitions of
fields of a header or struct, etc.?

I suppose something like that could be done, but it seems like at
least several months of language design and implementation work to
achieve, and would at best end up with something we can achieve now
using `#include`.  Show any programmer an example of the code
generation approach, and they can immediately hit the ground running
with it to achieve their goals.  Debugging their code generation is as
straightforward as looking at the output of their generator program,
and the error or warning messages from the P4 development tools they
use on that generated code.

An observation: I suppose I actually have no strong objections to
removing C preprocessor-like capabilities from any P4 compiler.  If
that happened, anyone that wants these capabilities can still use the
standalone `cpp` C preprocessor on their own to do all of this, plus
`#define` and `#ifdef`.  One simply needs to remember to delete all
lines beginning with `#` left over in the preprocessor output before
using it as input to their P4 compiler.  (And you can use the C
preprocessor for nearly any programming language, not only for P4.  It
may not work if the target language used `#include` for its own
purposes.)


## Related work

Perhaps most relevant to P4 is this paper:

    "pcube: Primitives for network data plane programming", by Rinku
    Shah, Aniket Shirke, Akash Trehan, Mythili Vutukuru, and
    Purushottam Kulkarni,
    https://www.cse.iitb.ac.in/~mythili/research/papers/2018-pcube.pdf

And the associated code repository:
https://github.com/networkedsystemsIITB/pcube

There are certainly other design choices on how to extend P4, but one
way is the way that the original C++ compiler was implemented, which
was as a preprocessor step that translated to C.  pcube is a
preprocessor that transforms its input, which is P4_14 extended with a
few extra constructs, into P4_14.  As mentioned in the paper, all of
their ideas should extend to an extended version of P4_16 that is
translated into standard P4_16.

You can think of parser generators like
[Bison](https://en.wikipedia.org/wiki/GNU_Bison) and
[Flex](https://en.wikipedia.org/wiki/Flex_(lexical_analyser_generator))
as particularly sophisticated examples of code generation via a
program.  You write a file in a domain-specific language to describe a
grammar, run the Bison program on it, and it generates C, C++, or Java
code that can be incorporated into your program.

Another reason to use such code generation is that often what would be
a large change in the generated code, might be a small change in the
"original source" from which the target code is generated.  The
example of Bison is particularly relevant here: in some cases it can
require only a few minutes to add a new alternative to a grammar rule,
or several new grammar rules, and the resulting generated C code from
the new Bison grammar could have much larger changes than those a
person needed to think about and type.

I have used simple code generation techniques in the late 1990s when
doing hardware logic design using
[VHDL](https://en.wikipedia.org/wiki/VHDL) and
[Verilog](https://en.wikipedia.org/wiki/Verilog), before later
versions of the Verilog language were introduced that made these
approaches less often useful (so I have heard from colleagues who used
those later versions of Verilog, after the year 2000 or so, when I no
longer actively did hardware design).

I have seen multiple tools that allowed one to embed
[Perl](https://en.wikipedia.org/wiki/Perl) code in specially formatted
comments into Verilog source files, that were a kind of templating
language.  The idea was you ran a particular Perl preprocessor on the
mingled Perl/Verilog source code, and it executed Perl code in those
specially formatted comments, and the output was a Verilog program.  I
am not aware of an open source tool like this to refer to, but it is
straightforward enough, and useful enough, to create such a tool in a
commercial setting, that there were multiple different implementations
of such tools developed within different hardware design teams.

[Common Lisp macros](https://en.wikipedia.org/wiki/Common_Lisp#Macros)
(not to be confused with macros in C or C++ -- Lisp's are
significantly more powerful) are an especially interesting example of
doing code generation using the same programming language, and even
within the same program, as the code being generated.  This is made
straightforward in Lisp family languages because the language is
defined not in terms of characters [1], but in terms of data
structures of the language itself, typically lists of symbols, which
can be nested.  The language provides a large powerful library for
manipulating these lists in many ways, which can be used when writing
Lisp macros.

[1] Yes, fine, there is a reader in Lisp, but it is about as simple
    and straightforward as a lexer in most programming languages,
    plus handling of nested lists.  But once you get past this simple
    reader, which is the same one for all programming language
    constructs, you have Lisp data structures in memory, and you can
    use Lisp macros to define new control flow constructs, if you
    wish, that did not come as part of the language itself.
