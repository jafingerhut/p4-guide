# Compiling

See README-using-bmv2.txt for some things that are common across
different P4 programs executed using bmv2.

To compile the P4_16 version of the code:

    p4c-bm2-ss checksum-ipv4-with-options.p4 -o checksum-ipv4-with-options.json


# Running

To run the behavioral model with 8 ports numbered 0 through 7:

    sudo simple_switch --log-console -i 0@veth2 -i 1@veth4 -i 2@veth6 -i 3@veth8 -i 4@veth10 -i 5@veth12 -i 6@veth14 -i 7@veth16 checksum-ipv4-with-options.json


No table entries need to be added for the default action 'foo' to be
run on all packets.


----------------------------------------------------------------------
scapy session for sending packets
----------------------------------------------------------------------
We must run scapy as root for it to have permission to send packets on
veth interfaces.

I found a working example of using Scapy 
http://allievi.sssup.it/techblog/archives/631

    sudo scapy

    fwd_pkt1=Ether() / IP(dst='10.1.0.1') / TCP(sport=5793, dport=80)
    pkt_with_opts=Ether() / IP(dst='10.1.0.1', options=IPOption('\x83\x03\x10')) / TCP(sport=5792, dport=80)

    # Send packet at layer2, specifying interface
    sendp(fwd_pkt1, iface="veth2")
    sendp(pkt_with_opts, iface="veth2")

----------------------------------------
