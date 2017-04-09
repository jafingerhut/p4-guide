See README-using-bmv2.txt for some things that are common across
different P4 programs executed using bmv2.

Useful for quickly creating multiple terminal windows and tabs:

    create-terminal-windows.sh

To compile the P4_14 version of the code:

    p4c-bmv2 --json demo1.p4_14.json demo1.p4_14.p4
                                     ^^^^^^^^^^^^^ source code
                    ^^^^^^^^^^^^^^^^ compiled output

To compile the P4_16 version of the code:

    p4c-bm2-ss -o demo1.p4_16.json demo1.p4_16.p4
                                   ^^^^^^^^^^^^^ source code
                  ^^^^^^^^^^^^^^^^ compiled output

To run behavioral model with 3 ports 1, 2, 3:

    # Note: I have tried running simple_switch on an Ubuntu 14 VM
    # using a .json file that was mounted via SSHFS.  It fails to read
    # such a file.  Workaround: Copy the .json file to a directory on
    # a local file system.  p4c-bmv2 and simple_switch_CLI do not have
    # this limitation.

    sudo simple_switch --log-console -i 0@veth2 -i 1@veth4 -i 2@veth6 -i 3@veth8 -i 4@veth10 -i 5@veth12 -i 6@veth14 -i 7@veth16 demo1.p4_14.json

To run CLI for controlling and examining simple_switch's table
contents:

    simple_switch_CLI

General syntax for table_add commands at simple_switch_CLI prompt:

    RuntimeCmd: help table_add
    Add entry to a match table: table_add <table name> <action name> <match fields> => <action parameters> [priority]

----------------------------------------------------------------------
demo1.p4_14.p4 or demo1.p4_16.p4 (same commands work for both)
----------------------------------------------------------------------

    table_set_default ipv4_da_lpm my_drop
    table_set_default mac_da my_drop
    table_set_default send_frame my_drop

    table_add ipv4_da_lpm set_l2ptr 10.1.0.1/32 => 58
    table_add mac_da set_bd_dmac_intf 58 => 9 02:13:57:ab:cd:ef 2
    table_add send_frame rewrite_mac 9 => 00:11:22:33:44:55

Another set of table entries to forward packets to a different output
interface:

    table_add ipv4_da_lpm set_l2ptr 10.1.0.200/32 => 81
    table_add mac_da set_bd_dmac_intf 81 => 15 08:de:ad:be:ef:00 4
    table_add send_frame rewrite_mac 15 => ca:fe:ba:be:d0:0d

You can examine the existing entries in a table with 'table_dump':

    table_dump ipv4_da_lpm
    ==========
    TABLE ENTRIES
    **********
    Dumping entry 0x0
    Match key:
    * ipv4.dstAddr        : LPM       0a010001/32
    Action entry: set_l2ptr - 3a
    **********
    Dumping entry 0x1
    Match key:
    * ipv4.dstAddr        : LPM       0a0100c8/32
    Action entry: set_l2ptr - 3a
    ==========
    Dumping default entry
    Action entry: my_drop - 
    ==========

The numbers on the "Dumping entry <number>" lines are 'table entry
handle ids'.  The table API implementation allocates a unique handle
id when adding a new entry, and you must provide that value to delete
the table entry.  The handle id is unique per entry, as long as the
entry remains in the table.  After removing an entry, its handle id
may be reused for a future entry added to the table.

Handle ids are _not_ unique across all tables.  Only the pair
<table,handle_id> is unique.


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
