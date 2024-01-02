# Introduction

Some notes on using the Scapy library for generating and decoding
packet contents.  It covers only Python3, and Scapy version 2.5.0.

Historical note: The document named `README-scapy.md` that was here
until 2024-Jan-01 has been renamed
[`README-scapy-older.md`](README-scapy-older.md).  You are welcome to
read it if you are interested in older historical information related
to different versions of Scapy that were around in 2018-2021 time
frame, and some differences between Python2 and Python3 uses of the
Scapy library.


## Notes on installing Scapy

+ DO use `pip` or `pip3` to install the `scapy` package (instructions below)
+ DO NOT install the Ubuntu package `python3-scapy`
+ DO NOT use `pip` or `pip3` to install the `scapy-python3` package

On an Ubuntu Linux system (tested with versions 22.04, 20.04, 18.04,
and 16.04):

```bash
$ sudo apt-get install python3-pip
$ pip3 install scapy
```

With the commands above, it will install the Scapy package within your
`$HOME/.local` directory.

The official Scapy web site contains instructions for installing any
Scapy verson from source code.  I found the command below for
installing the latest development version of Scapy, if you like living
on the edge:

```
$ pip3 install --upgrade git+git://github.com/secdev/scapy
```


## Prerequisites

For all of the Python interactive sessions shown below, this Python
`import` statement was done first:

```python
from scapy.all import *
```


## Version combinations tested

+ Python3 with Scapy 2.5.0


## Create Scapy packet with IPv4 options, brief version

I found a working example of using Scapy to generate IPv4 headers with
IP options here: http://allievi.sssup.it/techblog/archives/631

```python
>>> pkt_with_opts=Ether(dst='00:00:00:00:00:05') / IP(dst='10.1.0.1', options=IPOption(b'\x83\x03\x10')) / TCP(sport=5792, dport=80)
>>> pkt_with_opts.show2()
###[ Ethernet ]### 
  dst       = 00:00:00:00:00:05
  src       = 08:00:27:25:3b:69
  type      = IPv4
###[ IP ]### 
     version   = 4
     ihl       = 6
     tos       = 0x0
     len       = 44
     id        = 1
     flags     = 
     frag      = 0
     ttl       = 64
     proto     = tcp
     chksum    = 0xd0b7
     src       = 10.0.2.15
     dst       = 10.1.0.1
     \options   \
      |###[ IP Option Loose Source and Record Route ]### 
      |  copy_flag = 1
      |  optclass  = control
      |  option    = loose_source_route
      |  length    = 3
      |  pointer   = 16
      |  routers   = []
      |###[ IP Option End of Options List ]### 
      |  copy_flag = 0
      |  optclass  = control
      |  option    = end_of_list
###[ TCP ]### 
        sport     = 5792
        dport     = http
        seq       = 0
        ack       = 0
        dataofs   = 5
        reserved  = 0
        flags     = S
        window    = 8192
        chksum    = 0x62e2
        urgptr    = 0
        options   = ''
```


## Create Scapy packet with IPv4 options, many details

This version works with all three versions I tested, and requires the
`b` before the argument to `IPOption` to work on all of them:

```python
>>> pkt_with_opts=Ether(dst='00:00:00:00:00:05') / IP(dst='10.1.0.1', options=IPOption(b'\x83\x03\x10')) / TCP(sport=5792, dport=80)

>>> bytes(pkt_with_opts)
b"\x00\x00\x00\x00\x00\x05\x08\x00'%;i\x08\x00F\x00\x00,\x00\x01\x00\x00@\x06\xd0\xb7\n\x00\x02\x0f\n\x01\x00\x01\x83\x03\x10\x00\x16\xa0\x00P\x00\x00\x00\x00\x00\x00\x00\x00P\x02 \x00b\xe2\x00\x00"
>>> len(bytes(pkt_with_opts))
58

>>> list(bytes(pkt_with_opts))
[0, 0, 0, 0, 0, 5, 8, 0, 39, 37, 59, 105, 8, 0, 70, 0, 0, 44, 0, 1, 0, 0, 64, 6, 208, 183, 10, 0, 2, 15, 10, 1, 0, 1, 131, 3, 16, 0, 22, 160, 0, 80, 0, 0, 0, 0, 0, 0, 0, 0, 80, 2, 32, 0, 98, 226, 0, 0]
```


## Convert Scapy packets to/from Python type `bytes`

