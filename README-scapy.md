Some notes on using the Scapy library for generating and decoding
packet contents.


## Create Scapy packet with IPv4 options

I found a working example of using Scapy to generate IPv4 headers with
IP options here: http://allievi.sssup.it/techblog/archives/631

```python
pkt_with_opts=Ether() / IP(dst='10.1.0.1', options=IPOption('\x83\x03\x10')) / TCP(sport=5792, dport=80)
```


## Convert Scapy packets to/from strings of 8-bit bytes

```python
# Construct a packet as a Scapy object

>>> pkt1=Ether() / IP(dst='10.1.0.1') / TCP(sport=5793, dport=80)
>>> type(pkt1)
<class 'scapy.layers.l2.Ether'>
>>> len(pkt1)
54

# Use str() constructor to convert it to a str
>>> pkt1s=str(pkt1)
>>> type(pkt1s)
<type 'str'>
>>> pkt1s
"RT\x00\x125\x02\x08\x00'\x01\x8b\xbc\x08\x00E\x00\x00(\x00\x01\x00\x00@\x06d\xbf\n\x00\x02\x0f\n\x01\x00\x01\x16\xa1\x00P\x00\x00\x00\x00\x00\x00\x00\x00P\x02 \x00b\xe1\x00\x00"
>>> len(pkt1s)
54

# Use Ether() constructor to convert str back to Scapy packet
>>> pkt1x=Ether(pkt1s)
>>> type(pkt1x)
<class 'scapy.layers.l2.Ether'>
>>> len(pkt1x)
54

# The converted to str, then back to Scapy pkt1x, is not equal to the
# original pkt1.  Why not?
>>> pkt1==pkt1x
False

# Their byte sequences are equal, so it must be some other attributes
# of the Scapy packet objects that are different.
>>> str(pkt1)==str(pkt1x)
True
>>> str(pkt1)==pkt1s
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
>>> pkt1=Ether() / IP(dst='10.1.0.1') / TCP(sport=5793, dport=80)
>>> def str_to_hex(s):
...     return ''.join(map(lambda x: '%02x' % (ord(x)), s))
... 
>>> str_to_hex(str(pkt1))
'525400123502080027018bbc08004500002800010000400664bf0a00020f0a01000116a1005000000000000000005002200062e10000'
```

Below are some intermediate steps demonstrating how the function
`str_to_hex` above works:

```python
>>> map(lambda x: x, str(pkt1))
['R', 'T', '\x00', '\x12', '5', '\x02', '\x08', '\x00', "'", '\x01', '\x8b', '\xbc', '\x08', '\x00', 'E', '\x00', '\x00', '(', '\x00', '\x01', '\x00', '\x00', '@', '\x06', 'd', '\xbf', '\n', '\x00', '\x02', '\x0f', '\n', '\x01', '\x00', '\x01', '\x16', '\xa1', '\x00', 'P', '\x00', '\x00', '\x00', '\x00', '\x00', '\x00', '\x00', '\x00', 'P', '\x02', ' ', '\x00', 'b', '\xe1', '\x00', '\x00']
>>> map(lambda x: '%02x' % (ord(x)), str(pkt1))
['52', '54', '00', '12', '35', '02', '08', '00', '27', '01', '8b', 'bc', '08', '00', '45', '00', '00', '28', '00', '01', '00', '00', '40', '06', '64', 'bf', '0a', '00', '02', '0f', '0a', '01', '00', '01', '16', 'a1', '00', '50', '00', '00', '00', '00', '00', '00', '00', '00', '50', '02', '20', '00', '62', 'e1', '00', '00']
>>> ''.join(map(lambda x: '%02x' % (ord(x)), str(pkt1)))
'525400123502080027018bbc08004500002800010000400664bf0a00020f0a01000116a1005000000000000000005002200062e10000'
```

Below shows how to convert from a string of hex digits (with optional
embedded space and tab characters, which will be ignored) to a Scapy
packet.

```python
>>> s1='5254 00123 5020 8002 7018BBC08004	500002800010000400664BF0A00020F0A01000116A1005000000000000000005002200062E10000'
>>> import re
>>> def hex_to_str(hex_s):
...     tmp = re.sub('[ \t]', '', hex_s)
...     return str(bytearray.fromhex(tmp))
... 

>>> pkt2=Ether(hex_to_str(s1))
>>> str(pkt1)==str(pkt2)
True
```


