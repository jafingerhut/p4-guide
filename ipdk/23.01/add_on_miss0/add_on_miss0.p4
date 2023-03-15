/* -*- P4_16 -*- */

#include <core.p4>
#include <pna.p4>

/*************************************************************************
 ************* C O N S T A N T S    A N D   T Y P E S  *******************
 *************************************************************************/
const int IPV4_HOST_SIZE = 65536;

/*************************************************************************
 ***********************  H E A D E R S  *********************************
 *************************************************************************/

/*  Define all the headers the program will recognize             */
/*  The actual sets of headers processed by each gress can differ */

typedef bit<48>  EthernetAddress;
typedef bit<32>  IPv4Address;
typedef bit<128> IPv6Address;

typedef bit<16> etype_t;
const etype_t ETYPE_IPV4      = 0x0800; /* IPv4 */

typedef bit<8> ipproto_t;
const ipproto_t IPPROTO_TCP = 6;       /* Transmission Control Protocol */
const ipproto_t IPPROTO_UDP = 17;      /* User Datagram Protocol */

// https://en.wikipedia.org/wiki/Ethernet_frame
header ethernet_h {
    EthernetAddress dst_addr;
    EthernetAddress src_addr;
    etype_t ether_type;
}

// RFC 791
// https://en.wikipedia.org/wiki/IPv4
// https://tools.ietf.org/html/rfc791
header ipv4_h {
    bit<8>  version_ihl;        // version always 4 for IPv4, ihl=header length
    bit<8>  diffserv;           // 6 bits of DSCP followed by 2-bit ECN
    bit<16> total_len;          // in bytes, including IPv4 header
    bit<16> identification;
    bit<16> flags_frag_offset;
    bit<8>  ttl;                // time to live
    ipproto_t protocol;
    bit<16> hdr_checksum;
    IPv4Address src_addr;
    IPv4Address dst_addr;
}

// RFC 793 and several later RFCs that update it
// https://en.wikipedia.org/wiki/Transmission_Control_Protocol
// https://tools.ietf.org/html/rfc793
header tcp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<32> seq_no;
    bit<32> ack_no;
    bit<4>  data_offset;
    bit<4>  res;
    bit<8>  flags;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgent_ptr;
}

// Masks of the bit positions of some bit flags within the TCP flags
// field.
const bit<8> TCP_URG_MASK = 0x20;
const bit<8> TCP_ACK_MASK = 0x10;
const bit<8> TCP_PSH_MASK = 0x08;
const bit<8> TCP_RST_MASK = 0x04;
const bit<8> TCP_SYN_MASK = 0x02;
const bit<8> TCP_FIN_MASK = 0x01;

// RFC 768
// https://en.wikipedia.org/wiki/User_Datagram_Protocol
// https://tools.ietf.org/html/rfc768
header udp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<16> length;
    bit<16> checksum;
}

// Define names for different expire time profile id values.

const ExpireTimeProfileId_t EXPIRE_TIME_PROFILE_TCP_NOW    = (ExpireTimeProfileId_t) 0;
const ExpireTimeProfileId_t EXPIRE_TIME_PROFILE_TCP_NEW    = (ExpireTimeProfileId_t) 1;
const ExpireTimeProfileId_t EXPIRE_TIME_PROFILE_TCP_ESTABLISHED = (ExpireTimeProfileId_t) 2;
const ExpireTimeProfileId_t EXPIRE_TIME_PROFILE_TCP_NEVER  = (ExpireTimeProfileId_t) 3;

/*************************************************************************
 **************  I N G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/

    /***********************  H E A D E R S  ************************/

struct headers_t {
    ethernet_h   ethernet;
    ipv4_h       ipv4;
    tcp_h        tcp;
    udp_h        udp;
}

    /******  G L O B A L   I N G R E S S   M E T A D A T A  *********/

struct metadata_t {
}

    /***********************  P A R S E R  **************************/
