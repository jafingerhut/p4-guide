This directory contains a few Pcap files that each have one packet in
them, with the following sequence of headers:

+ 14-byte Ethernet (no 802.1q VLAN tag header)
+ 20-byte IPv4 (no options)
+ TCP header, some with options, some without, depending upon the file

Below is the output of the command `tshark -V -r filename.pcap` on
each of these files.  The last part of this output shows the detailed
contents of the TCP header, and what TCP options the packet contains,
if any.

See [this README file](/README-scapy.md), in particular the parts
showing how to use the Scapy `rdpcap` function, for reading these
files into a Python program, and either send them as-is into a running
`simple_switch` process, or manipulate them in other ways using the
Scapy library.


# one-tcp-pkt1-mss-sackperm-ts-nop-winscale-options.pcap

```bash
$ tshark -V -r one-tcp-pkt1-mss-sackperm-ts-nop-winscale-options.pcap
Frame 1: 74 bytes on wire (592 bits), 74 bytes captured (592 bits)
    Encapsulation type: Ethernet (1)
    Arrival Time: Feb 17, 2020 23:05:41.848838000 PST
    [Time shift for this packet: 0.000000000 seconds]
    Epoch Time: 1582009541.848838000 seconds
    [Time delta from previous captured frame: 0.000000000 seconds]
    [Time delta from previous displayed frame: 0.000000000 seconds]
    [Time since reference or first frame: 0.000000000 seconds]
    Frame Number: 1
    Frame Length: 74 bytes (592 bits)
    Capture Length: 74 bytes (592 bits)
    [Frame is marked: False]
    [Frame is ignored: False]
    [Protocols in frame: eth:ethertype:ip:tcp]
Ethernet II, Src: PcsCompu_32:93:7c (08:00:27:32:93:7c), Dst: RealtekU_12:35:02 (52:54:00:12:35:02)
    Destination: RealtekU_12:35:02 (52:54:00:12:35:02)
        Address: RealtekU_12:35:02 (52:54:00:12:35:02)
        .... ..1. .... .... .... .... = LG bit: Locally administered address (this is NOT the factory default)
        .... ...0 .... .... .... .... = IG bit: Individual address (unicast)
    Source: PcsCompu_32:93:7c (08:00:27:32:93:7c)
        Address: PcsCompu_32:93:7c (08:00:27:32:93:7c)
        .... ..0. .... .... .... .... = LG bit: Globally unique address (factory default)
        .... ...0 .... .... .... .... = IG bit: Individual address (unicast)
    Type: IPv4 (0x0800)
Internet Protocol Version 4, Src: 10.0.2.15, Dst: 99.84.232.30
    0100 .... = Version: 4
    .... 0101 = Header Length: 20 bytes (5)
    Differentiated Services Field: 0x00 (DSCP: CS0, ECN: Not-ECT)
        0000 00.. = Differentiated Services Codepoint: Default (0)
        .... ..00 = Explicit Congestion Notification: Not ECN-Capable Transport (0)
    Total Length: 60
    Identification: 0x875c (34652)
    Flags: 0x4000, Don't fragment
        0... .... .... .... = Reserved bit: Not set
        .1.. .... .... .... = Don't fragment: Set
        ..0. .... .... .... = More fragments: Not set
        ...0 0000 0000 0000 = Fragment offset: 0
    Time to live: 64
    Protocol: TCP (6)
    Header checksum: 0x5bde [validation disabled]
    [Header checksum status: Unverified]
    Source: 10.0.2.15
    Destination: 99.84.232.30
Transmission Control Protocol, Src Port: 35388, Dst Port: 443, Seq: 0, Len: 0
    Source Port: 35388
    Destination Port: 443
    [Stream index: 0]
    [TCP Segment Len: 0]
    Sequence number: 0    (relative sequence number)
    [Next sequence number: 0    (relative sequence number)]
    Acknowledgment number: 0
    1010 .... = Header Length: 40 bytes (10)
    Flags: 0x002 (SYN)
        000. .... .... = Reserved: Not set
        ...0 .... .... = Nonce: Not set
        .... 0... .... = Congestion Window Reduced (CWR): Not set
        .... .0.. .... = ECN-Echo: Not set
        .... ..0. .... = Urgent: Not set
        .... ...0 .... = Acknowledgment: Not set
        .... .... 0... = Push: Not set
        .... .... .0.. = Reset: Not set
        .... .... ..1. = Syn: Set
            [Expert Info (Chat/Sequence): Connection establish request (SYN): server port 443]
                [Connection establish request (SYN): server port 443]
                [Severity level: Chat]
                [Group: Sequence]
        .... .... ...0 = Fin: Not set
        [TCP Flags: ··········S·]
    Window size value: 64240
    [Calculated window size: 64240]
    Checksum: 0x57b0 [unverified]
    [Checksum Status: Unverified]
    Urgent pointer: 0
    Options: (20 bytes), Maximum segment size, SACK permitted, Timestamps, No-Operation (NOP), Window scale
        TCP Option - Maximum segment size: 1460 bytes
            Kind: Maximum Segment Size (2)
            Length: 4
            MSS Value: 1460
        TCP Option - SACK permitted
            Kind: SACK Permitted (4)
            Length: 2
        TCP Option - Timestamps: TSval 1795426846, TSecr 0
            Kind: Time Stamp Option (8)
            Length: 10
            Timestamp value: 1795426846
            Timestamp echo reply: 0
        TCP Option - No-Operation (NOP)
            Kind: No-Operation (1)
        TCP Option - Window scale: 7 (multiply by 128)
            Kind: Window Scale (3)
            Length: 3
            Shift count: 7
            [Multiplier: 128]
    [Timestamps]
        [Time since first frame in this TCP stream: 0.000000000 seconds]
        [Time since previous frame in this TCP stream: 0.000000000 seconds]
```

