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
// Also /usr/include/netinet/in.h on many Linux systems.

typedef bit<16> ipport_t;

const ipport_t IPPORT_BOOTPS    =   67; /* Bootstrap Protocol (BOOTP) Server */
const ipport_t IPPORT_BOOTPC    =   68; /* Bootstrap Protocol (BOOTP) Client */
const ipport_t IPPORT_PTP       =  319; /* Precision Time Protocol (PTP) Event */
const ipport_t IPPORT_RIP       =  520; /* Routing Information Protocol (RIP) */
const ipport_t IPPORT_RIPNG     =  521; /* Routing Information Protocol next generation (RIPng) */
const ipport_t IPPORT_DHCPV6_CLIENT = 546; /* DHCPv6 Client */
const ipport_t IPPORT_DHCPV6_SERVER = 547; /* DHCPv6 Server */
const ipport_t IPPORT_HSRP      = 1985; /* Cisco Hot Standby Router Protocol (HSRP) */
const ipport_t IPPORT_GTPC_V1   = 2123; /* GTP control messages (GTP-C) */
const ipport_t IPPORT_GTPU_V1   = 2152; /* GTP user data messages (GTP-U) */
const ipport_t IPPORT_GTP_V0    = 3386; /* GTP 3GPP GSM/UMTS CDR logging protocol */
const ipport_t IPPORT_BFD_1HOP  = 3784; /* Bidirectional Forwarding Detection (BFD) for IPv4 and IPv6 (Single Hop) (RFC 5881) */
const ipport_t IPPORT_BFD_ECHO  = 3785; /* BFD Echo Protocol */
const ipport_t IPPORT_LISP      = 4341; /* LISP Data Packets */
const ipport_t IPPORT_BFD_MHOP  = 4784; /* BFD Multihop Control */
const ipport_t IPPORT_VXLAN     = 4789; /* Virtual eXtensible Local Area Network (VXLAN) */
const ipport_t IPPORT_VXLAN_GPE = 4790; /* Generic Protocol Extension for VXLAN (VXLAN_GPE) */
const ipport_t IPPORT_ROCE      = 4791; /* IP Routable RDMA Over Converged Ethernet (RoCEv2) */
const ipport_t IPPORT_GENEVE    = 6081; /* Virtualization Encapsulation (Geneve) */
const ipport_t IPPORT_SFLOW     = 6343; /* sFlow traffic monitoring */
const ipport_t IPPORT_MPLS      = 6635; /* Encapsulate MPLS packets in UDP tunnels with DTLS */