parser MainParserImpl(
    packet_in pkt,
    out   headers_t  hdr,
    inout metadata_t meta,
    in    pna_main_parser_input_metadata_t istd)
{
     state start {
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select (hdr.ethernet.ether_type) {
            ETYPE_IPV4:  parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select (hdr.ipv4.protocol) {
            IPPROTO_TCP: parse_tcp;
            IPPROTO_UDP: parse_udp;
            default: accept;
        }
    }

    state parse_tcp {
        pkt.extract(hdr.tcp);
        transition accept;
    }

    state parse_udp {
        pkt.extract(hdr.udp);
        transition accept;
    }
}

// As of 2023-Mar-14, p4c-dpdk implementation of PNA architecture
// still requires PreControl.

control PreControlImpl(
    in    headers_t hdr,
    inout metadata_t meta,
    in    pna_pre_input_metadata_t  istd,
    inout pna_pre_output_metadata_t ostd)
{
    apply {
    }
}

    /***************** M A T C H - A C T I O N  *********************/

struct ct_tcp_table_hit_params_t {
}

// Note 1:

// I attempted to compile the program with the call to
// set_entry_expire_time() uncommented using a version of p4c built
// from this source code of repository https://github.com/p4lang/p4c

// $ git log -n 1 | head -n 5
// commit ca1f3474d532aa5c8eea5db5adbd838bc8b52d07
// Author: Fabian Ruffy <5960321+fruffy@users.noreply.github.com>
// Date:   Thu Feb 23 10:40:19 2023 -0500
// 
//     Deprecate unified build in favor of unity build. (#3491)

// but I got this error message that I do not understand:

// add_on_miss1.p4(228): [--Werror=unexpected] error: set_entry_expire_time must only be called from within an action with ' ct_tcp_table_hit' property equal to true
//                 set_entry_expire_time(new_expire_time_profile_id);
//                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

// Note 2:

// I attempted to compile the program with the call to
// restart_expire_timer() uncommented using the same version of p4c
// mentioned in Note 1, but I got this error message:

// add_on_miss1.p4(261): [--Werror=unexpected] error: restart_expire_timer must only be called from within an action with ' ct_tcp_table_hit' property equal to true
//                 restart_expire_timer();
//                 ^^^^^^^^^^^^^^^^^^^^^^

control MainControlImpl(
    inout headers_t  hdr,
    inout metadata_t meta,
    in    pna_main_input_metadata_t  istd,
    inout pna_main_output_metadata_t ostd)
{
    action drop () {
        drop_packet();
    }

    // Inputs from previous tables (or actions, or in general other P4
    // code) that can modify the behavior of actions of ct_tcp_table.
    ExpireTimeProfileId_t new_expire_time_profile_id;

    action ct_tcp_table_hit () {
        // Make a change to the packet that is visible in the packet
        // output by the device, for debug purposes
        hdr.ethernet.src_addr[7:0] = 0xf1;
    }

    action ct_tcp_table_miss() {
        add_entry(action_name = "ct_tcp_table_hit",  // name of action
            action_params = (ct_tcp_table_hit_params_t) {},
            expire_time_profile_id = new_expire_time_profile_id);
        // Make a change to the packet that is visible in the packet
        // output by the device, for debug purposes
        hdr.ethernet.src_addr[7:0] = 0xa5;
    }

    table ct_tcp_table {
        key = {
            hdr.ipv4.src_addr: exact;
            hdr.ipv4.dst_addr: exact;
            hdr.ipv4.protocol: exact;
            hdr.tcp.src_port:  exact;
            hdr.tcp.dst_port:  exact;
        }
        actions = {
            @tableonly   ct_tcp_table_hit;
            @defaultonly ct_tcp_table_miss;
        }

        // New PNA table property 'add_on_miss = true' indicates that
        // this table can use extern function add_entry() in its
        // default (i.e. miss) action to add a new entry to the table
        // from the data plane.
        add_on_miss = true;

        // As of 2023-Mar-14, p4c-dpdk implementation of PNA
        // architecture does not implement value AUTO_DELETE yet.
        pna_idle_timeout = PNA_IdleTimeout_t.NOTIFY_CONTROL;
        const default_action = ct_tcp_table_miss;
    }

    action send(PortId_t port) {
        send_to_port(port);
    }

    table ipv4_host {
        key = {
            hdr.ipv4.dst_addr : exact;
        }
        actions = {
            send;
            drop;
            @defaultonly NoAction;
        }
        const default_action = drop();
        size = IPV4_HOST_SIZE;
    }

    apply {
        new_expire_time_profile_id = EXPIRE_TIME_PROFILE_TCP_NEW;
        if (hdr.ipv4.isValid() && hdr.tcp.isValid()) {
            ct_tcp_table.apply();
        }
        if (hdr.ipv4.isValid()) {
            ipv4_host.apply();
        }
    }
}

    /*********************  D E P A R S E R  ************************/

control MainDeparserImpl(
    packet_out pkt,
    in    headers_t hdr,
    in    metadata_t meta,
    in    pna_main_output_metadata_t ostd)
{
    apply {
        pkt.emit(hdr);
    }
}

/************ F I N A L   P A C K A G E ******************************/

PNA_NIC(
    MainParserImpl(),
    PreControlImpl(),
    MainControlImpl(),
    MainDeparserImpl()
    ) main;
