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

As of 2017-Jul-08, the P4_16 compiler `p4test` in
https://github.com/p4lang/p4c compiles tcp-options-parser.p4 without
any errors, but `p4c-bm2-ss` gives an error that Tcp_option_h is not a
header type.  This is because as of that date the bmv2 back end code
in `p4c-bm2-ss` code does not yet handle header_union.

tcp-options-parser2.p4 is a somewhat modified version that does not
use the header_union feature of the P4 language, but as a result it
also does not parse TCP options correctly.  It can be compiled with
both `p4test` and `p4c-bm2-ss`, which is the only reason why it was
created.
