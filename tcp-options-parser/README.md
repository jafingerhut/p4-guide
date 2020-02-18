See the comments after the license boilerplate near the beginning of
tcp-options-parser.p4 for some similar TCP options parsing code that
this code was derived from.

The code in parser Tcp_option_parser, and the definition of the TCP
option header types, is the distinctive part of this example.
Everything else is pretty standard stuff you can find in many other P4
programs.

That parser demonstrates a couple of things that are uncommon in P4
parsers:

(a) parser ParserImpl calls a sub-parser Tcp_option_parser.

(b) A 'transition select' statement in state 'next_option' with an
    expression based on a variable 'tcp_hdr_bytes_left' that is
    modified via assignment statements across potentially many state
    transitions, rather than a field extracted directly from a packet
    header without further modification.  The parser code does
    arithmetic to modify its value, depending upon the contents of
    various header bytes.

As of 2019-Mar-24, the P4_16 compiler https://github.com/p4lang/p4c
compiles `tcp-options-parser.p4` without any compilation errors:

```bash
p4test tcp-options-parser.p4
p4c --target bmv2 --arch v1model tcp-options-parser.p4
```

`p4c` as of that date now has better support for `header_union` than
it had in 2017.  I have not tested whether the compiled program
executes correctly using `simple_switch`.

`tcp-options-parser2.p4` is a somewhat modified version that does not
use the `header_union` feature of the P4 language, but as a result it
also does not parse TCP options correctly.  The only reason that
variation was created was that it compiled without error using older
versions of `p4c` (e.g. circa 2017).

The directory [`look-for-ts-tcp-option`](look-for-ts-tcp-option/)
contains another version that uses no header stacks, nor
`header_union` types, and thus is likely to be more portable than P4
code that does use those P4 language features, but note that as for
most programs in this repository, I have not done extensive testing on
them, nor have I checked what P4 targets they might be portable for.
They are intended for learning purposes, and perhaps a useful starting
point for your own P4 development efforts.
