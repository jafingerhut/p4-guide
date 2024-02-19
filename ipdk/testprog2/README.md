`mirrorpkts.p4` is a simple PNA architecture P4 program intended to
test the behavior of the `mirror_packet` extern function of PNA.

Unfortunately I do not yet know if there is a way to configure mirror
sessions using the P4Runtime API protocol for P4 DPDK.  The program
mirrorpkts.p4 and PTF test ptf-tests/ptf-test1.py seem to demonstrate
that at the very least, you can invoke the `mirror_packet` extern in a
P4 program, and if the mirror session has not been configured, no
mirror copy of the packet will be created.
