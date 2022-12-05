//////////////////////////////////////////////////////////////////////
// Andy Fingerhut
//
// This is an incomplete list of values used as the 16-bit protocol
// field in an Ethernet header.  It definitely lists many of the most
// commonly used values, but also many rarely used values.
//
// Abbreviations for references used in this file:
//
// [G] - RFC 1701 "Generic Routing Encapsulation (GRE)", the section
// called "Current List of Protocol Types"
// https://tools.ietf.org/html/rfc1701
//
// [R] - RFC 7042, "IANA Considerations and IETF Protocol and
// Documentation Usage for IEEE 802 Parameters"
// https://tools.ietf.org/html/rfc7042
//
// [W] - Wikipedia page on Ethertype,
// https://en.wikipedia.org/wiki/EtherType
//
// [E] - Linux source file /usr/include/net/ethernet.h from Ubuntu
// 20.04
//
// [F] - Linux source file /usr/include/linux/if_ether.h from Ubuntu
// 20.04
//
// [I] - IEEE 802 Numbers,
// https://www.iana.org/assignments/ieee-802-numbers/ieee-802-numbers.xml
//
// [X] - https://standards-oui.ieee.org/ethertype/eth.txt
//
//////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////
// Reference [R] Appendix B.1 of RFC 7042
// https://tools.ietf.org/html/rfc7042
//////////////////////////////////////////////////////////////////////

//   0x0800  Internet Protocol Version 4 (IPv4)
//   0x0806  Address Resolution Protocol (ARP)
//   0x0808  Frame Relay ARP
//   0x22F3  TRILL
//   0x22F4  L2-IS-IS
//   0x8035  Reverse Address Resolution Protocol (RARP)
//   0x86DD  Internet Protocol Version 6 (IPv6)
//   0x880B  Point-to-Point Protocol (PPP)
//   0x880C  General Switch Management Protocol (GSMP)
//   0x8847  MPLS
//   0x8848  MPLS with upstream-assigned label
//   0x8861  Multicast Channel Allocation Protocol (MCAP)
//   0x8863  PPP over Ethernet (PPPoE) Discovery Stage
//   0x8864  PPP over Ethernet (PPPoE) Session Stage
//   0x893B  TRILL Fine Grained Labeling (FGL)
//   0x8946  TRILL RBridge Channel

//////////////////////////////////////////////////////////////////////
// Reference [R] Appendix B.2 of RFC 7042
// https://tools.ietf.org/html/rfc7042
//////////////////////////////////////////////////////////////////////

//   0x8100  IEEE Std 802.1Q   - Customer VLAN Tag Type (C-Tag, formerly called the Q-Tag) (initially Wellfleet)
//   0x8808  IEEE Std 802.3    - Ethernet Passive Optical Network (EPON)
//   0x888E  IEEE Std 802.1X   - Port-based network access control
//   0x88A8  IEEE Std 802.1Q   - Service VLAN tag identifier (S-Tag)
//   0x88B5  IEEE Std 802      - Local Experimental Ethertype
//   0x88B6  IEEE Std 802      - Local Experimental Ethertype
//   0x88B7  IEEE Std 802      - OUI Extended Ethertype
//   0x88C7  IEEE Std 802.11   - Pre-Authentication (802.11i)
//   0x88CC  IEEE Std 802.1AB  - Link Layer Discovery Protocol (LLDP)
//   0x88E5  IEEE Std 802.1AE  - Media Access Control Security
//   0x88F5  IEEE Std 802.1Q   - Multiple VLAN Registration Protocol (MVRP)
//   0x88F6  IEEE Std 802.1Q   - Multiple Multicast Registration Protocol (MMRP)
//   0x890D  IEEE Std 802.11   - Fast Roaming Remote Request (802.11r)
//   0x8917  IEEE Std 802.21   - Media Independent Handover Protocol
//   0x8929  IEEE Std 802.1Qbe - Multiple I-SID Registration Protocol
//   0x8940  IEEE Std 802.1Qbg - ECP Protocol (also used in 802.1BR)

//////////////////////////////////////////////////////////////////////
// Reference [G] Values from section "Current List of Protocol Types"
// from RFC 1701 "Generic Routing Encapsulation (GRE)"
//////////////////////////////////////////////////////////////////////

