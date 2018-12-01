# Test input packets constructed using Scapy

```python
from scapy import all
p0=Ether() / IPv6() / IPv6ExtHdrRouting() / UDP()
p1=Ether() / IPv6() / IPv6ExtHdrRouting(addresses=['f002::1']) / UDP()
p2=Ether() / IPv6() / IPv6ExtHdrRouting(addresses=['f002::1', 'f002::2']) / UDP()
p3=Ether() / IPv6() / IPv6ExtHdrRouting(addresses=['f002::1', 'f002::2', 'f002::3']) / UDP()
p4=Ether() / IPv6() / IPv6ExtHdrRouting(addresses=['f002::1', 'f002::2', 'f002::3', 'f002::4']) / UDP()
p5=Ether() / IPv6() / IPv6ExtHdrRouting(addresses=['f002::1', 'f002::2', 'f002::3', 'f002::4', 'f002::5']) / UDP()
p8=Ether() / IPv6() / IPv6ExtHdrRouting(addresses=['f002::1', 'f002::2', 'f002::3', 'f002::4', 'f002::5', 'f002::6', 'f002::7', 'f002::8']) / UDP()
p9=Ether() / IPv6() / IPv6ExtHdrRouting(addresses=['f002::1', 'f002::2', 'f002::3', 'f002::4', 'f002::5', 'f002::6', 'f002::7', 'f002::8', 'f002::9']) / UDP()
sendp(p0, iface='veth2')
```


## Notes on verifying the contents of packets that Scapy creates

Tested using Scapy version 2.2.0 installed on an Ubuntu 16.04 Linux
system:

```python
>>> from scapy import all
>>> IPv6ExtHdrRouting()
<IPv6ExtHdrRouting  |>
>>> p1=Ether() / IPv6() / IPv6ExtHdrRouting() / UDP()
>>> p1
<Ether  type=0x86dd |<IPv6  nh=Routing Header |<IPv6ExtHdrRouting  nh=UDP |<UDP  |>>>>
>>> str(p1)
'\xff\xff\xff\xff\xff\xff\x00\x00\x00\x00\x00\x00\x86\xdd`\x00\x00\x00\x00\x10+@\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x11\x00\x00\x00\x00\x00\x00\x00\x005\x005\x00\x08\xffr'

>>> def str_to_hex(s):
...     return ''.join(map(lambda x: '%02x' % (ord(x)), s))
>>> str_to_hex(str(p1))
'ffffffffffff00000000000086dd6000000000102b4000000000000000000000000000000001000000000000000000000000000000011100000000000000003500350008ff72'
```

Below I break apart the hex string for the full packet from above into
pieces for each of the headers, and identify the values of several
fields.  This packet's IPv6 Routing extension header contains 0 IPv6
addresses.

```
Ether() (14 bytes)
ffffffffffff00000000000086dd

IPv6() (40 bytes)
6000000000102b40 version=6  payload_length=0x10=16  next_header=0x2b=43  hop_limit=0x40=64
0000000000000000
0000000000000001
0000000000000000
0000000000000001

IPv6ExtHdrRouting() (8 bytes)
1100000000000000  NextHeader=17 for UDP, all other fields 0

UDP() (8 bytes)
003500350008ff72
```

Below we use the `addresses` optional keyword arg for the
`IPv6ExtHdrRouting` constructor, to specify a list of 2 IPv6
addresses.

```python
>>> p2=Ether() / IPv6() / IPv6ExtHdrRouting(addresses=['f002::1', 'f002::2']) / UDP()
>>> str_to_hex(str(p2))
'ffffffffffff00000000000086dd6000000000302b4000000000000000000000000000000001000000000000000000000000000000011104000200000000f0020000000000000000000000000001f00200000000000000000000000000020035003500080f6f'
```

And again, below I break apart the hex string for the full packet from
above into pieces for each of the headers, and identify the values of
several fields.  This packet's IPv6 Routing extension header contains
2 IPv6 addresses.

```
Ether() (14 bytes)
ffffffffffff00000000000086dd

IPv6() (40 bytes)
6000000000302b40 version=6  payload_length=0x30=48  next_header=0x2b=43  hop_limit=0x40=64
0000000000000000
0000000000000001
0000000000000000
0000000000000001

IPv6ExtHdrRouting() (8 bytes)
1100000000000000  NextHeader=17 for UDP, all other fields 0

1104000200000000 next_header=0x11=17 for UDP, hdr_ext_len=4 for length (4+1)*8=40 bytes, routing_type=0, segments_left=2, last_entry=0, flags=0, tag=0
f002000000000000 seg[0] address=f002::1
0000000000000001
f002000000000000 seg[1] address=f002::2
0000000000000002

UDP() (8 bytes)
0035003500080f6f
```
