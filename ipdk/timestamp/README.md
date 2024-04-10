`timestamp.p4` is nearly the simplest PNA architecture P4 program I
can imagine to learn what values are being given by the implementation
to the `istd.timestamp` field.  It simply copies the value of that
metadata field to the source MAC address in the Ethernet header, and
sends all packets received to port 0.

When I tested this program using IPDK v23.07 on 2024-Apr-10 using
`ptf-test1.py`, which sends 4 packets into the P4 DPDK software
switch, each 1 second apart, the 4 output packets all had 0 in their
source MAC address fields.

If the timestamp feature were implemented in P4 DPDK, I would expect
those 4 source MAC address values to be different from each other.