```python
# Construct a packet as a Scapy object

>>> pkt1=Ether(dst='00:00:00:00:00:05') / IP(dst='10.1.0.1') / TCP(sport=5793, dport=80)
>>> type(pkt1)
<class 'scapy.layers.l2.Ether'>
>>> len(pkt1)
54

# Use bytes() constructor to convert it to type bytes

>>> pkt1b=bytes(pkt1)
>>> type(pkt1b)
<class 'bytes'>

>>> pkt1b
b"\x00\x00\x00\x00\x00\x05\x08\x00'%;i\x08\x00E\x00\x00(\x00\x01\x00\x00@\x06d\xbf\n\x00\x02\x0f\n\x01\x00\x01\x16\xa1\x00P\x00\x00\x00\x00\x00\x00\x00\x00P\x02 \x00b\xe1\x00\x00"

>>> len(pkt1b)
54

# Use Ether() constructor to convert bytes back to Scapy packet
>>> pkt1x=Ether(pkt1b)
>>> type(pkt1x)
<class 'scapy.layers.l2.Ether'>
>>> len(pkt1x)
54

# The converted to bytes, then back to Scapy pkt1x, is not equal to
# the original pkt1.  Why not?
>>> pkt1==pkt1x
False

# Their byte sequences are equal, so it must be some other attributes
# of the Scapy packet objects that are different.
>>> bytes(pkt1)==bytes(pkt1x)
True
>>> bytes(pkt1)==pkt1b
True

# The time attribute is different for them, which might explain why
# they are not equal.
>>> pkt1.time
1704172233.7114353
>>> pkt1x.time
1704172297.6892235
```


## Convert Scapy packets to/from strings of ASCII hex digits

This is similar to the previous section, except the strings are not an
entire 8-bit byte per character, but 2 ASCII hex digits per 8-bit
byte.  This is useful in multiple contexts, e.g. representing packet
contents in an STF file as part of an automated test of the p4c P4
compiler.

```python
>>> pkt1=Ether(src='00:11:22:33:44:55', dst='00:00:00:00:00:05') / IP(dst='10.1.0.1') / TCP(sport=5793, dport=80)

>>> def bytes_to_hex(b):
...     return ''.join(['%02x' % (x) for x in b])
... 

>>> bytes_to_hex(bytes(pkt1))
'00000000000500112233445508004500002800010000400664bf0a00020f0a01000116a1005000000000000000005002200062e10000'
```

Below shows how to convert from a string of hex digits (with optional
embedded space and tab characters, which will be ignored) to a Scapy
packet.

```python
>>> s1='0000 00000 0050 0112 233445508004        500002800010000400664bf0a00020f0a01000116a1005000000000000000005002200062e10000'

>>> import re
>>> def hex_to_bytes(hex_s):
...     tmp = re.sub('[ \t]', '', hex_s)
...     return bytes(bytearray.fromhex(tmp))
... 

>>> pkt2=Ether(hex_to_bytes(s1))
>>> bytes(pkt1)==bytes(pkt2)
True
```

Below are copies of the functions defined above, except without the
leading prompts on each line, to make it easier to copy and paste from
here into an interactive Python session.

```python
def bytes_to_hex(b):
    return ''.join(['%02x' % (x) for x in b])

import re
def hex_to_bytes(hex_s):
    tmp = re.sub('[ \t]', '', hex_s)
    return bytes(bytearray.fromhex(tmp))
```


## Writing Scapy packets to, and reading Scapy packets from, pcap files

```python
>>> pkt0=Ether(src='00:11:22:33:44:55', dst='00:00:00:00:00:05') / IP(dst='10.0.0.1') / TCP(sport=1, dport=8)
>>> pkt1=Ether(src='00:11:22:33:44:55', dst='00:00:00:00:00:05') / IP(dst='10.1.0.1') / TCP(sport=5793, dport=80)
>>> pkt2=Ether(src='00:11:22:33:44:55', dst='00:00:00:00:00:05') / IP(dst='10.2.0.2') / TCP(sport=65535, dport=443)
>>> wrpcap('some-pkts.pcap', [pkt0, pkt1, pkt2])

>>> pktlst=rdpcap('some-pkts.pcap')
>>> len(pktlst)
3
>>> pktlst
<some-pkts.pcap: TCP:3 UDP:0 ICMP:0 Other:0>
>>> pktlst[0]
<Ether  dst=00:00:00:00:00:05 src=00:11:22:33:44:55 type=IPv4 |<IP  version=4 ihl=5 tos=0x0 len=40 id=1 flags= frag=0 ttl=64 proto=tcp chksum=0x64c0 src=10.0.2.15 dst=10.0.0.1 |<TCP  sport=tcpmux dport=8 seq=0 ack=0 dataofs=5 reserved=0 flags=S window=8192 chksum=0x79ca urgptr=0 |>>>
>>> bytes(pkt0)==bytes(pktlst[0])
True
>>> bytes(pkt1)==bytes(pktlst[1])
True
>>> bytes(pkt2)==bytes(pktlst[2])
True
```


