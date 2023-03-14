`simple_l3_modecr.p4` is a fairly simple modification of the file
`simple_l3.p4` in this directory of the IPDK repository:
https://github.com/ipdk-io/ipdk/tree/main/build/networking/examples/simple_l3

The main difference from `simple_l3.p4` to `simple_l3_modecr.p4` is
that the latter copies parts of the 48-bit source MAC address in the
Ethernet header of received packets into several other fields of the
packet header.  This might be useful in helping to determine whether
original 48-bit source MAC address as received by the DPDK software
switch is overwritten in some later part of the system before we
record the output packet.

`simple_l3_modecr.conf` is just a copy of `simple_l3.conf` from that
same directory.
