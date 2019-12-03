# Compiling

See [README-using-bmv2.md](../README-using-bmv2.md) for some things
that are common across different P4 programs executed using bmv2.

To compile the P4_16 version of the code:

    p4c --target bmv2 --arch v1model demo3.p4_16.p4

To compile the P4_14 version of the code:

    p4c --std p4-14 --target bmv2 --arch v1model demo3.p4_14.p4

The .dot and .png files in the subdirectory 'graphs' were created with
the p4c-graphs program, which is also installed when you build and
install p4c-bm2-ss:

    p4c-graphs -I $HOME/p4c/p4include demo3.p4_16.p4

The '-I' option is only necessary if you did _not_ install the P4
compiler in your system-wide /usr/local/bin directory.


# Running

To run the behavioral model with 8 ports numbered 0 through 7:

    sudo simple_switch --log-console -i 0@veth2 -i 1@veth4 -i 2@veth6 -i 3@veth8 -i 4@veth10 -i 5@veth12 -i 6@veth14 -i 7@veth16 demo3.p4_16.json

To run CLI for controlling and examining simple_switch's table
contents:

    simple_switch_CLI

General syntax for table_add commands at simple_switch_CLI prompt:

    RuntimeCmd: help table_add
    Add entry to a match table: table_add <table name> <action name> <match fields> => <action parameters> [priority]

