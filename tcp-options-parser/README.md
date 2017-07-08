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
    maintained across potentially many state transitions, rather than
    a field extracted directly from a packet header without further
    modification.  The parser code does arithmetic to modify its
    value, depending upon the contents of various header bytes.
