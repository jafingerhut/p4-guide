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

`simple_l3_modecr.conf` is almost an exact copy of `simple_l3.conf`
from that same directory, with two occurrences of `simple_l3` replaced
with `simple_l3_modecr`.

The pcap file was created by running this command on an Ubuntu 20.04
system with the Python scapy package installed:
```bash
./gen-pcaps.py
```