You can find more comprehensive documentation about the `table_add`
and `table_set_default` commands
[here](https://github.com/p4lang/behavioral-model/blob/master/docs/runtime_CLI.md#table_add)
and
[here](https://github.com/p4lang/behavioral-model/blob/master/docs/runtime_CLI.md#table_set_default),
but you do not need to know all of that to understand and use the
example commands here.

----------------------------------------------------------------------
simple_switch_CLI commands for demo3 program
----------------------------------------------------------------------

    # These should be unnecessary for P4_16 program, which defines
    # these default actions with default_action assignments in its
    # table definitions.
    table_set_default compute_ipv4_hashes compute_lkp_ipv4_hash
    table_set_default ipv4_da_lpm my_drop
    table_set_default mac_da my_drop
    table_set_default send_frame my_drop

Add both sets of entries below:

    # For P4_16 program, set_l2ptr action name for table ipv4_da_lpm
    # is changed to set_l2ptr_with_stat.
    table_add ipv4_da_lpm set_l2ptr_with_stat 10.1.0.1/32 => 58
    table_add mac_da set_bd_dmac_intf 58 => 9 02:13:57:ab:cd:ef 2
    table_add send_frame rewrite_mac 9 => 00:11:22:33:44:55

    table_add ipv4_da_lpm set_l2ptr_with_stat 10.1.0.200/32 => 81
    table_add mac_da set_bd_dmac_intf 81 => 15 08:de:ad:be:ef:00 1
    table_add send_frame rewrite_mac 15 => ca:fe:ba:be:d0:0d

    # For P4_14 program, use this
    table_add ipv4_da_lpm set_l2ptr 10.1.0.1/32 => 58
    table_add mac_da set_bd_dmac_intf 58 => 9 02:13:57:ab:cd:ef 2
    table_add send_frame rewrite_mac 9 => 00:11:22:33:44:55

    table_add ipv4_da_lpm set_l2ptr 10.1.0.200/32 => 81
    table_add mac_da set_bd_dmac_intf 81 => 15 08:de:ad:be:ef:00 1
    table_add send_frame rewrite_mac 15 => ca:fe:ba:be:d0:0d

The entries above with action set_l2ptr on table ipv4_da_lpm work
exactly as they did before.  They avoid needing to do a lookup in the
new ecmp_group table.

Here is a first try at using the ecmp_group and ecmp_path tables for
forwarding packets.  It assumes that the table entries above are
already added.

I want all packets that match 11.1.0.1/32 to go through a 3-way ECMP
table to output ports 1, 2, and 3, where ports 1 and 2 reuse the
mac_da table entries added above.

    # mac_da and send_frame table entries for output port 3
    table_add mac_da set_bd_dmac_intf 101 => 22 08:de:ad:be:ef:00 3
    table_add send_frame rewrite_mac 22 => ca:fe:ba:be:d0:0d
    
    # LPM entry pointing at ecmp group idx 67.
    # Then ecmp_group entry for ecmp group idx 67 that returns num_paths=3.
    # Then 3 ecmp_path entries with ecmp group idx 67, and
    # ecmp_path_selector values in the range [0,2], each giving a
    # result with a different l2ptr value.

    table_add ipv4_da_lpm set_ecmp_group_idx 11.1.0.1/32 => 67
    table_add ecmp_group set_ecmp_path_idx 67 => 3
    table_add ecmp_path set_l2ptr 67 0 => 81
    table_add ecmp_path set_l2ptr 67 1 => 58
    table_add ecmp_path set_l2ptr 67 2 => 101


----------------------------------------------------------------------
scapy session for sending packets
----------------------------------------------------------------------
I believe we must run scapy as root for it to have permission to send
packets on veth interfaces.

```bash
$ sudo scapy
```

```python
fwd_to_p1=Ether() / IP(dst='10.1.0.200') / TCP(sport=5793, dport=80) / Raw('The quick brown fox jumped over the lazy dog.')
fwd_to_p2=Ether() / IP(dst='10.1.0.1') / TCP(sport=5793, dport=80)
drop_pkt1=Ether() / IP(dst='10.1.0.34') / TCP(sport=5793, dport=80)

# Send packet at layer2, specifying interface
sendp(fwd_to_p1, iface="veth2")
sendp(fwd_to_p2, iface="veth2")
sendp(drop_pkt1, iface="veth2")

# For packets going to the ECMP group, vary the source IP address
# so that each will likely get different hash values.

# The hash value for this one caused it to go out port 2 in my
# testing.
fwd_to_ecmp_grp1=Ether() / IP(dst='11.1.0.1', src='1.2.3.4') / TCP(sport=5793, dport=80)
# output port 1 for this packet
fwd_to_ecmp_grp2=Ether() / IP(dst='11.1.0.1', src='1.2.3.5') / TCP(sport=5793, dport=80)
# output port 3 for this packet
fwd_to_ecmp_grp3=Ether() / IP(dst='11.1.0.1', src='1.2.3.7') / TCP(sport=5793, dport=80)
```

----------------------------------------


# Patterns

The example table entries and sample packet given above can be
generalized to the following 3 patterns.


## Pattern 1 - no ECMP

The first pattern is for packets that do not do ECMP at all, because
their longest prefix match lookup result directly gives an l2ptr.

If you send an input packet like this:

    input port: anything
    Ether() / IP(dst=<hdr.ipv4.dstAddr>, ttl=<ttl>)

and you create the following table entries:

    table_add ipv4_da_lpm set_l2ptr_with_stat <hdr.ipv4.dstAddr>/32 => <l2ptr>
    table_add mac_da set_bd_dmac_intf <l2ptr> => <out_bd> <dmac> <out_intf>
    table_add send_frame rewrite_mac <out_bd> => <smac>

then the P4 program should produce an output packet like the one
below, matching the input packet in every way except, except for the
fields explicitly mentioned:

    output port: <out_intf>
    Ether(src=<smac>, dst=<dmac>) / IP(dst=<hdr.ipv4.dstAddr>, ttl=<ttl>-1)



## Pattern 2 - no ECMP, but one level of indirection

The second pattern is for packets that go through one level of
indirection in the ecmp_group table, but skip over the ecmp_path
table.  This is useful to software for having many longest prefix
match entries point at a since ecmp_group table entry, but by having
the indirection, all of those prefixes can be updated to a new output
port and source MAC address with a single write to the ecmp_path
table.

The only differences between pattern 2 and pattern 1 are in table
ipv4_da_lpm and ecmp_group.  mac_da and send_frame are the same as
before.

If you send an input packet like this:

    same as pattern 1

and you create the following table entries:

    table_add ipv4_da_lpm set_ecmp_group_idx <hdr.ipv4.dstAddr>/32 => <ecmp_group_idx>
    table_add ecmp_group set_l2ptr <ecmp_group_idx> => <l2ptr>
    same as pattern 1 from table mac_da onwards



## Pattern 3 - full ECMP

Software should use this for equal cost multipath routing,
i.e. multiple shortest paths to the same destination, over which
traffic should be load balanced, based upon a hash calculated from
some packet header field values specified in action
compute_lkp_ipv4_hash.

If you send an input packet like this:

    same as pattern 1

and you create the following table entries:

    table_add ipv4_da_lpm set_ecmp_group_idx <hdr.ipv4.dstAddr>/32 => <ecmp_group_idx>
    table_add ecmp_group set_ecmp_path_idx <ecmp_group_idx> => <num_paths>
    table_add ecmp_path set_l2ptr <ecmp_group_idx> <ecmp_path_selector> => <l2ptr>
    same as pattern 1 from table mac_da onwards

NOTE: <ecmp_path_selector> is a hash calculated from the packet, then
modulo'd by <num_paths>, so it can be any number in the range [0,
<num_paths>-1].  For this pattern, it would be good to install
<num_paths> entries in the ecmp_path table, and for each one of those
<l2ptr> values, there should be corresponding entries in the mac_da
and send_frame tables.  It is OK to have multiple ecmp_path entries
with the same <l2ptr> value -- this is normal when software creates
such tables, especially across different <ecmp_group_idx> values.

When checking the output packet, it is correct to receive an output
packet for any of the <num_paths> possible paths.  If the test
environment wants to narrow it down to 1 possible output packet, it
must do the same hash function that the data path code is doing.


# Last successfully tested with these software versions

For https://github.com/p4lang/p4c

```
$ git log -n 1 | head -n 3
commit 75df2526b6d9fa1146dfe41c73fc24224baf4502
Author: Chris Dodd <cdodd@barefootnetworks.com>
Date:   Sun Dec 1 09:13:08 2019 -0800
```

For https://github.com/p4lang/behavioral-model

```
$ git log -n 1 | head -n 3
commit 16c699953ee02306731ebf9a9241ea9fe3bbdc8c
Author: Antonin Bas <abas@vmware.com>
Date:   Sun Nov 17 14:09:11 2019 -0800
```
