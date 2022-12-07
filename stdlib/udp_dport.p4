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
// This is an incomplete list of values used as the 16-bit destination
// port value in UDP headers.  Note that real deployments of these
// protocols may use different port numbers.
//////////////////////////////////////////////////////////////////////

// https://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.txt
// https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers

enum bit<16> udp_dport_t  {
    BOOTPS    =   67, /* Bootstrap Protocol (BOOTP) Server */
    BOOTPC    =   68, /* Bootstrap Protocol (BOOTP) Client */
    PTP       =  319, /* Precision Time Protocol (PTP) Event */
    RIP       =  520, /* Routing Information Protocol (RIP) */
    RIPNG     =  521, /* Routing Information Protocol next generation (RIPng) */
    DHCPV6_CLIENT = 546, /* DHCPv6 Client */
    DHCPV6_SERVER = 547, /* DHCPv6 Server */
    HSRP      = 1985, /* Cisco Hot Standby Router Protocol (HSRP) */
    GTPC_V1   = 2123, /* GTP control messages (GTP-C) */
    GTPU_V1   = 2152, /* GTP user data messages (GTP-U) */
    GTP_V0    = 3386, /* GTP 3GPP GSM/UMTS CDR logging protocol */
    BFD_1HOP  = 3784, /* Bidirectional Forwarding Detection (BFD) for IPv4 and IPv6 (Single Hop) (RFC 5881) */
    BFD_ECHO  = 3785, /* BFD Echo Protocol */
    LISP      = 4341, /* LISP Data Packets */
    BFD_MHOP  = 4784, /* BFD Multihop Control */
    VXLAN     = 4789, /* Virtual eXtensible Local Area Network (VXLAN) */
    VXLAN_GPE = 4790, /* Generic Protocol Extension for VXLAN (VXLAN_GPE) */
    ROCE      = 4791, /* IP Routable RDMA Over Converged Ethernet (RoCEv2) */
    GENEVE    = 6081, /* Virtualization Encapsulation (Geneve) */
    SFLOW     = 6343, /* sFlow traffic monitoring */
    MPLS      = 6635  /* Encapsulate MPLS packets in UDP tunnels with DTLS */
}
