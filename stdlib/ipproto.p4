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

typedef bit<8> ipproto_t;

const ipproto_t IPPROTO_HOPOPTS = 0;   /* IPv6 Hop-by-Hop Option */
const ipproto_t IPPROTO_ICMP = 1;      /* Internet Control Message Protocol */
const ipproto_t IPPROTO_IGMP = 2;      /* Internet Group Management Protocol */
const ipproto_t IPPROTO_IPIP = 4;      /* IP in IP encapsulation */
const ipproto_t IPPROTO_TCP = 6;       /* Transmission Control Protocol */
const ipproto_t IPPROTO_EGP = 8;       /* Exterior Gateway Protocol */
const ipproto_t IPPROTO_PUP = 12;      /* PUP protocol */
const ipproto_t IPPROTO_UDP = 17;      /* User Datagram Protocol */
const ipproto_t IPPROTO_DCCP = 33;     /* Datagram Congestion Control Protocol */
const ipproto_t IPPROTO_IPV6 = 41;     /* IPv6 Encapsulation (6to4 and 6in4) */
const ipproto_t IPPROTO_ROUTING = 43;  /* IPv6 Routing Header */
const ipproto_t IPPROTO_FRAGMENT = 44; /* IPv6 Fragment Header */
const ipproto_t IPPROTO_RSVP = 46;     /* Resource Reservation Protocol */
const ipproto_t IPPROTO_GRE = 47;      /* Generic Routing Encapsulation RFC 1701, RFC 1702 */
const ipproto_t IPPROTO_ESP = 50;      /* Encapsulating Security Payload */
const ipproto_t IPPROTO_AH = 51;       /* Authentication Header */
const ipproto_t IPPROTO_ICMPV6 = 58;   /* ICMP for IPv6 */
const ipproto_t IPPROTO_NONXT = 59;    /* IPv6 No Next Header */
const ipproto_t IPPROTO_DSTOPTS = 60;  /* IPv6 Destination Options */
const ipproto_t IPPROTO_EIGRP = 88;    /* Cisco's Enhanced Interior Gateway routing protocol */
const ipproto_t IPPROTO_OSPF = 89;     /* Open Shortest Path First routing protocol */
const ipproto_t IPPROTO_ETHERIP = 97;  /* Ethernet-within-IP Encapsulation */
const ipproto_t IPPROTO_ENCAP = 98;    /* Encapsulation Header */
const ipproto_t IPPROTO_PIM = 103;     /* Protocol Independent Multicast */
const ipproto_t IPPROTO_COMP = 108;    /* IP Payload Compression Protocol */
const ipproto_t IPPROTO_VRRP = 112;    /* Virtual Router Redundancy Protocol */
const ipproto_t IPPROTO_L2TP = 115;    /* Layer Two Tunneling Protocol Version 3 */
const ipproto_t IPPROTO_SCTP = 132;    /* Stream Control Transmission Protocol */
const ipproto_t IPPROTO_MH = 135;      /* IPv6 Mobility Extension Header */
const ipproto_t IPPROTO_UDPLITE = 136; /* The Lightweight User Datagram Protocol (UDP-Lite) (RFC 3828) */
const ipproto_t IPPROTO_MPLS = 137;    /* MPLS (Multi Protocol Label Switching) Encapsulated in IP (RFC 4023, RFC 5332) */
const ipproto_t IPPROTO_HIP = 139;     /* Host Identity Protocol */
const ipproto_t IPPROTO_SHIM6 = 140;   /* Site Multihoming by IPv6 Intermediation */