## Writing Scapy packets to, and reading Scapy packets from, pcap files

```python
>>> pkt0=Ether() / IP(dst='10.0.0.1') / TCP(sport=1, dport=8)
>>> pkt1=Ether() / IP(dst='10.1.0.1') / TCP(sport=5793, dport=80)
>>> pkt2=Ether() / IP(dst='10.2.0.2') / TCP(sport=65535, dport=443)
>>> wrpcap('some-pkts.pcap', [pkt0, pkt1, pkt2])

>>> pktlst=rdpcap('some-pkts.pcap')
>>> len(pktlst)
3
>>> pktlst
<some-pkts.pcap: TCP:3 UDP:0 ICMP:0 Other:0>
>>> pktlst[0]
<Ether  dst=52:54:00:12:35:02 src=08:00:27:01:8b:bc type=0x800 |<IP  version=4L ihl=5L tos=0x0 len=40 id=1 flags= frag=0L ttl=64 proto=tcp chksum=0x64c0 src=10.0.2.15 dst=10.0.0.1 options=[] |<TCP  sport=tcpmux dport=8 seq=0 ack=0 dataofs=5L reserved=0L flags=S window=8192 chksum=0x79ca urgptr=0 |>>>
>>> str(pkt0)==str(pktlst[0])
True
>>> str(pkt1)==str(pktlst[1])
True
>>> str(pkt2)==str(pktlst[2])
True
```


## Truncate a packet

This is a pretty straightforward application of the techniques in the
previous section.

```python
>>> pkt1=Ether() / IP(dst='10.1.0.1') / TCP(sport=5793, dport=80)
>>> pkt1.show2()
###[ Ethernet ]### 
  dst= 52:54:00:12:35:02
  src= 08:00:27:01:8b:bc
  type= 0x800
###[ IP ]### 
     version= 4L
     ihl= 5L
     tos= 0x0
     len= 40
     id= 1
     flags= 
     frag= 0L
     ttl= 64
     proto= tcp
     chksum= 0x64bf
     src= 10.0.2.15
     dst= 10.1.0.1
     \options\
###[ TCP ]### 
        sport= 5793
        dport= http
        seq= 0
        ack= 0
        dataofs= 5L
        reserved= 0L
        flags= S
        window= 8192
        chksum= 0x62e1
        urgptr= 0
        options= {}

>>> len(pkt1)
54

# Create pkt2 with the same contents as pkt1, except the last byte is
# removed.
>>> pkt2=Ether(str(pkt1)[:-1])
>>> len(pkt2)
53
>>> pkt2.show2()
###[ Ethernet ]### 
  dst= 52:54:00:12:35:02
  src= 08:00:27:01:8b:bc
  type= 0x800
###[ IP ]### 
     version= 4L
     ihl= 5L
     tos= 0x0
     len= 40
     id= 1
     flags= 
     frag= 0L
     ttl= 64
     proto= tcp
     chksum= 0x64bf
     src= 10.0.2.15
     dst= 10.1.0.1
     \options\
###[ Raw ]### 
        load= '\x16\xa1\x00P\x00\x00\x00\x00\x00\x00\x00\x00P\x02 \x00b\xe1\x00'

>>> str(pkt1) == str(pkt2)
False
>>> str(pkt1)[0:53] == str(pkt2)
True
```


## Examining fields of a packet

