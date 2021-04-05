# Motivation

calling-convention.p4 was written simply to have a simple example P4
program that demonstrates the difference between the copy-in/copy-out
semantics of P4_16, vs. call by reference.

It demonstrates a perhaps subtle behavior mandated by the P4_16
language specification, where a program's behavior when calling
parsers or controls with multiple `out` or `inout` parameters can
change depending upon the order of those parameters, if those
parameters "overlap" in the caller (e.g. they refer to the same
variable, or where one variable is part of another).

I do not believe that this subtlety of the language is something that
will arise commonly in practical P4 programs.  This example program
was written primarily as a short test case for P4 compiler writers.
It does demonstrate why it would be incorrect, at least in a case like
this program, to implement `out` or `inout` parameters as "pass by
reference" or "pass by pointer".


# Compiling

See [README-using-bmv2.md](../README-using-bmv2.md) for some things
that are common across different P4 programs executed using bmv2.

To compile the P4_16 version of the code:

    p4c-bm2-ss calling-convention.p4 -o calling-convention.json


# Running

    sudo simple_switch --log-console -i 0@veth0 calling-convention.json

No table entries need to be added.

----------------------------------------------------------------------
scapy session for sending packets
----------------------------------------------------------------------

    sudo scapy

    pkt1=Ether() / IP(dst='10.1.0.1') / TCP(sport=5793, dport=80)
    pkt2=Ether() / IP(dst='192.168.3.4') / TCP(sport=5501, dport=80)

    # Send packet at layer2, specifying interface
    sendp(pkt1, iface="veth0")
    sendp(pkt2, iface="veth0")


# Behavior seen during simple_switch run with pkt1 and pkt2

Sending in pkt1 should cause control mod_headers1 to be called.

It will run its apply body.  Because its parameters are in the order
`inout headers hdr` first, followed by `inout ipv4_t ipv4`, the
copy-out of the parameter values will be done in that order.  Thus any
changes made to `hdr.ipv4.*` fields will be overwritten in the caller
when the `ipv4` parameter is copied out.

    Header field   pkt1       packet out
    ipv4.ttl       64         62           as expected from ipv4.ttl assignment
    ipv4.dstAddr   10.1.0.1   10.1.0.5     as expected from ipv4.dstAddr assignment
    tcp.srcPort    5793       5794         as expected from hdr.tcp.srcPort assignment


Sending in pkt2 should cause control mod_headers2 to be called.

It will run its apply body.  Because its parameters are in the order
`inout ipv4_t ipv4` first, followed by `inout headers hdr`, the
copy-out of the parameter values will be done in that order.  Thus any
changes made to `ipv4.*` fields will be overwritten in the caller when
the `hdr` parameter is copied out.

    Header field  pkt1        packet out
    ipv4.ttl      64          63           as expected from hdr.ipv4.ttl assignment
    ipv4.dstAddr  192.168.3.4 192.168.3.4  as expected, ipv4.dstAddr change in mod_headers2 was undone by copy-out of hdr.ipv4
    tcp.srcPort   5501        5502         as expected from hdr.tcp.srcPort assignment, which was not overwritten by copy-out of hdr.ipv4
