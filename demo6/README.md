See [README-using-bmv2.md](../README-using-bmv2.md) for some things
that are common across different P4 programs executed using bmv2.

To compile the P4_16 version of the code:

    p4c --target bmv2 --arch v1model demo6.p4_16.p4

To compile the P4_14 version of the code:

    p4c --std p4-14 --target bmv2 --arch v1model demo6.p4_14.p4

The .dot and .png files in the subdirectory 'graphs' were created with
the p4c-graphs program, which is also installed when you build and
install p4c-bm2-ss:

     p4c-graphs -I $HOME/p4c/p4include demo6.p4_16.p4

The '-I' option is only necessary if you did _not_ install the P4
compiler in your system-wide /usr/local/bin directory.

To run the behavioral model with 8 ports numbered 0 through 7:

    sudo simple_switch --log-console -i 0@veth2 -i 1@veth4 -i 2@veth6 -i 3@veth8 -i 4@veth10 -i 5@veth12 -i 6@veth14 -i 7@veth16 demo6.p4_16.json

To run CLI for controlling and examining simple_switch's table
contents:

    simple_switch_CLI

General syntax for table_add commands at simple_switch_CLI prompt:

    RuntimeCmd: help table_add
    Add entry to a match table: table_add <table name> <action name> <match fields> => <action parameters> [priority]

----------------------------------------------------------------------
simple_switch_CLI commands for demo6 program
----------------------------------------------------------------------

The demo6 programs are nearly identical to the corresponding programs
in the demo2 directory.  The only difference is that they demonstrate
the use of a P4 register for maintaining counts of packets received,
with a separate count for each input port.

Yes, it is certainly possible to use a P4 counter to do this, so this
example does not demonstrate the full power of P4 registers.  I only
created it to have a minimal working example that uses P4 registers.

All of these, except for the counter-specific ones, also work for
demo1.

    table_set_default ipv4_da_lpm my_drop
    table_set_default mac_da my_drop
    table_set_default send_frame my_drop

Add both sets of entries below:

    table_add ipv4_da_lpm set_l2ptr 10.1.0.1/32 => 58
    table_add mac_da set_bd_dmac_intf 58 => 9 02:13:57:ab:cd:ef 2
    table_add send_frame rewrite_mac 9 => 00:11:22:33:44:55

    table_add ipv4_da_lpm set_l2ptr 10.1.0.200/32 => 81
    table_add mac_da set_bd_dmac_intf 81 => 15 08:de:ad:be:ef:00 4
    table_add send_frame rewrite_mac 15 => ca:fe:ba:be:d0:0d

The same `counter_read` commands described in the file
`demo2/README.md` of this repository will work for this program.

You can read the contents of register `input_port_pkt_count` at index
1 with the following `simple_switch_CLI` command:

    register_read input_port_pkt_count 1

You can write the contents of that register at index 10 with the new
value of 57 with this command:

    register_write input_port_pkt_count 10 57

You should be able to examine counter values in the counter named
ipv4_da_lpm_stats using the `counter_read` command, which takes the
counter name and a handle id.  Because ipv4_da_lpm_stats is declared
`direct` on table ipv4_da_lpm, and thus contains one entry for every
one in ipv4_da_lpm, use the handle id for the corresponding
ipv4_da_lpm table entry that you want stats for.

[ There is a bug with some versions of p4c-bm2-ss that prevents
counter_read commands from succeeding, roughly corresponding to p4c
source code from 2017-Nov-07 until 2017-Nov-20. ]

    RuntimeCmd: counter_read ipv4_da_lpm_stats 0
    this is the direct counter for table ipv4_da_lpm
    ipv4_da_lpm_stats[0]=  BmCounterValue(packets=1, bytes=54)

After sending another packet matching the same ipv4_da_lpm entry,
reading the counter entry gives different values:

    RuntimeCmd: counter_read ipv4_da_lpm_stats 0
    this is the direct counter for table ipv4_da_lpm
    ipv4_da_lpm_stats[0]=  BmCounterValue(packets=2, bytes=108)

The command `counter_reset <name>` clears all counters in the named
collection of counters.

    RuntimeCmd: counter_reset ipv4_da_lpm_stats
    this is the direct counter for table ipv4_da_lpm

    RuntimeCmd: counter_read ipv4_da_lpm_stats 0
    this is the direct counter for table ipv4_da_lpm
    ipv4_da_lpm_stats[0]=  BmCounterValue(packets=0, bytes=0)

----------------------------------------------------------------------
scapy session for sending packets
----------------------------------------------------------------------
I believe we must run scapy as root for it to have permission to send
packets on veth interfaces.

```bash
$ sudo scapy
```

```python
fwd_pkt1=Ether() / IP(dst='10.1.0.1') / TCP(sport=5793, dport=80)
drop_pkt1=Ether() / IP(dst='10.1.0.34') / TCP(sport=5793, dport=80)

# Send packet at layer2, specifying interface
sendp(fwd_pkt1, iface="veth2")
sendp(drop_pkt1, iface="veth2")

fwd_pkt2=Ether() / IP(dst='10.1.0.1') / TCP(sport=5793, dport=80) / Raw('The quick brown fox jumped over the lazy dog.')
sendp(fwd_pkt2, iface="veth2")
```

----------------------------------------

# Last successfully tested with these software versions

For https://github.com/p4lang/p4c

```
$ git log -n 1 | head -n 3
commit b806cecb70c19620acbb86c963d4f84b48c0a51f
Author: fruffy <5960321+fruffy@users.noreply.github.com>
Date:   Thu May 23 23:26:23 2019 +0200
```

For https://github.com/p4lang/behavioral-model

```
$ git log -n 1 | head -n 3
commit 4d14161917095b69adaff99f3a3e056a2a150003
Author: Kevin Ye <kevinye2@users.noreply.github.com>
Date:   Sun Jun 2 19:31:53 2019 -0400
```