## Truncate a packet

This is a pretty straightforward application of the techniques in the
previous section.

```python
>>> pkt1=Ether(src='00:11:22:33:44:55', dst='00:00:00:00:00:05') / IP(dst='10.1.0.1') / TCP(sport=5793, dport=80)
>>> pkt1.show2()
###[ Ethernet ]### 
  dst       = 00:00:00:00:00:05
  src       = 00:11:22:33:44:55
  type      = IPv4
###[ IP ]### 
     version   = 4
     ihl       = 5
     tos       = 0x0
     len       = 40
     id        = 1
     flags     = 
     frag      = 0
     ttl       = 64
     proto     = tcp
     chksum    = 0x64bf
     src       = 10.0.2.15
     dst       = 10.1.0.1
     \options   \
###[ TCP ]### 
        sport     = 5793
        dport     = http
        seq       = 0
        ack       = 0
        dataofs   = 5
        reserved  = 0
        flags     = S
        window    = 8192
        chksum    = 0x62e1
        urgptr    = 0
        options   = ''

>>> len(pkt1)
54

# Create pkt2 with the same contents as pkt1, except the last byte is
# removed.
>>> pkt2=Ether(bytes(pkt1)[:-1])
>>> len(pkt2)
53
>>> pkt2.show2()
###[ Ethernet ]### 
  dst       = 00:00:00:00:00:05
  src       = 00:11:22:33:44:55
  type      = IPv4
###[ IP ]### 
     version   = 4
     ihl       = 5
     tos       = 0x0
     len       = 40
     id        = 1
     flags     = 
     frag      = 0
     ttl       = 64
     proto     = tcp
     chksum    = 0x64bf
     src       = 10.0.2.15
     dst       = 10.1.0.1
     \options   \
###[ Raw ]### 
        load      = '\x16\\xa1\x00P\x00\x00\x00\x00\x00\x00\x00\x00P\x02 \x00b\\xe1\x00'

>>> bytes(pkt1) == bytes(pkt2)
False
>>> bytes(pkt1)[0:53] == bytes(pkt2)
True
```


## Examining fields of a packet

```python
>>> pkt1=Ether(src='00:11:22:33:44:55', dst='00:00:00:00:00:05') / IP(dst='10.1.0.1') / TCP(sport=5793, dport=80)
>>> type(pkt1)
<class 'scapy.layers.l2.Ether'>
>>> type(pkt1[Ether])
<class 'scapy.layers.l2.Ether'>
>>> type(pkt1[IP])
<class 'scapy.layers.inet.IP'>
>>> type(pkt1[TCP])
<class 'scapy.layers.inet.TCP'>

>>> pkt1.fields_desc
[<DestMACField (Ether).dst>, <SourceMACField (Ether).src>, <XShortEnumField (Ether).type>]
>>> pkt1[Ether].fields_desc
[<DestMACField (Ether).dst>, <SourceMACField (Ether).src>, <XShortEnumField (Ether).type>]
>>> pkt1[IP].fields_desc
[<BitField (IP,IPerror,IPv46).version>, <BitField (IP,IPerror,IPv46).ihl>, <XByteField (IP,IPerror,IPv46).tos>, <ShortField (IP,IPerror,IPv46).len>, <ShortField (IP,IPerror,IPv46).id>, <FlagsField (IP,IPerror,IPv46).flags>, <BitField (IP,IPerror,IPv46).frag>, <ByteField (IP,IPerror,IPv46).ttl>, <ByteEnumField (IP,IPerror,IPv46).proto>, <XShortField (IP,IPerror,IPv46).chksum>, <scapy.fields.Emph object at 0x7fd08978c0c0>, <scapy.fields.Emph object at 0x7fd08978c1c0>, <PacketListField (IP,IPerror,IPv46).options>]
>>> pkt1[TCP].fields_desc
[<ShortEnumField (TCP,TCPerror).sport>, <ShortEnumField (TCP,TCPerror).dport>, <IntField (TCP,TCPerror).seq>, <IntField (TCP,TCPerror).ack>, <BitField (TCP,TCPerror).dataofs>, <BitField (TCP,TCPerror).reserved>, <FlagsField (TCP,TCPerror).flags>, <ShortField (TCP,TCPerror).window>, <XShortField (TCP,TCPerror).chksum>, <ShortField (TCP,TCPerror).urgptr>, <TCPOptionsField (TCP,TCPerror).options>]

# Get values of fields in Ether header
>>> pkt1[Ether].fields_desc
[<DestMACField (Ether).dst>, <SourceMACField (Ether).src>, <XShortEnumField (Ether).type>]
>>> pkt1[Ether].dst
'00:00:00:00:00:05'
>>> pkt1[Ether].src
'00:11:22:33:44:55'
>>> pkt1[Ether].type
2048
>>> type(pkt1[Ether].dst)
<class 'str'>
>>> type(pkt1[Ether].type)
<class 'int'>
```