# one-tcp-pkt2-mss-option-only.pcap

```bash
$ tshark -V -r one-tcp-pkt2-mss-option-only.pcap
Frame 1: 60 bytes on wire (480 bits), 60 bytes captured (480 bits)
    Encapsulation type: Ethernet (1)
    Arrival Time: Feb 17, 2020 23:05:41.877022000 PST
    [Time shift for this packet: 0.000000000 seconds]
    Epoch Time: 1582009541.877022000 seconds
    [Time delta from previous captured frame: 0.000000000 seconds]
    [Time delta from previous displayed frame: 0.000000000 seconds]
    [Time since reference or first frame: 0.000000000 seconds]
    Frame Number: 1
    Frame Length: 60 bytes (480 bits)
    Capture Length: 60 bytes (480 bits)
    [Frame is marked: False]
    [Frame is ignored: False]
    [Protocols in frame: eth:ethertype:ip:tcp]
Ethernet II, Src: RealtekU_12:35:02 (52:54:00:12:35:02), Dst: PcsCompu_32:93:7c (08:00:27:32:93:7c)
    Destination: PcsCompu_32:93:7c (08:00:27:32:93:7c)
        Address: PcsCompu_32:93:7c (08:00:27:32:93:7c)
        .... ..0. .... .... .... .... = LG bit: Globally unique address (factory default)
        .... ...0 .... .... .... .... = IG bit: Individual address (unicast)
    Source: RealtekU_12:35:02 (52:54:00:12:35:02)
        Address: RealtekU_12:35:02 (52:54:00:12:35:02)
        .... ..1. .... .... .... .... = LG bit: Locally administered address (this is NOT the factory default)
        .... ...0 .... .... .... .... = IG bit: Individual address (unicast)
    Type: IPv4 (0x0800)
    Padding: 0000
Internet Protocol Version 4, Src: 99.84.232.30, Dst: 10.0.2.15
    0100 .... = Version: 4
    .... 0101 = Header Length: 20 bytes (5)
    Differentiated Services Field: 0x00 (DSCP: CS0, ECN: Not-ECT)
        0000 00.. = Differentiated Services Codepoint: Default (0)
        .... ..00 = Explicit Congestion Notification: Not ECN-Capable Transport (0)
    Total Length: 44
    Identification: 0x0921 (2337)
    Flags: 0x0000
        0... .... .... .... = Reserved bit: Not set
        .0.. .... .... .... = Don't fragment: Not set
        ..0. .... .... .... = More fragments: Not set
        ...0 0000 0000 0000 = Fragment offset: 0
    Time to live: 64
    Protocol: TCP (6)
    Header checksum: 0x1a2a [validation disabled]
    [Header checksum status: Unverified]
    Source: 99.84.232.30
    Destination: 10.0.2.15
Transmission Control Protocol, Src Port: 443, Dst Port: 35388, Seq: 0, Ack: 1, Len: 0
    Source Port: 443
    Destination Port: 35388
    [Stream index: 0]
    [TCP Segment Len: 0]
    Sequence number: 0    (relative sequence number)
    [Next sequence number: 0    (relative sequence number)]
    Acknowledgment number: 1    (relative ack number)
    0110 .... = Header Length: 24 bytes (6)
    Flags: 0x012 (SYN, ACK)
        000. .... .... = Reserved: Not set
        ...0 .... .... = Nonce: Not set
        .... 0... .... = Congestion Window Reduced (CWR): Not set
        .... .0.. .... = ECN-Echo: Not set
        .... ..0. .... = Urgent: Not set
        .... ...1 .... = Acknowledgment: Set
        .... .... 0... = Push: Not set
        .... .... .0.. = Reset: Not set
        .... .... ..1. = Syn: Set
            [Expert Info (Chat/Sequence): Connection establish acknowledge (SYN+ACK): server port 443]
                [Connection establish acknowledge (SYN+ACK): server port 443]
                [Severity level: Chat]
                [Group: Sequence]
        .... .... ...0 = Fin: Not set
        [TCP Flags: ·······A··S·]
    Window size value: 65535
    [Calculated window size: 65535]
    Checksum: 0x3748 [unverified]
    [Checksum Status: Unverified]
    Urgent pointer: 0
    Options: (4 bytes), Maximum segment size
        TCP Option - Maximum segment size: 1460 bytes
            Kind: Maximum Segment Size (2)
            Length: 4
            MSS Value: 1460
    [Timestamps]
        [Time since first frame in this TCP stream: 0.000000000 seconds]
        [Time since previous frame in this TCP stream: 0.000000000 seconds]
```

