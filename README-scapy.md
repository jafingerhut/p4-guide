# Introduction

Some notes on using the Scapy library for generating and decoding
packet contents.  It covers both Python2 and Python3, and versions of
Scapy 2.2 up to 2.4.


## Versions of Scapy

One issue with Python3 and Scapy is that there are (at least) two
versions of Scapy for Python3.  A description of the current situation
as of 2019-Mar-19 is shown below, copied from https://scapy.net on
that date:

    An independent fork of Scapy was created from v2.2.0 in 2015,
    aimed at supporting only Python3
    ([scapy3k](https://github.com/phaethon/kamene)).  The fork
    diverged, did not follow evolutions and fixes, and has had its own
    life without contributions back to Scapy.  Unfortunately, it has
    been packaged as python3-scapy in some distributions, and as
    scapy-python3 on PyPI leading to confusion amongst users.  It
    should not be the case anymore soon.  Scapy supports Python3 in
    addition to Python2 since 2.4.0.  Scapy v2.4.0 should be favored
    as the official Scapy code base.  The fork has been renamed as
    kamene.

As of 2019-Mar-19, the Ubuntu 18.04 Linux package `python3-scapy` is
the kamene version described above.  I am personally going to avoid
using kamene, since it likely has some differences in its
implementation, and since the original Scapy is now supported on
Python3, I do not see much reason to use it over Scapy.

In summary, to use the original Scapy, updated as of March 2018 to
work with Python3, and to avoid using kamene:

+ DO use `pip` or `pip3` to install the `scapy` package (instructions below)
+ DO NOT install the Ubuntu package `python3-scapy`
+ DO NOT use `pip` or `pip3` to install the `scapy-python3` package

On an Ubuntu 16.04 or 18.04 Linux system:

```bash
$ sudo apt-get install python3-pip
$ pip3 install scapy
```

With the commands above, it will install the Scapy package within your
`$HOME/.local` directory.  Replace `pip3` with `pip` and it will
install Scapy for Python2.

The official Scapy web site contains instructions for installing any
Scapy verson from source code.  I found the command below for
installing the latest development version of Scapy, if you like living
on the edge:

```
$ pip3 install --upgrade git+git://github.com/secdev/scapy
```

TBD: In the future, it might be nice to have steps to uninstall
alternate versions of Scapy, and to have a tiny test script that can
be used to tell whether the version you are currently running is
kamene or Scapy, and which version number.


## Prerequisites

For all of the Python interactive sessions shown below, this Python
`import` statement was done first:

```python
from scapy.all import *
```

If you have not used earlier versions of Scapy or have no interest in
Python2 and Python3 differences, you can ignore the later sections
titled "Some differences between Scapy 2.4 vs. earlier Scapy versions"
and "Python type `bytes` vs. `str`".  Consider reading them if you
have used Python2 and are switching to Python3, or you have used
versions of Scapy earlier than 2.4, and would like to learn of a few
differences (only a few, relevant to Scapy).


## Version combinations tested

+ Python2 with Scapy 2.2.0
+ Python2 with Scapy 2.4.2
+ Python3 with Scapy 2.4.2


## Create Scapy packet with IPv4 options, brief version

I found a working example of using Scapy to generate IPv4 headers with
IP options here: http://allievi.sssup.it/techblog/archives/631

```python
>>> pkt_with_opts=Ether(dst='00:00:00:00:00:05') / IP(dst='10.1.0.1', options=IPOption(b'\x83\x03\x10')) / TCP(sport=5792, dport=80)
>>> pkt_with_opts.show2()
###[ Ethernet ]### 
  dst       = 00:00:00:00:00:05
  src       = 08:00:27:56:85:a4
  type      = 0x800
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
        options   = []
```

The `show2()` sample output above is for Python3 + Scapy 2.4.2.  The
output for the other two versions differs slightly in formatting, and
in the Ethernet source address (details in the next section if you are
curious).


## Create Scapy packet with IPv4 options, many details

This version works with all three versions I tested, and requires the
`b` before the argument to `IPOption` to work on all of them:

```python
>>> pkt_with_opts=Ether(dst='00:00:00:00:00:05') / IP(dst='10.1.0.1', options=IPOption(b'\x83\x03\x10')) / TCP(sport=5792, dport=80)

>>> bytes(pkt_with_opts)
"\x00\x00\x00\x00\x00\x05\x08\x00'(+c\x08\x00F\x00\x00,\x00\x01\x00\x00@\x06\xd0\xb7\n\x00\x02\x0f\n\x01\x00\x01\x83\x03\x10\x00\x16\xa0\x00P\x00\x00\x00\x00\x00\x00\x00\x00P\x02 \x00b\xe2\x00\x00"
>>> len(bytes(pkt_with_opts))
58

# Python2 + Scapy 2.2.0
# also Python2 + Scapy 2.4.2
>>> list(bytes(pkt_with_opts))
['\x00', '\x00', '\x00', '\x00', '\x00', '\x05', '\x08', '\x00', "'", '(', '+', 'c', '\x08', '\x00', 'F', '\x00', '\x00', ',', '\x00', '\x01', '\x00', '\x00', '@', '\x06', '\xd0', '\xb7', '\n', '\x00', '\x02', '\x0f', '\n', '\x01', '\x00', '\x01', '\x83', '\x03', '\x10', '\x00', '\x16', '\xa0', '\x00', 'P', '\x00', '\x00', '\x00', '\x00', '\x00', '\x00', '\x00', '\x00', 'P', '\x02', ' ', '\x00', 'b', '\xe2', '\x00', '\x00']
>>> list(map(lambda x: ord(x), bytes(pkt_with_opts)))
[0, 0, 0, 0, 0, 5, 8, 0, 39, 40, 43, 99, 8, 0, 70, 0, 0, 44, 0, 1, 0, 0, 64, 6, 208, 183, 10, 0, 2, 15, 10, 1, 0, 1, 131, 3, 16, 0, 22, 160, 0, 80, 0, 0, 0, 0, 0, 0, 0, 0, 80, 2, 32, 0, 98, 226, 0, 0]

# Python3 + Scapy 2.4.2
>>> list(bytes(pkt_with_opts))
[0, 0, 0, 0, 0, 5, 8, 0, 39, 86, 133, 164, 8, 0, 70, 0, 0, 44, 0, 1, 0, 0, 64, 6, 208, 183, 10, 0, 2, 15, 10, 1, 0, 1, 131, 3, 16, 0, 22, 160, 0, 80, 0, 0, 0, 0, 0, 0, 0, 0, 80, 2, 32, 0, 98, 226, 0, 0]
```

The Ethernet source address selected by Scapy is different on Python3
than Python2, but other than that the packets created are identical.
We did not specify an Ethernet source address to use, so it seems
reasonable to me that different versions of Python and/or Scapy might
have different values it selects there.


## Convert Scapy packets to/from Python type `bytes`

```python
# Construct a packet as a Scapy object

>>> pkt1=Ether(dst='00:00:00:00:00:05') / IP(dst='10.1.0.1') / TCP(sport=5793, dport=80)
>>> type(pkt1)
<class 'scapy.layers.l2.Ether'>
>>> len(pkt1)
54

# Use bytes() constructor to convert it to type bytes with Python3 (or
# to type str with Python2)

>>> pkt1b=bytes(pkt1)
>>> type(pkt1b)
<class 'bytes'>
# The above is for Python2 + Scapy 2.4.2.  Other two versions show str

>>> pkt1b
b'\x00\x00\x00\x00\x00\x05\x00\x11"3DU\x08\x00E\x00\x00(\x00\x01\x00\x00@\x06d\xbf\n\x00\x02\x0f\n\x01\x00\x01\x16\xa1\x00P\x00\x00\x00\x00\x00\x00\x00\x00P\x02 \x00b\xe1\x00\x00'
# The above is for Python2 + Scapy 2.4.2.  Other two versions do not
# have 'b' at the beginning.

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
1504418046.720192
>>> pkt1x.time
1504419231.279649
```


## Convert Scapy packets to/from strings of ASCII hex digits

This is similar to the previous section, except the strings are not an
entire 8-bit byte per character, but 2 ASCII hex digits per 8-bit
byte.  This is useful in multiple contexts, e.g. representing packet
contents in an STF file as part of an automated test of the p4c P4
compiler.

```python
>>> pkt1=Ether(src='00:11:22:33:44:55', dst='00:00:00:00:00:05') / IP(dst='10.1.0.1') / TCP(sport=5793, dport=80)

# Function bytes_to_hex() could probably be named better, since it can
# also take an argument of type str.  The if statement can be removed
# if you only need Python3 support.  The if is there to also work on
# Python2.

>>> def bytes_to_hex(b):
...     if isinstance(b, str):
...         return ''.join(['%02x' % (ord(x)) for x in b])
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
    if isinstance(b, str):
        return ''.join(['%02x' % (ord(x)) for x in b])
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
<Ether  dst=00:00:00:00:00:05 src=00:11:22:33:44:55 type=0x800 |<IP  version=4 ihl=5 tos=0x0 len=40 id=1 flags= frag=0 ttl=64 proto=tcp chksum=0x64c0 src=10.0.2.15 dst=10.0.0.1 |<TCP  sport=tcpmux dport=8 seq=0 ack=0 dataofs=5 reserved=0 flags=S window=8192 chksum=0x79ca urgptr=0 |>>>
>>> bytes(pkt0)==bytes(pktlst[0])
True
>>> bytes(pkt1)==bytes(pktlst[1])
True
>>> bytes(pkt2)==bytes(pktlst[2])
True
```

I have tested that the above is common behavior across the three
version combos.


## Truncate a packet

This is a pretty straightforward application of the techniques in the
previous section.

```python
>>> pkt1=Ether(src='00:11:22:33:44:55', dst='00:00:00:00:00:05') / IP(dst='10.1.0.1') / TCP(sport=5793, dport=80)
>>> pkt1.show2()
###[ Ethernet ]### 
  dst       = 00:00:00:00:00:05
  src       = 00:11:22:33:44:55
  type      = 0x800
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
        options   = []

# The output above is for Scapy 2.4.2.  Python2 plus Scapy 2.2.0 had
# nearly identical output, but had 'L' suffix after some integer
# values indicating they were Python 'long' values, and the last value
# 'options' printed as {} instead of [], probably indicating a dict
# rather than a list.

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
  type      = 0x800
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
        load      = '\x16\xa1\x00P\x00\x00\x00\x00\x00\x00\x00\x00P\x02 \x00b\xe1\x00'

# Again, the output above is for Scapy 2.4.2.  Python2 plus Scapy
# 2.2.0 had nearly identical output, but had 'L' suffix after some
# integer values.

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
[<Field (Ether).dst>, <Field (Ether).src>, <Field (Ether).type>]
>>> pkt1[Ether].fields_desc
[<Field (Ether).dst>, <Field (Ether).src>, <Field (Ether).type>]
>>> pkt1[IP].fields_desc
[<Field (IP,IPerror,_IPv46).version>, <Field (IP,IPerror,_IPv46).ihl>, <Field (IP,IPerror,_IPv46).tos>, <Field (IP,IPerror,_IPv46).len>, <Field (IP,IPerror,_IPv46).id>, <Field (IP,IPerror,_IPv46).flags>, <Field (IP,IPerror,_IPv46).frag>, <Field (IP,IPerror,_IPv46).ttl>, <Field (IP,IPerror,_IPv46).proto>, <Field (IP,IPerror,_IPv46).chksum>, <scapy.fields.Emph object at 0x7fe60e98b0a8>, <scapy.fields.Emph object at 0x7fe60e98b108>, <Field (IP,IPerror,_IPv46).options>]
>>> pkt1[TCP].fields_desc
[<Field (TCP,TCPerror).sport>, <Field (TCP,TCPerror).dport>, <Field (TCP,TCPerror).seq>, <Field (TCP,TCPerror).ack>, <Field (TCP,TCPerror).dataofs>, <Field (TCP,TCPerror).reserved>, <Field (TCP,TCPerror).flags>, <Field (TCP,TCPerror).window>, <Field (TCP,TCPerror).chksum>, <Field (TCP,TCPerror).urgptr>, <Field (TCP,TCPerror).options>]

# Get values of fields in Ether header
>>> pkt1[Ether].fields_desc
[<Field (Ether).dst>, <Field (Ether).src>, <Field (Ether).type>]
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

The output above (and later below in this section) is for Python3 and
Scapy 2.4.2.  There were only minor differences with the other two
versions.

Get values of fields in IP header.  Note that the packet is only
'partially built', meaning that some of the field values are `None`
(fields `ihl`, `len`, and `chksum` in this example).  The idea with
Scapy is that these fields are auto-calculated from other parts of the
packet on demand, just before doing things like `pkt1.show2()` or
`bytes(pkt1)`, which need those fields to be calculated.

See below for one way to get the calculated value of those fields.

```python
>>> pkt1[IP].fields_desc
[<Field (IP,IPerror,_IPv46).version>, <Field (IP,IPerror,_IPv46).ihl>, <Field (IP,IPerror,_IPv46).tos>, <Field (IP,IPerror,_IPv46).len>, <Field (IP,IPerror,_IPv46).id>, <Field (IP,IPerror,_IPv46).flags>, <Field (IP,IPerror,_IPv46).frag>, <Field (IP,IPerror,_IPv46).ttl>, <Field (IP,IPerror,_IPv46).proto>, <Field (IP,IPerror,_IPv46).chksum>, <scapy.fields.Emph object at 0x7fe60e98b0a8>, <scapy.fields.Emph object at 0x7fe60e98b108>, <Field (IP,IPerror,_IPv46).options>]

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

I have tested that the above is common behavior across the three
version combos.


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

I have tested that the above is common behavior across the three
version combos.


## Some differences between Scapy 2.4 vs. earlier Scapy versions

Before writing this, I had most often used Scapy 2.2 or earlier with
Python2.

Scapy 2.4 added a new function `raw()` which the Scapy developers
suggest using to convert packets to type `bytes`, rather than using
`str()` or `bytes()`, although it seems that perhaps `bytes()` still
works and returns the same value.  `raw()` does not exist in Scapy
2.2.

While it seems that perhaps `raw(pkt) == bytes(pkt)` is `True` for
both Python2 or Python3 with Scapy 2.4.x, `raw(pkt)` and `str(pkt)`
are _different_ for Python3.  It might be true in general that
`raw(pkt) == str(pkt)` still for Python2 with Scapy 2.4.x, but it
seems like a good idea to use `raw()` consistently if you plan to rely
on Scapy 2.4.x and later, or `bytes()` consistently if you want to
continue to write Python2 code that will run with older versions of
Scapy like 2.2.x.

Python3 plus Scapy 2.4.2 session demonstrating difference of return
value between `raw` and `str`:

```python
>>> pkt=Ether() 
>>> raw(pkt)
b"\xff\xff\xff\xff\xff\xff\x08\x00'V\x85\xa4\x90\x00"
>>> len(raw(pkt))
14
>>> str(pkt)
'b"\\xff\\xff\\xff\\xff\\xff\\xff\\x08\\x00\'V\\x85\\xa4\\x90\\x00"'
>>> len(str(pkt))
53
```

Python3 `raw(pkt)` and `bytes(pkt)` return type `bytes`, whereas with
Python2 they return type `str`.

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

Python3:

```python
>>> pkt=Ether() / IP(dst='10.1.0.1')
>>> raw(pkt)
Exception ignored in: <bound method SuperSocket.__del__ of <scapy.arch.linux.L2Socket object at 0x7f279ea89518>>
Traceback (most recent call last):
  File "/home/jafinger/.local/lib/python3.6/site-packages/scapy/supersocket.py", line 123, in __del__
    self.close()
  File "/home/jafinger/.local/lib/python3.6/site-packages/scapy/arch/linux.py", line 481, in close
    set_promisc(self.ins, self.iface, 0)
AttributeError: 'L2Socket' object has no attribute 'ins'
b"\xff\xff\xff\xff\xff\xff\x08\x00'V\x85\xa4\x08\x00E\x00\x00\x14\x00\x01\x00\x00@\x00d\xd9\n\x00\x02\x0f\n\x01\x00\x01"
```

Python2:

```python
>>> from scapy.all import *
>>> pkt=Ether() / IP(dst='10.1.0.1')
>>> raw(pkt)
Exception AttributeError: "'L2Socket' object has no attribute 'ins'" in <bound method L2Socket.__del__ of <scapy.arch.linux.L2Socket object at 0x7fee528d94d0>> ignored
"\xff\xff\xff\xff\xff\xff\x08\x00'(+c\x08\x00E\x00\x00\x14\x00\x01\x00\x00@\x00d\xd9\n\x00\x02\x0f\n\x01\x00\x01"
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


## Scapy version notes

This section has details recorded while trying to track down
differences in Scapy behavior between different versions I had
installed on different virtual machines, especially in regards to how
UDP header checksums were calculated.

The brief summary of that particular issue is that there is a corner
case bug in Scapy calculating UDP header checksums for IPv6/UDP
packets that was fixed in Scapy v2.3.2.

A similar bug exists for calculating the UDP header checksum for
IPv4/UDP packets up to and including Scapy v2.3.3.  There doesn't
appear to be a more recently "released" version of Scapy that fixes
that bug, but the latest Scapy version published on Github does have a
fix for it.



Latest version of Scapy seen using Synaptic package manager on these
versions of Ubuntu desktop Linux, as of 2017-Oct-19:

+ 14.04.5 LTS - python-scapy 2.2.0-1

  + On my VM named "Ubuntu 14.04" in VirtualBox, /usr/local/bin/scapy
    exists, but python-scapy package is not installed, so I probably
    installed it as part of some open source P4 tools some time ago (I
    don't recall exactly which install did this).  Starting it shows
    version 2.2.0-dev
  
+ 16.04.3 LTS - python-scapy 2.2.0-1

  + On my well-used VM named "Ubuntu 16.04" in VirtualBox, which is
    _not_ a fresh install, there is /usr/bin/scapy,
    /usr/local/bin/scapy, and even /home/jafinger/.local/bin/scapy (I
    don't know why that exists).  Both /usr/bin/scapy and
    /usr/local/bin/scapy claim they are version 2.3.3.  I do not know
    whether /usr/bin/scapy mmight have been overwritten after the
    python-scapy package was installed, and I do not know which
    install step I did that created /usr/local/bin/scapy.

  + On my little-used VM named "Ubuntu 16.04.3 try3" in VirtualBox,
    package python-scapy is installed, and the only scapy executable
    in my path is /usr/bin/scapy.  It reports as version 2.2.0.

+ 17.10       - python-scapy 2.3.3-1 (also python3-scapy 0.21-1)
  + After 'sudo apt-get install python-scapy', then running command
    /usr/bin/scapy, it says '(unknown.version)'.


Using scapy 2.2.0 on my VM named "Ubuntu 16.04.03 try3"

```Python
pkt1=Ether()/IP()/UDP()
pkt2=Ether()/IP()/UDP(dport=53+0x172)
pkt3=Ether()/IPv6()/UDP()
pkt4=Ether()/IPv6()/UDP(dport=53+0xff72)
wrpcap("udp-pkts.pcap", [pkt1, pkt2, pkt3, pkt4])
```

The value 0x172 was what I saw in the UDP checksum field of pkt1 after
being written out to the pcap file, according to wireshark.

By making pkt2 have a single 16-bit field that was larger by that much
than pkt1, the 16-bit 1's complement sum for the UDP fields should
have been 0xffff, and complementing that gives 0x0000.

Similarly the 0xff72 value was what I saw in the UDP checksum field of
pkt3, and pkt4 thus has a UDP one's complement sum of 0xffff, and
complementing that gives 0x0000.

0x0000 is what scapy put into the UDP checksum field for pkt2, which I
believe is incorrect.  RFC 768 has a special case that I think is only
applicable to UDP checksums, not to IPv4 header nor TCP header
checksums, which is that if the calculated value that would normally
be transmitted in the packet is 0, it should be replaced with 0xffff.
The protocol designers I believe wanted to reserve 0 as a special
value for UDP that means "the sender did not calculate a UDP checksum,
and the receiver should not check the value".  This is for efficiency
of encapsulating other packets within UDP payloads, I believe, which
is especially useful for implementing tunneling protocols that add new
UDP headers in high-speed routers.


VM name: "Ubuntu 16.04" /usr/bin/scapy says version 2.3.3
pkt2 IPv4/UDP checksum 0x0000 (looks wrong)
pkt4 IPv6/UDP checksum 0xffff (looks correct)

VM name: "Ubuntu 16.04.3 try3" /usr/bin/scapy says version 2.2.0
pkt2 IPv4/UDP checksum 0x0000 (looks wrong, wireshark 2.2.6 says missing)
pkt4 IPv6/UDP checksum 0x0000 (looks wrong, wireshark 2.2.6 says illegal)

VM name: "Ubuntu 14.04" /usr/local/bin/scapy says version 2.2.0-dev
pkt2 IPv4/UDP checksum 0x0000 (looks wrong, wireshark 1.12.1 says missing)
pkt4 IPv6/UDP checksum 0x0000 (looks wrong, wireshark 1.12.1 says illegal)

VM name: "Ubuntu 17.10" /usr/bin/scapy says version "unknown.version"
pkt2 IPv4/UDP checksum 0x0000 (looks wrong)
pkt4 IPv6/UDP checksum 0xffff (looks correct)

On my Ubuntu VM named "Ubuntu 16.04" I did these commands:

```bash
git clone https://github.com/secdev/scapy
cd scapy
git checkout ca0543ef581f2556c9933c073bdfd84f0b2ff895
./run_scapy
```

That reported itself on startup as version 2.3.3.dev793.  The pkt2
created and written to the pcap file this time had a UDP header
checksum of 0xffff, which I believe is correct.


Here is the secdev/scapy Github project commit that appears to have
fixed this corner case bug of UDP checksum calculation, for IPv4/UDP
packets:

```
commit 3a51db106625814de8d56bedf842b2b2454f0fce
Author: Guillaume Valadon <guillaume.valadon@ssi.gouv.fr>
Date:   Fri Nov 25 17:41:02 2016 +0100

    UDP checksum computation fixed
```

Using gitk, the commit above says it is on the master branch, and it
"Follows: v2.3.3".

And here is the commit that appears to have fixed this for IPv6/UDP
packets:

```
commit 12d9d9434bfbd375c518d5b1f0397905d900d5d4
Author: Guillaume Valadon <guillaume@valadon.net>
Date:   Mon May 11 16:00:37 2015 +0200

    IPv6 - when the UDP checksum is 0, set it to 0xffff
    
    --HG--
    branch : Issue #5116 - IPv6 & UDP.chksum == 0
```

Using gitk, the commit above is on the master branch, it "Follows:
v2.3.1" and "Precedes: v2.3.2".