Get values of fields in IP header.  Note that the packet is only
'partially built', meaning that some of the field values are `None`
(fields `ihl`, `len`, and `chksum` in this example).  The idea with
Scapy is that these fields are auto-calculated from other parts of the
packet on demand, just before doing things like `pkt1.show2()` or
`bytes(pkt1)`, which need those fields to be calculated.

See below for one way to get the calculated value of those fields.

```python
>>> pkt1[IP].fields_desc
[<BitField (IP,IPerror,IPv46).version>, <BitField (IP,IPerror,IPv46).ihl>, <XByteField (IP,IPerror,IPv46).tos>, <ShortField (IP,IPerror,IPv46).len>, <ShortField (IP,IPerror,IPv46).id>, <FlagsField (IP,IPerror,IPv46).flags>, <BitField (IP,IPerror,IPv46).frag>, <ByteField (IP,IPerror,IPv46).ttl>, <ByteEnumField (IP,IPerror,IPv46).proto>, <XShortField (IP,IPerror,IPv46).chksum>, <scapy.fields.Emph object at 0x7fd08978c0c0>, <scapy.fields.Emph object at 0x7fd08978c1c0>, <PacketListField (IP,IPerror,IPv46).options>]

>>> pkt1[IP].version
4
>>> pkt1[IP].ihl
>>> pkt1[IP].ihl == None
True
>>> pkt1[IP].tos
0
>>> pkt1[IP].len
>>> pkt1[IP].len == None
True
>>> pkt1[IP].id
1
>>> pkt1[IP].flags
<Flag 0 ()>
>>> pkt1[IP].frag
0
>>> pkt1[IP].ttl
64
>>> pkt1[IP].proto
6
>>> pkt1[IP].chksum
>>> pkt1[IP].chksum == None
True
>>> pkt1[IP].src
'10.0.2.15'
>>> type(pkt1[IP].src)
<class 'str'>
>>> pkt1[IP].dst
'10.1.0.1'
>>> pkt1[IP].options
[]
>>> type(pkt1[IP].options)
<class 'list'>
```

A straightforward way to get the values of these fields is to use
`bytes()` on the packet, which forces the packet to 'build',
calculating values for those fields, and then disssect it back into
fields by calling the `Ether()` constructor on the resulting bytes.

```
>>> pkt2=Ether(bytes(pkt1))
>>> pkt2[IP].chksum
25791
>>> pkt2[IP].len
40
>>> pkt2[IP].ihl
5
```


## Creating packets with incorrect values for auto-calculated fields

Here is one way to create a packet with an incorrect IPv4 header
checksum, without knowing in advance what the correct checksum is:
calculate the correct checksum, add 1 to it, then use that modified
value to construct another similar packet.

```python
>>> pkt1=Ether(src='00:11:22:33:44:55', dst='00:00:00:00:00:05') / IP(dst='10.1.0.1') / TCP(sport=5793, dport=80)
>>> pkt2=Ether(bytes(pkt1))

# pkt2 has calculated correct IPv4 header checksum
>>> pkt2[IP].chksum
25791
>>> pkt1[IP].chksum=pkt2[IP].chksum+1
>>> pkt1[IP].chksum
25792
>>> bytes(pkt2)==bytes(pkt1)
False
```


## Creating packets that are only slightly different than other packets

You can use the `copy()` method to create a duplicate of a Scapy
packet object, then modify the copy, and no changes will be made to
the original.

Note that if the original packet is 'partially built',
i.e. `pkt1[IP].chksum is None` is `true`, as shown in the transcript
below, then the same is true for the copy.  Any changes made to the
copy's fields before doing something like `bytes()` or `show2()` on it
will cause those modified field values to be included when the fields
with value `None` are auto-calculated.

