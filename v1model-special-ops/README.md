# Introduction

The program v1model-special-ops.p4 demonstrates the use of resubmit
and recirculate operations in the BMV2 simple_switch's implementation
of P4_16's v1model architecture.  It doesn't do anything fancy with
these features, but at least it shows how to distinguish whether a
packet being processed in the ingress control block is the result of a
resubmit or recirculate option, vs. a new packet received from an
ingress port.

It also demonstrates "debug tables", which are in the program only
because when you use the `--log-console` or `--log-file` command line
options to the `simple_switch` command, when those tables are applied,
the log output shows the values of all fields in the key of those
tables.  Thus they are effectively 'debug print' commands.  The tables
have only `NoAction` as an action, so can never modify the packet or
its metadata.

Note that such debug tables are likely to be useless when compiling to
a hardware target.  Worse than useless, they might cause the program
to be larger or more complex in ways that it will not "fit" into the
target when the debug table(s) are present, even though the program
does fit when they are left out.  If you find them useful for
developing P4 programs, you can consider surrounding them with C
preprocessor `#ifdef` directives so that they can easily be included
or left out with a one line change (or perhaps a compiler command line
option).

I tested this program with a few table entries and test packets
described below, and the resulting log output from `simple_switch` for
a packet that was resubmitted is in the file `resub-pkt-log.txt`, and
for a recirculated packet in `recirc-pkt-log.txt`.

I used these versions of the p4lang/behavioral-model and p4lang/p4c
repositories in my testing:

+ p4lang/behavioral-model - git commit
  13370aaf9329fcb369a3ea3989722eb5f61c07f3 dated Aug 16 2018
+ p4lang/p4c - git commit c534c585f8faba3e10af5776d5538c8a4374b8a6
  dated Aug 31 2018

I believe there might be a way to pass parameters to the
`recirculate()` and `resubmit()` P4_16 operations that might actually
cause some additional metadata field values to be preserved across the
resubmit or recirculate options, but if so, I have not found the way
to do that yet.


# Compiling

See [README-using-bmv2.md](../README-using-bmv2.md) for some things
that are common across different P4 programs executed using bmv2.

To compile the P4_16 version of the code (which is the only version):

    p4c --target bmv2 --arch v1model v1model-special-ops.p4
                                     ^^^^^^^^^^^^^^^^^^^^^^ source code

Running that command will create these files:

    v1model-special-ops.p4i - the output of running only the preprocessor on
        the P4 source program.
    v1model-special-ops.json - the JSON file format expected by BMv2
        behavioral model `simple_switch`.

Only the file with the `.json` suffix is needed to run your P4 program
using the `simple_switch` command.  You can ignore the file with
suffix `.p4i` unless you suspect that the preprocessor is doing
something unexpected with your program.

I have not attempted to create a corresponding P4_14 version of this
program.


# Running

To run the behavioral model with 8 ports numbered 0 through 7:

    sudo simple_switch --log-console -i 0@veth2 -i 1@veth4 -i 2@veth6 -i 3@veth8 -i 4@veth10 -i 5@veth12 -i 6@veth14 -i 7@veth16 v1model-special-ops.json

To get the log to go to a file instead of the console:

    sudo simple_switch --log-file ss-log --log-flush -i 0@veth2 -i 1@veth4 -i 2@veth6 -i 3@veth8 -i 4@veth10 -i 5@veth12 -i 6@veth14 -i 7@veth16 v1model-special-ops.json

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


    table_set_default ipv4_da_lpm my_drop
    table_set_default mac_da my_drop
    table_set_default send_frame my_drop
    table_add ipv4_da_lpm do_resubmit 10.1.0.101/32 => 10.1.0.1
    table_add ipv4_da_lpm do_recirculate 10.1.0.201/32 => 10.1.0.1
    table_add ipv4_da_lpm do_clone_i2e 10.3.0.55/32 => 10.5.0.99
    table_add ipv4_da_lpm set_l2ptr 10.1.0.1/32 => 58
    table_add mac_da set_bd_dmac_intf 58 => 9 02:13:57:ab:cd:ef 2
    table_add send_frame rewrite_mac 9 => 00:11:22:33:44:55
    mirroring_add 5 1

Note: 'mirroring_add 5 1' should cause a packet cloned to clone/mirror
session id 5 to be sent to output port 1.

----------------------------------------------------------------------
scapy session for sending packets
----------------------------------------------------------------------
Any process that you want to have permission to send and receive
packets on Ethernet interfaces (such as the veth virtual interfaces)
must run as the super-user root, hence the use of `sudo`:

```python
sudo scapy

fwd_pkt1=Ether() / IP(dst='10.1.0.1') / TCP(sport=5793, dport=80)
drop_pkt1=Ether() / IP(dst='10.1.0.34') / TCP(sport=5793, dport=80)
resub_pkt=Ether() / IP(dst='10.1.0.101') / TCP(sport=5793, dport=80)
recirc_pkt=Ether() / IP(dst='10.1.0.201') / TCP(sport=5793, dport=80)
clone_i2e_pkt=Ether() / IP(dst='10.3.0.55') / TCP(sport=5793, dport=80)

# Send packet at layer2, specifying interface
sendp(fwd_pkt1, iface="veth6")
sendp(drop_pkt1, iface="veth6")
sendp(resub_pkt, iface="veth6")
sendp(recirc_pkt, iface="veth6")
sendp(clone_i2e_pkt, iface="veth6")
```

----------------------------------------
