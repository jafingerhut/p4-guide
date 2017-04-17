## Guide to the included demo programs

### demo1

A very simple program that only does these things:

* on ingress:
  * parse Ethernet and IPv4 headers (ignoring IP options)
  * perform a longest prefix match on the IPv4 DA, resulting in an
    'l2ptr' value
  * l2ptr is an exact match index into a mac_da table, resulting in
    output BD (bridge domain), a new destination MAC address, and the
    output port.
  * decrement the IPv4 TTL field
* on egress:
  * look up the output port number to get a new source MAC address
  * calculate a new IPv4 header checksum


### demo2

The same as demo1, except add a per-prefix match count.


### demo3

The same as demo2, except add calculation of an ECMP hash, and add
ECMP group and path tables that can use the ECMP hash to pick one of
several paths for a packet that matches a single prefix in the longest
prefix match table.

Note that most P4 programs use 'action profiles' to implement ECMP.
demo3 does not use those.  There is no strong reason why not -- demo3
simply demonstrates another way to do ECMP that doesn't require P4
action profiles, yet still achieves sharing of ECMP table entries
among many IP prefixes.