// Reserved                            0000
// SNA                                 0004
// OSI network layer                   00FE
// PUP                                 0200
// XNS                                 0600
// IP                                  0800
// Chaos                               0804
// RFC 826 ARP                         0806
// Frame Relay ARP                     0808
// VINES                               0BAD
// VINES Echo                          0BAE
// VINES Loopback                      0BAF
// DECnet (Phase IV)                   6003
// Transparent Ethernet Bridging       6558
// Raw Frame Relay                     6559
// Apollo Domain                       8019
// Ethertalk (Appletalk)               809B
// Novell IPX                          8137
// RFC 1144 TCP/IP compression         876B
// IP Autonomous Systems               876C
// Secure Data                         876D
// Reserved                            FFFF

//////////////////////////////////////////////////////////////////////
// Reference [W] Ethertype values from Wikipedia page
// https://en.wikipedia.org/wiki/EtherType retrieved 2022-Dec-04
//////////////////////////////////////////////////////////////////////

// 0x0800 Internet Protocol version 4 (IPv4)
// 0x0806 Address Resolution Protocol (ARP)
// 0x0842 Wake-on-LAN[8]
// 0x22F0 Audio Video Transport Protocol (AVTP)
// 0x22F3 IETF TRILL Protocol
// 0x22EA Stream Reservation Protocol
// 0x6002 DEC MOP RC
// 0x6003 DECnet Phase IV, DNA Routing
// 0x6004 DEC LAT
// 0x8035 Reverse Address Resolution Protocol (RARP)
// 0x809B AppleTalk (Ethertalk)
// 0x80F3 AppleTalk Address Resolution Protocol (AARP)
// 0x8100 VLAN-tagged frame (IEEE 802.1Q) and Shortest Path Bridging IEEE 802.1aq with NNI compatibility[9]
// 0x8102 Simple Loop Prevention Protocol (SLPP)
// 0x8103 Virtual Link Aggregation Control Protocol (VLACP)
// 0x8137 IPX
// 0x8204 QNX Qnet
// 0x86DD Internet Protocol Version 6 (IPv6)
// 0x8808 Ethernet flow control
// 0x8809 Ethernet Slow Protocols[10] such as the Link Aggregation Control Protocol (LACP)
// 0x8819 CobraNet
// 0x8847 MPLS unicast
// 0x8848 MPLS multicast
// 0x8863 PPPoE Discovery Stage
// 0x8864 PPPoE Session Stage
// 0x887B HomePlug 1.0 MME
// 0x888E EAP over LAN (IEEE 802.1X)
// 0x8892 PROFINET Protocol
// 0x889A HyperSCSI (SCSI over Ethernet)
// 0x88A2 ATA over Ethernet
// 0x88A4 EtherCAT Protocol
// 0x88A8 Service VLAN tag identifier (S-Tag) on Q-in-Q tunnel.
// 0x88AB Ethernet Powerlink[citation needed]
// 0x88B8 GOOSE (Generic Object Oriented Substation event)
// 0x88B9 GSE (Generic Substation Events) Management Services
// 0x88BA SV (Sampled Value Transmission)
// 0x88BF MikroTik RoMON (unofficial)
// 0x88CC Link Layer Discovery Protocol (LLDP)
// 0x88CD SERCOS III
// 0x88E1 HomePlug Green PHY
// 0x88E3 Media Redundancy Protocol (IEC62439-2)
// 0x88E5 IEEE 802.1AE MAC security (MACsec)
// 0x88E7 Provider Backbone Bridges (PBB) (IEEE 802.1ah)
// 0x88F7 Precision Time Protocol (PTP) over IEEE 802.3 Ethernet
// 0x88F8 NC-SI
// 0x88FB Parallel Redundancy Protocol (PRP)
// 0x8902 IEEE 802.1ag Connectivity Fault Management (CFM) Protocol / ITU-T Recommendation Y.1731 (OAM)
// 0x8906 Fibre Channel over Ethernet (FCoE)
// 0x8914 FCoE Initialization Protocol
// 0x8915 RDMA over Converged Ethernet (RoCE)
// 0x891D TTEthernet Protocol Control Frame (TTE)
// 0x893a 1905.1 IEEE Protocol
// 0x892F High-availability Seamless Redundancy (HSR)
// 0x9000 Ethernet Configuration Testing Protocol[11]
// 0xF1C1 Redundancy Tag (IEEE 802.1CB Frame Replication and Elimination for Reliability)

//////////////////////////////////////////////////////////////////////
// Reference [E] Portion of file /usr/include/net/ethernet.h from an
// Ubuntu 20.04 Linux system, retrieved on 2022-Dec-04, part of Ubuntu
// package libc6-dev:amd64
//////////////////////////////////////////////////////////////////////

