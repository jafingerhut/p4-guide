Some notes on using the Scapy library for generating and decoding
packet contents.

I found a working example of using Scapy to generate IPv4 headers with
IP options here: http://allievi.sssup.it/techblog/archives/631

```python
pkt_with_opts=Ether() / IP(dst='10.1.0.1', options=IPOption('\x83\x03\x10')) / TCP(sport=5792, dport=80)
```
