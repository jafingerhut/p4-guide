See README-using-bmv2.txt for some things that are common across
different P4 programs executed using bmv2.

Useful for quickly creating multiple terminal windows and tabs:

    create-terminal-windows.sh

To compile the P4_14 version of the code:

    p4c-bmv2 --json demo2.p4_14.json demo2.p4_14.p4

To compile the P4_16 version of the code:

    p4c-bm2-ss -o demo2.p4_16.json demo2.p4_16.p4

To run behavioral model with 3 ports 1, 2, 3:

    # Note: I have tried running simple_switch on an Ubuntu 14 VM
    # using a .json file that was mounted via SSHFS.  It fails to read
    # such a file.  Workaround: Copy the .json file to a directory on
    # a local file system.  p4c-bmv2 and simple_switch_CLI do not have
    # this limitation.

    sudo simple_switch --log-console -i 0@veth2 -i 1@veth4 -i 2@veth6 -i 3@veth8 -i 4@veth10 -i 5@veth12 -i 6@veth14 -i 7@veth16 demo2.p4_14.json

To run CLI for controlling and examining simple_switch's table
contents:

    simple_switch_CLI

General syntax for table_add commands at simple_switch_CLI prompt:

    RuntimeCmd: help table_add
    Add entry to a match table: table_add <table name> <action name> <match fields> => <action parameters> [priority]

----------------------------------------------------------------------
simple_switch_CLI commands for demo2 program
----------------------------------------------------------------------

All of these, except for the counter-specific ones, also work for
demo1.

    table_set_default ipv4_da_lpm my_drop
    table_set_default mac_da my_drop
    table_set_default send_frame my_drop

Add both sets of entries below:

    table_add ipv4_da_lpm set_l2ptr 10.1.0.1/32 => 58
    table_add mac_da set_bd_dmac_intf 58 => 9 02:13:57:ab:cd:ef 2
    table_add send_frame rewrite_mac 9 => 00:11:22:33:44:55

    table_add ipv4_da_lpm set_l2ptr 10.1.0.200/32 => 58
    table_add mac_da set_bd_dmac_intf 81 => 15 08:de:ad:be:ef:00 4
    table_add send_frame rewrite_mac 15 => ca:fe:ba:be:d0:0d

WARNING: With 2017-Apr-06 version of p4c-bm2-ss and simple_switch, the
counter_read commands below fail for demo2.p4_16.p4.  I have filed an
issue on Github for this.

You can examine counter values in the counter named ipv4_da_lpm_stats
using the `counter_read` command, which takes the counter name and a
handle id.  Because ipv4_da_lpm_stats is declared `direct` on table
ipv4_da_lpm, and thus contains one entry for every one in ipv4_da_lpm,
use the handle id for the corresponding ipv4_da_lpm table entry that
you want stats for.

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

    sudo scapy

    fwd_pkt1=Ether() / IP(dst='10.1.0.1') / TCP(sport=5793, dport=80)
    drop_pkt1=Ether() / IP(dst='10.1.0.34') / TCP(sport=5793, dport=80)

    # Send packet at layer2, specifying interface
    sendp(fwd_pkt1, iface="veth2")
    sendp(drop_pkt1, iface="veth2")

    fwd_pkt2=Ether() / IP(dst='10.1.0.1') / TCP(sport=5793, dport=80) / Raw('The quick brown fox jumped over the lazy dog.')
    sendp(fwd_pkt2, iface="veth2")

----------------------------------------