// #define ETHERTYPE_PUP      0x0200  /* Xerox PUP */
// #define ETHERTYPE_SPRITE   0x0500  /* Sprite */
// #define ETHERTYPE_IP       0x0800  /* IP */
// #define ETHERTYPE_ARP      0x0806  /* Address resolution */
// #define ETHERTYPE_REVARP   0x8035  /* Reverse ARP */
// #define ETHERTYPE_AT       0x809B  /* AppleTalk protocol */
// #define ETHERTYPE_AARP     0x80F3  /* AppleTalk ARP */
// #define ETHERTYPE_VLAN     0x8100  /* IEEE 802.1Q VLAN tagging */
// #define ETHERTYPE_IPX      0x8137  /* IPX */
// #define ETHERTYPE_IPV6     0x86dd  /* IP protocol version 6 */
// #define ETHERTYPE_LOOPBACK 0x9000  /* used to test interfaces */

//////////////////////////////////////////////////////////////////////
// Reference [F] Portion of file /usr/include/linux/if_ether.h from an
// Ubuntu 20.04 Linux system, retrieved on 2022-Dec-04, part of Ubuntu
// package linux-libc-dev:amd64
//////////////////////////////////////////////////////////////////////

// #define ETH_P_LOOP      0x0060          /* Ethernet Loopback packet     */
// #define ETH_P_PUP       0x0200          /* Xerox PUP packet             */
// #define ETH_P_PUPAT     0x0201          /* Xerox PUP Addr Trans packet  */
// #define ETH_P_TSN       0x22F0          /* TSN (IEEE 1722) packet       */
// #define ETH_P_ERSPAN2   0x22EB          /* ERSPAN version 2 (type III)  */
// #define ETH_P_IP        0x0800          /* Internet Protocol packet     */
// #define ETH_P_X25       0x0805          /* CCITT X.25                   */
// #define ETH_P_ARP       0x0806          /* Address Resolution packet    */
// #define ETH_P_BPQ       0x08FF          /* G8BPQ AX.25 Ethernet Packet  [ NOT AN OFFICIALLY REGISTERED ID ] */
// #define ETH_P_IEEEPUP   0x0a00          /* Xerox IEEE802.3 PUP packet */
// #define ETH_P_IEEEPUPAT 0x0a01          /* Xerox IEEE802.3 PUP Addr Trans packet */
// #define ETH_P_BATMAN    0x4305          /* B.A.T.M.A.N.-Advanced packet [ NOT AN OFFICIALLY REGISTERED ID ] */
// #define ETH_P_DEC       0x6000          /* DEC Assigned proto           */
// #define ETH_P_DNA_DL    0x6001          /* DEC DNA Dump/Load            */
// #define ETH_P_DNA_RC    0x6002          /* DEC DNA Remote Console       */
// #define ETH_P_DNA_RT    0x6003          /* DEC DNA Routing              */
// #define ETH_P_LAT       0x6004          /* DEC LAT                      */
// #define ETH_P_DIAG      0x6005          /* DEC Diagnostics              */
// #define ETH_P_CUST      0x6006          /* DEC Customer use             */
// #define ETH_P_SCA       0x6007          /* DEC Systems Comms Arch       */
// #define ETH_P_TEB       0x6558          /* Trans Ether Bridging         */
// #define ETH_P_RARP      0x8035          /* Reverse Addr Res packet      */
// #define ETH_P_ATALK     0x809B          /* Appletalk DDP                */
// #define ETH_P_AARP      0x80F3          /* Appletalk AARP               */
// #define ETH_P_8021Q     0x8100          /* 802.1Q VLAN Extended Header  */
// #define ETH_P_ERSPAN    0x88BE          /* ERSPAN type II               */
// #define ETH_P_IPX       0x8137          /* IPX over DIX                 */
// #define ETH_P_IPV6      0x86DD          /* IPv6 over bluebook           */
// #define ETH_P_PAUSE     0x8808          /* IEEE Pause frames. See 802.3 31B */
// #define ETH_P_SLOW      0x8809          /* Slow Protocol. See 802.3ad 43B */
// #define ETH_P_WCCP      0x883E          /* Web-cache coordination protocol
//                                          * defined in draft-wilson-wrec-wccp-v2-00.txt */
// #define ETH_P_MPLS_UC   0x8847          /* MPLS Unicast traffic         */
// #define ETH_P_MPLS_MC   0x8848          /* MPLS Multicast traffic       */
// #define ETH_P_ATMMPOA   0x884c          /* MultiProtocol Over ATM       */
// #define ETH_P_PPP_DISC  0x8863          /* PPPoE discovery messages     */
// #define ETH_P_PPP_SES   0x8864          /* PPPoE session messages       */
// #define ETH_P_LINK_CTL  0x886c          /* HPNA, wlan link local tunnel */
// #define ETH_P_ATMFATE   0x8884          /* Frame-based ATM Transport
//                                          * over Ethernet
//                                          */
// #define ETH_P_PAE       0x888E          /* Port Access Entity (IEEE 802.1X) */
// #define ETH_P_AOE       0x88A2          /* ATA over Ethernet            */
// #define ETH_P_8021AD    0x88A8          /* 802.1ad Service VLAN         */
// #define ETH_P_802_EX1   0x88B5          /* 802.1 Local Experimental 1.  */
// #define ETH_P_PREAUTH   0x88C7          /* 802.11 Preauthentication */
// #define ETH_P_TIPC      0x88CA          /* TIPC                         */
// #define ETH_P_LLDP      0x88CC          /* Link Layer Discovery Protocol */
// #define ETH_P_MACSEC    0x88E5          /* 802.1ae MACsec */
// #define ETH_P_8021AH    0x88E7          /* 802.1ah Backbone Service Tag */
// #define ETH_P_MVRP      0x88F5          /* 802.1Q MVRP                  */
// #define ETH_P_1588      0x88F7          /* IEEE 1588 Timesync */
// #define ETH_P_NCSI      0x88F8          /* NCSI protocol                */
// #define ETH_P_PRP       0x88FB          /* IEC 62439-3 PRP/HSRv0        */
// #define ETH_P_FCOE      0x8906          /* Fibre Channel over Ethernet  */
// #define ETH_P_IBOE      0x8915          /* Infiniband over Ethernet     */
// #define ETH_P_TDLS      0x890D          /* TDLS */
// #define ETH_P_FIP       0x8914          /* FCoE Initialization Protocol */
// #define ETH_P_80221     0x8917          /* IEEE 802.21 Media Independent Handover Protocol */
// #define ETH_P_HSR       0x892F          /* IEC 62439-3 HSRv1    */
// #define ETH_P_NSH       0x894F          /* Network Service Header */
// #define ETH_P_LOOPBACK  0x9000          /* Ethernet loopback packet, per IEEE 802.3 */
// #define ETH_P_QINQ1     0x9100          /* deprecated QinQ VLAN [ NOT AN OFFICIALLY REGISTERED ID ] */
// #define ETH_P_QINQ2     0x9200          /* deprecated QinQ VLAN [ NOT AN OFFICIALLY REGISTERED ID ] */
// #define ETH_P_QINQ3     0x9300          /* deprecated QinQ VLAN [ NOT AN OFFICIALLY REGISTERED ID ] */
// #define ETH_P_EDSA      0xDADA          /* Ethertype DSA [ NOT AN OFFICIALLY REGISTERED ID ] */
// #define ETH_P_DSA_8021Q 0xDADB          /* Fake VLAN Header for DSA [ NOT AN OFFICIALLY REGISTERED ID ] */
// #define ETH_P_IFE       0xED3E          /* ForCES inter-FE LFB type */
// #define ETH_P_AF_IUCV   0xFBFB          /* IBM af_iucv [ NOT AN OFFICIALLY REGISTERED ID ] */
// 
// #define ETH_P_802_3_MIN 0x0600          /* If the value in the ethernet type is less than this value
//                                          * then the frame is Ethernet II. Else it is 802.3 */
// 
// /*
//  *      Non DIX types. Won't clash for 1500 types.
//  */
// 
// #define ETH_P_802_3     0x0001          /* Dummy type for 802.3 frames  */
// #define ETH_P_AX25      0x0002          /* Dummy protocol id for AX.25  */
// #define ETH_P_ALL       0x0003          /* Every packet (be careful!!!) */
// #define ETH_P_802_2     0x0004          /* 802.2 frames                 */
// #define ETH_P_SNAP      0x0005          /* Internal only                */
// #define ETH_P_DDCMP     0x0006          /* DEC DDCMP: Internal only     */
// #define ETH_P_WAN_PPP   0x0007          /* Dummy type for WAN PPP frames*/
// #define ETH_P_PPP_MP    0x0008          /* Dummy type for PPP MP frames */
// #define ETH_P_LOCALTALK 0x0009          /* Localtalk pseudo type        */
// #define ETH_P_CAN       0x000C          /* CAN: Controller Area Network */
// #define ETH_P_CANFD     0x000D          /* CANFD: CAN flexible data rate*/
// #define ETH_P_PPPTALK   0x0010          /* Dummy type for Atalk over PPP*/
// #define ETH_P_TR_802_2  0x0011          /* 802.2 frames                 */
// #define ETH_P_MOBITEX   0x0015          /* Mobitex (kaz@cafe.net)       */
// #define ETH_P_CONTROL   0x0016          /* Card specific control frames */
// #define ETH_P_IRDA      0x0017          /* Linux-IrDA                   */
// #define ETH_P_ECONET    0x0018          /* Acorn Econet                 */
// #define ETH_P_HDLC      0x0019          /* HDLC frames                  */
// #define ETH_P_ARCNET    0x001A          /* 1A for ArcNet :-)            */
// #define ETH_P_DSA       0x001B          /* Distributed Switch Arch.     */
// #define ETH_P_TRAILER   0x001C          /* Trailer switch tagging       */
// #define ETH_P_PHONET    0x00F5          /* Nokia Phonet frames          */
// #define ETH_P_IEEE802154 0x00F6         /* IEEE802.15.4 frame           */
// #define ETH_P_CAIF      0x00F7          /* ST-Ericsson CAIF protocol    */
// #define ETH_P_XDSA      0x00F8          /* Multiplexed DSA protocol     */
// #define ETH_P_MAP       0x00F9          /* Qualcomm multiplexing and
//                                          * aggregation protocol
//                                          */

