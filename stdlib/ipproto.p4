/*
Copyright 2022 Andy Fingerhut

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

//////////////////////////////////////////////////////////////////////
// This is an incomplete list of values used as the 8-bit protocol
// field in an IPv4 header, or the Next Header field in an IPv6
// header.  It definitely lists many of the most commonly used values,
// but also some rarely used values.
//////////////////////////////////////////////////////////////////////

// Wikipedia page "List of IP protocol numbers",
// https://en.wikipedia.org/wiki/List_of_IP_protocol_numbers

// Some references in Linux source files, and the Ubuntu 20.04 package
// they are a part of, as of 2022-Dec-05:

// /usr/include/netinet/in.h libc6-dev:amd64
// /usr/include/linux/in.h linux-libc-dev:amd64
// /usr/include/linux/in6.h linux-libc-dev:amd64
// /usr/include/linux/l2tp.h linux-libc-dev:amd64

enum bit<8> ipproto_t {
  HOPOPT = 0,    /* IPv6 Hop-by-Hop Option */
  ICMP = 1,      /* Internet Control Message Protocol */
  IGMP = 2,      /* Internet Group Management Protocol */
  IPIP = 4,      /* IP in IP encapsulation */
  TCP = 6,       /* Transmission Control Protocol */
  EGP = 8,       /* Exterior Gateway Protocol */
  PUP = 12,      /* PUP protocol */
  UDP = 17,      /* User Datagram Protocol */
  DCCP = 33,     /* Datagram Congestion Control Protocol */
  IPV6 = 41,     /* IPv6 Encapsulation (6to4 and 6in4) */
  ROUTING = 43,  /* IPv6 Routing Header */
  FRAGMENT = 44, /* IPv6 Fragment Header */
  RSVP = 46,     /* Resource Reservation Protocol */
  GRE = 47,      /* Generic Routing Encapsulation RFC 1701, RFC 1702 */
  ESP = 50,      /* Encapsulating Security Payload */
  AH = 51,       /* Authentication Header */
  ICMPV6 = 58,   /* ICMP for IPv6 */
  NONXT = 59,    /* IPv6 No Next Header */
  DSTOPTS = 60,  /* IPv6 Destination Options */
  EIGRP = 88,    /* Cisco's Enhanced Interior Gateway routing protocol */
  OSPF = 89,     /* Open Shortest Path First routing protocol */
  ETHERIP = 97,  /* Ethernet-within-IP Encapsulation */
  ENCAP = 98,    /* Encapsulation Header */
  PIM = 103,     /* Protocol Independent Multicast */
  COMP = 108,    /* IP Payload Compression Protocol */
  VRRP = 112,    /* Virtual Router Redundancy Protocol */
  L2TP = 115,    /* Layer Two Tunneling Protocol Version 3 */
  SCTP = 132,    /* Stream Control Transmission Protocol */
  MH = 135       /* IPv6 Mobility Extension Header */
  UDPLITE = 136, /* The Lightweight User Datagram Protocol (UDP-Lite) (RFC 3828) */
  MPLS = 137     /* MPLS (Multi Protocol Label Switching) Encapsulated in IP (RFC 4023, RFC 5332) */
}
