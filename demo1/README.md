# Compiling

See [README-using-bmv2.md](../README-using-bmv2.md) for some things
that are common across different P4 programs executed using bmv2.

To compile the P4_16 version of the code:

    p4c --target bmv2 --arch v1model demo1.p4_16.p4
                                     ^^^^^^^^^^^^^^ source code

Running that command will create these files:

    demo1.p4_16.p4i - the output of running only the preprocessor on
        the P4 source program.
    demo1.p4_16.json - the JSON file format expected by BMv2
        behavioral model `simple_switch`.

Only the file with the `.json` suffix is needed to run your P4 program
using the `simple_switch` command.  You can ignore the file with
suffix `.p4i` unless you suspect that the preprocessor is doing
something unexpected with your program.

To compile the P4_14 version of the code:

    p4c --std p4-14 --target bmv2 --arch v1model demo1.p4_14.p4
                                                 ^^^^^^^^^^^^^^ source code
        ^^^^^^^^^^^ specify P4_14 source code

The .dot and .png files in the subdirectory 'graphs' were created with
the p4c-graphs program, which is also installed when you build and
install p4c-bm2-ss:

     p4c-graphs -I $HOME/p4c/p4include demo1.p4_16.p4

The '-I' option is only necessary if you did _not_ install the P4
compiler in your system-wide /usr/local/bin directory.


# Running

To run the behavioral model with 8 ports numbered 0 through 7:

    sudo simple_switch --log-console -i 0@veth2 -i 1@veth4 -i 2@veth6 -i 3@veth8 -i 4@veth10 -i 5@veth12 -i 6@veth14 -i 7@veth16 demo1.p4_16.json

To get the log to go to a file instead of the console:

    sudo simple_switch --log-file ss-log --log-flush -i 0@veth2 -i 1@veth4 -i 2@veth6 -i 3@veth8 -i 4@veth10 -i 5@veth12 -i 6@veth14 -i 7@veth16 demo1.p4_16.json

CHECK THIS: If you see "Add port operation failed" messages in the
output of the simple_switch command, it means that one or more of the
virtual Ethernet interfaces veth2, veth4, etc. have not been created
on your system.  Search for "veth" in the file README-using-bmv2.txt
(top level directory of this repository) for a command to create them.

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

    # Version with dotted decimal IPv4 address and : separators inside
    # of hexadecimal Ethernet addresses.
    table_add ipv4_da_lpm set_l2ptr 10.1.0.200/32 => 81
    table_add mac_da set_bd_dmac_intf 81 => 15 08:de:ad:be:ef:00 4
    table_add send_frame rewrite_mac 15 => ca:fe:ba:be:d0:0d

    # Version with hex values instead of the above versions.
    # Note: the prefix length after the / character must be decimal.
    # I tried 0x20 and simple_switch_CLI raised an exception and
    # exited.
    table_add ipv4_da_lpm set_l2ptr 0x0a0100c8/32 => 0x51
    table_add mac_da set_bd_dmac_intf 0x51 => 0xf 0x08deadbeef00 0x4
    table_add send_frame rewrite_mac 0xf => 0xcafebabed00d

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


# Patterns

The example table entries and sample packet given above can be
generalized to the following pattern.

If you send an input packet like this, specified as Python code when
using the Scapy library:

    input port: anything
    Ether() / IP(dst=<hdr.ipv4.dstAddr>, ttl=<ttl>)

and you create the following table entries:

    table_add ipv4_da_lpm set_l2ptr <hdr.ipv4.dstAddr>/32 => <l2ptr>
    table_add mac_da set_bd_dmac_intf <l2ptr> => <out_bd> <dmac> <out_intf>
    table_add send_frame rewrite_mac <out_bd> => <smac>

then the P4 program should produce an output packet like the one
below, matching the input packet in every way except, except for the
fields explicitly mentioned:

    output port: <out_intf>
    Ether(src=<smac>, dst=<dmac>) / IP(dst=<hdr.ipv4.dstAddr>, ttl=<ttl>-1)