```python
>>> pkt1=Ether(src='00:11:22:33:44:55', dst='00:00:00:00:00:05') / IP(dst='10.1.0.1') / TCP(sport=5793, dport=80)
>>> pkt2=pkt1.copy()
>>> pkt1[IP].chksum is None
True
>>> pkt2[IP].chksum is None
True
>>> pkt2[IP].ttl -= 1
>>> pkt1[IP].ttl
64
>>> pkt2[IP].ttl
63

# Auto-calculated checksums are different for pkt1 and pkt2, because
# they have different ttl field values.

>>> Ether(bytes(pkt1))[IP].chksum
25791
>>> Ether(bytes(pkt2))[IP].chksum
26047
```


## Some differences between Scapy 2.4 vs. earlier Scapy versions

Scapy 2.4 added a new function `raw()` which the Scapy developers
suggest using to convert packets to type `bytes`, rather than using
`str()` or `bytes()`, although it seems that perhaps `bytes()` still
works and returns the same value as `raw()`.

There are some Scapy packets that when you "build" them, i.e. take the
data structure representing the partially specified packet, and
convert them to a fully-specified sequence of bytes, Scapy tries to
access a network interface in order to gather more information to use
in deciding what value to use for packet fields.

If you are running as the super-user `root`, some packets can be
transmitted and received, and there is typically no exception raised
while doing so.

If you are running as a normal user, without super user privileges,
Scapy will execute some code that attempts to transmit a packet, and
an exception will be raised (at least with Scapy version 2.4.2 that I
tested with).  Below are sample outputs while running Python2/Python3
plus Scapy 2.4.2 as a normal user, in case you run across this issue.
As far as I can tell, Scapy still picks a default value for the field
in order to complete the construction of the packet.  It is the output
from exception being raised, and then I think internally caught inside
of Scapy itself, that is new in Scapy 2.4.x vs. at least some earlier
versions of Scapy that I have used.

Python3 with Scapy 2.5.0:

```python
>>> from scapy.all import *
>>> pkt=Ether() / IP(dst='10.1.0.1')
>>> raw(pkt)
WARNING: getmacbyip failed on [Errno 1] Operation not permitted
WARNING: Mac address to reach destination not found. Using broadcast.
b"\xff\xff\xff\xff\xff\xff\x08\x00'%;i\x08\x00E\x00\x00\x14\x00\x01\x00\x00@\x00d\xd9\n\x00\x02\x0f\n\x01\x00\x01"
```

Note that this does not occur for _all_ Ether plus IP packets.  If you
specify a dst address option to the call to `Ether()`, then Scapy will
use that destination MAC address, and not even attempt to send packets
on a network interface.  Similarly if you specify no `dst` option for
`IP()`.


## Python type `bytes` vs. `str`

One primary difference seems to be that Python3 Scapy uses the Python
type `bytes` rather than `str` in many places.  While the following is
probably common knowledge to more experienced Python programmers, here
are some differences between type `str` and `bytes` that I have
determined via experiments, run in Python 3.6.7:

A value `s` of type `str` is a sequence of 1-character strings.

+ `len(s)` returns the length of the string
+ `s[int_index]` returns a length 1 value of type `str`
+ `s[start_index:end_index]` returns a substring of type `str`

```python
>>> type('\x83\x03\x10')
<class 'str'>
>>> len('\x83\x03\x10')
3

>>> type('\x83\x03\x10'[1])
<class 'str'>
>>> '\x83\x03\x10'[1]
'\x03'
>>> len('\x83\x03\x10'[1])
1

>>> type('\x83\x03\x10'[1:3])
<class 'str'>
>>> '\x83\x03\x10'[1:3]
'\x03\x10'
```

A literal value of type `bytes` can be written by prefixing a string
literal with the character `b`.

A value `b` of type `bytes` is a sequence of `int` values in the range
[0, 255] (i.e. bytes).

+ `len(b)` returns the length of `b`, i.e. the number of bytes it contains
+ `b[int_index]` returns a value of type `int` in range [0, 255]
+ `b[start_index:end_index]` returns a part of `b`, and has type `bytes`

```python
>>> type(b'\x83\x03\x10')
<class 'bytes'>
>>> len(b'\x83\x03\x10')
3
>>> type(b'\x83\x03\x10'[1])
<class 'int'>
>>> b'\x83\x03\x10'[1]
3

>>> type(b'\x83\x03\x10'[1:3])
<class 'bytes'>
>>> b'\x83\x03\x10'[1:3]
b'\x03\x10'
>>> len(b'\x83\x03\x10'[1:3])
2
```

TBD: There must be built-in methods for converting between type `str`
and `bytes`, I would guess.  There might even be more than one,
depending upon character set encoding, perhaps?
