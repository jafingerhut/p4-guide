See README-using-bmv2.txt for some things that are common across
different P4 programs executed using bmv2.

Useful for quickly creating multiple terminal windows and tabs:

    create-terminal-windows.sh

To compile the P4_14 version of the code:

    p4c-bmv2 --json demo4.p4_14.json demo4.p4_14.p4

To compile the P4_16 version of the code:

    p4c-bm2-ss -o demo4.p4_16.json demo4.p4_16.p4

The .dot and .png files were created with p4-graphs program, installed
from of the https://github.com/p4lang/p4-hlir repository, using this
command:

     p4-graphs demo4.p4_14.p4

To run behavioral model with 3 ports 1, 2, 3:

    # Note: I have tried running simple_switch on an Ubuntu 14 VM
    # using a .json file that was mounted via SSHFS.  It fails to read
    # such a file.  Workaround: Copy the .json file to a directory on
    # a local file system.  p4c-bmv2 and simple_switch_CLI do not have
    # this limitation.

    sudo simple_switch --log-console -i 0@veth2 -i 1@veth4 -i 2@veth6 -i 3@veth8 -i 4@veth10 -i 5@veth12 -i 6@veth14 -i 7@veth16 demo4.p4_14.json

To run CLI for controlling and examining simple_switch's table
contents:

    simple_switch_CLI

General syntax for table_add commands at simple_switch_CLI prompt:

    RuntimeCmd: help table_add
    Add entry to a match table: table_add <table name> <action name> <match fields> => <action parameters> [priority]

----------------------------------------------------------------------
simple_switch_CLI commands for demo4 program
----------------------------------------------------------------------

All of these, except for the counter-specific ones, also work for
demo1.

    # These should be unnecessary for P4_16 program, which defines
    # these default actions with default_action assignments in its
    # table definitions.
    table_set_default compute_ipv4_hashes compute_lkp_ipv4_hash
    table_set_default ipv4_da_lpm my_drop
    table_set_default mac_da my_drop
    table_set_default send_frame my_drop

Add both sets of entries below:

    table_add ipv4_da_lpm set_l2ptr 10.1.0.1/32 => 58
    table_add mac_da set_bd_dmac_intf 58 => 9 02:13:57:ab:cd:ef 2
    table_add send_frame rewrite_mac 9 => 00:11:22:33:44:55

    table_add ipv4_da_lpm set_l2ptr 10.1.0.200/32 => 81
    table_add mac_da set_bd_dmac_intf 81 => 15 08:de:ad:be:ef:00 1
    table_add send_frame rewrite_mac 15 => ca:fe:ba:be:d0:0d

    # For P4_16 program, set_l2ptr action name for table ipv4_da_lpm
    # is changed to set_l2ptr_with_stat.

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

    sudo scapy

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

----------------------------------------