```python
>>> pkt1=Ether() / IP(dst='10.1.0.1') / TCP(sport=5793, dport=80)
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
[<Field (IP,IPerror).version>, <Field (IP,IPerror).ihl>, <Field (IP,IPerror).tos>, <Field (IP,IPerror).len>, <Field (IP,IPerror).id>, <Field (IP,IPerror).flags>, <Field (IP,IPerror).frag>, <Field (IP,IPerror).ttl>, <Field (IP,IPerror).proto>, <Field (IP,IPerror).chksum>, <scapy.fields.Emph object at 0x7f9d315e1ef8>, <scapy.fields.Emph object at 0x7f9d315e1f30>, <Field (IP,IPerror).options>]
>>> pkt1[TCP].fields_desc
[<Field (TCP,TCPerror).sport>, <Field (TCP,TCPerror).dport>, <Field (TCP,TCPerror).seq>, <Field (TCP,TCPerror).ack>, <Field (TCP,TCPerror).dataofs>, <Field (TCP,TCPerror).reserved>, <Field (TCP,TCPerror).flags>, <Field (TCP,TCPerror).window>, <Field (TCP,TCPerror).chksum>, <Field (TCP,TCPerror).urgptr>, <Field (TCP,TCPerror).options>]

# Get values of fields in Ether header
>>> pkt1[Ether].fields_desc
[<Field (Ether).dst>, <Field (Ether).src>, <Field (Ether).type>]
>>> pkt1[Ether].dst
'52:54:00:12:35:02'
>>> pkt1[Ether].src
'08:00:27:01:8b:bc'
>>> pkt1[Ether].type
2048
>>> type(pkt1[Ether].dst)
<type 'str'>
>>> type(pkt1[Ether].type)
<type 'int'>
```

Get values of fields in IP header.  Note that the packet is only
'partially built', meaning that some of the field values are `None`
(fields `ihl`, `len`, and `chksum` in this example).  The idea with
Scapy is that these fields are auto-calculated from other parts of the
packet on demand, just before doing things like `pkt1.show2()` or
`str(pkt1)`, which need those fields to be calculated.

See below for one way to get the calculated value of those fields.

```python
>>> pkt1[IP].fields_desc
[<Field (IP,IPerror).version>, <Field (IP,IPerror).ihl>, <Field (IP,IPerror).tos>, <Field (IP,IPerror).len>, <Field (IP,IPerror).id>, <Field (IP,IPerror).flags>, <Field (IP,IPerror).frag>, <Field (IP,IPerror).ttl>, <Field (IP,IPerror).proto>, <Field (IP,IPerror).chksum>, <scapy.fields.Emph object at 0x7f9d315e1ef8>, <scapy.fields.Emph object at 0x7f9d315e1f30>, <Field (IP,IPerror).options>]

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
0
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
<type 'str'>
>>> pkt1[IP].dst
'10.1.0.1'
>>> pkt1[IP].options
[]
>>> type(pkt1[IP].options)
<type 'list'>
```

A straightforward way to get the values of these fields is to use
`str()` on the packet, which forces the packet to 'build', calculating
values for those fields, and then disssect it back into fields by
calling the `Ether()` constructor on the resulting string.

```
>>> pkt2=Ether(str(pkt1))
>>> pkt2[IP].chksum
25791
>>> pkt2[IP].len
40
>>> pkt2[IP].ihl
5L
```


## Creating packets with incorrect values for auto-calculated fields

Here is one way to create a packet with an incorrect IPv4 header
checksum, without knowing in advance what the correct checksum is:
calculate the correct checksum, add 1 to it, then use that modified
value to construct another similar packet.

```python
>>> pkt1=Ether() / IP(dst='10.1.0.1') / TCP(sport=5793, dport=80)
>>> pkt2=Ether(str(pkt1))
# pkt2 has calculated correct IPv4 header checksum
>>> pkt2[IP].chksum
25791
>>> pkt1[IP].chksum=pkt2[IP].chksum+1
>>> pkt1[IP].chksum
25792
>>> str(pkt2)==str(pkt1)
False
```


## Creating packets that are only slightly different than other packets

You can use the `copy()` method to create a duplicate of a Scapy
packet object, then modify the copy, and no changes will be made to
the original.

Note that if the original packet is 'partially built',
i.e. `pkt1[IP].chksum is None` is `true`, as shown in the transcript
below, then the same is true for the copy.  Any changes made to the
copy's fields before doing something like `str()` or `show2()` on it
will cause those modified field values to be included when the fields
with value `None` are auto-calculated.

```python
>>> pkt1=Ether() / IP(dst='10.1.0.1') / TCP(sport=5793, dport=80)
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

>>> Ether(str(pkt1))[IP].chksum
WARNING: Mac address to reach destination not found. Using broadcast.
25791
>>> Ether(str(pkt2))[IP].chksum
WARNING: Mac address to reach destination not found. Using broadcast.
26047
```
