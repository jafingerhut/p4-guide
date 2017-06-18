2017-Jun-18 Andy Fingerhut (andy.fingerhut@gmail.com)

rewrite-examples.p4 was created by starting from the 2017-Mar-07
version of switch.p4 from this repository:

    https://github.com/p4lang/switch

The P4_14 source code is in the directory p4src in that repository.  A
version auto-translated to P4_16 can be found here:

    https://github.com/jafingerhut/p4lang-tests/blob/master/v1.0.3/switch-2017-03-07/out1/switch-translated-to-p4-16.p4

Starting from that P4_16 program, I deleted all of the code and tables
for the ingress control block, and most of the code except for the
egress control block.

What remains is a small subset of the parser, and a subset of the
egress rewrite code, plus a significant portion of the tunnel
encapsulation code, which has been heavily modified.

This code compiles cleanly with the latest P4_16 compiler as of
2017-Jun-16, but it has not been tested to see whether it has enough
code to do anything useful on its own, or whether the code that is
there is correct.

It is intended to demonstrate one way to implement tunnel
encapsulation code, where an IPv4 or IPv6 packet with an Ethernet
header may be encapsulated into any one of these kinds of tunnels,
with the given sequence of headers prepended in front of the original
packet:

    Ethernet + IPv4 + GRE
    Ethernet + IPv4
    Ethernet + IPv6 + GRE
    Ethernet + IPv6
    Ethernet + a generic 20-byte header
    Ethernet + a generic 28-byte header
    Ethernet + a generic 40-byte header

Most of the code of interest is in the 'process_tunnel_encap' control
block.  The 'DeparserImpl' control block shows the order that headers
will be emitted when the packet processing is complete.  Note that the
emit() method does nothing if the header it is given as an argument is
invalid, which all headers are initially, until they are made valid by
being parsed, or having their setValid() method called on them.

None of the headers with names beginning 'outer_' or 'generic_' are
ever parsed in this program, so the only way they can become valid is
by having their setValid() method called.