# one-tcp-pkt3-no-options.pcap

```bash
$ tshark -V -r one-tcp-pkt3-no-options.pcap
Frame 1: 54 bytes on wire (432 bits), 54 bytes captured (432 bits)
    Encapsulation type: Ethernet (1)
    Arrival Time: Feb 17, 2020 23:05:43.788326000 PST
    [Time shift for this packet: 0.000000000 seconds]
    Epoch Time: 1582009543.788326000 seconds
    [Time delta from previous captured frame: 0.000000000 seconds]
    [Time delta from previous displayed frame: 0.000000000 seconds]
    [Time since reference or first frame: 0.000000000 seconds]
    Frame Number: 1
    Frame Length: 54 bytes (432 bits)
    Capture Length: 54 bytes (432 bits)
    [Frame is marked: False]
    [Frame is ignored: False]
    [Protocols in frame: eth:ethertype:ip:tcp]
Ethernet II, Src: PcsCompu_32:93:7c (08:00:27:32:93:7c), Dst: RealtekU_12:35:02 (52:54:00:12:35:02)
    Destination: RealtekU_12:35:02 (52:54:00:12:35:02)
        Address: RealtekU_12:35:02 (52:54:00:12:35:02)
        .... ..1. .... .... .... .... = LG bit: Locally administered address (this is NOT the factory default)
        .... ...0 .... .... .... .... = IG bit: Individual address (unicast)
    Source: PcsCompu_32:93:7c (08:00:27:32:93:7c)
        Address: PcsCompu_32:93:7c (08:00:27:32:93:7c)
        .... ..0. .... .... .... .... = LG bit: Globally unique address (factory default)
        .... ...0 .... .... .... .... = IG bit: Individual address (unicast)
    Type: IPv4 (0x0800)
Internet Protocol Version 4, Src: 10.0.2.15, Dst: 99.84.232.95
    0100 .... = Version: 4
    .... 0101 = Header Length: 20 bytes (5)
    Differentiated Services Field: 0x00 (DSCP: CS0, ECN: Not-ECT)
        0000 00.. = Differentiated Services Codepoint: Default (0)
        .... ..00 = Explicit Congestion Notification: Not ECN-Capable Transport (0)
    Total Length: 40
    Identification: 0x1e19 (7705)
    Flags: 0x4000, Don't fragment
        0... .... .... .... = Reserved bit: Not set
        .1.. .... .... .... = Don't fragment: Set
        ..0. .... .... .... = More fragments: Not set
        ...0 0000 0000 0000 = Fragment offset: 0
    Time to live: 64
    Protocol: TCP (6)
    Header checksum: 0xc4f4 [validation disabled]
    [Header checksum status: Unverified]
    Source: 10.0.2.15
    Destination: 99.84.232.95
Transmission Control Protocol, Src Port: 54550, Dst Port: 443, Seq: 1, Ack: 1, Len: 0
    Source Port: 54550
    Destination Port: 443
    [Stream index: 0]
    [TCP Segment Len: 0]
    Sequence number: 1    (relative sequence number)
    [Next sequence number: 1    (relative sequence number)]
    Acknowledgment number: 1    (relative ack number)
    0101 .... = Header Length: 20 bytes (5)
    Flags: 0x010 (ACK)
        000. .... .... = Reserved: Not set
        ...0 .... .... = Nonce: Not set
        .... 0... .... = Congestion Window Reduced (CWR): Not set
        .... .0.. .... = ECN-Echo: Not set
        .... ..0. .... = Urgent: Not set
        .... ...1 .... = Acknowledgment: Set
        .... .... 0... = Push: Not set
        .... .... .0.. = Reset: Not set
        .... .... ..0. = Syn: Not set
        .... .... ...0 = Fin: Not set
        [TCP Flags: ·······A····]
    Window size value: 64240
    [Calculated window size: 64240]
    [Window size scaling factor: -1 (unknown)]
    Checksum: 0x57dd [unverified]
    [Checksum Status: Unverified]
    Urgent pointer: 0
    [Timestamps]
        [Time since first frame in this TCP stream: 0.000000000 seconds]
        [Time since previous frame in this TCP stream: 0.000000000 seconds]
```