//////////////////////////////////////////////////////////////////////
// Reference [X] This is a tiny fraction of the values listed at that
// source, primarily the ones that I have seen used in some P4 code
// somewhere that are not part of one of the sources above.
//////////////////////////////////////////////////////////////////////

// 0x8903 Cisco DCE (Data Center Ethernet)
// 0x8926 Cisco VNTAG (Virtual Network endpoint TAG)
// 0x893F Bridge Port Extension tag (E-TAG) as defined in IEEE Std 802.1BR.  
// 0x894F Cisco NSH (Network Service Header), RFC 8300

//////////////////////////////////////////////////////////////////////
// These appear to have no standard definition, but are sometimes used
// in the wild.
//////////////////////////////////////////////////////////////////////

// 0x6007 ND [I] calls this "DEC LAVC, SCA"
// 0x9100 Sometimes called QINQ.  Not standard, but seems to have historically been used in stacks of VLAN tags.
// 0x9200 Not standard, but seems to have historically been used in stacks of VLAN tags.

//////////////////////////////////////////////////////////////////////
// Selected subset of Ethertypes to define in actual source code.
// Feel free to add new ones as needed.
//////////////////////////////////////////////////////////////////////

enum bit<16> ether_type_t {
    IPV4      = 0x0800, /* IPv4 */
    ARP       = 0x0806, /* Address Resolution Protocol */
    RARP      = 0x8035, /* Reverse ARP, RFC 903 */
    AT        = 0x809B, /* AppleTalk protocol */
    AARP      = 0x80F3, /* AppleTalk ARP */
    VLAN      = 0x8100, /* IEEE 802.1Q Customer VLAN Tag Type (C-Tag, formerly called the Q-Tag) */
    IPX       = 0x8137, /* IPX */
    IPV6      = 0x86DD, /* IP protocol version 6 */
    PAUSE     = 0x8808, /* IEEE Pause frames. See 802.3 31B */
    MPLS      = 0x8847, /* MPLS */
    MPLS_UPSTREAM = 0x8848, /* MPLS with upstream-assigned label */
    QINQ      = 0x88A8, /* Service VLAN tag identifier (S-Tag) */
    LLDP      = 0x88CC, /* Link Layer Discovery Protocol */
    MACSEC    = 0x88E5, /* IEEE 802.1ae MAC security (MACsec) */
    PBB       = 0x88E7, /* IEEE 802.1ah Provider Backbone Bridges */
    PTP       = 0x88F7, /* Precision Time Protocol */
    DCE       = 0x8903, /* Cisco Data Center Ethernet */
    FCOE      = 0x8906, /* Fibre Channel over Ethernet */
    VNTAG     = 0x8926, /* Cisco Virtual Network endpoint Tag */
    BR        = 0x893F, /* Bridge Port Extension tag (E-TAG) */
    NSH       = 0x894F, /* Network Service Header, RFC 8300 */
    ROCE      = 0x8915, /* RDMA over Converged Ethernet */
    LOOPBACK  = 0x9000, /* Ethernet loopback packet, per IEEE 802.3 */
    QINQ1     = 0x9100, /* deprecated QinQ VLAN (NOT AN OFFICIALLY REGISTERED ID) */
    QINQ2     = 0x9200, /* deprecated QinQ VLAN (NOT AN OFFICIALLY REGISTERED ID) */
    QINQ3     = 0x9300  /* deprecated QinQ VLAN (NOT AN OFFICIALLY REGISTERED ID) */
}
